#include "BrightenDevirtPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

static bool IsKnownDispatcherName(StringRef Name) {
  return Name == "__remill_function_call" || Name == "__remill_jump" ||
         Name == "__remill_function_return" ||
         Name == "__lifter_refine_noop_call" ||
         Name == "__remill_missing_block" || Name == "__remill_error" ||
         Name == "__remill_async_hyper_call" ||
         Name == "__remill_sync_hyper_call";
}

bool BrightenDevirtPass::CleanupUnusedRemillDispatchers(Module &M) {
  SmallVector<Function *, 16> Dead;
  bool Changed = false;

  for (Function &F : M) {
    StringRef Name = F.getName();
    if (!IsKnownDispatcherName(Name) && !Name.starts_with("ext_")) {
      continue;
    }

    // Remill control helpers are implementation details, not program entry
    // points.  Their external linkage otherwise roots an unreachable
    // dispatcher/lifted-body SCC and makes every shared State access appear
    // live during the following recovery passes.  Internalization plus the
    // GlobalDCE scheduled by this plugin removes only SCCs not reachable from
    // a real module entry; genuinely used dynamic dispatchers remain intact.
    if (IsKnownDispatcherName(Name) && !F.isDeclaration() &&
        !F.hasLocalLinkage()) {
      F.setLinkage(GlobalValue::InternalLinkage);
      Changed = true;
    }

    if (F.use_empty()) {
      Dead.push_back(&F);
    } else if (IsKnownDispatcherName(Name)) {
      errs() << "[devirt] remill dispatcher still needed: @" << Name << "\n";
    }
  }

  for (Function *F : Dead) {
    F->eraseFromParent();
  }

  return Changed || !Dead.empty();
}

} // namespace brighten_devirt
