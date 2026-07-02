#include "BrightenDevirtPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

static bool IsRemillCall(CallBase *CB, Function *RemillCall) {
  return RemillCall && ResolveCalledFunction(CB->getCalledOperand()) == RemillCall;
}

static Value *CoerceArg(IRBuilder<> &B, Value *V, Type *Ty) {
  if (V->getType() == Ty) {
    return V;
  }
  if (V->getType()->isIntegerTy() && Ty->isIntegerTy()) {
    unsigned FromBits = V->getType()->getIntegerBitWidth();
    unsigned ToBits = Ty->getIntegerBitWidth();
    if (FromBits < ToBits) {
      return B.CreateZExt(V, Ty);
    }
    if (FromBits > ToBits) {
      return B.CreateTrunc(V, Ty);
    }
  }
  if (V->getType()->isPointerTy() && Ty->isPointerTy()) {
    return B.CreateBitCast(V, Ty);
  }
  return V;
}

static CallInst *CreateLiftedDirectCall(IRBuilder<> &B, CallInst *Old,
                                        Function *Target, Value *ResolvedPC) {
  FunctionType *FTy = Target->getFunctionType();
  if (FTy->getNumParams() > Old->arg_size()) {
    errs() << "[devirt] ERROR: rewrite type mismatch for @" << Target->getName()
           << "\n";
    return nullptr;
  }
  if (!Old->use_empty() && FTy->getReturnType() != Old->getType()) {
    errs() << "[devirt] ERROR: rewrite return type mismatch for @"
           << Target->getName() << "\n";
    return nullptr;
  }

  SmallVector<Value *, 4> Args;
  for (unsigned I = 0, E = FTy->getNumParams(); I < E && I < Old->arg_size();
       ++I) {
    Value *Arg = (I == 1 && ResolvedPC) ? ResolvedPC : Old->getArgOperand(I);
    Args.push_back(CoerceArg(B, Arg, FTy->getParamType(I)));
  }

  CallInst *NewCall = B.CreateCall(FTy, Target, Args);
  NewCall->setCallingConv(Target->getCallingConv());
  NewCall->setTailCallKind(Old->getTailCallKind());
  return NewCall;
}

bool BrightenDevirtPass::DevirtualizeRemillFunctionCalls(Module &M) {
  Function *RemillCall = M.getFunction("__remill_function_call");
  if (!RemillCall) {
    return false;
  }

  const DataLayout &DL = M.getDataLayout();
  SmallVector<CallInst *, 64> Worklist;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          if (IsRemillCall(CI, RemillCall)) {
            Worklist.push_back(CI);
          }
        } else if (auto *II = dyn_cast<InvokeInst>(&I)) {
          if (IsRemillCall(II, RemillCall)) {
            errs() << "[devirt] WARNING: remill invoke call not lowered\n";
          }
        }
      }
    }
  }

  bool Changed = false;
  for (CallInst *CI : Worklist) {
    if (CI->arg_size() < 3) {
      continue;
    }

    Value *PCVal = CI->getArgOperand(1);
    auto PC = ExtractConstantPC(PCVal, DL);
    if (!PC) {
      if (LowerFiniteRemillPCSwitch(M, CI, RemillCall, false)) {
        Changed = true;
        continue;
      }
      errs() << "[devirt] INFO: dynamic remill call preserved\n";
      continue;
    }

    Function *Target = FindLiftedSubroutineByPC(M, *PC);
    if (!Target) {
      errs() << "[devirt] WARNING: unresolved constant __remill_function_call PC = 0x"
             << Twine::utohexstr(*PC) << "\n";
      continue;
    }

    IRBuilder<> B(CI);
    Value *ResolvedPC =
        ConstantInt::get(CI->getArgOperand(1)->getType(), *PC);
    CallInst *NewCall = CreateLiftedDirectCall(B, CI, Target, ResolvedPC);
    if (!NewCall) {
      continue;
    }
    if (!CI->use_empty()) {
      CI->replaceAllUsesWith(NewCall);
    }
    CI->eraseFromParent();
    Changed = true;

    errs() << "[devirt] lowered remill call PC 0x" << Twine::utohexstr(*PC)
           << " -> @" << Target->getName() << "\n";
  }

  return Changed;
}

} // namespace brighten_devirt
