#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_runtime {

using namespace llvm;

namespace {

static bool DefineMemoryRead(Function &F, Module &M) {
  Type *RetTy = F.getReturnType();
  Type *AddrTy = F.arg_size() >= 2 ? F.getArg(1)->getType() : nullptr;
  if (!F.isDeclaration() || F.arg_size() < 2 ||
      (!AddrTy->isIntegerTy() && !AddrTy->isPointerTy()) ||
      (!RetTy->isVoidTy() && !RetTy->isFirstClassType())) {
    return false;
  }
  if ((F.getName().ends_with("_f80") || F.getName().ends_with("_f128")) &&
      !RetTy->isFloatingPointTy())
    return false;
  Function *Translate = GetOrCreateTranslateGuestPointer(M);
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  Value *Addr = CastAddressToI64(B, F.getArg(1));
  Value *Ptr = B.CreateCall(Translate, {Addr, B.getFalse()});
  if (RetTy->isVoidTy()) {
    B.CreateRetVoid();
    return true;
  }
  StringRef Name = F.getName();
  if (Name.ends_with("_f80")) {
    Type *F80Ty = Type::getX86_FP80Ty(F.getContext());
    LoadInst *LI = B.CreateLoad(F80Ty, Ptr);
    LI->setAlignment(Align(1));
    Value *Cast = F80Ty == RetTy ? static_cast<Value *>(LI)
                                 : B.CreateFPCast(LI, RetTy);
    B.CreateRet(Cast);
    return true;
  }
  if (Name.ends_with("_f128")) {
    Type *F128Ty = Type::getFP128Ty(F.getContext());
    LoadInst *LI = B.CreateLoad(F128Ty, Ptr);
    LI->setAlignment(Align(1));
    Value *Cast = F128Ty == RetTy ? static_cast<Value *>(LI)
                                  : B.CreateFPCast(LI, RetTy);
    B.CreateRet(Cast);
    return true;
  }
  if (RetTy->isFirstClassType()) {
    LoadInst *LI = B.CreateLoad(RetTy, Ptr);
    // Remill memory intrinsics model guest ISA accesses, which may be
    // unaligned (notably on x86).  Claiming natural alignment turns valid
    // guest accesses into LLVM UB and lets optimization change semantics.
    LI->setAlignment(Align(1));
    B.CreateRet(LI);
  } else {
    B.CreateRet(ZeroValue(RetTy));
  }
  return true;
}

static bool DefineMemoryWrite(Function &F, Module &M) {
  Type *AddrTy = F.arg_size() >= 2 ? F.getArg(1)->getType() : nullptr;
  Type *RetTy = F.getReturnType();
  bool SupportedReturn = RetTy->isVoidTy() ||
                         (RetTy->isPointerTy() &&
                          F.arg_size() >= 1 &&
                          F.getArg(0)->getType() == RetTy);
  if (!F.isDeclaration() || F.arg_size() < 3 ||
      (!AddrTy->isIntegerTy() && !AddrTy->isPointerTy()) ||
      !F.getArg(2)->getType()->isFirstClassType() || !SupportedReturn) {
    return false;
  }
  if ((F.getName().ends_with("_f80") || F.getName().ends_with("_f128")) &&
      !F.getArg(2)->getType()->isFloatingPointTy())
    return false;
  Function *Translate = GetOrCreateTranslateGuestPointer(M);
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  Value *Addr = CastAddressToI64(B, F.getArg(1));
  Value *Ptr = B.CreateCall(Translate, {Addr, B.getTrue()});
  Value *Val = F.getArg(2);
  StringRef Name = F.getName();
  if (Name.ends_with("_f80")) {
    Type *F80Ty = Type::getX86_FP80Ty(F.getContext());
    Value *Cast = Val->getType() == F80Ty ? Val : B.CreateFPCast(Val, F80Ty);
    StoreInst *SI = B.CreateStore(Cast, Ptr);
    SI->setAlignment(Align(1));
  } else if (Name.ends_with("_f128")) {
    Type *F128Ty = Type::getFP128Ty(F.getContext());
    Value *Cast = Val->getType() == F128Ty ? Val : B.CreateFPCast(Val, F128Ty);
    StoreInst *SI = B.CreateStore(Cast, Ptr);
    SI->setAlignment(Align(1));
  } else {
    StoreInst *SI = B.CreateStore(Val, Ptr);
    SI->setAlignment(Align(1));
  }
  if (F.getReturnType()->isVoidTy()) {
    B.CreateRetVoid();
  } else if (F.getReturnType()->isPointerTy()) {
    B.CreateRet(F.getArg(0));
  } else {
    B.CreateRet(ZeroValue(F.getReturnType()));
  }
  return true;
}

}  // namespace

bool BrightenRuntimeHelperPass::LowerRemillMemoryIntrinsics(Module &M) {
  bool Changed = false;
  SmallVector<Function *, 32> Work;
  for (Function &F : M) {
    if (!IsRemillDecl(F)) {
      continue;
    }
    StringRef Name = F.getName();
    if (Name.starts_with("__remill_read_memory_") ||
        Name.starts_with("__remill_write_memory_")) {
      Work.push_back(&F);
    }
  }
  for (Function *F : Work) {
    StringRef Name = F->getName();
    if (Name.starts_with("__remill_read_memory_")) {
      Changed |= DefineMemoryRead(*F, M);
    } else {
      Changed |= DefineMemoryWrite(*F, M);
    }
  }
  return Changed;
}

}  // namespace brighten_runtime
