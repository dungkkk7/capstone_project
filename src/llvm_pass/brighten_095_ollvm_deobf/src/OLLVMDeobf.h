#pragma once

#include "llvm/IR/PassManager.h"

namespace brighten_ollvm_deobf {

class OLLVMDeobfPass : public llvm::PassInfoMixin<OLLVMDeobfPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &MAM);
};

} // namespace brighten_ollvm_deobf
