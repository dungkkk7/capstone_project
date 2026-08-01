#include "BrightenDevirtPass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Transforms/IPO/GlobalDCE.h"

namespace brighten_devirt {

using namespace llvm;

PreservedAnalyses BrightenDevirtPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;

  Changed |= LowerExternalCalls(M);
  Changed |= DevirtualizeRemillFunctionCalls(M);
  Changed |= DevirtualizeRemillJumps(M);
  Changed |= AnnotateRemillReturns(M);
  Changed |= CleanupCallbackThunks(M);
  Changed |= CleanupUnusedRemillDispatchers(M);
  Changed |= LowerProvenConstantStateSwitches(M);

  VerifyDevirtualization(M);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

PreservedAnalyses BrightenRegionSSAUnflattenPass::run(
    Module &M, ModuleAnalysisManager &) {
  return BrightenDevirtPass::LowerRegionSSAStateSwitches(M)
             ? PreservedAnalyses::none()
             : PreservedAnalyses::all();
}

} // namespace brighten_devirt

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenDevirtPass",
          "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-devirt-pass") {
                    MPM.addPass(brighten_devirt::BrightenDevirtPass());
                    MPM.addPass(::llvm::GlobalDCEPass());
                    return true;
                  }
                  if (Name == "brighten-region-ssa-unflatten-pass") {
                    MPM.addPass(
                        brighten_devirt::BrightenRegionSSAUnflattenPass());
                    return true;
                  }
                  return false;
                });
          }};
}
