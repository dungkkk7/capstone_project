#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/TypeSize.h"

#include <algorithm>
#include <map>
#include <tuple>

namespace brighten_type {

using namespace llvm;

namespace {

struct IntervalKey {
  uint64_t Offset = 0;
  uint64_t Size = 0;

  bool operator<(const IntervalKey &Other) const {
    return std::tie(Offset, Size) < std::tie(Other.Offset, Other.Size);
  }
};

static void reject(TypeConstraintSolution &Solution, ObjectCandidate &Cand,
                   StringRef Reason) {
  std::string Text = Reason.str();
  if (!is_contained(Solution.RejectionReasons, Text))
    Solution.RejectionReasons.push_back(Text);
  if (!is_contained(Cand.RejectionReasons, Text))
    Cand.RejectionReasons.push_back(std::move(Text));
}

static std::optional<uint64_t> fixedStoreSize(Type *Ty, const DataLayout &DL) {
  if (!Ty || !Ty->isSized())
    return std::nullopt;
  TypeSize Size = DL.getTypeStoreSize(Ty);
  if (Size.isScalable())
    return std::nullopt;
  return Size.getFixedValue();
}

static std::optional<uint64_t> fixedAllocSize(Type *Ty, const DataLayout &DL) {
  if (!Ty || !Ty->isSized())
    return std::nullopt;
  TypeSize Size = DL.getTypeAllocSize(Ty);
  if (Size.isScalable())
    return std::nullopt;
  return Size.getFixedValue();
}

static bool intervalsOverlap(const SolvedField &A, const SolvedField &B) {
  return A.Offset < B.Offset + B.Size && B.Offset < A.Offset + A.Size;
}

static bool solveFields(ArrayRef<const AccessFact *> Facts,
                        uint64_t RegionSize, ObjectCandidate &Cand,
                        TypeReconstructionContext &Ctx,
                        TypeConstraintSolution &Solution) {
  std::map<IntervalKey, SmallVector<const AccessFact *, 4>> Groups;
  for (const AccessFact *Fact : Facts) {
    if (!Fact || Fact->IsWeak)
      continue;
    if (!Fact->ConstantOffset.has_value() || *Fact->ConstantOffset < 0)
      return false;
    uint64_t Offset = static_cast<uint64_t>(*Fact->ConstantOffset);
    if (Offset > RegionSize || Fact->AccessSize > RegionSize - Offset)
      return false;
    Groups[{Offset, Fact->AccessSize}].push_back(Fact);
  }

  if (Groups.empty()) {
    reject(Solution, Cand, "no-strong-typed-evidence");
    return false;
  }

  for (const auto &Entry : Groups) {
    const IntervalKey &Key = Entry.first;
    ArrayRef<const AccessFact *> Group = Entry.second;
    Type *Chosen = Group.front()->ObservedType;
    if (!Chosen) {
      reject(Solution, Cand, "missing-observed-type");
      return false;
    }
    auto AllocSize = fixedAllocSize(Chosen, Ctx.DL);
    if (!AllocSize || *AllocSize != Key.Size) {
      reject(Solution, Cand, "observed-type-has-nonexact-storage-size");
      return false;
    }

    SolvedField Field;
    Field.Offset = Key.Offset;
    Field.Size = Key.Size;
    Field.Ty = Chosen;
    Field.Family = ClassifyTypeFamily(Chosen);
    Field.MinimumAlignment = Group.front()->Alignment;

    for (const AccessFact *Fact : Group) {
      if (!AreEvidenceTypesCompatible(Chosen, Fact->ObservedType, Ctx.DL)) {
        reject(Solution, Cand, "contradictory-types-at-same-interval");
        Ctx.Report.ObjectsRejectedConflict++;
        return false;
      }
      if (Fact->Alignment.value() < Field.MinimumAlignment.value())
        Field.MinimumAlignment = Fact->Alignment;
      Field.HasRead |= !Fact->IsWrite;
      Field.HasWrite |= Fact->IsWrite;
      Field.HasVolatile |= Fact->IsVolatile;
      Field.HasAtomic |= Fact->IsAtomic;
      Field.EvidenceCount++;
    }
    Solution.Fields.push_back(Field);
  }

  llvm::sort(Solution.Fields,
             [](const SolvedField &A, const SolvedField &B) {
               return std::tie(A.Offset, A.Size) < std::tie(B.Offset, B.Size);
             });

  for (size_t I = 0; I < Solution.Fields.size(); ++I) {
    for (size_t J = I + 1; J < Solution.Fields.size(); ++J) {
      const SolvedField &A = Solution.Fields[I];
      const SolvedField &B = Solution.Fields[J];
      if (B.Offset >= A.Offset + A.Size)
        break;
      if (intervalsOverlap(A, B)) {
        reject(Solution, Cand, "overlapping-storage-intervals");
        Ctx.Report.ObjectsRejectedOverlap++;
        return false;
      }
    }
  }

  return true;
}

static unsigned computeConfidence(const ObjectCandidate &Cand,
                                  const TypeConstraintSolution &Solution,
                                  uint64_t RegionSize) {
  unsigned Confidence = 100;
  if (Solution.HasDynamicIndex)
    Confidence -= 5;

  uint64_t Covered = 0;
  for (const SolvedField &Field : Solution.Fields)
    Covered += Field.Size;
  if (Covered < RegionSize)
    Confidence -= 5;

  bool HasRead = false;
  bool HasWrite = false;
  for (const SolvedField &Field : Solution.Fields) {
    HasRead |= Field.HasRead;
    HasWrite |= Field.HasWrite;
  }
  if (!HasRead || !HasWrite)
    Confidence -= 5;

  if (Cand.Kind == ObjectKind::Global &&
      (Cand.Linkage == GlobalValue::ExternalLinkage ||
       Cand.Linkage == GlobalValue::WeakAnyLinkage ||
       Cand.Linkage == GlobalValue::WeakODRLinkage ||
       Cand.Linkage == GlobalValue::LinkOnceAnyLinkage ||
       Cand.Linkage == GlobalValue::LinkOnceODRLinkage))
    Confidence -= 5;
  return Confidence;
}

} // namespace

bool SolveTypeConstraints(TypeReconstructionContext &Ctx) {
  bool AnySolved = false;
  Ctx.Solutions.clear();

  for (auto &Owned : Ctx.Candidates) {
    ObjectCandidate &Cand = *Owned;
    TypeConstraintSolution Solution;

    if (Cand.Escaped) {
      reject(Solution, Cand, "object-pointer-escaped");
      Ctx.Solutions[&Cand] = std::move(Solution);
      continue;
    }

    SmallVector<const AccessFact *, 16> Strong;
    for (const AccessFact &Fact : Cand.Accesses)
      if (!Fact.IsWeak)
        Strong.push_back(&Fact);
    if (Strong.empty()) {
      reject(Solution, Cand, "no-strong-typed-evidence");
      Ctx.Solutions[&Cand] = std::move(Solution);
      continue;
    }

    const AccessFact *FirstDynamic = nullptr;
    bool HasConstantStrong = false;
    for (const AccessFact *Fact : Strong) {
      if (Fact->DynamicIndexExpr) {
        if (!FirstDynamic)
          FirstDynamic = Fact;
      } else {
        HasConstantStrong = true;
      }
    }

    uint64_t RegionSize = Cand.ObjectSize;
    SmallVector<const AccessFact *, 16> ShapeFacts;
    if (FirstDynamic) {
      if (HasConstantStrong) {
        reject(Solution, Cand, "mixed-static-and-dynamic-layout-model");
        Ctx.Solutions[&Cand] = std::move(Solution);
        continue;
      }
      if (FirstDynamic->Stride <= 0) {
        reject(Solution, Cand, "non-positive-affine-stride");
        Ctx.Report.ObjectsRejectedNonAffine++;
        Ctx.Solutions[&Cand] = std::move(Solution);
        continue;
      }

      uint64_t Stride = static_cast<uint64_t>(FirstDynamic->Stride);
      if (Cand.ObjectSize % Stride != 0) {
        reject(Solution, Cand, "object-size-not-divisible-by-array-stride");
        Ctx.Solutions[&Cand] = std::move(Solution);
        continue;
      }
      uint64_t Count = Cand.ObjectSize / Stride;
      if (Count < Ctx.MinArrayElements) {
        reject(Solution, Cand, "insufficient-array-element-count");
        Ctx.Solutions[&Cand] = std::move(Solution);
        continue;
      }

      for (const AccessFact *Fact : Strong) {
        if (Fact->DynamicIndexExpr != FirstDynamic->DynamicIndexExpr ||
            Fact->Stride != FirstDynamic->Stride) {
          reject(Solution, Cand, "multiple-affine-index-families");
          Ctx.Report.ObjectsRejectedNonAffine++;
          ShapeFacts.clear();
          break;
        }
        ShapeFacts.push_back(Fact);
      }
      if (ShapeFacts.empty()) {
        Ctx.Solutions[&Cand] = std::move(Solution);
        continue;
      }

      Solution.HasDynamicIndex = true;
      Solution.DynamicIndexExpr = FirstDynamic->DynamicIndexExpr;
      Solution.ElementStride = Stride;
      Solution.ElementCount = Count;
      RegionSize = Stride;
    } else {
      ShapeFacts = Strong;
    }

    if (!solveFields(ShapeFacts, RegionSize, Cand, Ctx, Solution)) {
      Ctx.Solutions[&Cand] = std::move(Solution);
      continue;
    }

    Solution.Confidence = computeConfidence(Cand, Solution, RegionSize);
    Cand.Confidence = Solution.Confidence;
    if (Solution.Confidence < Ctx.MinConfidence) {
      reject(Solution, Cand, "confidence-below-registered-threshold");
      Ctx.Solutions[&Cand] = std::move(Solution);
      continue;
    }

    Solution.Valid = true;
    AnySolved = true;
    Ctx.Solutions[&Cand] = std::move(Solution);
  }

  return AnySolved;
}

const TypeConstraintSolution *
GetTypeSolution(const ObjectCandidate &Cand,
                const TypeReconstructionContext &Ctx) {
  auto It = Ctx.Solutions.find(const_cast<ObjectCandidate *>(&Cand));
  if (It == Ctx.Solutions.end())
    return nullptr;
  return &It->second;
}

} // namespace brighten_type
