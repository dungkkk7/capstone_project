#include "BrightenGlobalDataPass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_global_data {

using namespace llvm;

PreservedAnalyses BrightenGlobalDataPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;
  Changed |= RecoverGlobalData(M);
  Changed |= RecoverStringLiterals(M);
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_global_data

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenGlobalDataPass",
          "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-global-data-pass") {
                    MPM.addPass(brighten_global_data::BrightenGlobalDataPass());
                    return true;
                  }
                  return false;
                });
          }};
}
