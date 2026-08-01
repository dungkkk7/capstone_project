#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_runtime {

using namespace llvm;

bool BrightenRuntimeHelperPass::VerifyNoUnresolvedRemillIntrinsics(Module &M) {
  for (Function &F : M) {
    if (IsRemillDecl(F)) {
      errs() << "[brighten-remill-runtime] unresolved (preserved): "
             << F.getName() << "\n";
    }
  }
  // Never fabricate zero/null/no-op semantics.  A live unresolved declaration
  // is intentionally left for the final native contract gate to reject.
  return false;
}

}  // namespace brighten_runtime
