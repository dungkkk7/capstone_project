#include "RuleCatalogBuilder.h"

namespace deobfuscate095::catalog_detail {

void appendAddRules(std::vector<RuleSpec> &Rules) {
  addRule(Rules, "Add_HackersDelightRule_1", sub(v(0), add(bnot(v(1)), c(1))), add(v(0), v(1)));
  addRule(Rules, "Add_HackersDelightRule_2", add(bor(v(0), v(1)), band(v(0), v(1))), add(v(0), v(1)));
  addRule(Rules, "Add_HackersDelightRule_3", add(bxor(v(0), v(1)), mul(c(2), band(v(0), v(1)))), add(v(0), v(1)));
  addRule(Rules, "Add_HackersDelightRule_4", sub(mul(c(2), bor(v(0), v(1))), bxor(v(0), v(1))), add(v(0), v(1)));
  addRule(Rules, "Add_HackersDelightRule_5", add(mul(c(2), band(v(0), v(1))), bxor(v(0), v(1))), add(v(0), v(1)));
  addRule(Rules, "Add_CarryFreeOrRule", add(v(0), band(v(1), bnot(v(0)))), bor(v(0), v(1)));
  addRule(Rules, "Add_OrNotCarryRule", add(add(bor(v(1), bnot(v(0))), v(0)), c(1)), band(v(0), v(1)));
  addRule(Rules, "Add_DisjointAndRule", add(band(v(0), v(1)), band(bnot(v(0)), v(1))), v(1));
  addRule(Rules, "Add_OllvmRule_1", add(band(v(0), v(1)), bor(v(0), v(1))), add(v(0), v(1)));
  addRule(Rules, "Add_OllvmRule_2", add(bnot(add(bnot(v(0)), bnot(v(1)))), c(1)), add(add(v(0), v(1)), c(2)));
  addRule(Rules, "Add_OllvmRule_3", neg(add(add(bnot(v(0)), bnot(v(1))), c(2))), add(v(0), v(1)));
  addRule(Rules, "Add_OllvmRule_4", add(add(bnot(bor(bnot(v(0)), bnot(v(1)))), bnot(bor(v(0), bnot(v(1))))), c(1)), add(v(1), c(1)));
  addRule(Rules, "Add_SpecialConstantRule_1", add(add(v(0), v(1)), mul(c(-2), band(v(0), v(1)))), bxor(v(0), v(1)));
  addRule(Rules, "Add_SpecialConstantRule_2", add(bxor(v(0), v(1)), mul(c(-2), band(bnot(v(0)), v(1)))), sub(v(0), v(1)));
  addRule(Rules, "Add_FactorRule_1", add(add(bnot(v(0)), bnot(v(1))), c(2)), neg(add(v(0), v(1))));
  addRule(Rules, "Add_FactorRule_2", add(bxor(v(0), bnot(v(1))), mul(c(2), bor(v(0), v(1)))), sub(add(v(0), v(1)), c(1)));
  addRule(Rules, "AddXor_Rule_1", sub(add(v(0), v(1)), bxor(v(0), v(1))), mul(c(2), band(v(0), v(1))));
  addRule(Rules, "AddXor_Rule_2", sub(add(v(0), v(1)), bor(v(0), v(1))), band(v(0), v(1)));
  addRule(Rules, "Add_NegRule_1", sub(v(0), neg(v(1))), add(v(0), v(1)));
  addRule(Rules, "Add_NegRule_2", neg(sub(neg(v(0)), neg(v(1)))), sub(v(0), v(1)));
  addRule(Rules, "Add_NegRule_3", neg(add(neg(v(0)), neg(v(1)))), add(v(0), v(1)));
  addRule(Rules, "Add_ComplexRule_1", add(band(bnot(v(0)), v(1)), bor(v(0), v(1))), add(v(0), mul(c(2), band(bnot(v(0)), v(1)))));
}

} // namespace deobfuscate095::catalog_detail
