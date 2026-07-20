#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

bool flattenACBitVector(Value *V, ACBitVectorExpr &Expr,
                               unsigned &Budget, unsigned Depth) {
  if (Depth > 32 || Budget == 0 ||
      !V->getType()->isIntegerTy(Expr.Constant.getBitWidth()))
    return false;
  if (auto *C = dyn_cast<ConstantInt>(V)) {
    if (Expr.Opcode == Instruction::And) Expr.Constant &= C->getValue();
    else if (Expr.Opcode == Instruction::Or) Expr.Constant |= C->getValue();
    else Expr.Constant ^= C->getValue();
    return true;
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Expr.Opcode || hasPoisonGeneratingFlags(BO)) {
    Expr.Terms.push_back(V);
    return true;
  }
  --Budget;
  ++Expr.Nodes;
  return flattenACBitVector(BO->getOperand(0), Expr, Budget, Depth + 1) &&
         flattenACBitVector(BO->getOperand(1), Expr, Budget, Depth + 1);
}

Value *buildACBitVector(ACBitVectorExpr &Expr, Instruction *Before,
                               unsigned &NewNodes) {
  SmallVector<Value *, 16> Unique;
  for (Value *Term : Expr.Terms) {
    auto It = llvm::find(Unique, Term);
    if (Expr.Opcode == Instruction::Xor) {
      if (It == Unique.end()) Unique.push_back(Term);
      else Unique.erase(It);
    } else if (It == Unique.end()) {
      Unique.push_back(Term);
    }
  }
  IRBuilder<> B(Before);
  Value *Result = nullptr;
  auto Append = [&](Value *Term) {
    if (!Result) Result = Term;
    else Result = B.CreateBinOp(static_cast<Instruction::BinaryOps>(Expr.Opcode),
                                Result, Term, "deobf.ac");
  };
  for (Value *Term : Unique) Append(Term);
  bool IsIdentity = Expr.Opcode == Instruction::And
                        ? Expr.Constant.isAllOnes()
                        : Expr.Constant.isZero();
  if (!IsIdentity || !Result)
    Append(ConstantInt::get(Before->getType(), Expr.Constant));
  unsigned ValueCount = Unique.size() + (!IsIdentity || Unique.empty());
  NewNodes = ValueCount ? ValueCount - 1 : 0;
  return Result;
}

SmallVector<Value *, 16>
canonicalACTerms(const ACBitVectorExpr &Expr) {
  SmallVector<Value *, 16> Result;
  for (Value *Term : Expr.Terms) {
    auto It = llvm::find(Result, Term);
    if (Expr.Opcode == Instruction::Xor) {
      if (It == Result.end()) Result.push_back(Term);
      else Result.erase(It);
    } else if (It == Result.end()) {
      Result.push_back(Term);
    }
  }
  llvm::sort(Result, std::less<Value *>{});
  return Result;
}

// Multi-root extraction for AC e-classes.  Unlike the affine-only extractor,
// this handles xor/and/or equivalence classes (including cancellation and
// idempotence) and shares one dominating canonical representative.  All roots
// are committed as one tuple transaction.
bool rewriteMultiRootACBitVectorRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  struct Candidate {
    BinaryOperator *Root = nullptr;
    ACBitVectorExpr Expr;
    SmallVector<Value *, 16> CanonicalTerms;

    Candidate(BinaryOperator *Root, ACBitVectorExpr Expr,
              SmallVector<Value *, 16> Terms)
        : Root(Root), Expr(std::move(Expr)),
          CanonicalTerms(std::move(Terms)) {}
  };
  SmallVector<Candidate, 32> Candidates;
  for (Instruction &I : instructions(F)) {
    auto *Root = dyn_cast<BinaryOperator>(&I);
    if (!Root || !Root->getType()->isIntegerTy() ||
        Root->getType()->getIntegerBitWidth() > 256 ||
        (Root->getOpcode() != Instruction::And &&
         Root->getOpcode() != Instruction::Or &&
         Root->getOpcode() != Instruction::Xor))
      continue;
    unsigned Budget = 40;
    ACBitVectorExpr Expr(Root->getOpcode(),
                         Root->getType()->getIntegerBitWidth());
    if (!flattenACBitVector(Root, Expr, Budget) || Expr.Nodes == 0) continue;
    SmallVector<Value *, 16> Terms = canonicalACTerms(Expr);
    Candidates.emplace_back(Root, std::move(Expr), std::move(Terms));
  }
  DominatorTree DT(F);
  auto DominatesInstruction = [&](Instruction *A, Instruction *B) {
    if (A == B) return true;
    if (A->getParent() == B->getParent()) return A->comesBefore(B);
    return DT.dominates(A, B);
  };
  for (unsigned I = 0; I != Candidates.size(); ++I) {
    SmallVector<unsigned, 8> Group{I};
    for (unsigned J = I + 1; J != Candidates.size(); ++J) {
      const Candidate &A = Candidates[I], &B = Candidates[J];
      if (A.Root->getType() == B.Root->getType() &&
          A.Expr.Opcode == B.Expr.Opcode &&
          A.Expr.Constant == B.Expr.Constant &&
          A.CanonicalTerms == B.CanonicalTerms)
        Group.push_back(J);
    }
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
    bool SelfLeaf = llvm::any_of(Candidates[I].CanonicalTerms, [&](Value *V) {
      return llvm::any_of(Group, [&](unsigned Index) {
        return V == Candidates[Index].Root;
      });
    });
    if (SelfLeaf) continue;
    unsigned OldNodes = 0;
    for (unsigned Index : Group) OldNodes += Candidates[Index].Expr.Nodes;
    unsigned NewNodes = 0;
    Value *Replacement =
        buildACBitVector(Candidates[I].Expr, Anchor, NewNodes);
    auto *ReplacementI = dyn_cast<Instruction>(Replacement);
    if (NewNodes >= OldNodes) {
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    SmallVector<Value *, 8> OldRoots;
    std::string OldTupleText;
    raw_string_ostream OldOS(OldTupleText);
    bool SamePoison = true;
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
      if (RA->getParent() == RB->getParent()) return RB->comesBefore(RA);
      bool ADominates = DT.dominates(RA, RB);
      bool BDominates = DT.dominates(RB, RA);
      if (ADominates != BDominates) return BDominates;
      return std::less<Instruction *>{}(RB, RA);
    });
    for (unsigned Index : Group) {
      BinaryOperator *Root = Candidates[Index].Root;
      Root->replaceAllUsesWith(Replacement);
    }
    SmallVector<WeakTrackingVH, 8> DeadRoots;
    for (unsigned Index : Group)
      DeadRoots.emplace_back(Candidates[Index].Root);
    for (WeakTrackingVH &Handle : DeadRoots)
      if (auto *Root = dyn_cast_or_null<Instruction>(Handle))
        RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origins,
                       "multi_root_ac_tuple_z3_unsat", "proved"};
    Record.OldHash = hashText(OldTupleText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash =
        hashText(OldTupleText + "\n!=tuple\n" + NewText);
    Record.Dependencies.push_back("pure_integer_multi_root_dag");
    Record.Dependencies.push_back("shared_dominating_ac_extraction");
    Record.Dependencies.push_back("identical_poison_support_per_root");
    Proofs.push_back(std::move(Record));
    return true;
  }
  return false;
}

bool collectGeneralBVRegion(
    Value *V, SmallPtrSetImpl<Instruction *> &Nodes,
    SmallPtrSetImpl<Value *> &Leaves, unsigned Depth) {
  if (!V || Depth > 40 || !V->getType()->isIntegerTy()) return false;
  if (isa<ConstantInt>(V)) return true;
  if (isa<Argument>(V) || isa<FreezeInst>(V)) {
    Leaves.insert(V);
    return true;
  }
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->mayReadOrWriteMemory() || !Nodes.insert(I).second)
    return I != nullptr && Nodes.contains(I);
  if (Nodes.size() > 40) return false;
  if (auto *BO = dyn_cast<BinaryOperator>(I)) {
    if (hasPoisonGeneratingFlags(BO)) return false;
    if (BO->isShift()) {
      auto *Count = dyn_cast<ConstantInt>(BO->getOperand(1));
      if (!Count || Count->getValue().uge(BO->getType()->getIntegerBitWidth()))
        return false;
    }
  } else if (auto *Cast = dyn_cast<CastInst>(I)) {
    if (!Cast->getSrcTy()->isIntegerTy() ||
        (isa<TruncInst>(Cast) && cast<TruncInst>(Cast)->hasNoUnsignedWrap()))
      return false;
  } else if (auto *Cmp = dyn_cast<ICmpInst>(I)) {
    (void)Cmp;
  } else if (auto *II = dyn_cast<IntrinsicInst>(I)) {
    Intrinsic::ID ID = II->getIntrinsicID();
    if (ID != Intrinsic::ctpop && ID != Intrinsic::bswap &&
        ID != Intrinsic::bitreverse && ID != Intrinsic::fshl &&
        ID != Intrinsic::fshr)
      return false;
  } else {
    return false;
  }
  for (Value *Op : I->operands())
    if (!collectGeneralBVRegion(Op, Nodes, Leaves, Depth + 1)) return false;
  return true;
}

unsigned generalBVRegionCost(ArrayRef<Instruction *> Nodes) {
  unsigned Cost = 0;
  for (Instruction *I : Nodes) {
    Cost += 1;
    if (isa<CastInst>(I)) Cost += 3;
    if (isa<IntrinsicInst>(I)) Cost += 8;
    if (auto *BO = dyn_cast<BinaryOperator>(I);
        BO && BO->getOpcode() == Instruction::Mul &&
        (isa<ConstantInt>(BO->getOperand(0)) ||
         isa<ConstantInt>(BO->getOperand(1))))
      Cost += 4;
    if (isa<ICmpInst>(I) && Cost >= 3) Cost -= 3;
  }
  return Cost;
}

// General mixed-operator e-class extraction.  Structural leaf equality is
// only a cheap candidate filter; semantic membership is established by Z3.
// An existing cheaper representative must dominate every root, so no cloning
// or speculative motion is required.  At least two non-representative roots
// are committed together under one tuple proof.
bool rewriteMultiRootGeneralBVRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  struct Candidate {
    Instruction *Root = nullptr;
    SmallVector<Instruction *, 40> Nodes;
    SmallVector<Value *, 16> Leaves;
    unsigned Cost = 0;
  };
  SmallVector<Candidate, 32> Candidates;
  for (Instruction &I : instructions(F)) {
    if (!I.getType()->isIntegerTy() ||
        I.getType()->getIntegerBitWidth() > 256)
      continue;
    SmallPtrSet<Instruction *, 32> NodeSet;
    SmallPtrSet<Value *, 16> LeafSet;
    if (!collectGeneralBVRegion(&I, NodeSet, LeafSet) || NodeSet.size() < 2)
      continue;
    Candidate C;
    C.Root = &I;
    C.Nodes.append(NodeSet.begin(), NodeSet.end());
    C.Leaves.append(LeafSet.begin(), LeafSet.end());
    llvm::sort(C.Leaves, std::less<Value *>{});
    C.Cost = generalBVRegionCost(C.Nodes);
    Candidates.push_back(std::move(C));
    if (Candidates.size() == 32) break;
  }
  DominatorTree DT(F);
  auto Dominates = [&](Instruction *A, Instruction *B) {
    if (A == B) return true;
    if (A->getParent() == B->getParent()) return A->comesBefore(B);
    return DT.dominates(A, B);
  };
  unsigned ComparisonBudget = 96;
  for (unsigned R = 0; R != Candidates.size() && ComparisonBudget; ++R) {
    Candidate &Representative = Candidates[R];
    SmallVector<unsigned, 8> Equivalent;
    for (unsigned I = 0; I != Candidates.size() && ComparisonBudget; ++I) {
      if (I == R) continue;
      Candidate &Probe = Candidates[I];
      if (Probe.Root->getType() != Representative.Root->getType() ||
          Probe.Cost <= Representative.Cost ||
          Probe.Leaves != Representative.Leaves ||
          !Dominates(Representative.Root, Probe.Root) ||
          !hasSamePoisonSupport(Probe.Root, Representative.Root))
        continue;
      --ComparisonBudget;
      if (proveEquivalentSMT(Probe.Root, Representative.Root))
        Equivalent.push_back(I);
    }
    if (Equivalent.size() < 2) continue;
    SmallVector<Value *, 8> OldRoots{Representative.Root};
    std::string OldTupleText;
    raw_string_ostream OldOS(OldTupleText);
    OldOS << valueText(*Representative.Root) << '\n';
    for (unsigned Index : Equivalent) {
      OldRoots.push_back(Candidates[Index].Root);
      OldOS << valueText(*Candidates[Index].Root) << '\n';
    }
    OldOS.flush();
    if (!proveTupleEquivalentSMT(OldRoots, Representative.Root)) continue;

    std::string Origins = valueName(*Representative.Root);
    for (unsigned Index : Equivalent)
      Origins += "," + valueName(*Candidates[Index].Root);
    for (unsigned Index : Equivalent)
      Candidates[Index].Root->replaceAllUsesWith(Representative.Root);
    SmallVector<WeakTrackingVH, 8> DeadRoots;
    for (unsigned Index : Equivalent)
      DeadRoots.emplace_back(Candidates[Index].Root);
    for (WeakTrackingVH &Handle : DeadRoots)
      if (auto *Root = dyn_cast_or_null<Instruction>(Handle))
        RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origins,
                       "multi_root_mixed_bv_tuple_z3_unsat", "proved"};
    Record.OldHash = hashText(OldTupleText);
    Record.NewHash = hashText(valueText(*Representative.Root));
    Record.ProofQueryHash = hashText(
        OldTupleText + "\n!=tuple\n" + valueText(*Representative.Root));
    Record.Dependencies.push_back("bounded_pure_integer_mixed_operator_dag");
    Record.Dependencies.push_back("cheaper_existing_dominating_representative");
    Record.Dependencies.push_back("identical_poison_support_per_root");
    Proofs.push_back(std::move(Record));
    return true;
  }
  return false;
}

bool rewriteACBitVectorRegions(Function &F, Metrics &M,
                                      SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 64> Work;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && (BO->getOpcode() == Instruction::And ||
               BO->getOpcode() == Instruction::Or ||
               BO->getOpcode() == Instruction::Xor) &&
        BO->getType()->isIntegerTy() &&
        BO->getType()->getIntegerBitWidth() <= 256)
      Work.emplace_back(BO);
  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<BinaryOperator>(Handle);
    if (!Root) continue;
    unsigned Budget = 40;
    ACBitVectorExpr Expr(Root->getOpcode(),
                         Root->getType()->getIntegerBitWidth());
    if (!flattenACBitVector(Root, Expr, Budget) || Expr.Nodes == 0) continue;
    unsigned NewNodes = 0;
    Value *Replacement = buildACBitVector(Expr, Root, NewNodes);
    auto *ReplacementI = dyn_cast<Instruction>(Replacement);
    if (Replacement == Root || NewNodes >= Expr.Nodes) {
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    if (!hasSamePoisonSupport(Root, Replacement)) {
      ++M.PoisonSupportRejects;
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string OldText = valueText(*Root);
    std::string NewText = valueText(*Replacement);
    if (!proveEquivalentSMT(Root, Replacement)) {
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string Origin = valueName(*Root);
    Root->replaceAllUsesWith(Replacement);
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origin,
                       "ac_saturation_z3_unsat", "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("pure_integer_dag");
    Record.Dependencies.push_back("identical_poison_support");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

bool matchBitwiseNot(Value *V, Value *&Operand) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Xor ||
      !BO->getType()->isIntegerTy() || hasPoisonGeneratingFlags(BO))
    return false;
  auto *L = dyn_cast<ConstantInt>(BO->getOperand(0));
  auto *R = dyn_cast<ConstantInt>(BO->getOperand(1));
  ConstantInt *Mask = R ? R : L;
  if (!Mask || !Mask->isMinusOne()) return false;
  Operand = R ? BO->getOperand(0) : BO->getOperand(1);
  return true;
}

bool matchMaskedValue(Value *V, unsigned Opcode, Value *&Variable,
                             ConstantInt *&Mask) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Opcode || hasPoisonGeneratingFlags(BO))
    return false;
  auto *L = dyn_cast<ConstantInt>(BO->getOperand(0));
  auto *R = dyn_cast<ConstantInt>(BO->getOperand(1));
  Mask = R ? R : L;
  if (!Mask) return false;
  Variable = R ? BO->getOperand(0) : BO->getOperand(1);
  return true;
}

// Cost-reducing e-graph rules that require new IR construction.  The local
// structural guards are only candidate generation: poison support and a
// fixed-width Z3 equality proof remain mandatory before committing.
bool rewriteDeMorganCastRegions(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 32> Work;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getType()->isIntegerTy() &&
        (BO->getOpcode() == Instruction::And ||
         BO->getOpcode() == Instruction::Or ||
         BO->getOpcode() == Instruction::Xor))
      Work.emplace_back(BO);

  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<BinaryOperator>(Handle);
    if (!Root) continue;
    Value *Replacement = nullptr;
    StringRef Rule;
    IRBuilder<> B(Root);

    if (Root->getOpcode() == Instruction::And ||
        Root->getOpcode() == Instruction::Or) {
      Value *L = nullptr, *R = nullptr;
      auto *LI = dyn_cast<Instruction>(Root->getOperand(0));
      auto *RI = dyn_cast<Instruction>(Root->getOperand(1));
      if (LI && RI && LI->hasOneUse() && RI->hasOneUse() &&
          matchBitwiseNot(LI, L) && matchBitwiseNot(RI, R)) {
        unsigned InnerOpcode = Root->getOpcode() == Instruction::And
                                   ? Instruction::Or
                                   : Instruction::And;
        Value *Inner = B.CreateBinOp(
            static_cast<Instruction::BinaryOps>(InnerOpcode), L, R,
            "deobf.demorgan.inner");
        Replacement = B.CreateNot(Inner, "deobf.demorgan");
        Rule = "demorgan_z3_unsat";
      }
    }

    if (!Replacement) {
      auto *LC = dyn_cast<CastInst>(Root->getOperand(0));
      auto *RC = dyn_cast<CastInst>(Root->getOperand(1));
      if (LC && RC && LC->hasOneUse() && RC->hasOneUse() &&
          LC->getOpcode() == RC->getOpcode() &&
          (LC->getOpcode() == Instruction::ZExt ||
           LC->getOpcode() == Instruction::SExt) &&
          LC->getSrcTy() == RC->getSrcTy() &&
          LC->getDestTy() == RC->getDestTy() &&
          LC->getSrcTy()->isIntegerTy()) {
        Value *Inner = B.CreateBinOp(
            static_cast<Instruction::BinaryOps>(Root->getOpcode()),
            LC->getOperand(0), RC->getOperand(0), "deobf.cast.inner");
        Replacement = LC->getOpcode() == Instruction::ZExt
                          ? B.CreateZExt(Inner, Root->getType(),
                                        "deobf.cast.factor")
                          : B.CreateSExt(Inner, Root->getType(),
                                        "deobf.cast.factor");
        Rule = "bitwise_cast_factor_z3_unsat";
      }
    }

    if (!Replacement) {
      unsigned InnerOpcode = 0, OuterOpcode = 0;
      if (Root->getOpcode() == Instruction::Or ||
          Root->getOpcode() == Instruction::Xor) {
        InnerOpcode = Root->getOpcode();
        OuterOpcode = Instruction::And;
      } else if (Root->getOpcode() == Instruction::And) {
        InnerOpcode = Instruction::And;
        OuterOpcode = Instruction::Or;
      }
      Value *L = nullptr, *R = nullptr;
      ConstantInt *LM = nullptr, *RM = nullptr;
      auto *LI = dyn_cast<Instruction>(Root->getOperand(0));
      auto *RI = dyn_cast<Instruction>(Root->getOperand(1));
      if (InnerOpcode && LI && RI && LI->hasOneUse() && RI->hasOneUse() &&
          matchMaskedValue(LI, OuterOpcode, L, LM) &&
          matchMaskedValue(RI, OuterOpcode, R, RM) &&
          LM->getValue() == RM->getValue()) {
        Value *Inner = B.CreateBinOp(
            static_cast<Instruction::BinaryOps>(InnerOpcode), L, R,
            "deobf.mask.inner");
        Replacement = B.CreateBinOp(
            static_cast<Instruction::BinaryOps>(OuterOpcode), Inner, LM,
            "deobf.mask.factor");
        Rule = "mask_factor_z3_unsat";
      }
    }

    if (!Replacement) continue;
    auto *ReplacementI = dyn_cast<Instruction>(Replacement);
    if (!hasSamePoisonSupport(Root, Replacement) ||
        !proveEquivalentSMT(Root, Replacement)) {
      if (ReplacementI && ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string OldText = valueText(*Root);
    std::string NewText = valueText(*Replacement);
    std::string Origin = valueName(*Root);
    Root->replaceAllUsesWith(Replacement);
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.EGraphRewrites;
    ProofRecord Record{F.getName().str(), "bv_egraph_rewrite", Origin,
                       Rule.str(), "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("cost_reducing_pure_integer_dag");
    Record.Dependencies.push_back("identical_poison_support");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_ollvm_deobf
