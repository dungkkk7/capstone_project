// Fold a narrow subset of common OLLVM MBA identities that survive lifting.
// We keep this intentionally small and syntax-driven so it is safe before the
// heavier optimization pipeline runs.
#include "BrightenRepairPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Transforms/Utils/Local.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static ConstantInt *constInt(Value *V) {
  return dyn_cast<ConstantInt>(V);
}

static Value *stripOneUseCasts(Value *V) {
  while (auto *I = dyn_cast<CastInst>(V)) {
    if (!I->hasOneUse()) {
      break;
    }
    if (!I->getType()->isIntegerTy() ||
        !I->getOperand(0)->getType()->isIntegerTy()) {
      break;
    }
    V = I->getOperand(0);
  }
  return V;
}

static bool sameValue(Value *A, Value *B) {
  return stripOneUseCasts(A) == stripOneUseCasts(B);
}

static bool matchXorConst(Value *V, Value *&X, APInt &C) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Xor) {
    return false;
  }

  if (auto *CI = constInt(BO->getOperand(1))) {
    X = BO->getOperand(0);
    C = CI->getValue();
    return true;
  }
  if (auto *CI = constInt(BO->getOperand(0))) {
    X = BO->getOperand(1);
    C = CI->getValue();
    return true;
  }
  return false;
}

static bool matchAndConst(Value *V, Value *&X, APInt &C) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::And) {
    return false;
  }

  if (auto *CI = constInt(BO->getOperand(1))) {
    X = BO->getOperand(0);
    C = CI->getValue();
    return true;
  }
  if (auto *CI = constInt(BO->getOperand(0))) {
    X = BO->getOperand(1);
    C = CI->getValue();
    return true;
  }
  return false;
}

static bool matchOrConst(Value *V, Value *&X, APInt &C) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Or) {
    return false;
  }

  if (auto *CI = constInt(BO->getOperand(1))) {
    X = BO->getOperand(0);
    C = CI->getValue();
    return true;
  }
  if (auto *CI = constInt(BO->getOperand(0))) {
    X = BO->getOperand(1);
    C = CI->getValue();
    return true;
  }
  return false;
}

static bool matchShlOne(Value *V, Value *&X) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Shl) {
    return false;
  }
  auto *CI = constInt(BO->getOperand(1));
  if (!CI || !CI->isOne()) {
    return false;
  }
  X = BO->getOperand(0);
  return true;
}

static bool matchMulTwo(Value *V, Value *&X) {
  if (matchShlOne(V, X)) {
    return true;
  }

  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Mul) {
    return false;
  }
  if (auto *CI = constInt(BO->getOperand(1)); CI && CI->equalsInt(2)) {
    X = BO->getOperand(0);
    return true;
  }
  if (auto *CI = constInt(BO->getOperand(0)); CI && CI->equalsInt(2)) {
    X = BO->getOperand(1);
    return true;
  }
  return false;
}

static bool matchAddConst(Value *V, Value *&X, APInt &C) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Add) {
    return false;
  }

  if (auto *CI = constInt(BO->getOperand(1))) {
    X = BO->getOperand(0);
    C = CI->getValue();
    return true;
  }
  if (auto *CI = constInt(BO->getOperand(0))) {
    X = BO->getOperand(1);
    C = CI->getValue();
    return true;
  }
  return false;
}

static bool matchAddPair(Value *V, Value *&A, Value *&B) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Add) {
    return false;
  }
  A = BO->getOperand(0);
  B = BO->getOperand(1);
  return true;
}

static bool matchSubPair(Value *V, Value *&A, Value *&B) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Sub) {
    return false;
  }
  A = BO->getOperand(0);
  B = BO->getOperand(1);
  return true;
}

static bool matchOrPair(Value *V, Value *&A, Value *&B) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Or) {
    return false;
  }
  A = BO->getOperand(0);
  B = BO->getOperand(1);
  return true;
}

static bool matchXorPair(Value *V, Value *&A, Value *&B) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Xor) {
    return false;
  }
  A = BO->getOperand(0);
  B = BO->getOperand(1);
  return true;
}

static bool matchAndPair(Value *V, Value *&A, Value *&B) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::And) {
    return false;
  }
  A = BO->getOperand(0);
  B = BO->getOperand(1);
  return true;
}

static bool samePair(Value *A1, Value *B1, Value *A2, Value *B2) {
  return (sameValue(A1, A2) && sameValue(B1, B2)) ||
         (sameValue(A1, B2) && sameValue(B1, A2));
}

static bool matchAddXorSelf(Value *V, Value *&X, APInt &C) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Add) {
    return false;
  }

  Value *XorX = nullptr;
  APInt XorC(1, 0);
  if (matchXorConst(BO->getOperand(0), XorX, XorC) &&
      sameValue(XorX, BO->getOperand(1))) {
    X = XorX;
    C = XorC;
    return true;
  }
  if (matchXorConst(BO->getOperand(1), XorX, XorC) &&
      sameValue(XorX, BO->getOperand(0))) {
    X = XorX;
    C = XorC;
    return true;
  }
  return false;
}

static bool matchRawMBAZero(Value *V) {
  Value *Left = nullptr;
  Value *Right = nullptr;

  if (!matchSubPair(V, Left, Right)) {
    return false;
  }

  // 2*(A|B) - (A^B) - (A+B) == 0
  {
    Value *InnerLeft = nullptr;
    Value *InnerRight = nullptr;
    if (matchSubPair(Left, InnerLeft, InnerRight)) {
      Value *OrAB = nullptr;
      Value *XorA = nullptr;
      Value *XorB = nullptr;
      Value *OrA = nullptr;
      Value *OrB = nullptr;
      Value *AddA = nullptr;
      Value *AddB = nullptr;
      if (matchMulTwo(InnerLeft, OrAB) &&
          matchXorPair(InnerRight, XorA, XorB) &&
          matchOrPair(OrAB, OrA, OrB) &&
          matchAddPair(Right, AddA, AddB) &&
          samePair(OrA, OrB, XorA, XorB) &&
          samePair(OrA, OrB, AddA, AddB)) {
        return true;
      }
    }
  }

  // 2*(A|B) - (A^B) - A - B == 0
  {
    Value *InnerLeft = nullptr;
    Value *TrailingB = nullptr;
    if (matchSubPair(Left, InnerLeft, TrailingB)) {
      Value *Mul2OrAB = nullptr;
      Value *TrailingA = nullptr;
      if (matchSubPair(InnerLeft, Mul2OrAB, TrailingA)) {
        Value *OrAB = nullptr;
        Value *OrA = nullptr;
        Value *OrB = nullptr;
        Value *XorA = nullptr;
        Value *XorB = nullptr;
        if (matchMulTwo(Mul2OrAB, OrAB) &&
            matchOrPair(OrAB, OrA, OrB) &&
            matchXorPair(TrailingA, XorA, XorB) &&
            samePair(OrA, OrB, XorA, XorB) &&
            samePair(OrA, OrB, Right, TrailingB)) {
          return true;
        }
      }
    }
  }

  // (A+B) - (A^B) - 2*(A&B) == 0
  {
    Value *InnerLeft = nullptr;
    Value *InnerRight = nullptr;
    if (matchSubPair(Left, InnerLeft, InnerRight)) {
      Value *AndAB = nullptr;
      Value *AndA = nullptr;
      Value *AndB = nullptr;
      Value *AddA = nullptr;
      Value *AddB = nullptr;
      Value *XorA = nullptr;
      Value *XorB = nullptr;
      if (matchAddPair(InnerLeft, AddA, AddB) &&
          matchXorPair(InnerRight, XorA, XorB) &&
          matchMulTwo(Right, AndAB) &&
          matchAndPair(AndAB, AndA, AndB) &&
          samePair(AddA, AddB, XorA, XorB) &&
          samePair(AddA, AddB, AndA, AndB)) {
        return true;
      }
    }
  }

  // (A|B) - (A^B) - (A&B) == 0
  {
    Value *InnerLeft = nullptr;
    Value *InnerRight = nullptr;
    if (matchSubPair(Left, InnerLeft, InnerRight)) {
      Value *OrA = nullptr;
      Value *OrB = nullptr;
      Value *XorA = nullptr;
      Value *XorB = nullptr;
      Value *AndA = nullptr;
      Value *AndB = nullptr;
      if (matchOrPair(InnerLeft, OrA, OrB) &&
          matchXorPair(InnerRight, XorA, XorB) &&
          matchAndPair(Right, AndA, AndB) &&
          samePair(OrA, OrB, XorA, XorB) &&
          samePair(OrA, OrB, AndA, AndB)) {
        return true;
      }
    }
  }

  // ((A&B) + (A|B)) - A - B == 0
  {
    Value *InnerLeft = nullptr;
    Value *TrailingB = nullptr;
    if (matchSubPair(V, InnerLeft, TrailingB)) {
      Value *AddLeft = nullptr;
      Value *TrailingA = nullptr;
      if (matchSubPair(InnerLeft, AddLeft, TrailingA)) {
        Value *AddA = nullptr;
        Value *AddB = nullptr;
        if (matchAddPair(AddLeft, AddA, AddB)) {
          auto MatchAndOrAdd = [&](Value *MaybeAnd, Value *MaybeOr) {
            Value *AndA = nullptr;
            Value *AndB = nullptr;
            Value *OrA = nullptr;
            Value *OrB = nullptr;
            return matchAndPair(MaybeAnd, AndA, AndB) &&
                   matchOrPair(MaybeOr, OrA, OrB) &&
                   samePair(AndA, AndB, OrA, OrB) &&
                   samePair(AndA, AndB, TrailingA, TrailingB);
          };

          if (MatchAndOrAdd(AddA, AddB) || MatchAndOrAdd(AddB, AddA)) {
            return true;
          }
        }
      }
    }
  }

  return false;
}

static bool matchTwiceMaskedPlusConst(Value *V, Value *X, const APInt &C) {
  Value *Base = nullptr;
  APInt AddC(1, 0);
  if (!matchAddConst(V, Base, AddC) || AddC != C) {
    return false;
  }

  Value *Masked = nullptr;
  if (!matchShlOne(Base, Masked)) {
    return false;
  }

  Value *AndX = nullptr;
  APInt Mask(1, 0);
  if (!matchAndConst(Masked, AndX, Mask)) {
    return false;
  }

  return sameValue(AndX, X) && Mask == ~C;
}

static bool matchShiftedMaskedPlusConst(Value *V, Value *X, const APInt &C) {
  Value *Base = nullptr;
  APInt AddC(1, 0);
  if (!matchAddConst(V, Base, AddC) || AddC != C) {
    return false;
  }

  Value *Masked = nullptr;
  APInt Mask(1, 0);
  if (!matchAndConst(Base, Masked, Mask)) {
    return false;
  }

  Value *ShlX = nullptr;
  return matchShlOne(Masked, ShlX) && sameValue(ShlX, X) &&
         Mask == (~C << 1);
}

static bool matchOrAndPlusConst(Value *V, Value *X, const APInt &C) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Add) {
    return false;
  }

  auto MatchSides = [&](Value *A, Value *B) {
    Value *OrX = nullptr;
    Value *AndX = nullptr;
    APInt OrC(1, 0), AndC(1, 0);
    return matchOrConst(A, OrX, OrC) && matchAndConst(B, AndX, AndC) &&
           sameValue(OrX, X) && sameValue(AndX, X) && OrC == C &&
           AndC == ~C;
  };

  return MatchSides(BO->getOperand(0), BO->getOperand(1)) ||
         MatchSides(BO->getOperand(1), BO->getOperand(0));
}

static bool matchOrShlTwicePlusNegConst(Value *V, Value *X,
                                        const APInt &C) {
  Value *Base = nullptr;
  APInt AddC(1, 0);
  if (!matchAddConst(V, Base, AddC) || AddC != -C) {
    return false;
  }

  auto *OrBO = dyn_cast<BinaryOperator>(Base);
  if (!OrBO || OrBO->getOpcode() != Instruction::Or) {
    return false;
  }

  auto MatchSide = [&](Value *A, Value *B) {
    Value *ShlX = nullptr;
    auto *CI = constInt(B);
    return CI && CI->getValue() == (C << 1) && matchShlOne(A, ShlX) &&
           sameValue(ShlX, X);
  };

  return MatchSide(OrBO->getOperand(0), OrBO->getOperand(1)) ||
         MatchSide(OrBO->getOperand(1), OrBO->getOperand(0));
}

static bool matchSimpleMBAZeroDiff(Value *A, Value *B) {
  Value *X = nullptr;
  APInt C(1, 0);
  auto MatchesOtherSide = [&](Value *Other) {
    return matchTwiceMaskedPlusConst(Other, X, C) ||
           matchShiftedMaskedPlusConst(Other, X, C) ||
           matchOrAndPlusConst(Other, X, C) ||
           matchOrShlTwicePlusNegConst(Other, X, C);
  };

  if (matchAddXorSelf(A, X, C) && MatchesOtherSide(B)) {
    return true;
  }
  if (matchAddXorSelf(B, X, C) && MatchesOtherSide(A)) {
    return true;
  }
  return false;
}

}  // namespace

bool BrightenRepairPass::SimplifyObfuscatedMBA(Module &M) {
  bool Changed = false;
  SmallVector<BinaryOperator *, 32> Worklist;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    for (Instruction &I : instructions(F)) {
      auto *BO = dyn_cast<BinaryOperator>(&I);
      if (!BO || BO->getOpcode() != Instruction::Sub ||
          !BO->getType()->isIntegerTy()) {
        continue;
      }
      Worklist.push_back(BO);
    }
  }

  for (BinaryOperator *BO : Worklist) {
    if (!BO->getParent()) {
      continue;
    }
    if (!matchRawMBAZero(BO) &&
        !matchSimpleMBAZeroDiff(BO->getOperand(0), BO->getOperand(1))) {
      continue;
    }

    BO->replaceAllUsesWith(ConstantInt::get(BO->getType(), 0));
    RecursivelyDeleteTriviallyDeadInstructions(BO);
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair
