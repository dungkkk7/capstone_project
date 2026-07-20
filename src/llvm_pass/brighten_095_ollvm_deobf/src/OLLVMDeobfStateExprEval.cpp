#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

PHINode *findStateRoot(Value *V, unsigned Depth) {
  if (Depth > 8) return nullptr;
  if (auto *PN = dyn_cast<PHINode>(V)) return PN;
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    if (II->getIntrinsicID() == Intrinsic::bswap)
      return findStateRoot(II->getArgOperand(0), Depth + 1);
    if ((II->getIntrinsicID() == Intrinsic::fshl ||
         II->getIntrinsicID() == Intrinsic::fshr) &&
        II->getArgOperand(0) == II->getArgOperand(1) &&
        isa<ConstantInt>(II->getArgOperand(2)))
      return findStateRoot(II->getArgOperand(0), Depth + 1);
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || !BO->getType()->isIntegerTy()) return nullptr;
  Value *A = BO->getOperand(0), *B = BO->getOperand(1);
  if (isa<ConstantInt>(B)) return findStateRoot(A, Depth + 1);
  if (BO->isCommutative() && isa<ConstantInt>(A))
    return findStateRoot(B, Depth + 1);
  return nullptr;
}

std::optional<bool> evalStatePredicate(Value *V, PHINode *Root,
                                              const APInt &State,
                                              unsigned Depth) {
  if (Depth > 12) return std::nullopt;
  if (auto *C = dyn_cast<ConstantInt>(V))
    if (C->getType()->isIntegerTy(1)) return !C->isZero();
  if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
    auto L = evalStateExpr(Cmp->getOperand(0), Root, State, Depth + 1);
    auto R = evalStateExpr(Cmp->getOperand(1), Root, State, Depth + 1);
    if (!L || !R || L->getBitWidth() != R->getBitWidth()) return std::nullopt;
    switch (Cmp->getPredicate()) {
    case ICmpInst::ICMP_EQ: return *L == *R;
    case ICmpInst::ICMP_NE: return *L != *R;
    case ICmpInst::ICMP_UGT: return L->ugt(*R);
    case ICmpInst::ICMP_UGE: return L->uge(*R);
    case ICmpInst::ICMP_ULT: return L->ult(*R);
    case ICmpInst::ICMP_ULE: return L->ule(*R);
    case ICmpInst::ICMP_SGT: return L->sgt(*R);
    case ICmpInst::ICMP_SGE: return L->sge(*R);
    case ICmpInst::ICMP_SLT: return L->slt(*R);
    case ICmpInst::ICMP_SLE: return L->sle(*R);
    default: return std::nullopt;
    }
  }
  if (auto *BO = dyn_cast<BinaryOperator>(V);
      BO && BO->getType()->isIntegerTy(1) &&
      !hasPoisonGeneratingFlags(BO)) {
    auto L = evalStatePredicate(BO->getOperand(0), Root, State, Depth + 1);
    auto R = evalStatePredicate(BO->getOperand(1), Root, State, Depth + 1);
    if (!L || !R) return std::nullopt;
    if (BO->getOpcode() == Instruction::And) return *L && *R;
    if (BO->getOpcode() == Instruction::Or) return *L || *R;
    if (BO->getOpcode() == Instruction::Xor) return *L != *R;
  }
  auto E = evalStateExpr(V, Root, State, Depth + 1);
  if (E && E->getBitWidth() == 1) return !E->isZero();
  return std::nullopt;
}

std::optional<APInt> evalStateExpr(Value *V, PHINode *Root,
                                          const APInt &State,
                                          unsigned Depth) {
  if (Depth > 12) return std::nullopt;
  if (V == Root) return State;
  if (auto *CI = dyn_cast<ConstantInt>(V)) return CI->getValue();
  if (auto *Cast = dyn_cast<CastInst>(V)) {
    auto Op = evalStateExpr(Cast->getOperand(0), Root, State, Depth + 1);
    if (!Op || !Cast->getType()->isIntegerTy()) return std::nullopt;
    unsigned Width = Cast->getType()->getIntegerBitWidth();
    switch (Cast->getOpcode()) {
    case Instruction::Trunc:
      if (cast<TruncInst>(Cast)->hasNoUnsignedWrap()) return std::nullopt;
      return Op->trunc(Width);
    case Instruction::ZExt: return Op->zext(Width);
    case Instruction::SExt: return Op->sext(Width);
    case Instruction::BitCast:
      return Op->getBitWidth() == Width ? Op : std::optional<APInt>();
    default: return std::nullopt;
    }
  }
  if (auto *Select = dyn_cast<SelectInst>(V)) {
    auto T = evalStateExpr(Select->getTrueValue(), Root, State, Depth + 1);
    auto F = evalStateExpr(Select->getFalseValue(), Root, State, Depth + 1);
    if (!T || !F) return std::nullopt;
    if (*T == *F) return T;
    auto C = evalStatePredicate(Select->getCondition(), Root, State,
                                Depth + 1);
    return C ? (*C ? T : F) : std::nullopt;
  }
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    auto Op = evalStateExpr(II->getArgOperand(0), Root, State, Depth + 1);
    if (!Op) return std::nullopt;
    if (II->getIntrinsicID() == Intrinsic::bswap)
      return Op->getBitWidth() % 16 == 0
                 ? std::optional<APInt>(Op->byteSwap())
                 : std::nullopt;
    auto *Amount = dyn_cast<ConstantInt>(II->getArgOperand(2));
    if (!Amount || II->getArgOperand(0) != II->getArgOperand(1))
      return std::nullopt;
    unsigned Rotate = Amount->getValue().urem(Op->getBitWidth());
    if (II->getIntrinsicID() == Intrinsic::fshl) return Op->rotl(Rotate);
    if (II->getIntrinsicID() == Intrinsic::fshr) return Op->rotr(Rotate);
    return std::nullopt;
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || hasPoisonGeneratingFlags(BO)) return std::nullopt;
  auto L = evalStateExpr(BO->getOperand(0), Root, State, Depth + 1);
  auto R = evalStateExpr(BO->getOperand(1), Root, State, Depth + 1);
  if (!L || !R || L->getBitWidth() != R->getBitWidth()) return std::nullopt;
  switch (BO->getOpcode()) {
  case Instruction::Add: return *L + *R;
  case Instruction::Sub: return *L - *R;
  case Instruction::Mul: return *L * *R;
  case Instruction::Xor: return *L ^ *R;
  case Instruction::And: return *L & *R;
  case Instruction::Or: return *L | *R;
  case Instruction::Shl:
  case Instruction::LShr:
  case Instruction::AShr: {
    uint64_t Amount = R->getLimitedValue(L->getBitWidth());
    if (Amount >= L->getBitWidth()) return std::nullopt;
    if (BO->getOpcode() == Instruction::Shl) return L->shl(Amount);
    if (BO->getOpcode() == Instruction::LShr) return L->lshr(Amount);
    return L->ashr(Amount);
  }
  default: return std::nullopt;
  }
}

std::optional<APInt> decodeStateExpr(Value *V, PHINode *Root,
                                            const APInt &Encoded,
                                            unsigned Depth) {
  if (Depth > 12) return std::nullopt;
  if (V == Root) return Encoded;
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    if (II->getIntrinsicID() == Intrinsic::bswap) {
      if (Encoded.getBitWidth() % 16 != 0) return std::nullopt;
      return decodeStateExpr(II->getArgOperand(0), Root, Encoded.byteSwap(),
                             Depth + 1);
    }
    auto *Amount = dyn_cast<ConstantInt>(II->getArgOperand(2));
    if (!Amount || II->getArgOperand(0) != II->getArgOperand(1))
      return std::nullopt;
    unsigned Rotate = Amount->getValue().urem(Encoded.getBitWidth());
    if (II->getIntrinsicID() == Intrinsic::fshl)
      return decodeStateExpr(II->getArgOperand(0), Root,
                             Encoded.rotr(Rotate), Depth + 1);
    if (II->getIntrinsicID() == Intrinsic::fshr)
      return decodeStateExpr(II->getArgOperand(0), Root,
                             Encoded.rotl(Rotate), Depth + 1);
    return std::nullopt;
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || hasPoisonGeneratingFlags(BO)) return std::nullopt;
  auto *LC = dyn_cast<ConstantInt>(BO->getOperand(0));
  auto *RC = dyn_cast<ConstantInt>(BO->getOperand(1));
  Value *Variable = nullptr;
  APInt Next = Encoded;
  switch (BO->getOpcode()) {
  case Instruction::Add:
    if (RC) { Variable = BO->getOperand(0); Next -= RC->getValue(); }
    else if (LC) { Variable = BO->getOperand(1); Next -= LC->getValue(); }
    break;
  case Instruction::Sub:
    if (RC) { Variable = BO->getOperand(0); Next += RC->getValue(); }
    else if (LC) { Variable = BO->getOperand(1); Next = LC->getValue() - Next; }
    break;
  case Instruction::Xor:
    if (RC) { Variable = BO->getOperand(0); Next ^= RC->getValue(); }
    else if (LC) { Variable = BO->getOperand(1); Next ^= LC->getValue(); }
    break;
  case Instruction::Mul: {
    ConstantInt *C = RC ? RC : LC;
    if (!C || !C->getValue()[0]) break;
    Variable = RC ? BO->getOperand(0) : BO->getOperand(1);
    Next *= C->getValue().multiplicativeInverse();
    break;
  }
  default: break;
  }
  if (!Variable) return std::nullopt;
  return decodeStateExpr(Variable, Root, Next, Depth + 1);
}

} // namespace brighten_ollvm_deobf
