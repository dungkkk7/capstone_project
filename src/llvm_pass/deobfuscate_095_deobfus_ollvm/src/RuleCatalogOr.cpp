#include "RuleCatalogBuilder.h"

namespace deobfuscate095::catalog_detail {

void appendOrRules(std::vector<RuleSpec> &Rules) {
  addRule(Rules, "Or_HackersDelightRule_1", add(band(v(0), v(1)), bxor(v(0), v(1))), bor(v(0), v(1)));
  addRule(Rules, "Or_HackersDelightRule_2", sub(add(v(0), v(1)), band(v(0), v(1))), bor(v(0), v(1)));
  addRule(Rules, "Or_MbaRule_1", bnot(band(bnot(v(0)), bnot(v(1)))), bor(v(0), v(1)));
  addRule(Rules, "Or_MbaRule_2", bor(bxor(v(0), v(1)), band(v(0), v(1))), bor(v(0), v(1)));
  addRule(Rules, "Or_MbaRule_3", bor(band(v(0), v(1)), bxor(v(0), v(1))), bor(v(0), v(1)));
  addRule(Rules, "Or_FactorRule_1", bor(v(0), band(v(0), v(1))), v(0));
  addRule(Rules, "Or_FactorRule_2", bor(band(v(0), v(1)), v(0)), v(0));
  addRule(Rules, "Or_FactorRule_3", bor(bor(v(0), v(1)), band(v(0), v(1))), bor(v(0), v(1)));
  addRule(Rules, "Or_OllvmRule_1", bor(bor(band(bnot(v(0)), v(1)), band(v(0), bnot(v(1)))), band(v(0), v(1))), bor(v(0), v(1)));
  addRule(Rules, "OrBnot_FactorRule_1", bor(bnot(v(0)), bnot(v(1))), bnot(band(v(0), v(1))));
  addRule(Rules, "OrBnot_FactorRule_2", bor(v(0), bnot(v(0))), c(-1));
  addRule(Rules, "OrBnot_FactorRule_3", bor(bnot(v(0)), v(0)), c(-1));
  addRule(Rules, "Or_Rule_1", bor(v(0), v(0)), v(0));
  addRule(Rules, "Or_Rule_2", bor(v(0), c(0)), v(0));
  addRule(Rules, "Or_Rule_3", bor(v(0), c(-1)), c(-1));
}

} // namespace deobfuscate095::catalog_detail
