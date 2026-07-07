#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/Support/raw_ostream.h"

#include <algorithm>

namespace brighten_global {

using namespace llvm;

static bool Overlaps(const ObjectCandidate &A, const ObjectCandidate &B) {
  return A.Begin < B.End && B.Begin < A.End;
}

static unsigned GetKindPriority(ObjectKind Kind) {
  switch (Kind) {
  case ObjectKind::JumpTable: return 5;
  case ObjectKind::PointerTable: return 4;
  case ObjectKind::StringLiteral: return 3;
  case ObjectKind::Array: return 2;
  case ObjectKind::Scalar: return 1;
  default: return 0;
  }
}

bool BrightenGlobalDataRecoveryPass::ResolveObjectConflicts(
    GlobalDataContext &Ctx) {
  bool Changed = false;

  // Sort proven candidates by confidence & kind priority
  std::sort(Ctx.Candidates.begin(), Ctx.Candidates.end(),
            [](const std::unique_ptr<ObjectCandidate> &A,
               const std::unique_ptr<ObjectCandidate> &B) {
              if (A->Confidence != B->Confidence)
                return A->Confidence > B->Confidence;
              unsigned PriA = GetKindPriority(A->Kind);
              unsigned PriB = GetKindPriority(B->Kind);
              if (PriA != PriB)
                return PriA > PriB;
              uint64_t LenA = A->End - A->Begin;
              uint64_t LenB = B->End - B->Begin;
              if (LenA != LenB)
                return LenA > LenB;
              return A->Begin < B->Begin;
            });

  std::vector<std::unique_ptr<ObjectCandidate>> Resolved;

  for (auto &Cand : Ctx.Candidates) {
    const ObjectCandidate *ConflictingActive = nullptr;
    for (const auto &Active : Resolved) {
      if (Overlaps(*Cand, *Active)) {
        ConflictingActive = Active.get();
        break;
      }
    }

    if (!ConflictingActive) {
      Resolved.push_back(std::move(Cand));
    } else {
      std::string Reason = "candidate=" + Cand->Name +
                           " range=[0x" + Twine::utohexstr(Cand->Begin).str() + ",0x" + Twine::utohexstr(Cand->End).str() + ")"
                           " action=dropped reason=overlapping-object-conflict winner=" + ConflictingActive->Name;
      Ctx.Report.Details.push_back(Reason);
      Changed = true;
    }
  }

  // Sort resolved proven candidates by Begin address ascending
  std::sort(Resolved.begin(), Resolved.end(),
            [](const std::unique_ptr<ObjectCandidate> &A,
               const std::unique_ptr<ObjectCandidate> &B) {
              return A->Begin < B->Begin;
            });

  Ctx.Candidates = std::move(Resolved);

  if (Ctx.Debug)
    errs() << "[brighten-global-data] resolved conflicts, total candidates: "
           << Ctx.Candidates.size() << "\n";

  return false; // Analysis only
}
} // namespace brighten_global
