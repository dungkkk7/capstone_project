#include "BrightenRepairPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/IntrinsicInst.h"

namespace brighten_repair {

using namespace llvm;

static Value *stripIntegerExtension(Value *V) {
  while (auto *Cast = dyn_cast<CastInst>(V)) {
    if (Cast->getOpcode() != Instruction::ZExt &&
        Cast->getOpcode() != Instruction::SExt)
      break;
    V = Cast->getOperand(0);
  }
  return V;
}

static bool isSignedIndefinite(ConstantInt *C, unsigned SourceBits) {
  if (!C || SourceBits == 0 || SourceBits > C->getBitWidth())
    return false;
  APInt Expected(C->getBitWidth(), 1);
  Expected <<= SourceBits - 1;
  return C->getValue() == Expected;
}

static bool isFabsOf(Value *MaybeFabs, Value *Input) {
  auto *II = dyn_cast<IntrinsicInst>(MaybeFabs);
  return II && II->getIntrinsicID() == Intrinsic::fabs &&
         II->arg_size() == 1 && II->getArgOperand(0) == Input;
}

// Remill's x86 CVTTSD2SI/CVTTSS2SI template guards an LLVM fptosi with an
// absolute-value range check.  Some lifted modules use an ordered comparison,
// so NaN reaches fptosi and becomes poison.  The hardware instruction instead
// returns the signed "integer indefinite" value for both out-of-range values
// and NaN.  Turn only the fully recognized guard into an unordered-or-greater
// comparison; unrelated floating-point comparisons are untouched.
bool BrightenRepairPass::RepairX86FPToIntIndefiniteGuards(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *Sel = dyn_cast<SelectInst>(&I);
        if (!Sel)
          continue;
        auto *Cmp = dyn_cast<FCmpInst>(Sel->getCondition());
        if (!Cmp || Cmp->getPredicate() != FCmpInst::FCMP_OGT)
          continue;

        Value *Converted = stripIntegerExtension(Sel->getFalseValue());
        auto *FPToSI = dyn_cast<FPToSIInst>(Converted);
        auto *Indefinite = dyn_cast<ConstantInt>(Sel->getTrueValue());
        if (!FPToSI ||
            !isSignedIndefinite(Indefinite,
                                FPToSI->getDestTy()->getIntegerBitWidth()))
          continue;

        Value *Input = FPToSI->getOperand(0);
        if (!isFabsOf(Cmp->getOperand(0), Input) ||
            !isa<ConstantFP>(Cmp->getOperand(1)))
          continue;

        Cmp->setPredicate(FCmpInst::FCMP_UGT);
        Changed = true;
      }
    }
  }
  return Changed;
}

} // namespace brighten_repair
