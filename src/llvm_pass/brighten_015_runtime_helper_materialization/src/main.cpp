#include "BrightenRuntimeHelperPass.h"

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_runtime {

using namespace llvm;

PreservedAnalyses BrightenRuntimeHelperPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;

  Changed |= LowerMcSemaAttachThunks(M);
  Changed |= PreserveX86DivideFaults(M);
  Changed |= ImplementExternCallBridge(M);
  Changed |= CanonicalizeGuestAddressConstants(M);
  Changed |= RepairExternalFunctionPointerDereferences(M);
  Changed |= RepairIntToPtrDereferences(M);
  Changed |= DefineRemillControlFlowRuntime(M);
  Changed |= LowerRemillMemoryIntrinsics(M);
  Changed |= DefineRemillPureValueIntrinsics(M);
  Changed |= DefineRemillAtomicBarrierRuntime(M);
  Changed |= DefineRemillArchHypercallStubs(M);
  Changed |= VerifyNoUnresolvedRemillIntrinsics(M);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

}  // namespace brighten_runtime

extern "C" LLVM_ATTRIBUTE_WEAK llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenRuntimeHelperPass",
          "0.1.0",
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
