// Prune McSema flag stores killed before any read in the same block.
// Conservative: do not cross calls, unknown stores, atomics, or block edges.
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

static bool IsKilledBeforeRead(StoreInst &SI, GlobalValue *Storage) {
  for (Instruction *I = SI.getNextNode(); I; I = I->getNextNode()) {
    if (IsHardMemoryBarrier(*I)) {
      return false;
    }

    if (auto *LI = dyn_cast<LoadInst>(I)) {
      if ((LI->isVolatile() || LI->isAtomic()) &&
          GetGlobalStorage(LI->getPointerOperand()) == Storage) {
        return false;
      }
      if (GetGlobalStorage(LI->getPointerOperand()) == Storage) {
        return false;
      }
      continue;
    }

    auto *NextSI = dyn_cast<StoreInst>(I);
    if (!NextSI) {
      continue;
    }
    if (NextSI->isVolatile() || NextSI->isAtomic()) {
      return false;
    }

    GlobalValue *Other = GetGlobalStorage(NextSI->getPointerOperand());
    if (!Other) {
      return false;
    }
    if (Other == Storage) {
      return true;
    }
  }
  return false;
}

}  // namespace

bool BrightenRepairPass::PruneDeadMcSemaFlagStores(Module &M) {
  bool Changed = false;
  SmallVector<StoreInst *, 32> StoresToErase;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<StoreInst>(&I);
        if (!SI || SI->isVolatile() || SI->isAtomic()) {
          continue;
        }

        GlobalValue *Storage = GetGlobalStorage(SI->getPointerOperand());
        if (!IsFlagStorage(Storage)) {
          continue;
        }
        if (!IsKilledBeforeRead(*SI, Storage)) {
          continue;
        }

        StoresToErase.push_back(SI);
        Changed = true;
      }
    }
  }

  for (StoreInst *SI : StoresToErase) {
    SI->eraseFromParent();
  }
  return Changed;
}

}  // namespace brighten_repair

