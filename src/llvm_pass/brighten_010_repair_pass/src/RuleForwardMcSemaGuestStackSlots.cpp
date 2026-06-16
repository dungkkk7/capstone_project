// Forward exact guest-stack slot load after a same-block store.
// Covers the common McSema pattern:
//   %sp = load @RSP_
//   %slot_i = add %sp, C
//   %slot = inttoptr %slot_i to ptr
//   store T %x, ptr %slot
//   %y = load T, ptr %slot       ==> %x
#include "BrightenRepairPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Instructions.h"

#include <cstdint>
#include <optional>

namespace brighten_repair {

using namespace llvm;

namespace {

struct StackKey {
  Value *Base = nullptr;
  int64_t Offset = 0;
};

struct StackAccess {
  StackKey Key;
  uint64_t Size = 0;
};

static GlobalValue *GetGlobalStorage(Value *Ptr) {
  Ptr = Ptr->stripPointerCasts();
  return dyn_cast<GlobalValue>(Ptr);
}

static bool IsRSPStorage(Value *Ptr) {
  auto *GV = GetGlobalStorage(Ptr);
  return GV && (GV->getName().starts_with("RSP_") ||
                GV->getName().starts_with("RBP_"));
}

static bool IsMcSemaStateStorage(Value *Ptr) {
  auto *GV = GetGlobalStorage(Ptr);
  if (!GV) {
    return false;
  }
  StringRef Name = GV->getName();
  return Name.starts_with("RAX_") || Name.starts_with("RBX_") ||
         Name.starts_with("RCX_") || Name.starts_with("RDX_") ||
         Name.starts_with("RSI_") || Name.starts_with("RDI_") ||
         Name.starts_with("RBP_") || Name.starts_with("RSP_") ||
         Name.starts_with("R8_") || Name.starts_with("R9_") ||
         Name.starts_with("R10_") || Name.starts_with("R11_") ||
         Name.starts_with("R12_") || Name.starts_with("R13_") ||
         Name.starts_with("R14_") || Name.starts_with("R15_") ||
         Name.starts_with("RIP_") || Name.starts_with("CF_") ||
         Name.starts_with("PF_") || Name.starts_with("AF_") ||
         Name.starts_with("ZF_") || Name.starts_with("SF_") ||
         Name.starts_with("OF_");
}

static bool AddOffset(int64_t A, int64_t B, int64_t &Out) {
  return !__builtin_add_overflow(A, B, &Out);
}

static bool SubOffset(int64_t A, int64_t B, int64_t &Out) {
  return !__builtin_sub_overflow(A, B, &Out);
}

static std::optional<StackKey> NormalizeStackIntAddress(Value *V,
                                                        int64_t Offset = 0,
                                                        unsigned Depth = 0) {
  if (Depth > 4) {
    return std::nullopt;
  }
  V = V->stripPointerCasts();

  if (auto *LI = dyn_cast<LoadInst>(V)) {
    if (!LI->isVolatile() && !LI->isAtomic()) {
      if (auto *GV = GetGlobalStorage(LI->getPointerOperand())) {
        if (IsRSPStorage(GV)) {
          return StackKey{GV, Offset};
        }
      }
    }
    return std::nullopt;
  }

  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO) {
    return std::nullopt;
  }
  if (BO->getOpcode() != Instruction::Add &&
      BO->getOpcode() != Instruction::Sub) {
    return std::nullopt;
  }

  auto *LConst = dyn_cast<ConstantInt>(BO->getOperand(0));
  auto *RConst = dyn_cast<ConstantInt>(BO->getOperand(1));
  if (BO->getOpcode() == Instruction::Add) {
    if (LConst && LConst->getBitWidth() <= 64) {
      int64_t NewOffset = 0;
      if (!AddOffset(Offset, LConst->getSExtValue(), NewOffset)) {
        return std::nullopt;
      }
      return NormalizeStackIntAddress(BO->getOperand(1), NewOffset,
                                      Depth + 1);
    }
    if (RConst && RConst->getBitWidth() <= 64) {
      int64_t NewOffset = 0;
      if (!AddOffset(Offset, RConst->getSExtValue(), NewOffset)) {
        return std::nullopt;
      }
      return NormalizeStackIntAddress(BO->getOperand(0), NewOffset,
                                      Depth + 1);
    }
    return std::nullopt;
  }

  if (RConst && RConst->getBitWidth() <= 64) {
    int64_t NewOffset = 0;
    if (!SubOffset(Offset, RConst->getSExtValue(), NewOffset)) {
      return std::nullopt;
    }
    return NormalizeStackIntAddress(BO->getOperand(0), NewOffset, Depth + 1);
  }
  return std::nullopt;
}

static std::optional<uint64_t> FixedStoreSize(Type *Ty,
                                              const DataLayout &DL) {
  TypeSize Size = DL.getTypeStoreSize(Ty);
  if (Size.isScalable()) {
    return std::nullopt;
  }
  return Size.getFixedValue();
}

static std::optional<StackAccess> NormalizeGuestStackAccess(Value *Ptr,
                                                            Type *ValueTy,
                                                            const DataLayout &DL) {
  auto Size = FixedStoreSize(ValueTy, DL);
  if (!Size || *Size == 0) {
    return std::nullopt;
  }

  Ptr = Ptr->stripPointerCasts();
  if (auto *I2P = dyn_cast<IntToPtrInst>(Ptr)) {
    if (auto Key = NormalizeStackIntAddress(I2P->getOperand(0))) {
      return StackAccess{*Key, *Size};
    }
    return std::nullopt;
  }
  if (auto *CE = dyn_cast<ConstantExpr>(Ptr)) {
    if (CE->getOpcode() == Instruction::IntToPtr) {
      if (auto Key = NormalizeStackIntAddress(CE->getOperand(0))) {
        return StackAccess{*Key, *Size};
      }
    }
  }
  return std::nullopt;
}

static bool IsHardMemoryBarrier(const Instruction &I) {
  return isa<CallBase>(I) || isa<AtomicRMWInst>(I) ||
         isa<AtomicCmpXchgInst>(I) || isa<FenceInst>(I);
}

static bool SameSlot(const StackAccess &A, const StackAccess &B) {
  return A.Key.Base == B.Key.Base && A.Key.Offset == B.Key.Offset &&
         A.Size == B.Size;
}

static bool MayOverlap(const StackAccess &A, const StackAccess &B) {
  if (A.Key.Base != B.Key.Base) {
    return false;
  }
  int64_t AEnd = 0;
  int64_t BEnd = 0;
  if (!AddOffset(A.Key.Offset, static_cast<int64_t>(A.Size), AEnd) ||
      !AddOffset(B.Key.Offset, static_cast<int64_t>(B.Size), BEnd)) {
    return true;
  }
  return A.Key.Offset < BEnd && B.Key.Offset < AEnd;
}

static StoreInst *FindReachingStackStore(LoadInst &LI, Value *SlotPtr,
                                         const StackAccess &LoadAccess,
                                         const DataLayout &DL) {
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

    Value *StorePtr = SI->getPointerOperand()->stripPointerCasts();
    if (GetGlobalStorage(StorePtr) == LoadAccess.Key.Base) {
      return nullptr;
    }

    if (StorePtr == SlotPtr) {
      if (SI->getValueOperand()->getType() != LI.getType()) {
        return nullptr;
      }
      return SI;
    }

    // Stores to globals or McSema state aliases cannot alias a concrete guest
    // stack slot materialized through inttoptr.
    if (GetGlobalStorage(StorePtr)) {
      continue;
    }
    if (IsMcSemaStateStorage(StorePtr)) {
      continue;
    }

    auto StoreAccess =
        NormalizeGuestStackAccess(StorePtr, SI->getValueOperand()->getType(), DL);
    if (StoreAccess) {
      if (!MayOverlap(LoadAccess, *StoreAccess)) {
        continue;
      }
      if (SameSlot(LoadAccess, *StoreAccess) &&
          SI->getValueOperand()->getType() == LI.getType()) {
        return SI;
      }
      return nullptr;
    }

    return nullptr;
  }
  return nullptr;
}

}  // namespace

bool BrightenRepairPass::ForwardMcSemaGuestStackSlots(Module &M) {
  bool Changed = false;
  SmallVector<LoadInst *, 32> LoadsToErase;
  const DataLayout &DL = M.getDataLayout();

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *LI = dyn_cast<LoadInst>(&I);
        if (!LI || LI->isVolatile() || LI->isAtomic()) {
          continue;
        }

        Value *SlotPtr = LI->getPointerOperand()->stripPointerCasts();
        auto LoadAccess = NormalizeGuestStackAccess(SlotPtr, LI->getType(), DL);
        if (!LoadAccess) {
          continue;
        }

        StoreInst *SI = FindReachingStackStore(*LI, SlotPtr, *LoadAccess, DL);
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
