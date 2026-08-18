#include "RuleEngineInternal.h"
#include "RuleEngineSupport.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/Transforms/Utils/Local.h"

#include <array>
#include <optional>
#include <vector>

namespace deobfuscate095::rule_detail {
namespace {

using namespace llvm;

constexpr unsigned kRuleOpCount = 10;

struct Bindings {
  IntegerType *Type = nullptr;
  std::array<Value *, 4> Values{};
  std::array<bool, 4> Bound{};
};

bool isPatternConstant(const RuleExprRef &Expr, int64_t Value) {
  return Expr && Expr->Op == RuleOp::Constant && Expr->Constant == Value;
}

bool isCommutative(RuleOp Op) {
  return Op == RuleOp::Add || Op == RuleOp::Mul || Op == RuleOp::And ||
         Op == RuleOp::Or || Op == RuleOp::Xor;
}

std::optional<unsigned> llvmOpcodeFor(RuleOp Op) {
  switch (Op) {
  case RuleOp::Add: return Instruction::Add;
  case RuleOp::Sub: return Instruction::Sub;
  case RuleOp::Mul: return Instruction::Mul;
  case RuleOp::And: return Instruction::And;
  case RuleOp::Or: return Instruction::Or;
  case RuleOp::Xor: return Instruction::Xor;
  default: return std::nullopt;
  }
}

bool matchExpr(const RuleExprRef &Pattern, Value *Candidate,
               Bindings &State, unsigned Depth = 0) {
  if (!Pattern || !Candidate || Depth > 64 ||
      isDirectlyIndeterminate(Candidate))
    return false;

  if (Pattern->Op == RuleOp::Variable) {
    if (Pattern->Variable >= State.Values.size() ||
        Candidate->getType() != State.Type)
      return false;
    if (!State.Bound[Pattern->Variable]) {
      State.Bound[Pattern->Variable] = true;
      State.Values[Pattern->Variable] = Candidate;
      return true;
    }
    return State.Values[Pattern->Variable] == Candidate;
  }

  if (Pattern->Op == RuleOp::Constant)
    return isConstant(Candidate, Pattern->Constant, State.Type);

  if (Candidate->getType() != State.Type ||
      hasPoisonRefiningFlags(Candidate))
    return false;

  const std::optional<unsigned> Opcode = valueOpcode(Candidate);
  if (!Opcode)
    return false;

  if (Pattern->Op == RuleOp::Not) {
    if (*Opcode != Instruction::Xor)
      return false;
    Value *L = operand(Candidate, 0);
    Value *R = operand(Candidate, 1);
    if (isAllOnes(R, State.Type))
      return matchExpr(Pattern->Left, L, State, Depth + 1);
    if (isAllOnes(L, State.Type))
      return matchExpr(Pattern->Left, R, State, Depth + 1);
    return false;
  }

  if (Pattern->Op == RuleOp::Neg) {
    return *Opcode == Instruction::Sub &&
           isZero(operand(Candidate, 0), State.Type) &&
           matchExpr(Pattern->Left, operand(Candidate, 1),
                     State, Depth + 1);
  }

  // LLVM commonly spells multiplication by two as `shl x, 1`.
  if (Pattern->Op == RuleOp::Mul &&
      *Opcode == Instruction::Shl &&
      isOne(operand(Candidate, 1), State.Type)) {
    if (isPatternConstant(Pattern->Left, 2))
      return matchExpr(Pattern->Right, operand(Candidate, 0),
                       State, Depth + 1);
    if (isPatternConstant(Pattern->Right, 2))
      return matchExpr(Pattern->Left, operand(Candidate, 0),
                       State, Depth + 1);
    return false;
  }

  const std::optional<unsigned> Expected =
      llvmOpcodeFor(Pattern->Op);
  if (!Expected || *Opcode != *Expected)
    return false;

  Value *L = operand(Candidate, 0);
  Value *R = operand(Candidate, 1);
  if (!L || !R)
    return false;

  Bindings Direct = State;
  if (matchExpr(Pattern->Left, L, Direct, Depth + 1) &&
      matchExpr(Pattern->Right, R, Direct, Depth + 1)) {
    State = Direct;
    return true;
  }

  if (!isCommutative(Pattern->Op))
    return false;

  Bindings Swapped = State;
  if (matchExpr(Pattern->Left, R, Swapped, Depth + 1) &&
      matchExpr(Pattern->Right, L, Swapped, Depth + 1)) {
    State = Swapped;
    return true;
  }
  return false;
}

Value *materialize(const RuleExprRef &Expr, const Bindings &State,
                   IRBuilder<> &Builder) {
  if (!Expr)
    return nullptr;
  switch (Expr->Op) {
  case RuleOp::Variable:
    return Expr->Variable < State.Values.size() &&
                   State.Bound[Expr->Variable]
               ? State.Values[Expr->Variable]
               : nullptr;
  case RuleOp::Constant:
    return ConstantInt::get(
        State.Type,
        APInt(State.Type->getBitWidth(),
              static_cast<uint64_t>(Expr->Constant), true));
  default:
    break;
  }

  Value *L = materialize(Expr->Left, State, Builder);
  Value *R = Expr->Right
                 ? materialize(Expr->Right, State, Builder)
                 : nullptr;
  if (!L)
    return nullptr;

  switch (Expr->Op) {
  case RuleOp::Add:
    return R ? Builder.CreateAdd(L, R, "deobf.rule.add")
             : nullptr;
  case RuleOp::Sub:
    return R ? Builder.CreateSub(L, R, "deobf.rule.sub")
             : nullptr;
  case RuleOp::Mul:
    return R ? Builder.CreateMul(L, R, "deobf.rule.mul")
             : nullptr;
  case RuleOp::And:
    return R ? Builder.CreateAnd(L, R, "deobf.rule.and")
             : nullptr;
  case RuleOp::Or:
    return R ? Builder.CreateOr(L, R, "deobf.rule.or")
             : nullptr;
  case RuleOp::Xor:
    return R ? Builder.CreateXor(L, R, "deobf.rule.xor")
             : nullptr;
  case RuleOp::Not:
    return Builder.CreateNot(L, "deobf.rule.not");
  case RuleOp::Neg:
    return Builder.CreateNeg(L, "deobf.rule.neg");
  case RuleOp::Variable:
  case RuleOp::Constant:
    return nullptr;
  }
  return nullptr;
}

using Buckets =
    std::array<std::vector<const RuleSpec *>, kRuleOpCount>;

const Buckets &ruleBuckets() {
  static const Buckets Result = [] {
    Buckets B;
    for (const RuleSpec &Rule : ruleCatalog())
      B[static_cast<unsigned>(Rule.Pattern->Op)].push_back(&Rule);
    return B;
  }();
  return Result;
}

SmallVector<RuleOp, 2> candidateRoots(Instruction &I) {
  SmallVector<RuleOp, 2> Roots;
  auto *Type = dyn_cast<IntegerType>(I.getType());
  if (!Type)
    return Roots;

  switch (I.getOpcode()) {
  case Instruction::Add:
    Roots.push_back(RuleOp::Add);
    break;
  case Instruction::Sub:
    if (isZero(I.getOperand(0), Type))
      Roots.push_back(RuleOp::Neg);
    Roots.push_back(RuleOp::Sub);
    break;
  case Instruction::Mul:
    Roots.push_back(RuleOp::Mul);
    break;
  case Instruction::Shl:
    if (isOne(I.getOperand(1), Type))
      Roots.push_back(RuleOp::Mul);
    break;
  case Instruction::And:
    Roots.push_back(RuleOp::And);
    break;
  case Instruction::Or:
    Roots.push_back(RuleOp::Or);
    break;
  case Instruction::Xor:
    if (isAllOnes(I.getOperand(0), Type) ||
        isAllOnes(I.getOperand(1), Type))
      Roots.push_back(RuleOp::Not);
    Roots.push_back(RuleOp::Xor);
    break;
  default:
    break;
  }
  return Roots;
}

bool eraseEquivalentMaterialization(Instruction &Old,
                                    Value *Replacement) {
  auto *New = dyn_cast_or_null<Instruction>(Replacement);
  if (!New || New == &Old ||
      New->getParent() != Old.getParent() ||
      !New->isIdenticalTo(&Old))
    return false;
  RecursivelyDeleteTriviallyDeadInstructions(New);
  return true;
}

} // namespace

bool matchCatalogExpression(const RuleExprRef &Pattern,
                            Value *Candidate,
                            IntegerType *Type) {
  Bindings State;
  State.Type = Type;
  return matchExpr(Pattern, Candidate, State);
}

bool applyMBARules(Module &M, RuleEngineStats &Stats) {
  SmallVector<Instruction *, 512> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F)) {
      auto *Type = dyn_cast<IntegerType>(I.getType());
      if (!Type || !isa<BinaryOperator>(I) || I.use_empty())
        continue;
      unsigned Width = Type->getBitWidth();
      if (Width == 0 || Width > 64)
        continue;
      if (!candidateRoots(I).empty())
        Candidates.push_back(&I);
    }
  }

  bool Changed = false;
  for (Instruction *I : Candidates) {
    if (!I->getParent() || I->use_empty())
      continue;
    auto *Type = dyn_cast<IntegerType>(I->getType());
    if (!Type)
      continue;

    bool Rewritten = false;
    for (RuleOp Root : candidateRoots(*I)) {
      for (const RuleSpec *Rule :
           ruleBuckets()[static_cast<unsigned>(Root)]) {
        ++Stats.Attempts;
        Bindings State;
        State.Type = Type;
        if (!matchExpr(Rule->Pattern, I, State))
          continue;
        ++Stats.StructuralMatches;

        IRBuilder<> Builder(I);
        Value *Replacement =
            materialize(Rule->Replacement, State, Builder);
        if (!Replacement || Replacement == I ||
            Replacement->getType() != I->getType())
          continue;
        if (eraseEquivalentMaterialization(*I, Replacement))
          continue;

        I->replaceAllUsesWith(Replacement);
        I->eraseFromParent();
        ++Stats.RuleRewrites;
        ++Stats.Hits[Rule->Name];
        Changed = true;
        Rewritten = true;
        break;
      }
      if (Rewritten)
        break;
    }
  }
  return Changed;
}

} // namespace deobfuscate095::rule_detail
