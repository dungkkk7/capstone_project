// Define missing Remill control helpers so lifted modules link standalone.
// These helpers preserve the memory-threading convention by returning the
// incoming memory argument. Direct resolvable calls are still normalized by
// RuleNormalizeRemillFunctionCalls later in the pipeline.
#include "BrightenRepairPass.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static bool IsRemillControlHelperName(StringRef Name) {
  return Name == "__remill_function_call" ||
         Name == "__remill_function_return" ||
         Name == "__remill_jump" ||
         Name == "__remill_missing_block" ||
         Name == "__remill_async_hyper_call";
}

static bool HasMemoryThreadingSignature(const Function &F) {
  auto *FTy = F.getFunctionType();
  if (FTy->getNumParams() != 3 || !FTy->getReturnType()->isPointerTy()) {
    return false;
  }
  return FTy->getParamType(0)->isPointerTy() &&
         FTy->getParamType(1)->isIntegerTy() &&
         FTy->getParamType(2)->isPointerTy();
}

static bool DefineReturnMemory(Function &F) {
  if (!F.isDeclaration() || !HasMemoryThreadingSignature(F)) {
    return false;
  }

  BasicBlock *Entry = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(Entry);
  auto ArgIt = F.arg_begin();
  (void)*ArgIt++;  // state
  (void)*ArgIt++;  // pc
  Value *Memory = &*ArgIt;
  B.CreateRet(Memory);
  return true;
}

}  // namespace

bool BrightenRepairPass::DefineRemillControlHelpers(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (!IsRemillControlHelperName(F.getName())) {
      continue;
    }
    Changed |= DefineReturnMemory(F);
  }
  return Changed;
}

}  // namespace brighten_repair

