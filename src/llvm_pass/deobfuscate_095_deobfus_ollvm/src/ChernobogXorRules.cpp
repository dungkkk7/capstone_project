#include "ChernobogXorRules.h"

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

// LLVM's bitwise not is xor V, -1.  Both operand orders are canonical
// spellings of the same source bnot; no other xor is accepted here.
static bool matchNot(Value *V, Value *&Input) {
  auto *X = dyn_cast<BinaryOperator>(V);
  if (!isPlainIntegerBinary(X, Instruction::Xor))
    return false;
  if (isAllOnes(X->getOperand(0))) {
    Input = X->getOperand(1);
    return true;
  }
  if (isAllOnes(X->getOperand(1))) {
    Input = X->getOperand(0);
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

// Match (not X | Y), accepting only the legal commutation of that OR.
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
  bool Complement = false;
};

// Xor_OllvmRule_1: (~x | y) & (x | ~y) -> ~(x ^ y).
// The root operand order intentionally remains the source form so reporting
// stays one-to-one with Rule_1 versus Rule_2.  Inner ORs are commutative.
static std::optional<Match> matchRule1(Value *Root) {
  auto *And = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(And, Instruction::And))
    return std::nullopt;
  Value *X = nullptr;
  Value *Y = nullptr;
  if (!matchNotXOrY(And->getOperand(0), X, Y))
    return std::nullopt;
  Value *Y2 = nullptr;
  Value *X2 = nullptr;
  if (!matchNotXOrY(And->getOperand(1), Y2, X2) || X != X2 || Y != Y2 ||
      !hasDefinedLeaves(X, Y))
    return std::nullopt;
  return Match{"Xor_OllvmRule_1", X, Y, true};
}

// Xor_OllvmRule_2: (x | ~y) & (~x | y) -> ~(x ^ y).
static std::optional<Match> matchRule2(Value *Root) {
  auto *And = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(And, Instruction::And))
    return std::nullopt;
  Value *Y = nullptr;
  Value *X = nullptr;
  if (!matchNotXOrY(And->getOperand(0), Y, X))
    return std::nullopt;
  Value *X2 = nullptr;
  Value *Y2 = nullptr;
  if (!matchNotXOrY(And->getOperand(1), X2, Y2) || X != X2 || Y != Y2 ||
      !hasDefinedLeaves(X, Y))
    return std::nullopt;
  return Match{"Xor_OllvmRule_2", X, Y, true};
}

// Xor_OllvmRule_3: ~(~x & ~y) & ~(x & y) -> x ^ y.
static std::optional<Match> matchRule3(Value *Root) {
  auto *RootAnd = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(RootAnd, Instruction::And))
    return std::nullopt;
  // The outer AND is commutative; unlike Rule_1/2 there is no separate
  // source rule whose report encodes the opposite root order.
  for (unsigned I = 0; I != 2; ++I) {
    Value *NotPair = nullptr;
    Value *Pair = nullptr;
    if (!matchNot(RootAnd->getOperand(I), NotPair) ||
        !matchNot(RootAnd->getOperand(1 - I), Pair))
      continue;
    auto *NotAnd = dyn_cast<BinaryOperator>(NotPair);
    auto *And = dyn_cast<BinaryOperator>(Pair);
    if (!isPlainIntegerBinary(NotAnd, Instruction::And) ||
        !isPlainIntegerBinary(And, Instruction::And))
      continue;
    Value *X = nullptr;
    Value *Y = nullptr;
    if (matchNot(NotAnd->getOperand(0), X) &&
        matchNot(NotAnd->getOperand(1), Y) &&
        matchUnorderedPair(And, X, Y) && hasDefinedLeaves(X, Y))
      return Match{"Xor_OllvmRule_3", X, Y, false};
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

bool simplifyChernobogXorRules(Function &F, ChernobogXorRuleMetrics &Metrics) {
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
    Value *Replacement = B.CreateXor(M->X, M->Y, "deobf.chernobog.xor");
    if (M->Complement)
      Replacement = B.CreateXor(
          Replacement, ConstantInt::getAllOnesValue(Root->getType()),
          "deobf.chernobog.xnor");
    Root->replaceAllUsesWith(Replacement);
    Root->eraseFromParent();
    auto &Count = Metrics.Rules[M->Name.str()];
    ++Count.Hits;
    Count.OperationsBefore += Before;
    Count.OperationsAfter += M->Complement ? 2 : 1;
    Changed = true;
  }
  return Changed;
}

} // namespace deobfuscate095
