#include "RuleCatalogBuilder.h"

namespace deobfuscate095::catalog_detail {

void appendXorRules(std::vector<RuleSpec> &Rules) {
  addRule(Rules, "Xor_HackersDelightRule_1", sub(bor(v(0), v(1)), band(v(0), v(1))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_HackersDelightRule_2", band(bor(v(0), v(1)), bor(bnot(v(0)), bnot(v(1)))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_HackersDelightRule_3", bor(band(bnot(v(0)), v(1)), band(v(0), bnot(v(1)))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_HackersDelightRule_4", sub(add(v(0), v(1)), mul(c(2), band(v(0), v(1)))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_HackersDelightRule_5", sub(mul(c(2), bor(v(0), v(1))), add(v(0), v(1))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_MbaRule_1", band(bor(v(0), v(1)), bnot(band(v(0), v(1)))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_MbaRule_2", band(bnot(band(v(0), v(1))), bor(v(0), v(1))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_MbaRule_3", bor(bnot(bor(bnot(v(0)), bnot(v(1)))), bnot(bor(v(0), v(1)))), bnot(bxor(v(0), v(1))));
  addRule(Rules, "Xor_FactorRule_1", bor(band(v(0), bnot(v(1))), band(bnot(v(0)), v(1))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_FactorRule_2", bor(bnot(bor(v(0), v(1))), band(v(0), v(1))), bnot(bxor(v(0), v(1))));
  addRule(Rules, "Xor_FactorRule_3", bor(band(v(0), v(1)), bnot(bor(v(0), v(1)))), bnot(bxor(v(0), v(1))));
  addRule(Rules, "Xor_OllvmRule_1", band(bor(bnot(v(0)), v(1)), bor(v(0), bnot(v(1)))), bnot(bxor(v(0), v(1))));
  addRule(Rules, "Xor_OllvmRule_2", band(bor(v(0), bnot(v(1))), bor(bnot(v(0)), v(1))), bnot(bxor(v(0), v(1))));
  addRule(Rules, "Xor_OllvmRule_3", band(bnot(band(bnot(v(0)), bnot(v(1)))), bnot(band(v(0), v(1)))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_SpecialConstantRule_1", add(add(v(0), v(1)), mul(c(-2), band(v(0), v(1)))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_SpecialConstantRule_2", add(bor(v(0), v(1)), mul(c(-1), band(v(0), v(1)))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_Rule_1", bxor(bnot(v(0)), bnot(v(1))), bxor(v(0), v(1)));
  addRule(Rules, "Xor_Rule_2", bxor(v(0), c(0)), v(0));
  addRule(Rules, "Xor_Rule_3", bxor(v(0), v(0)), c(0));
}

} // namespace deobfuscate095::catalog_detail
