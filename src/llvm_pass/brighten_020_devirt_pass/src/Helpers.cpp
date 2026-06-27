#include "BrightenDevirtPass.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Function.h"
#include <string>

namespace brighten_devirt {

using namespace llvm;

Function *FindLiftedSubroutineByPC(Module &M, uint64_t PC) {
  std::string Name = (Twine("sub_") + Twine::utohexstr(PC)).str();
  auto *F = M.getFunction(Name);
  if (F && !F->isDeclaration()) {
    return F;
  }
  return nullptr;
}

} // namespace brighten_devirt
