#include "BrightenRepairPass.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Operator.h"

namespace brighten_repair {

using namespace llvm;

bool BrightenRepairPass::ProtectSetjmpCallers(Module &M) {
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration()) continue;

    bool CallsSetjmp = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          Value *CalleeVal = CI->getCalledOperand()->stripPointerCasts();
          if (auto *Callee = dyn_cast<Function>(CalleeVal)) {
            StringRef CalleeName = Callee->getName();
            if (CalleeName.contains("setjmp") || CalleeName.contains("sigsetjmp") || 
                Callee->hasFnAttribute(Attribute::ReturnsTwice)) {
              CallsSetjmp = true;
              break;
            }
          }
        }
      }
      if (CallsSetjmp) break;
    }

    if (CallsSetjmp) {
      // Add noinline and optnone to prevent LLVM optimizations from miscompiling returns_twice callers
      if (!F.hasFnAttribute(Attribute::NoInline)) {
        F.addFnAttr(Attribute::NoInline);
        Changed = true;
      }
      if (!F.hasFnAttribute(Attribute::OptimizeNone)) {
        F.addFnAttr(Attribute::OptimizeNone);
        Changed = true;
      }
      if (F.hasFnAttribute(Attribute::AlwaysInline)) {
        F.removeFnAttr(Attribute::AlwaysInline);
        Changed = true;
      }
    }
  }

  return Changed;
}

} // namespace brighten_repair
