#ifndef BRIGHTEN_070_GLOBAL_DATA_RECOVERY_PASS_H
#define BRIGHTEN_070_GLOBAL_DATA_RECOVERY_PASS_H

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

namespace brighten_global {

// 070 v2 models lifted segments as byte-addressed storage.  It materializes a
// source-level global only when every observed reference to the recovered byte
// interval has a constant provenance and compatible access type.
class BrightenGlobalDataRecoveryPass
    : public llvm::PassInfoMixin<BrightenGlobalDataRecoveryPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

} // namespace brighten_global

#endif
