#ifndef BRIGHTEN_STATE_SSA_PASS_H
#define BRIGHTEN_STATE_SSA_PASS_H

#include "llvm/IR/PassManager.h"
#include "llvm/IR/Module.h"

namespace brighten_state_ssa {

class BrightenStateSSAPass : public llvm::PassInfoMixin<BrightenStateSSAPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &AM);

  // Phase 3 Rules
  static bool PromoteStateToSSA(llvm::Module &M);
};

} // namespace brighten_state_ssa

#endif // BRIGHTEN_STATE_SSA_PASS_H
