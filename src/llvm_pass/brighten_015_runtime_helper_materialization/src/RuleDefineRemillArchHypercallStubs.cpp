#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include "llvm/Support/raw_ostream.h"

namespace brighten_runtime {

using namespace llvm;

bool BrightenRuntimeHelperPass::DefineRemillArchHypercallStubs(Module &M) {
  for (Function &F : M) {
    if (!IsRemillDecl(F)) {
      continue;
    }
    StringRef Name = F.getName();
    if (HasPrefixAny(Name, {"__remill_x86_", "__remill_amd64_",
                            "__remill_aarch64_", "__remill_aarch32_",
                            "__remill_sparc_", "__remill_ppc_"})) {
      errs() << "[brighten-remill-runtime] unresolved architecture helper: "
             << Name << "\n";
    }
  }
  return false;
}

}  // namespace brighten_runtime
