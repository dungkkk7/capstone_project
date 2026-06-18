// Forward same-block McSema register/state loads after exact stores.
// This is intentionally local and exact-alias only; it is a cleanup rule, not
// a full memory-to-register recovery pass.
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

static bool StartsWithAny(StringRef Name, ArrayRef<StringRef> Prefixes) {
  for (StringRef Prefix : Prefixes) {
    if (Name.starts_with(Prefix)) {
      return true;
    }
  }
  return false;
}

static bool IsMcSemaStateStorage(const GlobalValue *GV) {
  if (!GV) {
    return false;
  }
  static constexpr StringRef Prefixes[] = {
      "RBX_", "RCX_", "RDX_", "RSI_", "RDI_", "RBP_", "RSP_",
      "R8_",  "R9_",  "R10_", "R11_", "R12_", "R13_", "R14_", "R15_",
      "RIP_",
  };
  return StartsWithAny(GV->getName(), Prefixes);
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
      // Keep unknown/inttoptr memory stores as barriers. Treating guest-stack
      // stores as non-aliasing looked attractive for call-arg cleanup, but it
      // regressed optimized semantics on mix3__hash_hash_blake2b_3bd019ba104e.
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

bool BrightenRepairPass::ForwardMcSemaStateLoads(Module &M) {
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
        if (!IsMcSemaStateStorage(Storage)) {
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
