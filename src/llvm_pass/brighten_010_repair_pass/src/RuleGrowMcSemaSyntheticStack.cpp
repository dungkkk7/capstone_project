// Mo rong __mcsema_stack neu qua nho.
// - Tao global stack lon toi thieu
// - Patch store set top stack
#include "BrightenRepairPass.h"

#include <cstdint>
#include <vector>

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static constexpr uint64_t kMinMcSemaStackBytes = 16ull * 1024ull * 1024ull;
static constexpr uint64_t kStackTopRedZoneBytes = 512;

static bool ConstantMentionsValue(const Constant *C, const Value *Needle,
                                  SmallPtrSetImpl<const Constant *> &Visited) {
  if (C == Needle) {
    return true;
  }
  if (!Visited.insert(C).second) {
    return false;
  }
  for (const Use &U : C->operands()) {
    auto *Nested = dyn_cast<Constant>(U.get());
    if (Nested && ConstantMentionsValue(Nested, Needle, Visited)) {
      return true;
    }
  }
  return false;
}

static GlobalVariable *GetOrCreateLargeStack(Module &M, uint64_t SizeBytes,
                                             MaybeAlign Align) {
  if (auto *Existing = M.getGlobalVariable("__lifter_refine_mcsema_stack")) {
    return Existing;
  }

  LLVMContext &Ctx = M.getContext();
  auto *StackTy = ArrayType::get(Type::getInt8Ty(Ctx), SizeBytes);
  auto *GV = new GlobalVariable(
      M, StackTy, false, GlobalValue::InternalLinkage,
      ConstantAggregateZero::get(StackTy), "__lifter_refine_mcsema_stack");
  GV->setAlignment(Align.valueOrOne());
  return GV;
}

static Value *BuildAlignedStackTop(IRBuilder<> &B, GlobalVariable *Stack,
                                   uint64_t SizeBytes) {
  Value *Top = B.CreateConstInBoundsGEP2_32(
      Stack->getValueType(), Stack, 0,
      static_cast<unsigned>(SizeBytes - kStackTopRedZoneBytes));
  Value *AsInt = B.CreatePtrToInt(Top, B.getInt64Ty());
  return B.CreateAnd(AsInt, B.getInt64(~uint64_t(15)));
}

}  // namespace

bool BrightenRepairPass::GrowMcSemaSyntheticStack(Module &M) {
  auto *OldStack = M.getNamedGlobal("__mcsema_stack");
  if (!OldStack) {
    return false;
  }

  auto *OldTy = dyn_cast<ArrayType>(OldStack->getValueType());
  if (!OldTy || !OldTy->getElementType()->isIntegerTy(8)) {
    return false;
  }

  uint64_t OldSize = OldTy->getNumElements();
  if (OldSize >= kMinMcSemaStackBytes) {
    return false;
  }

  GlobalVariable *LargeStack =
      GetOrCreateLargeStack(M, kMinMcSemaStackBytes, OldStack->getAlign());

  std::vector<StoreInst *> StoresToPatch;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<StoreInst>(&I);
        if (!SI) {
          continue;
        }
        auto *C = dyn_cast<Constant>(SI->getValueOperand());
        SmallPtrSet<const Constant *, 16> Visited;
        if (!C || !ConstantMentionsValue(C, OldStack, Visited)) {
          continue;
        }
        if (!SI->getValueOperand()->getType()->isIntegerTy(64)) {
          continue;
        }
        StoresToPatch.push_back(SI);
      }
    }
  }

  if (StoresToPatch.empty()) {
    return false;
  }

  for (StoreInst *SI : StoresToPatch) {
    IRBuilder<> B(SI);
    Value *NewTop = BuildAlignedStackTop(B, LargeStack, kMinMcSemaStackBytes);
    SI->setOperand(0, NewTop);
  }

  return true;
}

}  // namespace brighten_repair
