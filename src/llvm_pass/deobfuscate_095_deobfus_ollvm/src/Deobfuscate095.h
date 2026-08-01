#ifndef DEOBFUSCATE_095_H
#define DEOBFUSCATE_095_H

#include "llvm/IR/PassManager.h"
#include "llvm/IR/Module.h"

namespace deobfuscate095 {

class Deobfuscate095Pass
    : public llvm::PassInfoMixin<Deobfuscate095Pass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &MAM);
};

} // namespace deobfuscate095

#endif

