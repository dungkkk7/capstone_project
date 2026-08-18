#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/Support/TypeSize.h"

#include <algorithm>
#include <string>
#include <tuple>
#include <vector>

namespace brighten_type {

using namespace llvm;

namespace {

struct LayoutField {
  uint64_t Offset = 0;
  uint64_t Size = 0;
  Type *Ty = nullptr;
};

static std::string typeName(const ObjectCandidate &Cand, StringRef Suffix) {
  std::string Name = "brighten.struct.";
  if (Cand.Kind == ObjectKind::Stack) {
    Name += "stack.";
    if (auto *AI = dyn_cast<AllocaInst>(Cand.BaseVal)) {
      Name += AI->getFunction()->getName().str();
      Name += ".";
    }
  } else if (Cand.Kind == ObjectKind::Global) {
    Name += "global.";
  } else {
    Name += "proven.";
  }
  Name += Cand.Name;
  Name += Suffix.str();
  return Name;
}

static bool layoutMatches(ArrayRef<LayoutField> Fields, StructType *Ty,
                          const DataLayout &DL, uint64_t ObjectSize) {
  const StructLayout *Layout = DL.getStructLayout(Ty);
  if (Layout->getSizeInBytes().isScalable() ||
      Layout->getSizeInBytes().getFixedValue() != ObjectSize)
    return false;
  if (Fields.size() != Ty->getNumElements())
    return false;
  for (size_t I = 0; I < Fields.size(); ++I)
    if (Layout->getElementOffset(I) != Fields[I].Offset)
      return false;
  return true;
}

} // namespace

Type *BuildStructTypeFromSolvedFields(ObjectCandidate &Cand,
                                      ArrayRef<SolvedField> Solved,
                                      uint64_t ObjectSize,
                                      TypeReconstructionContext &Ctx,
                                      StringRef NameSuffix) {
  if (Solved.empty() || ObjectSize == 0)
    return nullptr;

  SmallVector<SolvedField, 16> Fields(Solved.begin(), Solved.end());
  llvm::sort(Fields, [](const SolvedField &A, const SolvedField &B) {
    return std::tie(A.Offset, A.Size) < std::tie(B.Offset, B.Size);
  });

  // Convert repeated, fully observed adjacent fields into an array field.  No
  // missing interval is invented as an element, so sparse evidence cannot
  // turn padding into application data.
  SmallVector<LayoutField, 16> Grouped;
  for (size_t I = 0; I < Fields.size();) {
    size_t J = I + 1;
    while (J < Fields.size() && Fields[J].Ty == Fields[I].Ty &&
           Fields[J].Size == Fields[I].Size &&
           Fields[J].Offset == Fields[J - 1].Offset + Fields[I].Size)
      ++J;
    uint64_t Count = J - I;
    if (Count >= Ctx.MinArrayElements) {
      Grouped.push_back({Fields[I].Offset, Count * Fields[I].Size,
                         ArrayType::get(Fields[I].Ty, Count)});
    } else {
      for (size_t K = I; K < J; ++K)
        Grouped.push_back({Fields[K].Offset, Fields[K].Size, Fields[K].Ty});
    }
    I = J;
  }

  SmallVector<LayoutField, 24> WithPadding;
  uint64_t Cursor = 0;
  Type *Byte = Type::getInt8Ty(Ctx.M.getContext());
  for (const LayoutField &Field : Grouped) {
    if (!Field.Ty || Field.Offset < Cursor || Field.Offset > ObjectSize ||
        Field.Size > ObjectSize - Field.Offset) {
      Cand.RejectionReasons.push_back("invalid-solved-field-layout");
      return nullptr;
    }
    if (Field.Offset > Cursor) {
      uint64_t Padding = Field.Offset - Cursor;
      WithPadding.push_back(
          {Cursor, Padding, ArrayType::get(Byte, Padding)});
    }
    WithPadding.push_back(Field);
    Cursor = Field.Offset + Field.Size;
  }
  if (Cursor < ObjectSize)
    WithPadding.push_back(
        {Cursor, ObjectSize - Cursor,
         ArrayType::get(Byte, ObjectSize - Cursor)});

  SmallVector<Type *, 24> Elements;
  for (const LayoutField &Field : WithPadding)
    Elements.push_back(Field.Ty);

  StructType *Literal = StructType::get(Ctx.M.getContext(), Elements, false);
  bool Packed = false;
  if (!layoutMatches(WithPadding, Literal, Ctx.DL, ObjectSize)) {
    Literal = StructType::get(Ctx.M.getContext(), Elements, true);
    Packed = true;
  }
  if (!layoutMatches(WithPadding, Literal, Ctx.DL, ObjectSize)) {
    Cand.RejectionReasons.push_back("struct-layout-does-not-preserve-bytes");
    return nullptr;
  }

  std::string Base = typeName(Cand, NameSuffix);
  std::string Unique = Base;
  for (unsigned Suffix = 0;
       StructType::getTypeByName(Ctx.M.getContext(), Unique);
       ++Suffix)
    Unique = Base + "." + std::to_string(Suffix);
  return StructType::create(Ctx.M.getContext(), Elements, Unique, Packed);
}

Type *InferStructType(ObjectCandidate &Cand, TypeReconstructionContext &Ctx) {
  const TypeConstraintSolution *Solution = GetTypeSolution(Cand, Ctx);
  if (!Solution || !Solution->Valid || Solution->HasDynamicIndex)
    return nullptr;
  return BuildStructTypeFromSolvedFields(Cand, Solution->Fields,
                                         Cand.ObjectSize, Ctx);
}

} // namespace brighten_type
