#ifndef DEOBFUSCATE_095_CHERNOBOG_SUB_RULES_H
#define DEOBFUSCATE_095_CHERNOBOG_SUB_RULES_H

#include "llvm/IR/Function.h"
#include <map>
#include <string>

namespace deobfuscate095 {

struct ChernobogSubRuleStat {
  uint64_t Hits = 0;
  uint64_t OperationsBefore = 0;
  uint64_t OperationsAfter = 0;
};

struct ChernobogSubRuleMetrics {
  std::map<std::string, ChernobogSubRuleStat> Rules;
};

bool simplifyChernobogSubRules(llvm::Function &F,
                               ChernobogSubRuleMetrics &Metrics);

} // namespace deobfuscate095

#endif // DEOBFUSCATE_095_CHERNOBOG_SUB_RULES_H
