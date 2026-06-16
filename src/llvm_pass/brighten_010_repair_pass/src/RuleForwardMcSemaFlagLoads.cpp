// Forward McSema flag loads inside one basic block.
// - store i8 %v, @ZF_; load i8, @ZF_  ==>  %v
// - Only when no call/unknown store can clobber state in between.
#include "BrightenRepairPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static GlobalValue *GetGlobalStorage(Value *Ptr) {
  Ptr = Ptr->stripPointerCasts();
  return dyn_cast<GlobalValue>(Ptr);
}

static bool IsFlagStorage(const GlobalValue *GV) {
  if (!GV) {
    return false;
  }
  StringRef Name = GV->getName();
  return Name.starts_with("CF_") || Name.starts_with("PF_") ||
         Name.starts_with("AF_") || Name.starts_with("ZF_") ||
         Name.starts_with("SF_") || Name.starts_with("OF_");
}

static bool IsHardMemoryBarrier(const Instruction &I) {
  return isa<CallBase>(I) || isa<AtomicRMWInst>(I) ||
         isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I);
}

static StoreInst *FindReachingStore(LoadInst &LI, GlobalValue *Storage) {
  for (Instruction *I = LI.getPrevNode(); I; I = I->getPrevNode()) {
    if (IsHardMemoryBarrier(*I)) {
      return nullptr;
    }

    auto *SI = dyn_cast<StoreInst>(I);
    if (!SI) {
      continue;
    }
    if (SI->isVolatile() || SI->isAtomic()) {
      return nullptr;
    }

    GlobalValue *Other = GetGlobalStorage(SI->getPointerOperand());
    if (!Other) {
      return nullptr;
    }
    if (Other != Storage) {
      continue;
    }
    if (SI->getValueOperand()->getType() != LI.getType()) {
      return nullptr;
    }
    return SI;
  }
  return nullptr;
}

}  // namespace

bool BrightenRepairPass::ForwardMcSemaFlagLoads(Module &M) {
  bool Changed = false;
  SmallVector<LoadInst *, 32> LoadsToErase;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *LI = dyn_cast<LoadInst>(&I);
        if (!LI || LI->isVolatile() || LI->isAtomic()) {
          continue;
        }

        GlobalValue *Storage = GetGlobalStorage(LI->getPointerOperand());
        if (!IsFlagStorage(Storage)) {
          continue;
        }

        StoreInst *SI = FindReachingStore(*LI, Storage);
        if (!SI) {
          continue;
        }

        LI->replaceAllUsesWith(SI->getValueOperand());
        LoadsToErase.push_back(LI);
        Changed = true;
      }
    }
  }

  for (LoadInst *LI : LoadsToErase) {
    LI->eraseFromParent();
  }
  return Changed;
}

}  // namespace brighten_repair

