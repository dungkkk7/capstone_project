#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/TypeSize.h"

#include <set>

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

} // namespace

Type *InferArrayType(ObjectCandidate &Cand, TypeReconstructionContext &Ctx) {
  const TypeConstraintSolution *Solution = GetTypeSolution(Cand, Ctx);
  if (!Solution || !Solution->Valid || Solution->Fields.empty())
    return nullptr;

  if (Solution->HasDynamicIndex) {
    if (!Solution->DynamicIndexExpr || Solution->ElementStride == 0 ||
        Solution->ElementCount < Ctx.MinArrayElements)
      return nullptr;

    Type *ElementType = nullptr;
    if (Solution->Fields.size() == 1 && Solution->Fields.front().Offset == 0 &&
        Solution->Fields.front().Size == Solution->ElementStride) {
      auto Size = fixedAllocSize(Solution->Fields.front().Ty, Ctx.DL);
      if (Size && *Size == Solution->ElementStride)
        ElementType = Solution->Fields.front().Ty;
    }
    if (!ElementType)
      ElementType = BuildStructTypeFromSolvedFields(
          Cand, Solution->Fields, Solution->ElementStride, Ctx, ".elem");
    if (!ElementType)
      return nullptr;
    auto ElementSize = fixedAllocSize(ElementType, Ctx.DL);
    if (!ElementSize || *ElementSize != Solution->ElementStride)
      return nullptr;
    return ArrayType::get(ElementType, Solution->ElementCount);
  }

  Type *ElementType = Solution->Fields.front().Ty;
  uint64_t ElementSize = Solution->Fields.front().Size;
  if (!ElementType || ElementSize == 0 ||
      Solution->Fields.front().Offset != 0 ||
      Solution->Fields.size() < Ctx.MinArrayElements ||
      Cand.ObjectSize % ElementSize != 0)
    return nullptr;

  auto AllocSize = fixedAllocSize(ElementType, Ctx.DL);
  if (!AllocSize || *AllocSize != ElementSize)
    return nullptr;

  std::set<uint64_t> SeenElements;
  for (const SolvedField &Field : Solution->Fields) {
    if (Field.Ty != ElementType || Field.Size != ElementSize ||
        Field.Offset % ElementSize != 0)
      return nullptr;
    SeenElements.insert(Field.Offset / ElementSize);
  }
  if (SeenElements.size() < Ctx.MinArrayElements)
    return nullptr;

  uint64_t Count = Cand.ObjectSize / ElementSize;
  if (*SeenElements.rbegin() >= Count)
    return nullptr;
  return ArrayType::get(ElementType, Count);
}

} // namespace brighten_type
