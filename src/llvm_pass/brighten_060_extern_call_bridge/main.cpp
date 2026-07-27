#include "BrightenExternCallBridgePass.h"

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_extern {

using namespace llvm;

#include "llvm/Support/CommandLine.h"

static llvm::cl::opt<bool> ExternCompatFallback(
    "extern-compat-fallback",
    llvm::cl::desc("Enable compatibility fallback translation using __translate_guest_pointer"),
    llvm::cl::init(false));

PreservedAnalyses BrightenExternCallBridgePass::run(Module &M,
                                                     ModuleAnalysisManager &) {
  ExternCallContext Ctx(M);
  if (ExternCompatFallback) {
    Ctx.Mode = ExternRecoveryMode::CompatFallback;
  } else {
    Ctx.Mode = ExternRecoveryMode::NativeStrict;
  }
  Ctx.SigDB.initialize(M.getContext());
  bool Changed = false;

  Changed |= DiscoverExternalSymbols(Ctx);
  Changed |= AnalyzeExternalCallsites(Ctx);
  Changed |= RecoverLibcArguments(Ctx);
  Changed |= RecoverVarargArguments(Ctx);
  Changed |= LowerMaterializedVAListCalls(Ctx);
  Changed |= LowerLiftedExternalABICalls(Ctx);
  Changed |= RewriteExternalCallsites(Ctx);
  Changed |= AnnotateDirectScanfDestinationNoCapture(Ctx);
  Changed |= RewriteExternalReturns(Ctx);
  Changed |= CleanupExternalCallArtifacts(Ctx);
  VerifyExternalCallRecovery(Ctx);
  PrintExternalCallRecoveryReport(Ctx);

  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_extern

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "BrightenExternCallBridgePass", "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-extern-call-bridge") {
                    MPM.addPass(
                        brighten_extern::BrightenExternCallBridgePass());
                    return true;
                  }
                  return false;
                });
          }};
}
