#include "Deobfuscate095.h"
#include "Deobfuscate095Internal.h"

#include "llvm/IR/Verifier.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <cstdint>

namespace deobfuscate095 {
namespace {

using namespace llvm;

static cl::opt<std::string> ReportPath(
    "095-report",
    cl::desc("Write rule-first 095 JSON evidence here"),
    cl::init(""));
static cl::opt<unsigned> Z3TimeoutMs(
    "095-z3-timeout-ms",
    cl::desc("Per-query timeout for the optional Z3 fallback"),
    cl::init(50));
static cl::opt<unsigned> MaxRounds(
    "095-max-rounds",
    cl::desc("Maximum deterministic rule-engine fixpoint rounds"),
    cl::init(12));
static cl::opt<bool> EnableZ3Fallback(
    "095-enable-z3-fallback",
    cl::desc("Enable bounded Z3 after deterministic rules"),
    cl::init(false));
static cl::opt<unsigned> MaxMBACandidates(
    "095-max-mba-candidates",
    cl::desc("Unmatched MBA expressions sent to Z3"),
    cl::init(0));
static cl::opt<unsigned> MaxPredicateZ3Candidates(
    "095-max-predicate-z3-candidates",
    cl::desc("Unmatched predicates sent to Z3"),
    cl::init(0));
static cl::opt<unsigned> MaxMBARecipes(
    "095-max-mba-recipes-per-expression",
    cl::desc("Z3 fallback recipes per expression"),
    cl::init(24));
static cl::opt<bool> DisableMBA(
    "095-disable-mba",
    cl::desc("Disable MBA catalog and MBA Z3 fallback"),
    cl::init(false), cl::Hidden);
static cl::opt<bool> DisableDeflatten(
    "095-disable-deflatten",
    cl::desc("Compatibility option; CFG belongs to pass 020"),
    cl::init(false), cl::Hidden);
static cl::opt<unsigned> LegacyMaxZ3Candidates(
    "095-max-z3-candidates",
    cl::desc("Deprecated alias for the MBA fallback limit"),
    cl::init(0), cl::Hidden);
static cl::opt<unsigned> LegacyMaxOpaqueCandidates(
    "095-max-opaque-z3-candidates",
    cl::desc("Deprecated alias for predicate fallback limit"),
    cl::init(0), cl::Hidden);
static cl::opt<bool> VerifyCatalog(
    "095-verify-rule-catalog",
    cl::desc("Prove all 108 rules and matcher registrations"),
    cl::init(false));
static cl::opt<unsigned> CatalogTimeoutMs(
    "095-rule-catalog-timeout-ms",
    cl::desc("Per-width catalog proof timeout"),
    cl::init(1000));

void verifyOrDie(Module &M, StringRef Stage) {
  std::string Error;
  raw_string_ostream OS(Error);
  if (!verifyModule(M, &OS))
    return;
  report_fatal_error(
      Twine("095 produced invalid IR after ") + Stage +
      ":\n" + OS.str());
}

FallbackConfig fallbackConfig() {
  FallbackConfig Config;
  Config.TimeoutMs = Z3TimeoutMs;
  Config.PredicateLimit =
      MaxPredicateZ3Candidates != 0
          ? unsigned(MaxPredicateZ3Candidates)
          : unsigned(LegacyMaxOpaqueCandidates);
  Config.MBALimit =
      MaxMBACandidates != 0
          ? unsigned(MaxMBACandidates)
          : unsigned(LegacyMaxZ3Candidates);
  Config.MBARecipes = MaxMBARecipes;
  Config.DisableMBA = DisableMBA;
  return Config;
}

} // namespace

llvm::PreservedAnalyses
Deobfuscate095Pass::run(llvm::Module &M,
                        llvm::ModuleAnalysisManager &) {
  (void)DisableDeflatten;

  CatalogVerification Catalog;
  Catalog.Registered = ruleCatalog().size();
  MatcherVerification Matcher;
  Matcher.Registered = ruleCatalog().size();

  if (VerifyCatalog) {
    Catalog = verifyRuleCatalog(CatalogTimeoutMs);
    Matcher = verifyRuleMatcherCatalog(M.getContext());
    if (Catalog.Registered != 108 ||
        Catalog.Verified != 108 ||
        Catalog.Rejected != 0 ||
        Matcher.Registered != 108 ||
        Matcher.Verified != 108 ||
        Matcher.Rejected != 0)
      report_fatal_error(
          "095 rule catalog certification failed");
  }

  RuleEngineStats RuleStats;
  RuleEngine Engine(!DisableMBA);
  bool AnyChanged =
      Engine.run(M, MaxRounds, RuleStats);
  verifyOrDie(M, "deterministic rule fixpoint");

  const FallbackConfig Config = fallbackConfig();
  FallbackMetrics Fallback;
  ProofStats Proofs;
  if (EnableZ3Fallback &&
      (Config.PredicateLimit != 0 ||
       (!Config.DisableMBA && Config.MBALimit != 0))) {
    bool FallbackChanged =
        runZ3Fallback(M, Config, Fallback, Proofs);
    if (FallbackChanged) {
      AnyChanged = true;
      verifyOrDie(M, "optional Z3 fallback");
      AnyChanged |= Engine.run(M, MaxRounds, RuleStats);
      verifyOrDie(M, "post-fallback rule fixpoint");
    }
  }

  writeRuleReport(M, RuleStats, Catalog, Matcher,
                  VerifyCatalog, EnableZ3Fallback,
                  Config, Fallback, Proofs, ReportPath);

  errs() << "095 rule-first: mba-rules="
         << ruleCatalog().size()
         << " rule-rewrites=" << RuleStats.RuleRewrites
         << " predicate-rewrites="
         << RuleStats.PredicateRewrites
         << " z3-queries=" << Proofs.Queries
         << " z3-unknown=" << Proofs.Unknown << "\n";

  return AnyChanged ? PreservedAnalyses::none()
                    : PreservedAnalyses::all();
}

} // namespace deobfuscate095
