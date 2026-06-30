// Hardening scanf("%s") khong co width.
// - Neu suy ra duoc buffer size thi chen width an toan
// - Chi xu ly format don gian de tranh sai semantic
#include "BrightenRepairPass.h"

#include <cstdint>
#include <optional>
#include <string>

#include "llvm/ADT/Twine.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/IRBuilder.h"

namespace brighten_repair {

using namespace llvm;

bool BrightenRepairPass::HardenUnsafeScanf(Module &M) {
  // Rule hardening cho scanf("%s", buf):
  // nếu format chưa có width và suy luận được kích thước vùng ghi,
  // ta tự chèn width an toàn "%<n-1>s".
  const DataLayout &DL = M.getDataLayout();
  bool Changed = false;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm() || CI->arg_size() < 2) {
          continue;
        }
        if (!IsScanfLikeCall(CI)) {
          continue;
        }

        StringRef Fmt;
        if (!getConstantStringInfo(CI->getArgOperand(0), Fmt, true)) {
          continue;
        }

        bool HasWidth = false;
        uint64_t ExistingWidth = 0;
        if (!ParseSimplePercentS(Fmt, HasWidth, ExistingWidth)) {
          // Chỉ xử lý format cực đơn giản để tránh rewrite sai semantic.
          continue;
        }
        if (HasWidth) {
          // Đã có width thì bỏ qua (caller đã có guard độ dài).
          continue;
        }

        auto WritableBytes = InferWritableBytesAtPointer(CI->getArgOperand(1), DL);
        if (!WritableBytes.has_value() || *WritableBytes <= 1) {
          continue;
        }

        uint64_t SafeWidth = *WritableBytes - 1;
        std::string NewFmt = (Twine("%") + Twine(SafeWidth) + "s").str();
        IRBuilder<> B(CI);
        // Tạo global string mới và thay arg format tại chỗ.
        Value *NewFmtPtr = B.CreateGlobalStringPtr(NewFmt, ".fmt.refine.scanf");
        CI->setArgOperand(0, NewFmtPtr);
        Changed = true;
      }
    }
  }

  return Changed;
}

}  // namespace brighten_repair

