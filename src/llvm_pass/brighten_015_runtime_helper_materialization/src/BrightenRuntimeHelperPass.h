#pragma once

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

namespace brighten_runtime {

// Phase 015 has one responsibility: make the lifted Remill/McSema runtime
// semantics explicit enough for later semantic analyses.  It deliberately
// does NOT recover native external ABIs, stack objects, function signatures,
// globals, or source types; those belong to 040/050/060/070/080.
class BrightenRuntimeHelperPass
    : public llvm::PassInfoMixin<BrightenRuntimeHelperPass> {
 public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &);

 private:
  static bool LowerMcSemaAttachThunks(llvm::Module &M);
  static bool PreserveX86DivideFaults(llvm::Module &M);
  static bool CanonicalizeGuestAddressConstants(llvm::Module &M);
  static bool DefineRemillControlFlowRuntime(llvm::Module &M);
  static bool LowerRemillMemoryIntrinsics(llvm::Module &M);
  static bool DefineRemillPureValueIntrinsics(llvm::Module &M);
  static bool DefineRemillAtomicBarrierRuntime(llvm::Module &M);
  static bool DefineRemillArchHypercallStubs(llvm::Module &M);
  static bool VerifyNoUnresolvedRemillIntrinsics(llvm::Module &M);
};

}  // namespace brighten_runtime
