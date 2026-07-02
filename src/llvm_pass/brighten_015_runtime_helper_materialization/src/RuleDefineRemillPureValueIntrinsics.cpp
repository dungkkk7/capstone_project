#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_runtime {

using namespace llvm;

namespace {

static bool DefineFallbackBody(Function &F) {
  if (!F.isDeclaration()) {
    return false;
  }
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  Type *RetTy = F.getReturnType();
  if (RetTy->isVoidTy()) {
    B.CreateRetVoid();
    return true;
  }
  if (RetTy->isPointerTy()) {
    if (Value *Mem = FindLikelyMemoryArg(F)) {
      B.CreateRet(Mem);
    } else {
      B.CreateRet(ZeroValue(RetTy));
    }
    return true;
  }
  B.CreateRet(ZeroValue(RetTy));
  return true;
}

static bool DefineCompareOrFlagComputation(Function &F) {
  if (!F.isDeclaration()) {
    return false;
  }
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  Type *RetTy = F.getReturnType();
  if (RetTy->isVoidTy()) {
    B.CreateRetVoid();
    return true;
  }
  for (Argument &Arg : F.args()) {
    if (Arg.getType() == RetTy) {
      B.CreateRet(&Arg);
      return true;
    }
  }
  B.CreateRet(ZeroValue(RetTy));
  return true;
}

}  // namespace

bool BrightenRuntimeHelperPass::DefineRemillPureValueIntrinsics(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (!IsRemillDecl(F)) {
      continue;
    }
    StringRef Name = F.getName();
    if (Name.starts_with("__remill_undefined_") ||
        Name == "__remill_fpu_exception_test_and_clear" ||
        Name.starts_with("__remill_fpu_")) {
      Changed |= DefineFallbackBody(F);
    } else if (Name.starts_with("__remill_compare_") ||
               Name.starts_with("__remill_flag_computation_")) {
      Changed |= DefineCompareOrFlagComputation(F);
    }
  }
  return Changed;
}

}  // namespace brighten_runtime
