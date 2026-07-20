#include "NativeCleanup.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/DebugInfo.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_native_cleanup {

using namespace llvm;

namespace {

class PublishMetadataCleanupPass
    : public PassInfoMixin<PublishMetadataCleanupPass> {
public:
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    bool DebugRemoved = StripDebugInfo(M);
    bool Changed = DebugRemoved;
    unsigned NamedRemoved = 0;
    unsigned AttachmentsRemoved = 0;

    // These nodes are pipeline diagnostics/control markers.  Their durable
    // forms are the JSON proof ledger and native-contract report emitted by
    // the driver, so retaining them in the published IR only bloats the
    // artifact and LLM context.  Run this pass only after the final audit.
    SmallVector<NamedMDNode *, 8> DeadNamedMetadata;
    for (StringRef Name : {
             StringRef("llvm.ident"),
             StringRef("ollvm.deobf.profile"),
             StringRef("ollvm.deobf.inventory"),
             StringRef("ollvm.deobf.proofs"),
             StringRef("brighten.globals.preserved"),
             StringRef("brighten.late.stack.lowered"),
         })
      if (NamedMDNode *NMD = M.getNamedMetadata(Name))
        DeadNamedMetadata.push_back(NMD);
    for (NamedMDNode *NMD : DeadNamedMetadata) {
      NMD->eraseFromParent();
      Changed = true;
      ++NamedRemoved;
    }

    LLVMContext &Ctx = M.getContext();
    SmallVector<unsigned, 8> TransientKinds;
    for (StringRef Name : {
             StringRef("brighten.stack.ensured"),
             StringRef("brighten.return_candidate"),
             StringRef("brighten.return_rax.info"),
             StringRef("ollvm.deobf.dynamic_entry_dispatch"),
         })
      TransientKinds.push_back(Ctx.getMDKindID(Name));

    auto StripTransient = [&](auto &Value) {
      for (unsigned Kind : TransientKinds)
        if (Value.getMetadata(Kind)) {
          Value.setMetadata(Kind, nullptr);
          Changed = true;
          ++AttachmentsRemoved;
        }
    };
    for (GlobalVariable &GV : M.globals())
      StripTransient(GV);
    for (Function &F : M) {
      StripTransient(F);
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          StripTransient(I);
    }

    errs() << "brighten-publish-metadata-cleanup: debug="
           << (DebugRemoved ? "removed" : "absent")
           << ", named=" << NamedRemoved
           << ", attachments=" << AttachmentsRemoved << "\n";

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace

PreservedAnalyses NativeCleanupPass::run(Module &M, ModuleAnalysisManager &) {
  bool Changed = cleanupModule(M, EnforceStrict, PostSouper);
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_native_cleanup

extern "C" LLVM_ATTRIBUTE_WEAK llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenNativeCleanupPass",
          "0.1.0",
          [](llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](llvm::StringRef Name, llvm::ModulePassManager &MPM,
                   llvm::ArrayRef<llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-native-cleanup-pass") {
                    MPM.addPass(
                        brighten_native_cleanup::NativeCleanupPass(false));
                    return true;
                  }
                  if (Name == "brighten-native-cleanup-final-pass") {
                    MPM.addPass(
                        brighten_native_cleanup::NativeCleanupPass(true));
                    return true;
                  }
                  if (Name == "brighten-native-cleanup-post-souper-pass") {
                    MPM.addPass(brighten_native_cleanup::NativeCleanupPass(
                        true, true));
                    return true;
                  }
                  if (Name == "brighten-publish-metadata-cleanup-pass") {
                    MPM.addPass(
                        brighten_native_cleanup::PublishMetadataCleanupPass());
                    return true;
                  }
                  return false;
                });
          }};
}
