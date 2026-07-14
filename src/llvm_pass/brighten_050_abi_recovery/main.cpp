#include "BrightenABIRecoveryPass.h"

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_abi {

using namespace llvm;

PreservedAnalyses BrightenABIRecoveryPass::run(Module &M,
                                               ModuleAnalysisManager &) {
  ABIRecoveryContext Ctx(M);
  bool Changed = false;

  Changed |= NormalizeRegisterAccesses(Ctx);
  Changed |= AnalyzeFunctionLiveIns(Ctx);
  Changed |= AnalyzeFunctionLiveOuts(Ctx);
  Changed |= AnalyzeCallsiteABI(Ctx);
  Changed |= InferFunctionABISignatures(Ctx);
  Changed |= CloneNativeFunctions(Ctx);
  Changed |= RewriteNativeFunctionBodies(Ctx);
  // Rewrite while Remill functions still have their original identity.  The
  // wrapper pass below is only a compatibility boundary for genuinely
  // unresolved dynamic users; it must not hide direct calls from ABI recovery.
  Changed |= RewriteKnownCallsites(Ctx);
  Changed |= CreateRemillWrappers(Ctx);
  Changed |= RewriteMainWrapper(Ctx);
  Changed |= CleanupDeadRemillABI(Ctx);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_abi

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "BrightenABIRecoveryPass", "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-abi-recovery-pass") {
                    MPM.addPass(brighten_abi::BrightenABIRecoveryPass());
                    return true;
                  }
                  return false;
                });
          }};
}
