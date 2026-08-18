#include "RuleCatalog.h"
#include "RuleCatalogBuilder.h"

#include <z3++.h>

#include <array>
#include <sstream>
#include <stdexcept>
#include <utility>

namespace deobfuscate095 {
namespace {

using namespace catalog_detail;

std::vector<RuleSpec> buildCatalog() {
  std::vector<RuleSpec> Rules;
  Rules.reserve(108);
  appendAddRules(Rules);
  appendAndRules(Rules);
  appendOrRules(Rules);
  appendSubRules(Rules);
  appendXorRules(Rules);
  appendMiscRules(Rules);
  if (Rules.size() != 108)
    throw std::logic_error("Chernobog rule catalog must contain 108 rules");
  return Rules;
}

uint64_t widthConstant(int64_t Value, unsigned Width) {
  uint64_t Raw = static_cast<uint64_t>(Value);
  if (Width < 64)
    Raw &= (uint64_t(1) << Width) - 1;
  return Raw;
}

z3::expr toZ3(const RuleExprRef &Expr, z3::context &Context,
              const std::vector<z3::expr> &Variables, unsigned Width) {
  switch (Expr->Op) {
  case RuleOp::Variable:
    if (Expr->Variable >= Variables.size())
      throw std::logic_error("rule variable index is out of range");
    return Variables[Expr->Variable];
  case RuleOp::Constant:
    return Context.bv_val(widthConstant(Expr->Constant, Width), Width);
  case RuleOp::Add:
    return toZ3(Expr->Left, Context, Variables, Width) +
           toZ3(Expr->Right, Context, Variables, Width);
  case RuleOp::Sub:
    return toZ3(Expr->Left, Context, Variables, Width) -
           toZ3(Expr->Right, Context, Variables, Width);
  case RuleOp::Mul:
    return toZ3(Expr->Left, Context, Variables, Width) *
           toZ3(Expr->Right, Context, Variables, Width);
  case RuleOp::And:
    return toZ3(Expr->Left, Context, Variables, Width) &
           toZ3(Expr->Right, Context, Variables, Width);
  case RuleOp::Or:
    return toZ3(Expr->Left, Context, Variables, Width) |
           toZ3(Expr->Right, Context, Variables, Width);
  case RuleOp::Xor:
    return toZ3(Expr->Left, Context, Variables, Width) ^
           toZ3(Expr->Right, Context, Variables, Width);
  case RuleOp::Not:
    return ~toZ3(Expr->Left, Context, Variables, Width);
  case RuleOp::Neg:
    return -toZ3(Expr->Left, Context, Variables, Width);
  }
  throw std::logic_error("unhandled rule expression opcode");
}

const char *opName(RuleOp Op) {
  switch (Op) {
  case RuleOp::Variable: return "v";
  case RuleOp::Constant: return "c";
  case RuleOp::Add: return "add";
  case RuleOp::Sub: return "sub";
  case RuleOp::Mul: return "mul";
  case RuleOp::And: return "and";
  case RuleOp::Or: return "or";
  case RuleOp::Xor: return "xor";
  case RuleOp::Not: return "not";
  case RuleOp::Neg: return "neg";
  }
  return "unknown";
}

void render(const RuleExprRef &Expr, std::ostringstream &OS) {
  if (Expr->Op == RuleOp::Variable) {
    OS << "x" << Expr->Variable;
    return;
  }
  if (Expr->Op == RuleOp::Constant) {
    OS << Expr->Constant;
    return;
  }
  OS << opName(Expr->Op) << "(";
  render(Expr->Left, OS);
  if (Expr->Right) {
    OS << ",";
    render(Expr->Right, OS);
  }
  OS << ")";
}

} // namespace

const std::vector<RuleSpec> &ruleCatalog() {
  static const std::vector<RuleSpec> Rules = buildCatalog();
  return Rules;
}

CatalogVerification verifyRuleCatalog(unsigned TimeoutMs) {
  CatalogVerification Result;
  Result.Registered = ruleCatalog().size();

  constexpr std::array<unsigned, 5> Widths = {1, 8, 16, 32, 64};
  for (const RuleSpec &Rule : ruleCatalog()) {
    bool Verified = true;
    for (unsigned Width : Widths) {
      ++Result.WidthChecks;
      try {
        z3::context Context;
        std::vector<z3::expr> Variables;
        Variables.reserve(4);
        for (unsigned I = 0; I < 4; ++I) {
          std::string Name = "x" + std::to_string(I);
          Variables.push_back(Context.bv_const(Name.c_str(), Width));
        }

        z3::solver Solver(Context);
        z3::params Parameters(Context);
        Parameters.set("timeout", TimeoutMs);
        Solver.set(Parameters);
        Solver.add(toZ3(Rule.Pattern, Context, Variables, Width) !=
                   toZ3(Rule.Replacement, Context, Variables, Width));
        if (Solver.check() != z3::unsat) {
          Verified = false;
          break;
        }
      } catch (const z3::exception &) {
        Verified = false;
        break;
      }
    }
    if (Verified) {
      ++Result.Verified;
    } else {
      ++Result.Rejected;
      Result.RejectedRules.push_back(Rule.Name);
    }
  }
  return Result;
}

unsigned expressionOperationCount(const RuleExprRef &Expr) {
  if (!Expr || Expr->Op == RuleOp::Variable ||
      Expr->Op == RuleOp::Constant)
    return 0;
  return 1 + expressionOperationCount(Expr->Left) +
         expressionOperationCount(Expr->Right);
}

std::string renderRuleExpression(const RuleExprRef &Expr) {
  std::ostringstream OS;
  render(Expr, OS);
  return OS.str();
}

} // namespace deobfuscate095
