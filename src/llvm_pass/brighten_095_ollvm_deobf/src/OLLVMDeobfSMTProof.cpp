#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

// Proves only theorem-library facts.  Unknown is represented by nullopt and
// is never converted into a rewrite.
std::optional<bool> proveBoolean(Value *V, unsigned Depth) {
  if (Depth > 12)
    return std::nullopt;
  if (auto *C = dyn_cast<ConstantInt>(V))
    if (C->getType()->isIntegerTy(1))
      return !C->isZero();

  if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
    Value *L = Cmp->getOperand(0), *R = Cmp->getOperand(1);
    Value *AndL = nullptr, *Mask = nullptr;
    if (!matchBin(L, Instruction::And, AndL, Mask)) {
      std::swap(L, R);
      if (!matchBin(L, Instruction::And, AndL, Mask))
        return std::nullopt;
    }
    if (!isOne(Mask) || !isZero(R) || !isAdjacentProduct(AndL))
      return std::nullopt;
    if (Cmp->getPredicate() == ICmpInst::ICMP_EQ)
      return true;
    if (Cmp->getPredicate() == ICmpInst::ICMP_NE)
      return false;
    return std::nullopt;
  }

  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || !BO->getType()->isIntegerTy(1))
    return std::nullopt;
  auto L = proveBoolean(BO->getOperand(0), Depth + 1);
  auto R = proveBoolean(BO->getOperand(1), Depth + 1);
  if (BO->getOpcode() == Instruction::Or) {
    if ((L && *L) || (R && *R)) return true;
    if (L && R) return *L || *R;
  }
  if (BO->getOpcode() == Instruction::And) {
    if ((L && !*L) || (R && !*R)) return false;
    if (L && R) return *L && *R;
  }
  if (BO->getOpcode() == Instruction::Xor && L && R)
    return *L != *R;
  return std::nullopt;
}

SmallVector<PathConstraint, 16>
collectDominatingConstraints(BranchInst &Target, DominatorTree &DT) {
  SmallVector<PathConstraint, 16> Constraints;
  BasicBlock *TargetBB = Target.getParent();
  for (DomTreeNode *Node = DT.getNode(TargetBB); Node && Constraints.size() < 32;
       Node = Node->getIDom()) {
    BasicBlock *BB = Node->getBlock();
    for (Instruction &I : *BB) {
      if (&I == &Target) break;
      auto *II = dyn_cast<IntrinsicInst>(&I);
      if (II && II->getIntrinsicID() == Intrinsic::assume)
        Constraints.push_back({II->getArgOperand(0), true});
      if (Constraints.size() == 32) break;
    }
    if (BB == TargetBB || Constraints.size() == 32) continue;
    auto *BI = dyn_cast<BranchInst>(BB->getTerminator());
    if (!BI || !BI->isConditional()) continue;
    bool TrueDominates = DT.dominates(BI->getSuccessor(0), TargetBB);
    bool FalseDominates = DT.dominates(BI->getSuccessor(1), TargetBB);
    if (TrueDominates != FalseDominates)
      Constraints.push_back({BI->getCondition(), TrueDominates});
  }
  return Constraints;
}

std::optional<SMTBooleanProof>
proveBooleanSMT(
    Value *Condition, ArrayRef<PathConstraint> Constraints,
    const DenseMap<const LoadInst *, Value *> *ReachingLoadValues) {
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx, ReachingLoadValues);
    auto Expr = Translator.translate(Condition);
    if (!Expr || !Expr->is_bool()) return std::nullopt;
    z3::params Params(Ctx);
    Params.set("timeout", 250u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    std::string Certificate;
    raw_string_ostream CertificateOS(Certificate);
    unsigned Added = 0;
    for (const PathConstraint &Constraint : Constraints) {
      auto ConstraintExpr = Translator.translate(Constraint.first);
      if (!ConstraintExpr || !ConstraintExpr->is_bool()) return std::nullopt;
      Solver.add(Constraint.second ? *ConstraintExpr : !*ConstraintExpr);
      CertificateOS << (Constraint.second ? "true:" : "false:")
                    << valueText(*Constraint.first) << '\n';
      ++Added;
    }
    CertificateOS << Translator.getSliceCertificate();
    CertificateOS.flush();
    // Never discharge an obligation by explosion from inconsistent path
    // facts.  An unreachable block is left to CFG cleanup, not called an
    // opaque-predicate proof.
    if (Solver.check() != z3::sat) return std::nullopt;
    Solver.push();
    Solver.add(!*Expr);
    z3::check_result TrueResult = Solver.check();
    Solver.pop();
    if (TrueResult == z3::unsat)
      return SMTBooleanProof{true, Added, std::move(Certificate),
                             Translator.getResolvedLoadCount(),
                             Translator.getResolvedDiamondPhiCount(),
                             Translator.getResolvedSwitchPhiCount(),
                             Translator.getResolvedInductivePhiCount()};
    Solver.push();
    Solver.add(*Expr);
    z3::check_result FalseResult = Solver.check();
    Solver.pop();
    if (FalseResult == z3::unsat)
      return SMTBooleanProof{false, Added, std::move(Certificate),
                             Translator.getResolvedLoadCount(),
                             Translator.getResolvedDiamondPhiCount(),
                             Translator.getResolvedSwitchPhiCount(),
                             Translator.getResolvedInductivePhiCount()};
  } catch (const z3::exception &) {
    return std::nullopt;
  }
  return std::nullopt;
}

void collectConditionPHIs(Value *V,
                                 SmallPtrSetImpl<PHINode *> &Phis,
                                 SmallPtrSetImpl<Value *> &Seen,
                                 unsigned Depth) {
  if (!V || Depth > 48 || !Seen.insert(V).second) return;
  if (auto *Phi = dyn_cast<PHINode>(V)) {
    Phis.insert(Phi);
    return;
  }
  if (auto *U = dyn_cast<User>(V))
    for (Value *Op : U->operands())
      collectConditionPHIs(Op, Phis, Seen, Depth + 1);
}

// Prove a loop predicate by one-step induction over one cyclic integer PHI.
// This is deliberately stronger than path-bounded unrolling: non-PHI inputs
// remain universally quantified Z3 symbols, every external seed must establish
// the same truth value, and every backedge recurrence must preserve it.
std::optional<CyclicPredicateProof>
proveBooleanCyclicInduction(Value *Condition) {
  if (!Condition || !Condition->getType()->isIntegerTy(1)) return std::nullopt;
  SmallPtrSet<PHINode *, 4> Phis;
  SmallPtrSet<Value *, 32> Seen;
  collectConditionPHIs(Condition, Phis, Seen);
  PHINode *Phi = nullptr;
  for (PHINode *Candidate : Phis) {
    bool Cyclic = false;
    for (unsigned I = 0; I != Candidate->getNumIncomingValues(); ++I)
      Cyclic |= isPotentiallyReachable(Candidate->getParent(),
                                      Candidate->getIncomingBlock(I));
    if (!Cyclic) continue;
    if (Phi) return std::nullopt;
    Phi = Candidate;
  }
  if (!Phi || !Phi->getType()->isIntegerTy()) return std::nullopt;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    auto Predicate = Translator.translate(Condition);
    auto PhiExpr = Translator.translate(Phi);
    if (!Predicate || !Predicate->is_bool() || !PhiExpr || !PhiExpr->is_bv())
      return std::nullopt;
    z3::params Params(Ctx);
    Params.set("timeout", 1000u);
    auto SubstitutePhi = [&](const z3::expr &Replacement) {
      z3::expr_vector From(Ctx), To(Ctx);
      From.push_back(*PhiExpr);
      To.push_back(Replacement);
      return Predicate->substitute(From, To);
    };
    std::optional<bool> InvariantValue;
    std::string Certificate;
    raw_string_ostream OS(Certificate);
    OS << "cyclic-phi:" << valueText(*Phi) << '\n';
    for (unsigned I = 0; I != Phi->getNumIncomingValues(); ++I) {
      BasicBlock *Pred = Phi->getIncomingBlock(I);
      if (isPotentiallyReachable(Phi->getParent(), Pred)) continue;
      auto Seed = Translator.translate(Phi->getIncomingValue(I));
      if (!Seed || !Seed->is_bv() ||
          Seed->get_sort().bv_size() != PhiExpr->get_sort().bv_size())
        return std::nullopt;
      z3::expr SeedPredicate = SubstitutePhi(*Seed);
      z3::solver TrueSolver(Ctx), FalseSolver(Ctx);
      TrueSolver.set(Params);
      FalseSolver.set(Params);
      TrueSolver.add(!SeedPredicate);
      FalseSolver.add(SeedPredicate);
      std::optional<bool> SeedValue;
      if (TrueSolver.check() == z3::unsat) SeedValue = true;
      else if (FalseSolver.check() == z3::unsat) SeedValue = false;
      if (!SeedValue || (InvariantValue && *InvariantValue != *SeedValue))
        return std::nullopt;
      InvariantValue = SeedValue;
      OS << "seed:" << valueText(*Phi->getIncomingValue(I)) << '\n';
    }
    if (!InvariantValue) return std::nullopt;
    unsigned Backedges = 0;
    for (unsigned I = 0; I != Phi->getNumIncomingValues(); ++I) {
      BasicBlock *Pred = Phi->getIncomingBlock(I);
      if (!isPotentiallyReachable(Phi->getParent(), Pred)) continue;
      auto Next = Translator.translate(Phi->getIncomingValue(I));
      if (!Next || !Next->is_bv() ||
          Next->get_sort().bv_size() != PhiExpr->get_sort().bv_size())
        return std::nullopt;
      z3::expr NextPredicate = SubstitutePhi(*Next);
      z3::solver Step(Ctx);
      Step.set(Params);
      Step.add(*InvariantValue ? *Predicate : !*Predicate);
      Step.add(*InvariantValue ? !NextPredicate : NextPredicate);
      if (Step.check() != z3::unsat) return std::nullopt;
      ++Backedges;
      OS << "backedge:" << valueText(*Phi->getIncomingValue(I)) << '\n';
    }
    if (!Backedges) return std::nullopt;
    OS << "invariant:" << (*InvariantValue ? "true" : "false") << '\n';
    OS.flush();
    return CyclicPredicateProof{*InvariantValue, std::move(Certificate)};
  } catch (const z3::exception &) {
    return std::nullopt;
  }
}

} // namespace brighten_ollvm_deobf
