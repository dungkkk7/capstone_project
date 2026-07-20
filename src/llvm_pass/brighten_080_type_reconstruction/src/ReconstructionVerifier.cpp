#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_type {

using namespace llvm;

bool PrevalidateTypePlan(InferredTypePlan &Plan, TypeReconstructionContext &Ctx) {
  if (!Plan.ProposedRootType) {
    Plan.RejectionReasons.push_back("no-proposed-type");
    return false;
  }

  if (!Plan.ProposedRootType->isSized()) {
    Plan.RejectionReasons.push_back("proposed-type-not-sized");
    return false;
  }

  uint64_t ProposedSize = Ctx.DL.getTypeAllocSize(Plan.ProposedRootType).getFixedValue();
  if (ProposedSize != Plan.Candidate->ObjectSize) {
    Plan.RejectionReasons.push_back("proposed-size-mismatch: expected " +
                                    std::to_string(Plan.Candidate->ObjectSize) +
                                    ", got " + std::to_string(ProposedSize));
    return false;
  }

  return true;
}

bool VerifyReconstruction(TypeReconstructionContext &Ctx) {
  if (Ctx.Verify) {
    std::string ErrorStr;
    raw_string_ostream OS(ErrorStr);
    if (verifyModule(Ctx.M, &OS)) {
      errs() << "VERIFIER ERROR after Type Reconstruction: " << ErrorStr << "\n";
      Ctx.Report.VerificationFailures++;
      return false;
    }
  }
  return true;
}

} // namespace brighten_type
