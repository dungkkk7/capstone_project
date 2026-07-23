#include "llvm/Support/ErrorHandling.h"
#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

#include <cstdlib>

namespace brighten_global {

using namespace llvm;

PreservedAnalyses BrightenGlobalDataRecoveryPass::run(Module &M,
                                                       ModuleAnalysisManager &) {
  GlobalDataContext Ctx(M);
  bool Changed = false;

  // Analysis / helper passes (do not modify IR)
  DiscoverGuestSegments(Ctx);
  FlattenSegmentBytes(Ctx);
  BuildGuestAddressMap(Ctx);
  GenerateObjectCandidates(Ctx);
  ResolveObjectConflicts(Ctx);

  // Do not partially rewrite a segment when analysis cannot place a live
  // guest-address carrier in any recovered object.  Once globals have been
  // materialized there is no sound way to roll the module back, and forcing a
  // pointer-sized placeholder can split one logical array into unrelated host
  // objects.  Preserve the original lifted storage so later compatibility
  // cleanup can retain its established guest-address semantics.
  if (Ctx.Mode == DataRecoveryMode::NativeStrict) {
    for (const auto &Ref : Ctx.AddressRefs) {
      if (!Ref->Segment || !Ref->Segment->BaseResolved || !Ref->UserInst ||
          !Ref->UserInst->getParent() || !Ref->SkipReason.empty())
        continue;
      bool Covered = false;
      for (const auto &Candidate : Ctx.Candidates) {
        if (Ref->GuestAddr >= Candidate->Begin &&
            Ref->GuestAddr < Candidate->End) {
          Covered = true;
          break;
        }
      }
      if (Covered)
        continue;
      // The generated translator range-checks the guest address before this
      // dynamic GEP and returns the resulting segment pointer.  It is storage
      // infrastructure, not an uncovered program data consumer; all actual
      // users of the translated pointer are analyzed independently.
      if (Ref->UserInst->getFunction()->getName() ==
          "__translate_guest_pointer")
        continue;
      // Address-identity comparisons and arithmetic-only intermediate bases
      // do not themselves consume memory and therefore do not require a
      // recovered object.  Their downstream pointer consumers are recorded
      // independently.  Unknown dynamic GEP carriers and direct
      // LoadStorePointer uses must remain covered: ignoring those categories
      // allowed partial rewrites before strict validation found the gap.
      if (Ref->ConsumerKind == DataConsumerKind::ComparisonOnly ||
          Ref->ConsumerKind == DataConsumerKind::ArithmeticOnly)
        continue;
      errs() << "[brighten-global-data] preserving module: unresolved guest "
                "address carrier at 0x"
             << Twine::utohexstr(Ref->GuestAddr) << " kind="
             << static_cast<unsigned>(Ref->ConsumerKind) << "\n";
      errs() << "  instruction: ";
      Ref->UserInst->print(errs());
      errs() << "\n";
      return PreservedAnalyses::all();
    }
  }

  // Transformation passes
  Changed |= MaterializeRecoveredGlobals(Ctx);
  Changed |= RecoverJumpTableCFG(Ctx);
  Changed |= RewriteGuestDataReferences(Ctx);
  Changed |= RewriteGuestPointerTranslatorCalls(Ctx);
  Changed |= RemoveDeadSegmentConstantUsers(Ctx);
  Changed |= CleanupDeadSegmentArtifacts(Ctx);

  bool HasVerifierError = VerifyGlobalDataRecovery(Ctx);
  const bool AuditOnly = std::getenv("BRIGHTEN_GLOBAL_AUDIT_ONLY") != nullptr;
  if (Ctx.Mode == DataRecoveryMode::NativeStrict && HasVerifierError &&
      !AuditOnly) {
    report_fatal_error("global data recovery validation failed in strict mode");
  }
  PrintGlobalDataRecoveryReport(Ctx);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_global

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "BrightenGlobalDataRecoveryPass", "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-global-data-recovery-pass") {
                    MPM.addPass(
                        brighten_global::BrightenGlobalDataRecoveryPass());
                    return true;
                  }
                  return false;
                });
          }};
}
