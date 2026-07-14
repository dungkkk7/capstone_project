#ifndef BRIGHTEN_NATIVE_CLEANUP_H
#define BRIGHTEN_NATIVE_CLEANUP_H

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

namespace brighten_native_cleanup {

class NativeCleanupPass
    : public llvm::PassInfoMixin<NativeCleanupPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);

  static bool cleanupModule(llvm::Module &M);
};

} // namespace brighten_native_cleanup

#endif
