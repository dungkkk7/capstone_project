#ifndef BRIGHTEN_STATE_OFFSET_RESOLVER_H
#define BRIGHTEN_STATE_OFFSET_RESOLVER_H

#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

#include <climits>
#include <cstdint>
#include <optional>

namespace brighten_state_ssa {

using namespace llvm;

enum class StateBaseKind {
  Global,
  Arg0,
};

struct ResolvedStateAccess {
  uint64_t Offset;
  StateBaseKind Base;
};

// ===================================================================
// Signature check & lifted function classification
// ===================================================================

inline bool HasLiftedSignature(Function &F) {
  if (F.arg_size() < 3) return false;
  auto ArgIt = F.arg_begin();
  Type *StateTy = ArgIt++->getType();
  Type *PcTy    = ArgIt++->getType();
  Type *MemTy   = ArgIt++->getType();
  return StateTy->isPointerTy() && PcTy->isIntegerTy(64) &&
         MemTy->isPointerTy() && F.getReturnType()->isPointerTy();
}

inline bool IsLiftedFunction(Function &F) {
  StringRef Name = F.getName();
  bool LiftedName = Name.starts_with("sub_") ||
                    Name.starts_with("auto_sub_") ||
                    Name == "main_wrapper" ||
                    Name == "start_wrapper";
  return LiftedName && HasLiftedSignature(F);
}

// ===================================================================
// State base resolution
// ===================================================================

inline std::optional<StateBaseKind> ResolveStateBase(Value *Base, Function &F,
                                                     GlobalVariable *StateGV) {
  Base = Base->stripPointerCasts();
  while (auto *GA = dyn_cast<GlobalAlias>(Base))
    Base = GA->getAliasee()->stripPointerCasts();

  if (StateGV) {
    if (auto *GV = dyn_cast<GlobalVariable>(Base)) {
      if (GV == StateGV || GV->getName() == "__mcsema_reg_state")
        return StateBaseKind::Global;
    }
  }
  if (IsLiftedFunction(F)) {
    if (auto *Arg = dyn_cast<Argument>(Base)) {
      if (Arg->getParent() == &F && Arg->getArgNo() == 0)
        return StateBaseKind::Arg0;
    }
  }
  return std::nullopt;
}

// ===================================================================
// Resolve state offset (supporting Global & Arg0 bases)
// ===================================================================

inline std::optional<ResolvedStateAccess>
ResolveStateOffset(Value *Ptr, const DataLayout &DL, Function &F,
                   GlobalVariable *StateGV) {
  int64_t TotalOffset = 0;
  Value *Base = Ptr;

  while (true) {
    if (auto *GEP = dyn_cast<GEPOperator>(Base)) {
      APInt APOffset(64, 0);
      if (!GEP->accumulateConstantOffset(DL, APOffset))
        return std::nullopt;
      int64_t Add = APOffset.getSExtValue();
      if ((Add > 0 && TotalOffset > INT64_MAX - Add) ||
          (Add < 0 && TotalOffset < INT64_MIN - Add))
        return std::nullopt;
      TotalOffset += Add;
      Base = GEP->getPointerOperand();
      continue;
    }
    if (auto *BC = dyn_cast<BitCastOperator>(Base)) {
      Base = BC->getOperand(0);
      continue;
    }
    if (auto *GA = dyn_cast<GlobalAlias>(Base)) {
      Base = GA->getAliasee();
      continue;
    }
    break;
  }

  if (TotalOffset < 0) return std::nullopt;

  auto BaseKind = ResolveStateBase(Base, F, StateGV);
  if (!BaseKind) return std::nullopt;

  return ResolvedStateAccess{static_cast<uint64_t>(TotalOffset), *BaseKind};
}

// ===================================================================
// State escape boundary analysis
// ===================================================================

inline bool IsStatePointerLike(Value *V, Function &F, GlobalVariable *StateGV,
                               const DataLayout &DL) {
  if (!V->getType()->isPointerTy()) return false;
  if (ResolveStateBase(V, F, StateGV)) return true;
  return ResolveStateOffset(V, DL, F, StateGV).has_value();
}

inline bool CallMayAccessState(CallInst *CI, Function &Caller,
                               GlobalVariable *StateGV,
                               const DataLayout &DL) {
  if (CI->isInlineAsm()) return false;

  bool HasStateOperand = false;
  for (Use &Arg : CI->args()) {
    if (IsStatePointerLike(Arg.get(), Caller, StateGV, DL)) {
      HasStateOperand = true;
      break;
    }
  }

  Function *Callee = CI->getCalledFunction();
  if (HasStateOperand) return true;
  if (!Callee) return true;
  if (Callee->isDeclaration()) return false;
  return IsLiftedFunction(*Callee);
}

inline bool FunctionHasUnsupportedStateBoundary(Function &F,
                                                GlobalVariable *StateGV,
                                                const DataLayout &DL) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        if (CallMayAccessState(CI, F, StateGV, DL) && CI->isMustTailCall())
          return true;
      } else if (auto *II = dyn_cast<InvokeInst>(&I)) {
        for (Use &Arg : II->args()) {
          if (IsStatePointerLike(Arg.get(), F, StateGV, DL))
            return true;
        }
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        if (IsStatePointerLike(SI->getValueOperand(), F, StateGV, DL))
          return true;
      } else if (auto *RI = dyn_cast<ReturnInst>(&I)) {
        if (RI->getReturnValue() &&
            IsStatePointerLike(RI->getReturnValue(), F, StateGV, DL))
          return true;
      }
    }
  }
  return false;
}

} // namespace brighten_state_ssa

#endif // BRIGHTEN_STATE_OFFSET_RESOLVER_H
