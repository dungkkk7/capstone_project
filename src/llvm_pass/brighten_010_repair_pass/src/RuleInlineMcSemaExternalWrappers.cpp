// Let LLVM inline small McSema external-call wrappers.
//
// McSema emits internal `ext_<pc>_<libcall>` wrappers that shuttle arguments
// through the guest register state, call the real libc symbol, then update RAX
// and RSP. They are marked noinline, which preserves an extra emulator-looking
// layer in the optimized binary. Marking only these internal wrappers
// alwaysinline exposes their state updates to O2 without touching lifted
// subroutines or external declarations.
#include "BrightenRepairPass.h"

#include "llvm/IR/Attributes.h"
#include "llvm/IR/Function.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static bool IsMcSemaExternalWrapper(const Function &F) {
  return !F.isDeclaration() && F.hasLocalLinkage() &&
         F.getName().starts_with("ext_");
}

}  // namespace

bool BrightenRepairPass::InlineMcSemaExternalWrappers(Module &M) {
  bool Changed = false;

  for (Function &F : M) {
    if (!IsMcSemaExternalWrapper(F)) {
      continue;
    }

    if (F.hasFnAttribute(Attribute::NoInline)) {
      F.removeFnAttr(Attribute::NoInline);
      Changed = true;
    }
    if (!F.hasFnAttribute(Attribute::AlwaysInline)) {
      F.addFnAttr(Attribute::AlwaysInline);
      Changed = true;
    }
    if (F.hasFnAttribute(Attribute::OptimizeNone)) {
      F.removeFnAttr(Attribute::OptimizeNone);
      Changed = true;
    }
  }

  return Changed;
}

}  // namespace brighten_repair
