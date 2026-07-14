#include "ABIAnalysis.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <functional>

namespace brighten_abi {

using namespace llvm;

bool LooksLikeRemillFunction(Function &F) {
  if (F.isDeclaration() || F.arg_size() != 3) {
    return false;
  }
  if (!F.getReturnType()->isPointerTy()) {
    return false;
  }
  auto It = F.arg_begin();
  Type *A0 = (It++)->getType();
  Type *A1 = (It++)->getType();
  Type *A2 = (It++)->getType();
  return A0->isPointerTy() && A1->isIntegerTy(64) && A2->isPointerTy();
}

static bool IsSpecialName(StringRef Name) {
  return Name.starts_with("__remill_") || Name.starts_with("__mcsema_") ||
         Name.starts_with("__translate_guest_pointer") ||
         Name.starts_with("llvm.") || Name.starts_with("ext_") ||
         Name.contains("setjmp") || Name.contains("longjmp");
}

bool IsEligibleRemillFunction(Function &F) {
  if (!LooksLikeRemillFunction(F)) {
    return false;
  }
  StringRef Name = F.getName();
  if (IsSpecialName(Name)) {
    return false;
  }
  return Name.starts_with("sub_");
}

bool HasForbiddenInlineAsm(Function &F) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB) {
        continue;
      }
      if (isa<InlineAsm>(CB->getCalledOperand()->stripPointerCasts())) {
        return true;
      }
    }
  }
  return false;
}

Function *ResolveCalledFunction(Value *Callee) {
  if (!Callee) {
    return nullptr;
  }
  Value *V = Callee->stripPointerCasts();
  if (auto *Alias = dyn_cast<GlobalAlias>(V)) {
    if (Constant *Aliasee = Alias->getAliasee()) {
      V = Aliasee->stripPointerCasts();
    }
  }
  return dyn_cast<Function>(V);
}

FunctionABISummary *FindSummary(ABIRecoveryContext &Ctx, Function *F) {
  if (!F) {
    return nullptr;
  }
  auto It = Ctx.OwnedSummaries.find(F);
  if (It != Ctx.OwnedSummaries.end()) {
    return It->second.get();
  }
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (S->RemillFn == F || S->OriginalFn == F || S->NativeFn == F ||
        S->WrapperFn == F) {
      return S;
    }
  }
  return nullptr;
}

FunctionABISummary *FindSummaryByOriginalName(ABIRecoveryContext &Ctx,
                                              StringRef Name) {
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (S->OriginalName == Name) {
      return S;
    }
  }
  return nullptr;
}

static unsigned IntegerWidth(Type *Ty, const DataLayout &DL) {
  if (!Ty) {
    return 0;
  }
  if (auto *IT = dyn_cast<IntegerType>(Ty)) {
    return IT->getBitWidth();
  }
  if (Ty->isPointerTy()) {
    return DL.getPointerSizeInBits();
  }
  if (Ty->isFloatingPointTy()) {
    return static_cast<unsigned>(DL.getTypeStoreSize(Ty).getFixedValue() * 8);
  }
  if (Ty->isVectorTy()) {
    return static_cast<unsigned>(DL.getTypeStoreSize(Ty).getFixedValue() * 8);
  }
  return 0;
}

Type *MergeABIType(Type *A, Type *B, const DataLayout &DL) {
  if (!A) {
    return B;
  }
  if (!B) {
    return A;
  }
  if (A == B) {
    return A;
  }
  LLVMContext &Ctx = A->getContext();
  if (A->isPointerTy() || B->isPointerTy()) {
    return PointerType::getUnqual(Ctx);
  }
  if (A->isVectorTy()) {
    return A;
  }
  if (B->isVectorTy()) {
    return B;
  }
  if (A->isDoubleTy() || B->isDoubleTy()) {
    return Type::getDoubleTy(Ctx);
  }
  if (A->isFloatTy() || B->isFloatTy()) {
    return Type::getFloatTy(Ctx);
  }
  unsigned W = std::max(IntegerWidth(A, DL), IntegerWidth(B, DL));
  if (W == 0) {
    W = 64;
  }
  W = std::min<unsigned>(std::max<unsigned>(W, 1), 128);
  return IntegerType::get(Ctx, W);
}

Value *CoerceValue(IRBuilder<> &B, Value *V, Type *DstTy, Twine Name) {
  if (!V || !DstTy || V->getType() == DstTy) {
    return V;
  }
  Type *SrcTy = V->getType();
  const DataLayout &DL = B.GetInsertBlock()->getModule()->getDataLayout();

  if (SrcTy->isPointerTy() && DstTy->isPointerTy()) {
    return V;
  }
  if (SrcTy->isPointerTy() && DstTy->isIntegerTy()) {
    Value *I = B.CreatePtrToInt(V, DL.getIntPtrType(DstTy->getContext()),
                                Name + ".pti");
    if (I->getType() == DstTy) {
      return I;
    }
    return CoerceValue(B, I, DstTy, Name);
  }
  if (SrcTy->isIntegerTy() && DstTy->isPointerTy()) {
    Type *PtrIntTy = DL.getIntPtrType(DstTy->getContext());
    Value *I = CoerceValue(B, V, PtrIntTy, Name + ".ptrint");
    return B.CreateIntToPtr(I, DstTy, Name);
  }
  if (auto *SI = dyn_cast<IntegerType>(SrcTy)) {
    if (auto *DI = dyn_cast<IntegerType>(DstTy)) {
      unsigned SW = SI->getBitWidth();
      unsigned DW = DI->getBitWidth();
      if (SW == DW) {
        return V;
      }
      if (SW > DW) {
        return B.CreateTrunc(V, DstTy, Name);
      }
      return B.CreateZExt(V, DstTy, Name);
    }
  }
  if (SrcTy->isFloatingPointTy() && DstTy->isFloatingPointTy()) {
    unsigned SW = IntegerWidth(SrcTy, DL);
    unsigned DW = IntegerWidth(DstTy, DL);
    if (SW > DW) {
      return B.CreateFPTrunc(V, DstTy, Name);
    }
    return B.CreateFPExt(V, DstTy, Name);
  }
  if (SrcTy->isVectorTy() && DstTy->isVectorTy()) {
    return B.CreateBitCast(V, DstTy, Name);
  }
  return nullptr;
}

static Value *ReturnMarkerValueBefore(Instruction *Before) {
  BasicBlock *BB = Before->getParent();
  for (auto It = BasicBlock::reverse_iterator(Before->getIterator());
       It != BB->rend(); ++It) {
    auto *CB = dyn_cast<CallBase>(&*It);
    if (!CB) {
      continue;
    }
    Function *Callee = CB->getCalledFunction();
    if (!Callee || Callee->getIntrinsicID() != Intrinsic::sideeffect) {
      continue;
    }
    auto Bundle = CB->getOperandBundle("brighten_return_rax");
    if (Bundle && !Bundle->Inputs.empty()) {
      return Bundle->Inputs[0].get();
    }
  }
  return nullptr;
}

static std::optional<uint64_t> IdentifyStateOffsetWithBase(Value *Ptr, Value *StateBase) {
  if (!Ptr) {
    return std::nullopt;
  }
  Value *Stripped = Ptr->stripPointerCasts();
  if (auto Offset = IdentifyStateOffset(Stripped)) {
    return Offset;
  }
  if (!StateBase) {
    return std::nullopt;
  }
  Module *M = nullptr;
  if (auto *I = dyn_cast<Instruction>(StateBase)) {
    M = I->getModule();
  } else if (auto *Arg = dyn_cast<Argument>(StateBase)) {
    M = Arg->getParent()->getParent();
  }
  if (!M) {
    return std::nullopt;
  }
  const DataLayout &DL = M->getDataLayout();
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Stripped->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (Base == StateBase && !Offset.isNegative()) {
    return Offset.getZExtValue();
  }
  return std::nullopt;
}

static Value *FindStoreInBlockBefore(BasicBlock *BB, Instruction *Before,
                                     ABIReg Reg) {
  Function *F = BB->getParent();
  Value *StateBase = F->arg_size() > 0 ? F->getArg(0) : nullptr;

  auto It = Before ? BasicBlock::reverse_iterator(Before->getIterator())
                   : BB->rbegin();
  for (; It != BB->rend(); ++It) {
    Instruction &I = *It;
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      auto Offset = IdentifyStateOffsetWithBase(SI->getPointerOperand(), StateBase);
      if (Offset) {
        auto StoreReg = RegisterForOffset(*Offset);
        if (StoreReg && *StoreReg == Reg) {
          return SI->getValueOperand();
        }
      }
    }
    if (auto RA = IdentifyRegAccess(I)) {
      if (RA->IsStore && RA->Reg == Reg) {
        return RA->Value;
      }
    }
  }
  return nullptr;
}

static Value *FindPredValue(BasicBlock *BB, ABIReg Reg, unsigned Depth,
                            SmallPtrSetImpl<BasicBlock *> &Seen) {
  if (!BB || Depth > 8 || !Seen.insert(BB).second) {
    return nullptr;
  }
  if (Value *V = FindStoreInBlockBefore(BB, nullptr, Reg)) {
    return V;
  }
  SmallVector<BasicBlock *, 4> Preds(predecessors(BB));
  if (Preds.size() != 1) {
    return nullptr;
  }
  return FindPredValue(Preds.front(), Reg, Depth + 1, Seen);
}

Value *FindRegisterValueBeforeReturn(ReturnInst *RI, ABIReg Reg) {
  if (!RI) {
    return nullptr;
  }
  if (Value *V = FindStoreInBlockBefore(RI->getParent(), RI, Reg)) {
    return V;
  }

  SmallVector<BasicBlock *, 8> Preds(predecessors(RI->getParent()));
  if (Preds.empty()) {
    return nullptr;
  }
  SmallVector<Value *, 8> Values;
  for (BasicBlock *Pred : Preds) {
    SmallPtrSet<BasicBlock *, 16> Seen;
    Value *V = FindPredValue(Pred, Reg, 0, Seen);
    if (!V) {
      return nullptr;
    }
    Values.push_back(V);
  }
  if (Values.size() == 1) {
    return Values.front();
  }
  bool Same = llvm::all_of(Values, [&](Value *V) { return V == Values[0]; });
  if (Same) {
    return Values[0];
  }

  Type *PhiTy = Values[0]->getType();
  const DataLayout &DL = RI->getModule()->getDataLayout();
  for (Value *V : Values) {
    PhiTy = MergeABIType(PhiTy, V->getType(), DL);
  }

  IRBuilder<> B(&*RI->getParent()->getFirstInsertionPt());
  PHINode *Phi = B.CreatePHI(PhiTy, Values.size(), "abi.ret");
  for (auto [Pred, V] : llvm::zip(Preds, Values)) {
    if (V->getType() != PhiTy) {
      IRBuilder<> PredB(Pred->getTerminator());
      V = CoerceValue(PredB, V, PhiTy, "abi.ret.coerce");
      if (!V) {
        Phi->eraseFromParent();
        return nullptr;
      }
    }
    Phi->addIncoming(V, Pred);
  }
  return Phi;
}

bool ReturnOperandIsOriginalMemoryArg(Function &F, ReturnInst &RI) {
  if (F.arg_size() < 3 || RI.getNumOperands() == 0) {
    return false;
  }
  Value *V = RI.getReturnValue();
  Value *MemArg = F.getArg(2);

  SmallPtrSet<Value *, 8> Visited;
  std::function<bool(Value *)> IsOriginalMemory = [&](Value *Candidate) {
    if (!Candidate || !Visited.insert(Candidate).second)
      return true;
    if (Candidate == MemArg)
      return true;

    if (auto *CB = dyn_cast<CallBase>(Candidate)) {
      if (CB->arg_size() >= 3)
        return IsOriginalMemory(CB->getArgOperand(2));
      if (CB->arg_size() > 0)
        return IsOriginalMemory(CB->getArgOperand(CB->arg_size() - 1));
      return false;
    }
    if (auto *PN = dyn_cast<PHINode>(Candidate)) {
      for (Value *Incoming : PN->incoming_values()) {
        if (!IsOriginalMemory(Incoming))
          return false;
      }
      return true;
    }
    if (auto *SI = dyn_cast<SelectInst>(Candidate)) {
      return IsOriginalMemory(SI->getTrueValue()) &&
             IsOriginalMemory(SI->getFalseValue());
    }
    return false;
  };

  return IsOriginalMemory(V);
}

void DebugCandidate(FunctionABISummary &S) {
  errs() << "[brighten-abi] candidate function: " << S.OriginalName << "\n";
}

void DebugLiveIns(FunctionABISummary &S) {
  errs() << "[brighten-abi] live-in: " << S.OriginalName << ": ";
  bool First = true;
  for (const ABIArgInfo &Arg : S.Args) {
    if (!First) {
      errs() << ", ";
    }
    First = false;
    errs() << GetRegisterName(Arg.Reg) << " " << TypeToString(Arg.Ty);
  }
  if (First) {
    errs() << "<none>";
  }
  errs() << "\n";
}

void DebugReturn(FunctionABISummary &S) {
  errs() << "[brighten-abi] return: " << S.OriginalName << ": "
         << GetReturnKindName(S.RetKind);
  if (S.RetTy) {
    errs() << " " << TypeToString(S.RetTy);
  }
  errs() << "\n";
}

} // namespace brighten_abi
