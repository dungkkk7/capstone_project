#include "BrightenDevirtPass.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Transforms/IPO/GlobalDCE.h"

#include <cstdlib>

namespace brighten_devirt {

using namespace llvm;

// Diagnostic-only bisect gate.  It is intentionally opt-in and affects no
// production invocation unless the environment explicitly names a rule.
static bool RuleDisabled(StringRef Rule) {
  const char *Value = std::getenv("BRIGHTEN_020_DISABLE_RULE");
  if (!Value || !*Value)
    return false;
  SmallVector<StringRef, 8> Rules;
  StringRef(Value).split(Rules, ',', /*MaxSplit=*/-1,
                         /*KeepEmpty=*/false);
  return llvm::is_contained(Rules, Rule);
}

PreservedAnalyses BrightenDevirtPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = false;

  if (!RuleDisabled("lower_external_calls"))
    Changed |= LowerExternalCalls(M);
  if (!RuleDisabled("devirtualize_remill_function_calls"))
    Changed |= DevirtualizeRemillFunctionCalls(M);
  if (!RuleDisabled("devirtualize_remill_jumps"))
    Changed |= DevirtualizeRemillJumps(M);
  if (!RuleDisabled("annotate_remill_returns"))
    Changed |= AnnotateRemillReturns(M);
  if (!RuleDisabled("cleanup_callback_thunks"))
    Changed |= CleanupCallbackThunks(M);
  if (!RuleDisabled("cleanup_unused_remill_dispatchers"))
    Changed |= CleanupUnusedRemillDispatchers(M);
  if (!RuleDisabled("lower_proven_constant_state_switches"))
    Changed |= LowerProvenConstantStateSwitches(M);

  VerifyDevirtualization(M);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

PreservedAnalyses BrightenRegionSSAUnflattenPass::run(
    Module &M, ModuleAnalysisManager &) {
  return BrightenDevirtPass::LowerRegionSSAStateSwitches(M)
             ? PreservedAnalyses::none()
             : PreservedAnalyses::all();
}

} // namespace brighten_devirt

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenDevirtPass",
          "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-devirt-pass") {
                    MPM.addPass(brighten_devirt::BrightenDevirtPass());
                    if (!brighten_devirt::RuleDisabled("global_dce"))
                      MPM.addPass(::llvm::GlobalDCEPass());
                    return true;
                  }
                  if (Name == "brighten-region-ssa-unflatten-pass") {
                    MPM.addPass(
                        brighten_devirt::BrightenRegionSSAUnflattenPass());
                    return true;
                  }
                  return false;
                });
          }};
}
