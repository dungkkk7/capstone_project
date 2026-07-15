#include "BrightenABIRecoveryPass.h"

#include "llvm/IR/InstIterator.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_abi {

using namespace llvm;

static bool HasReturnMetadata(Function &F) {
  if (F.getMetadata("brighten.return_candidate")) {
    return true;
  }
  for (Instruction &I : instructions(F)) {
    if (I.getMetadata("brighten.return_rax.info") ||
        I.getMetadata("brighten.return_candidate")) {
      return true;
    }
    auto *CB = dyn_cast<CallBase>(&I);
    if (!CB) {
      continue;
    }
    Function *Callee = CB->getCalledFunction();
    if (Callee && Callee->getIntrinsicID() == Intrinsic::sideeffect &&
        CB->getOperandBundle("brighten_return_rax")) {
      return true;
    }
  }
  return false;
}

static bool HasFullWidthRegisterValueBeforeReturn(ReturnInst *RI,
                                                  ABIReg Reg) {
  Value *V = FindRegisterValueBeforeReturn(RI, Reg);
  if (!V) {
    return false;
  }
  Type *Ty = V->getType();
  return Ty->isPointerTy() || Ty->isIntegerTy(64);
}

static void AnalyzeOne(FunctionABISummary &S) {
  Function &F = *S.RemillFn;
  S.HasReturnMetadata = HasReturnMetadata(F);

  SmallVector<ReturnInst *, 8> Returns;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto RA = IdentifyRegAccess(I)) {
        if (RA->IsStore && IsReturnRegister(RA->Reg)) {
          S.LiveOutStores.insert(RA->Reg);
        }
      }
    }
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator())) {
      Returns.push_back(RI);
    }
  }

  if (Returns.empty()) {
    S.HasCompleteReturnValues = false;
    S.ReturnsOriginalMemoryArg = false;
    return;
  }

  bool CompleteRAX = true;
  bool CompleteRDX = true;
  bool ReturnsMemArg = true;
  for (ReturnInst *RI : Returns) {
    if (!FindRegisterValueBeforeReturn(RI, ABIReg::RAX)) {
      CompleteRAX = false;
    }
    if (!ReturnOperandIsOriginalMemoryArg(F, *RI)) {
      ReturnsMemArg = false;
    }
    if (!HasFullWidthRegisterValueBeforeReturn(RI, ABIReg::RDX)) {
      CompleteRDX = false;
    }
  }

  S.HasRAXStoreBeforeReturn = CompleteRAX;
  S.HasCompleteReturnValues = CompleteRAX;
  S.HasCompleteRDXValues = CompleteRDX;
  S.ReturnsOriginalMemoryArg = ReturnsMemArg;
}

bool BrightenABIRecoveryPass::AnalyzeFunctionLiveOuts(
    ABIRecoveryContext &Ctx) {
  for (FunctionABISummary *S : Ctx.Summaries) {
    AnalyzeOne(*S);
  }
  return false;
}

} // namespace brighten_abi
