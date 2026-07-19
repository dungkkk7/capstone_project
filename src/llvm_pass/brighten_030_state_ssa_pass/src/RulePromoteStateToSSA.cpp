#include "BrightenStateSSAPass.h"
#include "StateOffsetResolver.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Metadata.h"

#include <optional>
#include <limits>
#include <algorithm>

namespace brighten_state_ssa {

using namespace llvm;

static Value *buildStateFieldGEP(IRBuilder<> &B, Value *StatePtr, unsigned offset, Type *Ty) {
  return B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, offset);
}

bool BrightenStateSSAPass::PromoteStateToSSA(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  LLVMContext &Ctx = M.getContext();

  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");

  for (Function &F : M) {
    // An arbitrary native function can also have a first pointer argument and
    // a large constant GEP.  Treating that pointer as Remill State corrupts
    // unrelated application memory, so promotion is restricted to the
    // canonical lifted ABI.
    if (F.isDeclaration() || !IsLiftedFunction(F)) continue;

    bool HasUnsupportedCallBoundary = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (isa<InvokeInst>(I) || isa<CallBrInst>(I)) {
          HasUnsupportedCallBoundary = true;
          break;
        }
        if (auto *CI = dyn_cast<CallInst>(&I); CI && CI->isMustTailCall()) {
          HasUnsupportedCallBoundary = true;
          break;
        }
      }
      if (HasUnsupportedCallBoundary) break;
    }
    if (HasUnsupportedCallBoundary) continue;

    struct FieldInfo {
      unsigned offset;
      Type *type = nullptr;
      unsigned max_access_size = 0;
      SmallVector<LoadInst *, 4> loads;
      SmallVector<StoreInst *, 4> stores;
    };

    DenseMap<unsigned, FieldInfo> fields;
    DenseSet<unsigned> unsupported_fields;
    std::optional<StateBaseKind> FunctionBase;
    bool MixedStateBases = false;
    bool UnsupportedStateAccess = false;

    auto IsStateRootedPointer = [&](Value *Ptr) {
      Value *Root = Ptr;
      while (true) {
        Root = Root->stripPointerCasts();
        if (auto *GEP = dyn_cast<GEPOperator>(Root)) {
          Root = GEP->getPointerOperand();
          continue;
        }
        if (auto *GA = dyn_cast<GlobalAlias>(Root)) {
          Root = GA->getAliasee();
          continue;
        }
        break;
      }
      if (StateGV && Root == StateGV)
        return true;
      return F.arg_size() && Root == F.getArg(0);
    };

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          auto Resolved = ResolveStateOffset(LI->getPointerOperand(), DL, F, StateGV);
          if (Resolved &&
              Resolved->Offset <= std::numeric_limits<unsigned>::max()) {
            unsigned u_off = static_cast<unsigned>(Resolved->Offset);
            if (!FunctionBase) FunctionBase = Resolved->Base;
            else if (*FunctionBase != Resolved->Base) MixedStateBases = true;
            if (LI->isVolatile() || LI->isAtomic()) {
              unsupported_fields.insert(u_off);
              UnsupportedStateAccess = true;
              continue;
            }
            auto &info = fields[u_off];
            info.offset = u_off;
            unsigned sz = DL.getTypeStoreSize(LI->getType());
            if (sz > info.max_access_size) {
              info.max_access_size = sz;
              info.type = LI->getType();
            }
            info.loads.push_back(LI);
          } else if (IsStateRootedPointer(LI->getPointerOperand()))
            UnsupportedStateAccess = true;
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          auto Resolved = ResolveStateOffset(SI->getPointerOperand(), DL, F, StateGV);
          if (Resolved &&
              Resolved->Offset <= std::numeric_limits<unsigned>::max()) {
            unsigned u_off = static_cast<unsigned>(Resolved->Offset);
            if (!FunctionBase) FunctionBase = Resolved->Base;
            else if (*FunctionBase != Resolved->Base) MixedStateBases = true;
            if (SI->isVolatile() || SI->isAtomic()) {
              unsupported_fields.insert(u_off);
              UnsupportedStateAccess = true;
              continue;
            }
            auto &info = fields[u_off];
            info.offset = u_off;
            unsigned sz = DL.getTypeStoreSize(SI->getValueOperand()->getType());
            if (sz > info.max_access_size) {
              info.max_access_size = sz;
              info.type = SI->getValueOperand()->getType();
            }
            info.stores.push_back(SI);
          } else if (IsStateRootedPointer(SI->getPointerOperand()))
            UnsupportedStateAccess = true;
        }
      }
    }

    if (MixedStateBases || UnsupportedStateAccess || !FunctionBase) continue;

    // Build connected byte-interval components.  Every overlapping view in a
    // component shares one integer backing object, so a partial write remains
    // coherent with every wider/narrower alias.
    for (unsigned Offset : unsupported_fields)
      fields.erase(Offset);
    if (fields.empty()) continue;

    SmallVector<unsigned, 32> OrderedOffsets;
    for (const auto &Pair : fields)
      OrderedOffsets.push_back(Pair.first);
    llvm::sort(OrderedOffsets);
    DenseMap<unsigned, FieldInfo> MergedFields;
    bool InvalidComponent = false;
    for (unsigned Offset : OrderedOffsets) {
      FieldInfo &Source = fields[Offset];
      uint64_t SourceEnd = uint64_t(Offset) + Source.max_access_size;
      if (Source.max_access_size == 0) {
        InvalidComponent = true;
        break;
      }
      unsigned ComponentBegin = Offset;
      if (!MergedFields.empty()) {
        unsigned PreviousBegin = 0;
        bool FoundPrevious = false;
        for (const auto &Pair : MergedFields)
          if (!FoundPrevious || Pair.first > PreviousBegin) {
            PreviousBegin = Pair.first;
            FoundPrevious = true;
          }
        FieldInfo &Previous = MergedFields[PreviousBegin];
        uint64_t PreviousEnd = uint64_t(Previous.offset) +
                               Previous.max_access_size;
        if (uint64_t(Offset) < PreviousEnd)
          ComponentBegin = PreviousBegin;
      }
      FieldInfo &Target = MergedFields[ComponentBegin];
      if (Target.max_access_size == 0)
        Target.offset = ComponentBegin;
      uint64_t TargetEnd = std::max(
          uint64_t(Target.offset) + Target.max_access_size, SourceEnd);
      if (TargetEnd - Target.offset > 4096) {
        InvalidComponent = true;
        break;
      }
      Target.max_access_size = unsigned(TargetEnd - Target.offset);
      Target.loads.append(Source.loads.begin(), Source.loads.end());
      Target.stores.append(Source.stores.begin(), Source.stores.end());
    }
    if (InvalidComponent) continue;
    fields = std::move(MergedFields);
    if (fields.empty()) continue;

    bool InvalidAccessType = false;
    auto ValidateType = [&](Type *Ty) {
      TypeSize StoreSize = DL.getTypeStoreSize(Ty);
      TypeSize BitSize = DL.getTypeSizeInBits(Ty);
      return Ty->isFirstClassType() && !Ty->isAggregateType() &&
             !StoreSize.isScalable() && !BitSize.isScalable() &&
             StoreSize.getFixedValue() != 0 &&
             StoreSize.getFixedValue() <= 4096 &&
             BitSize.getFixedValue() == StoreSize.getFixedValue() * 8;
    };
    for (const auto &Pair : fields) {
      for (LoadInst *LI : Pair.second.loads)
        InvalidAccessType |= !ValidateType(LI->getType());
      for (StoreInst *SI : Pair.second.stores)
        InvalidAccessType |= !ValidateType(SI->getValueOperand()->getType());
    }
    if (InvalidAccessType) continue;

    Value *StatePtr = *FunctionBase == StateBaseKind::Arg0
                          ? static_cast<Value *>(F.getArg(0))
                          : static_cast<Value *>(StateGV);
    if (!StatePtr) continue;

    // Create allocas in the entry block
    IRBuilder<> EntryBuilder(&F.getEntryBlock().front());
    DenseMap<unsigned, AllocaInst *> field_allocas;

    for (auto &pair : fields) {
      unsigned offset = pair.first;
      auto &info = pair.second;

      // Force type to be integer of maximum access size
      Type *AllocaTy = Type::getIntNTy(Ctx, info.max_access_size * 8);
      info.type = AllocaTy;

      AllocaInst *Alloca = EntryBuilder.CreateAlloca(AllocaTy, nullptr, "state_" + std::to_string(offset));
      Alloca->setMetadata(
          "brighten.state.offset",
          MDNode::get(Ctx, ConstantAsMetadata::get(
                               ConstantInt::get(Type::getInt64Ty(Ctx), offset))));
      field_allocas[offset] = Alloca;

      // Initialize alloca from state
      IRBuilder<> B(Alloca->getNextNode());
      Value *GEP = buildStateFieldGEP(B, StatePtr, offset, AllocaTy);
      Value *InitVal = B.CreateAlignedLoad(AllocaTy, GEP, Align(1),
                                           "state_init");
      B.CreateStore(InitVal, Alloca);
    }

    // Replace loads
    for (auto &pair : fields) {
      unsigned offset = pair.first;
      auto &info = pair.second;
      AllocaInst *Alloca = field_allocas[offset];

      for (LoadInst *LI : info.loads) {
        IRBuilder<> B(LI);
        Value *Loaded = B.CreateLoad(info.type, Alloca);
        auto Resolved = ResolveStateOffset(LI->getPointerOperand(), DL, F,
                                           StateGV);
        if (!Resolved || Resolved->Offset < offset)
          report_fatal_error("validated State load lost byte offset");
        Type *LITy = LI->getType();
        unsigned AccessBits = unsigned(DL.getTypeStoreSize(LITy) * 8);
        unsigned StorageBits = info.max_access_size * 8;
        uint64_t RelativeByte = DL.isLittleEndian()
                                    ? Resolved->Offset - offset
                                    : uint64_t(offset) + info.max_access_size -
                                          (Resolved->Offset + AccessBits / 8);
        unsigned Shift = unsigned(RelativeByte * 8);
        Value *Bits = Loaded;
        if (Shift)
          Bits = B.CreateLShr(Bits, Shift, "state.extract.shift");
        if (AccessBits != StorageBits)
          Bits = B.CreateTrunc(Bits, Type::getIntNTy(Ctx, AccessBits),
                               "state.extract");
        Value *Replacement = nullptr;
        if (LITy->isIntegerTy()) {
          Replacement = Bits;
        } else if (LITy->isPointerTy()) {
          Replacement = B.CreateIntToPtr(Bits, LITy);
        } else {
          Replacement = B.CreateBitCast(Bits, LITy);
        }

        LI->replaceAllUsesWith(Replacement);
        LI->eraseFromParent();
      }
    }

    // Replace stores
    for (auto &pair : fields) {
      unsigned offset = pair.first;
      auto &info = pair.second;
      AllocaInst *Alloca = field_allocas[offset];

      for (StoreInst *SI : info.stores) {
        IRBuilder<> B(SI);
        Value *StoredVal = SI->getValueOperand();
        Type *SITy = StoredVal->getType();
        auto Resolved = ResolveStateOffset(SI->getPointerOperand(), DL, F,
                                           StateGV);
        if (!Resolved || Resolved->Offset < offset)
          report_fatal_error("validated State store lost byte offset");

        Value *IntStoredVal = nullptr;
        if (SITy->isIntegerTy()) {
          IntStoredVal = StoredVal;
        } else if (SITy->isPointerTy()) {
          IntStoredVal = B.CreatePtrToInt(StoredVal, Type::getIntNTy(Ctx, DL.getTypeStoreSize(SITy) * 8));
        } else {
          Type *IntTy = Type::getIntNTy(Ctx, DL.getTypeStoreSize(SITy) * 8);
          IntStoredVal = B.CreateBitCast(StoredVal, IntTy);
        }

        unsigned val_bits = DL.getTypeStoreSize(SITy) * 8;
        unsigned alloca_bits = info.max_access_size * 8;
        uint64_t RelativeByte = DL.isLittleEndian()
                                    ? Resolved->Offset - offset
                                    : uint64_t(offset) + info.max_access_size -
                                          (Resolved->Offset + val_bits / 8);
        unsigned Shift = unsigned(RelativeByte * 8);

        if (val_bits == alloca_bits && Shift == 0) {
          B.CreateStore(IntStoredVal, Alloca);
        } else {
          Value *Curr = B.CreateLoad(info.type, Alloca);
          APInt FieldMask = APInt::getBitsSet(alloca_bits, Shift,
                                             Shift + val_bits);
          APInt MaskValue = ~FieldMask;
          Value *Mask = ConstantInt::get(info.type, MaskValue);
          Value *Cleared = B.CreateAnd(Curr, Mask);
          Value *ZextVal = val_bits == alloca_bits
                               ? IntStoredVal
                               : B.CreateZExt(IntStoredVal, info.type);
          if (Shift)
            ZextVal = B.CreateShl(ZextVal, Shift);
          Value *NewVal = B.CreateOr(Cleared, ZextVal);
          B.CreateStore(NewVal, Alloca);
        }

        SI->eraseFromParent();
      }
    }

    // Flush/reload around calls
    for (BasicBlock &BB : F) {
      for (auto InstIt = BB.begin(); InstIt != BB.end(); ) {
        Instruction &I = *InstIt++;
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm()) continue;

        Function *Callee = CI->getCalledFunction();
        if (Callee) {
          // Skip libc calls and declarations unless they take State parameter
          bool takes_state = false;
          for (auto &arg : CI->args()) {
            if (arg.get() == StatePtr || arg.get() == StateGV) { takes_state = true; break; }
          }
          if (Callee->isDeclaration() && !takes_state) {
            continue;
          }
        }

        if (CI->arg_size() < 1) continue;
        // Flush before call
        {
          IRBuilder<> B(CI);
          for (auto &pair : fields) {
            unsigned offset = pair.first;
            auto &info = pair.second;
            AllocaInst *Alloca = field_allocas[offset];
            Value *Val = B.CreateLoad(info.type, Alloca);
            Value *GEP = buildStateFieldGEP(B, StatePtr, offset, info.type);
            B.CreateAlignedStore(Val, GEP, Align(1));
          }
        }

        // Reload after call
        {
          IRBuilder<> B(CI->getNextNode());
          for (auto &pair : fields) {
            unsigned offset = pair.first;
            auto &info = pair.second;
            AllocaInst *Alloca = field_allocas[offset];
            Value *GEP = buildStateFieldGEP(B, StatePtr, offset, info.type);
            Value *Val = B.CreateAlignedLoad(info.type, GEP, Align(1));
            B.CreateStore(Val, Alloca);
          }
        }
      }
    }

    // Flush before returns
    for (BasicBlock &BB : F) {
      Instruction *Term = BB.getTerminator();
      if (auto *RI = dyn_cast<ReturnInst>(Term)) {
        IRBuilder<> B(RI);
        for (auto &pair : fields) {
          unsigned offset = pair.first;
          auto &info = pair.second;
          AllocaInst *Alloca = field_allocas[offset];
          Value *Val = B.CreateLoad(info.type, Alloca);
          Value *GEP = buildStateFieldGEP(B, StatePtr, offset, info.type);
          B.CreateAlignedStore(Val, GEP, Align(1));
        }
      }
    }

    Changed = true;
  }

  return Changed;
}

} // namespace brighten_state_ssa
