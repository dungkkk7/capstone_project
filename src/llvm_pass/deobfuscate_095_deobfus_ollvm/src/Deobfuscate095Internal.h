#ifndef DEOBFUSCATE_095_INTERNAL_H
#define DEOBFUSCATE_095_INTERNAL_H

#include "RuleCatalog.h"
#include "RuleEngine.h"
#include "Z3Prover.h"

#include "llvm/IR/Module.h"

#include <cstdint>

namespace deobfuscate095 {

struct FallbackConfig {
  unsigned PredicateLimit = 0;
  unsigned MBALimit = 0;
  unsigned MBARecipes = 24;
  unsigned TimeoutMs = 50;
  bool DisableMBA = false;
};

struct FallbackMetrics {
  uint64_t PredicateCandidates = 0;
  uint64_t PredicateProofs = 0;
  uint64_t MBACandidates = 0;
  uint64_t MBAProofs = 0;
};

bool runZ3Fallback(llvm::Module &M, const FallbackConfig &Config,
                   FallbackMetrics &Metrics, ProofStats &Proofs);

void writeRuleReport(const llvm::Module &M,
                     const RuleEngineStats &Rules,
                     const CatalogVerification &Catalog,
                     const MatcherVerification &Matcher,
                     bool CatalogWasVerified,
                     bool FallbackEnabled,
                     const FallbackConfig &Config,
                     const FallbackMetrics &Fallback,
                     const ProofStats &Proofs,
                     llvm::StringRef ReportPath);

} // namespace deobfuscate095

#endif
