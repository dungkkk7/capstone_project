#ifndef DEOBFUSCATE_095_RULE_CATALOG_BUILDER_H
#define DEOBFUSCATE_095_RULE_CATALOG_BUILDER_H

#include "RuleCatalog.h"

#include <utility>
#include <vector>

namespace deobfuscate095::catalog_detail {

inline RuleExprRef leaf(RuleOp Op, unsigned Variable, int64_t Constant) {
  auto Node = std::make_shared<RuleExpr>();
  Node->Op = Op;
  Node->Variable = Variable;
  Node->Constant = Constant;
  return Node;
}

inline RuleExprRef unary(RuleOp Op, RuleExprRef Value) {
  auto Node = std::make_shared<RuleExpr>();
  Node->Op = Op;
  Node->Left = std::move(Value);
  return Node;
}

inline RuleExprRef binary(RuleOp Op, RuleExprRef Left, RuleExprRef Right) {
  auto Node = std::make_shared<RuleExpr>();
  Node->Op = Op;
  Node->Left = std::move(Left);
  Node->Right = std::move(Right);
  return Node;
}

inline RuleExprRef v(unsigned Index) {
  return leaf(RuleOp::Variable, Index, 0);
}
inline RuleExprRef c(int64_t Value) {
  return leaf(RuleOp::Constant, 0, Value);
}
inline RuleExprRef add(RuleExprRef A, RuleExprRef B) {
  return binary(RuleOp::Add, std::move(A), std::move(B));
}
inline RuleExprRef sub(RuleExprRef A, RuleExprRef B) {
  return binary(RuleOp::Sub, std::move(A), std::move(B));
}
inline RuleExprRef mul(RuleExprRef A, RuleExprRef B) {
  return binary(RuleOp::Mul, std::move(A), std::move(B));
}
inline RuleExprRef band(RuleExprRef A, RuleExprRef B) {
  return binary(RuleOp::And, std::move(A), std::move(B));
}
inline RuleExprRef bor(RuleExprRef A, RuleExprRef B) {
  return binary(RuleOp::Or, std::move(A), std::move(B));
}
inline RuleExprRef bxor(RuleExprRef A, RuleExprRef B) {
  return binary(RuleOp::Xor, std::move(A), std::move(B));
}
inline RuleExprRef bnot(RuleExprRef A) {
  return unary(RuleOp::Not, std::move(A));
}
inline RuleExprRef neg(RuleExprRef A) {
  return unary(RuleOp::Neg, std::move(A));
}

inline void addRule(std::vector<RuleSpec> &Rules, const char *Name,
                    RuleExprRef Pattern, RuleExprRef Replacement) {
  Rules.push_back(
      RuleSpec{Name, std::move(Pattern), std::move(Replacement)});
}

void appendAddRules(std::vector<RuleSpec> &Rules);
void appendAndRules(std::vector<RuleSpec> &Rules);
void appendOrRules(std::vector<RuleSpec> &Rules);
void appendSubRules(std::vector<RuleSpec> &Rules);
void appendXorRules(std::vector<RuleSpec> &Rules);
void appendMiscRules(std::vector<RuleSpec> &Rules);

} // namespace deobfuscate095::catalog_detail

#endif
