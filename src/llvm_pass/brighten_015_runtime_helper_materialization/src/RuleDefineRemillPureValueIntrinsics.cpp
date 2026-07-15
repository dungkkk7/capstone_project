#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include "llvm/Support/raw_ostream.h"

namespace brighten_runtime {

using namespace llvm;

bool BrightenRuntimeHelperPass::DefineRemillPureValueIntrinsics(Module &M) {
  // The old implementation returned an arbitrary same-typed argument (or
  // zero) for flag/FPU/undefined helpers.  Those functions are not identities,
  // and choosing zero silently changes branches and floating-point behavior.
  // Preserve declarations until a helper has an exact lowering.
  for (Function &F : M) {
    if (!IsRemillDecl(F)) {
      continue;
    }
    StringRef Name = F.getName();
    if (Name.starts_with("__remill_undefined_") ||
        Name == "__remill_fpu_exception_test_and_clear" ||
        Name.starts_with("__remill_fpu_") ||
        Name.starts_with("__remill_compare_") ||
        Name.starts_with("__remill_flag_computation_"))
      errs() << "[brighten-remill-runtime] exact value lowering unavailable: "
             << Name << "\n";
  }
  return false;
}

}  // namespace brighten_runtime
