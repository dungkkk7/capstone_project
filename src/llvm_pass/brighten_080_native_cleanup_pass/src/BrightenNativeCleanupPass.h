#pragma once

#include "llvm/IR/PassManager.h"

namespace brighten_native_cleanup {

class BrightenNativeCleanupPass : public llvm::PassInfoMixin<BrightenNativeCleanupPass> {
 public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &AM);
 private:
  bool CleanupNativeArtifacts(llvm::Module &M);
};

} // namespace brighten_native_cleanup
