#include "llvm/ADT/SmallPtrSet.h"
#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_global {

using namespace llvm;

static Function *FindFnByGuestAddr(Module &M, uint64_t Addr) {
  for (Function &F : M) {
    StringRef Name = F.getName();
    for (const char *Prefix : {"sub_", "auto_sub_", "callback_sub_"}) {
      if (!Name.starts_with(Prefix))
        continue;
      StringRef Rest = Name.drop_front(strlen(Prefix));
      size_t Dot = Rest.find('.');
      if (Dot != StringRef::npos)
        Rest = Rest.substr(0, Dot);
      uint64_t FnAddr = 0;
      if (!Rest.getAsInteger(16, FnAddr) && FnAddr == Addr)
        return &F;
    }
  }
  return nullptr;
}

static bool TraceToValue(Value *Source, Value *Target, SmallPtrSetImpl<Value *> &Visited) {
  if (Source == Target)
    return true;
  if (!Visited.insert(Source).second)
    return false;
  for (User *U : Source->users()) {
    if (U == Target)
      return true;
    if (isa<PtrToIntInst>(U) || isa<IntToPtrInst>(U) ||
        isa<ZExtInst>(U) || isa<SExtInst>(U) || isa<TruncInst>(U) ||
        isa<BitCastInst>(U)) {
      if (TraceToValue(U, Target, Visited))
        return true;
    }
  }
  return false;
}

static bool IsJumpTableLoad(Instruction *I, GlobalDataContext &Ctx,
                             uint64_t &TableBase, Value *&IndexVal,
                             unsigned &EntrySize, GuestSegment *&Seg,
                             CallInst *&OutJumpCall) {
  auto *LI = dyn_cast<LoadInst>(I);
  if (!LI)
    return false;

  Value *Ptr = LI->getPointerOperand();
  auto *GEP = dyn_cast<GetElementPtrInst>(Ptr);
  if (!GEP)
    return false;

  Value *Base = GEP->getPointerOperand();
  auto *BaseGV = dyn_cast<GlobalVariable>(Base);
  if (!BaseGV)
    return false;

  GuestSegment *FoundSeg = nullptr;
  for (auto &S : Ctx.Segments) {
    if (S->GV == BaseGV) {
      FoundSeg = S.get();
      break;
    }
  }
  if (!FoundSeg || !FoundSeg->BaseResolved)
    return false;

  if (GEP->getNumIndices() < 2)
    return false;

  auto *FirstIdx = dyn_cast<ConstantInt>(GEP->getOperand(1));
  if (!FirstIdx || !FirstIdx->isZero())
    return false;

  Value *Idx = GEP->getOperand(2);

  // Compute exact GEP constant offset
  APInt ConstantOffset(Ctx.DL.getPointerSizeInBits(), 0);
  if (GEP->accumulateConstantOffset(Ctx.DL, ConstantOffset)) {
    TableBase = FoundSeg->GuestBase + ConstantOffset.getZExtValue();
  } else {
    // If not a pure constant offset, try base segment + constant component of offset
    TableBase = FoundSeg->GuestBase;
  }

  Type *LoadTy = LI->getType();
  unsigned LoadSize = Ctx.DL.getTypeStoreSize(LoadTy);
  if (LoadSize != 4 && LoadSize != 8)
    return false;

  bool TraceOk = false;
  BasicBlock *BB = I->getParent();
  for (Instruction &Inst : *BB) {
    if (auto *CI = dyn_cast<CallInst>(&Inst)) {
      Function *Callee = CI->getCalledFunction();
      if (Callee && Callee->getName() == "__remill_jump") {
        SmallPtrSet<Value *, 8> Visited;
        if (TraceToValue(LI, CI->getArgOperand(1), Visited)) {
          TraceOk = true;
          OutJumpCall = CI;
          break;
        }
      }
    }
  }

  if (!TraceOk || !OutJumpCall)
    return false;

  IndexVal = Idx;
  EntrySize = LoadSize;
  Seg = FoundSeg;
  return true;
}

static bool TryResolveJumpTable(GlobalDataContext &Ctx, uint64_t TableAddr,
                                 GuestSegment *Seg, unsigned EntrySize,
                                 JumpTableInfo &JTInfo) {
  uint64_t SegEnd = Seg->GuestBase + Seg->Size;
  SmallVector<JumpTableEntry, 32> Entries;
  uint64_t Addr = TableAddr;
  unsigned MaxEntries = 4096;

  while (Addr + EntrySize <= SegEnd && Entries.size() < MaxEntries) {
    SmallVector<uint8_t, 8> Bytes;
    if (!Ctx.readSegmentBytes(Seg, Addr, EntrySize, Bytes))
      break;

    uint64_t Val = 0;
    for (unsigned I = 0; I < EntrySize; ++I)
      Val |= (uint64_t)Bytes[I] << (I * 8);

    if (Val == 0)
      break;

    JumpTableEntry Entry;
    Entry.GuestTarget = Val;
    Entry.TargetFn = FindFnByGuestAddr(Ctx.M, Val);
    Entry.Resolved = (Entry.TargetFn != nullptr);

    if (!Entry.Resolved)
      return false;

    Entries.push_back(Entry);
    Addr += EntrySize;
  }

  if (Entries.size() < 2)
    return false;

  JTInfo.TableBase = TableAddr;
  JTInfo.EntryCount = Entries.size();
  JTInfo.EntrySize = EntrySize;
  JTInfo.Segment = Seg;
  JTInfo.Entries = std::move(Entries);
  JTInfo.Recovered = true;
  return true;
}

bool BrightenGlobalDataRecoveryPass::RecoverJumpTableCFG(
    GlobalDataContext &Ctx) {
  bool Changed = false;
  unsigned Count = 0;

  for (Function &F : Ctx.M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        uint64_t TableBase = 0;
        Value *IndexVal = nullptr;
        unsigned EntrySize = 0;
        GuestSegment *Seg = nullptr;
        CallInst *JumpCall = nullptr;

        if (!IsJumpTableLoad(&I, Ctx, TableBase, IndexVal, EntrySize, Seg, JumpCall))
          continue;

        auto JT = std::make_unique<JumpTableInfo>();
        if (!TryResolveJumpTable(Ctx, TableBase, Seg, EntrySize, *JT)) {
          JT->TableBase = TableBase;
          JT->Recovered = false;
          JT->SkipReason = "jump-table-target-unknown";
          JT->Action = "preserved";
          Ctx.JumpTables.push_back(std::move(JT));
          continue;
        }

        // Verify function return signature compatibility
        Type *RetTy = F.getReturnType();
        bool SignatureCompat = true;
        for (auto &Entry : JT->Entries) {
          if (!Entry.TargetFn) {
            SignatureCompat = false;
            break;
          }
          Type *TargetRetTy = Entry.TargetFn->getReturnType();
          if (RetTy != TargetRetTy) {
            if (!RetTy->isPointerTy() || !TargetRetTy->isPointerTy()) {
              if (!RetTy->isIntegerTy() || !TargetRetTy->isIntegerTy()) {
                SignatureCompat = false;
                break;
              }
            }
          }
        }

        if (!SignatureCompat) {
          JT->TableBase = TableBase;
          JT->Recovered = false;
          JT->SkipReason = "signature-mismatch-unsafe-cfg";
          JT->Action = "preserved";
          Ctx.JumpTables.push_back(std::move(JT));
          continue;
        }

        // The table load is removed below.  If it still has a live use, the
        // use is part of the program's data flow and cannot be replaced with
        // a fabricated null value.  Preserve the original CFG instead.
        if (!I.use_empty()) {
          JT->TableBase = TableBase;
          JT->Recovered = false;
          JT->SkipReason = "jump-table-load-has-live-users";
          JT->Action = "preserved";
          Ctx.JumpTables.push_back(std::move(JT));
          continue;
        }

        JT->BranchInst = &I;
        JT->IndexValue = IndexVal;
        JT->Action = "recovered-jumptable";

        LLVMContext &LCtx = Ctx.M.getContext();
        BasicBlock *DefaultBB = BasicBlock::Create(LCtx, "jt_default", &F);
        IRBuilder<> DefaultBuilder(DefaultBB);
        DefaultBuilder.CreateUnreachable();

        IRBuilder<> Builder(JumpCall);
        SwitchInst *SI = Builder.CreateSwitch(IndexVal, DefaultBB, JT->Entries.size());

        unsigned CaseId = 0;
        for (auto &Entry : JT->Entries) {
          BasicBlock *CaseBB = BasicBlock::Create(LCtx, "jt_case_" + std::to_string(CaseId), &F);
          IRBuilder<> CaseBuilder(CaseBB);

          Value *StateParam = JumpCall->getArgOperand(0);
          Value *MemParam = JumpCall->getArgOperand(2);
          Value *PCParam = ConstantInt::get(Type::getInt64Ty(LCtx), Entry.GuestTarget);

          SmallVector<Value *, 3> Args;
          if (Entry.TargetFn->arg_size() >= 1) {
            Value *Arg0 = StateParam;
            Type *ParamTy = Entry.TargetFn->getFunctionType()->getParamType(0);
            if (Arg0->getType() != ParamTy) {
              Arg0 = CaseBuilder.CreateBitCast(Arg0, ParamTy);
            }
            Args.push_back(Arg0);
          }
          if (Entry.TargetFn->arg_size() >= 2) {
            Value *Arg1 = PCParam;
            Type *ParamTy = Entry.TargetFn->getFunctionType()->getParamType(1);
            if (Arg1->getType() != ParamTy) {
              Arg1 = CaseBuilder.CreateZExtOrTrunc(Arg1, ParamTy);
            }
            Args.push_back(Arg1);
          }
          if (Entry.TargetFn->arg_size() >= 3) {
            Value *Arg2 = MemParam;
            Type *ParamTy = Entry.TargetFn->getFunctionType()->getParamType(2);
            if (Arg2->getType() != ParamTy) {
              Arg2 = CaseBuilder.CreateBitCast(Arg2, ParamTy);
            }
            Args.push_back(Arg2);
          }

          CallInst *Call = CaseBuilder.CreateCall(Entry.TargetFn, Args);

          if (RetTy->isVoidTy()) {
            CaseBuilder.CreateRetVoid();
          } else {
            Value *RetVal = Call;
            if (Call->getType() != RetTy) {
              if (RetTy->isPointerTy() && Call->getType()->isPointerTy()) {
                RetVal = CaseBuilder.CreateBitCast(Call, RetTy);
              } else {
                RetVal = CaseBuilder.CreateZExtOrTrunc(Call, RetTy);
              }
            }
            CaseBuilder.CreateRet(RetVal);
          }

unsigned GEP_ElemSize = 1;
          if (auto *GEPInst = dyn_cast<GetElementPtrInst>(cast<LoadInst>(&I)->getPointerOperand())) {
            GEP_ElemSize = Ctx.DL.getTypeAllocSize(GEPInst->getSourceElementType());
          }
          uint64_t CaseVal = CaseId;
          if (GEP_ElemSize == 1) {
            CaseVal = (uint64_t)CaseId * JT->EntrySize;
          }
          auto *IndexTy = cast<IntegerType>(IndexVal->getType());
          SI->addCase(ConstantInt::get(IndexTy, CaseVal), CaseBB);
          ++CaseId;
        }

        Instruction *Next = SI->getNextNode();
        while (Next) {
          Instruction *ToErase = Next;
          Next = Next->getNextNode();
          ToErase->eraseFromParent();
        }

        Value *Ptr = cast<LoadInst>(&I)->getPointerOperand();
        I.eraseFromParent();
        if (auto *GEPInst = dyn_cast<GetElementPtrInst>(Ptr)) {
          if (GEPInst->use_empty()) {
            GEPInst->eraseFromParent();
          }
        }

        Changed = true;
        ++Count;
        Ctx.JumpTables.push_back(std::move(JT));
        break;
      }
    }
  }

  Ctx.Report.JumpTablesRecovered = Count;
  if (Ctx.Debug && Count > 0)
    errs() << "[brighten-global-data] converted " << Count
           << " jump tables to switches\n";

  return Changed;
}

} // namespace brighten_global
