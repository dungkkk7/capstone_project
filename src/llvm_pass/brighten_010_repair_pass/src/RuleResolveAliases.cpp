#include "BrightenRepairPass.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/IRBuilder.h"
#include <vector>

namespace brighten_repair {

using namespace llvm;

bool BrightenRepairPass::ResolveAliases(Module &M) {
  bool Changed = false;
  GlobalVariable *RegState = M.getGlobalVariable("__mcsema_reg_state");
  if (!RegState) {
    return false;
  }

  if (RegState->isThreadLocal()) {
    RegState->setThreadLocal(false);
    Changed = true;
  }

  SmallVector<GlobalAlias *, 16> Aliases;
  for (GlobalAlias &GA : M.aliases()) {
    Aliases.push_back(&GA);
  }

  for (GlobalAlias *GA : Aliases) {
    Constant *Aliasee = GA->getAliasee();
    Constant *Replacement = Aliasee;

    if (auto *GEPOp = dyn_cast<GEPOperator>(Aliasee)) {
      Value *PtrOp = GEPOp->getPointerOperand();
      bool IsNullBase = false;
      if (isa<ConstantPointerNull>(PtrOp)) {
        IsNullBase = true;
      } else if (auto *CE = dyn_cast<ConstantExpr>(PtrOp)) {
        if (CE->isCast() && isa<ConstantPointerNull>(CE->getOperand(0))) {
          IsNullBase = true;
        }
      }

      if (IsNullBase) {
        Type *SrcTy = GEPOp->getSourceElementType();
        SmallVector<Constant *, 4> Idxs;
        for (auto It = GEPOp->idx_begin(); It != GEPOp->idx_end(); ++It) {
          Idxs.push_back(cast<Constant>(*It));
        }
        Constant *Base = RegState;
        if (Base->getType() != PtrOp->getType()) {
          Base = ConstantExpr::getBitCast(Base, PtrOp->getType());
        }
        Replacement = ConstantExpr::getGetElementPtr(SrcTy, Base, Idxs, GEPOp->isInBounds());
      }
    }

    GA->replaceAllUsesWith(Replacement);
    GA->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

bool BrightenRepairPass::PreserveCalleeSavedRegisters(Module &M) {
  bool Changed = false;
  GlobalVariable *RegState = M.getGlobalVariable("__mcsema_reg_state");
  if (!RegState) {
    return false;
  }

  // Callee-saved register offsets in State struct:
  // rbx: 2232
  // rbp: 2328
  // r12: 2408
  // r13: 2424
  // r14: 2440
  // r15: 2456
  static const uint64_t CalleeSavedOffsets[] = {
    2232, 2328, 2408, 2424, 2440, 2456
  };

  std::vector<CallInst *> GuestCalls;
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    if (F.getName() == "main" || F.getName() == "main_wrapper") continue;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          Function *Callee = CI->getCalledFunction();
          if (Callee && !Callee->isDeclaration()) {
            auto *FTy = Callee->getFunctionType();
            if (FTy->getNumParams() == 3 && FTy->getReturnType()->isPointerTy()) {
              if (FTy->getParamType(0)->isPointerTy() &&
                  FTy->getParamType(1)->isIntegerTy() &&
                  FTy->getParamType(2)->isPointerTy()) {
                GuestCalls.push_back(CI);
              }
            }
          }
        }
      }
    }
  }

  if (GuestCalls.empty()) {
    return false;
  }

  Type *Int64Ty = Type::getInt64Ty(M.getContext());
  Type *Int8Ty = Type::getInt8Ty(M.getContext());

  for (CallInst *CI : GuestCalls) {
    IRBuilder<> BuilderBefore(CI);
    
    std::vector<Value *> SavedVals;
    for (uint64_t Offset : CalleeSavedOffsets) {
      Value *GEP = BuilderBefore.CreateConstGEP1_64(Int8Ty, RegState, Offset);
      Value *Load = BuilderBefore.CreateAlignedLoad(Int64Ty, GEP, Align(8));
      SavedVals.push_back(Load);
    }

    IRBuilder<> BuilderAfter(CI->getNextNode());

    for (size_t i = 0; i < SavedVals.size(); ++i) {
      uint64_t Offset = CalleeSavedOffsets[i];
      Value *GEP = BuilderAfter.CreateConstGEP1_64(Int8Ty, RegState, Offset);
      BuilderAfter.CreateAlignedStore(SavedVals[i], GEP, Align(8));
    }

    Changed = true;
  }

  return Changed;
}

} // namespace brighten_repair
