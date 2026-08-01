#include "ChernobogOrRules.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"

#include <functional>
#include <optional>

using namespace llvm;

namespace deobfuscate095 {
namespace {

static bool hasForbiddenValue(Value *V, unsigned Depth = 0) {
  if (!V || Depth > 24 || V->getType()->isVectorTy())
    return true;
  if (isa<FreezeInst, UndefValue, PoisonValue>(V))
    return true;
  auto *I = dyn_cast<Instruction>(V);
  if (!I)
    return false;
  for (Value *Op : I->operands())
    if (hasForbiddenValue(Op, Depth + 1))
      return true;
  return false;
}

static bool isPlainIntegerBinary(const BinaryOperator *BO,
                                 Instruction::BinaryOps Opcode) {
  return BO && BO->getOpcode() == Opcode && BO->getType()->isIntegerTy() &&
         !BO->getType()->isIntegerTy(1);
}

static bool isAllOnes(Value *V) {
  auto *C = dyn_cast<ConstantInt>(V);
  return C && C->getValue().isAllOnes();
}

static bool matchNot(Value *V, Value *&Input) {
  auto *Xor = dyn_cast<BinaryOperator>(V);
  if (!isPlainIntegerBinary(Xor, Instruction::Xor))
    return false;
  if (isAllOnes(Xor->getOperand(0))) {
    Input = Xor->getOperand(1);
    return true;
  }
  if (isAllOnes(Xor->getOperand(1))) {
    Input = Xor->getOperand(0);
    return true;
  }
  return false;
}

static bool hasDefinedLeaves(Value *A, Value *B) {
  return A && B && A->getType() == B->getType() &&
         A->getType()->isIntegerTy() && !A->getType()->isIntegerTy(1) &&
         !hasForbiddenValue(A) && !hasForbiddenValue(B);
}

static bool matchUnorderedPair(const BinaryOperator *BO, Value *A, Value *B) {
  return BO && ((BO->getOperand(0) == A && BO->getOperand(1) == B) ||
                (BO->getOperand(0) == B && BO->getOperand(1) == A));
}

static unsigned pureDagOperationCount(Value *Root) {
  SmallPtrSet<Value *, 16> Seen;
  std::function<unsigned(Value *)> Count = [&](Value *V) -> unsigned {
    if (!V || !Seen.insert(V).second)
      return 0;
    auto *BO = dyn_cast<BinaryOperator>(V);
    if (!BO)
      return 0;
    return 1 + Count(BO->getOperand(0)) + Count(BO->getOperand(1));
  };
  return Count(Root);
}

struct Match {
  StringRef Name;
  Value *X = nullptr;
  Value *Y = nullptr;
};

// Or_OllvmRule_1: (~x & y) | (x & ~y) | (x & y) -> x | y
static std::optional<Match> matchOrOllvm1(Value *Root) {
  auto *Or = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(Or, Instruction::Or))
    return std::nullopt;

  for (unsigned I = 0; I != 2; ++I) {
    auto *LeftOr = dyn_cast<BinaryOperator>(Or->getOperand(I));
    auto *AndXY = dyn_cast<BinaryOperator>(Or->getOperand(1 - I));
    if (!isPlainIntegerBinary(LeftOr, Instruction::Or) ||
        !isPlainIntegerBinary(AndXY, Instruction::And))
      continue;

    Value *X = AndXY->getOperand(0);
    Value *Y = AndXY->getOperand(1);
    if (!hasDefinedLeaves(X, Y))
      continue;

    for (unsigned J = 0; J != 2; ++J) {
      auto *TermA = dyn_cast<BinaryOperator>(LeftOr->getOperand(J));
      auto *TermB = dyn_cast<BinaryOperator>(LeftOr->getOperand(1 - J));
      if (!isPlainIntegerBinary(TermA, Instruction::And) ||
          !isPlainIntegerBinary(TermB, Instruction::And))
        continue;

      Value *NotX = nullptr, *NotY = nullptr;
      Value *InX1 = nullptr, *InY1 = nullptr;
      Value *InX2 = nullptr, *InY2 = nullptr;

      if (matchNot(TermA->getOperand(0), NotX) && TermA->getOperand(1) == Y &&
          NotX == X &&
          TermB->getOperand(0) == X && matchNot(TermB->getOperand(1), NotY) &&
          NotY == Y) {
        return Match{"Or_OllvmRule_1", X, Y};
      }
    }
  }
  return std::nullopt;
}

// Or_HackersDelightRule_1: (x & y) + (x ^ y) -> x | y
static std::optional<Match> matchOrHD1(Value *Root) {
  auto *Add = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(Add, Instruction::Add))
    return std::nullopt;

  for (unsigned I = 0; I != 2; ++I) {
    auto *And = dyn_cast<BinaryOperator>(Add->getOperand(I));
    auto *Xor = dyn_cast<BinaryOperator>(Add->getOperand(1 - I));
    if (!isPlainIntegerBinary(And, Instruction::And) ||
        !isPlainIntegerBinary(Xor, Instruction::Xor))
      continue;
    Value *X = And->getOperand(0);
    Value *Y = And->getOperand(1);
    if (matchUnorderedPair(Xor, X, Y) && hasDefinedLeaves(X, Y))
      return Match{"Or_HackersDelightRule_1", X, Y};
  }
  return std::nullopt;
}

// Or_HackersDelightRule_2: (x + y) - (x & y) -> x | y
static std::optional<Match> matchOrHD2(Value *Root) {
  auto *Sub = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(Sub, Instruction::Sub))
    return std::nullopt;

  auto *Add = dyn_cast<BinaryOperator>(Sub->getOperand(0));
  auto *And = dyn_cast<BinaryOperator>(Sub->getOperand(1));
  if (!isPlainIntegerBinary(Add, Instruction::Add) ||
      !isPlainIntegerBinary(And, Instruction::And))
    return std::nullopt;

  Value *X = And->getOperand(0);
  Value *Y = And->getOperand(1);
  if (matchUnorderedPair(Add, X, Y) && hasDefinedLeaves(X, Y))
    return Match{"Or_HackersDelightRule_2", X, Y};
  return std::nullopt;
}

// Or_MbaRule_1: ~(~x & ~y) -> x | y
static std::optional<Match> matchOrMba1(Value *Root) {
  Value *AndNot = nullptr;
  if (!matchNot(Root, AndNot))
    return std::nullopt;

  auto *And = dyn_cast<BinaryOperator>(AndNot);
  if (!isPlainIntegerBinary(And, Instruction::And))
    return std::nullopt;

  Value *X = nullptr, *Y = nullptr;
  if (matchNot(And->getOperand(0), X) && matchNot(And->getOperand(1), Y) &&
      hasDefinedLeaves(X, Y))
    return Match{"Or_MbaRule_1", X, Y};
  return std::nullopt;
}

static std::optional<Match> match(Value *Root) {
  if (auto M = matchOrOllvm1(Root)) return M;
  if (auto M = matchOrHD1(Root)) return M;
  if (auto M = matchOrHD2(Root)) return M;
  return matchOrMba1(Root);
}

} // namespace

bool simplifyChernobogOrRules(Function &F, ChernobogOrRuleMetrics &Metrics) {
  SmallVector<Instruction *, 64> Roots;
  for (Instruction &I : instructions(F))
    if (I.getType()->isIntegerTy() && !I.getType()->isIntegerTy(1) &&
        !I.use_empty())
      Roots.push_back(&I);

  bool Changed = false;
  for (Instruction *Root : reverse(Roots)) {
    if (!Root->getParent() || Root->use_empty())
      continue;
    auto M = match(Root);
    if (!M)
      continue;
    const unsigned Before = pureDagOperationCount(Root);
    IRBuilder<> B(Root);
    B.SetCurrentDebugLocation(Root->getDebugLoc());
    Value *Replacement = B.CreateOr(M->X, M->Y, "deobf.chernobog.or");
    Root->replaceAllUsesWith(Replacement);
    Root->eraseFromParent();
    auto &Count = Metrics.Rules[M->Name.str()];
    ++Count.Hits;
    Count.OperationsBefore += Before;
    Count.OperationsAfter += 1;
    Changed = true;
  }
  return Changed;
}

} // namespace deobfuscate095
