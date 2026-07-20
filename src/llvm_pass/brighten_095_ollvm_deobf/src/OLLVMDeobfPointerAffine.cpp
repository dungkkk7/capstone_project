#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

IntAffine combineAffine(const IntAffine &L, const IntAffine &R,
                               bool Subtract) {
  if (!L.Valid || !R.Valid) return IntAffine();
  IntAffine Out = L;
  Out.Valid = true;
  Out.Offset = Subtract ? L.Offset - R.Offset : L.Offset + R.Offset;
  for (const auto &[Term, Coeff] : R.Terms) {
    int64_t Delta = Subtract ? -Coeff : Coeff;
    int64_t &Combined = Out.Terms[Term];
    if ((Delta > 0 && Combined > std::numeric_limits<int64_t>::max() - Delta) ||
        (Delta < 0 && Combined < std::numeric_limits<int64_t>::min() - Delta))
      return IntAffine();
    Combined += Delta;
    if (Combined == 0) Out.Terms.erase(Term);
  }
  return Out;
}

bool sameAffineTerms(const IntAffine &L, const IntAffine &R) {
  if (!L.Valid || !R.Valid || L.Terms.size() != R.Terms.size()) return false;
  for (const auto &[Term, Coeff] : L.Terms) {
    auto It = R.Terms.find(Term);
    if (It == R.Terms.end() || It->second != Coeff) return false;
  }
  return true;
}

const Value *unitAffineRoot(const IntAffine &A) {
  if (!A.Valid || A.Terms.size() != 1) return nullptr;
  const auto &Only = *A.Terms.begin();
  return Only.second == 1 ? Only.first : nullptr;
}

bool definitelyDistinctAffineObjects(const IntAffine &L,
                                             const IntAffine &R) {
  const Value *LB = unitAffineRoot(L), *RB = unitAffineRoot(R);
  if (!LB || !RB || LB == RB) return false;
  return (isa<GlobalValue>(LB) && isa<GlobalValue>(RB)) ||
         (isa<AllocaInst>(LB) && isa<AllocaInst>(RB));
}

IntAffine parseIntegerAffine(Value *V, unsigned Depth,
                                    BasicBlock *Header,
                                    BasicBlock *Pred,
                                    const DenseMap<BasicBlock *, BasicBlock *>
                                        *PathPreds) {
  if (Depth > 24) return IntAffine();
  if (auto *Phi = dyn_cast<PHINode>(V)) {
    BasicBlock *IncomingPred = nullptr;
    if (PathPreds) IncomingPred = PathPreds->lookup(Phi->getParent());
    if (!IncomingPred && Header && Pred && Phi->getParent() == Header)
      IncomingPred = Pred;
    if (IncomingPred) {
      int Index = Phi->getBasicBlockIndex(IncomingPred);
      if (Index < 0) return IntAffine();
      return parseIntegerAffine(Phi->getIncomingValue(Index), Depth + 1,
                                Header, Pred, PathPreds);
    }
  }
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    IntAffine Out;
    Out.Valid = true;
    Out.Offset = CI->getValue().sextOrTrunc(64);
    return Out;
  }
  auto *Op = dyn_cast<Operator>(V);
  if (!Op) {
    if (!V->getType()->isIntegerTy()) return IntAffine();
    IntAffine Out;
    Out.Valid = true;
    Out.Terms[V] = 1;
    return Out;
  }
  if (Op->getOpcode() == Instruction::PtrToInt) {
    IntAffine Out = parsePointerAffine(Op->getOperand(0), Depth + 1,
                                       Header, Pred, PathPreds);
    if (!Out.Valid) return IntAffine();
    Out.Offset = Out.Offset.sextOrTrunc(64);
    return Out;
  }
  if (Op->getOpcode() != Instruction::Add &&
      Op->getOpcode() != Instruction::Sub) {
    if (!V->getType()->isIntegerTy()) return IntAffine();
    IntAffine Out;
    Out.Valid = true;
    Out.Terms[V] = 1;
    return Out;
  }
  IntAffine L = parseIntegerAffine(Op->getOperand(0), Depth + 1,
                                   Header, Pred, PathPreds);
  IntAffine R = parseIntegerAffine(Op->getOperand(1), Depth + 1,
                                   Header, Pred, PathPreds);
  return combineAffine(L, R, Op->getOpcode() == Instruction::Sub);
}

IntAffine parsePointerAffine(Value *V, unsigned Depth,
                                    BasicBlock *Header, BasicBlock *Pred,
                                    const DenseMap<BasicBlock *, BasicBlock *>
                                        *PathPreds) {
  if (Depth > 24) return IntAffine();
  if (auto *Phi = dyn_cast<PHINode>(V)) {
    BasicBlock *IncomingPred = nullptr;
    if (PathPreds) IncomingPred = PathPreds->lookup(Phi->getParent());
    if (!IncomingPred && Header && Pred && Phi->getParent() == Header)
      IncomingPred = Pred;
    if (IncomingPred) {
      int Index = Phi->getBasicBlockIndex(IncomingPred);
      if (Index < 0) return IntAffine();
      return parsePointerAffine(Phi->getIncomingValue(Index), Depth + 1,
                                Header, Pred, PathPreds);
    }
  }
  V = V->stripPointerCasts();
  if (isa<GlobalValue>(V) || isa<Argument>(V) || isa<AllocaInst>(V)) {
    IntAffine Out;
    Out.Terms[V] = 1;
    Out.Valid = true;
    return Out;
  }
  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    if (!GEP->getSourceElementType()->isIntegerTy(8) ||
        GEP->getNumIndices() != 1)
      return IntAffine();
    IntAffine Base = parsePointerAffine(GEP->getPointerOperand(), Depth + 1,
                                        Header, Pred, PathPreds);
    IntAffine Index = parseIntegerAffine(*GEP->idx_begin(), Depth + 1,
                                         Header, Pred, PathPreds);
    return combineAffine(Base, Index, false);
  }
  auto *Op = dyn_cast<Operator>(V);
  if (Op && Op->getOpcode() == Instruction::IntToPtr)
    return parseIntegerAffine(Op->getOperand(0), Depth + 1, Header, Pred,
                              PathPreds);
  return IntAffine();
}

bool sameFrameAddress(Value *A, Value *B) {
  if (A == B) return true;
  IntAffine PA = parsePointerAffine(A), PB = parsePointerAffine(B);
  return sameAffineTerms(PA, PB) && !PA.Terms.empty() &&
         PA.Offset == PB.Offset;
}

bool sameFrameAddressAlongUniquePath(Value *A, Value *B,
                                            BasicBlock *Source,
                                            BasicBlock *Header) {
  if (!Source || !Header) return false;
  DenseMap<BasicBlock *, BasicBlock *> PathPreds;
  SmallPtrSet<BasicBlock *, 16> Seen;
  BasicBlock *Current = Source;
  while (Current != Header && Seen.insert(Current).second && Seen.size() <= 64) {
    auto *Br = dyn_cast<BranchInst>(Current->getTerminator());
    if (!Br || !Br->isUnconditional()) return false;
    BasicBlock *Next = Br->getSuccessor(0);
    PathPreds[Next] = Current;
    Current = Next;
  }
  if (Current != Header) return false;
  IntAffine PA = parsePointerAffine(A, 0, nullptr, nullptr, &PathPreds);
  IntAffine PB = parsePointerAffine(B, 0, nullptr, nullptr, &PathPreds);
  return sameAffineTerms(PA, PB) && !PA.Terms.empty() &&
         PA.Offset == PB.Offset;
}

bool frameAccessesProvablyDisjoint(Value *A, Type *ATy, Value *B,
                                          Type *BTy,
                                          const DataLayout &DL) {
  IntAffine PA = parsePointerAffine(A), PB = parsePointerAffine(B);
  if (!PA.Valid || !PB.Valid || PA.Terms.empty() || PB.Terms.empty())
    return false;
  if (definitelyDistinctAffineObjects(PA, PB)) return true;
  if (!sameAffineTerms(PA, PB)) return false;
  TypeSize AS = DL.getTypeStoreSize(ATy), BS = DL.getTypeStoreSize(BTy);
  if (AS.isScalable() || BS.isScalable()) return false;
  uint64_t ABytes = AS.getFixedValue(), BBytes = BS.getFixedValue();
  if (ABytes > uint64_t(std::numeric_limits<int64_t>::max()) ||
      BBytes > uint64_t(std::numeric_limits<int64_t>::max()))
    return false;
  int64_t ABegin = PA.Offset.getSExtValue(), BBegin = PB.Offset.getSExtValue();
  if (ABegin > std::numeric_limits<int64_t>::max() - int64_t(ABytes) ||
      BBegin > std::numeric_limits<int64_t>::max() - int64_t(BBytes))
    return false;
  return ABegin + int64_t(ABytes) <= BBegin ||
         BBegin + int64_t(BBytes) <= ABegin;
}

} // namespace brighten_ollvm_deobf
