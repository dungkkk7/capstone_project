#ifndef DEOBFUSCATE_095_RULE_ENGINE_H
#define DEOBFUSCATE_095_RULE_ENGINE_H

#include "RuleCatalog.h"

#include "llvm/IR/Module.h"

#include <cstdint>
#include <map>
#include <string>
#include <vector>

namespace deobfuscate095 {

struct RuleEngineStats {
  uint64_t Rounds = 0;
  uint64_t Attempts = 0;
  uint64_t StructuralMatches = 0;
  uint64_t RuleRewrites = 0;
  uint64_t PredicateCandidates = 0;
  uint64_t PredicateRewrites = 0;
  uint64_t BranchRewrites = 0;
  uint64_t SelectRewrites = 0;
  std::map<std::string, uint64_t> Hits;
};

struct MatcherVerification {
  uint64_t Registered = 0;
  uint64_t Verified = 0;
  uint64_t Rejected = 0;
  std::vector<std::string> RejectedRules;
};

MatcherVerification verifyRuleMatcherCatalog(llvm::LLVMContext &Context);

class RuleEngine {
public:
  explicit RuleEngine(bool EnableMBA = true) : EnableMBA(EnableMBA) {}

  bool run(llvm::Module &M, unsigned MaxRounds, RuleEngineStats &Stats) const;

private:
  bool EnableMBA;
};

} // namespace deobfuscate095

#endif
