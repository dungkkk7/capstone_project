#include "BrightenDevirtPass.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"

namespace brighten_devirt {

using namespace llvm;

bool BrightenDevirtPass::DevirtualizeRemillCalls(Module &M) {
  bool Changed = false;

  Function *RemillCall = M.getFunction("__remill_function_call");
  Function *RemillJump = M.getFunction("__remill_jump");

  if (!RemillCall && !RemillJump) {
    return false;
  }

  SmallVector<CallInst *, 64> CallsToRewrite;

  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          Value *CalleeVal = CI->getCalledOperand()->stripPointerCasts();
          Function *Callee = dyn_cast<Function>(CalleeVal);
          if (Callee == RemillCall || Callee == RemillJump) {
            // Check if the 2nd argument (PC) is a constant integer
            if (CI->arg_size() >= 2) {
              if (auto *PCVal = dyn_cast<ConstantInt>(CI->getArgOperand(1))) {
                CallsToRewrite.push_back(CI);
              }
            }
          }
        }
      }
    }
  }

  for (CallInst *CI : CallsToRewrite) {
    auto *PCVal = cast<ConstantInt>(CI->getArgOperand(1));
    uint64_t PC = PCVal->getZExtValue();

    Function *Target = FindLiftedSubroutineByPC(M, PC);
    if (Target) {
      IRBuilder<> B(CI);
      // Construct the arguments: (state, PC, mem)
      Value *State = CI->getArgOperand(0);
      Value *Mem = CI->getArgOperand(2);
      
      SmallVector<Value *, 3> Args;
      Args.push_back(State);
      Args.push_back(PCVal);
      Args.push_back(Mem);

      CallInst *NewCall = B.CreateCall(Target->getFunctionType(), Target, Args);
      NewCall->setCallingConv(CI->getCallingConv());
      NewCall->setTailCall(CI->isTailCall());

      CI->replaceAllUsesWith(NewCall);
      CI->eraseFromParent();
      Changed = true;
    }
  }

  return Changed;
}

} // namespace brighten_devirt
