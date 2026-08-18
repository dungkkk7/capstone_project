#include "RuleCatalogBuilder.h"

namespace deobfuscate095::catalog_detail {

void appendSubRules(std::vector<RuleSpec> &Rules) {
  addRule(Rules, "Sub_HackersDelightRule_1", add(add(v(0), bnot(v(1))), c(1)), sub(v(0), v(1)));
  addRule(Rules, "Sub_HackersDelightRule_2", bnot(add(bnot(v(0)), v(1))), sub(v(0), v(1)));
  addRule(Rules, "Sub_HackersDelightRule_3", sub(bxor(v(0), v(1)), mul(c(2), band(bnot(v(0)), v(1)))), sub(v(0), v(1)));
  addRule(Rules, "Sub_HackersDelightRule_4", add(neg(mul(c(2), band(bnot(v(0)), v(1)))), bxor(v(0), v(1))), sub(v(0), v(1)));
  addRule(Rules, "Sub1_FactorRule_1", bnot(add(bnot(v(0)), c(1))), sub(v(0), c(1)));
  addRule(Rules, "Sub1_FactorRule_2", add(v(0), c(-1)), sub(v(0), c(1)));
  addRule(Rules, "Sub_NegRule_1", add(v(0), neg(v(1))), sub(v(0), v(1)));
  addRule(Rules, "Sub_NegRule_2", add(neg(v(1)), v(0)), sub(v(0), v(1)));
  addRule(Rules, "Sub_SpecialConstantRule_1", add(bxor(v(0), v(1)), mul(c(-2), band(bnot(v(0)), v(1)))), sub(v(0), v(1)));
  addRule(Rules, "Sub_Rule_1", sub(v(0), c(0)), v(0));
  addRule(Rules, "Sub_Rule_2", sub(v(0), v(0)), c(0));
  addRule(Rules, "Sub_Rule_3", sub(c(0), v(0)), neg(v(0)));
  addRule(Rules, "Sub_AddCancelRule", sub(add(v(0), v(1)), v(1)), v(0));
}

} // namespace deobfuscate095::catalog_detail
