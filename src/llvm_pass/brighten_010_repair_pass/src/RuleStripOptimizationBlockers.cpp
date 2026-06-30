// Strip optnone/noinline from ordinary lifted functions so later cleanup
// passes can actually simplify them. Special-case protection like setjmp
// callers can re-add blockers in later rules.
#include "BrightenRepairPass.h"

#include "llvm/IR/Attributes.h"

namespace brighten_repair {

using namespace llvm;

bool BrightenRepairPass::StripOptimizationBlockers(Module &M) {
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    if (F.hasFnAttribute(Attribute::OptimizeNone)) {
      F.removeFnAttr(Attribute::OptimizeNone);
      Changed = true;
    }

    if (F.hasFnAttribute(Attribute::NoInline)) {
      F.removeFnAttr(Attribute::NoInline);
      Changed = true;
    }
  }

  return Changed;
}

}  // namespace brighten_repair
