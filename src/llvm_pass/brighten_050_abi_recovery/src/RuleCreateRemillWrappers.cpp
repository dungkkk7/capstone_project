#include "BrightenABIRecoveryPass.h"
#include "ABIModel.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_abi {

using namespace llvm;

static Function *CreateWrapper(Module &M, FunctionABISummary &S) {
  Function *Remill = S.RemillFn;
  FunctionType *FT = Remill->getFunctionType();
  Function *Wrapper =
      Function::Create(FT, S.OriginalLinkage, S.OriginalName, M);
  Wrapper->copyAttributesFrom(Remill);
  Wrapper->setCallingConv(Remill->getCallingConv());
  Wrapper->setDSOLocal(Remill->isDSOLocal());

  BasicBlock *Entry = BasicBlock::Create(M.getContext(), "entry", Wrapper);
  IRBuilder<> B(Entry);

  if (S.Cloned && S.NativeFn) {
    Value *StatePtr = Wrapper->getArg(0);
    Value *MemPtr = Wrapper->getArg(2);

    SmallVector<Value *, 8> NativeArgs;
    // 1. Trát các tham số ẩn nếu native function cần
    if (S.HiddenState) {
      NativeArgs.push_back(StatePtr);
    }
    if (S.HiddenPC) {
      NativeArgs.push_back(Wrapper->getArg(1));
    }
    if (S.HiddenMemory) {
      NativeArgs.push_back(MemPtr);
    }

    // 2. Load các register arg từ State
    for (const ABIArgInfo &Arg : S.Args) {
      ABIReg Reg = Arg.Reg;
      Type *RegTy = Arg.Ty;
      const ABIRegisterInfo *Info = GetRegisterInfo(Reg);
      uint64_t Offset = Info ? Info->Offset : 0;
      Value *GEP = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, Offset);
      Value *Load = B.CreateLoad(RegTy, GEP);
      NativeArgs.push_back(Load);
    }

    CallInst *Call = B.CreateCall(S.NativeFn, NativeArgs);
    Call->setCallingConv(S.NativeFn->getCallingConv());

    // 3. Xử lý giá trị trả về
    if (S.RetKind != ReturnKind::Void) {
      const ABIRegisterInfo *Info = GetRegisterInfo(ABIReg::RAX);
      uint64_t RAXOffset = Info ? Info->Offset : 2216;
      Value *RAXGEP = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, RAXOffset);
      Value *RetVal = Call;
      if (RetVal->getType()->isPointerTy()) {
        RetVal = B.CreatePtrToInt(RetVal, B.getInt64Ty());
      } else if (RetVal->getType()->isIntegerTy() && RetVal->getType()->getIntegerBitWidth() < 64) {
        RetVal = B.CreateZExt(RetVal, B.getInt64Ty());
      }
      B.CreateStore(RetVal, RAXGEP);
    }

    B.CreateRet(MemPtr);
  } else {
    // Fallback: gọi remill gốc
    SmallVector<Value *, 3> Args;
    for (Argument &Arg : Wrapper->args()) {
      Args.push_back(&Arg);
    }
    CallInst *Call = B.CreateCall(Remill, Args);
    Call->setCallingConv(Remill->getCallingConv());
    B.CreateRet(Call);
  }
  return Wrapper;
}

static void RedirectRemainingUses(FunctionABISummary &S) {
  Function *Remill = S.RemillFn;
  Function *Wrapper = S.WrapperFn;
  Remill->replaceUsesWithIf(Wrapper, [&](Use &U) {
    auto *I = dyn_cast<Instruction>(U.getUser());
    if (I && I->getFunction() == Wrapper) {
      return false;
    }
    return true;
  });
}

bool BrightenABIRecoveryPass::CreateRemillWrappers(ABIRecoveryContext &Ctx) {
  bool Changed = false;
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (!S->Cloned || S->WrapperFn) {
      continue;
    }
    S->WrapperFn = CreateWrapper(Ctx.M, *S);
    S->WrapperCreated = true;
    RedirectRemainingUses(*S);
    S->RemillFn->setLinkage(GlobalValue::InternalLinkage);
    S->RemillFn->setDSOLocal(true);
    Changed = true;

    errs() << "[brighten-abi] wrapper kept: " << S->RemillFn->getName()
           << " reason=remaining-remill-users\n";
  }
  return Changed;
}

} // namespace brighten_abi
