#include "BrightenABIRecoveryPass.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_abi {

using namespace llvm;

static Value *BuildArgLoad(IRBuilder<> &B, Value *State, ABIArgInfo &Arg) {
  Value *Ptr = BuildStateRegisterPointer(B, State, Arg.Reg);
  if (!Ptr) {
    return nullptr;
  }
  Type *LoadTy = Arg.Ty->isPointerTy() ? B.getInt64Ty() : Arg.Ty;
  Value *V = B.CreateLoad(LoadTy, Ptr, (GetRegisterName(Arg.Reg) + ".mw").str());
  return CoerceValue(B, V, Arg.Ty, GetRegisterName(Arg.Reg));
}

bool BrightenABIRecoveryPass::RewriteMainWrapper(ABIRecoveryContext &Ctx) {
  Function *MW = Ctx.M.getFunction("main_wrapper");
  if (!MW) {
    return false;
  }

  FunctionABISummary *MainS = nullptr;
  CallInst *MainCall = nullptr;
  for (BasicBlock &BB : *MW) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI) continue;
      Function *Target = ResolveCalledFunction(CI->getCalledOperand());
      if (!Target) continue;

      MainS = FindSummary(Ctx, Target);
      if (MainS && MainS->NativeFn) {
        MainCall = CI;
        break;
      }
    }
    if (MainCall) break;
  }

  if (!MainCall || !MainS || !MainS->NativeFn) {
    return false;
  }

  bool Changed = false;
  IRBuilder<> B(MainCall);
  SmallVector<Value *, 12> Args;
  if (MainS->HiddenState) {
    Args.push_back(MainCall->arg_size() > 0 ? MainCall->getArgOperand(0) : UndefValue::get(B.getPtrTy()));
  }
  if (MainS->HiddenPC) {
    Args.push_back(MainCall->arg_size() > 1 ? MainCall->getArgOperand(1) : B.getInt64(0));
  }
  if (MainS->HiddenMemory) {
    Args.push_back(MainCall->arg_size() > 2 ? MainCall->getArgOperand(2) : UndefValue::get(B.getPtrTy()));
  }
  for (ABIArgInfo &Arg : MainS->Args) {
    Value *StatePtr = MainCall->arg_size() > 0 ? MainCall->getArgOperand(0) : MW->getArg(0);
    Value *V = BuildArgLoad(B, StatePtr, Arg);
    if (!V) {
      return Changed;
    }
    Args.push_back(V);
  }

  CallInst *NewCall =
      B.CreateCall(MainS->NativeFn, Args,
                   MainS->RetKind == ReturnKind::Void ? "" : "main.ret");
  NewCall->setCallingConv(MainS->NativeFn->getCallingConv());

  if (MainS->RetKind != ReturnKind::Void) {
    Value *StatePtr = MainCall->arg_size() > 0 ? MainCall->getArgOperand(0) : MW->getArg(0);
    Value *Ptr = BuildStateRegisterPointer(B, StatePtr,
                                           ABIReg::RAX);
    Value *I64 = CoerceValue(B, NewCall, B.getInt64Ty(), "main.ret.i64");
    if (Ptr && I64) {
      B.CreateStore(I64, Ptr);
    }
  }

  if (!MainCall->use_empty()) {
    Value *MemVal = MainCall->arg_size() > 2 ? MainCall->getArgOperand(2) : MW->getArg(2);
    MainCall->replaceAllUsesWith(MemVal);
  }
  MainCall->eraseFromParent();
  Changed = true;
  errs() << "[brighten-abi] callsite rewritten: caller=main_wrapper target="
         << MainS->NativeFn->getName() << "\n";

  return Changed;
}

} // namespace brighten_abi
