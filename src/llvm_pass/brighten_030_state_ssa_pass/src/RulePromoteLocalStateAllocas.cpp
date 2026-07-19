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
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"

#include <algorithm>
#include <limits>
#include <optional>
#include <tuple>

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
            auto *IsVolatile = dyn_cast<ConstantInt>(CI->getArgOperand(3));
            if (ZeroInit || !IsVolatile || !IsVolatile->isZero())
              return false;
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
// collection of byte-exact objects: one dominating zero initializer, constant
// offsets, first-class non-padded access types, and no escape.  Overlapping
// views share one integer backing slot and are lowered to endian-correct
// extract/insert operations before mem2reg.
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
    bool FunctionChanged = false;
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
      for (const Access &A : Accesses) {
        if (!DT.dominates(ZeroInit, A.Inst) || A.Size == 0 || A.Size > 4096 ||
            A.Offset > std::numeric_limits<uint64_t>::max() - A.Size) {
          errs() << "[brighten-state-ssa] fail dominate/size: inst=" << *A.Inst << " offset=" << A.Offset << "\n";
          Safe = false;
          break;
        }
        TypeSize BitSize = DL.getTypeSizeInBits(A.Ty);
        if (!A.Ty->isFirstClassType() || A.Ty->isAggregateType() ||
            BitSize.isScalable() ||
            BitSize.getFixedValue() != A.Size * 8) {
          errs() << "[brighten-state-ssa] padded/non-bitcastable access: "
                 << *A.Inst << "\n";
          Safe = false;
          break;
        }
      }
      if (Safe) {
        if (auto *CI = dyn_cast<CallInst>(ZeroInit)) {
          auto *Length = dyn_cast<ConstantInt>(CI->getArgOperand(2));
          auto InitOffset = resolveOffset(CI->getArgOperand(0), AI, DL);
          if (!Length || !InitOffset || Length->getValue().getActiveBits() > 64 ||
              *InitOffset > std::numeric_limits<uint64_t>::max() -
                                Length->getZExtValue()) {
            Safe = false;
          } else {
            uint64_t InitEnd = *InitOffset + Length->getZExtValue();
            for (const Access &A : Accesses)
              if (A.Offset < *InitOffset || A.Offset + A.Size > InitEnd) {
                Safe = false;
                break;
              }
          }
        }
      }
      if (!Safe)
        continue;

      struct Object {
        uint64_t Begin = 0;
        uint64_t End = 0;
        AllocaInst *Slot = nullptr;
      };
      SmallVector<const Access *, 32> Ordered;
      for (const Access &A : Accesses)
        Ordered.push_back(&A);
      llvm::sort(Ordered, [](const Access *A, const Access *B) {
        return std::tie(A->Offset, A->Size) < std::tie(B->Offset, B->Size);
      });
      SmallVector<Object, 16> Objects;
      for (const Access *A : Ordered) {
        uint64_t End = A->Offset + A->Size;
        if (!Objects.empty() && A->Offset < Objects.back().End) {
          Objects.back().End = std::max(Objects.back().End, End);
        } else {
          Objects.push_back({A->Offset, End, nullptr});
        }
      }
      for (const Object &O : Objects)
        if (O.End <= O.Begin || O.End - O.Begin > 4096) {
          Safe = false;
          break;
        }
      if (!Safe)
        continue;

      IRBuilder<> EB(&*F.getEntryBlock().getFirstInsertionPt());
      for (Object &O : Objects) {
        unsigned Bits = static_cast<unsigned>((O.End - O.Begin) * 8);
        Type *StorageTy = Type::getIntNTy(M.getContext(), Bits);
        O.Slot = EB.CreateAlloca(
            StorageTy, nullptr, "native.state.object." + Twine(O.Begin));
        IRBuilder<> InitB(ZeroInit);
        InitB.CreateStore(ConstantInt::get(StorageTy, 0), O.Slot);
      }

      auto FindObject = [&](const Access &A) -> Object * {
        uint64_t End = A.Offset + A.Size;
        for (Object &O : Objects)
          if (O.Begin <= A.Offset && End <= O.End)
            return &O;
        return nullptr;
      };

      for (const Access &A : Accesses) {
        Object *O = FindObject(A);
        assert(O && "validated access has no interval object");
        unsigned StorageBits =
            cast<IntegerType>(O->Slot->getAllocatedType())->getBitWidth();
        unsigned AccessBits = static_cast<unsigned>(A.Size * 8);
        uint64_t RelativeByte = DL.isLittleEndian()
                                    ? A.Offset - O->Begin
                                    : O->End - (A.Offset + A.Size);
        unsigned Shift = static_cast<unsigned>(RelativeByte * 8);
        IRBuilder<> B(A.Inst);
        if (auto *LI = dyn_cast<LoadInst>(A.Inst)) {
          Value *Bits = B.CreateLoad(O->Slot->getAllocatedType(), O->Slot,
                                     "native.state.object.load");
          if (Shift)
            Bits = B.CreateLShr(Bits, Shift, "native.state.extract.shift");
          if (AccessBits != StorageBits)
            Bits = B.CreateTrunc(
                Bits, Type::getIntNTy(M.getContext(), AccessBits),
                "native.state.extract");
          Value *Replacement = nullptr;
          if (A.Ty->isIntegerTy())
            Replacement = Bits;
          else if (A.Ty->isPointerTy())
            Replacement = B.CreateIntToPtr(Bits, A.Ty,
                                           "native.state.extract.ptr");
          else
            Replacement = B.CreateBitCast(Bits, A.Ty,
                                          "native.state.extract.bits");
          LI->replaceAllUsesWith(Replacement);
          LI->eraseFromParent();
        } else {
          auto *SI = cast<StoreInst>(A.Inst);
          Value *Stored = SI->getValueOperand();
          Value *StoredBits = nullptr;
          if (A.Ty->isIntegerTy())
            StoredBits = Stored;
          else if (A.Ty->isPointerTy())
            StoredBits = B.CreatePtrToInt(
                Stored, Type::getIntNTy(M.getContext(), AccessBits),
                "native.state.insert.ptr");
          else
            StoredBits = B.CreateBitCast(
                Stored, Type::getIntNTy(M.getContext(), AccessBits),
                "native.state.insert.bits");
          Value *Current = B.CreateLoad(O->Slot->getAllocatedType(), O->Slot,
                                        "native.state.object.current");
          APInt FieldMask = APInt::getBitsSet(StorageBits, Shift,
                                             Shift + AccessBits);
          Value *Cleared = B.CreateAnd(
              Current, ConstantInt::get(O->Slot->getAllocatedType(),
                                        ~FieldMask),
              "native.state.insert.clear");
          if (AccessBits != StorageBits)
            StoredBits = B.CreateZExt(StoredBits, O->Slot->getAllocatedType(),
                                      "native.state.insert.extend");
          if (Shift)
            StoredBits = B.CreateShl(StoredBits, Shift,
                                     "native.state.insert.shift");
          Value *Merged = B.CreateOr(Cleared, StoredBits,
                                     "native.state.insert");
          B.CreateStore(Merged, O->Slot);
          SI->eraseFromParent();
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
      for (Object &O : Objects)
        Promote.push_back(O.Slot);
      PromoteMemToReg(Promote, DT);
      Changed = FunctionChanged = true;
    }
    if (FunctionChanged)
      for (BasicBlock &BB : F)
        SimplifyInstructionsInBlock(&BB);
  }
  return Changed;
}

} // namespace brighten_state_ssa
