#include "RuleEngineInternal.h"
#include "RuleEngineSupport.h"

#include "llvm/ADT/SmallVector.h"

namespace deobfuscate095::rule_detail {
namespace {

using namespace llvm;

bool matchesJnzRule1(ICmpInst &Cmp) {
  if (Cmp.getPredicate() != ICmpInst::ICMP_NE)
    return false;

  auto Matches = [&](Value *Left, Value *Right) {
    auto *Type = dyn_cast<IntegerType>(Left->getType());
    auto NegOpcode = valueOpcode(Left);
    if (!Type || Right->getType() != Type || !NegOpcode ||
        *NegOpcode != Instruction::Sub ||
        !isZero(operand(Left, 0), Type))
      return false;
    Value *AndValue = operand(Left, 1);
    auto AndOpcode = valueOpcode(AndValue);
    if (!AndOpcode || *AndOpcode != Instruction::And)
      return false;
    Value *L = operand(AndValue, 0);
    Value *R = operand(AndValue, 1);
    Value *NotBase = nullptr;
    return (isOne(R, Type) && extractNot(L, NotBase) &&
            sameValue(NotBase, Right)) ||
           (isOne(L, Type) && extractNot(R, NotBase) &&
            sameValue(NotBase, Right));
  };
  return Matches(Cmp.getOperand(0), Cmp.getOperand(1)) ||
         Matches(Cmp.getOperand(1), Cmp.getOperand(0));
}

std::optional<NamedBoolean> matchJumpRule(ICmpInst &Cmp) {
  if (matchesJnzRule1(Cmp))
    return NamedBoolean{"jump.JnzRule1", true};

  Value *Expr = nullptr;
  if (splitZeroComparison(Cmp, Expr)) {
    if (Cmp.getPredicate() == ICmpInst::ICMP_NE &&
        isOrWithOddConstant(Expr))
      return NamedBoolean{"jump.JnzRule2", true};
    if (Cmp.getPredicate() == ICmpInst::ICMP_NE &&
        isOrComplement(Expr))
      return NamedBoolean{"jump.JnzRule3", true};
    if (Cmp.getPredicate() == ICmpInst::ICMP_NE &&
        isXorSelf(Expr))
      return NamedBoolean{"jump.JnzRule4", false};
    if (Cmp.getPredicate() == ICmpInst::ICMP_EQ &&
        isAndComplement(Expr))
      return NamedBoolean{"jump.JzRule1", true};
    if (Cmp.getPredicate() == ICmpInst::ICMP_EQ &&
        isXorSelf(Expr))
      return NamedBoolean{"jump.JzRule2", true};
  }

  if (sameValue(Cmp.getOperand(0), Cmp.getOperand(1))) {
    if (Cmp.getPredicate() == ICmpInst::ICMP_ULT)
      return NamedBoolean{"jump.JbRule1", false};
    if (Cmp.getPredicate() == ICmpInst::ICMP_UGE)
      return NamedBoolean{"jump.JaeRule1", true};
  }

  if ((Cmp.getPredicate() == ICmpInst::ICMP_EQ ||
       Cmp.getPredicate() == ICmpInst::ICMP_NE) &&
      isa<ConstantInt>(Cmp.getOperand(0)) &&
      isa<ConstantInt>(Cmp.getOperand(1)))
    if (std::optional<bool> Folded = evaluateConstantICmp(Cmp))
      return NamedBoolean{"jump.JzConstRule", *Folded};

  return std::nullopt;
}

} // namespace

bool applyJumpRules(Module &M, RuleEngineStats &Stats) {
  SmallVector<BranchInst *, 128> Branches;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (BasicBlock &BB : F)
        if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
            BI && BI->isConditional())
          Branches.push_back(BI);

  bool Changed = false;
  for (BranchInst *BI : Branches) {
    if (!BI->getParent())
      continue;
    auto *Cmp = dyn_cast<ICmpInst>(BI->getCondition());
    if (!Cmp)
      continue;
    ++Stats.PredicateCandidates;
    std::optional<NamedBoolean> Match = matchJumpRule(*Cmp);
    if (!Match)
      continue;
    replaceBranch(*BI, Match->Value);
    ++Stats.PredicateRewrites;
    ++Stats.BranchRewrites;
    ++Stats.Hits[Match->Name];
    Changed = true;
  }
  return Changed;
}

} // namespace deobfuscate095::rule_detail
