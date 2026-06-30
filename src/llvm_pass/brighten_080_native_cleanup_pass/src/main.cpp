#include "BrightenNativeCleanupPass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_native_cleanup {

using namespace llvm;

PreservedAnalyses BrightenNativeCleanupPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;
  Changed |= CleanupNativeArtifacts(M);
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_native_cleanup

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenNativeCleanupPass",
          "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-native-cleanup-pass") {
                    MPM.addPass(brighten_native_cleanup::BrightenNativeCleanupPass());
                    return true;
                  }
                  return false;
                });
          }};
}
