#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include <vector>

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_runtime {

using namespace llvm;

namespace {

static bool DefineReturnMemory(Function &F) {
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

static bool DefinePCDispatcher(Function &Helper, Module &M) {
  if (!Helper.isDeclaration() || !HasMemoryThreadingSignature(Helper)) {
    return false;
  }
  LLVMContext &Ctx = M.getContext();
  FunctionType *FTy = Helper.getFunctionType();
  std::vector<std::pair<uint64_t, Function *>> Targets;
  for (Function &F : M) {
    if (F.isDeclaration() || F.getFunctionType() != FTy || &F == &Helper) {
      continue;
    }
    auto PC = ParseAddressName(F.getName());
    if (PC.has_value()) {
      Targets.push_back({*PC, &F});
    }
  }

  BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", &Helper);
  BasicBlock *DefaultBB = BasicBlock::Create(Ctx, "fallback", &Helper);
  auto It = Helper.arg_begin();
  Value *State = &*It++;
  Value *PC = &*It++;
  Value *Mem = &*It++;

  {
    IRBuilder<> B(DefaultBB);
    B.CreateRet(Mem);
  }
  IRBuilder<> B(Entry);
  auto *Switch = B.CreateSwitch(PC, DefaultBB, Targets.size());
  for (auto &[TargetPC, Target] : Targets) {
    BasicBlock *CaseBB = BasicBlock::Create(Ctx, "case_" + Target->getName(), &Helper);
    Switch->addCase(ConstantInt::get(cast<IntegerType>(PC->getType()), TargetPC), CaseBB);
    IRBuilder<> CB(CaseBB);
    CB.CreateRet(CB.CreateCall(FTy, Target, {State, PC, Mem}));
  }
  return true;
}

}  // namespace

bool BrightenRuntimeHelperPass::DefineRemillControlFlowRuntime(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    StringRef Name = F.getName();
    if (Name == "__remill_function_call" || Name == "__remill_jump") {
      Changed |= DefinePCDispatcher(F, M);
    } else if (Name == "__remill_function_return" ||
               Name == "__remill_missing_block" ||
               Name == "__remill_error" ||
               Name == "__remill_async_hyper_call" ||
               Name == "__remill_sync_hyper_call") {
      Changed |= DefineReturnMemory(F);
    }
  }
  return Changed;
}

}  // namespace brighten_runtime
