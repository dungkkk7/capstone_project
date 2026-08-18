#ifndef DEOBFUSCATE_095_RULE_CATALOG_H
#define DEOBFUSCATE_095_RULE_CATALOG_H

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace deobfuscate095 {

enum class RuleOp : uint8_t {
  Variable,
  Constant,
  Add,
  Sub,
  Mul,
  And,
  Or,
  Xor,
  Not,
  Neg,
};

struct RuleExpr;
using RuleExprRef = std::shared_ptr<const RuleExpr>;

struct RuleExpr {
  RuleOp Op = RuleOp::Variable;
  unsigned Variable = 0;
  int64_t Constant = 0;
  RuleExprRef Left;
  RuleExprRef Right;
};

struct RuleSpec {
  std::string Name;
  RuleExprRef Pattern;
  RuleExprRef Replacement;
};

struct CatalogVerification {
  uint64_t Registered = 0;
  uint64_t Verified = 0;
  uint64_t Rejected = 0;
  uint64_t WidthChecks = 0;
  std::vector<std::string> RejectedRules;
};

const std::vector<RuleSpec> &ruleCatalog();
CatalogVerification verifyRuleCatalog(unsigned TimeoutMs);
unsigned expressionOperationCount(const RuleExprRef &Expr);
std::string renderRuleExpression(const RuleExprRef &Expr);

inline constexpr const char *kChernobogCatalogRepository = "19h/chernobog";
inline constexpr const char *kChernobogCatalogRevision =
    "d272b5dffbfbcaea479fb64e469577c2d8011c4c";

} // namespace deobfuscate095

#endif
