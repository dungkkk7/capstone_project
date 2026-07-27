#include "ChernobogSubRules.h"

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

static bool hasDefinedLeaves(Value *A, Value *B) {
  return A && B && A->getType() == B->getType() &&
         A->getType()->isIntegerTy() && !A->getType()->isIntegerTy(1) &&
         !hasForbiddenValue(A) && !hasForbiddenValue(B);
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
  bool IsSubOne = false;
};

// Sub_HackersDelightRule_1: x + ~y + 1 -> x - y
static std::optional<Match> matchSubHD1(Value *Root) {
  auto *AddOuter = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(AddOuter, Instruction::Add))
    return std::nullopt;

  for (unsigned I = 0; I != 2; ++I) {
    if (!isIntegerConstant(AddOuter->getOperand(1 - I), 1))
      continue;
    auto *AddInner = dyn_cast<BinaryOperator>(AddOuter->getOperand(I));
    if (!isPlainIntegerBinary(AddInner, Instruction::Add))
      continue;

    for (unsigned J = 0; J != 2; ++J) {
      Value *X = AddInner->getOperand(J);
      Value *NotY = AddInner->getOperand(1 - J);
      Value *Y = nullptr;
      if (matchNot(NotY, Y) && hasDefinedLeaves(X, Y))
        return Match{"Sub_HackersDelightRule_1", X, Y};
    }
  }
  return std::nullopt;
}

// Sub_HackersDelightRule_2: ~(~x + y) -> x - y
static std::optional<Match> matchSubHD2(Value *Root) {
  Value *Sum = nullptr;
  if (!matchNot(Root, Sum))
    return std::nullopt;

  auto *Add = dyn_cast<BinaryOperator>(Sum);
  if (!isPlainIntegerBinary(Add, Instruction::Add))
    return std::nullopt;

  for (unsigned I = 0; I != 2; ++I) {
    Value *NotX = Add->getOperand(I);
    Value *Y = Add->getOperand(1 - I);
    Value *X = nullptr;
    if (matchNot(NotX, X) && hasDefinedLeaves(X, Y))
      return Match{"Sub_HackersDelightRule_2", X, Y};
  }
  return std::nullopt;
}

// Sub_NegRule_1: x + (-y) -> x - y
static std::optional<Match> matchSubNeg1(Value *Root) {
  auto *Add = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(Add, Instruction::Add))
    return std::nullopt;

  for (unsigned I = 0; I != 2; ++I) {
    Value *X = Add->getOperand(I);
    Value *NegY = Add->getOperand(1 - I);
    Value *Y = nullptr;
    if (matchNeg(NegY, Y) && hasDefinedLeaves(X, Y))
      return Match{"Sub_NegRule_1", X, Y};
  }
  return std::nullopt;
}

// Sub_AddCancelRule: (x + y) - y -> x or (y + x) - y -> x
static std::optional<Match> matchSubAddCancel(Value *Root) {
  auto *Sub = dyn_cast<BinaryOperator>(Root);
  if (!isPlainIntegerBinary(Sub, Instruction::Sub))
    return std::nullopt;

  auto *Add = dyn_cast<BinaryOperator>(Sub->getOperand(0));
  Value *Y = Sub->getOperand(1);
  if (!isPlainIntegerBinary(Add, Instruction::Add))
    return std::nullopt;

  if (Add->getOperand(0) == Y && hasDefinedLeaves(Add->getOperand(1), Y))
    return Match{"Sub_AddCancelRule", Add->getOperand(1), Y, true};
  if (Add->getOperand(1) == Y && hasDefinedLeaves(Add->getOperand(0), Y))
    return Match{"Sub_AddCancelRule", Add->getOperand(0), Y, true};

  return std::nullopt;
}

static std::optional<Match> match(Value *Root) {
  if (auto M = matchSubHD1(Root)) return M;
  if (auto M = matchSubHD2(Root)) return M;
  if (auto M = matchSubNeg1(Root)) return M;
  return matchSubAddCancel(Root);
}

} // namespace

bool simplifyChernobogSubRules(Function &F, ChernobogSubRuleMetrics &Metrics) {
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
    if (M->IsSubOne) {
      Replacement = M->X;
    } else {
      Replacement = B.CreateSub(M->X, M->Y, "deobf.chernobog.sub");
    }
    Root->replaceAllUsesWith(Replacement);
    Root->eraseFromParent();
    auto &Count = Metrics.Rules[M->Name.str()];
    ++Count.Hits;
    Count.OperationsBefore += Before;
    Count.OperationsAfter += M->IsSubOne ? 0 : 1;
    Changed = true;
  }
  return Changed;
}

} // namespace deobfuscate095
