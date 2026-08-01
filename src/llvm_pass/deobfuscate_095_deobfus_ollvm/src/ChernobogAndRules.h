#ifndef DEOBFUSCATE_095_CHERNOBOG_AND_RULES_H
#define DEOBFUSCATE_095_CHERNOBOG_AND_RULES_H

#include <cstdint>
#include <map>
#include <string>

namespace llvm {
class Function;
}

namespace deobfuscate095 {

struct ChernobogAndRuleMetrics {
  struct Count {
    uint64_t Hits = 0;
    uint64_t OperationsBefore = 0;
    uint64_t OperationsAfter = 0;
  };
  std::map<std::string, Count> Rules;
};

// Exact, fail-closed ports of Chernobog And_OllvmRule_1..3.  This layer only
// recognizes those three source expression trees; it performs neither DCE
// nor generic AND/MBA simplification.
bool simplifyChernobogAndRules(llvm::Function &F,
                               ChernobogAndRuleMetrics &Metrics);

} // namespace deobfuscate095

#endif
