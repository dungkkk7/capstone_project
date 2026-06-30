#ifndef BRIGHTEN_ABI_RECOVERY_PASS_H
#define BRIGHTEN_ABI_RECOVERY_PASS_H

#include "llvm/IR/PassManager.h"
#include "llvm/IR/Module.h"

namespace brighten_abi_recovery {

class BrightenABIRecoveryPass : public llvm::PassInfoMixin<BrightenABIRecoveryPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &AM);

  static bool RecoverABISignatures(llvm::Module &M);
};

} // namespace brighten_abi_recovery

#endif // BRIGHTEN_ABI_RECOVERY_PASS_H
