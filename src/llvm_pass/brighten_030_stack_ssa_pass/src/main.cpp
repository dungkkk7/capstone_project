#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

struct BrightenStackSSAPass : public PassInfoMixin<BrightenStackSSAPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    errs() << "Running BrightenStackSSAPass\n";
    // TODO: implement pass logic
    return PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
    LLVM_PLUGIN_API_VERSION,
    "BrightenStackSSAPass",
    LLVM_VERSION_STRING,
    [](PassBuilder &PB) {
      PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "brighten-stack-ssa-pass") {
            MPM.addPass(BrightenStackSSAPass());
            return true;
          }
          return false;
        }
      );
    }
  };
}
