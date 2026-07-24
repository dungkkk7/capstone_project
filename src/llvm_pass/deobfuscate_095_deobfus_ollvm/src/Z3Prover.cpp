#include "Z3Prover.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

#include <z3++.h>

using namespace llvm;

namespace deobfuscate095 {
namespace {

struct Translation {
  z3::expr Expr;
  SmallVector<Value *, 4> Leaves;
  DenseMap<Value *, unsigned> LeafIndex;
  unsigned Operations = 0;

  explicit Translation(z3::context &C) : Expr(C) {}
};

class Translator {
public:
  explicit Translator(z3::context &C) : C(C) {}

  std::optional<Translation> translate(Value *Root) {
    Translation T(C);
    DenseMap<Value *, z3::expr> Cache;
    SmallPtrSet<Value *, 32> Active;
    auto E = visit(Root, T, Cache, Active, 0);
    if (!E)
      return std::nullopt;
    T.Expr = *E;
    return T;
  }

private:
  z3::context &C;

  static bool supportedInteger(Type *Ty) {
    return Ty && Ty->isIntegerTy() && Ty->getIntegerBitWidth() >= 1 &&
           Ty->getIntegerBitWidth() <= 64;
  }

  std::optional<z3::expr>
  leaf(Value *V, Translation &T, DenseMap<Value *, z3::expr> &Cache) {
    if (!supportedInteger(V->getType()))
      return std::nullopt;
    auto It = T.LeafIndex.find(V);
    unsigned Index;
    if (It == T.LeafIndex.end()) {
      Index = T.Leaves.size();
      if (Index >= 4)
        return std::nullopt;
      T.Leaves.push_back(V);
      T.LeafIndex[V] = Index;
    } else {
      Index = It->second;
    }
    std::string Name = "v" + std::to_string(Index) + "_" +
                       std::to_string(reinterpret_cast<uintptr_t>(V));
    z3::expr E = C.bv_const(Name.c_str(), V->getType()->getIntegerBitWidth());
    Cache.insert({V, E});
    return E;
  }

  std::optional<z3::expr>
  visit(Value *V, Translation &T, DenseMap<Value *, z3::expr> &Cache,
        SmallPtrSetImpl<Value *> &Active, unsigned Depth) {
    if (!V || !supportedInteger(V->getType()) || Depth > 32)
      return std::nullopt;
    if (auto It = Cache.find(V); It != Cache.end())
      return It->second;
    if (auto *CI = dyn_cast<ConstantInt>(V)) {
      SmallString<80> Digits;
      CI->getValue().toString(Digits, 10, false, false);
      z3::expr E = C.bv_val(Digits.c_str(), CI->getBitWidth());
      Cache.insert({V, E});
      return E;
    }
    if (!Active.insert(V).second)
      return std::nullopt;

    auto Finish = [&](std::optional<z3::expr> E) -> std::optional<z3::expr> {
      Active.erase(V);
      if (E)
        Cache.insert({V, *E});
      return E;
    };

    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      return Finish(leaf(V, T, Cache));

    if (auto *BO = dyn_cast<BinaryOperator>(I)) {
      // Dropping poison-generating nowrap/exact preconditions is a sound
      // over-approximation for universal proofs: if the expression is equal
      // for every wrapping bit-vector input, it is also equal on the smaller
      // set of defined LLVM executions.  Treating the whole flagged operation
      // as an unrelated leaf loses common OLLVM parity identities.
      auto L = visit(BO->getOperand(0), T, Cache, Active, Depth + 1);
      auto R = visit(BO->getOperand(1), T, Cache, Active, Depth + 1);
      if (!L || !R)
        return Finish(leaf(V, T, Cache));
      std::optional<z3::expr> E;
      switch (BO->getOpcode()) {
      case Instruction::Add: E = *L + *R; break;
      case Instruction::Sub: E = *L - *R; break;
      case Instruction::Mul: E = *L * *R; break;
      case Instruction::And: E = *L & *R; break;
      case Instruction::Or:  E = *L | *R; break;
      case Instruction::Xor: E = *L ^ *R; break;
      case Instruction::Shl:
      case Instruction::LShr:
      case Instruction::AShr: {
        auto *Shift = dyn_cast<ConstantInt>(BO->getOperand(1));
        unsigned Width = BO->getType()->getIntegerBitWidth();
        if (!Shift || Shift->getValue().uge(Width))
          return Finish(leaf(V, T, Cache));
        if (BO->getOpcode() == Instruction::Shl)
          E = z3::shl(*L, *R);
        else if (BO->getOpcode() == Instruction::LShr)
          E = z3::lshr(*L, *R);
        else
          E = z3::ashr(*L, *R);
        break;
      }
      default: return Finish(leaf(V, T, Cache));
      }
      ++T.Operations;
      return Finish(E);
    }

    if (auto *Cast = dyn_cast<CastInst>(I)) {
      auto Op = visit(Cast->getOperand(0), T, Cache, Active, Depth + 1);
      if (!Op)
        return Finish(leaf(V, T, Cache));
      unsigned Src = Cast->getSrcTy()->getIntegerBitWidth();
      unsigned Dst = Cast->getDestTy()->getIntegerBitWidth();
      std::optional<z3::expr> E;
      switch (Cast->getOpcode()) {
      case Instruction::Trunc: E = Op->extract(Dst - 1, 0); break;
      case Instruction::ZExt: E = z3::zext(*Op, Dst - Src); break;
      case Instruction::SExt: E = z3::sext(*Op, Dst - Src); break;
      default: return Finish(leaf(V, T, Cache));
      }
      ++T.Operations;
      return Finish(E);
    }

    if (auto *Cmp = dyn_cast<ICmpInst>(I)) {
      auto L = visit(Cmp->getOperand(0), T, Cache, Active, Depth + 1);
      auto R = visit(Cmp->getOperand(1), T, Cache, Active, Depth + 1);
      if (!L || !R)
        return Finish(leaf(V, T, Cache));
      z3::expr B = C.bool_val(false);
      switch (Cmp->getPredicate()) {
      case CmpInst::ICMP_EQ: B = (*L == *R); break;
      case CmpInst::ICMP_NE: B = (*L != *R); break;
      case CmpInst::ICMP_UGT: B = z3::ugt(*L, *R); break;
      case CmpInst::ICMP_UGE: B = z3::uge(*L, *R); break;
      case CmpInst::ICMP_ULT: B = z3::ult(*L, *R); break;
      case CmpInst::ICMP_ULE: B = z3::ule(*L, *R); break;
      case CmpInst::ICMP_SGT: B = (*L > *R); break;
      case CmpInst::ICMP_SGE: B = (*L >= *R); break;
      case CmpInst::ICMP_SLT: B = (*L < *R); break;
      case CmpInst::ICMP_SLE: B = (*L <= *R); break;
      default: return Finish(leaf(V, T, Cache));
      }
      ++T.Operations;
      return Finish(z3::ite(B, C.bv_val(1, 1), C.bv_val(0, 1)));
    }

    if (auto *Sel = dyn_cast<SelectInst>(I)) {
      auto Cond = visit(Sel->getCondition(), T, Cache, Active, Depth + 1);
      auto TV = visit(Sel->getTrueValue(), T, Cache, Active, Depth + 1);
      auto FV = visit(Sel->getFalseValue(), T, Cache, Active, Depth + 1);
      if (!Cond || !TV || !FV)
        return Finish(leaf(V, T, Cache));
      ++T.Operations;
      return Finish(z3::ite(*Cond == C.bv_val(1, 1), *TV, *FV));
    }

    return Finish(leaf(V, T, Cache));
  }
};

} // namespace

class Z3Prover::Impl {
public:
  explicit Impl(unsigned TimeoutMs) : Solver(Context) {
    z3::params Params(Context);
    Params.set("timeout", TimeoutMs);
    Solver.set(Params);
  }

  z3::context Context;
  z3::solver Solver;
};

Z3Prover::Z3Prover(unsigned TimeoutMs)
    : P(std::make_unique<Impl>(TimeoutMs)) {}
Z3Prover::~Z3Prover() = default;

std::optional<bool> Z3Prover::proveBooleanConstant(Value *V) {
  if (!V || !V->getType()->isIntegerTy(1))
    return std::nullopt;
  Translator X(P->Context);
  auto T = X.translate(V);
  if (!T)
    return std::nullopt;

  auto Check = [&](const z3::expr &Constraint) {
    ++Stats.Queries;
    P->Solver.reset();
    P->Solver.add(Constraint);
    z3::check_result R = P->Solver.check();
    if (R == z3::unsat) {
      ++Stats.Proved;
      return ProofResult::Proved;
    }
    if (R == z3::sat) {
      ++Stats.Disproved;
      return ProofResult::Disproved;
    }
    ++Stats.Unknown;
    return ProofResult::Unknown;
  };

  z3::expr One = P->Context.bv_val(1, 1);
  z3::expr Zero = P->Context.bv_val(0, 1);
  if (Check(T->Expr != One) == ProofResult::Proved)
    return true;
  if (Check(T->Expr != Zero) == ProofResult::Proved)
    return false;
  return std::nullopt;
}

std::optional<SimplificationProof>
Z3Prover::proveSimplerInteger(Value *V, unsigned MinOps) {
  if (!V || !V->getType()->isIntegerTy() ||
      V->getType()->getIntegerBitWidth() == 1)
    return std::nullopt;
  Translator X(P->Context);
  auto T = X.translate(V);
  if (!T || T->Operations < MinOps || T->Leaves.size() > 2)
    return std::nullopt;

  unsigned Width = V->getType()->getIntegerBitWidth();
  z3::expr Zero = P->Context.bv_val(0, Width);
  z3::expr One = P->Context.bv_val(1, Width);
  z3::expr Ones = P->Context.bv_val(-1, Width);
  SmallVector<std::pair<CandidateKind, z3::expr>, 16> Candidates;
  Candidates.emplace_back(CandidateKind::ConstantZero, Zero);
  Candidates.emplace_back(CandidateKind::ConstantOne, One);
  Candidates.emplace_back(CandidateKind::ConstantAllOnes, Ones);
  if (!T->Leaves.empty()) {
    z3::expr A = P->Context.bv_const(
        ("v0_" + std::to_string(reinterpret_cast<uintptr_t>(T->Leaves[0])))
            .c_str(), Width);
    Candidates.emplace_back(CandidateKind::Leaf0, A);
    Candidates.emplace_back(CandidateKind::Not0, ~A);
    Candidates.emplace_back(CandidateKind::Neg0, -A);
    if (T->Leaves.size() == 2) {
      z3::expr B = P->Context.bv_const(
          ("v1_" + std::to_string(reinterpret_cast<uintptr_t>(T->Leaves[1])))
              .c_str(), Width);
      Candidates.emplace_back(CandidateKind::Leaf1, B);
      Candidates.emplace_back(CandidateKind::Not1, ~B);
      Candidates.emplace_back(CandidateKind::Neg1, -B);
      Candidates.emplace_back(CandidateKind::Add, A + B);
      Candidates.emplace_back(CandidateKind::Sub01, A - B);
      Candidates.emplace_back(CandidateKind::Sub10, B - A);
      Candidates.emplace_back(CandidateKind::Xor, A ^ B);
      Candidates.emplace_back(CandidateKind::And, A & B);
      Candidates.emplace_back(CandidateKind::Or, A | B);
    }
  }

  for (const auto &Candidate : Candidates) {
    ++Stats.Queries;
    P->Solver.reset();
    P->Solver.add(T->Expr != Candidate.second);
    z3::check_result R = P->Solver.check();
    if (R == z3::unsat) {
      ++Stats.Proved;
      SimplificationProof Proof;
      Proof.Kind = Candidate.first;
      Proof.Leaves.append(T->Leaves.begin(), T->Leaves.end());
      return Proof;
    }
    if (R == z3::unknown)
      ++Stats.Unknown;
    else
      ++Stats.Disproved;
  }
  return std::nullopt;
}

} // namespace deobfuscate095
