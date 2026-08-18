#include "BrightenDevirtPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

namespace {

static bool IsRemillJump(CallBase *CB, Function *RemillJump) {
  return RemillJump && ResolveCalledFunction(CB->getCalledOperand()) == RemillJump;
}

static Value *CoerceLiftedArgument(IRBuilder<> &B, Value *V, Type *Ty) {
  if (V->getType() == Ty)
    return V;
  if (V->getType()->isPointerTy() && Ty->isPointerTy()) {
    auto *From = cast<PointerType>(V->getType());
    auto *To = cast<PointerType>(Ty);
    if (From->getAddressSpace() != To->getAddressSpace())
      return nullptr;
    return B.CreateBitCast(V, Ty, "devirt.jump.arg.cast");
  }
  if (V->getType()->isIntegerTy() && Ty->isIntegerTy()) {
    unsigned FromBits = V->getType()->getIntegerBitWidth();
    unsigned ToBits = Ty->getIntegerBitWidth();
    if (FromBits == ToBits)
      return V;
    return FromBits < ToBits ? B.CreateZExt(V, Ty, "devirt.jump.arg.zext")
                             : B.CreateTrunc(V, Ty, "devirt.jump.arg.trunc");
  }
  return nullptr;
}

static CallInst *CreateLiftedDirectJump(IRBuilder<> &B, CallInst *Old,
                                        Function *Target, Value *ResolvedPC) {
  FunctionType *FTy = Target->getFunctionType();
  if (FTy->isVarArg() || FTy->getNumParams() != Old->arg_size())
    return nullptr;
  if (!Old->use_empty() && FTy->getReturnType() != Old->getType())
    return nullptr;

  SmallVector<Value *, 4> Args;
  for (unsigned I = 0, E = FTy->getNumParams(); I < E; ++I) {
    Value *Arg = (I == 1 && ResolvedPC) ? ResolvedPC : Old->getArgOperand(I);
    Value *Coerced = CoerceLiftedArgument(B, Arg, FTy->getParamType(I));
    if (!Coerced)
      return nullptr;
    Args.push_back(Coerced);
  }

  CallInst *NewCall = B.CreateCall(FTy, Target, Args, Old->getName());
  NewCall->setCallingConv(Target->getCallingConv());
  NewCall->setTailCallKind(Old->getTailCallKind());
  NewCall->setDebugLoc(Old->getDebugLoc());
  return NewCall;
}

} // namespace

bool BrightenDevirtPass::DevirtualizeRemillJumps(Module &M) {
  Function *RemillJump = M.getFunction("__remill_jump");
  if (!RemillJump)
    return false;

  const DataLayout &DL = M.getDataLayout();
  SmallVector<CallInst *, 64> Worklist;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          if (IsRemillJump(CI, RemillJump))
            Worklist.push_back(CI);
        } else if (auto *II = dyn_cast<InvokeInst>(&I)) {
          if (IsRemillJump(II, RemillJump))
            errs() << "[devirt] remill invoke jump preserved\n";
        }
      }
    }
  }

  bool Changed = false;
  for (CallInst *CI : Worklist) {
    if (!CI->getParent() || CI->arg_size() < 3)
      continue;
    Value *PCVal = CI->getArgOperand(1);
    auto PC = ExtractConstantPC(PCVal, DL);
    if (!PC) {
      if (LowerFiniteRemillPCSwitch(M, CI, RemillJump, true))
        Changed = true;
      continue;
    }

    Function *Target = FindLiftedSubroutineByPC(M, *PC);
    if (!Target) {
      errs() << "[devirt] unresolved constant jump PC 0x"
             << Twine::utohexstr(*PC) << "\n";
      continue;
    }

    IRBuilder<> B(CI);
    Value *ResolvedPC = ConstantInt::get(PCVal->getType(), *PC);
    CallInst *NewCall = CreateLiftedDirectJump(B, CI, Target, ResolvedPC);
    if (!NewCall)
      continue;
    if (!CI->use_empty())
      CI->replaceAllUsesWith(NewCall);
    CI->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_devirt
