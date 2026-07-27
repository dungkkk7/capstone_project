#ifndef DEOBFUSCATE_095_CHERNOBOG_XOR_RULES_H
#define DEOBFUSCATE_095_CHERNOBOG_XOR_RULES_H

#include <cstdint>
#include <map>
#include <string>

namespace llvm {
class Function;
}

namespace deobfuscate095 {

// Kept separate from the generic MBA counters: each entry is evidence for an
// exact source rule, rather than a simplification LLVM happened to perform.
struct ChernobogXorRuleMetrics {
  struct Count {
    uint64_t Hits = 0;
    uint64_t OperationsBefore = 0;
    uint64_t OperationsAfter = 0;
  };
  std::map<std::string, Count> Rules;
};

// Exact, fail-closed ports of Chernobog Xor_OllvmRule_1..3.  Only pure scalar
// integer DAG roots with defined leaves are eligible.  This function neither
// performs DCE nor recognizes any other XOR/MBA family.
bool simplifyChernobogXorRules(llvm::Function &F,
                               ChernobogXorRuleMetrics &Metrics);

} // namespace deobfuscate095

#endif
