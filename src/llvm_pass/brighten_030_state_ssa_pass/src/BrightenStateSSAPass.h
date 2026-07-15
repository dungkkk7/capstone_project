#ifndef BRIGHTEN_STATE_SSA_PASS_H
#define BRIGHTEN_STATE_SSA_PASS_H

#include "llvm/IR/PassManager.h"
#include "llvm/IR/Module.h"

namespace brighten_state_ssa {

class BrightenStateSSAPass : public llvm::PassInfoMixin<BrightenStateSSAPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &AM);

  // Phase 3 Rules
  static bool LowerKnownFlagComputations(llvm::Module &M);
  static bool PromoteStateToSSA(llvm::Module &M);
  static bool PromoteLocalStateAllocas(llvm::Module &M);
  static bool SimplifyFlagConsumers(llvm::Module &M);
};

class BrightenLocalStateAllocaPass
    : public llvm::PassInfoMixin<BrightenLocalStateAllocaPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

} // namespace brighten_state_ssa

#endif // BRIGHTEN_STATE_SSA_PASS_H
