#include "BrightenRepairPass.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

static bool IsFlagName(StringRef Name) {
  return Name.starts_with("CF_") || Name.starts_with("PF_") ||
         Name.starts_with("AF_") || Name.starts_with("ZF_") ||
         Name.starts_with("SF_") || Name.starts_with("OF_");
}

static GlobalValue *GetFlagObject(Value *Ptr) {
  Ptr = Ptr->stripPointerCasts();
  auto *GV = dyn_cast<GlobalValue>(Ptr);
  if (!GV || !IsFlagName(GV->getName())) {
    return nullptr;
  }
  return GV;
}

static bool HasOnlyLocalLoadStoreUsers(Value *V, Function &F,
                                       DenseSet<User *> &Seen) {
  for (User *U : V->users()) {
    if (!Seen.insert(U).second) {
      continue;
    }

    if (auto *I = dyn_cast<Instruction>(U)) {
      if (I->getFunction() != &F) {
        return false;
      }
      if (auto *LI = dyn_cast<LoadInst>(I)) {
        if (LI->isVolatile() || GetFlagObject(LI->getPointerOperand()) != V) {
          return false;
        }
        continue;
      }
      if (auto *SI = dyn_cast<StoreInst>(I)) {
        if (SI->isVolatile() || GetFlagObject(SI->getPointerOperand()) != V) {
          return false;
        }
        continue;
      }
      return false;
    }

    if (isa<ConstantExpr>(U) || isa<GlobalAlias>(U)) {
      if (!HasOnlyLocalLoadStoreUsers(cast<Value>(U), F, Seen)) {
        return false;
      }
      continue;
    }

    return false;
  }
  return true;
}

static bool HasOnlyLocalLoadStoreUsers(GlobalValue *GV, Function &F) {
  DenseSet<User *> Seen;
  return HasOnlyLocalLoadStoreUsers(cast<Value>(GV), F, Seen);
}

static Value *AdaptStoredValue(IRBuilder<> &B, Value *V, Type *LoadTy) {
  Type *StoreTy = V->getType();
  if (StoreTy == LoadTy) {
    return V;
  }

  if (StoreTy->isIntegerTy() && LoadTy->isIntegerTy()) {
    unsigned StoreBits = StoreTy->getIntegerBitWidth();
    unsigned LoadBits = LoadTy->getIntegerBitWidth();
    if (StoreBits < LoadBits) {
      return B.CreateZExt(V, LoadTy);
    }
    if (StoreBits > LoadBits) {
      if (LoadBits == 1) {
        return B.CreateICmpNE(V, ConstantInt::get(StoreTy, 0));
      }
      return B.CreateTrunc(V, LoadTy);
    }
  }

  return nullptr;
}

static bool IsMemoryBarrier(Instruction &I) {
  if (isa<CallBase>(I) || isa<FenceInst>(I)) {
    return true;
  }
  if (auto *LI = dyn_cast<LoadInst>(&I)) {
    return LI->isVolatile() || LI->isAtomic();
  }
  if (auto *SI = dyn_cast<StoreInst>(&I)) {
    return SI->isVolatile() || SI->isAtomic();
  }
  return I.mayReadOrWriteMemory() && !isa<LoadInst>(I) && !isa<StoreInst>(I);
}

static void RecursivelyEraseDeadInstruction(Value *V) {
  if (auto *I = dyn_cast<Instruction>(V)) {
    if (I->use_empty()) {
      SmallVector<Value *, 4> Ops;
      for (Value *Op : I->operands()) {
        Ops.push_back(Op);
      }
      I->eraseFromParent();
      for (Value *Op : Ops) {
        RecursivelyEraseDeadInstruction(Op);
      }
    }
  }
}

bool BrightenRepairPass::ForwardFlagLoads(Module &M) {
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    SmallVector<LoadInst *, 32> LoadsToErase;
    DenseSet<StoreInst *> StoresToErase;
    DenseMap<GlobalValue *, SmallVector<StoreInst *, 8>> FlagStores;

    for (BasicBlock &BB : F) {
      DenseMap<GlobalValue *, StoreInst *> LastFlagStore;

      for (Instruction &I : BB) {
        if (auto *SI = dyn_cast<StoreInst>(&I)) {
          GlobalValue *Flag = GetFlagObject(SI->getPointerOperand());
          if (!Flag) {
            if (IsMemoryBarrier(I)) {
              LastFlagStore.clear();
            }
            continue;
          }

          if (auto It = LastFlagStore.find(Flag); It != LastFlagStore.end()) {
            StoresToErase.insert(It->second);
          }
          LastFlagStore[Flag] = SI;
          FlagStores[Flag].push_back(SI);
          continue;
        }

        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          GlobalValue *Flag = GetFlagObject(LI->getPointerOperand());
          if (!Flag) {
            if (IsMemoryBarrier(I)) {
              LastFlagStore.clear();
            }
            continue;
          }

          auto It = LastFlagStore.find(Flag);
          if (It == LastFlagStore.end()) {
            continue;
          }

          IRBuilder<> B(LI);
          Value *Replacement =
              AdaptStoredValue(B, It->second->getValueOperand(), LI->getType());
          if (!Replacement) {
            continue;
          }
          LI->replaceAllUsesWith(Replacement);
          LoadsToErase.push_back(LI);
          continue;
        }

        if (IsMemoryBarrier(I)) {
          LastFlagStore.clear();
        }
      }
    }

    for (LoadInst *LI : LoadsToErase) {
      LI->eraseFromParent();
      Changed = true;
    }

    DenseSet<GlobalValue *> LocallyLoweredFlags;
    for (auto &Entry : FlagStores) {
      GlobalValue *Flag = Entry.first;
      bool HasRemainingLoad = false;
      for (User *U : Flag->users()) {
        if (auto *LI = dyn_cast<LoadInst>(U)) {
          if (LI->getFunction() == &F) {
            HasRemainingLoad = true;
            break;
          }
        }
      }
      if (!HasRemainingLoad && HasOnlyLocalLoadStoreUsers(Flag, F)) {
        LocallyLoweredFlags.insert(Flag);
      }
    }

    for (auto &Entry : FlagStores) {
      if (!LocallyLoweredFlags.count(Entry.first)) {
        continue;
      }
      for (StoreInst *SI : Entry.second) {
        StoresToErase.insert(SI);
      }
    }

    for (StoreInst *SI : StoresToErase) {
      if (!SI->getParent()) {
        continue;
      }
      Value *Val = SI->getValueOperand();
      SI->eraseFromParent();
      RecursivelyEraseDeadInstruction(Val);
      Changed = true;
    }
  }

  return Changed;
}

}  // namespace brighten_repair
