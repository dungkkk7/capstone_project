#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_runtime {

using namespace llvm;

namespace {

static bool DefineMemoryRead(Function &F, Module &M) {
  if (!F.isDeclaration() || F.arg_size() < 2) {
    return false;
  }
  Function *Translate = GetOrCreateTranslateGuestPointer(M);
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  Value *Addr = CastAddressToI64(B, F.getArg(1));
  Value *Ptr = B.CreateCall(Translate, {Addr, B.getTrue()});
  Type *RetTy = F.getReturnType();
  if (RetTy->isVoidTy()) {
    B.CreateRetVoid();
    return true;
  }
  StringRef Name = F.getName();
  if (Name.ends_with("_f80")) {
    Type *F80Ty = Type::getX86_FP80Ty(F.getContext());
    LoadInst *LI = B.CreateLoad(F80Ty, Ptr);
    LI->setAlignment(Align(16));
    Value *Cast = B.CreateFPTrunc(LI, RetTy);
    B.CreateRet(Cast);
    return true;
  }
  if (Name.ends_with("_f128")) {
    Type *F128Ty = Type::getFP128Ty(F.getContext());
    LoadInst *LI = B.CreateLoad(F128Ty, Ptr);
    LI->setAlignment(Align(16));
    Value *Cast = B.CreateFPTrunc(LI, RetTy);
    B.CreateRet(Cast);
    return true;
  }
  if (RetTy->isPointerTy()) {
    B.CreateRet(B.CreateBitCast(Ptr, RetTy));
  } else if (RetTy->isFirstClassType()) {
    LoadInst *LI = B.CreateLoad(RetTy, Ptr);
    unsigned Bits = M.getDataLayout().getTypeStoreSizeInBits(RetTy);
    if (Bits >= 8 && llvm::isPowerOf2_32(Bits / 8)) {
      LI->setAlignment(Align(Bits / 8));
    }
    B.CreateRet(LI);
  } else {
    B.CreateRet(ZeroValue(RetTy));
  }
  return true;
}

static bool DefineMemoryWrite(Function &F, Module &M) {
  if (!F.isDeclaration() || F.arg_size() < 3) {
    return false;
  }
  Function *Translate = GetOrCreateTranslateGuestPointer(M);
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  Value *Addr = CastAddressToI64(B, F.getArg(1));
  Value *Ptr = B.CreateCall(Translate, {Addr, B.getTrue()});
  Value *Val = F.getArg(2);
  StringRef Name = F.getName();
  if (Name.ends_with("_f80")) {
    Type *F80Ty = Type::getX86_FP80Ty(F.getContext());
    Value *Cast = B.CreateFPExt(Val, F80Ty);
    StoreInst *SI = B.CreateStore(Cast, Ptr);
    SI->setAlignment(Align(16));
  } else if (Name.ends_with("_f128")) {
    Type *F128Ty = Type::getFP128Ty(F.getContext());
    Value *Cast = B.CreateFPExt(Val, F128Ty);
    StoreInst *SI = B.CreateStore(Cast, Ptr);
    SI->setAlignment(Align(16));
  } else {
    StoreInst *SI = B.CreateStore(Val, Ptr);
    unsigned Bits = M.getDataLayout().getTypeStoreSizeInBits(Val->getType());
    if (Bits >= 8 && llvm::isPowerOf2_32(Bits / 8)) {
      SI->setAlignment(Align(Bits / 8));
    }
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
