#include "BrightenDevirtPass.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Function.h"
#include <string>

namespace brighten_devirt {

using namespace llvm;

Function *FindLiftedSubroutineByPC(Module &M, uint64_t PC) {
  std::string Prefix = (Twine("sub_") + Twine::utohexstr(PC)).str();
  if (auto *F = M.getFunction(Prefix)) {
    if (!F->isDeclaration()) return F;
  }
  std::string PrefixWithUnderscore = Prefix + "_";
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    if (F.getName().starts_with(PrefixWithUnderscore)) {
      return &F;
    }
  }
  return nullptr;
}

} // namespace brighten_devirt
