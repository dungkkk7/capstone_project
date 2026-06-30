#pragma once

#include "llvm/IR/PassManager.h"

namespace brighten_type_reconstruct {

class BrightenTypeReconstructPass : public llvm::PassInfoMixin<BrightenTypeReconstructPass> {
 public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &AM);
 private:
  bool ReconstructTypes(llvm::Module &M);
};

} // namespace brighten_type_reconstruct
