#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_type {

using namespace llvm;

static cl::opt<TypeMode> TypeModeOpt(
    "brighten-type-mode", cl::init(TypeMode::Conservative),
    cl::desc("Type reconstruction mode:"),
    cl::values(clEnumValN(TypeMode::Conservative, "conservative", "Conservative mode"),
               clEnumValN(TypeMode::Balanced, "balanced", "Balanced mode"),
               clEnumValN(TypeMode::Aggressive, "aggressive", "Aggressive mode")));

static cl::opt<unsigned> MinConfidenceOpt(
    "brighten-type-min-confidence", cl::init(80),
    cl::desc("Minimum confidence to rewrite"));

static cl::opt<unsigned> MaxDepthOpt(
    "brighten-type-max-depth", cl::init(16),
    cl::desc("Maximum search depth for pointer tracing"));

static cl::opt<unsigned> MinArrayElementsOpt(
    "brighten-type-min-array-elements", cl::init(2),
    cl::desc("Minimum elements to infer an array"));

static cl::opt<std::string> ReportPathOpt(
    "brighten-type-report", cl::init(""),
    cl::desc("Path to write type reconstruction report"));

static cl::opt<bool> VerifyOpt(
    "brighten-type-verify", cl::init(true),
    cl::desc("Run verifier after transformation"));

static cl::opt<bool> DumpRejectionsOpt(
    "brighten-type-dump-rejections", cl::init(false),
    cl::desc("Dump details of rejected candidates"));

extern bool DiscoverCandidates(TypeReconstructionContext &Ctx);
extern void AnalyzePointerOffsets(TypeReconstructionContext &Ctx);
extern bool PlanAndRewrite(TypeReconstructionContext &Ctx, bool OnlyStruct, bool OnlyArray);
extern bool VerifyReconstruction(TypeReconstructionContext &Ctx);

bool RunTypeReconstruction(Module &M, TypeMode Mode, bool OnlyStruct, bool OnlyArray) {
  TypeReconstructionContext Ctx(M);
  Ctx.Mode = Mode;
  Ctx.MinConfidence = MinConfidenceOpt;
  Ctx.MaxDepth = MaxDepthOpt;
  Ctx.MinArrayElements = MinArrayElementsOpt;
  Ctx.ReportPath = ReportPathOpt;
  Ctx.Verify = VerifyOpt;
  Ctx.DumpRejections = DumpRejectionsOpt;

  bool Changed = false;
  
  if (DiscoverCandidates(Ctx)) {
    AnalyzePointerOffsets(Ctx);
    if (CollectAccessEvidence(Ctx) && SolveTypeConstraints(Ctx))
      Changed |= PlanAndRewrite(Ctx, OnlyStruct, OnlyArray);
    VerifyReconstruction(Ctx);
  }

  // Print statistics or dump JSON report if requested
  if (!Ctx.ReportPath.empty()) {
    std::error_code EC;
    raw_fd_ostream OS(Ctx.ReportPath, EC, sys::fs::OF_Text);
    if (!EC) {
      OS << "{\n";
      OS << "  \"objects_analyzed\": " << Ctx.Report.ObjectsAnalyzed << ",\n";
      OS << "  \"objects_reconstructed\": " << Ctx.Report.ObjectsReconstructed << ",\n";
      OS << "  \"structs_reconstructed\": " << Ctx.Report.StructsReconstructed << ",\n";
      OS << "  \"arrays_recovered\": " << Ctx.Report.ArraysRecovered << ",\n";
      OS << "  \"globals_retyped\": " << Ctx.Report.GlobalsRetyped << ",\n";
      OS << "  \"allocas_retyped\": " << Ctx.Report.AllocasRetyped << ",\n";
      OS << "  \"geps_rewritten\": " << Ctx.Report.GEPsRewritten << ",\n";
      OS << "  \"objects_rejected_overlap\": " << Ctx.Report.ObjectsRejectedOverlap << ",\n";
      OS << "  \"objects_rejected_conflict\": " << Ctx.Report.ObjectsRejectedConflict << ",\n";
      OS << "  \"objects_rejected_escape\": " << Ctx.Report.ObjectsRejectedEscape << ",\n";
      OS << "  \"objects_rejected_unknown_offset\": " << Ctx.Report.ObjectsRejectedUnknownOffset << ",\n";
      OS << "  \"objects_rejected_non_affine\": " << Ctx.Report.ObjectsRejectedNonAffine << ",\n";
      OS << "  \"objects_rejected_out_of_bounds\": " << Ctx.Report.ObjectsRejectedOutOfBounds << ",\n";
      OS << "  \"objects_rejected_initializer\": " << Ctx.Report.ObjectsRejectedInitializer << ",\n";
      OS << "  \"verification_failures\": " << Ctx.Report.VerificationFailures << "\n";
      OS << "}\n";
    }
  }

  return Changed;
}

PreservedAnalyses BrightenTypeReconstructionPass::run(Module &M,
                                                      ModuleAnalysisManager &AM) {
  bool Changed = RecoverNativePointerIntegerRoundTrips(M, AM);
  Changed |= RunTypeReconstruction(M, TypeModeOpt, false, false);
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

PreservedAnalyses BrightenStructRecoverPass::run(Module &M,
                                                 ModuleAnalysisManager &AM) {
  bool Changed = RecoverNativePointerIntegerRoundTrips(M, AM);
  Changed |= RunTypeReconstruction(M, TypeModeOpt, true, false);
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

PreservedAnalyses BrightenArrayRecoverPass::run(Module &M,
                                                ModuleAnalysisManager &AM) {
  bool Changed = RecoverNativePointerIntegerRoundTrips(M, AM);
  Changed |= RunTypeReconstruction(M, TypeModeOpt, false, true);
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

PreservedAnalyses
BrightenAddressCanonicalizePass::run(Module &M,
                                     ModuleAnalysisManager &AM) {
  return CanonicalizeAddresses(M, AM)
             ? PreservedAnalyses::none()
             : PreservedAnalyses::all();
}

PreservedAnalyses
BrightenHeapProvenResolverCollapsePass::run(Module &M,
                                             ModuleAnalysisManager &AM) {
  return CollapseHeapProvenPointerResolvers(M, AM)
             ? PreservedAnalyses::none()
             : PreservedAnalyses::all();
}

} // namespace brighten_type

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION, "BrightenTypeReconstructionPass", "0.1.0",
          [](::llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](::llvm::StringRef Name, ::llvm::ModulePassManager &MPM,
                   ::llvm::ArrayRef<::llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-type-reconstruct") {
                    MPM.addPass(brighten_type::BrightenTypeReconstructionPass());
                    return true;
                  }
                  if (Name == "brighten-struct-recover") {
                    MPM.addPass(brighten_type::BrightenStructRecoverPass());
                    return true;
                  }
                  if (Name == "brighten-array-recover") {
                    MPM.addPass(brighten_type::BrightenArrayRecoverPass());
                    return true;
                  }
                  if (Name == "brighten-address-canonicalize") {
                    MPM.addPass(
                        brighten_type::BrightenAddressCanonicalizePass());
                    return true;
                  }
                  if (Name == "brighten-heap-proven-resolver-collapse") {
                    MPM.addPass(
                        brighten_type::BrightenHeapProvenResolverCollapsePass());
                    return true;
                  }
                  return false;
                });
          }};
}
