// Prune McSema flag/RIP stores that are unobservable inside the lifted module.
//
// McSema often materializes CPU flags and RIP into thread-local aliases even
// when no lifted code ever reads them. Those stores make the recompiled binary
// look like a CPU-state emulator in decompilers. This rule removes only exact
// stores to private flag/RIP aliases when the alias has no loads and does not
// escape through calls, returns, PHIs, or unknown users.
#include "BrightenRepairPass.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Transforms/Utils/Local.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static GlobalValue *GetGlobalStorage(Value *Ptr) {
  Ptr = Ptr->stripPointerCasts();
  return dyn_cast<GlobalValue>(Ptr);
}

static bool IsUnusedStoreCandidate(const GlobalValue *GV) {
  if (!GV) {
    return false;
  }
  StringRef Name = GV->getName();
  return Name.starts_with("RIP_") || Name.starts_with("CF_") ||
         Name.starts_with("PF_") || Name.starts_with("AF_") ||
         Name.starts_with("ZF_") || Name.starts_with("SF_") ||
         Name.starts_with("OF_");
}

static bool IsPointerTransform(const User *U) {
  if (isa<BitCastInst>(U) || isa<AddrSpaceCastInst>(U) ||
      isa<GetElementPtrInst>(U)) {
    return true;
  }
  if (const auto *CE = dyn_cast<ConstantExpr>(U)) {
    return CE->isCast() || CE->getOpcode() == Instruction::GetElementPtr;
  }
  return false;
}

static void AnalyzePointerUses(Value *V, GlobalValue *Root,
                               SmallPtrSetImpl<Value *> &Seen, bool &HasRead,
                               bool &Escaped) {
  if (HasRead || Escaped || !Seen.insert(V).second) {
    return;
  }

  for (User *U : V->users()) {
    if (auto *SI = dyn_cast<StoreInst>(U)) {
      if (GetGlobalStorage(SI->getPointerOperand()) == Root) {
        if (SI->isVolatile() || SI->isAtomic()) {
          Escaped = true;
        }
        continue;
      }
      // The alias is being stored as a value, so later code may observe it.
      Escaped = true;
      return;
    }

    if (auto *LI = dyn_cast<LoadInst>(U)) {
      if (GetGlobalStorage(LI->getPointerOperand()) == Root) {
        HasRead = true;
      } else {
        Escaped = true;
      }
      return;
    }

    if (isa<AtomicRMWInst>(U) || isa<AtomicCmpXchgInst>(U)) {
      HasRead = true;
      return;
    }

    if (IsPointerTransform(U)) {
      AnalyzePointerUses(cast<Value>(U), Root, Seen, HasRead, Escaped);
      if (HasRead || Escaped) {
        return;
      }
      continue;
    }

    // Calls, returns, PHIs, selects, integer casts, comparisons, and any other
    // use are treated as escapes. That keeps this a cleanup rule, not an alias
    // analysis replacement.
    Escaped = true;
    return;
  }
}

static bool HasOnlyNonVolatileStores(GlobalValue *GV) {
  bool HasRead = false;
  bool Escaped = false;
  SmallPtrSet<Value *, 16> Seen;
  AnalyzePointerUses(GV, GV, Seen, HasRead, Escaped);
  return !HasRead && !Escaped;
}

static void CleanupDeadProducers(ArrayRef<WeakTrackingVH> Roots) {
  for (const WeakTrackingVH &VH : Roots) {
    Value *V = VH;
    auto *I = dyn_cast_or_null<Instruction>(V);
    if (!I || !I->getParent()) {
      continue;
    }
    RecursivelyDeleteTriviallyDeadInstructions(I);
  }
}

}  // namespace

bool BrightenRepairPass::PruneUnusedMcSemaStateStores(Module &M) {
  SmallPtrSet<GlobalValue *, 32> Prunable;

  for (GlobalAlias &GA : M.aliases()) {
    if (!IsUnusedStoreCandidate(&GA)) {
      continue;
    }
    if (!HasOnlyNonVolatileStores(&GA)) {
      continue;
    }
    Prunable.insert(&GA);
  }

  for (GlobalVariable &GV : M.globals()) {
    if (!IsUnusedStoreCandidate(&GV)) {
      continue;
    }
    if (!GV.hasLocalLinkage()) {
      continue;
    }
    if (!HasOnlyNonVolatileStores(&GV)) {
      continue;
    }
    Prunable.insert(&GV);
  }

  if (Prunable.empty()) {
    return false;
  }

  bool Changed = false;
  SmallVector<StoreInst *, 64> StoresToErase;
  SmallVector<WeakTrackingVH, 128> MaybeDead;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<StoreInst>(&I);
        if (!SI || SI->isVolatile() || SI->isAtomic()) {
          continue;
        }

        GlobalValue *Storage = GetGlobalStorage(SI->getPointerOperand());
        if (!Storage || !Prunable.contains(Storage)) {
          continue;
        }

        MaybeDead.push_back(WeakTrackingVH(SI->getValueOperand()));
        MaybeDead.push_back(WeakTrackingVH(SI->getPointerOperand()));
        StoresToErase.push_back(SI);
      }
    }
  }

  for (StoreInst *SI : StoresToErase) {
    SI->eraseFromParent();
    Changed = true;
  }

  CleanupDeadProducers(MaybeDead);

  SmallVector<GlobalAlias *, 32> AliasesToErase;
  for (GlobalValue *GV : Prunable) {
    auto *GA = dyn_cast<GlobalAlias>(GV);
    if (GA && GA->hasLocalLinkage() && GA->use_empty()) {
      AliasesToErase.push_back(GA);
    }
  }
  for (GlobalAlias *GA : AliasesToErase) {
    GA->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair
