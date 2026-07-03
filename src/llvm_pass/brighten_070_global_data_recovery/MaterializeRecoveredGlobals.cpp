#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/Support/raw_ostream.h"

#include <cstring>

namespace brighten_global {

using namespace llvm;

static Constant *ReadInitFromFlatBytes(const std::vector<uint8_t> &FlatBytes,
                                       const std::map<uint64_t, Constant *> &Relocs,
                                       uint64_t Off, Type *Ty) {
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

  if (Ty->isIntegerTy(8)) {
    return ConstantInt::get(Ty, FlatBytes[Off]);
  }
  if (Ty->isIntegerTy(16)) {
    uint16_t Val = FlatBytes[Off] | (FlatBytes[Off + 1] << 8);
    return ConstantInt::get(Ty, Val);
  }
  if (Ty->isIntegerTy(32)) {
    uint32_t Val = FlatBytes[Off] | (FlatBytes[Off + 1] << 8) |
                   (FlatBytes[Off + 2] << 16) | (FlatBytes[Off + 3] << 24);
    return ConstantInt::get(Ty, Val);
  }
  if (Ty->isIntegerTy(64)) {
    uint64_t Val = 0;
    for (unsigned I = 0; I < 8; ++I)
      Val |= (uint64_t)FlatBytes[Off + I] << (I * 8);
    return ConstantInt::get(Ty, Val);
  }
  if (Ty->isFloatTy()) {
    uint32_t Val = FlatBytes[Off] | (FlatBytes[Off + 1] << 8) |
                   (FlatBytes[Off + 2] << 16) | (FlatBytes[Off + 3] << 24);
    float F;
    memcpy(&F, &Val, 4);
    return ConstantFP::get(Ty, F);
  }
  if (Ty->isDoubleTy()) {
    uint64_t Val = 0;
    for (unsigned I = 0; I < 8; ++I)
      Val |= (uint64_t)FlatBytes[Off + I] << (I * 8);
    double D;
    memcpy(&D, &Val, 8);
    return ConstantFP::get(Ty, D);
  }
  return nullptr;
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

bool BrightenGlobalDataRecoveryPass::MaterializeRecoveredGlobals(
    GlobalDataContext &Ctx) {
  bool Changed = false;

  for (auto &Cand : Ctx.Candidates) {
    if (Ctx.findObjectAt(Cand->Begin))
      continue;

    GuestSegment *Seg = Cand->SourceSegment;
    if (!Seg)
      continue;

    uint64_t Off = Cand->Begin - Seg->GuestBase;
    Constant *Init = nullptr;

    if (Seg->Kind == SegmentKind::Bss) {
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

        if (ElemTy->isIntegerTy(8)) {
          std::vector<uint8_t> Bytes(Seg->FlatBytes.begin() + Off,
                                     Seg->FlatBytes.begin() + Off + NumElems);
          Init = ConstantDataArray::get(Ctx.M.getContext(), Bytes);
        } else {
          SmallVector<Constant *, 64> Elems;
          for (unsigned I = 0; I < NumElems; ++I) {
            Constant *E = ReadInitFromFlatBytes(Seg->FlatBytes, Seg->Relocations, Off + I * ElemSize, ElemTy);
            if (!E)
              E = Constant::getNullValue(ElemTy);
            Elems.push_back(E);
          }
          Init = ConstantArray::get(ArrTy, Elems);
        }
      } else if (Cand->Kind == ObjectKind::PointerTable) {
        auto *ArrTy = cast<ArrayType>(Cand->Ty);
        unsigned PtrSize = Ctx.DL.getPointerSize();
        unsigned NumElems = ArrTy->getNumElements();
        PointerType *PtrTy = PointerType::get(Ctx.M.getContext(), 0);

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
              const RecoveredObject *Obj = Ctx.findObjectAt(EntryVal);
              if (Obj && Obj->GV)
                Target = Obj->GV;
            }
          }

          if (Target) {
            Constant *CastVal = ConstantExpr::getPointerCast(Target, PtrTy);
            Elems.push_back(CastVal);
          } else {
            Elems.push_back(Constant::getNullValue(PtrTy));
          }
        }
        Init = ConstantArray::get(ArrTy, Elems);
      } else {
        Init = ReadInitFromFlatBytes(Seg->FlatBytes, Seg->Relocations, Off, Cand->Ty);
      }
    }

    if (!Init)
      continue;

    std::string Name = Cand->Name;
    bool IsReadOnly = Seg->ReadOnly;
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
    GV->setAlignment(Align(Ctx.DL.getABITypeAlign(Init->getType())));

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
    Obj->Name = Name;
    Obj->Action = "recovered-" + Name;

    if (Cand->Kind == ObjectKind::StringLiteral)
      ++Ctx.Report.StringsRecovered;
    else if (Cand->Kind == ObjectKind::Scalar)
      ++Ctx.Report.GlobalScalarsRecovered;
    else if (Cand->Kind == ObjectKind::Array)
      ++Ctx.Report.GlobalArraysRecovered;
    else if (Cand->Kind == ObjectKind::PointerTable)
      ++Ctx.Report.PointerTablesRecovered;

    Ctx.RecoveredObjects[Cand->Begin] = std::move(Obj);
    Changed = true;
  }

  return Changed;
}

} // namespace brighten_global
