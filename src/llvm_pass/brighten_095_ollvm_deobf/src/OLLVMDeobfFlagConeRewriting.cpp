#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

bool collectCoveredFlagCone(
    Value *V, BinaryOperator *Producer,
    SmallPtrSetImpl<Instruction *> &Nodes, unsigned Depth) {
  if (!V || Depth > 64 || V == Producer ||
      V == Producer->getOperand(0) || V == Producer->getOperand(1) ||
      isa<Constant>(V) || isa<Argument>(V))
    return V != nullptr;
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->getFunction() != Producer->getFunction() ||
      !I->getType()->isIntegerTy() || I->mayReadOrWriteMemory())
    return false;
  if (auto *CB = dyn_cast<CallBase>(I); CB && !isa<IntrinsicInst>(CB))
    return false;
  if (!Nodes.insert(I).second) return true;
  for (Value *Op : I->operands())
    if (!collectCoveredFlagCone(Op, Producer, Nodes, Depth + 1))
      return false;
  return true;
}

bool isLowByteOfProducer(Value *Byte, BinaryOperator *Producer) {
  if (Producer->getType()->isIntegerTy(8)) return Byte == Producer;
  auto *Trunc = dyn_cast<TruncInst>(Byte);
  return Trunc && Trunc->getType()->isIntegerTy(8) &&
         Trunc->getOperand(0) == Producer && !Trunc->hasNoUnsignedWrap();
}

Value *buildLowByteParityPredicate(IRBuilder<> &B,
                                          BinaryOperator *Producer,
                                          StringRef Prefix) {
  Type *I8 = Type::getInt8Ty(Producer->getContext());
  Value *Byte = Producer->getType()->isIntegerTy(8)
                    ? static_cast<Value *>(Producer)
                    : B.CreateTrunc(Producer, I8, Prefix + ".byte");
  Function *Ctpop = Intrinsic::getOrInsertDeclaration(
      Producer->getModule(), Intrinsic::ctpop, {I8});
  Value *Count = B.CreateCall(Ctpop, {Byte}, Prefix + ".count");
  Value *LowBit =
      B.CreateAnd(Count, ConstantInt::get(I8, 1), Prefix + ".bit");
  return B.CreateICmpEQ(LowBit, ConstantInt::get(I8, 0), Prefix);
}

Value *buildSubFlagPredicate(const SubFlagCandidate &Candidate,
                                    BinaryOperator *Sub) {
  IRBuilder<> B(Candidate.Root);
  Value *A = Sub->getOperand(0), *RHS = Sub->getOperand(1);
  switch (Candidate.Kind) {
  case SubFlagKind::ZF: return B.CreateICmpEQ(A, RHS, "deobf.bundle.zf");
  case SubFlagKind::NZ: return B.CreateICmpNE(A, RHS, "deobf.bundle.nz");
  case SubFlagKind::SF:
    return B.CreateICmpSLT(Sub, ConstantInt::get(Sub->getType(), 0),
                           "deobf.bundle.sf");
  case SubFlagKind::CF: return B.CreateICmpULT(A, RHS, "deobf.bundle.cf");
  case SubFlagKind::AE: return B.CreateICmpUGE(A, RHS, "deobf.bundle.ae");
  case SubFlagKind::BE: return B.CreateICmpULE(A, RHS, "deobf.bundle.be");
  case SubFlagKind::A: return B.CreateICmpUGT(A, RHS, "deobf.bundle.a");
  case SubFlagKind::L: return B.CreateICmpSLT(A, RHS, "deobf.bundle.l");
  case SubFlagKind::GE: return B.CreateICmpSGE(A, RHS, "deobf.bundle.ge");
  case SubFlagKind::LE: return B.CreateICmpSLE(A, RHS, "deobf.bundle.le");
  case SubFlagKind::G: return B.CreateICmpSGT(A, RHS, "deobf.bundle.g");
  case SubFlagKind::OF: {
    Value *Zero = ConstantInt::get(Sub->getType(), 0);
    Value *RHSNegative = B.CreateICmpSLT(RHS, Zero, "deobf.bundle.of.bn");
    Value *DiffBelowA = B.CreateICmpSLT(Sub, A, "deobf.bundle.of.da");
    Value *NegativeOverflow =
        B.CreateAnd(RHSNegative, DiffBelowA, "deobf.bundle.of.neg");
    Value *RHSPositive = B.CreateICmpSGT(RHS, Zero, "deobf.bundle.of.bp");
    Value *DiffAboveA = B.CreateICmpSGT(Sub, A, "deobf.bundle.of.db");
    Value *PositiveOverflow =
        B.CreateAnd(RHSPositive, DiffAboveA, "deobf.bundle.of.pos");
    return B.CreateOr(NegativeOverflow, PositiveOverflow,
                      "deobf.bundle.of");
  }
  case SubFlagKind::PF: {
    return buildLowByteParityPredicate(B, Sub, "deobf.bundle.pf");
  }
  }
  llvm_unreachable("unknown subtraction flag kind");
}

bool rewriteOneSubFlagBundle(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<BinaryOperator *, 16> Producers;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getOpcode() == Instruction::Sub &&
        BO->getType()->isIntegerTy() && !hasPoisonGeneratingFlags(BO))
      Producers.push_back(BO);

  for (BinaryOperator *Sub : Producers) {
    SmallVector<SubFlagCandidate, 16> Candidates;
    auto Add = [&](Instruction *Root, SubFlagKind Kind) {
      if (!llvm::any_of(Candidates,
                        [&](const SubFlagCandidate &C) { return C.Root == Root; }))
        Candidates.push_back({Root, Kind});
    };
    for (Instruction &I : instructions(F)) {
      if (!I.getType()->isIntegerTy(1)) continue;
      BinaryOperator *Matched = nullptr;
      bool IsZero = false;
      Value *Negated = nullptr;
      Value *ParityByte = nullptr;
      if (matchSubZeroFlag(&I, Matched, IsZero) && Matched == Sub)
        Add(&I, IsZero ? SubFlagKind::ZF : SubFlagKind::NZ);
      else if (matchSubCombinedFlag(&I, false, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::BE);
      else if (matchSubCombinedFlag(&I, true, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::LE);
      else if (matchBooleanNot(&I, Negated) &&
               matchSubCombinedFlag(Negated, false, Matched) &&
               Matched == Sub)
        Add(&I, SubFlagKind::A);
      else if (matchBooleanNot(&I, Negated) &&
               matchSubCombinedFlag(Negated, true, Matched) &&
               Matched == Sub)
        Add(&I, SubFlagKind::G);
      else if (matchSubBorrowBit(&I, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::CF);
      else if (matchBooleanNot(&I, Negated) &&
               matchSubBorrowBit(Negated, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::AE);
      else if (matchSubSignedLessFlag(&I, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::L);
      else if (matchBooleanNot(&I, Negated) &&
               matchSubSignedLessFlag(Negated, Matched) && Matched == Sub)
        Add(&I, SubFlagKind::GE);
      else {
        Value *SFSource = nullptr;
        if (matchSignBit(&I, SFSource) && SFSource == Sub)
          Add(&I, SubFlagKind::SF);
        else if (matchSubOverflowBit(&I, Sub))
          Add(&I, SubFlagKind::OF);
        else if (matchLowByteEvenParity(&I, ParityByte) &&
                 isLowByteOfProducer(ParityByte, Sub))
          Add(&I, SubFlagKind::PF);
      }
    }
    if (Candidates.size() < 2 ||
        llvm::all_of(Candidates, [](const SubFlagCandidate &C) {
          return isa<ICmpInst>(C.Root);
        }))
      continue;

    SmallPtrSet<Instruction *, 32> ConeNodes;
    SmallPtrSet<Instruction *, 16> Roots;
    bool Covered = true;
    for (const SubFlagCandidate &C : Candidates) {
      Roots.insert(C.Root);
      Covered &= collectCoveredFlagCone(C.Root, Sub, ConeNodes);
    }
    for (Instruction *Node : ConeNodes) {
      if (Roots.contains(Node)) continue;
      for (User *U : Node->users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || !ConeNodes.contains(UI)) {
          Covered = false;
          break;
        }
      }
      if (!Covered) break;
    }
    if (!Covered) continue;

    SmallVector<Value *, 16> OldRoots, NewRoots;
    SmallVector<std::string, 16> OldTexts, NewTexts;
    SmallVector<std::string, 16> Origins;
    bool SamePoison = true;
    for (const SubFlagCandidate &C : Candidates) {
      Value *Replacement = buildSubFlagPredicate(C, Sub);
      OldRoots.push_back(C.Root);
      NewRoots.push_back(Replacement);
      OldTexts.push_back(valueText(*C.Root));
      NewTexts.push_back(valueText(*Replacement));
      Origins.push_back(valueName(*C.Root));
      SamePoison &= hasSamePoisonSupport(C.Root, Replacement);
    }
    if (!SamePoison ||
        !provePairwiseTupleEquivalentSMT(OldRoots, NewRoots)) {
      if (!SamePoison) ++M.PoisonSupportRejects;
      for (Value *Replacement : NewRoots)
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI && RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
      continue;
    }

    std::string TupleCertificate;
    raw_string_ostream TupleOS(TupleCertificate);
    for (unsigned I = 0; I != Candidates.size(); ++I)
      TupleOS << OldTexts[I] << "\n==\n" << NewTexts[I] << '\n';
    TupleOS.flush();
    // Inner flags dominate the compound condition roots in canonical lifted
    // cones.  Replacing in dominance order keeps every outer root alive until
    // its pre-built replacement is installed.
    DominatorTree DT(F);
    llvm::sort(Candidates, [&](const SubFlagCandidate &A,
                               const SubFlagCandidate &B) {
      if (A.Root->getParent() == B.Root->getParent())
        return A.Root->comesBefore(B.Root);
      bool ADominates = DT.dominates(A.Root, B.Root);
      bool BDominates = DT.dominates(B.Root, A.Root);
      if (ADominates != BDominates) return ADominates;
      return std::less<Instruction *>{}(A.Root, B.Root);
    });
    for (const SubFlagCandidate &C : Candidates) {
      unsigned Index = llvm::find(OldRoots, C.Root) - OldRoots.begin();
      C.Root->replaceAllUsesWith(NewRoots[Index]);
      RecursivelyDeleteTriviallyDeadInstructions(C.Root);
      ++M.FlagConesRecovered;
      ProofRecord Record{F.getName().str(), "x86_flag_recovery",
                         Origins[Index],
                         "z3_bv_tuple_equivalence_unsat", "proved"};
      Record.OldHash = hashText(OldTexts[Index]);
      Record.NewHash = hashText(NewTexts[Index]);
      Record.ProofQueryHash = hashText(TupleCertificate);
      Record.Dependencies.push_back("complete_sub_flag_bundle_use_coverage");
      Record.Dependencies.push_back("fixed_width_x86_flag_formula");
      Record.Dependencies.push_back("identical_poison_support_per_flag");
      Proofs.push_back(std::move(Record));
    }
    return true;
  }
  return false;
}

bool matchAddZeroFlag(Value *V, BinaryOperator *&Add, bool &IsZero) {
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
               Cmp->getPredicate() != ICmpInst::ICMP_NE))
    return false;
  Value *Expr = Cmp->getOperand(0);
  auto *Zero = dyn_cast<ConstantInt>(Cmp->getOperand(1));
  if (!Zero || !Zero->isZero()) {
    Expr = Cmp->getOperand(1);
    Zero = dyn_cast<ConstantInt>(Cmp->getOperand(0));
  }
  auto *Candidate = dyn_cast<BinaryOperator>(Expr);
  if (!Zero || !Zero->isZero() || !Candidate ||
      Candidate->getOpcode() != Instruction::Add ||
      hasPoisonGeneratingFlags(Candidate))
    return false;
  Add = Candidate;
  IsZero = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
  return true;
}

bool matchAddOverflowBit(Value *V, BinaryOperator *Add) {
  Value *Cone = nullptr;
  if (!matchSignBit(V, Cone)) return false;
  Value *X0 = nullptr, *X1 = nullptr;
  if (!matchBin(Cone, Instruction::And, X0, X1)) return false;
  auto Matches = [&](Value *NotSameSign, Value *ChangedSign) {
    Value *SameSignXor = nullptr;
    if (!matchBitwiseNot(NotSameSign, SameSignXor)) return false;
    Value *P = nullptr, *Q = nullptr;
    if (!matchBin(SameSignXor, Instruction::Xor, P, Q) ||
        !samePair(P, Q, Add->getOperand(0), Add->getOperand(1)))
      return false;
    if (!matchBin(ChangedSign, Instruction::Xor, P, Q)) return false;
    return samePair(P, Q, Add->getOperand(0), Add) ||
           samePair(P, Q, Add->getOperand(1), Add);
  };
  return Matches(X0, X1) || Matches(X1, X0);
}

Value *buildAddFlagPredicate(const AddFlagCandidate &Candidate,
                                    BinaryOperator *Add) {
  IRBuilder<> B(Candidate.Root);
  Value *A = Add->getOperand(0), *RHS = Add->getOperand(1);
  Value *Zero = ConstantInt::get(Add->getType(), 0);
  switch (Candidate.Kind) {
  case AddFlagKind::ZF: return B.CreateICmpEQ(Add, Zero, "deobf.add.zf");
  case AddFlagKind::NZ: return B.CreateICmpNE(Add, Zero, "deobf.add.nz");
  case AddFlagKind::SF: return B.CreateICmpSLT(Add, Zero, "deobf.add.sf");
  case AddFlagKind::CF: return B.CreateICmpULT(Add, A, "deobf.add.cf");
  case AddFlagKind::OF: {
    Value *RHSPositive = B.CreateICmpSGT(RHS, Zero, "deobf.add.of.bp");
    Value *SumBelowA = B.CreateICmpSLT(Add, A, "deobf.add.of.sa");
    Value *PositiveOverflow =
        B.CreateAnd(RHSPositive, SumBelowA, "deobf.add.of.pos");
    Value *RHSNegative = B.CreateICmpSLT(RHS, Zero, "deobf.add.of.bn");
    Value *SumAboveA = B.CreateICmpSGT(Add, A, "deobf.add.of.sb");
    Value *NegativeOverflow =
        B.CreateAnd(RHSNegative, SumAboveA, "deobf.add.of.neg");
    return B.CreateOr(PositiveOverflow, NegativeOverflow, "deobf.add.of");
  }
  case AddFlagKind::PF: {
    return buildLowByteParityPredicate(B, Add, "deobf.add.pf");
  }
  }
  llvm_unreachable("unknown addition flag kind");
}

bool rewriteOneAddFlagBundle(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<BinaryOperator *, 16> Producers;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getOpcode() == Instruction::Add &&
        BO->getType()->isIntegerTy() && !hasPoisonGeneratingFlags(BO))
      Producers.push_back(BO);
  for (BinaryOperator *Add : Producers) {
    SmallVector<AddFlagCandidate, 8> Candidates;
    auto AddCandidate = [&](Instruction *Root, AddFlagKind Kind) {
      if (!llvm::any_of(Candidates,
                        [&](const AddFlagCandidate &C) { return C.Root == Root; }))
        Candidates.push_back({Root, Kind});
    };
    for (Instruction &I : instructions(F)) {
      if (!I.getType()->isIntegerTy(1)) continue;
      BinaryOperator *Matched = nullptr;
      bool IsZero = false;
      Value *ParityByte = nullptr, *SFSource = nullptr;
      if (matchAddZeroFlag(&I, Matched, IsZero) && Matched == Add)
        AddCandidate(&I, IsZero ? AddFlagKind::ZF : AddFlagKind::NZ);
      else if (matchAddCarryBit(&I, Matched) && Matched == Add)
        AddCandidate(&I, AddFlagKind::CF);
      else if (matchSignBit(&I, SFSource) && SFSource == Add)
        AddCandidate(&I, AddFlagKind::SF);
      else if (matchAddOverflowBit(&I, Add))
        AddCandidate(&I, AddFlagKind::OF);
      else if (matchLowByteEvenParity(&I, ParityByte) &&
               isLowByteOfProducer(ParityByte, Add))
        AddCandidate(&I, AddFlagKind::PF);
    }
    if (Candidates.size() < 2 ||
        llvm::all_of(Candidates, [](const AddFlagCandidate &C) {
          return isa<ICmpInst>(C.Root);
        }))
      continue;
    SmallPtrSet<Instruction *, 32> ConeNodes;
    SmallPtrSet<Instruction *, 8> Roots;
    bool Covered = true;
    for (const AddFlagCandidate &C : Candidates) {
      Roots.insert(C.Root);
      Covered &= collectCoveredFlagCone(C.Root, Add, ConeNodes);
    }
    for (Instruction *Node : ConeNodes) {
      if (Roots.contains(Node)) continue;
      for (User *U : Node->users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || !ConeNodes.contains(UI)) {
          Covered = false;
          break;
        }
      }
      if (!Covered) break;
    }
    if (!Covered) continue;

    SmallVector<Value *, 8> OldRoots, NewRoots;
    SmallVector<std::string, 8> OldTexts, NewTexts, Origins;
    bool SamePoison = true;
    for (const AddFlagCandidate &C : Candidates) {
      Value *Replacement = buildAddFlagPredicate(C, Add);
      OldRoots.push_back(C.Root);
      NewRoots.push_back(Replacement);
      OldTexts.push_back(valueText(*C.Root));
      NewTexts.push_back(valueText(*Replacement));
      Origins.push_back(valueName(*C.Root));
      SamePoison &= hasSamePoisonSupport(C.Root, Replacement);
    }
    if (!SamePoison ||
        !provePairwiseTupleEquivalentSMT(OldRoots, NewRoots)) {
      if (!SamePoison) ++M.PoisonSupportRejects;
      for (Value *Replacement : NewRoots)
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI && RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
      continue;
    }
    std::string TupleCertificate;
    raw_string_ostream TupleOS(TupleCertificate);
    for (unsigned I = 0; I != Candidates.size(); ++I)
      TupleOS << OldTexts[I] << "\n==\n" << NewTexts[I] << '\n';
    TupleOS.flush();
    DominatorTree DT(F);
    llvm::sort(Candidates, [&](const AddFlagCandidate &A,
                               const AddFlagCandidate &B) {
      if (A.Root->getParent() == B.Root->getParent())
        return A.Root->comesBefore(B.Root);
      bool ADominates = DT.dominates(A.Root, B.Root);
      bool BDominates = DT.dominates(B.Root, A.Root);
      if (ADominates != BDominates) return ADominates;
      return std::less<Instruction *>{}(A.Root, B.Root);
    });
    for (const AddFlagCandidate &C : Candidates) {
      unsigned Index = llvm::find(OldRoots, C.Root) - OldRoots.begin();
      C.Root->replaceAllUsesWith(NewRoots[Index]);
      RecursivelyDeleteTriviallyDeadInstructions(C.Root);
      ++M.FlagConesRecovered;
      ProofRecord Record{F.getName().str(), "x86_flag_recovery",
                         Origins[Index], "z3_bv_tuple_equivalence_unsat",
                         "proved"};
      Record.OldHash = hashText(OldTexts[Index]);
      Record.NewHash = hashText(NewTexts[Index]);
      Record.ProofQueryHash = hashText(TupleCertificate);
      Record.Dependencies.push_back("complete_add_flag_bundle_use_coverage");
      Record.Dependencies.push_back("fixed_width_x86_flag_formula");
      Record.Dependencies.push_back("identical_poison_support_per_flag");
      Proofs.push_back(std::move(Record));
    }
    return true;
  }
  return false;
}

bool matchTestZeroFlag(Value *V, BinaryOperator *&Test,
                              bool &IsZero) {
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
               Cmp->getPredicate() != ICmpInst::ICMP_NE))
    return false;
  Value *Expr = Cmp->getOperand(0);
  auto *Zero = dyn_cast<ConstantInt>(Cmp->getOperand(1));
  if (!Zero || !Zero->isZero()) {
    Expr = Cmp->getOperand(1);
    Zero = dyn_cast<ConstantInt>(Cmp->getOperand(0));
  }
  auto *Candidate = dyn_cast<BinaryOperator>(Expr);
  if (!Zero || !Zero->isZero() || !Candidate ||
      Candidate->getOpcode() != Instruction::And)
    return false;
  Test = Candidate;
  IsZero = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
  return true;
}

Value *buildTestFlagPredicate(const TestFlagCandidate &Candidate,
                                     BinaryOperator *Test) {
  IRBuilder<> B(Candidate.Root);
  Value *Zero = ConstantInt::get(Test->getType(), 0);
  switch (Candidate.Kind) {
  case TestFlagKind::ZF:
    return B.CreateICmpEQ(Test, Zero, "deobf.test.zf");
  case TestFlagKind::NZ:
    return B.CreateICmpNE(Test, Zero, "deobf.test.nz");
  case TestFlagKind::SF:
    return B.CreateICmpSLT(Test, Zero, "deobf.test.sf");
  case TestFlagKind::PF: {
    return buildLowByteParityPredicate(B, Test, "deobf.test.pf");
  }
  }
  llvm_unreachable("unknown test flag kind");
}

bool rewriteOneTestFlagBundle(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<BinaryOperator *, 16> Producers;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getOpcode() == Instruction::And &&
        BO->getType()->isIntegerTy())
      Producers.push_back(BO);

  for (BinaryOperator *Test : Producers) {
    SmallVector<TestFlagCandidate, 8> Candidates;
    auto AddCandidate = [&](Instruction *Root, TestFlagKind Kind) {
      if (!llvm::any_of(Candidates, [&](const TestFlagCandidate &C) {
            return C.Root == Root;
          }))
        Candidates.push_back({Root, Kind});
    };
    for (Instruction &I : instructions(F)) {
      if (!I.getType()->isIntegerTy(1)) continue;
      BinaryOperator *Matched = nullptr;
      bool IsZero = false;
      Value *ParityByte = nullptr, *SFSource = nullptr;
      if (matchTestZeroFlag(&I, Matched, IsZero) && Matched == Test)
        AddCandidate(&I, IsZero ? TestFlagKind::ZF : TestFlagKind::NZ);
      else if (matchSignBit(&I, SFSource) && SFSource == Test)
        AddCandidate(&I, TestFlagKind::SF);
      else if (matchLowByteEvenParity(&I, ParityByte) &&
               isLowByteOfProducer(ParityByte, Test))
        AddCandidate(&I, TestFlagKind::PF);
    }
    if (Candidates.size() < 2 ||
        llvm::all_of(Candidates, [](const TestFlagCandidate &C) {
          return isa<ICmpInst>(C.Root);
        }))
      continue;

    SmallPtrSet<Instruction *, 32> ConeNodes;
    SmallPtrSet<Instruction *, 8> Roots;
    bool Covered = true;
    for (const TestFlagCandidate &C : Candidates) {
      Roots.insert(C.Root);
      Covered &= collectCoveredFlagCone(C.Root, Test, ConeNodes);
    }
    for (Instruction *Node : ConeNodes) {
      if (Roots.contains(Node)) continue;
      for (User *U : Node->users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || !ConeNodes.contains(UI)) {
          Covered = false;
          break;
        }
      }
      if (!Covered) break;
    }
    if (!Covered) continue;

    SmallVector<Value *, 8> OldRoots, NewRoots;
    SmallVector<std::string, 8> OldTexts, NewTexts, Origins;
    bool SamePoison = true;
    for (const TestFlagCandidate &C : Candidates) {
      Value *Replacement = buildTestFlagPredicate(C, Test);
      OldRoots.push_back(C.Root);
      NewRoots.push_back(Replacement);
      OldTexts.push_back(valueText(*C.Root));
      NewTexts.push_back(valueText(*Replacement));
      Origins.push_back(valueName(*C.Root));
      SamePoison &= hasSamePoisonSupport(C.Root, Replacement);
    }
    if (!SamePoison || !provePairwiseTupleEquivalentSMT(OldRoots, NewRoots)) {
      if (!SamePoison) ++M.PoisonSupportRejects;
      for (Value *Replacement : NewRoots)
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI && RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
      continue;
    }

    std::string TupleCertificate;
    raw_string_ostream TupleOS(TupleCertificate);
    for (unsigned I = 0; I != Candidates.size(); ++I)
      TupleOS << OldTexts[I] << "\n==\n" << NewTexts[I] << '\n';
    TupleOS.flush();
    DominatorTree DT(F);
    llvm::sort(Candidates, [&](const TestFlagCandidate &A,
                               const TestFlagCandidate &B) {
      if (A.Root->getParent() == B.Root->getParent())
        return A.Root->comesBefore(B.Root);
      bool ADominates = DT.dominates(A.Root, B.Root);
      bool BDominates = DT.dominates(B.Root, A.Root);
      if (ADominates != BDominates) return ADominates;
      return std::less<Instruction *>{}(A.Root, B.Root);
    });
    for (const TestFlagCandidate &C : Candidates) {
      unsigned Index = llvm::find(OldRoots, C.Root) - OldRoots.begin();
      C.Root->replaceAllUsesWith(NewRoots[Index]);
      RecursivelyDeleteTriviallyDeadInstructions(C.Root);
      ++M.FlagConesRecovered;
      ProofRecord Record{F.getName().str(), "x86_flag_recovery",
                         Origins[Index], "z3_bv_tuple_equivalence_unsat",
                         "proved"};
      Record.OldHash = hashText(OldTexts[Index]);
      Record.NewHash = hashText(NewTexts[Index]);
      Record.ProofQueryHash = hashText(TupleCertificate);
      Record.Dependencies.push_back("complete_test_flag_bundle_use_coverage");
      Record.Dependencies.push_back("fixed_width_x86_flag_formula");
      Record.Dependencies.push_back("identical_poison_support_per_flag");
      Proofs.push_back(std::move(Record));
    }
    return true;
  }
  return false;
}

bool rewriteX86FlagCones(Function &F, Metrics &M,
                                SmallVectorImpl<ProofRecord> &Proofs) {
  bool Changed = false;
  for (unsigned Transaction = 0; Transaction != 16; ++Transaction) {
    bool Local = rewriteOneTestFlagBundle(F, M, Proofs);
    Changed |= Local;
    if (!Local) break;
  }
  for (unsigned Transaction = 0; Transaction != 16; ++Transaction) {
    bool Local = rewriteOneAddFlagBundle(F, M, Proofs);
    Changed |= Local;
    if (!Local) break;
  }
  for (unsigned Transaction = 0; Transaction != 16; ++Transaction) {
    bool Local = rewriteOneSubFlagBundle(F, M, Proofs);
    Changed |= Local;
    if (!Local) break;
  }
  SmallVector<WeakTrackingVH, 32> Work;
  for (Instruction &I : instructions(F))
    if (I.getType()->isIntegerTy(1)) Work.emplace_back(&I);
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<Instruction>(Handle);
    if (!Root) continue;
    Value *Replacement = nullptr;
    IRBuilder<> B(Root);
    Value *StandaloneSFSource = nullptr;
    BinaryOperator *FlagOperation = nullptr;
    Value *ParityByte = nullptr;
    Value *Negated = nullptr;
    Value *ConditionA = nullptr, *ConditionB = nullptr;
    if (feedsFlagBooleanCombiner(*Root)) {
      continue;
    } else if (matchBooleanNot(Root, Negated) &&
        matchCombinedConditionOperands(Negated, false, ConditionA,
                                       ConditionB)) {
      Replacement = B.CreateICmpUGT(ConditionA, ConditionB,
                                    "deobf.cc.a");
    } else if (matchBooleanNot(Root, Negated) &&
               matchCombinedConditionOperands(Negated, true, ConditionA,
                                              ConditionB)) {
      Replacement = B.CreateICmpSGT(ConditionA, ConditionB,
                                    "deobf.cc.g");
    } else if (matchBooleanNot(Root, Negated) &&
               matchUnsignedLessOperands(Negated, ConditionA, ConditionB)) {
      Replacement = B.CreateICmpUGE(ConditionA, ConditionB,
                                    "deobf.cc.ae");
    } else if (matchBooleanNot(Root, Negated) &&
               matchSignedLessOperands(Negated, ConditionA, ConditionB)) {
      Replacement = B.CreateICmpSGE(ConditionA, ConditionB,
                                    "deobf.cc.ge");
    } else if (matchCombinedConditionOperands(Root, false, ConditionA,
                                              ConditionB)) {
      Replacement = B.CreateICmpULE(ConditionA, ConditionB,
                                    "deobf.cc.be");
    } else if (matchCombinedConditionOperands(Root, true, ConditionA,
                                              ConditionB)) {
      Replacement = B.CreateICmpSLE(ConditionA, ConditionB,
                                    "deobf.cc.le");
    } else if (isa<TruncInst>(Root) &&
               matchAddCarryBit(Root, FlagOperation)) {
      Replacement = B.CreateICmpULT(FlagOperation,
                                    FlagOperation->getOperand(0),
                                    "deobf.cf.add");
    } else if (isa<TruncInst>(Root) &&
               matchSubBorrowBit(Root, FlagOperation)) {
      Replacement = B.CreateICmpULT(FlagOperation->getOperand(0),
                                    FlagOperation->getOperand(1),
                                    "deobf.cf.sub");
    } else if (matchLowByteEvenParity(Root, ParityByte)) {
      Function *Ctpop = Intrinsic::getOrInsertDeclaration(
          F.getParent(), Intrinsic::ctpop, {ParityByte->getType()});
      Value *Count = B.CreateCall(Ctpop, {ParityByte}, "deobf.pf.count");
      Value *LowBit = B.CreateAnd(
          Count, ConstantInt::get(ParityByte->getType(), 1),
          "deobf.pf.bit");
      Replacement = B.CreateICmpEQ(
          LowBit, ConstantInt::get(ParityByte->getType(), 0), "deobf.pf");
    } else if (isa<TruncInst>(Root) &&
               matchSignBit(Root, StandaloneSFSource)) {
      Replacement = B.CreateICmpSLT(
          StandaloneSFSource,
          ConstantInt::get(StandaloneSFSource->getType(), 0), "deobf.sf");
    } else if (auto *Cmp = dyn_cast<ICmpInst>(Root)) {
      if (Cmp->getPredicate() == ICmpInst::ICMP_EQ ||
          Cmp->getPredicate() == ICmpInst::ICMP_NE) {
        Value *Expr = Cmp->getOperand(0);
        auto *Zero = dyn_cast<ConstantInt>(Cmp->getOperand(1));
        if (!Zero || !Zero->isZero()) {
          Expr = Cmp->getOperand(1);
          Zero = dyn_cast<ConstantInt>(Cmp->getOperand(0));
        }
        auto *Sub = dyn_cast<BinaryOperator>(Expr);
        if (Zero && Zero->isZero() && Sub &&
            Sub->getOpcode() == Instruction::Sub &&
            !hasPoisonGeneratingFlags(Sub)) {
          ICmpInst::Predicate Predicate =
              Cmp->getPredicate() == ICmpInst::ICMP_NE
                  ? ICmpInst::ICMP_NE
                  : ICmpInst::ICMP_EQ;
          Replacement = B.CreateICmp(Predicate, Sub->getOperand(0),
                                     Sub->getOperand(1), "deobf.zf");
        }
      }
    } else if (auto *BO = dyn_cast<BinaryOperator>(Root)) {
      if (BO->getOpcode() == Instruction::Or) {
        auto *L = dyn_cast<ICmpInst>(BO->getOperand(0));
        auto *R = dyn_cast<ICmpInst>(BO->getOperand(1));
        if (L && R && sameICmpOperands(L, R)) {
          ICmpInst *CF = L, *ZF = R;
          if (CF->getPredicate() == ICmpInst::ICMP_EQ) std::swap(CF, ZF);
          if (CF->getPredicate() == ICmpInst::ICMP_ULT &&
              ZF->getPredicate() == ICmpInst::ICMP_EQ)
            Replacement = B.CreateICmpULE(CF->getOperand(0), CF->getOperand(1),
                                          "deobf.cf_or_zf");
        }
      } else if (BO->getOpcode() == Instruction::Xor) {
        Value *SFSource = nullptr;
        Value *SF = BO->getOperand(0), *OF = BO->getOperand(1);
        if (!matchSignBit(SF, SFSource)) {
          std::swap(SF, OF);
          SFSource = nullptr;
        }
        auto *Sub = dyn_cast_or_null<BinaryOperator>(SFSource);
        if (Sub && Sub->getOpcode() == Instruction::Sub &&
            !hasPoisonGeneratingFlags(Sub) && matchSubOverflowBit(OF, Sub))
          Replacement = B.CreateICmpSLT(Sub->getOperand(0), Sub->getOperand(1),
                                        "deobf.sf_xor_of");
      }
    }
    if (!Replacement) continue;
    auto *ReplacementI = cast<Instruction>(Replacement);
    bool SamePoison = hasSamePoisonSupport(Root, Replacement);
    bool Equivalent = SamePoison && proveEquivalentSMT(Root, Replacement);
    if (!Equivalent) {
      if (ReplacementI->use_empty())
        RecursivelyDeleteTriviallyDeadInstructions(ReplacementI);
      continue;
    }
    std::string OldText = valueText(*Root);
    std::string NewText = valueText(*Replacement);
    std::string Origin = valueName(*Root);
    Root->replaceAllUsesWith(Replacement);
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    ++M.FlagConesRecovered;
    ProofRecord Record{F.getName().str(), "x86_flag_recovery", Origin,
                       "z3_bv_equivalence_unsat", "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("fixed_width_x86_flag_formula");
    Record.Dependencies.push_back("identical_poison_support");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_ollvm_deobf
