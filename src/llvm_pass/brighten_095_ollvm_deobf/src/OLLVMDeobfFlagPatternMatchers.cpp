#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

bool matchSignBit(Value *V, Value *&Source) {
  Source = nullptr;
  if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
    if (Cmp->getPredicate() == ICmpInst::ICMP_SLT &&
        isa<ConstantInt>(Cmp->getOperand(1)) &&
        cast<ConstantInt>(Cmp->getOperand(1))->isZero()) {
      Source = Cmp->getOperand(0);
      return true;
    }
  }
  auto *Trunc = dyn_cast<TruncInst>(V);
  if (!Trunc || !Trunc->getType()->isIntegerTy(1) ||
      Trunc->hasNoUnsignedWrap())
    return false;
  auto *Shift = dyn_cast<BinaryOperator>(Trunc->getOperand(0));
  if (!Shift || Shift->getOpcode() != Instruction::LShr ||
      hasPoisonGeneratingFlags(Shift))
    return false;
  auto *Amount = dyn_cast<ConstantInt>(Shift->getOperand(1));
  Value *Input = Shift->getOperand(0);
  if (!Amount || !Input->getType()->isIntegerTy() ||
      !Amount->equalsInt(Input->getType()->getIntegerBitWidth() - 1))
    return false;
  Source = Input;
  return true;
}

bool matchLogicalShiftXorStage(Value *V, unsigned Amount,
                                      Value *&Input) {
  Value *A = nullptr, *B = nullptr;
  if (!matchBin(V, Instruction::Xor, A, B)) return false;
  auto Try = [&](Value *Plain, Value *Shifted) {
    auto *Shift = dyn_cast<BinaryOperator>(Shifted);
    auto *Count = Shift ? dyn_cast<ConstantInt>(Shift->getOperand(1)) : nullptr;
    if (!Shift || Shift->getOpcode() != Instruction::LShr ||
        hasPoisonGeneratingFlags(Shift) || Shift->getOperand(0) != Plain ||
        !Count || !Count->equalsInt(Amount))
      return false;
    Input = Plain;
    return true;
  };
  return Try(A, B) || Try(B, A);
}

bool matchLowByteEvenParity(Value *V, Value *&Byte) {
  Value *Bit = nullptr, *One = nullptr;
  if (!matchBin(V, Instruction::Xor, Bit, One)) return false;
  auto *True = dyn_cast<ConstantInt>(One);
  if (!True || !True->getType()->isIntegerTy(1) || !True->isOne()) {
    std::swap(Bit, One);
    True = dyn_cast<ConstantInt>(One);
  }
  auto *Trunc = dyn_cast<TruncInst>(Bit);
  if (!True || !True->isOne() || !Trunc ||
      !Trunc->getType()->isIntegerTy(1) || Trunc->hasNoUnsignedWrap())
    return false;
  Value *S2 = nullptr, *S4 = nullptr;
  if (!matchLogicalShiftXorStage(Trunc->getOperand(0), 1, S2) ||
      !matchLogicalShiftXorStage(S2, 2, S4) ||
      !matchLogicalShiftXorStage(S4, 4, Byte) ||
      !Byte->getType()->isIntegerTy(8))
    return false;
  return true;
}

bool matchAddCarryCone(Value *Cone, BinaryOperator *&Add) {
  Value *T0 = nullptr, *T1 = nullptr;
  if (!matchBin(Cone, Instruction::Or, T0, T1)) return false;
  auto Try = [&](Value *ABTerm, Value *PropagateTerm) {
    Value *A = nullptr, *B = nullptr, *P = nullptr, *Q = nullptr;
    if (!matchBin(ABTerm, Instruction::And, A, B) ||
        !matchBin(PropagateTerm, Instruction::And, P, Q))
      return false;
    Value *NotSum = P, *AOrB = Q, *Sum = nullptr;
    if (!matchBitwiseNot(NotSum, Sum)) {
      std::swap(NotSum, AOrB);
      if (!matchBitwiseNot(NotSum, Sum)) return false;
    }
    auto *Candidate = dyn_cast<BinaryOperator>(Sum);
    Value *OA = nullptr, *OB = nullptr;
    if (!Candidate || Candidate->getOpcode() != Instruction::Add ||
        hasPoisonGeneratingFlags(Candidate) ||
        !matchBin(AOrB, Instruction::Or, OA, OB) ||
        !samePair(A, B, Candidate->getOperand(0), Candidate->getOperand(1)) ||
        !samePair(OA, OB, Candidate->getOperand(0), Candidate->getOperand(1)))
      return false;
    Add = Candidate;
    return true;
  };
  return Try(T0, T1) || Try(T1, T0);
}

bool matchAddCarryBit(Value *V, BinaryOperator *&Add) {
  Value *Cone = nullptr;
  return matchSignBit(V, Cone) && matchAddCarryCone(Cone, Add);
}

bool matchSubBorrowCone(Value *Cone, BinaryOperator *&Sub) {
  Value *T0 = nullptr, *T1 = nullptr;
  if (!matchBin(Cone, Instruction::Or, T0, T1)) return false;
  auto Try = [&](Value *GenerateTerm, Value *PropagateTerm) {
    Value *G0 = nullptr, *G1 = nullptr, *P0 = nullptr, *P1 = nullptr;
    if (!matchBin(GenerateTerm, Instruction::And, G0, G1) ||
        !matchBin(PropagateTerm, Instruction::And, P0, P1))
      return false;
    Value *A = nullptr, *B = G1;
    if (!matchBitwiseNot(G0, A)) {
      B = G0;
      if (!matchBitwiseNot(G1, A)) return false;
    }
    Value *NotXor = P0, *Diff = P1, *Xor = nullptr;
    if (!matchBitwiseNot(NotXor, Xor)) {
      std::swap(NotXor, Diff);
      if (!matchBitwiseNot(NotXor, Xor)) return false;
    }
    auto *Candidate = dyn_cast<BinaryOperator>(Diff);
    Value *XA = nullptr, *XB = nullptr;
    if (!Candidate || Candidate->getOpcode() != Instruction::Sub ||
        hasPoisonGeneratingFlags(Candidate) ||
        Candidate->getOperand(0) != A || Candidate->getOperand(1) != B ||
        !matchBin(Xor, Instruction::Xor, XA, XB) ||
        !samePair(XA, XB, A, B))
      return false;
    Sub = Candidate;
    return true;
  };
  return Try(T0, T1) || Try(T1, T0);
}

bool matchSubBorrowBit(Value *V, BinaryOperator *&Sub) {
  Value *Cone = nullptr;
  return matchSignBit(V, Cone) && matchSubBorrowCone(Cone, Sub);
}

bool matchSubOverflowBit(Value *V, BinaryOperator *Sub) {
  Value *Cone = nullptr;
  if (!matchSignBit(V, Cone)) return false;
  Value *X0 = nullptr, *X1 = nullptr, *Y0 = nullptr, *Y1 = nullptr;
  if (!matchBin(Cone, Instruction::And, X0, X1)) return false;
  auto Matches = [&](Value *First, Value *Second) {
    if (!matchBin(First, Instruction::Xor, Y0, Y1) ||
        !samePair(Y0, Y1, Sub->getOperand(0), Sub->getOperand(1)))
      return false;
    Value *P = nullptr, *Q = nullptr;
    return matchBin(Second, Instruction::Xor, P, Q) &&
           samePair(P, Q, Sub->getOperand(0), Sub);
  };
  return Matches(X0, X1) || Matches(X1, X0);
}

bool sameICmpOperands(ICmpInst *A, ICmpInst *B) {
  return A->getOperand(0) == B->getOperand(0) &&
         A->getOperand(1) == B->getOperand(1);
}

bool matchBooleanNot(Value *V, Value *&Inner) {
  Value *L = nullptr, *R = nullptr;
  if (!matchBin(V, Instruction::Xor, L, R) ||
      !V->getType()->isIntegerTy(1))
    return false;
  if (auto *C = dyn_cast<ConstantInt>(R); C && C->isOne()) {
    Inner = L;
    return true;
  }
  if (auto *C = dyn_cast<ConstantInt>(L); C && C->isOne()) {
    Inner = R;
    return true;
  }
  return false;
}

bool proveTupleEquivalentSMT(ArrayRef<Value *> OldRoots,
                                    Value *Replacement) {
  if (OldRoots.empty() || !Replacement) return false;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    auto NewExpr = Translator.translate(Replacement);
    if (!NewExpr) return false;
    z3::expr AnyDifference = Ctx.bool_val(false);
    for (Value *Old : OldRoots) {
      if (!Old || Old->getType() != Replacement->getType()) return false;
      auto OldExpr = Translator.translate(Old);
      if (!OldExpr || OldExpr->is_bool() != NewExpr->is_bool() ||
          OldExpr->is_bv() != NewExpr->is_bv())
        return false;
      AnyDifference = AnyDifference || (*OldExpr != *NewExpr);
    }
    z3::params Params(Ctx);
    Params.set("timeout", 1000u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    Solver.add(AnyDifference);
    return Solver.check() == z3::unsat;
  } catch (const z3::exception &) {
    return false;
  }
}

bool provePairwiseTupleEquivalentSMT(ArrayRef<Value *> OldRoots,
                                            ArrayRef<Value *> NewRoots) {
  if (OldRoots.empty() || OldRoots.size() != NewRoots.size()) return false;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    z3::expr AnyDifference = Ctx.bool_val(false);
    for (unsigned I = 0; I != OldRoots.size(); ++I) {
      if (!OldRoots[I] || !NewRoots[I] ||
          OldRoots[I]->getType() != NewRoots[I]->getType())
        return false;
      auto OldExpr = Translator.translate(OldRoots[I]);
      auto NewExpr = Translator.translate(NewRoots[I]);
      if (!OldExpr || !NewExpr ||
          OldExpr->is_bool() != NewExpr->is_bool() ||
          OldExpr->is_bv() != NewExpr->is_bv())
        return false;
      AnyDifference = AnyDifference || (*OldExpr != *NewExpr);
    }
    z3::params Params(Ctx);
    Params.set("timeout", 1500u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    Solver.add(AnyDifference);
    return Solver.check() == z3::unsat;
  } catch (const z3::exception &) {
    return false;
  }
}

bool matchSubZeroFlag(Value *V, BinaryOperator *&Sub,
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
      Candidate->getOpcode() != Instruction::Sub ||
      hasPoisonGeneratingFlags(Candidate))
    return false;
  Sub = Candidate;
  IsZero = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
  return true;
}

bool matchSubSignedLessFlag(Value *V, BinaryOperator *&Sub) {
  Value *SFSource = nullptr;
  Value *SF = nullptr, *OF = nullptr;
  if (!matchBin(V, Instruction::Xor, SF, OF) ||
      !V->getType()->isIntegerTy(1))
    return false;
  if (!matchSignBit(SF, SFSource)) {
    std::swap(SF, OF);
    SFSource = nullptr;
    if (!matchSignBit(SF, SFSource))
      return false;
  }
  auto *Candidate = dyn_cast_or_null<BinaryOperator>(SFSource);
  if (!Candidate || Candidate->getOpcode() != Instruction::Sub ||
      hasPoisonGeneratingFlags(Candidate) ||
      !matchSubOverflowBit(OF, Candidate))
    return false;
  Sub = Candidate;
  return true;
}

bool matchSubBorrowFlagFor(Value *V, BinaryOperator *Sub) {
  BinaryOperator *Candidate = nullptr;
  if (matchSubBorrowBit(V, Candidate))
    return Candidate == Sub;
  auto *Cmp = dyn_cast<ICmpInst>(V);
  return Cmp && Cmp->getPredicate() == ICmpInst::ICMP_ULT &&
         Cmp->getOperand(0) == Sub->getOperand(0) &&
         Cmp->getOperand(1) == Sub->getOperand(1);
}

bool matchSubZeroFlagFor(Value *V, BinaryOperator *Sub) {
  BinaryOperator *Candidate = nullptr;
  bool IsZero = false;
  return matchSubZeroFlag(V, Candidate, IsZero) && IsZero && Candidate == Sub;
}

bool matchSubSignedLessFlagFor(Value *V, BinaryOperator *Sub) {
  BinaryOperator *Candidate = nullptr;
  if (matchSubSignedLessFlag(V, Candidate))
    return Candidate == Sub;
  auto *Cmp = dyn_cast<ICmpInst>(V);
  return Cmp && Cmp->getPredicate() == ICmpInst::ICMP_SLT &&
         Cmp->getOperand(0) == Sub->getOperand(0) &&
         Cmp->getOperand(1) == Sub->getOperand(1);
}

bool matchSubCombinedFlag(Value *V, bool Signed,
                                 BinaryOperator *&Sub) {
  Value *L = nullptr, *R = nullptr;
  if (!matchBin(V, Instruction::Or, L, R) ||
      !V->getType()->isIntegerTy(1))
    return false;
  BinaryOperator *Candidate = nullptr;
  bool IsZero = false;
  auto Try = [&](Value *Primary, Value *ZeroFlag) {
    if (!matchSubZeroFlag(ZeroFlag, Candidate, IsZero) || !IsZero)
      return false;
    bool MatchesPrimary = Signed
                              ? matchSubSignedLessFlagFor(Primary, Candidate)
                              : matchSubBorrowFlagFor(Primary, Candidate);
    if (!MatchesPrimary)
      return false;
    Sub = Candidate;
    return true;
  };
  return Try(L, R) || Try(R, L);
}

bool matchUnsignedLessOperands(Value *V, Value *&A, Value *&B) {
  BinaryOperator *Sub = nullptr;
  if (matchSubBorrowBit(V, Sub)) {
    A = Sub->getOperand(0);
    B = Sub->getOperand(1);
    return true;
  }
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || Cmp->getPredicate() != ICmpInst::ICMP_ULT)
    return false;
  A = Cmp->getOperand(0);
  B = Cmp->getOperand(1);
  return true;
}

bool matchSignedLessOperands(Value *V, Value *&A, Value *&B) {
  BinaryOperator *Sub = nullptr;
  if (matchSubSignedLessFlag(V, Sub)) {
    A = Sub->getOperand(0);
    B = Sub->getOperand(1);
    return true;
  }
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || Cmp->getPredicate() != ICmpInst::ICMP_SLT)
    return false;
  A = Cmp->getOperand(0);
  B = Cmp->getOperand(1);
  return true;
}

bool matchCombinedConditionOperands(Value *V, bool Signed,
                                           Value *&A, Value *&B) {
  BinaryOperator *Sub = nullptr;
  if (matchSubCombinedFlag(V, Signed, Sub)) {
    A = Sub->getOperand(0);
    B = Sub->getOperand(1);
    return true;
  }
  Value *L = nullptr, *R = nullptr;
  if (!matchBin(V, Instruction::Or, L, R) ||
      !V->getType()->isIntegerTy(1))
    return false;
  auto *LCmp = dyn_cast<ICmpInst>(L);
  auto *RCmp = dyn_cast<ICmpInst>(R);
  if (!LCmp || !RCmp || !sameICmpOperands(LCmp, RCmp))
    return false;
  ICmpInst *Primary = LCmp, *Zero = RCmp;
  if (Primary->getPredicate() == ICmpInst::ICMP_EQ)
    std::swap(Primary, Zero);
  ICmpInst::Predicate Expected =
      Signed ? ICmpInst::ICMP_SLT : ICmpInst::ICMP_ULT;
  if (Primary->getPredicate() != Expected ||
      Zero->getPredicate() != ICmpInst::ICMP_EQ)
    return false;
  A = Primary->getOperand(0);
  B = Primary->getOperand(1);
  return true;
}

// Do not rewrite an intermediate flag bit before a compound condition-code
// cone (CF|ZF, SF^OF, or their inversions) has been recognized.  Replacing an
// inner bit first is individually sound, but destroys producer-wide evidence
// needed to prove and collapse the complete terminal predicate.
bool feedsFlagBooleanCombiner(const Instruction &I) {
  for (const User *U : I.users()) {
    auto *BO = dyn_cast<BinaryOperator>(U);
    if (BO && BO->getType()->isIntegerTy(1) &&
        (BO->getOpcode() == Instruction::Or ||
         BO->getOpcode() == Instruction::Xor))
      return true;
  }
  return false;
}

bool matchRotateLeftIdiom(BinaryOperator &Root, Value *&Input,
                                 unsigned &Amount) {
  if (Root.getOpcode() != Instruction::Or ||
      !Root.getType()->isIntegerTy())
    return false;
  auto Try = [&](Value *ShlValue, Value *LShrValue) {
    auto *Shl = dyn_cast<BinaryOperator>(ShlValue);
    auto *LShr = dyn_cast<BinaryOperator>(LShrValue);
    if (!Shl || !LShr || Shl->getOpcode() != Instruction::Shl ||
        LShr->getOpcode() != Instruction::LShr ||
        hasPoisonGeneratingFlags(Shl) || hasPoisonGeneratingFlags(LShr) ||
        Shl->getOperand(0) != LShr->getOperand(0))
      return false;
    auto *Left = dyn_cast<ConstantInt>(Shl->getOperand(1));
    auto *Right = dyn_cast<ConstantInt>(LShr->getOperand(1));
    unsigned Width = Root.getType()->getIntegerBitWidth();
    if (!Left || !Right || Left->getValue().uge(Width) ||
        Right->getValue().uge(Width) || Left->isZero() || Right->isZero() ||
        Left->getValue().urem(Width) + Right->getValue().urem(Width) != Width)
      return false;
    Input = Shl->getOperand(0);
    Amount = static_cast<unsigned>(Left->getValue().urem(Width));
    return true;
  };
  return Try(Root.getOperand(0), Root.getOperand(1)) ||
         Try(Root.getOperand(1), Root.getOperand(0));
}

bool rewriteRotateRegions(Function &F, Metrics &M,
                                 SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 16> Work;
  for (Instruction &I : instructions(F))
    if (auto *BO = dyn_cast<BinaryOperator>(&I);
        BO && BO->getOpcode() == Instruction::Or)
      Work.emplace_back(BO);
  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *Root = dyn_cast_or_null<BinaryOperator>(Handle);
    if (!Root) continue;
    Value *Input = nullptr;
    unsigned Amount = 0;
    if (!matchRotateLeftIdiom(*Root, Input, Amount)) continue;
    Function *Fshl = Intrinsic::getOrInsertDeclaration(
        F.getParent(), Intrinsic::fshl, {Root->getType()});
    IRBuilder<> B(Root);
    Value *Replacement = B.CreateCall(
        Fshl, {Input, Input, ConstantInt::get(Root->getType(), Amount)},
        "deobf.rotl");
    auto *ReplacementI = cast<Instruction>(Replacement);
    if (!hasSamePoisonSupport(Root, Replacement) ||
        !proveEquivalentSMT(Root, Replacement)) {
      if (ReplacementI->use_empty())
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
                       "rotate_idiom_z3_unsat", "proved"};
    Record.OldHash = hashText(OldText);
    Record.NewHash = hashText(NewText);
    Record.ProofQueryHash = hashText(OldText + "\n!=\n" + NewText);
    Record.Dependencies.push_back("constant_shift_counts_in_range");
    Record.Dependencies.push_back("identical_poison_support");
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_ollvm_deobf
