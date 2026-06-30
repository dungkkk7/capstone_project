// Canonicalize cac compare bi obfuscate.
// - Nhan dien pattern xor/sub/shift
// - Dua ve ICmp truc tiep de pass sau hieu
#include "BrightenRepairPass.h"

#include <vector>

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

bool BrightenRepairPass::CanonicalizeObfuscatedCompares(Module &M) {
  // Mục tiêu: nhận diện các mẫu compare đã bị obfuscate và đưa về dạng
  // ICmp trực tiếp, giúp các pass sau hiểu semantic tốt hơn.
  bool Changed = false;
  std::vector<ICmpInst *> Worklist;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Cmp = dyn_cast<ICmpInst>(&I);
        if (!Cmp) {
          continue;
        }
        if (Cmp->getOperand(0)->getType()->isIntegerTy(32)) {
          Worklist.push_back(Cmp);
        }
      }
    }
  }

  for (ICmpInst *Cmp : Worklist) {
    // Xử lý theo worklist để an toàn khi xóa/replace instruction.
    Value *L = Cmp->getOperand(0);
    Value *R = Cmp->getOperand(1);
    IRBuilder<> B(Cmp);

    // Mẫu 1: (xor a, b) == 0  <=>  a == b
    //        (xor a, b) != 0  <=>  a != b
    if ((Cmp->getPredicate() == ICmpInst::ICMP_EQ || Cmp->getPredicate() == ICmpInst::ICMP_NE) &&
        (IsConstInt(R, 0) || IsConstInt(L, 0))) {
      Value *X = IsConstInt(R, 0) ? L : R;
      if (auto *Xor = dyn_cast<BinaryOperator>(X)) {
        if (Xor->getOpcode() == Instruction::Xor && Xor->getType()->isIntegerTy(32)) {
          auto Pred = (Cmp->getPredicate() == ICmpInst::ICMP_EQ) ? ICmpInst::ICMP_EQ : ICmpInst::ICMP_NE;
          Value *NewCmp = B.CreateICmp(Pred, Xor->getOperand(0), Xor->getOperand(1));
          Cmp->replaceAllUsesWith(NewCmp);
          Cmp->eraseFromParent();
          Changed = true;
          continue;
        }
      }
    }

    if (Cmp->getPredicate() != ICmpInst::ICMP_NE || !(IsConstInt(R, 0) || IsConstInt(L, 0))) {
      continue;
    }

    // Chuẩn hoá lớp vỏ (and x,1) quanh root nếu có.
    Value *Root = IsConstInt(R, 0) ? L : R;
    if (auto *And = dyn_cast<BinaryOperator>(Root)) {
      if (And->getOpcode() == Instruction::And) {
        if (IsConstInt(And->getOperand(1), 1)) {
          Root = And->getOperand(0);
        } else if (IsConstInt(And->getOperand(0), 1)) {
          Root = And->getOperand(1);
        }
      }
    }

    auto *LShr = dyn_cast<BinaryOperator>(Root);
    if (!LShr || LShr->getOpcode() != Instruction::LShr || !IsConstInt(LShr->getOperand(1), 31)) {
      continue;
    }

    Value *EqInput = nullptr;
    Value *Pre = LShr->getOperand(0);

    // Mẫu 2: biến thể branchless-equality dùng xor/sub/ashr/lshr.
    auto *SubA = dyn_cast<BinaryOperator>(Pre);
    if (SubA && SubA->getOpcode() == Instruction::Sub) {
      auto *Xor = dyn_cast<BinaryOperator>(SubA->getOperand(0));
      auto *S = dyn_cast<BinaryOperator>(SubA->getOperand(1));
      if (Xor && Xor->getOpcode() == Instruction::Xor && S && S->getOpcode() == Instruction::AShr &&
          IsConstInt(S->getOperand(1), 31)) {
        Value *T = S->getOperand(0);
        Value *X = nullptr;
        if ((Xor->getOperand(0) == T && Xor->getOperand(1) == S) ||
            (Xor->getOperand(1) == T && Xor->getOperand(0) == S)) {
          if (MatchAddIntMin32(T, X)) {
            EqInput = X;
          }
        }
      }
    }

    if (!EqInput) {
      // Mẫu 3: biến thể khác của branchless-equality dùng shl + ashr + and.
      auto *SubB = dyn_cast<BinaryOperator>(Pre);
      if (SubB && SubB->getOpcode() == Instruction::Sub) {
        Value *T = SubB->getOperand(0);
        auto *And = dyn_cast<BinaryOperator>(SubB->getOperand(1));
        if (And && And->getOpcode() == Instruction::And) {
          Value *A0 = And->getOperand(0);
          Value *A1 = And->getOperand(1);
          auto *Shl = dyn_cast<BinaryOperator>(A0);
          auto *S = dyn_cast<BinaryOperator>(A1);
          if (!(Shl && Shl->getOpcode() == Instruction::Shl && IsConstInt(Shl->getOperand(1), 1) && S &&
                S->getOpcode() == Instruction::AShr && IsConstInt(S->getOperand(1), 31) &&
                Shl->getOperand(0) == T && S->getOperand(0) == T)) {
            Shl = dyn_cast<BinaryOperator>(A1);
            S = dyn_cast<BinaryOperator>(A0);
          }
          if (Shl && Shl->getOpcode() == Instruction::Shl && IsConstInt(Shl->getOperand(1), 1) && S &&
              S->getOpcode() == Instruction::AShr && IsConstInt(S->getOperand(1), 31) &&
              Shl->getOperand(0) == T && S->getOperand(0) == T) {
            Value *X = nullptr;
            if (MatchAddIntMin32(T, X)) {
              EqInput = X;
            }
          }
        }
      }
    }

    if (!EqInput) {
      continue;
    }

    // Canonical form cuối cùng: EqInput == 0.
    Value *Zero = ConstantInt::get(EqInput->getType(), 0);
    Value *NewCmp = B.CreateICmpEQ(EqInput, Zero);
    Cmp->replaceAllUsesWith(NewCmp);
    Cmp->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair

