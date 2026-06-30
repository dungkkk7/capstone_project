#include "BrightenABIRecoveryPass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_abi_recovery {

using namespace llvm;

PreservedAnalyses BrightenABIRecoveryPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;

  Changed |= RecoverABISignatures(M);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_abi_recovery

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenABIRecoveryPass",
          "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-abi-recovery-pass") {
                    MPM.addPass(brighten_abi_recovery::BrightenABIRecoveryPass());
                    return true;
                  }
                  return false;
                });
          }};
}
