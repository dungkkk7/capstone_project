#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <cctype>
#include <map>
#include <optional>
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
  // Some format/result strings are selected through a constant pointer in a
  // lifted state value and never reach a direct load/call evidence site.  The
  // named ELF alias is still a valid symbol-boundary proof for those strings;
  // include it in discovery so a later integer carrier can be rebased to the
  // complete literal rather than a pointer-sized raw-byte placeholder.
  if (!Seg->Executable) {
    for (GlobalAlias &GA : Ctx.M.aliases()) {
      if (!GA.getName().starts_with("data_"))
        continue;
      uint64_t AliasAddr = 0;
      StringRef Hex = GA.getName().drop_front(StringRef("data_").size());
      if (!Hex.empty() && !Hex.getAsInteger(16, AliasAddr) &&
          AliasAddr >= Seg->GuestBase &&
          AliasAddr < Seg->GuestBase + Seg->Size)
        RefAddrs.insert(AliasAddr);
    }
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

    // A memcpy source/destination is a byte region, not a C string.  When
    // the region begins at a string-looking alias, keep adjacent
    // NUL-separated literals in one object; otherwise materialization turns
    // e.g. a 40-byte command table into only the first 6-byte string.
    bool HasBufferUse = false;
    for (auto &Ref : Ctx.AddressRefs) {
      if (Ref->GuestAddr < Addr || Ref->GuestAddr >= Addr + Len)
        continue;
      HasBufferUse |= Ref->ConsumerKind == DataConsumerKind::LibcWriteBufferArg;
    }
    // Several adjacent ELF aliases are a strong indication of a packed
    // lookup/command table rather than independent C strings.
    unsigned AdjacentAliases = 0;
    for (GlobalAlias &GA : Ctx.M.aliases()) {
      StringRef N = GA.getName();
      if (!N.starts_with("data_"))
        continue;
      uint64_t A = 0;
      if (!N.drop_front(5).getAsInteger(16, A) && A >= Addr &&
          A < Addr + 64)
        ++AdjacentAliases;
    }
    HasBufferUse |= AdjacentAliases >= 4;
    uint64_t NextAlias = Seg->GuestBase + Seg->Size;
    bool HasNextAlias = false;
    for (GlobalAlias &GA : Ctx.M.aliases()) {
      StringRef N = GA.getName();
      if (!N.starts_with("data_"))
        continue;
      uint64_t A = 0;
      if (!N.drop_front(5).getAsInteger(16, A) && A > Addr && A < NextAlias) {
        NextAlias = A;
        HasNextAlias = true;
      }
    }
    // The segment end is only a storage boundary, not evidence that adjacent
    // NUL-terminated literals form one byte object.  Extend to a boundary
    // only when an actual ELF alias proves it (or a buffer consumer above
    // proves the wider access).  Otherwise independent rodata strings would
    // be merged and lose their own native identities.
    if (HasNextAlias && NextAlias > Addr + Len && NextAlias - Addr <= 64)
      HasBufferUse = true;
    if (HasBufferUse) {
      uint64_t Cursor = Off + Len;
      while (Cursor < Seg->FlatBytes.size()) {
        uint64_t Next = Cursor;
        while (Next < Seg->FlatBytes.size() && Seg->FlatBytes[Next] != 0) {
          if (!IsPrintableOrControl(Seg->FlatBytes[Next]))
            break;
          ++Next;
        }
        if (Next == Cursor || Next >= Seg->FlatBytes.size() ||
            Seg->FlatBytes[Next] != 0)
          break;
        ++Next;
        Len = Next - Off;
        Cursor = Next;
      }
      if (HasNextAlias && NextAlias > Addr + Len &&
          NextAlias <= Seg->GuestBase + Seg->Size)
        Len = NextAlias - Addr;
    }

    unsigned Confidence = 0;
    SmallVector<UseEvidence, 8> EvList;
    bool HasStrongEvidence = false;
    bool HasNamedDataAlias = false;

    // A named ELF alias is itself a symbol-boundary proof.  This matters for
    // format strings whose address is first stored into the lifted register
    // state and only reaches printf/scanf several blocks later, so the local
    // callsite classifier cannot see the eventual libc use.
    for (GlobalAlias &GA : Ctx.M.aliases()) {
      if (!GA.getName().starts_with("data_"))
        continue;
      uint64_t AliasAddr = 0;
      StringRef Hex = GA.getName().drop_front(StringRef("data_").size());
      if (!Hex.empty() && !Hex.getAsInteger(16, AliasAddr) &&
          AliasAddr == Addr) {
        HasNamedDataAlias = true;
        break;
      }
    }

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

    if (!HasStrongEvidence && !HasNamedDataAlias)
      continue;

    if (HasNamedDataAlias && !HasStrongEvidence) {
      UseEvidence Boundary;
      Boundary.Kind = EvidenceKind::SymbolBoundary;
      Boundary.Confidence = 40;
      Boundary.Description = "named ELF data alias with exact string bounds";
      EvList.push_back(Boundary);
      Confidence += Boundary.Confidence;
    }

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = Addr;
    Cand->End = Addr + Len;
    Cand->Kind = HasBufferUse ? ObjectKind::RawBytes : ObjectKind::StringLiteral;
    Cand->Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), Len);
    Cand->Confidence = Confidence;
    if (HasBufferUse)
      Cand->Confidence += 120;
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

static bool ExtractDynamicScale(Value *V, uint64_t &Scale,
                                SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  V = V->stripPointerCasts();
  if (isa<ConstantInt>(V))
    return false;
  if (auto *Cast = dyn_cast<CastInst>(V))
    return ExtractDynamicScale(Cast->getOperand(0), Scale, Seen);
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    unsigned Opc = BO->getOpcode();
    if (Opc == Instruction::Mul) {
      if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(0))) {
        uint64_t Inner = 1;
        if (ExtractDynamicScale(BO->getOperand(1), Inner, Seen)) {
          Scale = C->getZExtValue() * Inner;
          return Scale != 0;
        }
      }
      if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1))) {
        uint64_t Inner = 1;
        if (ExtractDynamicScale(BO->getOperand(0), Inner, Seen)) {
          Scale = C->getZExtValue() * Inner;
          return Scale != 0;
        }
      }
    }
    if (Opc == Instruction::Shl) {
      if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1))) {
        uint64_t Inner = 1;
        if (ExtractDynamicScale(BO->getOperand(0), Inner, Seen)) {
          unsigned Shift = C->getLimitedValue(63);
          Scale = Inner << Shift;
          return Scale != 0;
        }
      }
    }
    if (Opc == Instruction::Add || Opc == Instruction::Sub) {
      if (isa<ConstantInt>(BO->getOperand(0)))
        return ExtractDynamicScale(BO->getOperand(1), Scale, Seen);
      if (isa<ConstantInt>(BO->getOperand(1)))
        return ExtractDynamicScale(BO->getOperand(0), Scale, Seen);
    }
  }
  // A remaining non-constant value is an index with byte scale one.
  Scale = 1;
  return true;
}

static std::optional<uint64_t> NamedGuestAddress(Value *V) {
  auto *GV = dyn_cast<GlobalValue>(V);
  if (!GV)
    GV = dyn_cast<GlobalValue>(V ? V->stripPointerCasts() : nullptr);
  if (!GV || !GV->getName().starts_with("data_"))
    return std::nullopt;
  uint64_t Address = 0;
  StringRef Hex = GV->getName().drop_front(StringRef("data_").size());
  if (Hex.empty() || Hex.getAsInteger(16, Address))
    return std::nullopt;
  return Address;
}

static std::optional<uint64_t>
SegmentRootGuestAddress(Value *V, GuestSegment *Seg, const DataLayout &DL,
                        SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second || !Seg)
    return std::nullopt;
  V = V->stripPointerCasts();
  if (V == Seg->GV)
    return Seg->GuestBase;

  if (auto Named = NamedGuestAddress(V))
    return Named;

  if (auto *GA = dyn_cast<GlobalAlias>(V)) {
    if (Constant *Aliasee = GA->getAliasee())
      return SegmentRootGuestAddress(Aliasee, Seg, DL, Seen);
    return std::nullopt;
  }

  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP)
    return std::nullopt;
  auto Base = SegmentRootGuestAddress(GEP->getPointerOperand(), Seg, DL,
                                      Seen);
  if (!Base)
    return std::nullopt;
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  if (!GEP->accumulateConstantOffset(DL, Offset) || Offset.isNegative())
    return std::nullopt;
  return *Base + Offset.getZExtValue();
}

static std::optional<uint64_t> NamedAliasAddressInSegment(Module &M,
                                                           GuestSegment *Seg,
                                                           uint64_t Addr) {
  uint64_t Best = Seg->GuestBase + Seg->Size;
  for (GlobalAlias &GA : M.aliases()) {
    auto AliasAddr = NamedGuestAddress(&GA);
    if (!AliasAddr || *AliasAddr <= Addr || *AliasAddr < Seg->GuestBase ||
        *AliasAddr >= Seg->GuestBase + Seg->Size)
      continue;
    Best = std::min(Best, *AliasAddr);
  }
  return Best;
}

// A lifted binary often has aliases for individual fields of the first few
// elements of a record array.  Those aliases are evidence *inside* the array,
// not a boundary for it.  In particular, treating `base + stride` as the next
// object shrinks a heap/queue array to one record and silently corrupts every
// later indexed access.  If an alias proves that a second record exists, keep
// consuming the contiguous alias run and use the first real gap as the object
// boundary.  Without that proof, retain the conservative next-alias rule.
static uint64_t DynamicRecordArrayEnd(GlobalDataContext &Ctx,
                                      GuestSegment *Seg, uint64_t Begin,
                                      uint64_t Stride) {
  const uint64_t SegEnd = Seg->GuestBase + Seg->Size;
  if (Stride == 0 || Begin >= SegEnd)
    return SegEnd;

  SmallVector<uint64_t, 16> Aliases;
  for (GlobalAlias &GA : Ctx.M.aliases()) {
    auto AliasAddr = NamedGuestAddress(&GA);
    if (!AliasAddr || *AliasAddr <= Begin || *AliasAddr >= SegEnd)
      continue;
    Aliases.push_back(*AliasAddr);
  }

  if (Aliases.empty())
    return SegEnd;
  std::sort(Aliases.begin(), Aliases.end());

  bool HasRecordAliasRun = false;
  size_t RunStart = 0;
  uint64_t Previous = Begin;
  if (Stride <= SegEnd - Begin &&
      llvm::is_contained(Aliases, Begin + Stride)) {
    HasRecordAliasRun = true;
  } else {
    // Debug/data aliases do not necessarily name the first indexed element.
    // Two later aliases on consecutive stride boundaries still prove that
    // they are entries inside the same dynamically indexed object.
    for (size_t I = 0; I + 1 < Aliases.size(); ++I) {
      if ((Aliases[I] - Begin) % Stride == 0 &&
          (Aliases[I + 1] - Begin) % Stride == 0 &&
          Aliases[I + 1] - Aliases[I] == Stride) {
        HasRecordAliasRun = true;
        Previous = Aliases[I];
        RunStart = I + 1;
        break;
      }
    }
  }

  if (!HasRecordAliasRun) {
    // An alias inside the first stride is a field boundary, not the end of
    // the dynamically indexed record array.  Use the first alias at or beyond
    // the next record as the conservative object boundary.
    for (uint64_t AliasAddr : Aliases)
      if (AliasAddr - Begin >= Stride)
        return AliasAddr;
    return SegEnd;
  }

  for (size_t I = RunStart; I < Aliases.size(); ++I) {
    uint64_t AliasAddr = Aliases[I];
    if (AliasAddr - Previous > Stride)
      return AliasAddr;
    Previous = AliasAddr;
  }
  return SegEnd;
}

static void GenerateDynamicRecordCandidates(GlobalDataContext &Ctx,
                                             GuestSegment *Seg) {
  struct DynamicUse {
    uint64_t Begin = 0;
    uint64_t Stride = 0;
    Type *AccessTy = nullptr;
    bool IsWrite = false;
  };
  SmallVector<DynamicUse, 32> Uses;

  for (Function &F : Ctx.M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *GEP = dyn_cast<GetElementPtrInst>(&I);
        if (!GEP)
          continue;
        SmallPtrSet<Value *, 16> BaseSeen;
        auto BaseAddress = SegmentRootGuestAddress(
            GEP->getPointerOperand(), Seg, Ctx.DL, BaseSeen);
        if (!BaseAddress || *BaseAddress < Seg->GuestBase ||
            *BaseAddress >= Seg->GuestBase + Seg->Size)
          continue;

        Value *DynamicIndex = nullptr;
        for (unsigned Op = 1; Op < GEP->getNumOperands(); ++Op) {
          if (!isa<ConstantInt>(GEP->getOperand(Op))) {
            DynamicIndex = GEP->getOperand(Op);
            break;
          }
        }
        if (!DynamicIndex)
          continue;

        uint64_t Stride = 1;
        SmallPtrSet<Value *, 16> Seen;
        if (!ExtractDynamicScale(DynamicIndex, Stride, Seen) || Stride < 2 ||
            Stride > 4096)
          continue;

        Type *AccessTy = nullptr;
        bool IsWrite = false;
        SmallVector<Value *, 8> PointerWorklist{GEP};
        SmallPtrSet<Value *, 16> PointerSeen;
        while (!PointerWorklist.empty() && !AccessTy) {
          Value *Pointer = PointerWorklist.pop_back_val();
          if (!PointerSeen.insert(Pointer).second)
            continue;
          for (User *U : Pointer->users()) {
            if (auto *LI = dyn_cast<LoadInst>(U)) {
              if (LI->getPointerOperand() == Pointer)
                AccessTy = LI->getType();
              break;
            }
            if (auto *SI = dyn_cast<StoreInst>(U)) {
              if (SI->getPointerOperand() == Pointer) {
                AccessTy = SI->getValueOperand()->getType();
                IsWrite = true;
              }
              break;
            }
            if (isa<BitCastInst>(U) || isa<AddrSpaceCastInst>(U))
              PointerWorklist.push_back(cast<Value>(U));
          }
        }
        if (!AccessTy || !AccessTy->isFirstClassType() ||
            Ctx.DL.getTypeStoreSize(AccessTy) == 0)
          continue;
        Uses.push_back({*BaseAddress, Stride, AccessTy, IsWrite});
      }
    }
  }

  for (const DynamicUse &Use : Uses) {
    uint64_t Begin = Use.Begin;
    uint64_t Stride = Use.Stride;
    if (Begin < Seg->GuestBase || Begin >= Seg->GuestBase + Seg->Size)
      continue;

    // Determine the record fields from constant accesses in the same stride
    // window.  Missing fields are conservatively represented as i64 because
    // the dynamic access itself is an integer carrier in the lifted ABI.
    // The recovered object is deliberately a byte-record array.  A guest
    // record may have a packed layout (p00578 is 3 x i32 = 12 bytes), so
    // forcing an i64-only StructType changes its stride to 16 and leaves the
    // original 12-byte address arithmetic outside the native object.
    if (Stride == 0 || Stride > 4096)
      continue;

    Type *ByteTy = Type::getInt8Ty(Ctx.M.getContext());
    ArrayType *Record = ArrayType::get(ByteTy, Stride);
    uint64_t End = DynamicRecordArrayEnd(Ctx, Seg, Begin, Stride);
    End = Begin + ((End - Begin) / Stride) * Stride;
    if (End <= Begin)
      continue;

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = Begin;
    Cand->End = End;
    Cand->Kind = ObjectKind::Array;
    Cand->Ty = ArrayType::get(Record, (End - Begin) / Stride);
    Cand->SourceSegment = Seg;
    Cand->Name = "dyn_arr_cand_" + Twine::utohexstr(Begin).str();
    UseEvidence Ev;
    Ev.Kind = EvidenceKind::IndexedStrideAccess;
    Ev.Confidence = 260;
    Ev.Description = "dynamic byte address recovered as typed record array";
    Cand->EvidenceList.push_back(Ev);
    Cand->Confidence = Ev.Confidence;
    if (Use.IsWrite) {
      UseEvidence WEv;
      WEv.Kind = EvidenceKind::WriteObserved;
      WEv.Confidence = 10;
      Cand->EvidenceList.push_back(WEv);
    }
    Ctx.Candidates.push_back(std::move(Cand));
  }

}

// A dynamically-indexed GEP can also be an artifact of the lifted register
// state machine: a flattened state value is carried through an inttoptr/GEP
// shape without ever dereferencing it.  Treating that shape as a data object
// creates a huge synthetic range and later rewrites ordinary state numbers as
// host pointers.  Require an actual memory access before using it as backing
// evidence for a dynamic object.
static bool DynamicGEPFeedsMemoryAccess(GetElementPtrInst *GEP) {
  SmallVector<Value *, 8> Worklist{GEP};
  SmallPtrSet<Value *, 16> Seen;
  while (!Worklist.empty()) {
    Value *Pointer = Worklist.pop_back_val();
    if (!Seen.insert(Pointer).second)
      continue;
    for (User *U : Pointer->users()) {
      if (auto *LI = dyn_cast<LoadInst>(U)) {
        if (LI->getPointerOperand() == Pointer)
          return true;
      }
      if (auto *SI = dyn_cast<StoreInst>(U)) {
        if (SI->getPointerOperand() == Pointer)
          return true;
      }
      if (isa<BitCastInst>(U) || isa<AddrSpaceCastInst>(U))
        Worklist.push_back(cast<Value>(U));
    }
  }
  return false;
}

// A byte lookup indexed through `sext i8` is still allowed to reach every
// non-negative signed-char value.  The scalar observations that happen to
// have named aliases inside that window are table entries, not object
// boundaries.  Preserve this proven lower bound so their rewrites share the
// same backing object as the dynamic lookup.
static std::optional<uint64_t>
SignedByteIndexExtent(Value *V, unsigned Depth = 0) {
  if (!V || Depth > 4)
    return std::nullopt;
  if (auto *SE = dyn_cast<SExtInst>(V)) {
    if (SE->getOperand(0)->getType()->isIntegerTy(8))
      return 128;
    return std::nullopt;
  }
  if (auto *TI = dyn_cast<TruncInst>(V))
    return SignedByteIndexExtent(TI->getOperand(0), Depth + 1);
  if (auto *FI = dyn_cast<FreezeInst>(V))
    return SignedByteIndexExtent(FI->getOperand(0), Depth + 1);
  return std::nullopt;
}

struct DynamicIndexBase {
  uint64_t Stride = 1;
  std::optional<uint64_t> MinimumByteExtent;
};

static std::map<uint64_t, DynamicIndexBase>
CollectDynamicIndexBases(GlobalDataContext &Ctx, GuestSegment *Seg) {
  std::map<uint64_t, DynamicIndexBase> Bases;
  for (Function &F : Ctx.M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *GEP = dyn_cast<GetElementPtrInst>(&I);
        if (!GEP)
          continue;

        Value *DynamicIndex = nullptr;
        for (unsigned Op = 1; Op < GEP->getNumOperands(); ++Op) {
          if (!isa<ConstantInt>(GEP->getOperand(Op))) {
            DynamicIndex = GEP->getOperand(Op);
            break;
          }
        }
        if (!DynamicIndex)
          continue;
        if (!DynamicGEPFeedsMemoryAccess(GEP))
          continue;

        uint64_t Stride = 1;
        SmallPtrSet<Value *, 16> ScaleSeen;
        if (!ExtractDynamicScale(DynamicIndex, Stride, ScaleSeen) ||
            Stride == 0 || Stride > 4096)
          continue;

        SmallPtrSet<Value *, 16> Seen;
        auto Base = SegmentRootGuestAddress(GEP->getPointerOperand(), Seg,
                                            Ctx.DL, Seen);
        if (Base && *Base >= Seg->GuestBase &&
            *Base < Seg->GuestBase + Seg->Size) {
          std::optional<uint64_t> MinimumByteExtent;
          if (Stride == 1)
            MinimumByteExtent = SignedByteIndexExtent(DynamicIndex);
          auto [It, Inserted] = Bases.try_emplace(
              *Base, DynamicIndexBase{Stride, MinimumByteExtent});
          if (!Inserted) {
            It->second.Stride = std::min(It->second.Stride, Stride);
            if (MinimumByteExtent &&
                (!It->second.MinimumByteExtent ||
                 *MinimumByteExtent > *It->second.MinimumByteExtent))
              It->second.MinimumByteExtent = MinimumByteExtent;
          }
        }
      }
    }
  }
  return Bases;
}

static void GenerateScalarCandidates(GlobalDataContext &Ctx, GuestSegment *Seg) {
  std::map<uint64_t, SmallVector<std::pair<Type*, bool>, 4>> AccessMap;
  const std::map<uint64_t, DynamicIndexBase> DynamicIndexBases =
      CollectDynamicIndexBases(Ctx, Seg);

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

    // A scalar observation at a dynamically indexed base only describes one
    // byte of a larger guest object.  Making it a scalar turns every later
    // indexed access into out-of-bounds LLVM IR, which permits O3 to change
    // control flow and results.  Keep the full alias-bounded byte range.
    if (auto DynamicBase = DynamicIndexBases.find(Addr);
        DynamicBase != DynamicIndexBases.end()) {
      uint64_t End = DynamicRecordArrayEnd(Ctx, Seg, Addr,
                                           DynamicBase->second.Stride);
      auto NextSymbol = NamedAliasAddressInSegment(Ctx.M, Seg, Addr + 1);
      if (NextSymbol && *NextSymbol > Addr) {
        End = std::min(End, *NextSymbol);
      }
      if (DynamicBase->second.MinimumByteExtent) {
        uint64_t Available = Seg->GuestBase + Seg->Size - Addr;
        uint64_t RequiredEnd =
            Addr + std::min(*DynamicBase->second.MinimumByteExtent, Available);
        End = std::max(End, RequiredEnd);
        if (NextSymbol && *NextSymbol > Addr && *NextSymbol >= RequiredEnd) {
          End = std::min(End, *NextSymbol);
        }
      }
      if (End <= Addr)
        continue;

      auto Cand = std::make_unique<ObjectCandidate>();
      Cand->Begin = Addr;
      Cand->End = End;
      Cand->Kind = ObjectKind::RawBytes;
      Cand->Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()),
                                End - Addr);
      Cand->SourceSegment = Seg;
      Cand->Name = "dyn_bytes_" + Twine::utohexstr(Addr).str();
      UseEvidence Ev;
      Ev.Kind = EvidenceKind::IndexedStrideAccess;
      // A proven signed-byte domain must dominate scalar aliases inside its
      // 128-byte window.  For an otherwise unconstrained byte index, prefer
      // stronger constant-width array evidence when available; the raw-byte
      // candidate still wins when it is the only safe representation.
      Ev.Confidence = DynamicBase->second.MinimumByteExtent ? 280 : 180;
      Ev.Description =
          "dynamic guest index requires alias-bounded byte backing";
      Cand->EvidenceList.push_back(Ev);
      Cand->Confidence = Ev.Confidence;
      Ctx.Candidates.push_back(std::move(Cand));
      continue;
    }

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

// BSS arrays commonly reach libc through an integer carrier such as
// `ptrtoint(@data_base) + index * stride`.  There is no direct load/store at
// the base in that form, so the scalar and GEP-based array rules above cannot
// establish an object range.  Preserve a writable alias as one byte object
// when it is the base of genuinely dynamic address arithmetic.  The next ELF
// alias is the strongest available boundary; treating the remainder as raw
// bytes preserves layout without guessing a source-level element type.
static std::optional<uint64_t>
SignedByteIndexExtent(Value *V, unsigned Depth);

static std::optional<uint64_t>
AliasSignedByteLookupExtent(Value *V, SmallPtrSetImpl<Value *> &Seen,
                            unsigned Depth = 0) {
  if (!V || Depth > 16 || !Seen.insert(V).second)
    return std::nullopt;

  for (User *U : V->users()) {
    if (auto *GEP = dyn_cast<GEPOperator>(U)) {
      for (unsigned I = 1; I < GEP->getNumOperands(); ++I) {
        Value *Index = GEP->getOperand(I);
        if (isa<ConstantInt>(Index))
          continue;
        if (auto Extent = SignedByteIndexExtent(Index, 0))
          return Extent;
      }
    }
    if (isa<ConstantExpr>(U) || isa<CastInst>(U) ||
        isa<BinaryOperator>(U) || isa<GetElementPtrInst>(U) ||
        isa<PHINode>(U) || isa<SelectInst>(U)) {
      if (auto Extent = AliasSignedByteLookupExtent(cast<Value>(U), Seen,
                                                     Depth + 1))
        return Extent;
    }
  }
  return std::nullopt;
}

static bool AliasFeedsDynamicAddress(Value *V,
                                     SmallPtrSetImpl<Value *> &Seen,
                                     unsigned Depth = 0) {
  if (!V || Depth > 16 || !Seen.insert(V).second)
    return false;

  for (User *U : V->users()) {
    if (auto *BO = dyn_cast<BinaryOperator>(U)) {
      if (BO->getOpcode() == Instruction::Add ||
          BO->getOpcode() == Instruction::Sub) {
        for (Value *Op : BO->operands())
          if (Op != V && !isa<Constant>(Op))
            return true;
      }
    }
    if (auto *GEP = dyn_cast<GEPOperator>(U)) {
      for (unsigned I = 1; I < GEP->getNumOperands(); ++I)
        if (!isa<ConstantInt>(GEP->getOperand(I)))
          return true;
    }

    if (isa<ConstantExpr>(U) || isa<CastInst>(U) ||
        isa<BinaryOperator>(U) || isa<GetElementPtrInst>(U) ||
        isa<PHINode>(U) || isa<SelectInst>(U)) {
      if (AliasFeedsDynamicAddress(cast<Value>(U), Seen, Depth + 1))
        return true;
    }
  }
  return false;
}

// A typed object at a dynamic guest base proves only the bytes inside that
// object.  Treating "base is covered" as "dynamic range is covered" drops the
// rest of large BSS arrays when the original segment is removed.  Advance
// through only the candidate intervals that form one contiguous prefix; the
// caller materializes the remaining tail as byte-preserving storage.
static uint64_t ContiguousCandidateCoverageEnd(GlobalDataContext &Ctx,
                                               uint64_t Begin,
                                               uint64_t Limit) {
  uint64_t CoveredEnd = Begin;
  bool Progress = true;
  while (Progress && CoveredEnd < Limit) {
    Progress = false;
    for (const auto &Existing : Ctx.Candidates) {
      if (Existing->Begin <= CoveredEnd && Existing->End > CoveredEnd) {
        uint64_t Next = std::min(Existing->End, Limit);
        if (Next > CoveredEnd) {
          CoveredEnd = Next;
          Progress = true;
        }
      }
    }
  }
  return CoveredEnd;
}

static void GenerateDynamicAliasBufferCandidates(GlobalDataContext &Ctx,
                                                 GuestSegment *Seg) {
  if (!Seg->Writable || Seg->Executable || Seg->Kind == SegmentKind::Unknown)
    return;

  const uint64_t SegEnd = Seg->GuestBase + Seg->Size;
  const std::map<uint64_t, DynamicIndexBase> DynamicIndexBases =
      CollectDynamicIndexBases(Ctx, Seg);
  std::set<uint64_t> SeenBases;
  for (GlobalAlias &GA : Ctx.M.aliases()) {
    auto Begin = NamedGuestAddress(&GA);
    if (!Begin || *Begin < Seg->GuestBase || *Begin >= SegEnd ||
        !SeenBases.insert(*Begin).second)
      continue;

    SmallPtrSet<Value *, 32> SeenUsers;
    if (!AliasFeedsDynamicAddress(&GA, SeenUsers))
      continue;

    auto NextBoundary = NamedAliasAddressInSegment(Ctx.M, Seg, *Begin);
    uint64_t End = NextBoundary && *NextBoundary > *Begin ? *NextBoundary
                                                           : SegEnd;
    bool NeedsOpenEndedByteBacking = false;
    if (auto It = DynamicIndexBases.find(*Begin);
        It != DynamicIndexBases.end() && It->second.Stride == 1 &&
        !It->second.MinimumByteExtent) {
      // With no proven index bound, an interior data_<addr> alias is not an
      // object boundary.  The original machine can legally address the
      // following bytes in the same writable mapping even when source-level
      // reconstruction would call that an out-of-bounds access.
      End = SegEnd;
      NeedsOpenEndedByteBacking = true;
    }
    SmallPtrSet<Value *, 32> LookupSeen;
    if (auto Extent = AliasSignedByteLookupExtent(&GA, LookupSeen)) {
      uint64_t Available = SegEnd - *Begin;
      End = std::max(End, *Begin + std::min(*Extent, Available));
    }
    if (End <= *Begin)
      continue;

    uint64_t ResidualBegin =
        NeedsOpenEndedByteBacking
            ? *Begin
            : ContiguousCandidateCoverageEnd(Ctx, *Begin, End);
    if (ResidualBegin >= End)
      continue;

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = ResidualBegin;
    Cand->End = End;
    Cand->Kind = ObjectKind::RawBytes;
    Cand->Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()),
                              End - ResidualBegin);
    Cand->SourceSegment = Seg;
    Cand->Name =
        "dyn_bytes_" + Twine::utohexstr(ResidualBegin).str();
    UseEvidence Ev;
    Ev.Kind = EvidenceKind::IndexedStrideAccess;
    Ev.Confidence = NeedsOpenEndedByteBacking ? 300 : 240;
    Ev.Description = NeedsOpenEndedByteBacking
                         ? "unbounded dynamic byte index requires writable "
                           "guest-image backing"
                         : "writable ELF alias used as base of dynamic guest "
                           "pointer arithmetic";
    Cand->EvidenceList.push_back(Ev);
    Cand->Confidence = Ev.Confidence;
    Ctx.Candidates.push_back(std::move(Cand));
  }

}

// Earlier simplification can fold a named alias into a plain integer before
// global-data recovery runs.  Preserve the same BSS-buffer rule for the
// resulting `guest_base + dynamic_offset` form.  The segment-membership check
// keeps ordinary arithmetic constants out of this recovery path.
static void GenerateFoldedDynamicBufferCandidates(GlobalDataContext &Ctx,
                                                  GuestSegment *Seg) {
  if (!Seg->Writable || Seg->Executable || Seg->Kind == SegmentKind::Unknown)
    return;

  const uint64_t SegEnd = Seg->GuestBase + Seg->Size;
  std::set<uint64_t> Bases;
  for (Function &F : Ctx.M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO || (BO->getOpcode() != Instruction::Add &&
                    BO->getOpcode() != Instruction::Sub))
          continue;
        for (unsigned OpIndex = 0; OpIndex < 2; ++OpIndex) {
          auto *Base = dyn_cast<ConstantInt>(BO->getOperand(OpIndex));
          Value *Offset = BO->getOperand(1 - OpIndex);
          if (!Base || isa<Constant>(Offset) || !Offset->getType()->isIntegerTy())
            continue;
          uint64_t Address = Base->getZExtValue();
          if (Address >= Seg->GuestBase && Address < SegEnd)
            Bases.insert(Address);
        }
      }
    }
  }

  for (uint64_t Begin : Bases) {
    auto NextBoundary = NamedAliasAddressInSegment(Ctx.M, Seg, Begin);
    uint64_t End = NextBoundary && *NextBoundary > Begin ? *NextBoundary
                                                          : SegEnd;
    uint64_t ResidualBegin =
        ContiguousCandidateCoverageEnd(Ctx, Begin, End);
    if (ResidualBegin >= End)
      continue;

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = ResidualBegin;
    Cand->End = End;
    Cand->Kind = ObjectKind::RawBytes;
    Cand->Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()),
                              End - ResidualBegin);
    Cand->SourceSegment = Seg;
    Cand->Name =
        "dyn_bytes_" + Twine::utohexstr(ResidualBegin).str();
    UseEvidence Ev;
    Ev.Kind = EvidenceKind::IndexedStrideAccess;
    Ev.Confidence = 240;
    Ev.Description =
        "folded writable guest base used in dynamic pointer arithmetic";
    Cand->EvidenceList.push_back(Ev);
    Cand->Confidence = Ev.Confidence;
    Ctx.Candidates.push_back(std::move(Cand));
  }
}

// A mutable scalar can hold the initial address of a guest buffer.  Unlike a
// direct address alias, the alias itself is only the address of the scalar;
// the pointer provenance appears after loading its contents.  Recover backing
// storage only when that loaded pointer is actually converted to a guest
// pointer, never merely because an integer happens to look like an address.
static bool ValueFeedsGuestPointer(Value *V, SmallPtrSetImpl<Value *> &Seen,
                                   unsigned Depth = 0) {
  if (!V || Depth > 16 || !Seen.insert(V).second)
    return false;

  for (User *U : V->users()) {
    if (isa<IntToPtrInst>(U))
      return true;
    if (auto *CB = dyn_cast<CallBase>(U)) {
      if (Function *Callee = CB->getCalledFunction())
        if (Callee->getName() == "__translate_guest_pointer")
          return true;
    }
    if (isa<CastInst>(U) || isa<BinaryOperator>(U) ||
        isa<GetElementPtrInst>(U) || isa<PHINode>(U) || isa<SelectInst>(U)) {
      if (ValueFeedsGuestPointer(cast<Value>(U), Seen, Depth + 1))
        return true;
    }
  }
  return false;
}

static std::optional<uint64_t> GuestAddressToFlatOffset(
    GlobalDataContext &Ctx, GuestSegment *Seg, uint64_t GuestAddr) {
  if (!Seg || !Seg->GV)
    return std::nullopt;
  for (GlobalAlias &GA : Ctx.M.aliases()) {
    StringRef Name = GA.getName();
    if (!Name.starts_with("data_"))
      continue;
    uint64_t Addr = 0;
    if (Name.drop_front(5).getAsInteger(16, Addr) || Addr != GuestAddr)
      continue;
    auto *GEP = dyn_cast<GEPOperator>(GA.getAliasee());
    if (!GEP || GEP->getPointerOperand()->stripPointerCasts() != Seg->GV)
      continue;
    APInt Offset(Ctx.DL.getIndexTypeSizeInBits(GEP->getType()), 0);
    if (GEP->accumulateConstantOffset(Ctx.DL, Offset) &&
        Offset.getActiveBits() <= 64)
      return Offset.getZExtValue();
  }
  return GuestAddr - Seg->GuestBase;
}

static void GenerateLoadedPointerCarrierCandidates(GlobalDataContext &Ctx,
                                                   GuestSegment *Seg) {
  if (!Seg || !Seg->Writable || Seg->Executable ||
      Seg->Kind == SegmentKind::Unknown)
    return;

  const uint64_t PtrSize = Ctx.DL.getPointerSize();
  if (PtrSize == 0)
    return;
  const uint64_t SegEnd = Seg->GuestBase + Seg->Size;
  std::set<uint64_t> SeenTargets;

  for (GlobalAlias &GA : Ctx.M.aliases()) {
    auto SourceAddr = NamedGuestAddress(&GA);
    if (!SourceAddr || *SourceAddr < Seg->GuestBase ||
        *SourceAddr + PtrSize > SegEnd)
      continue;

    bool IsPointerCarrier = false;
    for (Function &F : Ctx.M) {
      if (F.isDeclaration() || IsPointerCarrier)
        continue;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          auto *LI = dyn_cast<LoadInst>(&I);
          if (!LI || LI->getPointerOperand()->stripPointerCasts() != &GA ||
              !LI->getType()->isIntegerTy(PtrSize * 8))
            continue;
          SmallPtrSet<Value *, 32> SeenUsers;
          if (ValueFeedsGuestPointer(LI, SeenUsers)) {
            IsPointerCarrier = true;
            break;
          }
        }
        if (IsPointerCarrier)
          break;
      }
    }
    if (!IsPointerCarrier)
      continue;

    SmallVector<uint8_t, 8> Bytes;
    if (!Ctx.readSegmentBytes(Seg, *SourceAddr, PtrSize, Bytes) ||
        Bytes.size() != PtrSize)
      continue;
    uint64_t Target = 0;
    for (unsigned I = 0; I < PtrSize; ++I)
      Target |= uint64_t(Bytes[I]) << (I * 8);

    GuestSegment *TargetSeg = Ctx.findSegmentForAddr(Target);
    if (!TargetSeg || !TargetSeg->Writable || TargetSeg->Executable ||
        !SeenTargets.insert(Target).second)
      continue;

    auto NextBoundary = NamedAliasAddressInSegment(Ctx.M, TargetSeg, Target);
    uint64_t End = NextBoundary && *NextBoundary > Target
                       ? *NextBoundary
                       : TargetSeg->GuestBase + TargetSeg->Size;
    bool AlreadyCovered = false;
    for (const auto &Existing : Ctx.Candidates) {
      if (Target >= Existing->Begin && Target < Existing->End) {
        AlreadyCovered = true;
        break;
      }
      if (Existing->Begin > Target && Existing->Begin < End)
        End = Existing->Begin;
    }
    if (AlreadyCovered || End <= Target)
      continue;

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = Target;
    Cand->End = End;
    Cand->Kind = ObjectKind::RawBytes;
    Cand->Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), End - Target);
    Cand->SourceSegment = TargetSeg;
    Cand->Name = "ptr_carrier_bytes_" + Twine::utohexstr(Target).str();
    UseEvidence Ev;
    Ev.Kind = EvidenceKind::LoadStoreWidth;
    Ev.Confidence = 280;
    Ev.Description =
        "writable guest pointer loaded from scalar and consumed as address";
    Cand->EvidenceList.push_back(Ev);
    Cand->Confidence = Ev.Confidence;
    Ctx.Candidates.push_back(std::move(Cand));
  }
}

static void GenerateLoadedPointerCarrierReferenceCandidates(
    GlobalDataContext &Ctx, GuestSegment *Seg) {
  if (!Seg || !Seg->Writable || Seg->Executable ||
      Seg->Kind == SegmentKind::Unknown)
    return;
  const uint64_t PtrSize = Ctx.DL.getPointerSize();
  if (PtrSize == 0)
    return;

  std::set<uint64_t> SeenTargets;
  for (const auto &Ref : Ctx.AddressRefs) {
    if (Ref->Segment != Seg)
      continue;
    auto *LI = dyn_cast_or_null<LoadInst>(Ref->UserInst);
    if (!LI || !LI->getType()->isIntegerTy(PtrSize * 8))
      continue;
    SmallPtrSet<Value *, 32> SeenUsers;
    bool FeedsGuestPointer = ValueFeedsGuestPointer(LI, SeenUsers);
    if (!FeedsGuestPointer)
      continue;

    auto SourceOffset = GuestAddressToFlatOffset(Ctx, Seg, Ref->GuestAddr);
    if (!SourceOffset || *SourceOffset + PtrSize > Seg->FlatBytes.size())
      continue;
    uint64_t Target = 0;
    for (unsigned I = 0; I < PtrSize; ++I)
      Target |= uint64_t(Seg->FlatBytes[*SourceOffset + I]) << (I * 8);

    GuestSegment *TargetSeg = Ctx.findSegmentForAddr(Target);
    if (!TargetSeg || !TargetSeg->Writable || TargetSeg->Executable ||
        !SeenTargets.insert(Target).second)
      continue;

    auto NextBoundary = NamedAliasAddressInSegment(Ctx.M, TargetSeg, Target);
    uint64_t End = NextBoundary && *NextBoundary > Target
                       ? *NextBoundary
                       : TargetSeg->GuestBase + TargetSeg->Size;
    bool AlreadyCovered = false;
    for (const auto &Existing : Ctx.Candidates) {
      if (Target >= Existing->Begin && Target < Existing->End) {
        AlreadyCovered = true;
        break;
      }
      if (Existing->Begin > Target && Existing->Begin < End)
        End = Existing->Begin;
    }
    if (AlreadyCovered || End <= Target)
      continue;

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = Target;
    Cand->End = End;
    Cand->Kind = ObjectKind::RawBytes;
    Cand->Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), End - Target);
    Cand->SourceSegment = TargetSeg;
    Cand->Name = "ptr_carrier_bytes_" + Twine::utohexstr(Target).str();
    UseEvidence Ev;
    Ev.Kind = EvidenceKind::LoadStoreWidth;
    Ev.Confidence = 280;
    Ev.Description =
        "writable guest pointer loaded from scalar and consumed as address";
    Cand->EvidenceList.push_back(Ev);
    Cand->Confidence = Ev.Confidence;
    Ctx.Candidates.push_back(std::move(Cand));
  }
}

// A lifted image can materialize a data pointer as an integer value in the
// register state, or use it as the constant base of later address arithmetic,
// without ever using that value directly as the pointer operand of a
// load/store.  The later libc call or dynamic inttoptr consumes the carrier,
// so the normal scalar/array access analysis has no memory width from which to
// create an object.  In native mode the carrier still needs a real backing
// object: otherwise strict verification quite correctly rejects the surviving
// guest address constant.
static void GenerateAddressCarrierCandidates(GlobalDataContext &Ctx,
                                              GuestSegment *Seg) {
  if (!Seg || Seg->Kind == SegmentKind::Unknown || Seg->Executable ||
      Seg->Kind == SegmentKind::Plt)
    return;
  const uint64_t PtrSize = Ctx.DL.getPointerSize();
  if (PtrSize == 0)
    return;

  std::set<uint64_t> Seen;
  for (auto &Ref : Ctx.AddressRefs) {
    if (Ref->Segment != Seg ||
        (Ref->ConsumerKind != DataConsumerKind::IntegerAddressConsumer &&
         Ref->ConsumerKind != DataConsumerKind::ArithmeticOnly &&
         Ref->ConsumerKind != DataConsumerKind::LibcStringArg &&
         Ref->ConsumerKind != DataConsumerKind::LibcWriteBufferArg))
      continue;
    if (!Ref->OriginalValue ||
        (!Ref->OriginalValue->getType()->isIntegerTy() &&
         !Ref->OriginalValue->getType()->isPointerTy()))
      continue;
    if (!Seen.insert(Ref->GuestAddr).second)
      continue;
    if (Ref->GuestAddr < Seg->GuestBase ||
        Ref->GuestAddr >= Seg->GuestBase + Seg->Size)
      continue;

    uint64_t Available = Seg->GuestBase + Seg->Size - Ref->GuestAddr;
    // Prefer the next named ELF boundary for a carried data pointer.  A
    // pointer-sized placeholder is unsafe for a BSS buffer later consumed by
    // memcpy/strcmp, because the native call can legitimately access the
    // whole object rather than just the address carrier itself.
    auto NextBoundary =
        NamedAliasAddressInSegment(Ctx.M, Seg, Ref->GuestAddr);
    uint64_t Width = NextBoundary && *NextBoundary > Ref->GuestAddr
                         ? *NextBoundary - Ref->GuestAddr
                         : PtrSize;
    Width = std::min<uint64_t>(Width, Available);
    if (Width == 0)
      continue;

    // A byte-sized load at the start of a mutable C buffer commonly creates a
    // scalar candidate first.  Do not let that weak local observation suppress
    // the stronger libc evidence: materializing the base as i8 makes later
    // strlen/scanf/indexed accesses undefined and O3 is then free to fold
    // program state incorrectly.
    const bool MutableLibcBuffer =
        Seg->Writable && !Seg->ReadOnly &&
        (Ref->ConsumerKind == DataConsumerKind::LibcStringArg ||
         Ref->ConsumerKind == DataConsumerKind::LibcWriteBufferArg);
    if (!MutableLibcBuffer) {
      bool AlreadyCovered = false;
      for (const auto &Existing : Ctx.Candidates) {
        if (Ref->GuestAddr >= Existing->Begin &&
            Ref->GuestAddr < Existing->End) {
          AlreadyCovered = true;
          break;
        }
      }
      if (AlreadyCovered)
        continue;
    }

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->Begin = Ref->GuestAddr;
    Cand->End = Ref->GuestAddr + Width;
    Cand->Kind = ObjectKind::RawBytes;
    Cand->Ty = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), Width);
    Cand->SourceSegment = Seg;
    Cand->Name = "g_bytes_" + Twine::utohexstr(Ref->GuestAddr).str();
    UseEvidence Ev;
    Ev.Kind = MutableLibcBuffer ? EvidenceKind::LibcStringArg
                                : EvidenceKind::LoadStoreWidth;
    Ev.Confidence = MutableLibcBuffer ? 260 : 30;
    Ev.Description =
        MutableLibcBuffer
            ? "mutable guest libc buffer with alias-bounded byte extent"
            : Ref->ConsumerKind == DataConsumerKind::ArithmeticOnly
            ? "guest data address used as arithmetic base"
            : Ref->ConsumerKind == DataConsumerKind::LibcStringArg
                  ? "zero-backed guest string buffer consumed by libc"
                  : "guest data address carried through integer state";
    Cand->EvidenceList.push_back(Ev);
    Cand->Confidence = Ev.Confidence;
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

  // A table can be consumed through a dynamic GEP, so the address map may
  // not contain a direct load reference at the table base.  Named ELF data
  // aliases are still sufficient discovery evidence for a relocation-backed
  // table and keep it from being mis-materialized as byte records.
  for (GlobalAlias &GA : Ctx.M.aliases()) {
    auto Addr = NamedGuestAddress(&GA);
    if (!Addr || *Addr < Seg->GuestBase ||
        *Addr >= Seg->GuestBase + Seg->Size || *Addr % PtrSize != 0)
      continue;
    CandidateAddrs.insert(*Addr);
  }

  for (uint64_t Addr : CandidateAddrs) {
    SmallVector<uint64_t, 32> Entries;
    uint64_t Curr = Addr;
    unsigned MaxEntries = 512;
    bool HasRelocs = false;
    bool AllFunctionTargets = true;

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
      else
        AllFunctionTargets = false;
      if (Ctx.findSegmentForAddr(Val))
        Valid = true;
      if (Seg->Relocations.count(Offset))
        Valid = true;

      if (!Valid)
        break;

      Entries.push_back(Val);
      Curr += PtrSize;
    }

    // Relocations are the normal proof for a pointer table.  Stripped images
    // can retain only raw addresses; accept that form when every non-zero
    // entry resolves exactly to a recovered function.
    if (Entries.size() < 2 || (!HasRelocs && !AllFunctionTargets))
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
    // Relocation-backed pointer tables are stronger evidence than a generic
    // i64/byte array access.  Let this candidate win conflicts so the
    // materializer can emit native pointers instead of ptrtoint(pointer) into
    // narrow byte elements (which is rejected by clang and loses semantics).
    Ev.Confidence = 320;
    Cand->EvidenceList.push_back(Ev);
    Cand->Confidence = Ev.Confidence;

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
    GenerateDynamicRecordCandidates(Ctx, Seg.get());
    GenerateArrayCandidates(Ctx, Seg.get());
    GenerateScalarCandidates(Ctx, Seg.get());
    GenerateDynamicAliasBufferCandidates(Ctx, Seg.get());
    GenerateFoldedDynamicBufferCandidates(Ctx, Seg.get());
    GenerateAddressCarrierCandidates(Ctx, Seg.get());
    GeneratePointerTableCandidates(Ctx, Seg.get());
  }

  for (auto &Seg : Ctx.Segments) {
    if (Seg->BaseResolved) {
      GenerateLoadedPointerCarrierCandidates(Ctx, Seg.get());
      GenerateLoadedPointerCarrierReferenceCandidates(Ctx, Seg.get());
    }
  }

  if (Ctx.Debug && !Ctx.Candidates.empty())
    errs() << "[brighten-global-data] generated " << Ctx.Candidates.size()
           << " object candidates\n";

  return !Ctx.Candidates.empty();
}

} // namespace brighten_global
