#include "RuleEngine.h"
#include "RuleEngineInternal.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/NoFolder.h"

#include <array>

namespace deobfuscate095 {
namespace {

using namespace llvm;

Value *materializeCatalogExpression(
    const RuleExprRef &Expr,
    const std::array<Value *, 4> &Variables,
    IntegerType *Type, IRBuilder<NoFolder> &Builder) {
  if (!Expr)
    return nullptr;
  switch (Expr->Op) {
  case RuleOp::Variable:
    return Expr->Variable < Variables.size()
               ? Variables[Expr->Variable]
               : nullptr;
  case RuleOp::Constant:
    return ConstantInt::get(
        Type, APInt(Type->getBitWidth(),
                    static_cast<uint64_t>(Expr->Constant), true));
  default:
    break;
  }

  Value *L = materializeCatalogExpression(
      Expr->Left, Variables, Type, Builder);
  Value *R = Expr->Right
                 ? materializeCatalogExpression(
                       Expr->Right, Variables, Type, Builder)
                 : nullptr;
  if (!L)
    return nullptr;

  switch (Expr->Op) {
  case RuleOp::Add: return R ? Builder.CreateAdd(L, R) : nullptr;
  case RuleOp::Sub: return R ? Builder.CreateSub(L, R) : nullptr;
  case RuleOp::Mul: return R ? Builder.CreateMul(L, R) : nullptr;
  case RuleOp::And: return R ? Builder.CreateAnd(L, R) : nullptr;
  case RuleOp::Or: return R ? Builder.CreateOr(L, R) : nullptr;
  case RuleOp::Xor: return R ? Builder.CreateXor(L, R) : nullptr;
  case RuleOp::Not: return Builder.CreateNot(L);
  case RuleOp::Neg: return Builder.CreateNeg(L);
  case RuleOp::Variable:
  case RuleOp::Constant:
    return nullptr;
  }
  return nullptr;
}

} // namespace

MatcherVerification verifyRuleMatcherCatalog(LLVMContext &Context) {
  MatcherVerification Result;
  Result.Registered = ruleCatalog().size();

  Module Scratch("deobfuscate-095-rule-matcher-selftest", Context);
  IntegerType *IntTy = Type::getInt32Ty(Context);
  SmallVector<Type *, 4> Params(4, IntTy);
  FunctionType *FT = FunctionType::get(IntTy, Params, false);

  unsigned Index = 0;
  for (const RuleSpec &Rule : ruleCatalog()) {
    Function *F = Function::Create(
        FT, GlobalValue::InternalLinkage,
        "rule.matcher." + std::to_string(Index++), Scratch);
    BasicBlock *Entry =
        BasicBlock::Create(Context, "entry", F);
    IRBuilder<NoFolder> Builder(Entry);

    std::array<Value *, 4> Variables{};
    unsigned ArgIndex = 0;
    for (Argument &Arg : F->args()) {
      Arg.setName("x" + std::to_string(ArgIndex));
      Variables[ArgIndex++] = &Arg;
    }

    Value *Pattern = materializeCatalogExpression(
        Rule.Pattern, Variables, IntTy, Builder);
    bool Matched = Pattern &&
        rule_detail::matchCatalogExpression(
            Rule.Pattern, Pattern, IntTy);
    if (Matched) {
      ++Result.Verified;
      Builder.CreateRet(Pattern);
    } else {
      ++Result.Rejected;
      Result.RejectedRules.push_back(Rule.Name);
      Builder.CreateRet(ConstantInt::get(IntTy, 0));
    }
  }
  return Result;
}

} // namespace deobfuscate095
