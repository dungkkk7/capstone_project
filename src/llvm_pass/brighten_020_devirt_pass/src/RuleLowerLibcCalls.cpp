#include "BrightenDevirtPass.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Attributes.h"

namespace brighten_devirt {

using namespace llvm;

bool BrightenDevirtPass::LowerLibcCalls(Module &M) {
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration()) continue;

    StringRef Name = F.getName();
    if (Name.starts_with("ext_")) {
      if (!F.hasFnAttribute(Attribute::AlwaysInline)) {
        F.addFnAttr(Attribute::AlwaysInline);
        Changed = true;
      }
    }
  }

  return Changed;
}

} // namespace brighten_devirt
