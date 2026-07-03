#include "BrightenStateSSAPass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_state_ssa {

using namespace llvm;

PreservedAnalyses BrightenStateSSAPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;

  Changed |= PromoteStateToSSA(M);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_state_ssa

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenStateSSAPass",
          "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-state-ssa-pass") {
                    MPM.addPass(brighten_state_ssa::BrightenStateSSAPass());
                    return true;
                  }
                  return false;
                });
          }};
}
