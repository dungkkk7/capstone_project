#include "BrightenTypeReconstructPass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_type_reconstruct {

using namespace llvm;

PreservedAnalyses BrightenTypeReconstructPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;
  Changed |= ReconstructTypes(M);
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_type_reconstruct

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenTypeReconstructPass",
          "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-type-reconstruct-pass") {
                    MPM.addPass(brighten_type_reconstruct::BrightenTypeReconstructPass());
                    return true;
                  }
                  return false;
                });
          }};
}
