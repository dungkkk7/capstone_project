#ifndef BRIGHTEN_DEVIRT_PASS_H
#define BRIGHTEN_DEVIRT_PASS_H

#include "llvm/IR/PassManager.h"
#include "llvm/IR/Module.h"

namespace brighten_devirt {

class BrightenDevirtPass : public llvm::PassInfoMixin<BrightenDevirtPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &AM);

  // Phase 2 Rules
  static bool DevirtualizeRemillCalls(llvm::Module &M);
  static bool LowerRemillReturn(llvm::Module &M);
  static bool LowerLibcCalls(llvm::Module &M);
};

// Helper function declarations
llvm::Function *FindLiftedSubroutineByPC(llvm::Module &M, uint64_t PC);

} // namespace brighten_devirt

#endif // BRIGHTEN_DEVIRT_PASS_H
