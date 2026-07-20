#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/Support/raw_ostream.h"

namespace brighten_global {

using namespace llvm;

bool BrightenGlobalDataRecoveryPass::PrintGlobalDataRecoveryReport(
    GlobalDataContext &Ctx) {
  errs() << "brighten-global-data-recovery report:\n"
         << "  Segments discovered: " << Ctx.Report.SegmentsDiscovered << "\n"
         << "  Guest address refs discovered: "
         << Ctx.Report.GuestAddressRefsDiscovered << "\n"
         << "  Strings recovered: " << Ctx.Report.StringsRecovered << "\n"
         << "  Global scalars recovered: "
         << Ctx.Report.GlobalScalarsRecovered << "\n"
         << "  Global arrays recovered: "
         << Ctx.Report.GlobalArraysRecovered << "\n"
         << "  Pointer tables recovered: "
         << Ctx.Report.PointerTablesRecovered << "\n"
         << "  Jump tables recovered: "
         << Ctx.Report.JumpTablesRecovered << "\n"
         << "  Data references rewritten: "
         << Ctx.Report.DataRefsRewritten << "\n"
         << "  Segments removed: " << Ctx.Report.SegmentsRemoved << "\n"
         << "  Preserved refs/objects: " << Ctx.Report.PreservedRefs << "\n"
         << "  Verifier errors: " << Ctx.Report.VerifierErrors << "\n"
         << "  Detail:\n";

  for (auto &Seg : Ctx.Segments) {
    if (!Seg->GV && !Seg->BaseResolved)
      continue;
    errs() << "    segment=";
    if (Seg->GV)
      errs() << "@" << Seg->GV->getName();
    else
      errs() << "(removed)";
    errs() << " base=0x" << Twine::utohexstr(Seg->GuestBase)
           << " size=0x" << Twine::utohexstr(Seg->Size)
           << " kind=";
    switch (Seg->Kind) {
    case SegmentKind::Rodata: errs() << "rodata"; break;
    case SegmentKind::Data: errs() << "data"; break;
    case SegmentKind::Bss: errs() << "bss"; break;
    case SegmentKind::Got: errs() << "got"; break;
    case SegmentKind::Plt: errs() << "plt"; break;
    case SegmentKind::Unknown: errs() << "unknown"; break;
    }
    if (!Seg->SkipReason.empty())
      errs() << " reason=" << Seg->SkipReason;
    errs() << "\n";
  }

  for (auto &[Addr, Obj] : Ctx.RecoveredObjects) {
    errs() << "    object=" << Obj->Name
           << " action=" << Obj->Action
           << " range=[0x" << Twine::utohexstr(Obj->Begin)
           << ",0x" << Twine::utohexstr(Obj->End) << ")\n";
  }

  // Report preserved references with reasons
  std::map<std::string, unsigned> SkipReasonCounts;
  for (auto &Ref : Ctx.AddressRefs) {
    if (!Ref->Rewritten && !Ref->SkipReason.empty())
      ++SkipReasonCounts[Ref->SkipReason];
  }
  if (!SkipReasonCounts.empty()) {
    errs() << "  Preserved ref reasons:\n";
    for (auto &[Reason, Count] : SkipReasonCounts)
      errs() << "    " << Reason << ": " << Count << "\n";
  }

  return false;
}

} // namespace brighten_global
