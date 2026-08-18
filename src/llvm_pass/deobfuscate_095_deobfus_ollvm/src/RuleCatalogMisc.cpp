#include "RuleCatalogBuilder.h"

namespace deobfuscate095::catalog_detail {

void appendMiscRules(std::vector<RuleSpec> &Rules) {
  addRule(Rules, "Bnot_HackersDelightRule_1", bnot(bnot(v(0))), v(0));
  addRule(Rules, "Bnot_HackersDelightRule_2", sub(neg(v(0)), c(1)), bnot(v(0)));
  addRule(Rules, "Bnot_FactorRule_1", bnot(sub(v(0), c(1))), neg(v(0)));
  addRule(Rules, "Bnot_FactorRule_2", bnot(add(v(0), c(1))), sub(neg(v(0)), c(2)));
  addRule(Rules, "BnotXor_Rule_1", bxor(bnot(v(0)), v(1)), bnot(bxor(v(0), v(1))));
  addRule(Rules, "BnotXor_Rule_2", bxor(v(0), bnot(v(1))), bnot(bxor(v(0), v(1))));
  addRule(Rules, "Neg_HackersDelightRule_1", neg(neg(v(0))), v(0));
  addRule(Rules, "Neg_HackersDelightRule_2", add(bnot(v(0)), c(1)), neg(v(0)));
  addRule(Rules, "NegSub_HackersDelightRule_1", neg(sub(v(0), v(1))), sub(v(1), v(0)));
  addRule(Rules, "NegAdd_HackersDelightRule_1", neg(add(v(0), v(1))), sub(neg(v(0)), v(1)));
  addRule(Rules, "Neg_Rule_1", neg(c(0)), c(0));
  addRule(Rules, "Mul_Rule_1", mul(v(0), c(0)), c(0));
  addRule(Rules, "Mul_Rule_2", mul(v(0), c(1)), v(0));
  addRule(Rules, "Mul_Rule_3", mul(v(0), c(2)), add(v(0), v(0)));
  addRule(Rules, "Mul_Rule_4", mul(v(0), c(-1)), neg(v(0)));
  addRule(Rules, "Mul_FactorRule_1", mul(neg(v(0)), v(1)), neg(mul(v(0), v(1))));
  addRule(Rules, "Mul_FactorRule_2", mul(neg(v(0)), neg(v(1))), mul(v(0), v(1)));
  addRule(Rules, "Const_AddZero", add(v(0), c(0)), v(0));
  addRule(Rules, "Const_ZeroAdd", add(c(0), v(0)), v(0));
  addRule(Rules, "Const_OrSelf", bor(v(0), v(0)), v(0));
  addRule(Rules, "Const_AndSelf", band(v(0), v(0)), v(0));
}

} // namespace deobfuscate095::catalog_detail
