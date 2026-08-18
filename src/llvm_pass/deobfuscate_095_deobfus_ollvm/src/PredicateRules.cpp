#include "RuleEngineInternal.h"
#include "RuleEngineSupport.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/InstIterator.h"

namespace deobfuscate095::rule_detail {
namespace {

using namespace llvm;

std::optional<NamedBoolean> matchPredicateRule(ICmpInst &Cmp) {
  if (!Cmp.getOperand(0)->getType()->isIntegerTy() ||
      isDirectlyIndeterminate(Cmp.getOperand(0)) ||
      isDirectlyIndeterminate(Cmp.getOperand(1)))
    return std::nullopt;

  if (sameValue(Cmp.getOperand(0), Cmp.getOperand(1))) {
    switch (Cmp.getPredicate()) {
    case ICmpInst::ICMP_EQ:
      return NamedBoolean{"predicate.SetzSelfRule", true};
    case ICmpInst::ICMP_NE:
      return NamedBoolean{"predicate.SetnzSelfRule", false};
    case ICmpInst::ICMP_ULT:
      return NamedBoolean{"predicate.SetbSelfRule", false};
    case ICmpInst::ICMP_UGE:
      return NamedBoolean{"predicate.SetaeSelfRule", true};
    case ICmpInst::ICMP_UGT:
      return NamedBoolean{"predicate.SetaSelfRule", false};
    case ICmpInst::ICMP_ULE:
      return NamedBoolean{"predicate.SetbeSelfRule", true};
    case ICmpInst::ICMP_SLT:
      return NamedBoolean{"predicate.SetlSelfRule", false};
    case ICmpInst::ICMP_SGE:
      return NamedBoolean{"predicate.SetgeSelfRule", true};
    case ICmpInst::ICMP_SGT:
      return NamedBoolean{"predicate.SetgSelfRule", false};
    case ICmpInst::ICMP_SLE:
      return NamedBoolean{"predicate.SetleSelfRule", true};
    default:
      break;
    }
  }

  Value *Expr = nullptr;
  if (splitZeroComparison(Cmp, Expr)) {
    if (Cmp.getPredicate() == ICmpInst::ICMP_EQ &&
        isAndComplement(Expr))
      return NamedBoolean{
          "predicate.SetzAndComplementRule", true};
    if (Cmp.getPredicate() == ICmpInst::ICMP_NE &&
        isOrComplement(Expr))
      return NamedBoolean{
          "predicate.SetnzOrComplementRule", true};
    if (Cmp.getPredicate() == ICmpInst::ICMP_EQ &&
        isXorSelf(Expr))
      return NamedBoolean{"predicate.SetzXorSelfRule", true};
    if (Cmp.getPredicate() == ICmpInst::ICMP_NE &&
        isXorSelf(Expr))
      return NamedBoolean{"predicate.SetnzXorSelfRule", false};
    if (Cmp.getPredicate() == ICmpInst::ICMP_NE &&
        isOrWithAllOnes(Expr))
      return NamedBoolean{
          "predicate.SetnzOrMinusOneRule", true};
    if (Cmp.getPredicate() == ICmpInst::ICMP_NE &&
        isOrWithOddConstant(Expr))
      return NamedBoolean{"predicate.SetnzOrOneRule", true};
    if (Cmp.getPredicate() == ICmpInst::ICMP_EQ &&
        isAndWithZero(Expr))
      return NamedBoolean{"predicate.SetzAndZeroRule", true};
  }

  auto *Type =
      dyn_cast<IntegerType>(Cmp.getOperand(1)->getType());
  if (Type && isZero(Cmp.getOperand(1), Type)) {
    if (Cmp.getPredicate() == ICmpInst::ICMP_ULT)
      return NamedBoolean{"predicate.SetbZeroRule", false};
    if (Cmp.getPredicate() == ICmpInst::ICMP_UGE)
      return NamedBoolean{"predicate.SetaeZeroRule", true};
  }

  if (std::optional<bool> Folded = evaluateConstantICmp(Cmp))
    return NamedBoolean{"predicate.SetConstRule", *Folded};

  return std::nullopt;
}

} // namespace

bool applyPredicateRules(Module &M, RuleEngineStats &Stats) {
  SmallVector<ICmpInst *, 256> Comparisons;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (Instruction &I : instructions(F))
        if (auto *Cmp = dyn_cast<ICmpInst>(&I))
          Comparisons.push_back(Cmp);

  bool Changed = false;
  for (ICmpInst *Cmp : Comparisons) {
    if (!Cmp->getParent() || Cmp->use_empty())
      continue;
    ++Stats.PredicateCandidates;
    std::optional<NamedBoolean> Match =
        matchPredicateRule(*Cmp);
    if (!Match)
      continue;
    Cmp->replaceAllUsesWith(ConstantInt::get(
        Type::getInt1Ty(M.getContext()), Match->Value));
    Cmp->eraseFromParent();
    ++Stats.PredicateRewrites;
    ++Stats.Hits[Match->Name];
    Changed = true;
  }
  return Changed;
}

bool applyLogicalNotRules(Module &M, RuleEngineStats &Stats) {
  SmallVector<BinaryOperator *, 32> Worklist;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (Instruction &I : instructions(F))
        if (auto *BO = dyn_cast<BinaryOperator>(&I);
            BO && BO->getOpcode() == Instruction::Xor &&
            BO->getType()->isIntegerTy(1))
          Worklist.push_back(BO);

  bool Changed = false;
  for (BinaryOperator *BO : Worklist) {
    if (!BO->getParent() || BO->use_empty())
      continue;
    auto *L = dyn_cast<ConstantInt>(BO->getOperand(0));
    auto *R = dyn_cast<ConstantInt>(BO->getOperand(1));
    if (!L || !R || (!L->isOne() && !R->isOne()))
      continue;

    bool Input = L->isOne() ? !R->isZero() : !L->isZero();
    bool Value = !Input;
    const char *Name = Input ? "predicate.LnotOneRule"
                             : "predicate.LnotZeroRule";
    BO->replaceAllUsesWith(ConstantInt::get(
        cast<IntegerType>(BO->getType()), Value));
    BO->eraseFromParent();
    ++Stats.PredicateCandidates;
    ++Stats.PredicateRewrites;
    ++Stats.Hits[Name];
    Changed = true;
  }
  return Changed;
}

} // namespace deobfuscate095::rule_detail
