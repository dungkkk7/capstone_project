#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/TypeSize.h"

#include <algorithm>
#include <tuple>

namespace brighten_type {

using namespace llvm;

namespace {

static std::optional<uint64_t> fixedStoreSize(Type *Ty, const DataLayout &DL) {
  if (!Ty || !Ty->isSized())
    return std::nullopt;
  TypeSize Size = DL.getTypeStoreSize(Ty);
  if (Size.isScalable())
    return std::nullopt;
  return Size.getFixedValue();
}

static void reject(ObjectCandidate &Cand, StringRef Reason) {
  std::string Text = Reason.str();
  if (!is_contained(Cand.RejectionReasons, Text))
    Cand.RejectionReasons.push_back(std::move(Text));
}

static bool sameFact(const AccessFact &A, const AccessFact &B) {
  return A.ConstantOffset == B.ConstantOffset &&
         A.DynamicIndexExpr == B.DynamicIndexExpr && A.Stride == B.Stride &&
         A.AccessSize == B.AccessSize && A.ObservedType == B.ObservedType &&
         A.IsWrite == B.IsWrite && A.IsVolatile == B.IsVolatile &&
         A.IsAtomic == B.IsAtomic && A.SourceInst == B.SourceInst;
}

} // namespace

TypeFamily ClassifyTypeFamily(Type *Ty) {
  if (!Ty)
    return TypeFamily::Unsupported;
  if (Ty->isIntegerTy(8))
    return TypeFamily::ByteSequence;
  if (Ty->isIntegerTy())
    return TypeFamily::Integer;
  if (Ty->isFloatingPointTy())
    return TypeFamily::Floating;
  if (Ty->isPointerTy())
    return TypeFamily::Pointer;
  if (Ty->isAggregateType() || isa<FixedVectorType>(Ty))
    return TypeFamily::Aggregate;
  return TypeFamily::Unsupported;
}

bool AreEvidenceTypesCompatible(Type *A, Type *B, const DataLayout &DL) {
  if (A == B)
    return true;
  if (!A || !B || !A->isSized() || !B->isSized())
    return false;

  auto ASize = fixedStoreSize(A, DL);
  auto BSize = fixedStoreSize(B, DL);
  if (!ASize || !BSize || *ASize != *BSize)
    return false;

  TypeFamily AF = ClassifyTypeFamily(A);
  TypeFamily BF = ClassifyTypeFamily(B);
  if (AF != BF)
    return false;

  // Opaque pointers carry no pointee type.  The address space is the only
  // representational distinction relevant to a storage field.
  if (AF == TypeFamily::Pointer)
    return cast<PointerType>(A)->getAddressSpace() ==
           cast<PointerType>(B)->getAddressSpace();

  if (AF == TypeFamily::Integer)
    return cast<IntegerType>(A)->getBitWidth() ==
           cast<IntegerType>(B)->getBitWidth();

  // Floating-point formats and aggregate/vector layouts must agree exactly.
  return false;
}

bool CollectAccessEvidence(TypeReconstructionContext &Ctx) {
  bool AnyUsable = false;
  for (auto &Owned : Ctx.Candidates) {
    ObjectCandidate &Cand = *Owned;
    std::vector<AccessFact> Normalized;
    Normalized.reserve(Cand.Accesses.size());

    for (AccessFact Fact : Cand.Accesses) {
      if (!Fact.SourceInst || !Fact.SourceInst->getParent()) {
        reject(Cand, "stale-access-evidence");
        continue;
      }
      if (!Fact.ObservedType || !Fact.ObservedType->isSized()) {
        reject(Cand, "unsized-observed-type");
        continue;
      }
      auto ObservedSize = fixedStoreSize(Fact.ObservedType, Ctx.DL);
      if (!ObservedSize) {
        reject(Cand, "scalable-or-unknown-access-size");
        continue;
      }

      // Memory intrinsics with a dynamic length are useful for alias analysis
      // but cannot justify an exact aggregate layout.
      if (Fact.AccessSize == 0) {
        reject(Cand, "dynamic-memory-intrinsic-length");
        continue;
      }
      if (Fact.Kind == EvidenceKind::LoadStoreType &&
          Fact.AccessSize != *ObservedSize) {
        reject(Cand, "access-size-type-size-mismatch");
        continue;
      }
      if (!Fact.ConstantOffset.has_value()) {
        reject(Cand, "missing-constant-base-offset");
        continue;
      }

      int64_t SignedOffset = *Fact.ConstantOffset;
      if (SignedOffset < 0) {
        reject(Cand, "negative-object-offset");
        Ctx.Report.ObjectsRejectedOutOfBounds++;
        continue;
      }
      uint64_t Offset = static_cast<uint64_t>(SignedOffset);

      if (Fact.DynamicIndexExpr) {
        if (Fact.Stride <= 0) {
          reject(Cand, "non-affine-dynamic-index");
          Ctx.Report.ObjectsRejectedNonAffine++;
          continue;
        }
        uint64_t Stride = static_cast<uint64_t>(Fact.Stride);
        if (Offset > Stride || Fact.AccessSize > Stride - Offset) {
          reject(Cand, "dynamic-access-crosses-element-boundary");
          Ctx.Report.ObjectsRejectedOutOfBounds++;
          continue;
        }
        Fact.Kind = EvidenceKind::AffineArray;
      } else {
        if (Offset > Cand.ObjectSize ||
            Fact.AccessSize > Cand.ObjectSize - Offset) {
          reject(Cand, "access-outside-object");
          Ctx.Report.ObjectsRejectedOutOfBounds++;
          continue;
        }
        if (Fact.Kind == EvidenceKind::LoadStoreType)
          Fact.Kind = EvidenceKind::ConstantOffset;
      }

      Fact.IsWeak = Fact.Kind == EvidenceKind::InitializerBytes ||
                    Fact.IsAggregateClue;
      if (none_of(Normalized,
                  [&](const AccessFact &Existing) {
                    return sameFact(Existing, Fact);
                  }))
        Normalized.push_back(std::move(Fact));
    }

    Cand.Accesses = std::move(Normalized);
    if (!Cand.Accesses.empty() && !Cand.Escaped)
      AnyUsable = true;
  }
  return AnyUsable;
}

} // namespace brighten_type
