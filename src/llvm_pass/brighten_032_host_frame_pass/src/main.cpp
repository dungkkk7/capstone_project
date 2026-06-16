#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {

struct BrightenHostFramePass : public PassInfoMixin<BrightenHostFramePass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    errs() << "Running BrightenHostFramePass\n";
    // TODO: implement pass logic
    return PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
    LLVM_PLUGIN_API_VERSION,
    "BrightenHostFramePass",
    LLVM_VERSION_STRING,
    [](PassBuilder &PB) {
      PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "brighten-host-frame-pass") {
            MPM.addPass(BrightenHostFramePass());
            return true;
          }
          return false;
        }
      );
    }
  };
}
