#include "ChernobogAndRules.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
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

// LLVM's bnot is xor V, -1.  The two operand orders are equivalent source
// spellings; no arbitrary XOR expression is accepted.
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

// And_OllvmRule_1: (x | y) & ~(x ^ y) -> x & y.
// Keep the root operand order distinct from Rule_2, as in the source catalog.
static std::optional<Match> matchRule1(Value *Root) {
  auto *And = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(And, Instruction::And))
    return std::nullopt;
  auto *Or = dyn_cast<BinaryOperator>(And->getOperand(0));
  Value *XorInput = nullptr;
  if (!isPlainIntegerBinary(Or, Instruction::Or) ||
      !matchNot(And->getOperand(1), XorInput))
    return std::nullopt;
  auto *Xor = dyn_cast<BinaryOperator>(XorInput);
  Value *X = Or->getOperand(0);
  Value *Y = Or->getOperand(1);
  if (!isPlainIntegerBinary(Xor, Instruction::Xor) ||
      !matchUnorderedPair(Xor, X, Y) || !hasDefinedLeaves(X, Y))
    return std::nullopt;
  return Match{"And_OllvmRule_1", X, Y};
}

// And_OllvmRule_2: ~(x ^ y) & (x | y) -> x & y.
static std::optional<Match> matchRule2(Value *Root) {
  auto *And = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(And, Instruction::And))
    return std::nullopt;
  Value *XorInput = nullptr;
  auto *Or = dyn_cast<BinaryOperator>(And->getOperand(1));
  if (!matchNot(And->getOperand(0), XorInput) ||
      !isPlainIntegerBinary(Or, Instruction::Or))
    return std::nullopt;
  auto *Xor = dyn_cast<BinaryOperator>(XorInput);
  Value *X = Or->getOperand(0);
  Value *Y = Or->getOperand(1);
  if (!isPlainIntegerBinary(Xor, Instruction::Xor) ||
      !matchUnorderedPair(Xor, X, Y) || !hasDefinedLeaves(X, Y))
    return std::nullopt;
  return Match{"And_OllvmRule_2", X, Y};
}

// Match one source branch (~x | y), permitting OR and bnot operand order.
static bool matchNotXOrY(Value *V, Value *&X, Value *&Y) {
  auto *Or = dyn_cast<BinaryOperator>(V);
  if (!isPlainIntegerBinary(Or, Instruction::Or))
    return false;
  Value *Candidate = nullptr;
  if (matchNot(Or->getOperand(0), Candidate)) {
    X = Candidate;
    Y = Or->getOperand(1);
    return true;
  }
  if (matchNot(Or->getOperand(1), Candidate)) {
    X = Candidate;
    Y = Or->getOperand(0);
    return true;
  }
  return false;
}

// And_OllvmRule_3: (~x | y) & (x | ~y) & (x | y) -> x & y.
// The nested AND shape is retained exactly; only commutation of individual
// bitwise operators is admitted.
static std::optional<Match> matchRule3(Value *Root) {
  auto *OuterAnd = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(OuterAnd, Instruction::And))
    return std::nullopt;
  for (unsigned I = 0; I != 2; ++I) {
    auto *InnerAnd = dyn_cast<BinaryOperator>(OuterAnd->getOperand(I));
    auto *PositiveOr = dyn_cast<BinaryOperator>(OuterAnd->getOperand(1 - I));
    if (!isPlainIntegerBinary(InnerAnd, Instruction::And) ||
        !isPlainIntegerBinary(PositiveOr, Instruction::Or))
      continue;
    for (unsigned J = 0; J != 2; ++J) {
      Value *X = nullptr;
      Value *Y = nullptr;
      if (!matchNotXOrY(InnerAnd->getOperand(J), X, Y))
        continue;
      Value *Y2 = nullptr;
      Value *X2 = nullptr;
      if (!matchNotXOrY(InnerAnd->getOperand(1 - J), Y2, X2) || X != X2 ||
          Y != Y2 || !matchUnorderedPair(PositiveOr, X, Y) ||
          !hasDefinedLeaves(X, Y))
        continue;
      return Match{"And_OllvmRule_3", X, Y};
    }
  }
  return std::nullopt;
}

static std::optional<Match> match(Value *Root) {
  if (auto M = matchRule1(Root))
    return M;
  if (auto M = matchRule2(Root))
    return M;
  return matchRule3(Root);
}

} // namespace

bool simplifyChernobogAndRules(Function &F, ChernobogAndRuleMetrics &Metrics) {
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
    Value *Replacement = B.CreateAnd(M->X, M->Y, "deobf.chernobog.and");
    Root->replaceAllUsesWith(Replacement);
    Root->eraseFromParent();
    auto &Count = Metrics.Rules[M->Name.str()];
    ++Count.Hits;
    Count.OperationsBefore += Before;
    ++Count.OperationsAfter;
    Changed = true;
  }
  return Changed;
}

} // namespace deobfuscate095
