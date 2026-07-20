#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

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

  Ctx.Report.SegmentsDiscovered = Count;
  if (Ctx.Debug && Count > 0)
    errs() << "[brighten-global-data] discovered " << Count
           << " guest segments\n";

  return false; // Analysis only, does not modify IR
}

} // namespace brighten_global
