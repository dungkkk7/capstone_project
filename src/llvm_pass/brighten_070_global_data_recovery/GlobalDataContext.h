#ifndef BRIGHTEN_070_GLOBAL_DATA_CONTEXT_H
#define BRIGHTEN_070_GLOBAL_DATA_CONTEXT_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>
#include <algorithm>
#include <cstring>

namespace brighten_global {

using namespace llvm;

enum class DataRecoveryMode {
  NativeStrict,
  CompatFallback,
};

enum class SegmentKind {
  Rodata,
  Data,
  Bss,
  Got,
  Plt,
  Unknown,
};

enum class ObjectKind {
  StringLiteral,
  WideStringLiteral,
  Scalar,
  Array,
  PointerTable,
  JumpTable,
  RawBytes,
};

enum class DataConsumerKind {
  NativePointerConsumer,
  IntegerAddressConsumer,
  LibcStringArg,
  LibcWriteBufferArg,
  LoadStorePointer,
  ComparisonOnly,
  ArithmeticOnly,
  Unknown,
};

enum class EvidenceKind {
  LibcStringArg,
  FormatStringArg,
  LoadStoreWidth,
  IndexedStrideAccess,
  RelocationEntry,
  PointerTableUse,
  JumpTableUse,
  SymbolBoundary,
  SectionBoundary,
  NoConflictingOverlap,
  ReadonlySection,
  WriteObserved,
  AddressIdentityObserved,
};

struct UseEvidence {
  EvidenceKind Kind;
  Instruction *Inst = nullptr;
  unsigned Confidence = 0;
  std::string Description;
};

struct GuestSegment {
  GlobalVariable *GV = nullptr;
  uint64_t GuestBase = 0;
  uint64_t Size = 0;
  SegmentKind Kind = SegmentKind::Unknown;
  bool ReadOnly = false;
  bool Writable = false;
  bool Executable = false;
  // A page-tail is already the authoritative byte owner for its guest
  // interval.  It is never a source for an additional recovered writable
  // object unless a future pass can remove/rewrite every tail use as one
  // transaction.
  bool IsMappedPageTail = false;
  bool BaseResolved = false;
  std::string SkipReason;
  std::vector<uint8_t> FlatBytes;
  std::map<uint64_t, Constant *> Relocations;
};

struct GuestAddressRef {
  uint64_t GuestAddr = 0;
  GuestSegment *Segment = nullptr;
  uint64_t OffsetInSegment = 0;
  Value *OriginalValue = nullptr;
  Instruction *UserInst = nullptr;
  DataConsumerKind ConsumerKind = DataConsumerKind::Unknown;
  bool Rewritten = false;
  std::string SkipReason;
  std::vector<UseEvidence> EvidenceList;
};

// This is the only map used to assign a guest address to backing storage when
// ELF PT_LOAD evidence is available.  It deliberately describes backing
// regions, not recovered typed views: a recovered scalar/string can rewrite a
// proven direct use, but it must not become a second owner of a dynamic guest
// address.
struct GuestAddressRegion {
  uint64_t Begin = 0;
  uint64_t End = 0;
  GuestSegment *Segment = nullptr;
};

struct ObjectCandidate {
  uint64_t Begin = 0;
  uint64_t End = 0;
  ObjectKind Kind = ObjectKind::RawBytes;
  Type *Ty = nullptr;
  unsigned Confidence = 0;
  SmallVector<UseEvidence, 8> EvidenceList;
  SmallVector<std::string, 4> Risks;
  GuestSegment *SourceSegment = nullptr;
  std::string Name;
  // This candidate was proven from complete direct fixed-width accesses.  Its
  // materialization and rewrite are all-or-nothing: a residual interval may
  // not acquire a second storage location while an unresolved carrier remains.
  bool RequiresTransactionalDirectRewrite = false;
  bool Conflict = false;
  std::string DropReason;
};

struct RecoveredObject {
  uint64_t Begin = 0;
  uint64_t End = 0;
  ObjectKind Kind = ObjectKind::RawBytes;
  Type *Ty = nullptr;
  GlobalVariable *GV = nullptr;
  GuestSegment *SourceSegment = nullptr;
  bool ReadOnly = false;
  bool HasWrites = false;
  std::string Name;
  std::string Action;
  std::string SkipReason;
  bool RequiresTransactionalDirectRewrite = false;
  unsigned UseCount = 0;
};

struct JumpTableEntry {
  uint64_t GuestTarget = 0;
  Function *TargetFn = nullptr;
  BasicBlock *TargetBB = nullptr;
  bool Resolved = false;
};

struct JumpTableInfo {
  uint64_t TableBase = 0;
  uint64_t EntryCount = 0;
  unsigned EntrySize = 0;
  GuestSegment *Segment = nullptr;
  GlobalVariable *TableGV = nullptr;
  SmallVector<JumpTableEntry, 16> Entries;
  Instruction *BranchInst = nullptr;
  Value *IndexValue = nullptr;
  bool Recovered = false;
  std::string Action;
  std::string SkipReason;
};

struct GlobalDataReport {
  unsigned SegmentsDiscovered = 0;
  unsigned GuestAddressRefsDiscovered = 0;
  unsigned StringsRecovered = 0;
  unsigned GlobalScalarsRecovered = 0;
  unsigned GlobalArraysRecovered = 0;
  unsigned PointerTablesRecovered = 0;
  unsigned JumpTablesRecovered = 0;
  unsigned DataRefsRewritten = 0;
  unsigned SegmentsRemoved = 0;
  unsigned PreservedRefs = 0;
  unsigned VerifierErrors = 0;
  std::vector<std::string> Details;
};

struct GlobalDataContext {
  Module &M;
  const DataLayout &DL;
  DataRecoveryMode Mode = DataRecoveryMode::NativeStrict;
  bool Debug = true;

  SmallVector<std::unique_ptr<GuestSegment>, 16> Segments;
  std::map<uint64_t, GuestSegment *> SegmentByBase;
  SmallVector<GuestAddressRegion, 16> AuthoritativeGuestAddressMap;
  bool HasAuthoritativeGuestAddressMap = false;

  SmallVector<std::unique_ptr<GuestAddressRef>, 256> AddressRefs;

  std::vector<std::unique_ptr<ObjectCandidate>> Candidates;

  std::map<uint64_t, std::unique_ptr<RecoveredObject>> RecoveredObjects;

  SmallVector<std::unique_ptr<JumpTableInfo>, 16> JumpTables;

  GlobalDataReport Report;

  unsigned NextStringId = 0;
  unsigned NextWideStringId = 0;
  unsigned NextScalarId = 0;
  unsigned NextArrayId = 0;
  unsigned NextPtrTableId = 0;
  unsigned NextJumpTableId = 0;

  explicit GlobalDataContext(Module &Mod)
      : M(Mod), DL(Mod.getDataLayout()) {}

  // PT_LOAD-backed regions must form a partition.  A failed construction is
  // fail-closed: callers retain the old lifting representation rather than
  // selecting an arbitrary overlapping global.
  bool buildAuthoritativeGuestAddressMap() {
    SmallVector<GuestAddressRegion, 16> Regions;
    for (const auto &Seg : Segments) {
      if (!Seg || !Seg->BaseResolved || !Seg->Size ||
          Seg->GuestBase > UINT64_MAX - Seg->Size)
        return false;
      Regions.push_back({Seg->GuestBase, Seg->GuestBase + Seg->Size,
                         Seg.get()});
    }
    std::sort(Regions.begin(), Regions.end(), [](const GuestAddressRegion &L,
                                                 const GuestAddressRegion &R) {
      return L.Begin < R.Begin;
    });
    for (size_t I = 1; I < Regions.size(); ++I)
      if (Regions[I - 1].End > Regions[I].Begin)
        return false;
    AuthoritativeGuestAddressMap = std::move(Regions);
    HasAuthoritativeGuestAddressMap = true;
    return true;
  }

  GuestSegment *findSegmentForAddr(uint64_t Addr) const {
    if (HasAuthoritativeGuestAddressMap) {
      for (const GuestAddressRegion &Region : AuthoritativeGuestAddressMap)
        if (Addr >= Region.Begin && Addr < Region.End)
          return Region.Segment;
      return nullptr;
    }
    for (auto &Seg : Segments) {
      if (!Seg->BaseResolved)
        continue;
      if (Addr >= Seg->GuestBase && Addr < Seg->GuestBase + Seg->Size)
        return Seg.get();
    }
    return nullptr;
  }

  const RecoveredObject *findObjectAt(uint64_t Addr) const {
    auto It = RecoveredObjects.upper_bound(Addr);
    if (It != RecoveredObjects.begin()) {
      --It;
      if (Addr >= It->second->Begin && Addr < It->second->End)
        return It->second.get();
    }
    return nullptr;
  }

  bool hasOverlap(uint64_t Begin, uint64_t End) const {
    auto It = RecoveredObjects.lower_bound(Begin);
    if (It != RecoveredObjects.begin()) {
      auto Prev = std::prev(It);
      if (Prev->second->End > Begin)
        return true;
    }
    if (It != RecoveredObjects.end() && It->second->Begin < End)
      return true;
    return false;
  }

  bool readSegmentBytes(GuestSegment *Seg, uint64_t GuestAddr,
                        uint64_t Length, SmallVectorImpl<uint8_t> &Out) const {
    if (!Seg || !Seg->BaseResolved)
      return false;
    uint64_t Off = GuestAddr - Seg->GuestBase;
    if (Off + Length > Seg->FlatBytes.size())
      return false;
    Out.assign(Seg->FlatBytes.begin() + Off, Seg->FlatBytes.begin() + Off + Length);
    return true;
  }
};

} // namespace brighten_global

#endif
