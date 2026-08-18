#include "BrightenRuntimeHelperPass.h"

#include "llvm/IR/Verifier.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/ErrorHandling.h"

namespace brighten_runtime {

using namespace llvm;

PreservedAnalyses BrightenRuntimeHelperPass::run(Module &M,
                                                 ModuleAnalysisManager &) {
  bool Changed = false;

  // 015 is intentionally small and monotonic: it exposes runtime semantics
  // but never guesses a source ABI or application object model.
  Changed |= LowerMcSemaAttachThunks(M);
  Changed |= PreserveX86DivideFaults(M);
  Changed |= CanonicalizeGuestAddressConstants(M);
  Changed |= DefineRemillControlFlowRuntime(M);
  Changed |= LowerRemillMemoryIntrinsics(M);
  Changed |= DefineRemillPureValueIntrinsics(M);
  Changed |= DefineRemillAtomicBarrierRuntime(M);
  Changed |= DefineRemillArchHypercallStubs(M);
  Changed |= VerifyNoUnresolvedRemillIntrinsics(M);

  std::string Error;
  raw_string_ostream OS(Error);
  if (verifyModule(M, &OS))
    report_fatal_error("015 runtime materialization produced invalid IR:\n" +
                       OS.str());

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

}  // namespace brighten_runtime

extern "C" LLVM_ATTRIBUTE_WEAK llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenRuntimeHelperPass",
          "2.0.0",
          [](llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](llvm::StringRef Name, llvm::ModulePassManager &MPM,
                   llvm::ArrayRef<llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-remill-runtime-pass") {
                    MPM.addPass(brighten_runtime::BrightenRuntimeHelperPass());
                    return true;
                  }
                  return false;
                });
          }};
}
