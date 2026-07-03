#ifndef BRIGHTEN_070_GLOBAL_DATA_RECOVERY_PASS_H
#define BRIGHTEN_070_GLOBAL_DATA_RECOVERY_PASS_H

#include "GlobalDataContext.h"

#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"

namespace brighten_global {

class BrightenGlobalDataRecoveryPass
    : public llvm::PassInfoMixin<BrightenGlobalDataRecoveryPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);

  static bool DiscoverGuestSegments(GlobalDataContext &Ctx);
  static bool FlattenSegmentBytes(GlobalDataContext &Ctx);
  static bool BuildGuestAddressMap(GlobalDataContext &Ctx);
  static bool GenerateObjectCandidates(GlobalDataContext &Ctx);
  static bool ResolveObjectConflicts(GlobalDataContext &Ctx);
  static bool MaterializeRecoveredGlobals(GlobalDataContext &Ctx);
  static bool RewriteGuestDataReferences(GlobalDataContext &Ctx);
  static bool RecoverJumpTableCFG(GlobalDataContext &Ctx);
  static bool CleanupDeadSegmentArtifacts(GlobalDataContext &Ctx);
  static bool VerifyGlobalDataRecovery(GlobalDataContext &Ctx);
  static bool PrintGlobalDataRecoveryReport(GlobalDataContext &Ctx);
};

} // namespace brighten_global

#endif
