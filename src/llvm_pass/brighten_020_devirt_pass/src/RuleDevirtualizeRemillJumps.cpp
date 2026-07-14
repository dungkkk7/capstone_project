#include "BrightenDevirtPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

static bool IsRemillJump(CallBase *CB, Function *RemillJump) {
  return RemillJump && ResolveCalledFunction(CB->getCalledOperand()) == RemillJump;
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

static CallInst *CreateLiftedDirectJump(IRBuilder<> &B, CallInst *Old,
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

bool BrightenDevirtPass::DevirtualizeRemillJumps(Module &M) {
  Function *RemillJump = M.getFunction("__remill_jump");
  if (!RemillJump) {
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
          if (IsRemillJump(CI, RemillJump)) {
            Worklist.push_back(CI);
          }
        } else if (auto *II = dyn_cast<InvokeInst>(&I)) {
          if (IsRemillJump(II, RemillJump)) {
            errs() << "[devirt] WARNING: remill invoke jump not lowered\n";
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
      if (LowerFiniteRemillPCSwitch(M, CI, RemillJump, true)) {
        Changed = true;
        continue;
      }
      errs() << "[devirt] INFO: dynamic remill jump preserved\n";
      continue;
    }

    Function *Target = FindLiftedSubroutineByPC(M, *PC);
    if (!Target) {
      // The ABI recovery dispatcher uses its default arm as the Remill
      // fallback: an unknown jump target returns the incoming memory token.
      // A proven zero PC therefore has an exact native lowering, rather than
      // being a reason to retain the dispatcher.  Do not apply this to an
      // unknown SSA PC; only the constant case is covered here.
      if (*PC == 0 && CI->arg_size() >= 3) {
        Value *Memory = CI->getArgOperand(2);
        if (!CI->use_empty())
          CI->replaceAllUsesWith(Memory);
        CI->eraseFromParent();
        Changed = true;
        errs() << "[devirt] lowered remill jump PC 0x0 -> dispatcher fallback\n";
        continue;
      }
      errs() << "[devirt] WARNING: unresolved constant __remill_jump PC = 0x"
             << Twine::utohexstr(*PC) << "\n";
      continue;
    }

    IRBuilder<> B(CI);
    Value *ResolvedPC =
        ConstantInt::get(CI->getArgOperand(1)->getType(), *PC);
    CallInst *NewCall = CreateLiftedDirectJump(B, CI, Target, ResolvedPC);
    if (!NewCall) {
      continue;
    }
    if (!CI->use_empty()) {
      CI->replaceAllUsesWith(NewCall);
    }
    CI->eraseFromParent();
    Changed = true;

    errs() << "[devirt] lowered remill jump PC 0x" << Twine::utohexstr(*PC)
           << " -> @" << Target->getName() << "\n";
  }

  return Changed;
}

} // namespace brighten_devirt
