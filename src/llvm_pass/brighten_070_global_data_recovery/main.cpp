#include "llvm/Support/ErrorHandling.h"
#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

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

  // Transformation passes
  Changed |= MaterializeRecoveredGlobals(Ctx);
  Changed |= RecoverJumpTableCFG(Ctx);
  Changed |= RewriteGuestDataReferences(Ctx);
  Changed |= RewriteGuestPointerTranslatorCalls(Ctx);
  Changed |= RemoveDeadSegmentConstantUsers(Ctx);
  Changed |= CleanupDeadSegmentArtifacts(Ctx);

  bool HasVerifierError = VerifyGlobalDataRecovery(Ctx);
  if (Ctx.Mode == DataRecoveryMode::NativeStrict && HasVerifierError) {
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
