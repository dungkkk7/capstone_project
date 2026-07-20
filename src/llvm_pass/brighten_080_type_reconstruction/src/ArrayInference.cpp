#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>

namespace brighten_type {

using namespace llvm;

extern Type *InferStructType(ObjectCandidate &Cand, TypeReconstructionContext &Ctx);

Type *InferArrayType(ObjectCandidate &Cand, TypeReconstructionContext &Ctx) {
  if (Cand.Accesses.empty() || Cand.ObjectSize == 0)
    return nullptr;

  // Case 1: Dynamic affine access
  Value *CommonIdx = nullptr;
  int64_t CommonStride = 0;
  bool HasDynamic = false;
  bool UniformDynamic = true;

  for (const auto &Fact : Cand.Accesses) {
    if (Fact.DynamicIndexExpr) {
      HasDynamic = true;
      if (!CommonIdx) {
        CommonIdx = Fact.DynamicIndexExpr;
        CommonStride = Fact.Stride;
      } else if (CommonIdx != Fact.DynamicIndexExpr || CommonStride != Fact.Stride) {
        UniformDynamic = false;
      }
    }
  }

  if (HasDynamic && UniformDynamic && CommonIdx && CommonStride > 0) {
    if (Cand.ObjectSize % CommonStride != 0)
      return nullptr;

    uint64_t Count = Cand.ObjectSize / CommonStride;
    if (Count < Ctx.MinArrayElements)
      return nullptr;

    // Create a dummy candidate to infer the element type of size CommonStride
    ObjectCandidate Dummy;
    Dummy.BaseVal = Cand.BaseVal;
    Dummy.ObjectSize = CommonStride;
    Dummy.ABIAlignment = Cand.ABIAlignment;
    Dummy.AddressSpace = Cand.AddressSpace;
    Dummy.Kind = Cand.Kind;
    Dummy.Name = Cand.Name + ".elem";

    for (const auto &Fact : Cand.Accesses) {
      AccessFact DummyFact = Fact;
      DummyFact.DynamicIndexExpr = nullptr;
      DummyFact.ConstantOffset = Fact.ConstantOffset.value_or(0);
      Dummy.Accesses.push_back(DummyFact);
    }

    Type *ElemTy = InferStructType(Dummy, Ctx);
    if (!ElemTy) {
      ElemTy = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), CommonStride);
    }
    return ArrayType::get(ElemTy, Count);
  }

  // Case 2: Constant offset repeated access
  Type *CommonTy = nullptr;
  std::set<int64_t> Offsets;
  bool UniformType = true;

  for (const auto &Fact : Cand.Accesses) {
    if (Fact.DynamicIndexExpr)
      return nullptr;

    if (!Fact.ConstantOffset.has_value())
      return nullptr;

    Offsets.insert(Fact.ConstantOffset.value());
    if (!CommonTy) {
      CommonTy = Fact.ObservedType;
    } else if (CommonTy != Fact.ObservedType) {
      UniformType = false;
    }
  }

  if (!UniformType || !CommonTy || Offsets.size() < Ctx.MinArrayElements)
    return nullptr;

  uint64_t ElemSize = Ctx.DL.getTypeAllocSize(CommonTy).getFixedValue();
  if (ElemSize == 0 || Cand.ObjectSize % ElemSize != 0)
    return nullptr;

  uint64_t Count = Cand.ObjectSize / ElemSize;
  if (Count < Ctx.MinArrayElements)
    return nullptr;

  for (int64_t Off : Offsets) {
    if (Off < 0 || (uint64_t)Off >= Cand.ObjectSize || Off % ElemSize != 0)
      return nullptr;
  }

  return ArrayType::get(CommonTy, Count);
}

} // namespace brighten_type
