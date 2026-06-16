// Drop unused Remill/McSema runtime helper definitions.
//
// These helpers are emitted as externally-visible functions even when all
// control-flow calls were resolved away. Keeping them bloats the recompiled
// binary and IDA function list. Erase known zero-use helpers; internalize the
// live init helper so the later O2 GlobalDCE can drop it after inlining.
#include "BrightenRepairPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static bool IsPrunableHelperName(StringRef Name) {
  return Name == "__remill_function_call" ||
         Name == "__remill_function_return" ||
         Name == "__remill_jump" ||
         Name == "__remill_missing_block" ||
         Name == "__remill_async_hyper_call" ||
         Name == "__remill_error" ||
         Name == "__mcsema_detach_call_value" ||
         Name == "__mcsema_init_reg_state" ||
         Name == "__mcsema_debug_get_reg_state";
}

}  // namespace

bool BrightenRepairPass::PruneUnusedRemillMcSemaHelpers(Module &M) {
  SmallVector<Function *, 8> ToErase;
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration() || !IsPrunableHelperName(F.getName())) {
      continue;
    }
    if (!F.use_empty()) {
      if (F.getName() == "__mcsema_init_reg_state" && !F.hasLocalLinkage()) {
        F.setLinkage(GlobalValue::InternalLinkage);
        F.setVisibility(GlobalValue::DefaultVisibility);
        F.setDSOLocal(true);
        Changed = true;
      }
      continue;
    }
    ToErase.push_back(&F);
  }

  for (Function *F : ToErase) {
    F->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

}  // namespace brighten_repair
