#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"

#include <cctype>
#include <cstring>

namespace brighten_global {

using namespace llvm;

static std::optional<uint64_t> ParseHexPrefix(StringRef Text) {
  if (Text.empty())
    return std::nullopt;
  size_t End = 0;
  while (End < Text.size() &&
         std::isxdigit(static_cast<unsigned char>(Text[End])))
    ++End;
  if (End == 0)
    return std::nullopt;
  uint64_t Val = 0;
  if (Text.substr(0, End).getAsInteger(16, Val))
    return std::nullopt;
  return Val;
}

static bool IsExecutableSegmentName(StringRef Name) {
  if (Name.contains("__init_array") ||
      Name.contains("__fini_array") ||
      Name.contains("__preinit_array")) {
    return false;
  }

  return Name.contains("__text") ||
         Name.contains("__init_") || Name.ends_with("__init") ||
         Name.contains("__fini_") || Name.ends_with("__fini") ||
         Name.contains("__plt") ||
         Name.contains("__code") ||
         Name.contains("_LOAD_");
}

static SegmentKind ClassifySegmentName(StringRef Name) {
  if (Name.contains("__init_array") ||
      Name.contains("__fini_array") ||
      Name.contains("__preinit_array")) {
    return SegmentKind::Data;
  }
  if (Name.contains("rodata") || Name.contains("RODATA"))
    return SegmentKind::Rodata;
  if (Name.contains("__bss") || Name.ends_with("_bss"))
    return SegmentKind::Bss;
  if (Name.contains("__got") || Name.ends_with("_got"))
    return SegmentKind::Got;
  if (Name.contains("__plt") || Name.ends_with("_plt"))
    return SegmentKind::Plt;
  if (Name.contains("__data") || Name.ends_with("_data"))
    return SegmentKind::Data;
  return SegmentKind::Unknown;
}

static std::optional<uint64_t> ParseSegmentBase(StringRef Name) {
  // Pattern: seg_HEXADDR__suffix  or  data_HEXADDR
  for (const char *Prefix : {"seg_", "data_"}) {
    if (!Name.starts_with(Prefix))
      continue;
    StringRef Rest = Name.drop_front(strlen(Prefix));
    // For seg_: take hex digits before next '_'
    size_t Sep = Rest.find('_');
    StringRef HexPart = (Sep != StringRef::npos) ? Rest.substr(0, Sep) : Rest;
    return ParseHexPrefix(HexPart);
  }
  return std::nullopt;
}

static uint64_t ComputeSegmentSize(GlobalVariable *GV) {
  if (!GV->hasInitializer())
    return 0;
  Type *Ty = GV->getValueType();
  const DataLayout &DL = GV->getParent()->getDataLayout();
  return DL.getTypeAllocSize(Ty);
}

bool BrightenGlobalDataRecoveryPass::DiscoverGuestSegments(
    GlobalDataContext &Ctx) {
  Module &M = Ctx.M;
  unsigned Count = 0;

  for (GlobalVariable &GV : M.globals()) {
    StringRef Name = GV.getName();
    bool IsSegment = Name.starts_with("seg_");
    bool IsData = Name.starts_with("data_");

    if (!IsSegment && !IsData)
      continue;

    // Filter out executable/code segments
    if (IsExecutableSegmentName(Name)) {
      continue;
    }

    auto Seg = std::make_unique<GuestSegment>();
    Seg->GV = &GV;

    auto Base = ParseSegmentBase(Name);
    if (Base) {
      Seg->GuestBase = *Base;
      Seg->BaseResolved = true;
    } else {
      Seg->BaseResolved = false;
      Seg->SkipReason = "unknown-segment-base";
    }

    Seg->Size = ComputeSegmentSize(&GV);
    // McSema may place a named data alias exactly at the aggregate's
    // computed end (typically a BSS/global boundary).  Keep one pointer-sized
    // zero-backed slot so address-map lookup and materialization can represent
    // that legitimate object instead of reporting a false unresolved ref.
    for (GlobalAlias &GA : M.aliases()) {
      StringRef AliasName = GA.getName();
      if (!AliasName.starts_with("data_"))
        continue;
      uint64_t AliasAddr = 0;
      if (AliasName.drop_front(5).getAsInteger(16, AliasAddr) ||
          AliasAddr != Seg->GuestBase + Seg->Size)
        continue;
      auto *GEP = dyn_cast<GEPOperator>(GA.getAliasee());
      if (!GEP || GEP->getPointerOperand()->stripPointerCasts() != &GV)
        continue;
      Seg->Size += M.getDataLayout().getPointerSize();
      break;
    }
    Seg->Kind = ClassifySegmentName(Name);

    switch (Seg->Kind) {
    case SegmentKind::Rodata:
      Seg->ReadOnly = true;
      Seg->Writable = false;
      Seg->Executable = false;
      break;
    case SegmentKind::Data:
      Seg->ReadOnly = false;
      Seg->Writable = true;
      Seg->Executable = false;
      break;
    case SegmentKind::Bss:
      Seg->ReadOnly = false;
      Seg->Writable = true;
      Seg->Executable = false;
      break;
    case SegmentKind::Got:
    case SegmentKind::Plt:
      Seg->ReadOnly = false;
      Seg->Writable = false;
      Seg->Executable = (Seg->Kind == SegmentKind::Plt);
      break;
    case SegmentKind::Unknown:
      Seg->ReadOnly = GV.isConstant();
      Seg->Writable = !GV.isConstant();
      Seg->Executable = false;
      break;
    }

    if (Seg->BaseResolved)
      Ctx.SegmentByBase[Seg->GuestBase] = Seg.get();

    ++Count;
    Ctx.Segments.push_back(std::move(Seg));
  }

  // The loader maps PT_LOAD ranges at page granularity.  Do not infer this
  // from a segment name or alignment: the Python driver serializes the ELF
  // program headers as !brighten.elf.pt_loads, and CLI/no-ELF inputs simply
  // have no such metadata.  A separate byte region preserves the logical
  // object boundary while making the proven zero page tail available to the
  // same guest-address map as the source load segment.
  bool HasValidatedPTLoadPartition = false;
  if (NamedMDNode *Loads = M.getNamedMetadata("brighten.elf.pt_loads")) {
    SmallVector<std::tuple<uint64_t, uint64_t, uint64_t, uint64_t>, 8> Tails;
    bool Malformed = false;
    for (MDNode *N : Loads->operands()) {
      if (!N || N->getNumOperands() != 7) { Malformed = true; break; }
      uint64_t V[7] = {};
      for (unsigned I = 0; I != 7; ++I) {
        auto *CM = dyn_cast<ConstantAsMetadata>(N->getOperand(I));
        auto *CI = CM ? dyn_cast<ConstantInt>(CM->getValue()) : nullptr;
        if (!CI || !CI->getType()->isIntegerTy(64)) { Malformed = true; break; }
        V[I] = CI->getZExtValue();
      }
      if (Malformed || !V[2] || V[1] > V[2] || V[0] > UINT64_MAX - V[2] ||
          V[6] <= V[0] + V[2] || V[6] - (V[0] + V[2]) > UINT32_MAX) {
        Malformed = true; break;
      }
      Tails.emplace_back(V[0], V[0] + V[2], V[6], V[3]);
    }
    for (unsigned I = 0; !Malformed && I < Tails.size(); ++I)
      for (unsigned J = I + 1; J < Tails.size(); ++J)
        if (std::get<0>(Tails[I]) < std::get<2>(Tails[J]) &&
            std::get<0>(Tails[J]) < std::get<2>(Tails[I])) Malformed = true;
    if (!Malformed) for (auto [Begin, LogicalEnd, MappedEnd, Flags] : Tails) {
      GuestSegment *Source = nullptr;
      for (const auto &Existing : Ctx.Segments) {
        if (Existing->BaseResolved && Existing->GuestBase <= LogicalEnd - 1 &&
            LogicalEnd <= Existing->GuestBase + Existing->Size) {
          Source = Existing.get(); break;
        }
      }
      // McSema may append synthetic external-slot storage after the ELF
      // logical end.  It has no guest-range metadata; PT_LOAD is the
      // authoritative range, so require only that the backing aggregate
      // covers the proven mapped tail, never that its physical type ends
      // exactly at memsz.
      if (!Source || Source->GuestBase != Begin ||
          Source->GuestBase + Source->Size < MappedEnd ||
          Source->Executable != ((Flags & 1) != 0) ||
          Source->Writable != ((Flags & 2) != 0)) {
        continue;
      }
      // The lifted aggregate may physically include synthetic slots after the
      // ELF memsz.  They are not guest-addressable storage.  Clip the source
      // interval before BuildGuestAddressMap so [logical_end,mapped_end) has
      // exactly one owner (the page-tail below), for both loads and stores.
      Source->Size = LogicalEnd - Source->GuestBase;
      // This metadata is consumed by the later resolver lowering.  Without
      // it, that pass derives a range from a data_<addr> alias and the
      // aggregate's *physical* size, accidentally reintroducing McSema's
      // synthetic overhang as guest storage.  The PT_LOAD logical interval is
      // authoritative and is intentionally installed before aliases are
      // canonicalized.
      Source->GV->setMetadata("brighten.guest.range", MDNode::get(
          M.getContext(), {
              ConstantAsMetadata::get(ConstantInt::get(
                  Type::getInt64Ty(M.getContext()), Source->GuestBase)),
              ConstantAsMetadata::get(ConstantInt::get(
                  Type::getInt64Ty(M.getContext()), LogicalEnd))}));
      uint64_t TailSize = MappedEnd - LogicalEnd;
      auto *Ty = ArrayType::get(Type::getInt8Ty(M.getContext()), TailSize);
      auto *GV = new GlobalVariable(M, Ty, !(Flags & 2),
          GlobalValue::InternalLinkage, ConstantAggregateZero::get(Ty),
          "native_elf_mapped_page_tail");
      GV->setAlignment(Align(1));
      GV->setMetadata("brighten.guest.range", MDNode::get(M.getContext(), {
          ConstantAsMetadata::get(ConstantInt::get(Type::getInt64Ty(M.getContext()), LogicalEnd)),
          ConstantAsMetadata::get(ConstantInt::get(Type::getInt64Ty(M.getContext()), MappedEnd))}));
      // No direct IR use exists until a later native resolver is materialized;
      // retain this provenance-backed backing region across intervening DCE.
      appendToUsed(M, {GV});
      auto Tail = std::make_unique<GuestSegment>(); Tail->GV = GV;
      Tail->GuestBase = LogicalEnd; Tail->Size = TailSize; Tail->BaseResolved = true;
      Tail->ReadOnly = !(Flags & 2); Tail->Writable = Flags & 2; Tail->Executable = Flags & 1;
      Tail->IsMappedPageTail = true;
      Tail->Kind = Tail->Writable ? SegmentKind::Bss : SegmentKind::Unknown;
      Ctx.SegmentByBase[Tail->GuestBase] = Tail.get(); Ctx.Segments.push_back(std::move(Tail)); ++Count;
    }
    // A descriptor is useful only if every non-executable PT_LOAD which has
    // a lifted backing region participated in the same partition.  Do not
    // enable an authoritative map from a partially accepted descriptor set.
    HasValidatedPTLoadPartition = !Malformed;
  }

  if (HasValidatedPTLoadPartition && !Ctx.buildAuthoritativeGuestAddressMap()) {
    // Overlapping backing ranges have no proven owner.  Leave the existing
    // lifter representation untouched rather than letting first-match order
    // choose storage for a load and a different storage for a store.
    Ctx.HasAuthoritativeGuestAddressMap = false;
    Ctx.AuthoritativeGuestAddressMap.clear();
    if (Ctx.Debug)
      errs() << "[brighten-global-data] refused overlapping PT_LOAD guest map\n";
  }

  Ctx.Report.SegmentsDiscovered = Count;
  if (Ctx.Debug && Count > 0)
    errs() << "[brighten-global-data] discovered " << Count
           << " guest segments\n";

  return false; // Analysis only, does not modify IR
}

} // namespace brighten_global
