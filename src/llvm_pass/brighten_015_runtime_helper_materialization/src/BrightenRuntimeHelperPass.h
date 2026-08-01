#pragma once

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

namespace brighten_runtime {

class BrightenRuntimeHelperPass : public llvm::PassInfoMixin<BrightenRuntimeHelperPass> {
 public:
  llvm::PreservedAnalyses run(llvm::Module &M, llvm::ModuleAnalysisManager &);

 private:
  static bool LowerMcSemaAttachThunks(llvm::Module &M);
  static bool PreserveX86DivideFaults(llvm::Module &M);
  static bool DefineRemillControlFlowRuntime(llvm::Module &M);
  static bool LowerRemillMemoryIntrinsics(llvm::Module &M);
  static bool DefineRemillPureValueIntrinsics(llvm::Module &M);
  static bool DefineRemillAtomicBarrierRuntime(llvm::Module &M);
  static bool DefineRemillArchHypercallStubs(llvm::Module &M);
  static bool VerifyNoUnresolvedRemillIntrinsics(llvm::Module &M);

  // Nhập từ pass 010
  static bool ImplementExternCallBridge(llvm::Module &M);
  static bool RepairExternalFunctionPointerDereferences(llvm::Module &M);
  static bool RepairIntToPtrDereferences(llvm::Module &M);
  static bool CanonicalizeGuestAddressConstants(llvm::Module &M);
};

}  // namespace brighten_runtime
