#ifndef DEOBFUSCATE_095_RULE_ENGINE_SUPPORT_H
#define DEOBFUSCATE_095_RULE_ENGINE_SUPPORT_H

#include "llvm/ADT/APInt.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

#include <optional>

namespace deobfuscate095::rule_detail {

using namespace llvm;

struct NamedBoolean {
  const char *Name = nullptr;
  bool Value = false;
};

inline std::optional<unsigned> valueOpcode(Value *V) {
  if (auto *I = dyn_cast<Instruction>(V))
    return I->getOpcode();
  if (auto *CE = dyn_cast<ConstantExpr>(V))
    return CE->getOpcode();
  return std::nullopt;
}

inline Value *operand(Value *V, unsigned Index) {
  auto *U = dyn_cast<User>(V);
  return U && Index < U->getNumOperands() ? U->getOperand(Index) : nullptr;
}

inline bool isDirectlyIndeterminate(Value *V) {
  return isa<UndefValue>(V) || isa<PoisonValue>(V);
}

inline bool hasPoisonRefiningFlags(Value *V) {
  if (auto *OBO = dyn_cast<OverflowingBinaryOperator>(V))
    if (OBO->hasNoSignedWrap() || OBO->hasNoUnsignedWrap())
      return true;
  if (auto *PEO = dyn_cast<PossiblyExactOperator>(V))
    if (PEO->isExact())
      return true;
  return false;
}

inline bool isConstant(Value *V, int64_t Expected, IntegerType *Type) {
  auto *CI = dyn_cast_or_null<ConstantInt>(V);
  if (!CI || CI->getType() != Type)
    return false;
  APInt Value(Type->getBitWidth(), static_cast<uint64_t>(Expected), true);
  return CI->getValue() == Value;
}

inline bool isZero(Value *V, IntegerType *Type) {
  return isConstant(V, 0, Type);
}
inline bool isOne(Value *V, IntegerType *Type) {
  return isConstant(V, 1, Type);
}
inline bool isAllOnes(Value *V, IntegerType *Type) {
  auto *CI = dyn_cast_or_null<ConstantInt>(V);
  return CI && CI->getType() == Type && CI->getValue().isAllOnes();
}

inline bool sameValue(Value *A, Value *B) {
  return A == B && A && A->getType() == B->getType() &&
         !isDirectlyIndeterminate(A);
}

inline bool extractNot(Value *V, Value *&Base) {
  auto *Type = dyn_cast_or_null<IntegerType>(V ? V->getType() : nullptr);
  auto Opcode = valueOpcode(V);
  if (!Type || !Opcode || *Opcode != Instruction::Xor)
    return false;
  Value *L = operand(V, 0);
  Value *R = operand(V, 1);
  if (isAllOnes(R, Type)) {
    Base = L;
    return true;
  }
  if (isAllOnes(L, Type)) {
    Base = R;
    return true;
  }
  return false;
}

inline bool isAndComplement(Value *V) {
  auto Opcode = valueOpcode(V);
  if (!Opcode || *Opcode != Instruction::And)
    return false;
  Value *L = operand(V, 0);
  Value *R = operand(V, 1);
  Value *Base = nullptr;
  return (extractNot(L, Base) && sameValue(Base, R)) ||
         (extractNot(R, Base) && sameValue(Base, L));
}

inline bool isOrComplement(Value *V) {
  auto Opcode = valueOpcode(V);
  if (!Opcode || *Opcode != Instruction::Or)
    return false;
  Value *L = operand(V, 0);
  Value *R = operand(V, 1);
  Value *Base = nullptr;
  return (extractNot(L, Base) && sameValue(Base, R)) ||
         (extractNot(R, Base) && sameValue(Base, L));
}

inline bool isXorSelf(Value *V) {
  auto Opcode = valueOpcode(V);
  return Opcode && *Opcode == Instruction::Xor &&
         sameValue(operand(V, 0), operand(V, 1));
}

inline bool splitZeroComparison(ICmpInst &Cmp, Value *&Expr) {
  auto *Type = dyn_cast<IntegerType>(Cmp.getOperand(0)->getType());
  if (!Type)
    return false;
  if (isZero(Cmp.getOperand(1), Type)) {
    Expr = Cmp.getOperand(0);
    return true;
  }
  if ((Cmp.getPredicate() == ICmpInst::ICMP_EQ ||
       Cmp.getPredicate() == ICmpInst::ICMP_NE) &&
      isZero(Cmp.getOperand(0), Type)) {
    Expr = Cmp.getOperand(1);
    return true;
  }
  return false;
}

inline bool isOrWithOddConstant(Value *V) {
  auto *Type = dyn_cast_or_null<IntegerType>(V ? V->getType() : nullptr);
  auto Opcode = valueOpcode(V);
  if (!Type || !Opcode || *Opcode != Instruction::Or)
    return false;
  for (Value *Op : {operand(V, 0), operand(V, 1)})
    if (auto *CI = dyn_cast_or_null<ConstantInt>(Op))
      if (CI->getType() == Type && CI->getValue()[0])
        return true;
  return false;
}

inline bool isOrWithAllOnes(Value *V) {
  auto *Type = dyn_cast_or_null<IntegerType>(V ? V->getType() : nullptr);
  auto Opcode = valueOpcode(V);
  return Type && Opcode && *Opcode == Instruction::Or &&
         (isAllOnes(operand(V, 0), Type) ||
          isAllOnes(operand(V, 1), Type));
}

inline bool isAndWithZero(Value *V) {
  auto *Type = dyn_cast_or_null<IntegerType>(V ? V->getType() : nullptr);
  auto Opcode = valueOpcode(V);
  return Type && Opcode && *Opcode == Instruction::And &&
         (isZero(operand(V, 0), Type) ||
          isZero(operand(V, 1), Type));
}

inline std::optional<bool> evaluateConstantICmp(ICmpInst &Cmp) {
  auto *L = dyn_cast<ConstantInt>(Cmp.getOperand(0));
  auto *R = dyn_cast<ConstantInt>(Cmp.getOperand(1));
  if (!L || !R || L->getType() != R->getType())
    return std::nullopt;
  const APInt &A = L->getValue();
  const APInt &B = R->getValue();
  switch (Cmp.getPredicate()) {
  case ICmpInst::ICMP_EQ: return A == B;
  case ICmpInst::ICMP_NE: return A != B;
  case ICmpInst::ICMP_ULT: return A.ult(B);
  case ICmpInst::ICMP_ULE: return A.ule(B);
  case ICmpInst::ICMP_UGT: return A.ugt(B);
  case ICmpInst::ICMP_UGE: return A.uge(B);
  case ICmpInst::ICMP_SLT: return A.slt(B);
  case ICmpInst::ICMP_SLE: return A.sle(B);
  case ICmpInst::ICMP_SGT: return A.sgt(B);
  case ICmpInst::ICMP_SGE: return A.sge(B);
  default: return std::nullopt;
  }
}

inline void replaceBranch(BranchInst &Branch, bool Condition) {
  BasicBlock *Taken = Branch.getSuccessor(Condition ? 0 : 1);
  BasicBlock *Dead = Branch.getSuccessor(Condition ? 1 : 0);
  if (Taken != Dead)
    Dead->removePredecessor(Branch.getParent(), true);
  BranchInst::Create(Taken, &Branch);
  Branch.eraseFromParent();
}

} // namespace deobfuscate095::rule_detail

#endif
