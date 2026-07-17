#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include <vector>
#include <algorithm>
#include "llvm/ADT/DenseSet.h"
#include <algorithm>
#include "llvm/ADT/DenseSet.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_runtime {

using namespace llvm;

namespace {

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
    FunctionCallee Missing =
        M.getOrInsertFunction("__remill_missing_block", FTy);
    B.CreateRet(B.CreateCall(Missing, {State, PC, Mem}));
  }
  std::sort(Targets.begin(), Targets.end(), [](const auto &A, const auto &B) {
    if (A.first != B.first) {
      return A.first < B.first;
    }
    bool A_is_sub = A.second->getName().starts_with("sub_");
    bool B_is_sub = B.second->getName().starts_with("sub_");
    if (A_is_sub != B_is_sub) {
      return A_is_sub;
    }
    return A.second->getName() < B.second->getName();
  });

  IRBuilder<> B(Entry);
  auto *Switch = B.CreateSwitch(PC, DefaultBB, Targets.size());
  DenseSet<uint64_t> AddedPCs;
  for (auto &[TargetPC, Target] : Targets) {
    if (AddedPCs.insert(TargetPC).second) {
      BasicBlock *CaseBB = BasicBlock::Create(Ctx, "case_" + Target->getName(), &Helper);
      Switch->addCase(ConstantInt::get(cast<IntegerType>(PC->getType()), TargetPC), CaseBB);
      IRBuilder<> CB(CaseBB);
      CB.CreateRet(CB.CreateCall(FTy, Target, {State, PC, Mem}));
    }
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
      // Returning the incoming Memory token is not the semantics of return,
      // missing-block, error, or a hypercall.  Keep live declarations visible
      // so devirtualization/strict cleanup must resolve them explicitly.
      errs() << "[brighten-remill-runtime] unresolved control helper preserved: "
             << Name << "\n";
    }
  }
  return Changed;
}

}  // namespace brighten_runtime
