#ifndef BRIGHTEN_STACK_FRAME_PASS_H
#define BRIGHTEN_STACK_FRAME_PASS_H

#include "llvm/IR/PassManager.h"
#include "llvm/IR/Module.h"

namespace brighten_stack_frame {

class BrightenStackFramePass : public llvm::PassInfoMixin<BrightenStackFramePass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &AM);

  // Phase 4 Rules
  static bool RecoverStackFrame(llvm::Module &M);
};

// This is deliberately separate from the architectural stack recovery pass.
// It runs after State ABI lowering and region CFG recovery, where a marked
// byte backing can be proved to be one local frame even when its accesses were
// split across a single-use internal direct-call chain.
class BrightenPostStateFramePass
    : public llvm::PassInfoMixin<BrightenPostStateFramePass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &AM);

  // State-SSA can leave a module-global byte backing after architectural
  // register storage has been removed.  This rule only compacts a backing
  // whose complete (possibly inlined) use graph proves it is one initialized,
  // non-escaping function-local object.
  static bool CompactProvenPostStateFrameBackings(llvm::Module &M);
};

} // namespace brighten_stack_frame

#endif // BRIGHTEN_STACK_FRAME_PASS_H
