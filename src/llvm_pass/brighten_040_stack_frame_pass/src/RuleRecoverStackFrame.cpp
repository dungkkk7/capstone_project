#include "BrightenStackFramePass.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/DataLayout.h"
#include <algorithm>

namespace brighten_stack_frame {

using namespace llvm;

static int64_t resolveStateOffset(Value *ptr, const DataLayout &DL) {
  int64_t total_offset = 0;
  Value *base = ptr;

  while (true) {
    if (auto *GEP = dyn_cast<GEPOperator>(base)) {
      APInt ap_offset(64, 0);
      if (GEP->accumulateConstantOffset(DL, ap_offset)) {
        total_offset += ap_offset.getSExtValue();
        base = GEP->getPointerOperand();
        continue;
      }
      return -1;
    }
    if (auto *BC = dyn_cast<BitCastOperator>(base)) {
      base = BC->getOperand(0);
      continue;
    }
    if (auto *GA = dyn_cast<GlobalAlias>(base)) {
      base = GA->getAliasee();
      continue;
    }
    break;
  }

  base = base->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalVariable>(base)) {
    if (GV->getName() == "__mcsema_reg_state") {
      return total_offset;
    }
  }
  if (auto *Arg = dyn_cast<Argument>(base)) {
    if (Arg->getArgNo() == 0 && Arg->getParent()->getName() != "main") {
      return total_offset;
    }
  }
  return -1;
}

static bool traceToBase(Value *addr, Value *base_val, int64_t &offset, unsigned depth = 0) {
  if (depth > 8) return false;
  if (addr == base_val) {
    offset = 0;
    return true;
  }
  if (auto *binop = dyn_cast<BinaryOperator>(addr)) {
    auto opcode = binop->getOpcode();
    if (opcode == Instruction::Add) {
      if (auto *CI = dyn_cast<ConstantInt>(binop->getOperand(1))) {
        int64_t sub_off = 0;
        if (traceToBase(binop->getOperand(0), base_val, sub_off, depth + 1)) {
          offset = sub_off + CI->getSExtValue();
          return true;
        }
      }
      if (auto *CI = dyn_cast<ConstantInt>(binop->getOperand(0))) {
        int64_t sub_off = 0;
        if (traceToBase(binop->getOperand(1), base_val, sub_off, depth + 1)) {
          offset = CI->getSExtValue() + sub_off;
          return true;
        }
      }
    }
    if (opcode == Instruction::Sub) {
      if (auto *CI = dyn_cast<ConstantInt>(binop->getOperand(1))) {
        int64_t sub_off = 0;
        if (traceToBase(binop->getOperand(0), base_val, sub_off, depth + 1)) {
          offset = sub_off - CI->getSExtValue();
          return true;
        }
      }
    }
  }
  return false;
}

struct FrameRegion {
  int64_t min_offset;
  int64_t max_offset;
};

static SmallVector<FrameRegion, 4> clusterOffsets(SmallVectorImpl<int64_t> &offsets, int64_t gap = 16) {
  SmallVector<FrameRegion, 4> regions;
  if (offsets.empty()) return regions;

  std::sort(offsets.begin(), offsets.end());
  offsets.erase(std::unique(offsets.begin(), offsets.end()), offsets.end());

  int64_t cur_min = offsets[0];
  int64_t cur_max = offsets[0];

  for (size_t i = 1; i < offsets.size(); ++i) {
    if (offsets[i] - cur_max > gap) {
      regions.push_back({cur_min, cur_max});
      cur_min = offsets[i];
    }
    cur_max = offsets[i];
  }
  regions.push_back({cur_min, cur_max});
  return regions;
}

bool BrightenStackFramePass::RecoverStackFrame(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();

  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    if (F.getName() == "main") continue;

    SmallVector<Value *, 16> BaseValues;

    // Find all stack base values (loads from offset 2312 RSP and 2328 RBP)
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          if (LI->getType()->isIntegerTy(64)) {
            int64_t state_off = resolveStateOffset(LI->getPointerOperand(), DL);
            if (state_off == 2312 || state_off == 2328) {
              BaseValues.push_back(LI);
            }
          }
        }
      }
    }

    if (BaseValues.empty()) continue;

    IRBuilder<> EntryBuilder(&F.getEntryBlock().front());
    Type *Int8Ty = EntryBuilder.getInt8Ty();
    Type *Int64Ty = EntryBuilder.getInt64Ty();

    DenseSet<Instruction *> Erased;

    for (Value *Base : BaseValues) {
      // Collect constant inttoptr offsets from this base
      SmallVector<int64_t, 16> Offsets;
      SmallVector<IntToPtrInst *, 16> IntToPtrs;

      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
            int64_t offset = 0;
            if (traceToBase(ITP->getOperand(0), Base, offset)) {
              Offsets.push_back(offset);
              IntToPtrs.push_back(ITP);
            }
          }
        }
      }

      if (Offsets.empty()) continue;

      auto Regions = clusterOffsets(Offsets, 16);

      for (auto &Region : Regions) {
        int64_t min_off = Region.min_offset;
        int64_t max_off = Region.max_offset;
        int64_t frame_size = max_off - min_off + 8;
        if (frame_size <= 0) frame_size = 8;

        Type *FrameTy = ArrayType::get(Int8Ty, frame_size);
        AllocaInst *FrameAlloca = EntryBuilder.CreateAlloca(FrameTy, nullptr, "stack_frame");

        for (IntToPtrInst *ITP : IntToPtrs) {
          if (Erased.count(ITP)) continue;

          int64_t const_off = 0;
          if (!traceToBase(ITP->getOperand(0), Base, const_off)) continue;
          if (const_off < min_off || const_off > max_off) continue;

          IRBuilder<> B(ITP);
          Value *Idx = ConstantInt::get(Int64Ty, const_off - min_off);
          Value *GEP = B.CreateGEP(Int8Ty, FrameAlloca, Idx, "frame_ptr");
          
          ITP->replaceAllUsesWith(GEP);
          ITP->eraseFromParent();
          Erased.insert(ITP);
          Changed = true;
        }
      }
    }
  }

  return Changed;
}

} // namespace brighten_stack_frame
