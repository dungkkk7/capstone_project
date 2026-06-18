#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"

using namespace llvm;

namespace {

struct BrightenMemoryClassifyPass : public PassInfoMixin<BrightenMemoryClassifyPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    bool Changed = false;
    for (Function &F : M) {
      if (F.isDeclaration() || F.empty()) continue;
      
      for (Instruction &I : instructions(F)) {
        if (auto *I2P = dyn_cast<IntToPtrInst>(&I)) {
          // Identify integer-to-pointer casts that can be simplified into direct gep operations
          Changed = true;
        }
      }
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
    LLVM_PLUGIN_API_VERSION,
    "BrightenMemoryClassifyPass",
    LLVM_VERSION_STRING,
    [](PassBuilder &PB) {
      PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "brighten-memory-classify-pass") {
            MPM.addPass(BrightenMemoryClassifyPass());
            return true;
          }
          return false;
        }
      );
    }
  };
}
