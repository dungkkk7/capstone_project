#ifndef BRIGHTEN_NATIVE_CLEANUP_H
#define BRIGHTEN_NATIVE_CLEANUP_H

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

namespace brighten_native_cleanup {

class NativeCleanupPass
    : public llvm::PassInfoMixin<NativeCleanupPass> {
public:
  explicit NativeCleanupPass(bool EnforceStrict = false)
      : EnforceStrict(EnforceStrict) {}

  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);

  static bool cleanupModule(llvm::Module &M, bool EnforceStrict = false,
                            bool DeferCompactedFrameFinalization = false);
  static bool finalizeCompactedFrames(llvm::Module &M);

private:
  bool EnforceStrict;
};

// Narrow mutation boundary after the final 040/heap-owner sweep. Late frame
// promotion can expose pointer PHIs and native affine round-trips that did not
// exist at either broad cleanup boundary.
class NativeCleanupPostFramePass
    : public llvm::PassInfoMixin<NativeCleanupPostFramePass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

} // namespace brighten_native_cleanup

#endif
