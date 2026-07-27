#include "ChernobogJumpRules.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"

using namespace llvm;

namespace deobfuscate095 {
namespace {

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
  if (!Xor || Xor->getOpcode() != Instruction::Xor)
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

// JzRule1: (x & ~x) == 0 -> always 0 (always true for eq 0)
// JnzRule3: (x | ~x) != 0 -> always -1 (always true for ne 0)
// JzRule2: (x ^ x) == 0 -> always 0 (always true for eq 0)
static bool simplifyPredicateInst(ICmpInst *Cmp, bool &ResultConst) {
  if (!Cmp)
    return false;
  ICmpInst::Predicate Pred = Cmp->getPredicate();
  Value *Op0 = Cmp->getOperand(0);
  Value *Op1 = Cmp->getOperand(1);

  // Self comparison: x == x -> true, x != x -> false, x < x -> false, x >= x -> true
  if (Op0 == Op1) {
    if (Pred == ICmpInst::ICMP_EQ || Pred == ICmpInst::ICMP_SLE || Pred == ICmpInst::ICMP_SGE || Pred == ICmpInst::ICMP_ULE || Pred == ICmpInst::ICMP_UGE) {
      ResultConst = true;
      return true;
    }
    if (Pred == ICmpInst::ICMP_NE || Pred == ICmpInst::ICMP_SLT || Pred == ICmpInst::ICMP_SGT || Pred == ICmpInst::ICMP_ULT || Pred == ICmpInst::ICMP_UGT) {
      ResultConst = false;
      return true;
    }
  }

  // (x & ~x) == 0 -> true (JzRule1)
  if (isIntegerConstant(Op1, 0) || isIntegerConstant(Op0, 0)) {
    Value *Expr = isIntegerConstant(Op1, 0) ? Op0 : Op1;
    if (auto *BO = dyn_cast<BinaryOperator>(Expr)) {
      if (BO->getOpcode() == Instruction::And) {
        Value *A = BO->getOperand(0);
        Value *B = BO->getOperand(1);
        Value *Input = nullptr;
        if ((matchNot(B, Input) && Input == A) || (matchNot(A, Input) && Input == B)) {
          if (Pred == ICmpInst::ICMP_EQ) {
            ResultConst = true;
            return true;
          }
          if (Pred == ICmpInst::ICMP_NE) {
            ResultConst = false;
            return true;
          }
        }
      }
      // (x ^ x) == 0 -> true (JzRule2)
      if (BO->getOpcode() == Instruction::Xor) {
        if (BO->getOperand(0) == BO->getOperand(1)) {
          if (Pred == ICmpInst::ICMP_EQ) {
            ResultConst = true;
            return true;
          }
          if (Pred == ICmpInst::ICMP_NE) {
            ResultConst = false;
            return true;
          }
        }
      }
    }
  }
  return false;
}

} // namespace

bool simplifyChernobogJumpRules(Function &F, ChernobogJumpRuleMetrics &Metrics) {
  bool Changed = false;
  SmallVector<BranchInst *, 32> Branches;
  for (Instruction &I : instructions(F)) {
    if (auto *Br = dyn_cast<BranchInst>(&I))
      if (Br->isConditional())
        Branches.push_back(Br);
  }

  for (BranchInst *Br : Branches) {
    auto *Cmp = dyn_cast<ICmpInst>(Br->getCondition());
    if (!Cmp)
      continue;
    bool ResultConst = false;
    if (simplifyPredicateInst(Cmp, ResultConst)) {
      BasicBlock *Target = ResultConst ? Br->getSuccessor(0) : Br->getSuccessor(1);
      IRBuilder<> B(Br);
      B.CreateBr(Target);
      Br->eraseFromParent();
      if (Cmp->use_empty())
        Cmp->eraseFromParent();
      Metrics.Rules["JumpOptimizationRule"].Hits++;
      Changed = true;
    }
  }
  return Changed;
}

} // namespace deobfuscate095
