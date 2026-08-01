#ifndef DEOBFUSCATE_095_CHERNOBOG_ADD_RULES_H
#define DEOBFUSCATE_095_CHERNOBOG_ADD_RULES_H

#include <cstdint>
#include <map>
#include <string>

namespace llvm {
class Function;
}

namespace deobfuscate095 {

// Evidence is deliberately per source rule.  This prevents a generic LLVM
// simplification from being reported as coverage for a Chernobog rule.
struct ChernobogAddRuleMetrics {
  struct Count {
    uint64_t Hits = 0;
    uint64_t OperationsBefore = 0;
    uint64_t OperationsAfter = 0;
  };
  std::map<std::string, Count> Rules;
};

// Exact, fail-closed ports of Add_OllvmRule_1..4 from Chernobog.  This owns
// only pure scalar integer DAGs; it never performs cleanup or DCE.
bool simplifyChernobogAddRules(llvm::Function &F,
                               ChernobogAddRuleMetrics &Metrics);

} // namespace deobfuscate095

#endif
