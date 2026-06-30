#pragma once

#include "llvm/IR/PassManager.h"

namespace brighten_global_data {

class BrightenGlobalDataPass : public llvm::PassInfoMixin<BrightenGlobalDataPass> {
 public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &AM);
 private:
  bool RecoverGlobalData(llvm::Module &M);
  bool RecoverStringLiterals(llvm::Module &M);
};

} // namespace brighten_global_data
