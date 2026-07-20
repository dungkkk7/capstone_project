#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>

namespace brighten_type {

using namespace llvm;

struct StructField {
  uint64_t Offset = 0;
  uint64_t Size = 0;
  Type *Ty = nullptr;

  bool operator<(const StructField &Other) const {
    if (Offset != Other.Offset)
      return Offset < Other.Offset;
    return Size > Other.Size;
  }
};

Type *InferStructType(ObjectCandidate &Cand, TypeReconstructionContext &Ctx) {
  if (Cand.Accesses.empty() || Cand.ObjectSize == 0)
    return nullptr;

  std::vector<StructField> RawFields;
  for (const auto &Fact : Cand.Accesses) {
    if (Fact.DynamicIndexExpr)
      return nullptr;

    if (!Fact.ConstantOffset.has_value())
      return nullptr;

    int64_t Off = Fact.ConstantOffset.value();
    if (Off < 0 || (uint64_t)Off >= Cand.ObjectSize)
      return nullptr;

    uint64_t Size = Fact.AccessSize;
    if (Size == 0 || Off + Size > Cand.ObjectSize)
      return nullptr;

    RawFields.push_back({(uint64_t)Off, Size, Fact.ObservedType});
  }

  if (RawFields.empty())
    return nullptr;

  std::sort(RawFields.begin(), RawFields.end());

  std::vector<StructField> DisjointFields;
  for (const auto &Field : RawFields) {
    bool Handled = false;
    for (auto &Active : DisjointFields) {
      if (Field.Offset == Active.Offset) {
        if (Field.Size == Active.Size) {
          if (Field.Ty != Active.Ty) {
            if (Ctx.Mode == TypeMode::Conservative) {
              Cand.RejectionReasons.push_back("type-conflict-at-same-offset");
              return nullptr;
            } else {
              Active.Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), Active.Size);
              Handled = true;
              break;
            }
          } else {
            Handled = true;
            break;
          }
        } else if (Field.Size < Active.Size) {
          Handled = true;
          break;
        } else {
          Active = Field;
          Handled = true;
          break;
        }
      }
      if (Field.Offset < Active.Offset + Active.Size && Active.Offset < Field.Offset + Field.Size) {
        if (Field.Offset >= Active.Offset && Field.Offset + Field.Size <= Active.Offset + Active.Size) {
          Handled = true;
          break;
        }
        
        if (Ctx.Mode == TypeMode::Conservative) {
          Cand.RejectionReasons.push_back("overlapping-field-conflict");
          return nullptr;
        } else {
          uint64_t NewStart = std::min(Active.Offset, Field.Offset);
          uint64_t NewEnd = std::max(Active.Offset + Active.Size, Field.Offset + Field.Size);
          Active.Offset = NewStart;
          Active.Size = NewEnd - NewStart;
          Active.Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), Active.Size);
          Handled = true;
          break;
        }
      }
    }

    if (!Handled) {
      DisjointFields.push_back(Field);
    }
  }

  std::sort(DisjointFields.begin(), DisjointFields.end());

  // Group consecutive identical fields into arrays
  std::vector<StructField> GroupedFields;
  for (size_t i = 0; i < DisjointFields.size(); ) {
    size_t j = i + 1;
    uint64_t ElemSize = DisjointFields[i].Size;
    Type *ElemTy = DisjointFields[i].Ty;

    while (j < DisjointFields.size() &&
           DisjointFields[j].Ty == ElemTy &&
           DisjointFields[j].Offset == DisjointFields[j-1].Offset + DisjointFields[j-1].Size &&
           DisjointFields[j].Size == ElemSize) {
      ++j;
    }

    uint64_t Count = j - i;
    if (Count >= Ctx.MinArrayElements) {
      StructField ArrField;
      ArrField.Offset = DisjointFields[i].Offset;
      ArrField.Size = Count * ElemSize;
      ArrField.Ty = ArrayType::get(ElemTy, Count);
      GroupedFields.push_back(ArrField);
    } else {
      for (size_t k = i; k < j; ++k) {
        GroupedFields.push_back(DisjointFields[k]);
      }
    }
    i = j;
  }
  DisjointFields = std::move(GroupedFields);

  std::vector<StructField> FinalFields;
  uint64_t CurrentOffset = 0;

  for (const auto &Field : DisjointFields) {
    if (Field.Offset > CurrentOffset) {
      uint64_t PadSize = Field.Offset - CurrentOffset;
      Type *PadTy = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), PadSize);
      FinalFields.push_back({CurrentOffset, PadSize, PadTy});
    }
    FinalFields.push_back(Field);
    CurrentOffset = Field.Offset + Field.Size;
  }

  if (CurrentOffset < Cand.ObjectSize) {
    uint64_t PadSize = Cand.ObjectSize - CurrentOffset;
    Type *PadTy = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), PadSize);
    FinalFields.push_back({CurrentOffset, PadSize, PadTy});
  }

  std::vector<Type *> StructElements;
  for (const auto &Field : FinalFields) {
    StructElements.push_back(Field.Ty);
  }

  bool IsPacked = false;
  StructType *AnonSTy = StructType::get(Ctx.M.getContext(), StructElements, false);
  const StructLayout *Layout = Ctx.DL.getStructLayout(AnonSTy);

  bool LayoutMatches = true;
  for (size_t i = 0; i < FinalFields.size(); ++i) {
    if (Layout->getElementOffset(i) != FinalFields[i].Offset) {
      LayoutMatches = false;
      break;
    }
  }

  if (!LayoutMatches) {
    AnonSTy = StructType::get(Ctx.M.getContext(), StructElements, true);
    Layout = Ctx.DL.getStructLayout(AnonSTy);
    LayoutMatches = true;
    for (size_t i = 0; i < FinalFields.size(); ++i) {
      if (Layout->getElementOffset(i) != FinalFields[i].Offset) {
        LayoutMatches = false;
        break;
      }
    }
    IsPacked = true;
  }

  if (!LayoutMatches || Layout->getSizeInBytes().getFixedValue() != Cand.ObjectSize) {
    Cand.RejectionReasons.push_back("struct-layout-offset-mismatch");
    return nullptr;
  }

  std::string BaseName = "brighten.struct.";
  if (Cand.Kind == ObjectKind::Stack) {
    BaseName += "stack.";
    if (auto *AI = dyn_cast<AllocaInst>(Cand.BaseVal)) {
      BaseName += AI->getFunction()->getName().str() + ".";
    }
  } else if (Cand.Kind == ObjectKind::Global) {
    BaseName += "global.";
  } else {
    BaseName += "anon.";
  }
  BaseName += Cand.Name;

  std::string UniqueName = BaseName;
  unsigned Suffix = 0;
  while (StructType::getTypeByName(Ctx.M.getContext(), UniqueName)) {
    UniqueName = BaseName + "." + std::to_string(Suffix++);
  }

  return StructType::create(Ctx.M.getContext(), StructElements, UniqueName, IsPacked);
}

} // namespace brighten_type
