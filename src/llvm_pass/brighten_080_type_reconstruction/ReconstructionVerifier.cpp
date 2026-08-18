#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"

#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TypeSize.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_type {

using namespace llvm;

namespace {

static std::optional<uint64_t> fixedAllocSize(Type *Ty, const DataLayout &DL) {
  if (!Ty || !Ty->isSized())
    return std::nullopt;
  TypeSize Size = DL.getTypeAllocSize(Ty);
  if (Size.isScalable())
    return std::nullopt;
  return Size.getFixedValue();
}

static bool mapsToSubobject(Type *Ty, uint64_t Offset, uint64_t AccessSize,
                            Type *Observed, const DataLayout &DL) {
  auto Size = fixedAllocSize(Ty, DL);
  if (!Size || Offset > *Size || AccessSize > *Size - Offset)
    return false;

  if (Offset == 0 && *Size == AccessSize &&
      AreEvidenceTypesCompatible(Ty, Observed, DL))
    return true;

  if (auto *Array = dyn_cast<ArrayType>(Ty)) {
    auto ElementSize = fixedAllocSize(Array->getElementType(), DL);
    if (!ElementSize || *ElementSize == 0)
      return false;
    uint64_t Index = Offset / *ElementSize;
    if (Index >= Array->getNumElements())
      return false;
    return mapsToSubobject(Array->getElementType(), Offset % *ElementSize,
                           AccessSize, Observed, DL);
  }

  if (auto *Struct = dyn_cast<StructType>(Ty)) {
    const StructLayout *Layout = DL.getStructLayout(Struct);
    unsigned Field = Layout->getElementContainingOffset(Offset);
    uint64_t FieldOffset = Layout->getElementOffset(Field);
    return mapsToSubobject(Struct->getElementType(Field), Offset - FieldOffset,
                           AccessSize, Observed, DL);
  }

  return false;
}

} // namespace

bool PrevalidateTypePlan(InferredTypePlan &Plan,
                         TypeReconstructionContext &Ctx) {
  if (!Plan.Candidate || !Plan.ProposedRootType) {
    Plan.RejectionReasons.push_back("missing-candidate-or-proposed-type");
    return false;
  }
  ObjectCandidate &Cand = *Plan.Candidate;
  const TypeConstraintSolution *Solution = GetTypeSolution(Cand, Ctx);
  if (!Solution || !Solution->Valid) {
    Plan.RejectionReasons.push_back("candidate-has-no-valid-constraint-solution");
    return false;
  }
  if (Cand.Escaped) {
    Plan.RejectionReasons.push_back("candidate-pointer-escaped");
    return false;
  }
  if (!Plan.ProposedRootType->isSized()) {
    Plan.RejectionReasons.push_back("proposed-type-not-sized");
    return false;
  }

  auto ProposedSize = fixedAllocSize(Plan.ProposedRootType, Ctx.DL);
  if (!ProposedSize || *ProposedSize != Cand.ObjectSize) {
    Plan.RejectionReasons.push_back("proposed-size-does-not-match-object");
    return false;
  }

  Type *AccessRoot = Plan.ProposedRootType;
  if (Solution->HasDynamicIndex) {
    auto *Array = dyn_cast<ArrayType>(Plan.ProposedRootType);
    if (!Array || Array->getNumElements() != Solution->ElementCount) {
      Plan.RejectionReasons.push_back("dynamic-solution-requires-exact-array-root");
      return false;
    }
    auto ElementSize = fixedAllocSize(Array->getElementType(), Ctx.DL);
    if (!ElementSize || *ElementSize != Solution->ElementStride) {
      Plan.RejectionReasons.push_back("array-element-size-does-not-match-affine-stride");
      return false;
    }
    AccessRoot = Array->getElementType();
  }

  for (const AccessFact &Fact : Cand.Accesses) {
    if (!Fact.ConstantOffset.has_value() || *Fact.ConstantOffset < 0) {
      Plan.RejectionReasons.push_back("access-without-proven-offset");
      return false;
    }
    if (Fact.IsWeak) {
      // Whole-object byte operations retain the same address, extent and byte
      // representation after retyping.  They do not determine the type but do
      // not invalidate an independently proven layout.
      uint64_t Offset = static_cast<uint64_t>(*Fact.ConstantOffset);
      uint64_t Region = Solution->HasDynamicIndex ? Solution->ElementStride
                                                  : Cand.ObjectSize;
      if (Offset > Region || Fact.AccessSize > Region - Offset) {
        Plan.RejectionReasons.push_back("weak-byte-operation-outside-region");
        return false;
      }
      continue;
    }

    if (Solution->HasDynamicIndex) {
      if (Fact.DynamicIndexExpr != Solution->DynamicIndexExpr ||
          Fact.Stride != static_cast<int64_t>(Solution->ElementStride)) {
        Plan.RejectionReasons.push_back("access-not-in-solved-affine-family");
        return false;
      }
    } else if (Fact.DynamicIndexExpr) {
      Plan.RejectionReasons.push_back("unexpected-dynamic-access");
      return false;
    }

    uint64_t Offset = static_cast<uint64_t>(*Fact.ConstantOffset);
    if (!mapsToSubobject(AccessRoot, Offset, Fact.AccessSize,
                         Fact.ObservedType, Ctx.DL)) {
      Plan.RejectionReasons.push_back("access-does-not-map-to-exact-subobject");
      return false;
    }
  }

  Plan.Confidence = Solution->Confidence;
  Plan.ElementCount = Solution->ElementCount;
  Plan.FieldLayout.clear();
  for (const SolvedField &Field : Solution->Fields)
    Plan.FieldLayout[Field.Offset] = Field.Ty;
  return true;
}

bool VerifyReconstruction(TypeReconstructionContext &Ctx) {
  if (Ctx.Report.ObjectsReconstructed == 0)
    return true;

  std::string Error;
  raw_string_ostream OS(Error);
  if (verifyModule(Ctx.M, &OS)) {
    Ctx.Report.VerificationFailures++;
    OS.flush();
    report_fatal_error("brighten type reconstruction produced invalid IR: " +
                       Error);
  }
  return true;
}

} // namespace brighten_type
