#include "OLLVMDeobf.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

extern "C" LLVM_ATTRIBUTE_WEAK llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "BrightenOLLVMDeobfPass", "0.1.0",
          [](llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](llvm::StringRef Name, llvm::ModulePassManager &MPM,
                   llvm::ArrayRef<llvm::PassBuilder::PipelineElement>) {
                  if (Name != "brighten-ollvm-deobf-pass")
                    return false;
                  MPM.addPass(brighten_ollvm_deobf::OLLVMDeobfPass());
                  return true;
                });
          }};
}
