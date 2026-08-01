#include "BrightenRuntimeHelperPass.h"

#include <algorithm>
#include <csignal>

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/ADT/SmallVector.h"

namespace brighten_runtime {

using namespace llvm;

namespace {

struct DivideShape {
  BinaryOperator *Division = nullptr;
  Value *Dividend = nullptr;
  Value *Divisor = nullptr;
  bool IsSigned = false;
};

static bool IsZero(const Value *V, Type *Ty) {
  const auto *C = dyn_cast<ConstantInt>(V);
  return C && C->getType() == Ty && C->isZero();
}

static bool IsMinusOne(const Value *V, Type *Ty) {
  const auto *C = dyn_cast<ConstantInt>(V);
  return C && C->getType() == Ty && C->isMinusOne();
}

static bool IsSignedMinimum(const Value *V, Type *Ty) {
  const auto *C = dyn_cast<ConstantInt>(V);
  return C && C->getType() == Ty && C->getValue().isMinSignedValue();
}

static bool IsEqualityOf(const ICmpInst *Cmp, const Value *Needle,
                         bool (*MatchesOther)(const Value *, Type *)) {
  if (!Cmp || Cmp->getPredicate() != ICmpInst::ICMP_EQ)
    return false;
  Type *Ty = Needle->getType();
  return (Cmp->getOperand(0) == Needle && MatchesOther(Cmp->getOperand(1), Ty)) ||
         (Cmp->getOperand(1) == Needle && MatchesOther(Cmp->getOperand(0), Ty));
}

static bool IsZeroEquivalentTo(const Value *GuardValue,
                               const Value *Divisor) {
  if (GuardValue == Divisor)
    return true;
  // sext/zext preserve whether an integer value is zero.
  if (const auto *Cast = dyn_cast<CastInst>(Divisor))
    if ((Cast->getOpcode() == Instruction::SExt ||
         Cast->getOpcode() == Instruction::ZExt) &&
        Cast->getOperand(0) == GuardValue)
      return true;

  // McSema commonly guards a widened register before reconstructing the
  // signed divisor with `ashr exact (shl X, K), K`.  Both shifts must have
  // the same constant amount; this is a structural proof, not a heuristic.
  const auto *AShr = dyn_cast<BinaryOperator>(Divisor);
  if (!AShr || AShr->getOpcode() != Instruction::AShr || !AShr->isExact() ||
      AShr->getOperand(0) != GuardValue)
    return false;
  const auto *Shl = dyn_cast<BinaryOperator>(GuardValue);
  const auto *RightShift = dyn_cast<ConstantInt>(AShr->getOperand(1));
  const auto *LeftShift = Shl ? dyn_cast<ConstantInt>(Shl->getOperand(1))
                              : nullptr;
  return Shl && Shl->getOpcode() == Instruction::Shl && RightShift &&
         LeftShift && RightShift->getValue() == LeftShift->getValue();
}

static bool IsZeroDivisorCondition(const Value *Condition,
                                   const DivideShape &Shape,
                                   bool FaultOnTrue) {
  const auto *Cmp = dyn_cast<ICmpInst>(Condition);
  if (!Cmp)
    return false;
  const auto Pred = Cmp->getPredicate();
  if ((FaultOnTrue && Pred != ICmpInst::ICMP_EQ) ||
      (!FaultOnTrue && Pred != ICmpInst::ICMP_NE))
    return false;
  // Normalize the false edge of "divisor != 0" to an equality test before
  // comparing the exact divisor SSA value.
  return (IsZero(Cmp->getOperand(0), Cmp->getOperand(0)->getType()) &&
          IsZeroEquivalentTo(Cmp->getOperand(1), Shape.Divisor)) ||
         (IsZero(Cmp->getOperand(1), Cmp->getOperand(1)->getType()) &&
          IsZeroEquivalentTo(Cmp->getOperand(0), Shape.Divisor));
}

static bool IsSignedOverflowCondition(const Value *Condition,
                                      const DivideShape &Shape,
                                      bool FaultOnTrue) {
  // One accepted form is exactly
  //   (dividend == INT_MIN) & (divisor == -1)
  // on the fault edge.  Other algebraically equivalent forms are deliberately
  // left intact until they are proved by a predicate-specific pass.
  if (FaultOnTrue) {
    const auto *And = dyn_cast<BinaryOperator>(Condition);
    if (And && And->getOpcode() == Instruction::And) {
      const auto *Left = dyn_cast<ICmpInst>(And->getOperand(0));
      const auto *Right = dyn_cast<ICmpInst>(And->getOperand(1));
      if ((IsEqualityOf(Left, Shape.Dividend, IsSignedMinimum) &&
           IsEqualityOf(Right, Shape.Divisor, IsMinusOne)) ||
          (IsEqualityOf(Right, Shape.Dividend, IsSignedMinimum) &&
           IsEqualityOf(Left, Shape.Divisor, IsMinusOne)))
        return true;
    }
  }

  // The lifted IDIV helper can instead reject a quotient that does not fit
  // the architectural destination width:
  //   in_range = ((quotient + 2^(N-1)) u< 2^N)
  //   br in_range, normal, fault
  // We require the exact division SSA result and exact power-of-two bounds.
  if (FaultOnTrue)
    return false;
  const auto *Cmp = dyn_cast<ICmpInst>(Condition);
  if (!Cmp || Cmp->getPredicate() != ICmpInst::ICMP_ULT)
    return false;
  const auto *Limit = dyn_cast<ConstantInt>(Cmp->getOperand(1));
  const auto *BiasAdd = dyn_cast<BinaryOperator>(Cmp->getOperand(0));
  if (!Limit || !BiasAdd || BiasAdd->getOpcode() != Instruction::Add)
    return false;
  const auto *Bias = dyn_cast<ConstantInt>(BiasAdd->getOperand(1));
  if (!Bias || BiasAdd->getOperand(0) != Shape.Division ||
      !Bias->getValue().isPowerOf2() || !Limit->getValue().isPowerOf2())
    return false;
  return Limit->getValue().logBase2() == Bias->getValue().logBase2() + 1;
}

static CallInst *GetOnlyAbortThenUnreachable(BasicBlock &BB) {
  if (!isa<UnreachableInst>(BB.getTerminator()))
    return nullptr;

  CallInst *Abort = nullptr;
  for (Instruction &I : BB) {
    if (&I == BB.getTerminator() || isa<DbgInfoIntrinsic>(I))
      continue;
    auto *Call = dyn_cast<CallInst>(&I);
    if (!Call || Abort)
      return nullptr;
    Function *Callee = Call->getCalledFunction();
    if (!Callee || Callee->getName() != "abort")
      return nullptr;
    Abort = Call;
  }
  return Abort;
}

static SmallVector<DivideShape, 4> GetIntegerDivisions(Function &F) {
  SmallVector<DivideShape, 4> Shapes;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *Div = dyn_cast<BinaryOperator>(&I);
      if (!Div || (Div->getOpcode() != Instruction::SDiv &&
                   Div->getOpcode() != Instruction::UDiv))
        continue;
      if (!Div->getType()->isIntegerTy())
        continue;
      Shapes.push_back({Div, Div->getOperand(0), Div->getOperand(1),
                        Div->getOpcode() == Instruction::SDiv});
    }
  }
  return Shapes;
}

enum class FaultKind { None, Zero, SignedOverflow, Shared, Ambiguous };

static FaultKind ClassifyDivideFaultBlock(BasicBlock &Fault,
                                          const DivideShape &Shape) {
  bool SawZeroGuard = false;
  bool SawOverflowGuard = false;
  bool SawUnknownGuard = false;
  if (pred_empty(&Fault))
    return FaultKind::None;

  for (BasicBlock *Pred : predecessors(&Fault)) {
    auto *Branch = dyn_cast<BranchInst>(Pred->getTerminator());
    if (!Branch || !Branch->isConditional()) {
      SawUnknownGuard = true;
      continue;
    }
    const bool FaultOnTrue = Branch->getSuccessor(0) == &Fault;
    if (!FaultOnTrue && Branch->getSuccessor(1) != &Fault) {
      SawUnknownGuard = true;
      continue;
    }
    if (IsZeroDivisorCondition(Branch->getCondition(), Shape, FaultOnTrue)) {
      SawZeroGuard = true;
      continue;
    }
    if (Shape.IsSigned &&
        IsSignedOverflowCondition(Branch->getCondition(), Shape, FaultOnTrue)) {
      SawOverflowGuard = true;
      continue;
    }
    SawUnknownGuard = true;
  }
  // A block with no related guard is an ordinary abort path.  It is not a
  // divide-fault candidate and must remain untouched.  A mixed block is
  // ambiguous and prevents transactional rewriting of this helper.
  if (!SawZeroGuard && !SawOverflowGuard)
    return FaultKind::None;
  if (SawUnknownGuard)
    return FaultKind::Ambiguous;
  if (SawZeroGuard && SawOverflowGuard)
    return FaultKind::Shared;
  return SawZeroGuard ? FaultKind::Zero : FaultKind::SignedOverflow;
}

static void ReplaceAbortWithSigFpe(CallInst &Abort, Module &M) {
  LLVMContext &Ctx = M.getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  FunctionCallee Raise = M.getOrInsertFunction(
      "raise", FunctionType::get(I32, {I32}, false));
  IRBuilder<> B(&Abort);
  // Do not declare raise noreturn: a user SIGFPE handler is allowed to return.
  // The pre-existing unreachable remains the native fault path's termination.
  B.CreateCall(Raise, {ConstantInt::get(I32, SIGFPE)});
  Abort.eraseFromParent();
}

}  // namespace

bool BrightenRuntimeHelperPass::PreserveX86DivideFaults(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    const auto Shapes = GetIntegerDivisions(F);
    if (Shapes.empty())
      continue;
    SmallVector<CallInst *, 8> ToRewrite;
    bool FunctionAmbiguous = false;
    for (const DivideShape &Shape : Shapes) {
      SmallVector<CallInst *, 2> ZeroFaults;
      SmallVector<CallInst *, 2> OverflowFaults;
      bool Ambiguous = false;
      for (BasicBlock &BB : F) {
        CallInst *Abort = GetOnlyAbortThenUnreachable(BB);
        if (!Abort)
          continue;
        switch (ClassifyDivideFaultBlock(BB, Shape)) {
          case FaultKind::None: break;
          case FaultKind::Zero: ZeroFaults.push_back(Abort); break;
          case FaultKind::SignedOverflow: OverflowFaults.push_back(Abort); break;
          case FaultKind::Shared:
            ZeroFaults.push_back(Abort);
            OverflowFaults.push_back(Abort);
            break;
          case FaultKind::Ambiguous: Ambiguous = true; break;
        }
      }
      if (Ambiguous) {
        FunctionAmbiguous = true;
        break;
      }
      if (ZeroFaults.size() == 1 &&
          ((!Shape.IsSigned && OverflowFaults.empty()) ||
           (Shape.IsSigned && OverflowFaults.size() == 1))) {
        ToRewrite.push_back(ZeroFaults.front());
        if (Shape.IsSigned && OverflowFaults.front() != ZeroFaults.front())
          ToRewrite.push_back(OverflowFaults.front());
      }
    }
    if (FunctionAmbiguous)
      continue;
    llvm::sort(ToRewrite);
    if (std::adjacent_find(ToRewrite.begin(), ToRewrite.end()) !=
        ToRewrite.end())
      continue;
    ToRewrite.erase(std::unique(ToRewrite.begin(), ToRewrite.end()),
                    ToRewrite.end());
    for (CallInst *Abort : ToRewrite) {
      ReplaceAbortWithSigFpe(*Abort, M);
      Changed = true;
    }
  }
  return Changed;
}

}  // namespace brighten_runtime
