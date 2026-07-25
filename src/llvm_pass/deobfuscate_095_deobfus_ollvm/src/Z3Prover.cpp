#include "Z3Prover.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

#include <z3++.h>

#include <algorithm>

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
      // Chernobog's rule registry is not limited to binary MBA trees: a
      // number of OLLVM/Hackers-Delight identities contain three or more
      // independent leaves which cancel algebraically.  Keep those leaves
      // in the proof model even though the compact replacement vocabulary
      // below is intentionally small; Z3 will only accept a replacement if
      // all omitted leaves provably cancel.
      if (Index >= 8)
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
      // Chernobog's opaque-predicate and MBA rules explicitly cover modular
      // arithmetic identities (for example x*(x+1) % 2 == 0).  Keep the
      // divisor symbolic in the proof model, but reject a zero divisor just
      // as LLVM's defined execution would do for a proven nonzero operand.
      case Instruction::UDiv: E = z3::udiv(*L, *R); break;
      case Instruction::URem: E = z3::urem(*L, *R); break;
      case Instruction::SDiv: E = *L / *R; break;
      case Instruction::SRem: E = z3::srem(*L, *R); break;
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
  if (auto It = BooleanCache.find(V); It != BooleanCache.end()) {
    if (It->second == 1)
      return true;
    if (It->second == 0)
      return false;
    return std::nullopt;
  }
  Translator X(P->Context);
  auto T = X.translate(V);
  if (!T) {
    BooleanCache[V] = -1;
    return std::nullopt;
  }

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
  if (Check(T->Expr != One) == ProofResult::Proved) {
    BooleanCache[V] = 1;
    return true;
  }
  if (Check(T->Expr != Zero) == ProofResult::Proved) {
    BooleanCache[V] = 0;
    return false;
  }
  BooleanCache[V] = -1;
  return std::nullopt;
}

std::optional<SimplificationProof>
Z3Prover::proveSimplerInteger(Value *V, unsigned MinOps,
                             unsigned MaxChecks) {
  if (!V || !V->getType()->isIntegerTy() ||
      V->getType()->getIntegerBitWidth() == 1)
    return std::nullopt;
  Translator X(P->Context);
  auto T = X.translate(V);
  if (!T || T->Operations < MinOps)
    return std::nullopt;

  unsigned Width = V->getType()->getIntegerBitWidth();
  z3::expr Zero = P->Context.bv_val(0, Width);
  z3::expr One = P->Context.bv_val(1, Width);
  z3::expr Ones = P->Context.bv_val(-1, Width);
  struct Candidate {
    CandidateKind Kind;
    z3::expr Expr;
    unsigned Left = 0;
    unsigned Right = 1;
    uint64_t Constant = 0;
  };
  SmallVector<Candidate, 96> Candidates;
  Candidates.push_back({CandidateKind::ConstantZero, Zero});
  Candidates.push_back({CandidateKind::ConstantOne, One});
  Candidates.push_back({CandidateKind::ConstantAllOnes, Ones});
  if (!T->Leaves.empty()) {
    SmallVector<z3::expr, 8> Vars;
    const unsigned MaxRecipeVars = std::min<unsigned>(T->Leaves.size(), 4);
    for (unsigned LeafNo = 0; LeafNo < MaxRecipeVars; ++LeafNo) {
      Value *V = T->Leaves[LeafNo];
      Vars.push_back(P->Context.bv_const(
          ("v" + std::to_string(T->LeafIndex.lookup(V)) + "_" +
           std::to_string(reinterpret_cast<uintptr_t>(V))).c_str(), Width));
    }
    Candidates.push_back({CandidateKind::Leaf0, Vars[0]});
    // The lifted dataset overwhelmingly exposes binary OLLVM identities.
    // Keep those recipes inside the small residual-query budget; unary and
    // special-constant forms are appended afterwards.
    if (Vars.size() >= 2) {
      Candidates.push_back({CandidateKind::Leaf1, Vars[1]});
      Candidates.push_back({CandidateKind::Add, Vars[0] + Vars[1]});
      Candidates.push_back({CandidateKind::Sub01, Vars[0] - Vars[1]});
      Candidates.push_back({CandidateKind::Sub10, Vars[1] - Vars[0]});
      Candidates.push_back({CandidateKind::Xor, Vars[0] ^ Vars[1]});
      Candidates.push_back({CandidateKind::And, Vars[0] & Vars[1]});
      Candidates.push_back({CandidateKind::Or, Vars[0] | Vars[1]});
      Candidates.push_back({CandidateKind::PairMul, Vars[0] * Vars[1], 0, 1});
    }
    Candidates.push_back({CandidateKind::Not0, ~Vars[0]});
    Candidates.push_back({CandidateKind::Neg0, -Vars[0]});
    Candidates.push_back({CandidateKind::UnaryNot, ~Vars[0], 0, 1});
    Candidates.push_back({CandidateKind::UnaryNeg, -Vars[0], 0, 1});
    if (Vars.size() >= 2) {
      Candidates.push_back({CandidateKind::Not1, ~Vars[1]});
      Candidates.push_back({CandidateKind::Neg1, -Vars[1]});
      Candidates.push_back({CandidateKind::UnaryNot, ~Vars[1], 1, 1});
      Candidates.push_back({CandidateKind::UnaryNeg, -Vars[1], 1, 1});
    }
    for (unsigned I = 0; I < Vars.size(); ++I) {
      // Chernobog's special-constant/factor families use 0, 1, 2, -1 and
      // -2 heavily.  Keep the constants width-masked by bv_val.
      for (uint64_t C : {uint64_t(0), uint64_t(1), uint64_t(2),
                         ~uint64_t(0), ~uint64_t(1)}) {
        z3::expr K = P->Context.bv_val(C, Width);
        Candidates.push_back({CandidateKind::AddConst, Vars[I] + K, I, 1, C});
        Candidates.push_back({CandidateKind::SubConst, Vars[I] - K, I, 1, C});
        Candidates.push_back({CandidateKind::XorConst, Vars[I] ^ K, I, 1, C});
        Candidates.push_back({CandidateKind::AndConst, Vars[I] & K, I, 1, C});
        Candidates.push_back({CandidateKind::OrConst, Vars[I] | K, I, 1, C});
        Candidates.push_back({CandidateKind::MulConst, Vars[I] * K, I, 1, C});
        if (C < Width) {
          z3::expr Shift = P->Context.bv_val(C, Width);
          Candidates.push_back({CandidateKind::ShlConst, z3::shl(Vars[I], Shift), I, 1, C});
          Candidates.push_back({CandidateKind::LShrConst, z3::lshr(Vars[I], Shift), I, 1, C});
          Candidates.push_back({CandidateKind::AShrConst, z3::ashr(Vars[I], Shift), I, 1, C});
        }
      }
    }
    for (unsigned I = 0; I < Vars.size(); ++I) {
      for (unsigned J = 0; J < Vars.size(); ++J) {
        if (I == J) continue;
        Candidates.push_back({CandidateKind::PairAdd, Vars[I] + Vars[J], I, J});
        Candidates.push_back({CandidateKind::PairSub, Vars[I] - Vars[J], I, J});
        Candidates.push_back({CandidateKind::PairMul, Vars[I] * Vars[J], I, J});
        Candidates.push_back({CandidateKind::PairXor, Vars[I] ^ Vars[J], I, J});
        Candidates.push_back({CandidateKind::PairAnd, Vars[I] & Vars[J], I, J});
        Candidates.push_back({CandidateKind::PairOr, Vars[I] | Vars[J], I, J});
      }
    }
  }

  unsigned Checks = 0;
  for (const auto &Candidate : Candidates) {
    if (Checks++ >= MaxChecks)
      break;
    ++Stats.Queries;
    P->Solver.reset();
    P->Solver.add(T->Expr != Candidate.Expr);
    z3::check_result R = P->Solver.check();
    if (R == z3::unsat) {
      ++Stats.Proved;
      SimplificationProof Proof;
    Proof.Kind = Candidate.Kind;
    Proof.Leaves.append(T->Leaves.begin(), T->Leaves.end());
    Proof.LeftIndex = Candidate.Left;
    Proof.RightIndex = Candidate.Right;
    Proof.Constant = Candidate.Constant;
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
