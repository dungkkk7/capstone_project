// Sanitize strlen tren pointer co offset am.
// - Neu pointer ra ngoai base object thi thay bang 0
#include "BrightenRepairPass.h"

#include <vector>

#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

bool BrightenRepairPass::SanitizeDangerousStrlen(Module &M) {
  // Nếu phát hiện strlen đọc từ con trỏ có constant offset âm so với base object,
  // lời gọi này gần như chắc chắn nguy hiểm/không hợp lệ -> thay bằng 0.
  const DataLayout &DL = M.getDataLayout();
  bool Changed = false;
  std::vector<CallInst *> Worklist;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm() || CI->arg_size() != 1) {
          continue;
        }
        auto *Callee = CI->getCalledFunction();
        if (!Callee || Callee->getName() != "strlen") {
          continue;
        }
        // Gom worklist trước để có thể erase an toàn.
        Worklist.push_back(CI);
      }
    }
  }

  for (CallInst *CI : Worklist) {
    APInt ByteOffset(DL.getPointerSizeInBits(0), 0, true);
    Value *Base = CI->getArgOperand(0)->stripAndAccumulateConstantOffsets(DL, ByteOffset, true);
    if (!ByteOffset.isNegative()) {
      continue;
    }
    if (!isa<AllocaInst>(Base) && !isa<GlobalValue>(Base) && !isa<CallBase>(Base)) {
      continue;
    }
    if (!CI->getType()->isIntegerTy()) {
      continue;
    }

    // Sanitization bảo thủ: trả 0 thay vì tiếp tục đọc chuỗi ngoài vùng hợp lệ.
    Value *Zero = ConstantInt::get(CI->getType(), 0);
    CI->replaceAllUsesWith(Zero);
    CI->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair

