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
  static bool RecoverStrings(llvm::Module &M);
};

} // namespace brighten_stack_frame

#endif // BRIGHTEN_STACK_FRAME_PASS_H
