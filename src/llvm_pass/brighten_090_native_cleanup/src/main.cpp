#include "NativeCleanup.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_native_cleanup {

using namespace llvm;

PreservedAnalyses NativeCleanupPass::run(Module &M,
                                         ModuleAnalysisManager &AM) {
  (void)AM;
  bool Changed = cleanupModule(M, EnforceStrict, false);
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

PreservedAnalyses NativeCleanupPostFramePass::run(
    Module &M, ModuleAnalysisManager &AM) {
  (void)AM;
  bool Changed = NativeCleanupPass::finalizeCompactedFrames(M);
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
                  if (Name == "brighten-native-cleanup-post-frame-pass") {
                    MPM.addPass(brighten_native_cleanup::
                                    NativeCleanupPostFramePass());
                    return true;
                  }
                  return false;
                });
          }};
}
