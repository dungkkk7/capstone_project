#ifndef DEOBFUSCATE_095_CHERNOBOG_MISC_RULES_H
#define DEOBFUSCATE_095_CHERNOBOG_MISC_RULES_H

#include "llvm/IR/Function.h"
#include <map>
#include <string>

namespace deobfuscate095 {

struct ChernobogMiscRuleStat {
  uint64_t Hits = 0;
  uint64_t OperationsBefore = 0;
  uint64_t OperationsAfter = 0;
};

struct ChernobogMiscRuleMetrics {
  std::map<std::string, ChernobogMiscRuleStat> Rules;
};

bool simplifyChernobogMiscRules(llvm::Function &F,
                                ChernobogMiscRuleMetrics &Metrics);

} // namespace deobfuscate095

#endif // DEOBFUSCATE_095_CHERNOBOG_MISC_RULES_H
