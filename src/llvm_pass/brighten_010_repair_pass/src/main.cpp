// BrightenRepairPass plugin entry + pass registration.
// - Dang ky pass theo ten "brighten-repair-pass"
// - Chay danh sach rule theo thu tu on dinh
// - Tra ve PreservedAnalyses theo co thay doi
#include "BrightenRepairPass.h"

#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

namespace brighten_repair {

using namespace llvm;

PreservedAnalyses BrightenRepairPass::run(Module &M, ModuleAnalysisManager &) {
  // Chạy rule theo thứ tự cố định: từ vệ sinh metadata/flags,
  // tới sửa linkability, hardening, rồi chuẩn hoá control-flow/calls.
  bool Changed = false;

  Changed |= StripPoisonDrivingFlags(M);
  Changed |= StripPoisonDrivingAttributes(M);

  Changed |= ForwardMcSemaFlagLoads(M);
  Changed |= PruneDeadMcSemaFlagStores(M);
  Changed |= PruneDeadRipStores(M);
  Changed |= ForwardMcSemaStateLoads(M);
  Changed |= ForwardMcSemaGuestStackSlots(M);
  Changed |= PruneUnusedMcSemaStateStores(M);
  Changed |= InlineMcSemaExternalWrappers(M);

  Changed |= DefineRemillControlHelpers(M);
  Changed |= GrowMcSemaSyntheticStack(M);
  Changed |= HardenUnsafeScanf(M);
  Changed |= CanonicalizeObfuscatedCompares(M);
  Changed |= SanitizeDangerousStrlen(M);
  Changed |= RepairRemillVarArgFPCalls(M);
  Changed |= RepairRemillX87LibCalls(M);
  Changed |= RepairMcSemaX87PseudoDoubleLoads(M);
  Changed |= NormalizeJumpTableTargets(M);
  Changed |= RecoverNoReturnFallthroughTargets(M);
  Changed |= AddRemillEntryDispatchers(M);
  Changed |= SynthesizeMissingMain(M);
  Changed |= NormalizeRemillFunctionCalls(M);
  Changed |= RepairMcSemaRawIndirectCallStack(M);
  Changed |= GuardRawIndirectCalls(M);
  Changed |= PruneUnusedRemillMcSemaHelpers(M);

  // Có thay đổi IR thì invalidates tất cả; ngược lại giữ nguyên analyses.
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

}  // namespace brighten_repair

extern "C" LLVM_ATTRIBUTE_WEAK llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  // Đăng ký plugin pass để pipeline có thể gọi bằng tên "brighten-repair-pass".
  return {LLVM_PLUGIN_API_VERSION,
          "BrightenRepairPass",
          "0.1.0",
          [](llvm::PassBuilder &PB) {
            PB.registerPipelineParsingCallback(
                [](llvm::StringRef Name, llvm::ModulePassManager &MPM,
                   llvm::ArrayRef<llvm::PassBuilder::PipelineElement>) {
                  if (Name == "brighten-repair-pass") {
                    MPM.addPass(brighten_repair::BrightenRepairPass());
                    return true;
                  }
                  return false;
                });
          }};
}
