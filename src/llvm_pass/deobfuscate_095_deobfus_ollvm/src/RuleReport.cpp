#include "Deobfuscate095Internal.h"

#include "llvm/Support/FileSystem.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/raw_ostream.h"

namespace deobfuscate095 {

using namespace llvm;

void writeRuleReport(const Module &M,
                     const RuleEngineStats &Rules,
                     const CatalogVerification &Catalog,
                     const MatcherVerification &Matcher,
                     bool CatalogWasVerified,
                     bool FallbackEnabled,
                     const FallbackConfig &Config,
                     const FallbackMetrics &Fallback,
                     const ProofStats &Proofs,
                     StringRef ReportPath) {
  if (ReportPath.empty())
    return;

  std::error_code EC;
  raw_fd_ostream OS(ReportPath, EC, sys::fs::OF_Text);
  if (EC) {
    errs() << "095: cannot write report '" << ReportPath
           << "': " << EC.message() << "\n";
    return;
  }

  json::OStream J(OS, 2);
  J.object([&] {
    J.attribute("schema",
                "deobfuscate-095-rule-first-v3");
    J.attribute("module", M.getModuleIdentifier());
    J.attribute("unknown_is_evidence", false);

    J.attributeObject("source_catalog", [&] {
      J.attribute("repository",
                  kChernobogCatalogRepository);
      J.attribute("revision",
                  kChernobogCatalogRevision);
      J.attribute("implementation",
                  "independent-llvm-rule-port");
    });

    J.attributeObject("catalog", [&] {
      J.attribute("mba_registered",
                  static_cast<int64_t>(ruleCatalog().size()));
      J.attribute("predicate_registered",
                  static_cast<int64_t>(22));
      J.attribute("jump_registered",
                  static_cast<int64_t>(9));
      J.attribute("verification_requested",
                  CatalogWasVerified);
      J.attribute("verified",
                  static_cast<int64_t>(Catalog.Verified));
      J.attribute("rejected",
                  static_cast<int64_t>(Catalog.Rejected));
      J.attribute("width_checks",
                  static_cast<int64_t>(Catalog.WidthChecks));
      J.attribute("matcher_verified",
                  static_cast<int64_t>(Matcher.Verified));
      J.attribute("matcher_rejected",
                  static_cast<int64_t>(Matcher.Rejected));
      J.attributeArray("rejected_rules", [&] {
        for (const std::string &Name :
             Catalog.RejectedRules)
          J.value(Name);
      });
      J.attributeArray("matcher_rejected_rules", [&] {
        for (const std::string &Name :
             Matcher.RejectedRules)
          J.value(Name);
      });
    });

    J.attributeObject("rule_engine", [&] {
      J.attribute("rounds",
                  static_cast<int64_t>(Rules.Rounds));
      J.attribute("attempts",
                  static_cast<int64_t>(Rules.Attempts));
      J.attribute("structural_matches",
                  static_cast<int64_t>(
                      Rules.StructuralMatches));
      J.attribute("mba_rewrites",
                  static_cast<int64_t>(
                      Rules.RuleRewrites));
      J.attribute("predicate_candidates",
                  static_cast<int64_t>(
                      Rules.PredicateCandidates));
      J.attribute("predicate_rewrites",
                  static_cast<int64_t>(
                      Rules.PredicateRewrites));
      J.attribute("branch_rewrites",
                  static_cast<int64_t>(
                      Rules.BranchRewrites));
      J.attribute("select_rewrites",
                  static_cast<int64_t>(
                      Rules.SelectRewrites));
      J.attributeObject("hits", [&] {
        for (const auto &Entry : Rules.Hits)
          J.attribute(Entry.first,
                      static_cast<int64_t>(Entry.second));
      });
    });

    J.attributeObject("z3_fallback", [&] {
      J.attribute("enabled", FallbackEnabled);
      J.attribute("predicate_limit",
                  static_cast<int64_t>(
                      Config.PredicateLimit));
      J.attribute("mba_limit",
                  static_cast<int64_t>(Config.MBALimit));
      J.attribute("predicate_candidates",
                  static_cast<int64_t>(
                      Fallback.PredicateCandidates));
      J.attribute("predicate_proofs",
                  static_cast<int64_t>(
                      Fallback.PredicateProofs));
      J.attribute("mba_candidates",
                  static_cast<int64_t>(
                      Fallback.MBACandidates));
      J.attribute("mba_proofs",
                  static_cast<int64_t>(
                      Fallback.MBAProofs));
      J.attribute("queries",
                  static_cast<int64_t>(Proofs.Queries));
      J.attribute("proved",
                  static_cast<int64_t>(Proofs.Proved));
      J.attribute("disproved",
                  static_cast<int64_t>(Proofs.Disproved));
      J.attribute("unknown",
                  static_cast<int64_t>(Proofs.Unknown));
      J.attribute("unknown_is_evidence", false);
    });
  });
}

} // namespace deobfuscate095
