#include "BrightenStackFramePass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_stack_frame {

using namespace llvm;

PreservedAnalyses BrightenStackFramePass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;

  Changed |= RecoverStackFrame(M);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_stack_frame

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenStackFramePass",
          "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-stack-frame-pass") {
                    MPM.addPass(brighten_stack_frame::BrightenStackFramePass());
                    return true;
                  }
                  return false;
                });
          }};
}
