#include "ChernobogMiscRules.h"

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

static bool isIntegerConstant(Value *V, uint64_t N) {
  auto *C = dyn_cast<ConstantInt>(V);
  return C && C->getValue() == N;
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

static bool matchNeg(Value *V, Value *&Input) {
  auto *Sub = dyn_cast<BinaryOperator>(V);
  if (!isPlainIntegerBinary(Sub, Instruction::Sub))
    return false;
  if (isIntegerConstant(Sub->getOperand(0), 0)) {
    Input = Sub->getOperand(1);
    return true;
  }
  return false;
}

static bool hasDefinedLeaves(Value *A) {
  return A && A->getType()->isIntegerTy() && !A->getType()->isIntegerTy(1) &&
         !hasForbiddenValue(A);
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
  enum ActionKind {
    MakeNot,
    MakeNeg,
    MakeIdentity
  } Action = MakeIdentity;
};

// Bnot_HackersDelightRule_1: -x - 1 -> ~x
static std::optional<Match> matchBnotHD1(Value *Root) {
  auto *Sub = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(Sub, Instruction::Sub))
    return std::nullopt;

  if (!isIntegerConstant(Sub->getOperand(1), 1))
    return std::nullopt;

  Value *NegX = Sub->getOperand(0);
  Value *X = nullptr;
  if (matchNeg(NegX, X) && hasDefinedLeaves(X))
    return Match{"Bnot_HackersDelightRule_1", X, Match::MakeNot};
  return std::nullopt;
}

// Neg_HackersDelightRule_1: ~x + 1 -> -x
static std::optional<Match> matchNegHD1(Value *Root) {
  auto *Add = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(Add, Instruction::Add))
    return std::nullopt;

  for (unsigned I = 0; I != 2; ++I) {
    if (!isIntegerConstant(Add->getOperand(1 - I), 1))
      continue;
    Value *NotX = Add->getOperand(I);
    Value *X = nullptr;
    if (matchNot(NotX, X) && hasDefinedLeaves(X))
      return Match{"Neg_HackersDelightRule_1", X, Match::MakeNeg};
  }
  return std::nullopt;
}

// Const_OrSelf: x | x -> x
static std::optional<Match> matchOrSelf(Value *Root) {
  auto *Or = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(Or, Instruction::Or))
    return std::nullopt;

  if (Or->getOperand(0) == Or->getOperand(1) && hasDefinedLeaves(Or->getOperand(0)))
    return Match{"Const_OrSelf", Or->getOperand(0), Match::MakeIdentity};
  return std::nullopt;
}

// Const_AndSelf: x & x -> x
static std::optional<Match> matchAndSelf(Value *Root) {
  auto *And = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(And, Instruction::And))
    return std::nullopt;

  if (And->getOperand(0) == And->getOperand(1) && hasDefinedLeaves(And->getOperand(0)))
    return Match{"Const_AndSelf", And->getOperand(0), Match::MakeIdentity};
  return std::nullopt;
}

static std::optional<Match> match(Value *Root) {
  if (auto M = matchBnotHD1(Root)) return M;
  if (auto M = matchNegHD1(Root)) return M;
  if (auto M = matchOrSelf(Root)) return M;
  return matchAndSelf(Root);
}

} // namespace

bool simplifyChernobogMiscRules(Function &F, ChernobogMiscRuleMetrics &Metrics) {
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
    if (M->Action == Match::MakeNot) {
      Replacement = B.CreateXor(
          M->X, ConstantInt::get(Root->getType(), -1), "deobf.chernobog.not");
    } else if (M->Action == Match::MakeNeg) {
      Replacement = B.CreateSub(
          ConstantInt::get(Root->getType(), 0), M->X, "deobf.chernobog.neg");
    } else {
      Replacement = M->X;
    }
    Root->replaceAllUsesWith(Replacement);
    Root->eraseFromParent();
    auto &Count = Metrics.Rules[M->Name.str()];
    ++Count.Hits;
    Count.OperationsBefore += Before;
    Count.OperationsAfter += (M->Action == Match::MakeIdentity ? 0 : 1);
    Changed = true;
  }
  return Changed;
}

} // namespace deobfuscate095
