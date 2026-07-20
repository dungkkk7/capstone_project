#ifndef BRIGHTEN_080_TYPE_RECONSTRUCTION_PASS_H
#define BRIGHTEN_080_TYPE_RECONSTRUCTION_PASS_H

#include "TypeReconstructionContext.h"
#include "llvm/IR/PassManager.h"

namespace brighten_type {

class BrightenTypeReconstructionPass
    : public llvm::PassInfoMixin<BrightenTypeReconstructionPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

class BrightenStructRecoverPass
    : public llvm::PassInfoMixin<BrightenStructRecoverPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

class BrightenArrayRecoverPass
    : public llvm::PassInfoMixin<BrightenArrayRecoverPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

// Internal engine function
bool RunTypeReconstruction(llvm::Module &M, TypeMode Mode, bool OnlyStruct, bool OnlyArray);

} // namespace brighten_type

#endif
