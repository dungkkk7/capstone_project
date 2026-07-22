#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

// The devirt/ABI passes use this intrinsic only as an analysis marker while
// recovering the value returned in guest RAX.  It is not part of the native
// program semantics and must not survive the final lowering boundary: an
// operand bundle is still a hidden use of the lifted return value and keeps
// the old return-state protocol visible in otherwise native IR.
unsigned eraseBrightenReturnMarkers(Module &M, bool &Changed) {
  SmallVector<CallBase *, 64> Markers;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        if (!Callee || Callee->getIntrinsicID() != Intrinsic::sideeffect ||
            !CB->getOperandBundle("brighten_return_rax").has_value())
          continue;
        Markers.push_back(CB);
      }
    }
  }

  for (CallBase *Marker : Markers) {
    Marker->eraseFromParent();
    Changed = true;
  }
  return Markers.size();
}

unsigned eraseUnusedLiftedFunctions(Module &M, bool &Changed) {
  SmallVector<Function *, 32> Dead;
  for (Function &F : M) {
    if (F.isIntrinsic() || !F.use_empty())
      continue;
    if ((isLiftedFunctionName(F.getName()) ||
         isLiftedABI(F) ||
         F.getName().ends_with(".native") ||
         F.getName().starts_with("sub_") ||
         F.getName().starts_with("callback_sub_") ||
         F.getName() == ".init_proc_wrapper") &&
        F.getName() != "main")
      Dead.push_back(&F);
  }
  for (Function *F : Dead) {
    F->eraseFromParent();
    Changed = true;
  }
  return Dead.size();
}

unsigned eraseDeadInlineAsmTrampolines(Module &M, bool &Changed) {
  SmallVector<Function *, 16> Dead;
  for (Function &F : M) {
    if (F.isDeclaration() || F.getName() == "main" || !F.hasFnAttribute(Attribute::Naked))
      continue;
    bool HasInlineAsm = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CB = dyn_cast<CallBase>(&I))
          HasInlineAsm |= isa<InlineAsm>(CB->getCalledOperand());
      }
    }
    if (HasInlineAsm && F.use_empty())
      Dead.push_back(&F);
  }
  for (Function *F : Dead) {
    F->eraseFromParent();
    Changed = true;
  }
  return Dead.size();
}

unsigned eraseUnusedInlineAsmCalls(Module &M, bool &Changed) {
  SmallVector<CallBase *, 16> Dead;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        auto *Asm = CB ? dyn_cast<InlineAsm>(CB->getCalledOperand()) : nullptr;
        if (!CB || !Asm || Asm->hasSideEffects() || !CB->use_empty())
          continue;
        Dead.push_back(CB);
      }
    }
  }
  for (CallBase *CB : Dead) {
    CB->eraseFromParent();
    Changed = true;
  }
  return Dead.size();
}

unsigned eraseUnusedInternalGlobals(Module &M, bool &Changed) {
  SmallVector<GlobalVariable *, 32> Dead;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.hasLocalLinkage() && GV.use_empty())
      Dead.push_back(&GV);
  }
  for (GlobalVariable *GV : Dead) {
    GV->eraseFromParent();
    Changed = true;
  }
  return Dead.size();
}

unsigned eraseUnusedNativeDataArtifacts(Module &M, bool &Changed) {
  unsigned Removed = 0;

  auto HasOnlyRetentionUses = [&](Value *V, auto &&Self,
                                  SmallPtrSetImpl<Value *> &Seen) -> bool {
    if (!V || !Seen.insert(V).second)
      return true;
    for (User *U : V->users()) {
      if (auto *GV = dyn_cast<GlobalVariable>(U)) {
        if (GV->getName() == "llvm.used" ||
            GV->getName() == "llvm.compiler.used")
          continue;
      }
      if (isa<Constant>(U) && Self(cast<Value>(U), Self, Seen))
        continue;
      return false;
    }
    return true;
  };

  // Global-data recovery keeps temporary segment copies alive through
  // llvm.used until this final pass.  Drop only those temporary entries; do
  // not disturb unrelated compiler-used roots.
  for (StringRef UsedName : {StringRef("llvm.used"),
                             StringRef("llvm.compiler.used")}) {
    GlobalVariable *Used = M.getGlobalVariable(UsedName);
    auto *Array = Used ? dyn_cast<ConstantArray>(Used->getInitializer())
                       : nullptr;
    if (!Array)
      continue;
    SmallVector<Constant *, 32> Kept;
    for (Value *Operand : Array->operands()) {
      Value *Stripped = Operand->stripPointerCasts();
      auto *GV = dyn_cast<GlobalVariable>(Stripped);
      if (GV) {
        StringRef Name = GV->getName();
        bool TemporaryNativeCopy = Name.starts_with("native_data_");
        bool DeadLiftedSegment =
            GV->hasLocalLinkage() && !GV->hasSection() &&
            (Name.starts_with("seg_") ||
             Name.starts_with("native_residual_"));
        if (DeadLiftedSegment) {
          SmallPtrSet<Value *, 16> Seen;
          DeadLiftedSegment =
              HasOnlyRetentionUses(GV, HasOnlyRetentionUses, Seen);
        }
        if (TemporaryNativeCopy || DeadLiftedSegment)
          continue;
      }
      Kept.push_back(cast<Constant>(Operand));
    }
    if (Kept.size() == Array->getNumOperands())
      continue;
    if (Kept.empty()) {
      Used->eraseFromParent();
    } else {
      ArrayType *Ty = ArrayType::get(Array->getType()->getElementType(),
                                     Kept.size());
      auto *Replacement = new GlobalVariable(
          M, Ty, Used->isConstant(), Used->getLinkage(),
          ConstantArray::get(Ty, Kept), "");
      Replacement->copyAttributesFrom(Used);
      Replacement->takeName(Used);
      Used->eraseFromParent();
    }
    Changed = true;
  }

  if (Function *Mapper = M.getFunction("__brighten_native_data_pointer")) {
    if (Mapper->use_empty()) {
      Mapper->eraseFromParent();
      ++Removed;
      Changed = true;
    }
  }

  SmallVector<GlobalVariable *, 32> DeadGlobals;
  for (GlobalVariable &GV : M.globals()) {
    StringRef Name = GV.getName();
    if (!Name.starts_with("native_data_") && !Name.starts_with("seg_") &&
        !Name.starts_with("native_residual_"))
      continue;
    GV.removeDeadConstantUsers();
    if (GV.hasLocalLinkage() && !GV.hasSection() && GV.use_empty())
      DeadGlobals.push_back(&GV);
  }
  for (GlobalVariable *GV : DeadGlobals) {
    GV->eraseFromParent();
    ++Removed;
    Changed = true;
  }

  // LLVM keeps identified struct types in the module context even after their
  // LLVM keeps identified struct types in the module context even after their
  // last global/instruction reference is gone. Clear names of dead/unused
  // State, segment, and result struct types so textual IR remains clean.
  SmallPtrSet<Type *, 32> UsedTypes;
  for (GlobalVariable &GV : M.globals()) {
    UsedTypes.insert(GV.getValueType());
  }
  for (Function &F : M) {
    UsedTypes.insert(F.getReturnType());
    for (Argument &A : F.args())
      UsedTypes.insert(A.getType());
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        UsedTypes.insert(I.getType());
        if (auto *AI = dyn_cast<AllocaInst>(&I))
          UsedTypes.insert(AI->getAllocatedType());
        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I))
          UsedTypes.insert(GEP->getSourceElementType());
        for (Value *Op : I.operands())
          UsedTypes.insert(Op->getType());
      }
    }
  }

  for (StructType *ST : M.getIdentifiedStructTypes()) {
    if (!ST->hasName())
      continue;
    StringRef Name = ST->getName();
    if (Name.starts_with("seg_") || Name.contains("State") ||
        Name.contains("ArchState") || Name.contains("VectorReg") ||
        Name.contains("GPR") || Name.contains("MMX") ||
        Name.contains("FPU") || Name.contains("Segments") ||
        Name.contains("native_result") || Name.contains("state_result")) {
      if (!UsedTypes.count(ST))
        ST->setName("");
    }
  }
  return Removed;
}

} // namespace brighten_native_cleanup
