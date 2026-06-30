// Rewrite wrapper cho x87 libcall (sqrtl).
// - Lay arg long double tu stack
// - Goi intrinsic sqrt va cap nhat ST0, RSP
#include "BrightenRepairPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static Value *FindStorageByPrefix(Module &M, StringRef Prefix, Type *Ty) {
  for (GlobalAlias &GA : M.aliases()) {
    if (GA.getName().starts_with(Prefix) && GA.getValueType() == Ty) {
      return &GA;
    }
  }
  for (GlobalVariable &GV : M.globals()) {
    if (GV.getName().starts_with(Prefix) && GV.getValueType() == Ty) {
      return &GV;
    }
  }
  return nullptr;
}

static bool IsSqrtlExtWrapper(Function &F) {
  if (F.isDeclaration() || !F.getName().starts_with("ext_") ||
      !F.getName().ends_with("_sqrtl")) {
    return false;
  }
  if (!F.getReturnType()->isPointerTy() || F.arg_size() < 3) {
    return false;
  }
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      Function *Callee = CI ? CI->getCalledFunction() : nullptr;
      if (Callee && Callee->getName() == "sqrtl") {
        return true;
      }
    }
  }
  return false;
}

static bool RewriteSqrtlWrapper(Function &F, Value *RSP, Value *ST0X87) {
  Module *M = F.getParent();
  LLVMContext &Ctx = M->getContext();
  Type *I64Ty = Type::getInt64Ty(Ctx);
  Type *X87Ty = Type::getX86_FP80Ty(Ctx);
  auto *PtrTy = PointerType::getUnqual(Ctx);

  Value *MemoryArg = F.getArg(2);
  GlobalValue::LinkageTypes Linkage = F.getLinkage();
  GlobalValue::VisibilityTypes Visibility = F.getVisibility();
  bool IsDSOLocal = F.isDSOLocal();
  F.deleteBody();
  F.setLinkage(Linkage);
  F.setVisibility(Visibility);
  F.setDSOLocal(IsDSOLocal);

  BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", &F);
  IRBuilder<> B(Entry);

  LoadInst *SP = B.CreateLoad(I64Ty, RSP);
  Value *AfterReturnAddress = B.CreateAdd(SP, B.getInt64(8));

  // On x86_64 SysV, long double arguments are passed in memory.  At wrapper
  // entry RSP points at the synthetic return address, so arg0 is at RSP + 8.
  Value *ArgPtr = B.CreateIntToPtr(AfterReturnAddress, PtrTy);
  LoadInst *Arg = B.CreateLoad(X87Ty, ArgPtr);
  Arg->setAlignment(Align(1));
  Function *Sqrt = Intrinsic::getDeclaration(M, Intrinsic::sqrt, {X87Ty});
  Value *ResultX87 = B.CreateCall(Sqrt, {Arg});

  StoreInst *StoreResult = B.CreateStore(ResultX87, ST0X87);
  StoreResult->setAlignment(Align(1));
  B.CreateStore(AfterReturnAddress, RSP);
  B.CreateRet(MemoryArg);

  return true;
}

}  // namespace

bool BrightenRepairPass::RepairRemillX87LibCalls(Module &M) {
  LLVMContext &Ctx = M.getContext();
  Value *RSP = FindStorageByPrefix(M, "RSP_", Type::getInt64Ty(Ctx));
  Value *ST0 = FindStorageByPrefix(M, "ST0_", Type::getX86_FP80Ty(Ctx));
  if (!RSP || !ST0) {
    return false;
  }

  bool Changed = false;
  for (Function &F : M) {
    if (IsSqrtlExtWrapper(F)) {
      Changed |= RewriteSqrtlWrapper(F, RSP, ST0);
    }
  }
  return Changed;
}

}  // namespace brighten_repair
