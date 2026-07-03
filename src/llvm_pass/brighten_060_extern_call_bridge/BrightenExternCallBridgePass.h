#ifndef BRIGHTEN_060_EXTERN_CALL_BRIDGE_PASS_H
#define BRIGHTEN_060_EXTERN_CALL_BRIDGE_PASS_H

#include "ExternCallContext.h"

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

namespace brighten_extern {

class BrightenExternCallBridgePass
    : public llvm::PassInfoMixin<BrightenExternCallBridgePass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);

  static bool DiscoverExternalSymbols(ExternCallContext &Ctx);
  static bool AnalyzeExternalCallsites(ExternCallContext &Ctx);
  static bool RecoverLibcArguments(ExternCallContext &Ctx);
  static bool RecoverVarargArguments(ExternCallContext &Ctx);
  static bool RewriteExternalCallsites(ExternCallContext &Ctx);
  static bool RewriteExternalReturns(ExternCallContext &Ctx);
  static bool CleanupExternalCallArtifacts(ExternCallContext &Ctx);
  static bool VerifyExternalCallRecovery(ExternCallContext &Ctx);
  static bool PrintExternalCallRecoveryReport(ExternCallContext &Ctx);
};

} // namespace brighten_extern

#endif
