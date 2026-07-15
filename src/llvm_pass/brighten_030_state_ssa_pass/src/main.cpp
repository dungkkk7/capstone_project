#include "BrightenStateSSAPass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_state_ssa {

using namespace llvm;

PreservedAnalyses BrightenStateSSAPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;

  // These rules existed as source files but were previously neither linked
  // nor called, leaving all flag-byte formulas in the register State model.
  Changed |= LowerKnownFlagComputations(M);
  Changed |= PromoteStateToSSA(M);
  Changed |= PromoteLocalStateAllocas(M);
  Changed |= SimplifyFlagConsumers(M);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

PreservedAnalyses BrightenLocalStateAllocaPass::run(
    Module &M, ModuleAnalysisManager &) {
  return BrightenStateSSAPass::PromoteLocalStateAllocas(M)
             ? PreservedAnalyses::none()
             : PreservedAnalyses::all();
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
                  if (Name == "brighten-local-state-ssa-pass") {
                    MPM.addPass(
                        brighten_state_ssa::BrightenLocalStateAllocaPass());
                    return true;
                  }
                  return false;
                });
          }};
}
