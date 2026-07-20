#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

bool samePair(Value *A0, Value *A1, Value *B0, Value *B1) {
  return (A0 == B0 && A1 == B1) || (A0 == B1 && A1 == B0);
}

bool matchBin(Value *V, unsigned Opcode, Value *&A, Value *&B) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Opcode)
    return false;
  A = BO->getOperand(0);
  B = BO->getOperand(1);
  return true;
}

bool matchAllOnesXor(Value *V, Value *&X) {
  Value *A = nullptr, *B = nullptr;
  if (!matchBin(V, Instruction::Xor, A, B))
    return false;
  auto IsAllOnes = [](Value *C) {
    auto *CI = dyn_cast<ConstantInt>(C);
    return CI && CI->isMinusOne();
  };
  if (IsAllOnes(A)) { X = B; return true; }
  if (IsAllOnes(B)) { X = A; return true; }
  return false;
}

Value *createBinLike(BinaryOperator &Old, unsigned Opcode, Value *A,
                            Value *B) {
  IRBuilder<> Builder(&Old);
  return Builder.CreateBinOp(static_cast<Instruction::BinaryOps>(Opcode), A, B,
                             Old.getName() + ".deobf");
}

// Exact APInt/bit-vector identities only.  No rule here assumes unbounded
// integer arithmetic or crosses a memory/call boundary.
Value *matchCanonicalRewrite(BinaryOperator &I, bool &InstSub) {
  if (!I.getType()->isIntOrIntVectorTy() || hasPoisonGeneratingFlags(&I))
    return nullptr;
  Value *A = I.getOperand(0), *B = I.getOperand(1);
  Value *X = nullptr, *Y = nullptr, *P = nullptr, *Q = nullptr;
  auto IsZeroConstant = [](Value *V) {
    auto *C = dyn_cast<Constant>(V);
    return C && C->isNullValue();
  };
  auto IsAllOnesConstant = [](Value *V) {
    auto *C = dyn_cast<Constant>(V);
    return C && C->isAllOnesValue();
  };

  // Neutral elements, valid at every fixed integer width.
  if ((I.getOpcode() == Instruction::Add ||
       I.getOpcode() == Instruction::Xor ||
       I.getOpcode() == Instruction::Or) && IsZeroConstant(B))
    return A;
  if (I.getOpcode() == Instruction::Add && IsZeroConstant(A)) return B;
  if (I.getOpcode() == Instruction::And && IsAllOnesConstant(B)) return A;
  if (I.getOpcode() == Instruction::And && IsAllOnesConstant(A)) return B;

  // ~~x, with LLVM's canonical not representation xor -1.
  if (I.getOpcode() == Instruction::Xor && IsAllOnesConstant(B) &&
      matchAllOnesXor(A, X) && !hasPoisonGeneratingFlags(A))
    return X;

  // (x + C) - C and (x - C) + C.
  if ((I.getOpcode() == Instruction::Sub ||
       I.getOpcode() == Instruction::Add) && isa<ConstantInt>(B)) {
    unsigned InnerOp = I.getOpcode() == Instruction::Sub
                           ? Instruction::Add : Instruction::Sub;
    if (matchBin(A, InnerOp, X, Y) && Y == B &&
        !hasPoisonGeneratingFlags(A))
      return X;
  }

  // (x & ~C) + (x | C) == x + (x ^ C).
  if (I.getOpcode() == Instruction::Add) {
    Value *AndV = A, *OrV = B;
    if (!isa<BinaryOperator>(AndV) ||
        cast<BinaryOperator>(AndV)->getOpcode() != Instruction::And)
      std::swap(AndV, OrV);
    Value *AndX = nullptr, *AndMask = nullptr, *OrX = nullptr, *OrMask = nullptr;
    if (matchBin(AndV, Instruction::And, AndX, AndMask) &&
        matchBin(OrV, Instruction::Or, OrX, OrMask)) {
      auto TryMask = [&](Value *VX, Value *NotMask, Value *OX,
                         Value *Mask) -> Value * {
        auto *NC = dyn_cast<ConstantInt>(NotMask);
        auto *C = dyn_cast<ConstantInt>(Mask);
        if (VX != OX || !NC || !C || NC->getValue() != ~C->getValue())
          return nullptr;
        Value *XC = createBinLike(I, Instruction::Xor, VX, Mask);
        InstSub = true;
        return createBinLike(I, Instruction::Add, VX, XC);
      };
      if (Value *R = TryMask(AndX, AndMask, OrX, OrMask)) return R;
      if (Value *R = TryMask(AndMask, AndX, OrX, OrMask)) return R;
      if (Value *R = TryMask(AndX, AndMask, OrMask, OrX)) return R;
      if (Value *R = TryMask(AndMask, AndX, OrMask, OrX)) return R;
    }
  }

  // (x | y) + (x & y) == x + y, including commuted outer operands.
  if (I.getOpcode() == Instruction::Add) {
    Value *OrV = A, *AndV = B;
    if (!matchBin(OrV, Instruction::Or, X, Y)) {
      std::swap(OrV, AndV);
      X = Y = nullptr;
    }
    if (matchBin(OrV, Instruction::Or, X, Y) &&
        matchBin(AndV, Instruction::And, P, Q) &&
        samePair(X, Y, P, Q)) {
      InstSub = true;
      return createBinLike(I, Instruction::Add, X, Y);
    }
  }

  // (x ^ y) + 2*(x & y) == x + y.
  if (I.getOpcode() == Instruction::Add) {
    Value *XorV = A, *CarryV = B;
    if (!matchBin(XorV, Instruction::Xor, X, Y)) {
      std::swap(XorV, CarryV);
      X = Y = nullptr;
    }
    if (!matchBin(XorV, Instruction::Xor, X, Y)) return nullptr;
    Value *M0 = nullptr, *M1 = nullptr;
    if (matchBin(CarryV, Instruction::Mul, M0, M1)) {
      auto IsTwo = [](Value *V) {
        auto *C = dyn_cast<ConstantInt>(V);
        return C && C->equalsInt(2);
      };
      Value *AndV = IsTwo(M0) ? M1 : (IsTwo(M1) ? M0 : nullptr);
      if (AndV && matchBin(AndV, Instruction::And, P, Q) &&
          samePair(X, Y, P, Q)) {
        InstSub = true;
        return createBinLike(I, Instruction::Add, X, Y);
      }
    }
    Value *Shifted = nullptr, *One = nullptr;
    if (matchBin(CarryV, Instruction::Shl, Shifted, One)) {
      auto *C = dyn_cast<ConstantInt>(One);
      if (C && C->isOne() &&
          matchBin(Shifted, Instruction::And, P, Q) &&
          samePair(X, Y, P, Q)) {
        InstSub = true;
        return createBinLike(I, Instruction::Add, X, Y);
      }
    }
  }

  // (x + y) - (x | y) == x & y.
  if (I.getOpcode() == Instruction::Sub &&
      matchBin(A, Instruction::Add, X, Y) &&
      matchBin(B, Instruction::Or, P, Q) && samePair(X, Y, P, Q) &&
      !hasPoisonGeneratingFlags(A)) {
    InstSub = true;
    return createBinLike(I, Instruction::And, X, Y);
  }

  // (a & b) | (a ^ b) == a | b.
  if (I.getOpcode() == Instruction::Or &&
      matchBin(A, Instruction::And, X, Y) &&
      matchBin(B, Instruction::Xor, P, Q) && samePair(X, Y, P, Q)) {
    InstSub = true;
    return createBinLike(I, Instruction::Or, X, Y);
  }

  // (~a & b) | (a & ~b) == a ^ b.
  if (I.getOpcode() == Instruction::Or &&
      matchBin(A, Instruction::And, X, Y) &&
      matchBin(B, Instruction::And, P, Q)) {
    Value *NX = nullptr, *NQ = nullptr;
    if (matchAllOnesXor(X, NX) && matchAllOnesXor(Q, NQ) &&
        NX == P && Y == NQ) {
      InstSub = true;
      return createBinLike(I, Instruction::Xor, P, Y);
    }
    if (matchAllOnesXor(Y, NX) && matchAllOnesXor(P, NQ) &&
        NX == Q && X == NQ) {
      InstSub = true;
      return createBinLike(I, Instruction::Xor, X, Q);
    }
  }
  return nullptr;
}

bool isOne(const Value *V) {
  const auto *C = dyn_cast<ConstantInt>(V);
  return C && C->isOne();
}

bool isZero(const Value *V) {
  const auto *C = dyn_cast<ConstantInt>(V);
  return C && C->isZero();
}

bool isAdjacentProduct(Value *V) {
  Value *A = nullptr, *B = nullptr;
  if (!matchBin(V, Instruction::Mul, A, B) || hasPoisonGeneratingFlags(V))
    return false;
  auto IsMinusOneFrom = [](Value *Candidate, Value *Root) {
    Value *L = nullptr, *R = nullptr;
    if (matchBin(Candidate, Instruction::Sub, L, R))
      return L == Root && isOne(R) && !hasPoisonGeneratingFlags(Candidate);
    if (matchBin(Candidate, Instruction::Add, L, R)) {
      auto *C = dyn_cast<ConstantInt>(R);
      return L == Root && C && C->isMinusOne() &&
             !hasPoisonGeneratingFlags(Candidate);
    }
    return false;
  };
  return IsMinusOneFrom(A, B) || IsMinusOneFrom(B, A);
}

} // namespace brighten_ollvm_deobf
