#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

void addAffineTerm(AffineBVExpr &Expr, Value *Leaf,
                          const APInt &Coefficient) {
  for (auto &Term : Expr.Terms)
    if (Term.first == Leaf) {
      Term.second += Coefficient;
      return;
    }
  Expr.Terms.push_back({Leaf, Coefficient});
}

std::optional<AffineBVExpr> parseAffineBV(Value *V, unsigned Width,
                                                 unsigned &Budget,
                                                 unsigned Depth) {
  if (Depth > 32 || Budget == 0 || !V->getType()->isIntegerTy(Width))
    return std::nullopt;
  if (auto *C = dyn_cast<ConstantInt>(V)) {
    AffineBVExpr Result(Width);
    Result.Constant = C->getValue();
    return Result;
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || hasPoisonGeneratingFlags(BO) ||
      (BO->getOpcode() != Instruction::Add &&
       BO->getOpcode() != Instruction::Sub &&
       BO->getOpcode() != Instruction::Mul)) {
    AffineBVExpr Leaf(Width);
    addAffineTerm(Leaf, V, APInt(Width, 1));
    return Leaf;
  }
  --Budget;
  if (BO->getOpcode() == Instruction::Mul) {
    auto *LC = dyn_cast<ConstantInt>(BO->getOperand(0));
    auto *RC = dyn_cast<ConstantInt>(BO->getOperand(1));
    ConstantInt *Scale = RC ? RC : LC;
    Value *Variable = RC ? BO->getOperand(0) : BO->getOperand(1);
    if (!Scale) {
      AffineBVExpr Leaf(Width);
      addAffineTerm(Leaf, V, APInt(Width, 1));
      return Leaf;
    }
    auto Inner = parseAffineBV(Variable, Width, Budget, Depth + 1);
    if (!Inner) return std::nullopt;
    Inner->Constant *= Scale->getValue();
    for (auto &Term : Inner->Terms) Term.second *= Scale->getValue();
    ++Inner->Nodes;
    return Inner;
  }
  auto L = parseAffineBV(BO->getOperand(0), Width, Budget, Depth + 1);
  auto R = parseAffineBV(BO->getOperand(1), Width, Budget, Depth + 1);
  if (!L || !R) return std::nullopt;
  bool Subtract = BO->getOpcode() == Instruction::Sub;
  L->Constant = Subtract ? L->Constant - R->Constant
                         : L->Constant + R->Constant;
  for (auto &Term : R->Terms)
    addAffineTerm(*L, Term.first,
                  Subtract ? -Term.second : Term.second);
  L->Nodes += R->Nodes + 1;
  return L;
}

unsigned affineExtractionCost(const AffineBVExpr &Expr) {
  unsigned Values = !Expr.Constant.isZero();
  unsigned Cost = 0;
  for (const auto &Term : Expr.Terms) {
    if (Term.second.isZero()) continue;
    ++Values;
    Cost += !Term.second.isOne();
  }
  if (Values > 1) Cost += Values - 1;
  return Cost;
}

Value *buildAffineBV(const AffineBVExpr &Expr, Instruction *Before) {
  IRBuilder<> B(Before);
  Value *Result = nullptr;
  auto Append = [&](Value *Term) {
    Result = Result ? B.CreateAdd(Result, Term, "deobf.affine.sum") : Term;
  };
  for (const auto &Item : Expr.Terms) {
    if (Item.second.isZero()) continue;
    Value *Term = Item.first;
    if (!Item.second.isOne())
      Term = B.CreateMul(Term, ConstantInt::get(Term->getType(), Item.second),
                         "deobf.affine.scale");
    Append(Term);
  }
  if (!Expr.Constant.isZero())
    Append(ConstantInt::get(Before->getType(), Expr.Constant));
  return Result ? Result : ConstantInt::get(Before->getType(), 0);
}

bool sameAffineBV(const AffineBVExpr &L, const AffineBVExpr &R) {
  if (L.Constant != R.Constant) return false;
  unsigned LCount = llvm::count_if(
      L.Terms, [](const auto &Term) { return !Term.second.isZero(); });
  unsigned RCount = llvm::count_if(
      R.Terms, [](const auto &Term) { return !Term.second.isZero(); });
  if (LCount != RCount) return false;
  for (const auto &LT : L.Terms) {
    if (LT.second.isZero()) continue;
    auto It = llvm::find_if(R.Terms, [&](const auto &RT) {
      return RT.first == LT.first && RT.second == LT.second;
    });
    if (It == R.Terms.end()) return false;
  }
  return true;
}

// Extract one dominating representative for multiple equivalent affine
// roots.  The proof query rejects a model if any old root differs from the
// shared replacement, so cross-root sharing is validated as a tuple rather
// than inferred from independent local rewrites.
bool rewriteMultiRootAffineBVRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  struct Candidate {
    BinaryOperator *Root;
    AffineBVExpr Expr;
  };
  SmallVector<Candidate, 32> Candidates;
  for (Instruction &I : instructions(F)) {
    auto *Root = dyn_cast<BinaryOperator>(&I);
    if (!Root || !Root->getType()->isIntegerTy() ||
        Root->getType()->getIntegerBitWidth() > 256)
      continue;
    unsigned Budget = 40;
    auto Expr = parseAffineBV(Root, Root->getType()->getIntegerBitWidth(),
                              Budget);
    if (Expr && Expr->Nodes >= 1)
      Candidates.push_back({Root, std::move(*Expr)});
  }
  DominatorTree DT(F);
  auto DominatesInstruction = [&](Instruction *A, Instruction *B) {
    if (A == B) return true;
    if (A->getParent() == B->getParent()) return A->comesBefore(B);
    return DT.dominates(A, B);
  };
  SmallVector<bool, 32> Consumed(Candidates.size(), false);
  for (unsigned I = 0; I != Candidates.size(); ++I) {
    if (Consumed[I]) continue;
    SmallVector<unsigned, 8> Group{I};
    for (unsigned J = I + 1; J != Candidates.size(); ++J)
      if (!Consumed[J] && Candidates[I].Root->getType() ==
                              Candidates[J].Root->getType() &&
          sameAffineBV(Candidates[I].Expr, Candidates[J].Expr))
        Group.push_back(J);
    if (Group.size() < 2) continue;

    BinaryOperator *Anchor = nullptr;
    for (unsigned Index : Group) {
      BinaryOperator *Probe = Candidates[Index].Root;
      if (llvm::all_of(Group, [&](unsigned Other) {
            return DominatesInstruction(Probe, Candidates[Other].Root);
          })) {
        Anchor = Probe;
        break;
      }
    }
    if (!Anchor) continue;
    bool SelfLeaf = llvm::any_of(Candidates[I].Expr.Terms, [&](const auto &T) {
      return llvm::any_of(Group, [&](unsigned Index) {
        return T.first == Candidates[Index].Root;
      });
    });
    if (SelfLeaf) continue;
    unsigned OldCost = 0;
    for (unsigned Index : Group) OldCost += Candidates[Index].Expr.Nodes;
    if (affineExtractionCost(Candidates[I].Expr) >= OldCost) continue;

    Value *Replacement = buildAffineBV(Candidates[I].Expr, Anchor);
    auto *ReplacementI = dyn_cast<Instruction>(Replacement);
    SmallVector<Value *, 8> OldRoots;
    bool SamePoison = true;
    std::string OldTupleText;
    raw_string_ostream OldOS(OldTupleText);
    for (unsigned Index : Group) {
      Value *Root = Candidates[Index].Root;
      OldRoots.push_back(Root);
      SamePoison &= hasSamePoisonSupport(Root, Replacement);
      OldOS << valueText(*Root) << '\n';
    }
    OldOS.flush();
    if (!SamePoison || !proveTupleEquivalentSMT(OldRoots, Replacement)) {
      if (!SamePoison) ++M.PoisonSupportRejects;
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string NewText = valueText(*Replacement);
    std::string Origins;
    raw_string_ostream OriginOS(Origins);
    for (unsigned K = 0; K != Group.size(); ++K) {
      if (K) OriginOS << ',';
      OriginOS << valueName(*Candidates[Group[K]].Root);
    }
    OriginOS.flush();
    llvm::sort(Group, [&](unsigned A, unsigned B) {
      Instruction *RA = Candidates[A].Root;
      Instruction *RB = Candidates[B].Root;
      if (DominatesInstruction(RA, RB) && RA != RB) return false;
      if (DominatesInstruction(RB, RA) && RA != RB) return true;
      return A > B;
    });
    for (unsigned Index : Group) {
      BinaryOperator *Root = Candidates[Index].Root;
      Root->replaceAllUsesWith(Replacement);
      Consumed[Index] = true;
    }
    // Construct tracking handles only after every RAUW.  TrackingVH follows
    // RAUW, so creating it earlier would retarget the handle to Replacement
    // and leave the old roots alive indefinitely.
    SmallVector<WeakTrackingVH, 8> DeadRoots;
    for (unsigned Index : Group)
      DeadRoots.emplace_back(Candidates[Index].Root);
    for (WeakTrackingVH &Handle : DeadRoots)
      if (auto *Root = dyn_cast_or_null<Instruction>(Handle))
        RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origins,
                       "multi_root_affine_tuple_z3_unsat", "proved"};
    Record.OldHash = hashText(OldTupleText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldTupleText + "\n!=tuple\n" + NewText);
    Record.Dependencies.push_back("pure_integer_multi_root_dag");
    Record.Dependencies.push_back("shared_dominating_extraction");
    Record.Dependencies.push_back("identical_poison_support_per_root");
    Proofs.push_back(std::move(Record));
    // Recursive deletion may erase other candidate instructions.  Stop this
    // snapshot after one transaction; the production fixed point rebuilds a
    // fresh candidate graph before considering the next equivalence class.
    return true;
  }
  return false;
}

bool feedsSyntheticNativePointerSelect(Value *V, unsigned Depth) {
  if (!V || Depth > 4) return false;
  for (User *U : V->users()) {
    auto *I = dyn_cast<Instruction>(U);
    if (!I) continue;
    // Integer expressions used as GEP indices belong to recovered native
    // address formation.  This structural provenance is independent of case
    // names, concrete addresses, or generated SSA names.
    if (isa<GetElementPtrInst>(I)) return true;
    if (auto *SI = dyn_cast<SelectInst>(I);
        SI && SI->hasName() &&
        SI->getName().starts_with("native.data.pointer.select"))
      return true;
    if ((isa<ICmpInst>(I) || isa<BinaryOperator>(I) || isa<CastInst>(I)) &&
        feedsSyntheticNativePointerSelect(I, Depth + 1))
      return true;
  }
  return false;
}

bool rewriteAffineBVRegions(Function &F, Metrics &M,
                                   SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 64> Work;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getType()->isIntegerTy() &&
        BO->getType()->getIntegerBitWidth() <= 256)
      Work.emplace_back(BO);
  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<BinaryOperator>(Handle);
    if (!Root) continue;
    // These affine bounds are emitted by native data-pointer recovery, not by
    // OLLVM.  Treating them as MBA candidates creates false mandatory
    // residuals when the speculative cheaper form is (correctly) rejected by
    // Z3.  The native cleanup owns this synthetic cone.
    if (feedsSyntheticNativePointerSelect(Root)) continue;
    unsigned Width = Root->getType()->getIntegerBitWidth();
    unsigned Budget = 40;
    auto Expr = parseAffineBV(Root, Width, Budget);
    if (!Expr || Expr->Nodes < 3 ||
        affineExtractionCost(*Expr) >= Expr->Nodes)
      continue;
    bool SelfLeaf = false;
    for (const auto &Term : Expr->Terms) SelfLeaf |= Term.first == Root;
    if (SelfLeaf) continue;
    Value *Replacement = buildAffineBV(*Expr, Root);
    std::string OldText = valueText(*Root);
    std::string NewText = valueText(*Replacement);
    if (!hasSamePoisonSupport(Root, Replacement)) {
      ++M.PoisonSupportRejects;
      if (auto *RI = dyn_cast<Instruction>(Replacement); RI && RI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(RI);
      continue;
    }
    SMTEquivalenceResult Equivalence =
        checkEquivalentSMT(Root, Replacement);
    if (Equivalence != SMTEquivalenceResult::Proved) {
      if (auto *RI = dyn_cast<Instruction>(Replacement); RI && RI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(RI);
      // SAT proves that the cheaper affine extraction is simply not an
      // identity; it is a rejected speculative candidate, not unresolved
      // obfuscation.  Only an unsupported/timeout query remains an obligation.
      if (Equivalence == SMTEquivalenceResult::Unknown) {
        ProofRecord Record{F.getName().str(), "bv_egraph_candidate",
                           valueName(*Root), "z3_bv_equivalence", "unresolved",
                           "affine_extraction_equivalence_unknown"};
        Record.OldHash = hashText(OldText);
        Record.NewHash = hashText(NewText);
        Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
        Proofs.push_back(std::move(Record));
      }
      continue;
    }
    std::string Origin = valueName(*Root);
    Root->replaceAllUsesWith(Replacement);
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origin,
                       "affine_saturation_z3_unsat", "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("pure_integer_dag");
    Record.Dependencies.push_back("llvm_poison_flags_absent");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_ollvm_deobf
