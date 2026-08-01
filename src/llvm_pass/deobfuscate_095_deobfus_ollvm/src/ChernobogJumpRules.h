#ifndef DEOBFUSCATE_095_CHERNOBOG_JUMP_RULES_H
#define DEOBFUSCATE_095_CHERNOBOG_JUMP_RULES_H

#include <cstdint>
#include <map>
#include <string>

namespace llvm {
class Function;
}

namespace deobfuscate095 {

struct ChernobogJumpRuleMetrics {
  struct Count {
    uint64_t Hits = 0;
    uint64_t OperationsBefore = 0;
    uint64_t OperationsAfter = 0;
  };
  std::map<std::string, Count> Rules;
};

// Exact, fail-closed ports of Jump & Predicate rules from Chernobog (JnzRule1..4, JzRule1..2, Setz/nz rules).
bool simplifyChernobogJumpRules(llvm::Function &F,
                                ChernobogJumpRuleMetrics &Metrics);

} // namespace deobfuscate095

#endif
