#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Operator.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseSet.h"
#include <cstdlib>
#include <algorithm>
#include <vector>

using namespace llvm;

namespace {

bool IsRspAlias(Value *val) {
  if (!val) return false;
  Value *stripped = val->stripPointerCasts();
  if (auto *alias = dyn_cast_or_null<GlobalAlias>(stripped)) {
    StringRef name = alias->getName();
    size_t idx = name.find('_');
    if (idx == StringRef::npos) {
      return false;
    }
    return name.take_front(idx) == "RSP";
  }
  return false;
}

bool traceToBase(Value *addr, Value *base_val, int64_t &offset, unsigned depth = 0) {
  if (depth > 8) return false;
  if (addr == base_val) {
    offset = 0;
    return true;
  }

  if (auto *base_phi = dyn_cast<PHINode>(base_val)) {
    for (unsigned i = 0; i < base_phi->getNumIncomingValues(); ++i) {
      auto *inc = base_phi->getIncomingValue(i);
      if (inc != base_phi && addr == inc) {
        offset = 0;
        return true;
      }
    }
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

bool isDerivedFrom(Value *V, Value *base_val, DenseSet<Value *> &visited, unsigned depth = 0) {
  if (depth > 16) return false;
  if (V == base_val) return true;

  if (auto *base_phi = dyn_cast<PHINode>(base_val)) {
    for (unsigned i = 0; i < base_phi->getNumIncomingValues(); ++i) {
      auto *inc = base_phi->getIncomingValue(i);
      if (inc != base_phi && V == inc) return true;
    }
  }

  if (!visited.insert(V).second) return false;

  if (auto *binop = dyn_cast<BinaryOperator>(V)) {
    auto opcode = binop->getOpcode();
    if (opcode == Instruction::Add ||
        opcode == Instruction::Sub ||
        opcode == Instruction::Or ||
        opcode == Instruction::And ||
        opcode == Instruction::Shl ||
        opcode == Instruction::LShr ||
        opcode == Instruction::AShr) {
      return isDerivedFrom(binop->getOperand(0), base_val, visited, depth + 1) ||
             isDerivedFrom(binop->getOperand(1), base_val, visited, depth + 1);
    }
  }

  if (auto *CI = dyn_cast<CastInst>(V)) {
    auto opcode = CI->getOpcode();
    if (opcode == Instruction::Trunc ||
        opcode == Instruction::ZExt ||
        opcode == Instruction::SExt) {
      return isDerivedFrom(CI->getOperand(0), base_val, visited, depth + 1);
    }
  }

  if (auto *phi = dyn_cast<PHINode>(V)) {
    for (unsigned i = 0; i < phi->getNumIncomingValues(); ++i) {
      if (isDerivedFrom(phi->getIncomingValue(i), base_val, visited, depth + 1))
        return true;
    }
  }

  return false;
}

bool isDerivedFrom(Value *V, Value *base_val) {
  DenseSet<Value *> visited;
  return isDerivedFrom(V, base_val, visited, 0);
}

AllocaInst *getStackAllocaAndOffset(Value *base_val, int64_t &base_offset, const DataLayout &DL) {
  if (!base_val) return nullptr;
  Value *ptr = nullptr;
  if (auto *P2I = dyn_cast<PtrToIntInst>(base_val)) {
    ptr = P2I->getPointerOperand();
  }
  if (!ptr) return nullptr;

  int64_t offset = 0;
  Value *base = ptr;
  int limit = 10;
  while (limit-- > 0) {
    if (auto *GEP = dyn_cast<GEPOperator>(base)) {
      APInt ap_offset(64, 0);
      if (GEP->accumulateConstantOffset(DL, ap_offset)) {
        offset += ap_offset.getSExtValue();
        base = GEP->getPointerOperand();
        continue;
      }
    }
    if (auto *BC = dyn_cast<BitCastOperator>(base)) {
      base = BC->getOperand(0);
      continue;
    }
    break;
  }

  if (auto *AI = dyn_cast<AllocaInst>(base)) {
    StringRef Name = AI->getName();
    if (Name.contains("stack") || Name.contains("frame")) {
      base_offset = offset;
      return AI;
    }
  }
  return nullptr;
}

SmallVector<Value *, 4> findStackBaseValues(Function &F) {
  SmallVector<Value *, 4> result;
  DenseSet<Value *> seen;
  const DataLayout &DL = F.getParent()->getDataLayout();

  for (auto &BB : F) {
    for (auto &I : BB) {
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        if (IsRspAlias(LI->getPointerOperand())) {
          if (seen.insert(LI).second) {
            result.push_back(LI);
          }

          for (auto *user : LI->users()) {
            auto *binop = dyn_cast<BinaryOperator>(user);
            if (!binop) continue;
            int64_t offset = 0;
            if (!traceToBase(binop, LI, offset) || offset >= 0) continue;

            for (auto *bu : binop->users()) {
              auto *phi = dyn_cast<PHINode>(bu);
              if (!phi) continue;
              if (seen.insert(phi).second) {
                result.push_back(phi);
              }
            }
          }
        }
      }

      if (auto *P2I = dyn_cast<PtrToIntInst>(&I)) {
        int64_t dummy_offset = 0;
        if (getStackAllocaAndOffset(P2I, dummy_offset, DL)) {
          if (seen.insert(P2I).second) {
            result.push_back(P2I);
          }
        }
      }
    }
  }
  return result;
}

SmallVector<int64_t, 16> collectIntToPtrOffsets(Function &F, Value *base) {
  SmallVector<int64_t, 16> offsets;
  for (auto &BB : F) {
    for (auto &I : BB) {
      auto *ITP = dyn_cast<IntToPtrInst>(&I);
      if (!ITP) continue;
      int64_t offset = 0;
      if (traceToBase(ITP->getOperand(0), base, offset)) {
        offsets.push_back(offset);
      }
    }
  }
  return offsets;
}

struct FrameRegion {
  int64_t min_offset;
  int64_t max_offset;
};

SmallVector<FrameRegion, 4> clusterOffsets(SmallVector<int64_t, 16> &offsets, int64_t gap = 16) {
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

SmallVector<IntToPtrInst *, 16> collectDerivedIntToPtr(Function &F, Value *base) {
  SmallVector<IntToPtrInst *, 16> result;
  for (auto &BB : F) {
    for (auto &I : BB) {
      if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
        if (isDerivedFrom(ITP->getOperand(0), base)) {
          result.push_back(ITP);
        }
      }
    }
  }
  return result;
}

struct BrightenHostFramePass : public PassInfoMixin<BrightenHostFramePass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    bool Changed = false;
    const DataLayout &DL = M.getDataLayout();
    
    for (Function &F : M) {
      if (F.isDeclaration() || F.empty()) continue;
      if (!F.getName().ends_with("_native")) continue;

      auto base_values = findStackBaseValues(F);
      if (base_values.empty()) continue;

      IRBuilder<> EntryBuilder(&F.getEntryBlock().front());
      auto *i8_ty = EntryBuilder.getInt8Ty();
      auto *i64_ty = EntryBuilder.getInt64Ty();

      for (auto *base : base_values) {
        auto offsets = collectIntToPtrOffsets(F, base);
        if (offsets.empty()) continue;

        int64_t base_offset = 0;
        AllocaInst *existing_alloca = getStackAllocaAndOffset(base, base_offset, DL);

        if (existing_alloca) {
          auto int_to_ptrs = collectDerivedIntToPtr(F, base);
          for (auto *itp : int_to_ptrs) {
            Value *operand = itp->getOperand(0);
            int64_t const_off = 0;
            if (!traceToBase(operand, base, const_off)) continue;

            IRBuilder<> Builder(itp);
            auto *alloca_idx = ConstantInt::get(i64_ty, base_offset + const_off);
            auto *gep = Builder.CreateGEP(i8_ty, existing_alloca, alloca_idx, "frame_ptr");
            itp->replaceAllUsesWith(gep);
            itp->eraseFromParent();
            Changed = true;
          }
        } else {
          auto regions = clusterOffsets(offsets, 16);
          for (auto &region : regions) {
            int64_t min_off = region.min_offset;
            int64_t max_off = region.max_offset;
            int64_t frame_size = max_off - min_off + 8;
            if (frame_size <= 0) frame_size = 8;

            auto *frame_ty = ArrayType::get(i8_ty, frame_size);
            auto *frame_alloca = EntryBuilder.CreateAlloca(frame_ty, nullptr, "stack_frame");

            auto int_to_ptrs = collectDerivedIntToPtr(F, base);
            for (auto *itp : int_to_ptrs) {
              Value *operand = itp->getOperand(0);
              int64_t const_off = 0;
              if (!traceToBase(operand, base, const_off)) continue;
              if (const_off < min_off || const_off > max_off) continue;

              IRBuilder<> Builder(itp);
              auto *alloca_idx = ConstantInt::get(i64_ty, const_off - min_off);
              auto *gep = Builder.CreateGEP(i8_ty, frame_alloca, alloca_idx, "frame_ptr");
              itp->replaceAllUsesWith(gep);
              itp->eraseFromParent();
              Changed = true;
            }
          }
        }
      }
    }
    
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
    LLVM_PLUGIN_API_VERSION,
    "BrightenHostFramePass",
    LLVM_VERSION_STRING,
    [](PassBuilder &PB) {
      PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "brighten-host-frame-pass") {
            MPM.addPass(BrightenHostFramePass());
            return true;
          }
          return false;
        }
      );
    }
  };
}
