// Fix stack update quanh raw indirect call.
// - Tim RSP storage va new SP
// - Chen store neu mcsema bo qua
#include "BrightenRepairPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static bool IsLiftedCodeFunction(const Function &F) {
  return F.getName().starts_with("sub_");
}

static bool IsRSPStorage(Value *Ptr) {
  auto *GA = dyn_cast<GlobalAlias>(Ptr->stripPointerCasts());
  return GA && GA->getName().starts_with("RSP_") &&
         GA->getValueType()->isIntegerTy(64);
}

static Value *RawIntToPtrTarget(Value *Callee) {
  Callee = Callee->stripPointerCasts();
  if (auto *I2P = dyn_cast<IntToPtrInst>(Callee)) {
    return I2P->getOperand(0);
  }
  auto *CE = dyn_cast<ConstantExpr>(Callee);
  if (CE && CE->getOpcode() == Instruction::IntToPtr) {
    return CE->getOperand(0);
  }
  return nullptr;
}

static bool IsConstI64(Value *V, int64_t Expected) {
  auto *CI = dyn_cast<ConstantInt>(V);
  return CI && CI->getBitWidth() == 64 && CI->getSExtValue() == Expected;
}

static Value *FindRestoredStackPointer(CallInst &CI, Value *&RSPStorage) {
  for (Instruction *I = CI.getNextNode(); I; I = I->getNextNode()) {
    auto *SI = dyn_cast<StoreInst>(I);
    if (!SI || !IsRSPStorage(SI->getPointerOperand())) {
      continue;
    }
    RSPStorage = SI->getPointerOperand();
    return SI->getValueOperand();
  }
  return nullptr;
}

static Value *FindPushedStackPointer(CallInst &CI, Value *OldSP) {
  BasicBlock::iterator It(CI);
  while (It != CI.getParent()->begin()) {
    --It;
    auto *BO = dyn_cast<BinaryOperator>(&*It);
    if (!BO) {
      continue;
    }

    if (BO->getOpcode() == Instruction::Add) {
      if ((BO->getOperand(0) == OldSP && IsConstI64(BO->getOperand(1), -8)) ||
          (BO->getOperand(1) == OldSP && IsConstI64(BO->getOperand(0), -8))) {
        return BO;
      }
    }

    if (BO->getOpcode() == Instruction::Sub &&
        BO->getOperand(0) == OldSP && IsConstI64(BO->getOperand(1), 8)) {
      return BO;
    }
  }
  return nullptr;
}

static bool AlreadyStoresNewSP(CallInst &CI, Value *RSPStorage, Value *NewSP) {
  BasicBlock::iterator It(CI);
  while (It != CI.getParent()->begin()) {
    --It;
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (SI && SI->getPointerOperand() == RSPStorage &&
        SI->getValueOperand() == NewSP) {
      return true;
    }
  }
  return false;
}

}  // namespace

bool BrightenRepairPass::RepairMcSemaRawIndirectCallStack(Module &M) {
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration() || !IsLiftedCodeFunction(F)) {
      continue;
    }

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm() || CI->getCalledFunction()) {
          continue;
        }
        if (!RawIntToPtrTarget(CI->getCalledOperand())) {
          continue;
        }

        Value *RSPStorage = nullptr;
        Value *OldSP = FindRestoredStackPointer(*CI, RSPStorage);
        if (!OldSP || !RSPStorage) {
          continue;
        }

        Value *NewSP = FindPushedStackPointer(*CI, OldSP);
        if (!NewSP || AlreadyStoresNewSP(*CI, RSPStorage, NewSP)) {
          continue;
        }

        IRBuilder<> B(CI);
        B.CreateStore(NewSP, RSPStorage);
        Changed = true;
      }
    }
  }

  return Changed;
}

}  // namespace brighten_repair
