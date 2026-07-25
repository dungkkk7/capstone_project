#include "NativeCleanup.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Transforms/InstCombine/InstCombine.h"

namespace brighten_native_cleanup {

using namespace llvm;

PreservedAnalyses NativeCleanupPass::run(Module &M,
                                         ModuleAnalysisManager &AM) {
  FunctionAnalysisManager *FAM = nullptr;
  if (EnforceStrict)
    FAM = &AM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();

  bool Changed = cleanupModule(M, EnforceStrict, EnforceStrict);
  if (EnforceStrict &&
      M.getNamedMetadata("brighten.final.frame.compacted")) {
    // Affine frame compaction replaces a huge global with a small alloca, but
    // deliberately preserves the old pointer arithmetic.  One InstCombine
    // sweep canonicalizes those now-local addresses so the provenance-gated
    // finalizer can see exact native-frame slots and remove the generated
    // guest-range dispatches.  Run it only when this invocation compacted a
    // frame; an already-clean module remains a verifier-only operation.
    FAM->clear();
    FunctionPassManager FPM;
    FPM.addPass(InstCombinePass());
    for (Function &F : M)
      if (!F.isDeclaration())
        FPM.run(F, *FAM);
    Changed = true;
    Changed |= finalizeCompactedFrames(M);
  }
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_native_cleanup

extern "C" LLVM_ATTRIBUTE_WEAK llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenNativeCleanupPass",
          "0.1.0",
          [](llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](llvm::StringRef Name, llvm::ModulePassManager &MPM,
                   llvm::ArrayRef<llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-native-cleanup-pass") {
                    MPM.addPass(
                        brighten_native_cleanup::NativeCleanupPass(false));
                    return true;
                  }
                  if (Name == "brighten-native-cleanup-final-pass") {
                    MPM.addPass(
                        brighten_native_cleanup::NativeCleanupPass(true));
                    return true;
                  }
                  return false;
                });
          }};
}
