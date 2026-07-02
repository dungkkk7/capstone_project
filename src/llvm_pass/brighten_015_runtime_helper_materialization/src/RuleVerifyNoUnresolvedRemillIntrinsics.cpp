#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

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

}  // namespace

bool BrightenRuntimeHelperPass::VerifyNoUnresolvedRemillIntrinsics(Module &M) {
  bool Changed = false;
  SmallVector<Function *, 32> Unresolved;
  for (Function &F : M) {
    if (IsRemillDecl(F)) {
      Unresolved.push_back(&F);
    }
  }

  for (Function *F : Unresolved) {
    errs() << "[brighten-remill-runtime] fallback unresolved: "
           << F->getName() << "\n";
    Changed |= DefineFallbackBody(*F);
  }
  return Changed;
}

}  // namespace brighten_runtime
