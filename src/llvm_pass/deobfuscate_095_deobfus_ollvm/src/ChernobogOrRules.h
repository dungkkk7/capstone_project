#ifndef DEOBFUSCATE_095_CHERNOBOG_OR_RULES_H
#define DEOBFUSCATE_095_CHERNOBOG_OR_RULES_H

#include "llvm/IR/Function.h"
#include <map>
#include <string>

namespace deobfuscate095 {

struct ChernobogOrRuleStat {
  uint64_t Hits = 0;
  uint64_t OperationsBefore = 0;
  uint64_t OperationsAfter = 0;
};

struct ChernobogOrRuleMetrics {
  std::map<std::string, ChernobogOrRuleStat> Rules;
};

bool simplifyChernobogOrRules(llvm::Function &F,
                              ChernobogOrRuleMetrics &Metrics);

} // namespace deobfuscate095

#endif // DEOBFUSCATE_095_CHERNOBOG_OR_RULES_H
