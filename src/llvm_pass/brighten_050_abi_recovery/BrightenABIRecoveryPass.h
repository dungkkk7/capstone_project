#ifndef BRIGHTEN_050_ABI_RECOVERY_PASS_H
#define BRIGHTEN_050_ABI_RECOVERY_PASS_H

#include "ABIAnalysis.h"

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

namespace brighten_abi {

class BrightenABIRecoveryPass
    : public llvm::PassInfoMixin<BrightenABIRecoveryPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);

  static bool NormalizeRegisterAccesses(ABIRecoveryContext &Ctx);
  static bool AnalyzeFunctionLiveIns(ABIRecoveryContext &Ctx);
  static bool AnalyzeFunctionLiveOuts(ABIRecoveryContext &Ctx);
  static bool AnalyzeCallsiteABI(ABIRecoveryContext &Ctx);
  static bool InferFunctionABISignatures(ABIRecoveryContext &Ctx);
  static bool CloneNativeFunctions(ABIRecoveryContext &Ctx);
  static bool RewriteNativeFunctionBodies(ABIRecoveryContext &Ctx);
  static bool RewriteKnownCallsites(ABIRecoveryContext &Ctx);
  // Normalize only fully proven direct libc scanf("%d", int *) boundaries
  // into a typed call-through wrapper.  This is ABI normalization, not a
  // replacement for scanf and deliberately makes no capture/memory claim.
  static bool NormalizeScanfI32Boundaries(ABIRecoveryContext &Ctx);
  static bool LowerCallbackAndSharedStateABI(ABIRecoveryContext &Ctx);
  static bool CreateRemillWrappers(ABIRecoveryContext &Ctx);
  static bool RewriteMainWrapper(ABIRecoveryContext &Ctx);
  static bool CleanupDeadRemillABI(ABIRecoveryContext &Ctx);
};

} // namespace brighten_abi

#endif
