#include "ChernobogAddRules.h"

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
  if (!V || Depth > 24)
    return true;
  if (V->getType()->isVectorTy())
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

static bool isPlainIntegerBinary(const BinaryOperator *BO) {
  return BO && BO->getType()->isIntegerTy() &&
         !BO->getType()->isIntegerTy(1);
}

static Value *stripCasts(Value *V) {
  while (V && isa<CastInst>(V)) {
    V = cast<CastInst>(V)->getOperand(0);
  }
  return V;
}

static bool hasDefinedLeaves(Value *A, Value *B) {
  A = stripCasts(A);
  B = stripCasts(B);
  return A && B && A->getType()->isIntegerTy() && !A->getType()->isIntegerTy(1) &&
         !hasForbiddenValue(A) && !hasForbiddenValue(B);
}

static bool isIntegerConstant(Value *V, uint64_t N) {
  V = stripCasts(V);
  auto *C = dyn_cast<ConstantInt>(V);
  return C && C->getValue() == N;
}

static bool isAllOnes(Value *V) {
  V = stripCasts(V);
  auto *C = dyn_cast<ConstantInt>(V);
  return C && C->getValue().isAllOnes();
}

static BinaryOperator *asBinary(Value *V, Instruction::BinaryOps Op) {
  V = stripCasts(V);
  auto *BO = dyn_cast<BinaryOperator>(V);
  return BO && BO->getOpcode() == Op && isPlainIntegerBinary(BO) ? BO
                                                                    : nullptr;
}

// LLVM bnot is xor V, -1.  Match both operand orders, but transparently peel casts
static bool matchNot(Value *V, Value *&Input) {
  auto *Xor = asBinary(V, Instruction::Xor);
  if (!Xor)
    return false;
  if (isAllOnes(Xor->getOperand(0))) {
    Input = stripCasts(Xor->getOperand(1));
    return true;
  }
  if (isAllOnes(Xor->getOperand(1))) {
    Input = stripCasts(Xor->getOperand(0));
    return true;
  }
  return false;
}

static bool matchAddConstant(Value *V, uint64_t N, Value *&Other) {
  auto *Add = asBinary(V, Instruction::Add);
  if (!Add)
    return false;
  if (isIntegerConstant(Add->getOperand(0), N)) {
    Other = stripCasts(Add->getOperand(1));
    return true;
  }
  if (isIntegerConstant(Add->getOperand(1), N)) {
    Other = stripCasts(Add->getOperand(0));
    return true;
  }
  return false;
}

static bool matchUnorderedPair(BinaryOperator *BO, Value *A, Value *B) {
  if (!BO) return false;
  Value *Op0 = stripCasts(BO->getOperand(0));
  Value *Op1 = stripCasts(BO->getOperand(1));
  A = stripCasts(A);
  B = stripCasts(B);
  return (Op0 == A && Op1 == B) || (Op0 == B && Op1 == A);
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
  bool AddTwo = false;
  bool ReturnYPlusOne = false;
};

// (x & y) + (x | y) -> x + y.
static std::optional<Match> matchRule1(Value *Root) {
  auto *Add = asBinary(Root, Instruction::Add);
  if (!Add)
    return std::nullopt;
  for (unsigned I = 0; I != 2; ++I) {
    auto *And = asBinary(Add->getOperand(I), Instruction::And);
    auto *Or = asBinary(Add->getOperand(1 - I), Instruction::Or);
    if (!And || !Or)
      continue;
    Value *X = And->getOperand(0);
    Value *Y = And->getOperand(1);
    if (matchUnorderedPair(Or, X, Y) && hasDefinedLeaves(X, Y))
      return Match{"Add_OllvmRule_1", X, Y, false};
  }
  return std::nullopt;
}

// ~(~x + ~y) + 1 -> x + y + 2.
static std::optional<Match> matchRule2(Value *Root) {
  Value *NotSum = nullptr;
  if (!matchAddConstant(Root, 1, NotSum))
    return std::nullopt;
  Value *Sum = nullptr;
  if (!matchNot(NotSum, Sum))
    return std::nullopt;
  auto *Add = asBinary(Sum, Instruction::Add);
  if (!Add)
    return std::nullopt;
  Value *X = nullptr;
  Value *Y = nullptr;
  if (!matchNot(Add->getOperand(0), X) || !matchNot(Add->getOperand(1), Y) ||
      !hasDefinedLeaves(X, Y))
    return std::nullopt;
  return Match{"Add_OllvmRule_2", X, Y, true};
}

// -(~x + ~y + 2) -> x + y.  LLVM neg is sub 0, V.
static std::optional<Match> matchRule3(Value *Root) {
  auto *Neg = asBinary(Root, Instruction::Sub);
  if (!Neg || !isIntegerConstant(Neg->getOperand(0), 0))
    return std::nullopt;
  Value *NotPair = nullptr;
  if (!matchAddConstant(Neg->getOperand(1), 2, NotPair))
    return std::nullopt;
  auto *Add = asBinary(NotPair, Instruction::Add);
  if (!Add)
    return std::nullopt;
  Value *X = nullptr;
  Value *Y = nullptr;
  if (!matchNot(Add->getOperand(0), X) || !matchNot(Add->getOperand(1), Y) ||
      !hasDefinedLeaves(X, Y))
    return std::nullopt;
  return Match{"Add_OllvmRule_3", X, Y, false};
}

// ~(~x | ~y) + ~(x | ~y) + 1 -> y + 1.
static std::optional<Match> matchRule4(Value *Root) {
  Value *Inner = nullptr;
  if (!matchAddConstant(Root, 1, Inner))
    return std::nullopt;
  auto *Add = asBinary(Inner, Instruction::Add);
  if (!Add)
    return std::nullopt;
  for (unsigned I = 0; I != 2; ++I) {
    Value *FirstOr = nullptr;
    Value *SecondOr = nullptr;
    if (!matchNot(Add->getOperand(I), FirstOr) ||
        !matchNot(Add->getOperand(1 - I), SecondOr))
      continue;
    auto *First = asBinary(FirstOr, Instruction::Or);
    auto *Second = asBinary(SecondOr, Instruction::Or);
    if (!First || !Second)
      continue;
    for (unsigned J = 0; J != 2; ++J) {
      Value *X = nullptr;
      Value *Y = nullptr;
      if (!matchNot(First->getOperand(J), X) ||
          !matchNot(First->getOperand(1 - J), Y))
        continue;
      Value *NotY = nullptr;
      bool SecondMatches =
          (Second->getOperand(0) == X && matchNot(Second->getOperand(1), NotY)) ||
          (Second->getOperand(1) == X && matchNot(Second->getOperand(0), NotY));
      if (SecondMatches && NotY == Y && hasDefinedLeaves(X, Y))
        return Match{"Add_OllvmRule_4", X, Y, false, true};
    }
  }
  return std::nullopt;
}

// Add_HackersDelightRule_1: x - (~y + 1) -> x + y
static std::optional<Match> matchHD1(Value *Root) {
  auto *Sub = asBinary(Root, Instruction::Sub);
  if (!Sub)
    return std::nullopt;
  Value *X = Sub->getOperand(0);
  Value *YPlusOne = Sub->getOperand(1);
  Value *NotY = nullptr;
  if (matchAddConstant(YPlusOne, 1, NotY)) {
    Value *Y = nullptr;
    if (matchNot(NotY, Y) && hasDefinedLeaves(X, Y))
      return Match{"Add_HackersDelightRule_1", X, Y, false};
  }
  return std::nullopt;
}

// Add_HackersDelightRule_3: (x ^ y) + 2*(x & y) -> x + y
static std::optional<Match> matchHD3(Value *Root) {
  auto *Add = asBinary(Root, Instruction::Add);
  if (!Add)
    return std::nullopt;
  for (unsigned I = 0; I != 2; ++I) {
    auto *Xor = asBinary(Add->getOperand(I), Instruction::Xor);
    auto *Mul = asBinary(Add->getOperand(1 - I), Instruction::Mul);
    if (!Xor || !Mul)
      continue;
    Value *Two = nullptr, *AndVal = nullptr;
    if (isIntegerConstant(Mul->getOperand(0), 2)) AndVal = Mul->getOperand(1);
    else if (isIntegerConstant(Mul->getOperand(1), 2)) AndVal = Mul->getOperand(0);
    else continue;
    auto *And = asBinary(AndVal, Instruction::And);
    if (!And) continue;
    Value *X = Xor->getOperand(0);
    Value *Y = Xor->getOperand(1);
    if (matchUnorderedPair(And, X, Y) && hasDefinedLeaves(X, Y))
      return Match{"Add_HackersDelightRule_3", X, Y, false};
  }
  return std::nullopt;
}

// Add_CarryFreeOrRule: x + (y & ~x) -> x | y
static std::optional<Match> matchCarryFreeOr(Value *Root) {
  auto *Add = asBinary(Root, Instruction::Add);
  if (!Add)
    return std::nullopt;
  for (unsigned I = 0; I != 2; ++I) {
    Value *X = Add->getOperand(I);
    auto *And = asBinary(Add->getOperand(1 - I), Instruction::And);
    if (!And) continue;
    for (unsigned J = 0; J != 2; ++J) {
      Value *Y = And->getOperand(J);
      Value *NotX = And->getOperand(1 - J);
      Value *Input = nullptr;
      if (matchNot(NotX, Input) && Input == X && hasDefinedLeaves(X, Y)) {
        // Returns x | y by constructing an OR instruction
        return Match{"Add_CarryFreeOrRule", X, Y, false};
      }
    }
  }
  return std::nullopt;
}

// Add_HackersDelightRule_2: (x | y) + (x & y) -> x + y
static std::optional<Match> matchHD2(Value *Root) {
  auto *Add = asBinary(Root, Instruction::Add);
  if (!Add)
    return std::nullopt;
  for (unsigned I = 0; I != 2; ++I) {
    auto *Or = asBinary(Add->getOperand(I), Instruction::Or);
    auto *And = asBinary(Add->getOperand(1 - I), Instruction::And);
    if (!Or || !And)
      continue;
    Value *X = Or->getOperand(0);
    Value *Y = Or->getOperand(1);
    if (matchUnorderedPair(And, X, Y) && hasDefinedLeaves(X, Y))
      return Match{"Add_HackersDelightRule_2", X, Y, false};
  }
  return std::nullopt;
}

// Add_HackersDelightRule_4: 2*(x | y) - (x ^ y) -> x + y
static std::optional<Match> matchHD4(Value *Root) {
  auto *Sub = asBinary(Root, Instruction::Sub);
  if (!Sub)
    return std::nullopt;
  auto *Mul = asBinary(Sub->getOperand(0), Instruction::Mul);
  auto *Xor = asBinary(Sub->getOperand(1), Instruction::Xor);
  if (!Mul || !Xor)
    return std::nullopt;
  Value *OrVal = nullptr;
  if (isIntegerConstant(Mul->getOperand(0), 2)) OrVal = Mul->getOperand(1);
  else if (isIntegerConstant(Mul->getOperand(1), 2)) OrVal = Mul->getOperand(0);
  else return std::nullopt;
  auto *Or = asBinary(OrVal, Instruction::Or);
  if (!Or) return std::nullopt;
  Value *X = Xor->getOperand(0);
  Value *Y = Xor->getOperand(1);
  if (matchUnorderedPair(Or, X, Y) && hasDefinedLeaves(X, Y))
    return Match{"Add_HackersDelightRule_4", X, Y, false};
  return std::nullopt;
}

// Add_FactorRule_1: ~x + ~y + 2 -> -(x + y)
static std::optional<Match> matchFactor1(Value *Root) {
  Value *AddSum = nullptr;
  if (!matchAddConstant(Root, 2, AddSum))
    return std::nullopt;
  auto *Add = asBinary(AddSum, Instruction::Add);
  if (!Add)
    return std::nullopt;
  Value *X = nullptr, *Y = nullptr;
  if (matchNot(Add->getOperand(0), X) && matchNot(Add->getOperand(1), Y) && hasDefinedLeaves(X, Y))
    return Match{"Add_FactorRule_1", X, Y, false};
  return std::nullopt;
}

// Add_NegRule_1: x - (-y) -> x + y
static std::optional<Match> matchNeg1(Value *Root) {
  auto *Sub = asBinary(Root, Instruction::Sub);
  if (!Sub)
    return std::nullopt;
  Value *X = Sub->getOperand(0);
  auto *Neg = asBinary(Sub->getOperand(1), Instruction::Sub);
  if (!Neg || !isIntegerConstant(Neg->getOperand(0), 0))
    return std::nullopt;
  Value *Y = Neg->getOperand(1);
  if (hasDefinedLeaves(X, Y))
    return Match{"Add_NegRule_1", X, Y, false};
  return std::nullopt;
}

static std::optional<Match> match(Value *Root) {
  if (auto M = matchRule1(Root)) return M;
  if (auto M = matchRule2(Root)) return M;
  if (auto M = matchRule3(Root)) return M;
  if (auto M = matchRule4(Root)) return M;
  if (auto M = matchHD1(Root)) return M;
  if (auto M = matchHD2(Root)) return M;
  if (auto M = matchHD3(Root)) return M;
  if (auto M = matchHD4(Root)) return M;
  if (auto M = matchCarryFreeOr(Root)) return M;
  if (auto M = matchFactor1(Root)) return M;
  return matchNeg1(Root);
}

} // namespace

bool simplifyChernobogAddRules(Function &F, ChernobogAddRuleMetrics &Metrics) {
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
    Value *Replacement = nullptr;
    if (M->ReturnYPlusOne) {
      Replacement = B.CreateAdd(
          M->Y, ConstantInt::get(Root->getType(), 1),
          "deobf.chernobog.add1");
    } else {
      Replacement = B.CreateAdd(M->X, M->Y, "deobf.chernobog.add");
    }
    if (M->AddTwo)
      Replacement = B.CreateAdd(
          Replacement, ConstantInt::get(Root->getType(), 2),
          "deobf.chernobog.add2");
    Root->replaceAllUsesWith(Replacement);
    Root->eraseFromParent();
    auto &Count = Metrics.Rules[M->Name.str()];
    ++Count.Hits;
    Count.OperationsBefore += Before;
    Count.OperationsAfter += M->AddTwo ? 2 : 1;
    Changed = true;
  }
  return Changed;
}

} // namespace deobfuscate095
