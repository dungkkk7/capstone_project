#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

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

bool BrightenRuntimeHelperPass::DefineRemillArchHypercallStubs(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (!IsRemillDecl(F)) {
      continue;
    }
    StringRef Name = F.getName();
    if (HasPrefixAny(Name, {"__remill_x86_", "__remill_amd64_",
                            "__remill_aarch64_", "__remill_aarch32_",
                            "__remill_sparc_", "__remill_ppc_"})) {
      errs() << "[brighten-remill-runtime] arch stub: " << Name << "\n";
      Changed |= DefineFallbackBody(F);
    }
  }
  return Changed;
}

}  // namespace brighten_runtime
