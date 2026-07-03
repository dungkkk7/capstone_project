#include "BrightenDevirtPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

bool BrightenDevirtPass::CleanupCallbackThunks(Module &M) {
  SmallVector<Function *, 16> DeadFunctions;
  SmallVector<GlobalAlias *, 16> DeadAliases;
  SmallVector<GlobalVariable *, 16> DeadGlobals;

  for (Function &F : M) {
    if (!F.getName().starts_with("callback_sub_")) {
      continue;
    }
    if (F.use_empty()) {
      DeadFunctions.push_back(&F);
    } else {
      errs() << "[devirt] callback thunk still referenced: @" << F.getName()
             << "\n";
    }
  }

  for (GlobalAlias &Alias : M.aliases()) {
    if (Alias.getName().starts_with("callback_sub_") && Alias.use_empty()) {
      DeadAliases.push_back(&Alias);
    }
  }

  for (GlobalVariable &GV : M.globals()) {
    if (GV.getName().starts_with("callback_sub_") && GV.use_empty()) {
      DeadGlobals.push_back(&GV);
    }
  }

  for (GlobalAlias *Alias : DeadAliases) {
    Alias->eraseFromParent();
  }
  for (GlobalVariable *GV : DeadGlobals) {
    GV->eraseFromParent();
  }
  for (Function *F : DeadFunctions) {
    F->eraseFromParent();
  }

  return !DeadFunctions.empty() || !DeadAliases.empty() || !DeadGlobals.empty();
}

} // namespace brighten_devirt
