#include "BrightenABIRecoveryPass.h"

#include "llvm/Support/raw_ostream.h"

namespace brighten_abi {

using namespace llvm;

bool BrightenABIRecoveryPass::NormalizeRegisterAccesses(
    ABIRecoveryContext &Ctx) {
  for (Function &F : Ctx.M) {
    if (!IsEligibleRemillFunction(F)) {
      continue;
    }

    auto Summary = std::make_unique<FunctionABISummary>();
    Summary->OriginalFn = &F;
    Summary->RemillFn = &F;
    Summary->OriginalName = F.getName().str();
    Summary->OriginalLinkage = F.getLinkage();
    Summary->Eligible = true;
    Summary->HasForbiddenInlineAsm = HasForbiddenInlineAsm(F);
    if (Summary->HasForbiddenInlineAsm) {
      Summary->SkipNative = true;
      Summary->SkipReason = "inline-asm";
    }

    FunctionABISummary *Raw = Summary.get();
    Ctx.OwnedSummaries[&F] = std::move(Summary);
    Ctx.Summaries.push_back(Raw);
    DebugCandidate(*Raw);
  }

  return false;
}

} // namespace brighten_abi

