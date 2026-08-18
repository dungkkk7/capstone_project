#include "RuleCatalogBuilder.h"

namespace deobfuscate095::catalog_detail {

void appendAndRules(std::vector<RuleSpec> &Rules) {
  addRule(Rules, "And_HackersDelightRule_1", sub(add(v(0), v(1)), bor(v(0), v(1))), band(v(0), v(1)));
  addRule(Rules, "And_HackersDelightRule_2", sub(bor(v(0), v(1)), bxor(v(0), v(1))), band(v(0), v(1)));
  addRule(Rules, "And_HackersDelightRule_3", bnot(bor(bnot(v(0)), bnot(v(1)))), band(v(0), v(1)));
  addRule(Rules, "And_HackersDelightRule_4", band(bxor(v(0), bnot(v(1))), v(0)), band(v(0), v(1)));
  addRule(Rules, "And_OllvmRule_1", band(bor(v(0), v(1)), bnot(bxor(v(0), v(1)))), band(v(0), v(1)));
  addRule(Rules, "And_OllvmRule_2", band(bnot(bxor(v(0), v(1))), bor(v(0), v(1))), band(v(0), v(1)));
  addRule(Rules, "And_OllvmRule_3", band(band(bor(bnot(v(0)), v(1)), bor(v(0), bnot(v(1)))), bor(v(0), v(1))), band(v(0), v(1)));
  addRule(Rules, "And_FactorRule_1", band(v(0), bor(v(0), v(1))), v(0));
  addRule(Rules, "And_FactorRule_2", band(bor(v(0), v(1)), v(0)), v(0));
  addRule(Rules, "AndBnot_FactorRule_1", band(bnot(v(0)), bnot(v(1))), bnot(bor(v(0), v(1))));
  addRule(Rules, "AndBnot_FactorRule_2", band(v(0), bnot(v(0))), c(0));
  addRule(Rules, "AndBnot_FactorRule_3", band(bnot(v(0)), v(0)), c(0));
  addRule(Rules, "AndBnot_FactorRule_4", band(bxor(v(0), v(1)), bnot(v(1))), band(v(0), bnot(v(1))));
  addRule(Rules, "AndOr_FactorRule_1", band(bor(v(0), v(1)), bor(v(0), bnot(v(1)))), v(0));
  addRule(Rules, "AndXor_FactorRule_1", band(band(v(0), v(1)), bor(v(0), v(1))), band(v(0), v(1)));
  addRule(Rules, "And_Rule_1", band(v(0), v(0)), v(0));
  addRule(Rules, "And_Rule_2", band(v(0), c(0)), c(0));
  addRule(Rules, "And_Rule_3", band(v(0), c(-1)), v(0));
}

} // namespace deobfuscate095::catalog_detail
