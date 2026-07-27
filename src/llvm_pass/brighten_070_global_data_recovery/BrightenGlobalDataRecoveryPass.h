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
  static bool RewriteGuestPointerTranslatorCalls(GlobalDataContext &Ctx);
  static bool RecoverJumpTableCFG(GlobalDataContext &Ctx);
  static bool RemoveDeadSegmentConstantUsers(GlobalDataContext &Ctx);
  static bool CleanupDeadSegmentArtifacts(GlobalDataContext &Ctx);
  static bool VerifyGlobalDataRecovery(GlobalDataContext &Ctx);
  static bool PrintGlobalDataRecoveryReport(GlobalDataContext &Ctx);
};

// This is intentionally a separate late phase.  It owns the representation
// of proven guest-address resolvers after object recovery has finished; it
// does not discover objects or change their ranges.
class BrightenGuestPointerResolverCanonicalizePass
    : public llvm::PassInfoMixin<BrightenGuestPointerResolverCanonicalizePass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

bool CanonicalizeGuestPointerResolvers(llvm::Module &M);

// Runs only after the late ABI/external-call bridge has exposed a direct
// libc format operand. It does not recover arbitrary residual objects.
bool RecoverLateResidualFormatStrings(llvm::Module &M);

class BrightenLateResidualFormatStringRecoveryPass
    : public llvm::PassInfoMixin<BrightenLateResidualFormatStringRecoveryPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

} // namespace brighten_global

#endif
