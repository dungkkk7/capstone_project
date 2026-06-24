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

  if (auto *F = M.getFunction("main_wrapper")) {
    if (F->hasLocalLinkage()) {
      F->setLinkage(GlobalValue::ExternalLinkage);
      Changed = true;
    }
  }

  Changed |= StripPoisonDrivingFlags(M);
  Changed |= StripPoisonDrivingAttributes(M);

  Changed |= RepairObfuscatedStackSubtractions(M);

  // Quan trọng: chạy TRƯỚC khi optimizer xóa callback thunks
  Changed |= FixCallbackFunctionPointerStores(M);

  Changed |= ImplementExternCallBridge(M);
  Changed |= DefineRemillControlHelpers(M);

  Changed |= SynthesizeMissingMain(M);
  Changed |= ResolveAliases(M);
  Changed |= PreserveCalleeSavedRegisters(M);

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
