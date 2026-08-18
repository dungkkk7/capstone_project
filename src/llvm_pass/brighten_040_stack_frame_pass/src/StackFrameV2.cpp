#include "BrightenStackFramePass.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <cstdint>
#include <limits>
#include <optional>
#include <string>

using namespace llvm;

namespace brighten_stack_frame {
namespace {

static constexpr uint64_t RSPStateOffset = 2312;

struct Access {
  CallInst *Translator = nullptr;
  Instruction *MemoryInst = nullptr;
  int64_t Offset = 0;
  uint64_t Bytes = 0;
  bool IsLoad = false;
};

static std::optional<uint64_t> metadataOffset(const AllocaInst &A) {
  MDNode *MD = A.getMetadata("brighten.state.offset");
  if (!MD || MD->getNumOperands() != 1)
    return std::nullopt;
  auto *CAM = dyn_cast<ConstantAsMetadata>(MD->getOperand(0));
  auto *CI = CAM ? dyn_cast<ConstantInt>(CAM->getValue()) : nullptr;
  return CI ? std::optional<uint64_t>(CI->getZExtValue()) : std::nullopt;
}

static bool pointerIsStateOffset(Value *Ptr, Value *State,
                                 const DataLayout &DL, uint64_t Wanted) {
  if (!Ptr || !State)
    return false;
  APInt Delta(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Ptr->stripAndAccumulateConstantOffsets(DL, Delta, true);
  return Base->stripPointerCasts() == State->stripPointerCasts() &&
         !Delta.isNegative() && Delta.getZExtValue() == Wanted;
}

static void collectRSPAnchors(Function &F, const DataLayout &DL,
                              SmallPtrSetImpl<Value *> &Anchors) {
  Value *State = F.arg_empty() ? nullptr : F.getArg(0);
  SmallPtrSet<AllocaInst *, 8> RSPSlots;
  for (Instruction &I : F.getEntryBlock()) {
    auto *A = dyn_cast<AllocaInst>(&I);
    if (A && metadataOffset(*A) == RSPStateOffset)
      RSPSlots.insert(A);
  }

  // Backward compatibility for 030 outputs produced before the metadata was
  // mandatory: an entry alloca seeded exclusively from State+RSP is accepted.
  for (Instruction &I : F.getEntryBlock()) {
    auto *S = dyn_cast<StoreInst>(&I);
    if (!S)
      continue;
    auto *A = dyn_cast<AllocaInst>(S->getPointerOperand()->stripPointerCasts());
    auto *L = dyn_cast<LoadInst>(S->getValueOperand());
    if (A && L && pointerIsStateOffset(L->getPointerOperand(), State, DL,
                                      RSPStateOffset))
      RSPSlots.insert(A);
  }

  for (Instruction &I : instructions(F)) {
    if (auto *L = dyn_cast<LoadInst>(&I)) {
      Value *P = L->getPointerOperand()->stripPointerCasts();
      if (RSPSlots.contains(dyn_cast<AllocaInst>(P)) ||
          pointerIsStateOffset(P, State, DL, RSPStateOffset))
        Anchors.insert(L);
    }
  }
}

static std::optional<int64_t>
affineOffset(Value *V, const SmallPtrSetImpl<Value *> &Anchors,
             SmallPtrSetImpl<Value *> &Visiting, unsigned Depth = 0) {
  if (!V || Depth > 24 || !Visiting.insert(V).second)
    return std::nullopt;
  if (Anchors.contains(V)) {
    Visiting.erase(V);
    return 0;
  }

  auto Finish = [&](std::optional<int64_t> R) {
    Visiting.erase(V);
    return R;
  };

  if (auto *F = dyn_cast<FreezeInst>(V))
    return Finish(affineOffset(F->getOperand(0), Anchors, Visiting, Depth + 1));
  if (auto *C = dyn_cast<CastInst>(V)) {
    if (C->getOpcode() == Instruction::ZExt ||
        C->getOpcode() == Instruction::SExt ||
        C->getOpcode() == Instruction::Trunc)
      return Finish(affineOffset(C->getOperand(0), Anchors, Visiting, Depth + 1));
  }
  auto *B = dyn_cast<BinaryOperator>(V);
  if (!B || (B->getOpcode() != Instruction::Add &&
             B->getOpcode() != Instruction::Sub))
    return Finish(std::nullopt);

  auto *C0 = dyn_cast<ConstantInt>(B->getOperand(0));
  auto *C1 = dyn_cast<ConstantInt>(B->getOperand(1));
  if (!!C0 == !!C1)
    return Finish(std::nullopt);

  Value *Dynamic = C0 ? B->getOperand(1) : B->getOperand(0);
  ConstantInt *K = C0 ? C0 : C1;
  auto Base = affineOffset(Dynamic, Anchors, Visiting, Depth + 1);
  if (!Base || K->getBitWidth() > 64)
    return Finish(std::nullopt);
  int64_t Delta = K->getValue().sextOrTrunc(64).getSExtValue();
  if (B->getOpcode() == Instruction::Sub && C0)
    return Finish(std::nullopt); // constant - rsp is not an RSP-relative slot.
  if (B->getOpcode() == Instruction::Sub)
    Delta = -Delta;
  if ((Delta > 0 && *Base > INT64_MAX - Delta) ||
      (Delta < 0 && *Base < INT64_MIN - Delta))
    return Finish(std::nullopt);
  return Finish(*Base + Delta);
}

static uint64_t accessBytes(Instruction &I, const DataLayout &DL) {
  Type *Ty = nullptr;
  if (auto *L = dyn_cast<LoadInst>(&I))
    Ty = L->getType();
  else if (auto *S = dyn_cast<StoreInst>(&I))
    Ty = S->getValueOperand()->getType();
  if (!Ty || !Ty->isSized())
    return 0;
  TypeSize N = DL.getTypeStoreSize(Ty);
  return N.isScalable() ? 0 : N.getFixedValue();
}

static bool collectAccesses(Function &F, const DataLayout &DL,
                            const SmallPtrSetImpl<Value *> &Anchors,
                            SmallVectorImpl<Access> &Out) {
  Function *Translate = F.getParent()->getFunction("__translate_guest_pointer");
  if (!Translate)
    return false;

  for (Instruction &I : instructions(F)) {
    auto *C = dyn_cast<CallInst>(&I);
    if (!C || C->getCalledFunction() != Translate || C->arg_size() < 2)
      continue;
    auto *StackFlag = dyn_cast<ConstantInt>(C->getArgOperand(1));
    if (!StackFlag || !StackFlag->isOne())
      continue;

    SmallPtrSet<Value *, 16> Visiting;
    auto Offset = affineOffset(C->getArgOperand(0), Anchors, Visiting);
    if (!Offset)
      return false;

    SmallVector<User *, 4> Users(C->users());
    if (Users.empty())
      continue;
    for (User *U : Users) {
      auto *MI = dyn_cast<Instruction>(U);
      if (!MI)
        return false;
      bool IsLoad = false;
      if (auto *L = dyn_cast<LoadInst>(MI)) {
        if (L->getPointerOperand() != C || L->isVolatile() || L->isAtomic())
          return false;
        IsLoad = true;
      } else if (auto *S = dyn_cast<StoreInst>(MI)) {
        if (S->getPointerOperand() != C || S->isVolatile() || S->isAtomic())
          return false;
      } else {
        return false; // escape, ptrtoint, call, PHI, GEP, lifetime, etc.
      }
      uint64_t Bytes = accessBytes(*MI, DL);
      if (!Bytes || Bytes > 4096)
        return false;
      Out.push_back({C, MI, *Offset, Bytes, IsLoad});
    }
  }
  return !Out.empty();
}

static bool rangeContains(const Access &Store, const Access &Load) {
  if (Store.IsLoad || !Load.IsLoad)
    return false;
  if (Store.Offset > Load.Offset)
    return false;
  uint64_t Delta = static_cast<uint64_t>(Load.Offset - Store.Offset);
  return Delta <= Store.Bytes && Load.Bytes <= Store.Bytes - Delta;
}

static bool loadsAreDefinitelyInitialized(ArrayRef<Access> Accesses,
                                          DominatorTree &DT) {
  for (const Access &L : Accesses) {
    if (!L.IsLoad)
      continue;
    bool Proven = false;
    for (const Access &S : Accesses) {
      if (!rangeContains(S, L))
        continue;
      if (DT.dominates(S.MemoryInst, L.MemoryInst)) {
        Proven = true;
        break;
      }
    }
    if (!Proven)
      return false;
  }
  return true;
}

static bool localize(Function &F, SmallVectorImpl<Access> &Accesses) {
  int64_t Min = 0, Max = 0;
  bool First = true;
  for (const Access &A : Accesses) {
    if (A.Offset > INT64_MAX - static_cast<int64_t>(A.Bytes))
      return false;
    int64_t End = A.Offset + static_cast<int64_t>(A.Bytes);
    if (First) {
      Min = A.Offset;
      Max = End;
      First = false;
    } else {
      Min = std::min(Min, A.Offset);
      Max = std::max(Max, End);
    }
  }
  if (First || Max <= Min || static_cast<uint64_t>(Max - Min) > 1u << 20)
    return false;

  IRBuilder<> B(&*F.getEntryBlock().getFirstInsertionPt());
  ArrayType *FrameTy = ArrayType::get(B.getInt8Ty(), Max - Min);
  AllocaInst *Frame = B.CreateAlloca(FrameTy, nullptr, "native_local_frame");

  for (Access &A : Accesses) {
    IRBuilder<> At(A.MemoryInst);
    uint64_t Index = static_cast<uint64_t>(A.Offset - Min);
    Value *P = At.CreateConstGEP2_64(FrameTy, Frame, 0, Index, "frame_ptr");
    if (auto *L = dyn_cast<LoadInst>(A.MemoryInst))
      L->setOperand(0, P);
    else
      cast<StoreInst>(A.MemoryInst)->setOperand(1, P);
  }

  SmallPtrSet<CallInst *, 16> Seen;
  for (const Access &A : Accesses)
    if (Seen.insert(A.Translator).second && A.Translator->use_empty())
      A.Translator->eraseFromParent();
  return true;
}

static void verifyOrDie(Module &M) {
  std::string E;
  raw_string_ostream OS(E);
  if (verifyModule(M, &OS))
    report_fatal_error(Twine("040 v2 produced invalid IR:\n") + OS.str());
}

static bool recover(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    SmallPtrSet<Value *, 16> Anchors;
    collectRSPAnchors(F, DL, Anchors);
    if (Anchors.empty())
      continue;
    SmallVector<Access, 32> Accesses;
    if (!collectAccesses(F, DL, Anchors, Accesses))
      continue;
    DominatorTree DT(F);
    if (!loadsAreDefinitelyInitialized(Accesses, DT))
      continue;
    Changed |= localize(F, Accesses);
  }
  verifyOrDie(M);
  return Changed;
}

} // namespace

bool BrightenStackFramePass::RecoverStackFrame(Module &M) { return recover(M); }

bool BrightenPostStateFramePass::CompactProvenPostStateFrameBackings(Module &M) {
  // v2 intentionally uses the same proof domain after 030/095 expose more
  // affine addresses. Global backing localization is not guessed here; 030
  // must first make the stack anchor explicit.
  return recover(M);
}

} // namespace brighten_stack_frame
