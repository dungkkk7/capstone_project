#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_global {

using namespace llvm;

PreservedAnalyses BrightenGlobalDataRecoveryPass::run(Module &M,
                                                       ModuleAnalysisManager &) {
  GlobalDataContext Ctx(M);
  bool Changed = false;

  Changed |= DiscoverGuestSegments(Ctx);
  Changed |= FlattenSegmentBytes(Ctx);
  Changed |= BuildGuestAddressMap(Ctx);
  Changed |= GenerateObjectCandidates(Ctx);
  Changed |= ResolveObjectConflicts(Ctx);
  Changed |= MaterializeRecoveredGlobals(Ctx);
  Changed |= RewriteGuestDataReferences(Ctx);
  Changed |= RecoverJumpTableCFG(Ctx);
  Changed |= CleanupDeadSegmentArtifacts(Ctx);
  VerifyGlobalDataRecovery(Ctx);
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
