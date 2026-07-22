#include "BrightenABIRecoveryPass.h"

#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Metadata.h"
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

static ReturnKind XMM0KindFromValue(Value *V) {
  if (!V) {
    return ReturnKind::Unknown;
  }
  Type *Ty = V->getType();
  if (Ty->isFloatTy()) {
    return ReturnKind::FloatXMM0;
  }
  if (Ty->isDoubleTy()) {
    return ReturnKind::DoubleXMM0;
  }
  if (Ty->isVectorTy()) {
    return ReturnKind::VectorXMM0;
  }

  if (auto *BC = dyn_cast<BitCastInst>(V)) {
    ReturnKind Kind = XMM0KindFromValue(BC->getOperand(0));
    if (Kind != ReturnKind::Unknown) {
      return Kind;
    }
  }
  auto *LI = dyn_cast<LoadInst>(V);
  // State-SSA type hints describe the original register access, but the
  // canonical slot may later be reused through an incompatible view.  Only
  // integer bit containers of the exact ABI width are safe evidence for an
  // FP/vector return.  In particular, never reinterpret a loaded pointer as
  // a 128-bit XMM result merely because its alloca retained "vector" metadata.
  if (!LI || !Ty->isIntegerTy()) {
    return ReturnKind::Unknown;
  }
  auto *AI = dyn_cast<AllocaInst>(
      LI->getPointerOperand()->stripPointerCasts());
  if (!AI) {
    return ReturnKind::Unknown;
  }
  MDNode *Hint = AI->getMetadata("brighten.state.abi_type");
  if (!Hint || Hint->getNumOperands() != 1) {
    return ReturnKind::Unknown;
  }
  auto *Name = dyn_cast<MDString>(Hint->getOperand(0));
  if (!Name) {
    return ReturnKind::Unknown;
  }
  unsigned Bits = cast<IntegerType>(Ty)->getBitWidth();
  if (Name->getString() == "float" && Bits == 32) {
    return ReturnKind::FloatXMM0;
  }
  if (Name->getString() == "double" && Bits == 64) {
    return ReturnKind::DoubleXMM0;
  }
  if (Name->getString() == "vector" && Bits == 128) {
    return ReturnKind::VectorXMM0;
  }
  return ReturnKind::Unknown;
}

static bool ValueDependsOnImpl(Value *Root, Value *Needle,
                               SmallPtrSetImpl<Value *> &Seen,
                               unsigned Depth) {
  if (!Root || !Needle || Depth > 64)
    return false;
  if (Root == Needle)
    return true;
  if (!Seen.insert(Root).second)
    return false;
  auto *U = dyn_cast<User>(Root);
  if (!U)
    return false;
  for (Value *Operand : U->operands())
    if (ValueDependsOnImpl(Operand, Needle, Seen, Depth + 1))
      return true;
  return false;
}

static bool ValueDependsOn(Value *Root, Value *Needle) {
  SmallPtrSet<Value *, 32> Seen;
  return ValueDependsOnImpl(Root, Needle, Seen, 0);
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
  bool CompleteXMM0 = true;
  bool EveryXMM0DerivedFromRAX = true;
  ReturnKind XMM0Kind = ReturnKind::Unknown;
  bool ReturnsMemArg = true;
  for (ReturnInst *RI : Returns) {
    Value *RAXValue = FindRegisterValueBeforeReturn(RI, ABIReg::RAX);
    if (!RAXValue) {
      CompleteRAX = false;
    }
    if (!ReturnOperandIsOriginalMemoryArg(F, *RI)) {
      ReturnsMemArg = false;
    }
    if (!HasFullWidthRegisterValueBeforeReturn(RI, ABIReg::RDX)) {
      CompleteRDX = false;
    }
    Value *XMM0Value = FindRegisterValueBeforeReturn(RI, ABIReg::XMM0);
    ReturnKind ThisXMM0Kind = XMM0KindFromValue(XMM0Value);
    if (ThisXMM0Kind == ReturnKind::Unknown ||
        (XMM0Kind != ReturnKind::Unknown && ThisXMM0Kind != XMM0Kind)) {
      CompleteXMM0 = false;
    } else {
      XMM0Kind = ThisXMM0Kind;
    }
    EveryXMM0DerivedFromRAX &=
        RAXValue && XMM0Value && ValueDependsOn(XMM0Value, RAXValue);
  }

  S.HasRAXStoreBeforeReturn = CompleteRAX;
  S.HasCompleteReturnValues = CompleteRAX;
  S.HasCompleteRDXValues = CompleteRDX;
  S.HasCompleteXMM0Values = CompleteXMM0;
  S.XMM0ReturnDerivedFromRAX =
      CompleteXMM0 && CompleteRAX && EveryXMM0DerivedFromRAX;
  S.XMM0ReturnKind = CompleteXMM0 ? XMM0Kind : ReturnKind::Unknown;
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
