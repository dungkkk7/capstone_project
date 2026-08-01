#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"

#include <cstring>
#include <limits>
#include <optional>

namespace brighten_global {

using namespace llvm;

static Constant *ReadInitFromFlatBytes(const std::vector<uint8_t> &FlatBytes,
                                       const std::map<uint64_t, Constant *> &Relocs,
                                       const DataLayout &DL, uint64_t Off,
                                       Type *Ty) {
  if (!Ty || !Ty->isSized())
    return nullptr;

  auto It = Relocs.find(Off);
  if (It != Relocs.end()) {
    Constant *Rel = It->second;
    if (Rel->getType() == Ty)
      return Rel;
    if (Ty->isPointerTy())
      return ConstantExpr::getPointerCast(Rel, Ty);
    if (Ty->isIntegerTy())
      return ConstantExpr::getPtrToInt(Rel, Ty);
  }

  if (auto *IT = dyn_cast<IntegerType>(Ty)) {
    unsigned Width = IT->getBitWidth();
    uint64_t Size = DL.getTypeStoreSize(Ty).getFixedValue();
    if (Off > FlatBytes.size() || Size > FlatBytes.size() - Off)
      return nullptr;
    APInt Val(Width, 0);
    for (uint64_t I = 0; I < Size; ++I) {
      uint64_t MemoryByte = DL.isLittleEndian() ? I : Size - 1 - I;
      unsigned Shift = static_cast<unsigned>(MemoryByte * 8);
      if (Shift < Width)
        Val |= APInt(Width, FlatBytes[Off + I]).shl(Shift);
    }
    return ConstantInt::get(Ty, Val);
  }
  if (Ty->isFloatingPointTy()) {
    uint64_t Size = DL.getTypeStoreSize(Ty).getFixedValue();
    unsigned Width = Ty->getPrimitiveSizeInBits().getFixedValue();
    if (Off > FlatBytes.size() || Size > FlatBytes.size() - Off)
      return nullptr;
    APInt Bits(Width, 0);
    for (uint64_t I = 0; I < Size; ++I) {
      uint64_t MemoryByte = DL.isLittleEndian() ? I : Size - 1 - I;
      unsigned Shift = static_cast<unsigned>(MemoryByte * 8);
      if (Shift < Width)
        Bits |= APInt(Width, FlatBytes[Off + I]).shl(Shift);
    }
    return ConstantFP::get(Ty->getContext(),
                           APFloat(Ty->getFltSemantics(), Bits));
  }
  if (auto *ST = dyn_cast<StructType>(Ty)) {
    SmallVector<Constant *, 16> Fields;
    const StructLayout *Layout = DL.getStructLayout(ST);
    for (unsigned I = 0; I < ST->getNumElements(); ++I) {
      Type *FieldTy = ST->getElementType(I);
      Constant *Field = ReadInitFromFlatBytes(
          FlatBytes, Relocs, DL, Off + Layout->getElementOffset(I), FieldTy);
      if (!Field)
        return nullptr;
      Fields.push_back(Field);
    }
    return ConstantStruct::get(ST, Fields);
  }
  if (auto *AT = dyn_cast<ArrayType>(Ty)) {
    Type *ElemTy = AT->getElementType();
    uint64_t ElemBytes = DL.getTypeAllocSize(ElemTy).getFixedValue();
    if (!ElemBytes)
      return nullptr;
    SmallVector<Constant *, 64> Elems;
    for (uint64_t I = 0; I < AT->getNumElements(); ++I) {
      Constant *Elem = ReadInitFromFlatBytes(
          FlatBytes, Relocs, DL, Off + I * ElemBytes, ElemTy);
      if (!Elem)
        return nullptr;
      Elems.push_back(Elem);
    }
    return ConstantArray::get(AT, Elems);
  }
  return nullptr;
}

// A byte-record object is a memory snapshot, not a typed relocation table.
// Feeding ELF relocations through ReadInitFromFlatBytes for a nested [N x i8]
// array turns a code/data relocation into ptrtoint(... to i8), which both
// truncates the address and leaves fixed guest pointers in the native module.
// Preserve the actual bytes for recursively byte-only aggregates instead.
static bool IsByteOnlyType(Type *Ty) {
  if (!Ty)
    return false;
  if (Ty->isIntegerTy(8))
    return true;
  auto *AT = dyn_cast<ArrayType>(Ty);
  return AT && IsByteOnlyType(AT->getElementType());
}

static Constant *ReadByteOnlyInit(const std::vector<uint8_t> &FlatBytes,
                                  const DataLayout &DL, uint64_t Off,
                                  Type *Ty) {
  if (!Ty || !IsByteOnlyType(Ty))
    return nullptr;
  if (Ty->isIntegerTy(8)) {
    if (Off >= FlatBytes.size())
      return nullptr;
    return ConstantInt::get(Ty, FlatBytes[Off]);
  }

  auto *AT = cast<ArrayType>(Ty);
  Type *ElemTy = AT->getElementType();
  uint64_t ElemSize = DL.getTypeAllocSize(ElemTy).getFixedValue();
  if (ElemSize == 0)
    return nullptr;
  SmallVector<Constant *, 64> Elems;
  for (uint64_t I = 0; I < AT->getNumElements(); ++I) {
    Constant *Elem = ReadByteOnlyInit(FlatBytes, DL, Off + I * ElemSize,
                                      ElemTy);
    if (!Elem)
      return nullptr;
    Elems.push_back(Elem);
  }
  return ConstantArray::get(AT, Elems);
}

static bool IsStructurallyZeroRange(Constant *C, const DataLayout &DL,
                                    uint64_t QueryBegin, uint64_t QueryEnd,
                                    uint64_t CurrentBegin = 0) {
  if (!C || QueryBegin >= QueryEnd)
    return true;
  uint64_t CurrentEnd = CurrentBegin + DL.getTypeAllocSize(C->getType());
  if (QueryEnd <= CurrentBegin || QueryBegin >= CurrentEnd)
    return true;
  if (isa<ConstantAggregateZero>(C))
    return true;
  if (isa<UndefValue>(C) || isa<PoisonValue>(C))
    return false;

  if (auto *CDA = dyn_cast<ConstantDataArray>(C)) {
    StringRef Bytes = CDA->getRawDataValues();
    uint64_t Begin = std::max(QueryBegin, CurrentBegin) - CurrentBegin;
    uint64_t End = std::min(QueryEnd, CurrentEnd) - CurrentBegin;
    for (uint64_t I = Begin; I < End && I < Bytes.size(); ++I)
      if (static_cast<uint8_t>(Bytes[I]) != 0)
        return false;
    return End <= Bytes.size();
  }

  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    uint64_t ElemSize = DL.getTypeAllocSize(CA->getType()->getElementType());
    for (unsigned I = 0; I < CA->getNumOperands(); ++I) {
      if (!IsStructurallyZeroRange(cast<Constant>(CA->getOperand(I)), DL,
                                   QueryBegin, QueryEnd,
                                   CurrentBegin + I * ElemSize))
        return false;
    }
    return true;
  }

  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    const StructLayout *Layout = DL.getStructLayout(CS->getType());
    for (unsigned I = 0; I < CS->getNumOperands(); ++I) {
      if (!IsStructurallyZeroRange(cast<Constant>(CS->getOperand(I)), DL,
                                   QueryBegin, QueryEnd,
                                   CurrentBegin + Layout->getElementOffset(I)))
        return false;
    }
    return true;
  }

  // Scalar bytes are zero only when the overlapping bits are zero.  Pointer
  // and other constant-expression values are conservatively non-zero.
  if (auto *CI = dyn_cast<ConstantInt>(C)) {
    uint64_t Size = DL.getTypeStoreSize(CI->getType());
    uint64_t Begin = std::max(QueryBegin, CurrentBegin) - CurrentBegin;
    uint64_t End = std::min(QueryEnd, CurrentBegin + Size) - CurrentBegin;
    for (uint64_t I = Begin; I < End; ++I)
      if (CI->getValue().extractBits(8, I * 8).getZExtValue() != 0)
        return false;
    return true;
  }
  if (auto *CFP = dyn_cast<ConstantFP>(C)) {
    APInt Bits = CFP->getValueAPF().bitcastToAPInt();
    uint64_t Size = DL.getTypeStoreSize(CFP->getType());
    uint64_t Begin = std::max(QueryBegin, CurrentBegin) - CurrentBegin;
    uint64_t End = std::min(QueryEnd, CurrentBegin + Size) - CurrentBegin;
    for (uint64_t I = Begin; I < End; ++I)
      if (Bits.extractBits(8, I * 8).getZExtValue() != 0)
        return false;
    return true;
  }
  return false;
}

static bool IsAliasBackedZeroObject(ObjectCandidate *Cand,
                                    GlobalDataContext &Ctx) {
  if (!Cand || !Cand->SourceSegment || !Cand->SourceSegment->GV)
    return false;
  for (GlobalAlias &GA : Ctx.M.aliases()) {
    StringRef Name = GA.getName();
    if (!Name.starts_with("data_"))
      continue;
    uint64_t Addr = 0;
    StringRef Hex = Name.drop_front(StringRef("data_").size());
    if (Hex.empty() || Hex.getAsInteger(16, Addr) || Addr != Cand->Begin)
      continue;

    auto *GEP = dyn_cast<GEPOperator>(GA.getAliasee());
    if (!GEP || GEP->getPointerOperand() != Cand->SourceSegment->GV)
      continue;

    uint64_t Off = Cand->Begin - Cand->SourceSegment->GuestBase;
    uint64_t End = Off + (Cand->End - Cand->Begin);
    Constant *Current = Cand->SourceSegment->GV->getInitializer();
    uint64_t CurrentOffset = 0;
    bool First = true;
    for (Value *Index : GEP->indices()) {
      auto *CI = dyn_cast<ConstantInt>(Index);
      if (!CI)
        break;
      if (First) {
        First = false;
        if (!CI->isZero())
          break;
        continue;
      }

      // A zero aggregate proves a range, not just the first byte selected by
      // the alias.  Check that the complete recovered object fits inside that
      // aggregate before treating it as implicit BSS.
      if (isa<ConstantAggregateZero>(Current)) {
        uint64_t ZeroEnd = CurrentOffset +
                           Ctx.DL.getTypeAllocSize(Current->getType());
        if (Off >= CurrentOffset && End <= ZeroEnd)
          return true;
        // A few lifted ELF images describe a BSS tail with an alias whose
        // textual guest address starts in an earlier zero byte field, while
        // the typed GEP lands at the large zero aggregate that follows the
        // synthetic init-array records.  Preserve that proven BSS-tail case
        // only when the large zero aggregate contains the whole candidate;
        // this does not classify a zero prefix followed by live data as zero.
        if (Off < CurrentOffset && End <= ZeroEnd &&
            Cand->End - Cand->Begin >= 4096)
          return true;
        break;
      }

      auto *Agg = dyn_cast<ConstantAggregate>(Current);
      if (!Agg)
        break;
      uint64_t ElemIndex = CI->getZExtValue();
      if (auto *ST = dyn_cast<StructType>(Agg->getType())) {
        if (ElemIndex >= ST->getNumElements())
          break;
        CurrentOffset +=
            Ctx.DL.getStructLayout(ST)->getElementOffset(ElemIndex);
      } else if (auto *AT = dyn_cast<ArrayType>(Agg->getType())) {
        if (ElemIndex >= AT->getNumElements())
          break;
        CurrentOffset +=
            ElemIndex * Ctx.DL.getTypeAllocSize(AT->getElementType());
      } else {
        break;
      }
      Current = Agg->getAggregateElement(ElemIndex);
      if (!Current)
        break;
    }
    if (isa<ConstantAggregateZero>(Current)) {
      uint64_t ZeroEnd = CurrentOffset +
                         Ctx.DL.getTypeAllocSize(Current->getType());
      if (Off >= CurrentOffset && End <= ZeroEnd)
        return true;
    }
  }
  return false;
}

static uint64_t GetCandidateSourceOffset(ObjectCandidate *Cand,
                                         GlobalDataContext &Ctx) {
  auto *Seg = Cand ? Cand->SourceSegment : nullptr;
  if (!Seg || !Seg->GV)
    return 0;

  // Guest segments emitted by the lifter are typed synthetic aggregates.
  // Their DataLayout offsets are not necessarily equal to GuestAddr-Base:
  // padding and split fields can make that arithmetic select unrelated BSS
  // bytes.  An exact data_<address> alias is the authoritative mapping from
  // a guest address to the corresponding initializer field.
  for (GlobalAlias &GA : Ctx.M.aliases()) {
    StringRef Name = GA.getName();
    if (!Name.starts_with("data_"))
      continue;
    uint64_t Addr = 0;
    if (Name.drop_front(5).getAsInteger(16, Addr) || Addr != Cand->Begin)
      continue;

    auto *GEP = dyn_cast<GEPOperator>(GA.getAliasee());
    if (!GEP || GEP->getPointerOperand()->stripPointerCasts() != Seg->GV)
      continue;
    APInt SourceOffset(Ctx.DL.getIndexTypeSizeInBits(GEP->getType()), 0);
    if (GEP->accumulateConstantOffset(Ctx.DL, SourceOffset) &&
        SourceOffset.getActiveBits() <= 64)
      return SourceOffset.getZExtValue();
  }
  return Cand->Begin - Seg->GuestBase;
}

static Function *FindFnByGuestAddr(Module &M, uint64_t Addr) {
  for (Function &F : M) {
    StringRef Name = F.getName();
    for (const char *Prefix : {"sub_", "auto_sub_", "callback_sub_"}) {
      if (!Name.starts_with(Prefix))
        continue;
      StringRef Rest = Name.drop_front(strlen(Prefix));
      size_t Dot = Rest.find('.');
      if (Dot != StringRef::npos)
        Rest = Rest.substr(0, Dot);
      uint64_t FnAddr = 0;
      if (!Rest.getAsInteger(16, FnAddr) && FnAddr == Addr)
        return &F;
    }
  }
  return nullptr;
}

static std::optional<uint64_t> NamedDataGuestAddress(Value *V) {
  auto *GV = dyn_cast<GlobalValue>(V);
  if (!GV)
    return std::nullopt;
  StringRef Name = GV->getName();
  if (!Name.starts_with("data_"))
    return std::nullopt;
  uint64_t Addr = 0;
  StringRef Hex = Name.drop_front(StringRef("data_").size());
  if (Hex.empty() || Hex.getAsInteger(16, Addr))
    return std::nullopt;
  return Addr;
}

static std::optional<uint64_t> ConstantGuestAddress(Value *V) {
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return CI->getZExtValue();
  auto *CE = dyn_cast<ConstantExpr>(V);
  if (!CE || !CE->isCast() || CE->getNumOperands() != 1)
    return std::nullopt;
  auto *CI = dyn_cast<ConstantInt>(CE->getOperand(0));
  return CI ? std::optional<uint64_t>(CI->getZExtValue()) : std::nullopt;
}

static bool HasGuestCodeLabel(Module &M, uint64_t Addr) {
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      StringRef Name = BB.getName();
      for (const char *Prefix : {"inst_", "case_"}) {
        if (!Name.starts_with(Prefix))
          continue;
        StringRef Rest = Name.drop_front(strlen(Prefix));
        size_t Sep = Rest.find('_');
        if (Sep != StringRef::npos)
          Rest = Rest.substr(0, Sep);
        uint64_t LabelAddr = 0;
        if (!Rest.empty() && !Rest.getAsInteger(16, LabelAddr) &&
            (LabelAddr == Addr ||
             (LabelAddr > Addr && LabelAddr - Addr <= 16) ||
             (Addr > LabelAddr && Addr - LabelAddr <= 16)))
          return true;
      }
    }
  }
  return false;
}

static GlobalVariable *MaterializeCandidate(ObjectCandidate *Cand, GlobalDataContext &Ctx);

static bool CandidateHasObservedWrite(const ObjectCandidate *Cand,
                                      const GlobalDataContext &Ctx) {
  if (!Cand || !Cand->SourceSegment)
    return false;
  for (const auto &Ref : Ctx.AddressRefs) {
    if (!Ref || Ref->Segment != Cand->SourceSegment || !Ref->UserInst ||
        Ref->GuestAddr < Cand->Begin || Ref->GuestAddr >= Cand->End)
      continue;
    if (auto *SI = dyn_cast<StoreInst>(Ref->UserInst))
      if (SI->getPointerOperand() == Ref->OriginalValue)
        return true;
  }
  return false;
}

static GlobalVariable *MaterializeCandidate(ObjectCandidate *Cand, GlobalDataContext &Ctx) {
  if (!Cand)
    return nullptr;

  if (const RecoveredObject *Obj = Ctx.findObjectAt(Cand->Begin)) {
    return Obj->GV;
  }

  GuestSegment *Seg = Cand->SourceSegment;
  if (!Seg)
    return nullptr;
  // String extraction is intentionally not a generic mixed-blob split.  The
  // generator supplies the proof; repeat the section/mutability part at the
  // materialization boundary so a future candidate producer cannot bypass it.
  if (Cand->Kind == ObjectKind::StringLiteral &&
      (!Seg->BaseResolved || !Seg->ReadOnly || Seg->Writable ||
       Seg->Executable || CandidateHasObservedWrite(Cand, Ctx)))
    return nullptr;
  uint64_t Off = GetCandidateSourceOffset(Cand, Ctx);
  const uint64_t CandidateSize = Cand->End - Cand->Begin;
  if (CandidateSize > std::numeric_limits<uint64_t>::max() - Off)
    return nullptr;

  // Do not reinterpret relocation-bearing storage as bytes or integer
  // fields.  The flat image holds zero placeholders at those offsets; using
  // it for a RawBytes/Scalar/Array candidate would silently replace a dynamic
  // loader relocation or function pointer with zero.  PointerTable is the
  // sole owner allowed here because its materializer explicitly preserves
  // relocation constants as ptr fields.
  auto Reloc = Seg->Relocations.lower_bound(Off);
  if (Reloc != Seg->Relocations.end() &&
      Reloc->first < Off + CandidateSize &&
      Cand->Kind != ObjectKind::PointerTable)
    return nullptr;
  Constant *Init = nullptr;

  // Some lifted ELF images fold a large zero-initialized BSS tail into a
  // synthetic segment named __init_array.  The segment classifier therefore
  // says Data even though this particular recovered object has no file bytes
  // or relocations.  Treat only that proven zero range as zero-initialized;
  // do not let unrelated segment relocations become bytes of the object.
  bool RangeIsZero = true;
  for (uint64_t I = 0; I < CandidateSize; ++I) {
    if (Off + I >= Seg->FlatBytes.size() || Seg->FlatBytes[Off + I] != 0) {
      RangeIsZero = false;
      break;
    }
  }
  if (RangeIsZero) {
    for (const auto &Rel : Seg->Relocations) {
      if (Rel.first >= Off && Rel.first < Off + CandidateSize) {
        RangeIsZero = false;
        break;
      }
    }
  }
  bool StructuralZero = IsStructurallyZeroRange(
      Seg->GV->getInitializer(), Ctx.DL, Off,
      Off + (Cand->End - Cand->Begin));
  RangeIsZero = RangeIsZero || StructuralZero ||
                IsAliasBackedZeroObject(Cand, Ctx);

  if (Seg->Kind == SegmentKind::Bss || RangeIsZero) {
    Init = Constant::getNullValue(Cand->Ty);
  } else {
    if (Cand->Kind == ObjectKind::StringLiteral) {
      std::vector<uint8_t> Bytes(Seg->FlatBytes.begin() + Off,
                                 Seg->FlatBytes.begin() + Off + (Cand->End - Cand->Begin));
      StringRef BytesRef(reinterpret_cast<const char *>(Bytes.data()), Bytes.size());
      Init = ConstantDataArray::getString(Ctx.M.getContext(), BytesRef, false);
    } else if (Cand->Kind == ObjectKind::Array || Cand->Kind == ObjectKind::RawBytes) {
      auto *ArrTy = cast<ArrayType>(Cand->Ty);
      Type *ElemTy = ArrTy->getElementType();
      unsigned ElemSize = Ctx.DL.getTypeStoreSize(ElemTy);
      unsigned NumElems = ArrTy->getNumElements();

      if (Cand->Kind == ObjectKind::RawBytes || IsByteOnlyType(Cand->Ty)) {
        Init = ReadByteOnlyInit(Seg->FlatBytes, Ctx.DL, Off, Cand->Ty);
      } else if (ElemTy->isIntegerTy(8)) {
        std::vector<uint8_t> Bytes(Seg->FlatBytes.begin() + Off,
                                   Seg->FlatBytes.begin() + Off + NumElems);
        Init = ConstantDataArray::get(Ctx.M.getContext(), Bytes);
      } else {
        SmallVector<Constant *, 64> Elems;
        for (unsigned I = 0; I < NumElems; ++I) {
          Constant *E = ReadInitFromFlatBytes(Seg->FlatBytes,
                                              Seg->Relocations, Ctx.DL,
                                              Off + I * ElemSize, ElemTy);
          // Failure to decode an element is unresolved semantics, not a zero
          // initializer.  Substituting null/zero changes live program data and
          // violates the native contract; preserve the source segment so a
          // later rule (or strict verification) can diagnose it instead.
          if (!E) {
            Elems.clear();
            break;
          }
          Elems.push_back(E);
        }
        if (Elems.size() == NumElems)
          Init = ConstantArray::get(ArrTy, Elems);
      }
    } else if (Cand->Kind == ObjectKind::PointerTable) {
      auto *ArrTy = cast<ArrayType>(Cand->Ty);
      unsigned PtrSize = Ctx.DL.getPointerSize();
      unsigned NumElems = ArrTy->getNumElements();
      PointerType *PtrTy = PointerType::get(Ctx.M.getContext(), 0);

      // Relocation-backed entries into executable guest segments are jump
      // table labels, not callable pointers.  Materialize those as integer
      // guest targets so a native switch can consume them without creating
      // fixed guest inttoptr constants.
      bool IntegerTargets = true;
      for (unsigned I = 0; I < NumElems; ++I) {
        auto RelIt = Seg->Relocations.find(Off + I * PtrSize);
        auto TargetAddr = RelIt == Seg->Relocations.end()
                              ? std::nullopt
                              : NamedDataGuestAddress(RelIt->second);
        if (!TargetAddr && RelIt != Seg->Relocations.end())
          TargetAddr = ConstantGuestAddress(RelIt->second);
        GuestSegment *TargetSeg =
            TargetAddr ? Ctx.findSegmentForAddr(*TargetAddr) : nullptr;
        if ((!TargetSeg || !TargetSeg->Executable) &&
            (!TargetAddr || !HasGuestCodeLabel(Ctx.M, *TargetAddr))) {
          IntegerTargets = false;
          break;
        }
      }

      if (IntegerTargets) {
        IntegerType *IntTy = Type::getInt64Ty(Ctx.M.getContext());
        ArrayType *IntArrTy = ArrayType::get(IntTy, NumElems);
        SmallVector<Constant *, 32> Targets;
        for (unsigned I = 0; I < NumElems; ++I) {
          uint64_t EntryVal = 0;
          auto RelIt = Seg->Relocations.find(Off + I * PtrSize);
          if (RelIt != Seg->Relocations.end()) {
            if (auto Addr = NamedDataGuestAddress(RelIt->second))
              EntryVal = *Addr;
            else if (auto Addr = ConstantGuestAddress(RelIt->second))
              EntryVal = *Addr;
          } else {
            for (unsigned B = 0; B < PtrSize; ++B)
              EntryVal |= (uint64_t)Seg->FlatBytes[Off + I * PtrSize + B]
                          << (B * 8);
          }
          Targets.push_back(ConstantInt::get(IntTy, EntryVal));
        }
        Init = ConstantArray::get(IntArrTy, Targets);
      } else {

        SmallVector<Constant *, 32> Elems;
        for (unsigned I = 0; I < NumElems; ++I) {
        uint64_t EntryVal = 0;
        for (unsigned B = 0; B < PtrSize; ++B)
          EntryVal |= (uint64_t)Seg->FlatBytes[Off + I * PtrSize + B] << (B * 8);

        Constant *Target = nullptr;

        auto RelIt = Seg->Relocations.find(Off + I * PtrSize);
        if (RelIt != Seg->Relocations.end()) {
          Target = RelIt->second;
        } else {
          Function *Fn = FindFnByGuestAddr(Ctx.M, EntryVal);
          if (Fn) {
            Target = Fn;
          } else {
            const RecoveredObject *TargetObj = Ctx.findObjectAt(EntryVal);
            if (TargetObj && TargetObj->GV) {
              Target = TargetObj->GV;
            } else {
              ObjectCandidate *TargetCand = nullptr;
              for (auto &C : Ctx.Candidates) {
                if (EntryVal >= C->Begin && EntryVal < C->End) {
                  TargetCand = C.get();
                  break;
                }
              }
              if (TargetCand && TargetCand != Cand) {
                Target = MaterializeCandidate(TargetCand, Ctx);
              }
            }
          }
        }

          if (Target) {
            Constant *CastVal = ConstantExpr::getPointerCast(Target, PtrTy);
            Elems.push_back(CastVal);
          } else if (EntryVal == 0) {
            // A zero entry is a proven null pointer.  A non-zero unresolved
            // address must never be silently rewritten to null.
            Elems.push_back(Constant::getNullValue(PtrTy));
          } else {
            Elems.clear();
            break;
          }
        }
        if (Elems.size() == NumElems)
          Init = ConstantArray::get(ArrTy, Elems);
      }
    } else {
      Init = ReadInitFromFlatBytes(Seg->FlatBytes, Seg->Relocations, Ctx.DL,
                                   Off, Cand->Ty);
    }
  }

  if (!Init)
    return nullptr;

  std::string Name = Cand->Name;
  const bool HasObservedWrite = CandidateHasObservedWrite(Cand, Ctx);
  bool IsReadOnly = Seg->ReadOnly && !HasObservedWrite;
  GlobalValue::LinkageTypes Linkage = GlobalValue::InternalLinkage;

  if (Cand->Kind == ObjectKind::StringLiteral) {
    Name = ".str." + std::to_string(Ctx.NextStringId++);
    Linkage = GlobalValue::PrivateLinkage;
    IsReadOnly = true;
  } else if (Cand->Kind == ObjectKind::Scalar) {
    Name = "g_scalar_" + std::to_string(Ctx.NextScalarId++);
  } else if (Cand->Kind == ObjectKind::Array) {
    Name = "g_arr_" + std::to_string(Ctx.NextArrayId++);
  } else if (Cand->Kind == ObjectKind::PointerTable) {
    Name = "g_ptrtable_" + std::to_string(Ctx.NextPtrTableId++);
  }

  auto *GV = new GlobalVariable(Ctx.M, Init->getType(), IsReadOnly,
                                Linkage, Init, Name);
  // The recovered field begins inside a live source object.  Its alignment is
  // constrained by that source placement, not by the ABI preference for the
  // newly-created type (e.g. i32 at residual+2 is not align 4).  The scalar
  // preflight has already rejected overlapping typed intervals, but retain
  // the physical alignment proof for every materialized candidate.
  const Align SourceAlign = Seg->GV->getAlign().valueOrOne();
  GV->setAlignment(commonAlignment(SourceAlign, Off));

  // Keep the original ELF range as non-semantic provenance for the final
  // native cleanup pass.  It is needed when an ABI/state rewrite recreates a
  // dynamic pointer expression after this pass has already rewritten the
  // direct constant references.
  SmallVector<Metadata *, 2> RangeMetadata;
  RangeMetadata.push_back(ConstantAsMetadata::get(
      ConstantInt::get(Type::getInt64Ty(Ctx.M.getContext()), Cand->Begin)));
  RangeMetadata.push_back(ConstantAsMetadata::get(
      ConstantInt::get(Type::getInt64Ty(Ctx.M.getContext()), Cand->End)));
  GV->setMetadata("brighten.guest.range", MDNode::get(Ctx.M.getContext(),
                                                       RangeMetadata));

  // A dynamic address can remain in a State slot until ABI/native cleanup
  // reconstructs the pointer consumer.  At this point the recovered object
  // has no direct IR use yet, so globaldce would otherwise erase both it and
  // the range provenance before that late rewrite runs.  Keep byte-backed
  // objects alive through the intervening optimization pipeline; final
  // native cleanup removes temporary native-data roots once their consumers
  // have been materialized.
  if (Cand->Kind == ObjectKind::RawBytes)
    appendToUsed(Ctx.M, {GV});

  if (Cand->Kind == ObjectKind::StringLiteral) {
    GV->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  }

  auto Obj = std::make_unique<RecoveredObject>();
  Obj->Begin = Cand->Begin;
  Obj->End = Cand->End;
  Obj->Kind = Cand->Kind;
  Obj->Ty = Init->getType();
  Obj->GV = GV;
  Obj->SourceSegment = Seg;
  Obj->ReadOnly = IsReadOnly;
  Obj->HasWrites = HasObservedWrite;
  Obj->Name = Name;
  Obj->Action = "recovered-" + Name;
  Obj->RequiresTransactionalDirectRewrite =
      Cand->RequiresTransactionalDirectRewrite;

  if (Cand->Kind == ObjectKind::StringLiteral)
    ++Ctx.Report.StringsRecovered;
  else if (Cand->Kind == ObjectKind::Scalar)
    ++Ctx.Report.GlobalScalarsRecovered;
  else if (Cand->Kind == ObjectKind::Array)
    ++Ctx.Report.GlobalArraysRecovered;
  else if (Cand->Kind == ObjectKind::PointerTable)
    ++Ctx.Report.PointerTablesRecovered;

  auto *RetGV = GV;
  Ctx.RecoveredObjects[Cand->Begin] = std::move(Obj);
  return RetGV;
}

bool BrightenGlobalDataRecoveryPass::MaterializeRecoveredGlobals(
    GlobalDataContext &Ctx) {
  bool Changed = false;
  for (auto &Cand : Ctx.Candidates) {
    if (Ctx.findObjectAt(Cand->Begin))
      continue;
    if (MaterializeCandidate(Cand.get(), Ctx)) {
      Changed = true;
    }
  }
  return Changed;
}

} // namespace brighten_global
