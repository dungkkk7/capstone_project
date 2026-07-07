#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <cctype>
#include <map>
#include <set>
#include <cstring>

namespace brighten_global {

using namespace llvm;

static bool IsPrintableOrControl(uint8_t C) {
  return C == 0 || C == '\n' || C == '\r' || C == '\t' || C == '\\' ||
         (C >= 0x20 && C <= 0x7E);
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

static void GenerateStringCandidates(GlobalDataContext &Ctx, GuestSegment *Seg) {
  if (Seg->FlatBytes.empty())
    return;

  std::set<uint64_t> RefAddrs;
  for (auto &Ref : Ctx.AddressRefs) {
    if (Ref->Segment == Seg)
      RefAddrs.insert(Ref->GuestAddr);
  }

  for (uint64_t Addr : RefAddrs) {
    uint64_t Off = Addr - Seg->GuestBase;
    if (Off >= Seg->FlatBytes.size())
      continue;

    uint64_t End = Off;
    bool AllPrintable = true;
    while (End < Seg->FlatBytes.size() && Seg->FlatBytes[End] != 0) {
      if (!IsPrintableOrControl(Seg->FlatBytes[End]))
        AllPrintable = false;
      ++End;
    }

    bool NullTerm = (End < Seg->FlatBytes.size() && Seg->FlatBytes[End] == 0);
    uint64_t Len = End - Off + (NullTerm ? 1 : 0);

    if (!NullTerm || Len < 2 || !AllPrintable)
      continue;

    unsigned Confidence = 0;
    SmallVector<UseEvidence, 8> EvList;
    bool HasStrongEvidence = false;

    for (auto &Ref : Ctx.AddressRefs) {
      if (Ref->GuestAddr >= Addr && Ref->GuestAddr < Addr + Len) {
        for (auto &Ev : Ref->EvidenceList) {
          EvList.push_back(Ev);
          Confidence += Ev.Confidence;
          if (Ev.Kind == EvidenceKind::LibcStringArg ||
              Ev.Kind == EvidenceKind::FormatStringArg) {
            HasStrongEvidence = true;
          }
        }
      }
    }

    if (!HasStrongEvidence)
      continue;

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = Addr;
    Cand->End = Addr + Len;
    Cand->Kind = ObjectKind::StringLiteral;
    Cand->Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), Len);
    Cand->Confidence = Confidence;
    Cand->EvidenceList = std::move(EvList);
    Cand->SourceSegment = Seg;
    Cand->Name = "str_cand_" + Twine::utohexstr(Addr).str();
    Ctx.Candidates.push_back(std::move(Cand));
  }
}

static void GenerateArrayCandidates(GlobalDataContext &Ctx, GuestSegment *Seg) {
  struct ElementAccess {
    uint64_t GuestAddr;
    unsigned ElemSize;
    Type *ElemTy;
    bool IsWrite;
  };

  SmallVector<ElementAccess, 64> Accesses;
  for (auto &Ref : Ctx.AddressRefs) {
    if (Ref->Segment != Seg)
      continue;

    Instruction *User = Ref->UserInst;
    if (!User)
      continue;

    Type *AccessTy = nullptr;
    bool IsWrite = false;

    if (auto *LI = dyn_cast<LoadInst>(User)) {
      AccessTy = LI->getType();
    } else if (auto *SI = dyn_cast<StoreInst>(User)) {
      if (SI->getPointerOperand() == Ref->OriginalValue) {
        AccessTy = SI->getValueOperand()->getType();
        IsWrite = true;
      }
    }

    if (!AccessTy)
      continue;
    unsigned ElemSize = Ctx.DL.getTypeStoreSize(AccessTy);
    if (ElemSize == 0 || ElemSize > 8)
      continue;

    ElementAccess EA;
    EA.GuestAddr = Ref->GuestAddr;
    EA.ElemSize = ElemSize;
    EA.ElemTy = AccessTy;
    EA.IsWrite = IsWrite;
    Accesses.push_back(EA);
  }

  if (Accesses.empty())
    return;

  // Check if there is ANY dynamic/indexed GEP using the segment GV directly
  bool HasIndexedUse = false;
  if (Seg->GV) {
    for (User *U : Seg->GV->users()) {
      if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
        if (GEP->getNumIndices() >= 2 && !isa<ConstantInt>(GEP->getOperand(2))) {
          HasIndexedUse = true;
          break;
        }
      }
    }
  }

  std::map<unsigned, SmallVector<ElementAccess, 32>> BySize;
  for (auto &A : Accesses)
    BySize[A.ElemSize].push_back(A);

  for (auto &[ElemSize, EAs] : BySize) {
    std::sort(EAs.begin(), EAs.end(),
              [](const ElementAccess &A, const ElementAccess &B) {
                return A.GuestAddr < B.GuestAddr;
              });

    std::vector<uint64_t> UniqueAddrs;
    bool HasWrite = false;
    Type *ElemTy = EAs[0].ElemTy;
    for (auto &EA : EAs) {
      if (UniqueAddrs.empty() || UniqueAddrs.back() != EA.GuestAddr)
        UniqueAddrs.push_back(EA.GuestAddr);
      if (EA.IsWrite)
        HasWrite = true;
    }



    size_t ClusterStart = 0;
    while (ClusterStart < UniqueAddrs.size()) {
      size_t ClusterEnd = ClusterStart + 1;
      while (ClusterEnd < UniqueAddrs.size()) {
        uint64_t Expected = UniqueAddrs[ClusterStart] +
                            (ClusterEnd - ClusterStart) * ElemSize;
        if (UniqueAddrs[ClusterEnd] != Expected)
          break;
        ++ClusterEnd;
      }

      unsigned NumElems = ClusterEnd - ClusterStart;
      if (NumElems < 2) {
        ClusterStart = ClusterEnd;
        continue;
      }

      uint64_t ArrayBegin = UniqueAddrs[ClusterStart];
      uint64_t ArrayEnd = ArrayBegin + (uint64_t)NumElems * ElemSize;

      auto Cand = std::make_unique<ObjectCandidate>();
      Cand->Begin = ArrayBegin;
      Cand->End = ArrayEnd;
      Cand->Kind = ObjectKind::Array;
      Cand->Ty = ArrayType::get(ElemTy, NumElems);
      Cand->SourceSegment = Seg;
      Cand->Name = "arr_cand_" + Twine::utohexstr(ArrayBegin).str();

      UseEvidence Ev;
      Ev.Kind = EvidenceKind::IndexedStrideAccess;
      Ev.Confidence = 200;
      Cand->EvidenceList.push_back(Ev);
      Cand->Confidence = Ev.Confidence;

      if (HasWrite) {
        UseEvidence WEv;
        WEv.Kind = EvidenceKind::WriteObserved;
        WEv.Confidence = 10;
        Cand->EvidenceList.push_back(WEv);
      }

      Ctx.Candidates.push_back(std::move(Cand));
      ClusterStart = ClusterEnd;
    }
  }
}

static void GenerateScalarCandidates(GlobalDataContext &Ctx, GuestSegment *Seg) {
  std::map<uint64_t, SmallVector<std::pair<Type*, bool>, 4>> AccessMap;

  for (auto &Ref : Ctx.AddressRefs) {
    if (Ref->Segment != Seg)
      continue;
    Instruction *User = Ref->UserInst;
    if (!User)
      continue;

    Type *AccessTy = nullptr;
    bool IsWrite = false;

    if (auto *LI = dyn_cast<LoadInst>(User)) {
      AccessTy = LI->getType();
    } else if (auto *SI = dyn_cast<StoreInst>(User)) {
      if (SI->getPointerOperand() == Ref->OriginalValue) {
        AccessTy = SI->getValueOperand()->getType();
        IsWrite = true;
      }
    }

    if (!AccessTy)
      continue;
    unsigned Width = Ctx.DL.getTypeStoreSize(AccessTy);
    if (Width == 0 || Width > 8)
      continue;

    AccessMap[Ref->GuestAddr].push_back({AccessTy, IsWrite});
  }

  for (auto &[Addr, Accesses] : AccessMap) {
    if (Accesses.empty())
      continue;

    unsigned Width = Ctx.DL.getTypeStoreSize(Accesses[0].first);
    bool Consistent = true;
    bool HasWrite = false;
    Type *Ty = Accesses[0].first;

    for (auto &Acc : Accesses) {
      if (Ctx.DL.getTypeStoreSize(Acc.first) != Width) {
        Consistent = false;
        break;
      }
      if (Acc.second)
        HasWrite = true;
    }

    if (!Consistent)
      continue;

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = Addr;
    Cand->End = Addr + Width;
    Cand->Kind = ObjectKind::Scalar;
    Cand->Ty = Ty;
    Cand->SourceSegment = Seg;
    Cand->Name = "scalar_cand_" + Twine::utohexstr(Addr).str();

    UseEvidence Ev;
    Ev.Kind = EvidenceKind::LoadStoreWidth;
    Ev.Confidence = 50;
    Cand->EvidenceList.push_back(Ev);
    Cand->Confidence = 50;

    if (HasWrite) {
      UseEvidence WEv;
      WEv.Kind = EvidenceKind::WriteObserved;
      WEv.Confidence = 10;
      Cand->EvidenceList.push_back(WEv);
    }

    Ctx.Candidates.push_back(std::move(Cand));
  }
}

static void GeneratePointerTableCandidates(GlobalDataContext &Ctx, GuestSegment *Seg) {
  unsigned PtrSize = Ctx.DL.getPointerSize();
  uint64_t SegEnd = Seg->GuestBase + Seg->Size;

  std::set<uint64_t> CandidateAddrs;
  for (auto &Ref : Ctx.AddressRefs) {
    if (Ref->Segment != Seg)
      continue;
    if (Ref->GuestAddr % PtrSize != 0)
      continue;
    CandidateAddrs.insert(Ref->GuestAddr);
  }

  for (uint64_t Addr : CandidateAddrs) {
    SmallVector<uint64_t, 32> Entries;
    uint64_t Curr = Addr;
    unsigned MaxEntries = 512;
    bool HasRelocs = false;

    while (Curr + PtrSize <= SegEnd && Entries.size() < MaxEntries) {
      uint64_t Offset = Curr - Seg->GuestBase;
      if (Seg->Relocations.count(Offset)) {
        HasRelocs = true;
      }

      SmallVector<uint8_t, 8> Bytes;
      if (!Ctx.readSegmentBytes(Seg, Curr, PtrSize, Bytes))
        break;

      uint64_t Val = 0;
      for (unsigned I = 0; I < PtrSize; ++I)
        Val |= (uint64_t)Bytes[I] << (I * 8);

      if (Val == 0 && !Seg->Relocations.count(Offset))
        break;

      bool Valid = false;
      if (FindFnByGuestAddr(Ctx.M, Val))
        Valid = true;
      if (Ctx.findSegmentForAddr(Val))
        Valid = true;
      if (Seg->Relocations.count(Offset))
        Valid = true;

      if (!Valid)
        break;

      Entries.push_back(Val);
      Curr += PtrSize;
    }

    if (Entries.size() < 2 || !HasRelocs)
      continue;

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = Addr;
    Cand->End = Addr + Entries.size() * PtrSize;
    Cand->Kind = ObjectKind::PointerTable;
    Cand->Ty = ArrayType::get(PointerType::get(Ctx.M.getContext(), 0), Entries.size());
    Cand->SourceSegment = Seg;
    Cand->Name = "ptrtable_cand_" + Twine::utohexstr(Addr).str();

    UseEvidence Ev;
    Ev.Kind = EvidenceKind::PointerTableUse;
    Ev.Confidence = 150;
    Cand->EvidenceList.push_back(Ev);
    Cand->Confidence = 150;

    Ctx.Candidates.push_back(std::move(Cand));
  }
}

bool BrightenGlobalDataRecoveryPass::GenerateObjectCandidates(
    GlobalDataContext &Ctx) {
  Ctx.Candidates.clear();

  for (auto &Seg : Ctx.Segments) {
    if (!Seg->BaseResolved)
      continue;

    GenerateStringCandidates(Ctx, Seg.get());
    GenerateArrayCandidates(Ctx, Seg.get());
    GenerateScalarCandidates(Ctx, Seg.get());
    GeneratePointerTableCandidates(Ctx, Seg.get());
  }

  if (Ctx.Debug && !Ctx.Candidates.empty())
    errs() << "[brighten-global-data] generated " << Ctx.Candidates.size()
           << " object candidates\n";

  return !Ctx.Candidates.empty();
}

} // namespace brighten_global
