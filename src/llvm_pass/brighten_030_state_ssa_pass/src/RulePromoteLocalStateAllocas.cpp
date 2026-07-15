#include "llvm/IR/IntrinsicInst.h"
#include "BrightenStateSSAPass.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"

#include <limits>
#include <optional>

namespace brighten_state_ssa {

using namespace llvm;

namespace {

struct Access {
  Instruction *Inst = nullptr;
  uint64_t Offset = 0;
  Type *Ty = nullptr;
  uint64_t Size = 0;
};

static bool isStateAlloca(AllocaInst *AI) {
  if (!AI || !AI->isStaticAlloca()) return false;
  StringRef Name = AI->getName();
  if (Name.contains("state") || Name.contains("State")) return true;
  Type *AllocTy = AI->getAllocatedType();
  if (auto *ST = dyn_cast<StructType>(AllocTy)) {
    return ST->hasName() &&
           (ST->getName().contains("struct.State") ||
            ST->getName().contains("ArchState"));
  }
  if (auto *AT = dyn_cast<ArrayType>(AllocTy)) {
    return AT->getNumElements() >= 1000;
  }
  if (AI->isArrayAllocation()) {
    if (auto *CI = dyn_cast<ConstantInt>(AI->getArraySize())) {
      return CI->getZExtValue() >= 1000;
    }
  }
  return false;
}

static std::optional<uint64_t> resolveOffset(Value *Ptr, AllocaInst *Base,
                                             const DataLayout &DL) {
  APInt Offset(DL.getIndexTypeSizeInBits(Ptr->getType()), 0);
  Value *Root = Ptr->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (Root != Base || Offset.isNegative() || Offset.getActiveBits() > 64)
    return std::nullopt;
  return Offset.getZExtValue();
}

static bool collectPointerUsers(Value *Ptr, AllocaInst *Base,
                                const DataLayout &DL,
                                SmallPtrSetImpl<Value *> &Seen,
                                SmallVectorImpl<Access> &Accesses,
                                Instruction *&ZeroInit) {
  if (!Seen.insert(Ptr).second)
    return true;
  for (User *U : Ptr->users()) {
    if (auto *LI = dyn_cast<LoadInst>(U)) {
      if (LI->getPointerOperand() != Ptr || LI->isVolatile() || LI->isAtomic())
        return false;
      auto Offset = resolveOffset(Ptr, Base, DL);
      if (!Offset)
        return false;
      TypeSize Size = DL.getTypeStoreSize(LI->getType());
      if (Size.isScalable())
        return false;
      Accesses.push_back(
          {LI, *Offset, LI->getType(), Size.getFixedValue()});
      continue;
    }
    if (auto *CI = dyn_cast<CallInst>(U)) {
      if (Function *Callee = CI->getCalledFunction()) {
        if (Callee->getIntrinsicID() == Intrinsic::memset) {
          if (CI->getArgOperand(0) == Ptr && isa<ConstantInt>(CI->getArgOperand(1)) &&
              cast<ConstantInt>(CI->getArgOperand(1))->isZero()) {
            if (!ZeroInit)
              ZeroInit = CI;
            continue;
          }
        }
      }
      errs() << "[brighten-state-ssa] unknown call user of State alloca: " << *CI << "\n";
      return false;
    }
    if (auto *SI = dyn_cast<StoreInst>(U)) {
      if (SI->getPointerOperand() != Ptr || SI->isVolatile() || SI->isAtomic())
        return false;
      if (Ptr == Base && (SI->getValueOperand()->getType() == Base->getAllocatedType() ||
                          isa<ConstantAggregateZero>(SI->getValueOperand()))) {
        if (ZeroInit || !isa<ConstantAggregateZero>(SI->getValueOperand()))
          return false;
        ZeroInit = SI;
        continue;
      }
      auto Offset = resolveOffset(Ptr, Base, DL);
      if (!Offset)
        return false;
      Type *Ty = SI->getValueOperand()->getType();
      TypeSize Size = DL.getTypeStoreSize(Ty);
      if (Size.isScalable())
        return false;
      Accesses.push_back({SI, *Offset, Ty, Size.getFixedValue()});
      continue;
    }
    if (isa<GetElementPtrInst>(U) || isa<BitCastInst>(U) ||
        isa<AddrSpaceCastInst>(U)) {
      if (!collectPointerUsers(cast<Value>(U), Base, DL, Seen, Accesses,
                               ZeroInit))
        return false;
      continue;
    }
    errs() << "[brighten-state-ssa] unsupported user of State alloca: " << *U << "\n";
    return false;
  }
  return true;
}

} // namespace

// Native cleanup can localize a private McSema register file after the first
// State-SSA run.  Promote that late local object only when it is provably a
// collection of independent scalar slots: one dominating zero initializer,
// constant non-overlapping offsets, identical types at each offset, and no
// escape.  Ambiguous byte aliases remain untouched for strict-mode diagnosis.
bool BrightenStateSSAPass::PromoteLocalStateAllocas(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    SmallVector<AllocaInst *, 4> Candidates;
    for (Instruction &I : F.getEntryBlock())
      if (auto *AI = dyn_cast<AllocaInst>(&I); isStateAlloca(AI))
        Candidates.push_back(AI);

    DominatorTree DT(F);
    for (AllocaInst *AI : Candidates) {
      SmallPtrSet<Value *, 32> Seen;
      SmallVector<Access, 32> Accesses;
      Instruction *ZeroInit = nullptr;
      bool Collected = collectPointerUsers(AI, AI, DL, Seen, Accesses, ZeroInit);
      if (!Collected || !ZeroInit || Accesses.empty()) {
        errs() << "[brighten-state-ssa] Local State alloca promotion skipped in @" << F.getName()
               << ": collected=" << Collected << " zeroinit=" << (ZeroInit != nullptr)
               << " accesses=" << Accesses.size() << "\n";
        continue;
      }

      bool Safe = true;
      DenseMap<uint64_t, Type *> SlotTypes;
      DenseMap<uint64_t, uint64_t> SlotSizes;
      for (const Access &A : Accesses) {
        if (!DT.dominates(ZeroInit, A.Inst) || A.Size == 0 ||
            A.Offset > std::numeric_limits<uint64_t>::max() - A.Size) {
          errs() << "[brighten-state-ssa] fail dominate/size: inst=" << *A.Inst << " offset=" << A.Offset << "\n";
          Safe = false;
          break;
        }
        auto It = SlotTypes.find(A.Offset);
        if (It != SlotTypes.end() && It->second != A.Ty) {
          errs() << "[brighten-state-ssa] fail type conflict: offset=" << A.Offset << " ty1=" << *It->second << " ty2=" << *A.Ty << "\n";
          Safe = false;
          break;
        }
        SlotTypes[A.Offset] = A.Ty;
        SlotSizes[A.Offset] = A.Size;
      }
      for (auto A = SlotSizes.begin(); Safe && A != SlotSizes.end(); ++A) {
        uint64_t AEnd = A->first + A->second;
        for (auto B = std::next(A); B != SlotSizes.end(); ++B) {
          uint64_t BEnd = B->first + B->second;
          if (A->first < BEnd && B->first < AEnd) {
            Safe = false;
            break;
          }
        }
      }
      if (!Safe)
        continue;

      IRBuilder<> EB(&*F.getEntryBlock().getFirstInsertionPt());
      DenseMap<uint64_t, AllocaInst *> Slots;
      for (auto &Entry : SlotTypes) {
        AllocaInst *Slot = EB.CreateAlloca(
            Entry.second, nullptr, "native.state.slot." + Twine(Entry.first));
        Slots[Entry.first] = Slot;
        IRBuilder<> InitB(ZeroInit);
        InitB.CreateStore(Constant::getNullValue(Entry.second), Slot);
      }
      for (const Access &A : Accesses) {
        if (auto *LI = dyn_cast<LoadInst>(A.Inst)) {
          if (Slots.count(A.Offset)) {
            LI->setOperand(0, Slots[A.Offset]);
          } else {
            LI->replaceAllUsesWith(Constant::getNullValue(LI->getType()));
            LI->eraseFromParent();
          }
        } else {
          if (Slots.count(A.Offset))
            cast<StoreInst>(A.Inst)->setOperand(1, Slots[A.Offset]);
        }
      }
      ZeroInit->eraseFromParent();

      SmallVector<Instruction *, 32> DeadPointers;
      for (Value *V : Seen)
        if (auto *I = dyn_cast<Instruction>(V); I != AI)
          DeadPointers.push_back(I);
      bool Progress = true;
      while (Progress) {
        Progress = false;
        for (Instruction *I : DeadPointers)
          if (I->getParent() && I->use_empty()) {
            I->eraseFromParent();
            Progress = true;
          }
      }
      assert(AI->use_empty() && "validated State pointer graph was not dead");
      AI->eraseFromParent();

      SmallVector<AllocaInst *, 16> Promote;
      for (auto &Entry : Slots)
        Promote.push_back(Entry.second);
      PromoteMemToReg(Promote, DT);
      Changed = true;
    }
  }
  return Changed;
}

} // namespace brighten_state_ssa
