#include "BrightenRepairPass.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/InlineAsm.h"

namespace brighten_repair {

using namespace llvm;

bool BrightenRepairPass::DiscoverSymbols(Module &M) {
  bool Changed = false;
  NamedMDNode *NMD = M.getOrInsertNamedMetadata("brighten.symbols");
  LLVMContext &Ctx = M.getContext();
  Type *Int64Ty = Type::getInt64Ty(Ctx);

  // We want to avoid adding duplicates.
  DenseSet<uint64_t> ExistingPCs;
  for (unsigned i = 0; i < NMD->getNumOperands(); ++i) {
    MDNode *Node = NMD->getOperand(i);
    if (Node->getNumOperands() >= 1) {
      if (auto *VM = dyn_cast<ValueAsMetadata>(Node->getOperand(0))) {
        if (auto *CI = dyn_cast<ConstantInt>(VM->getValue())) {
          ExistingPCs.insert(CI->getZExtValue());
        }
      }
    }
  }

  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    StringRef Name = F.getName();

    uint64_t PC = ResolveGuestAddress(&F, M);
    if (PC == 0 && Name.starts_with("sub_")) {
      StringRef Hex = Name.drop_front(4);
      size_t Underscore = Hex.find('_');
      if (Underscore != StringRef::npos) {
        Hex = Hex.substr(0, Underscore);
      }
      Hex.getAsInteger(16, PC);
    }

    if (PC > 0 && ExistingPCs.insert(PC).second) {
      StringRef OrigName = Name;
      if (OrigName.starts_with("sub_")) {
        StringRef Hex = OrigName.drop_front(4);
        size_t Underscore = Hex.find('_');
        if (Underscore != StringRef::npos) {
          OrigName = Hex.drop_front(Underscore + 1);
        }
      }

      Metadata *Ops[] = {
        ValueAsMetadata::get(ConstantInt::get(Int64Ty, PC)),
        MDString::get(Ctx, OrigName)
      };
      NMD->addOperand(MDNode::get(Ctx, Ops));
      Changed = true;
    }
  }

  return Changed;
}

bool BrightenRepairPass::StripInvalidInlineAsm(Module &M) {
  bool Changed = false;

  auto IsTriviallyEmptyInlineAsm = [](CallInst *CI) {
    if (!CI || !CI->isInlineAsm()) {
      return false;
    }
    auto *IA = dyn_cast<InlineAsm>(CI->getCalledOperand());
    if (!IA) {
      return false;
    }
    return IA->getAsmString().trim().empty() &&
           IA->getConstraintString().trim().empty();
  };

  auto HasInlineAsm = [](Function *F) {
    if (!F || F->isDeclaration()) return false;
    for (BasicBlock &BB : *F) {
      for (Instruction &I : BB) {
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          if (CI->isInlineAsm()) return true;
        }
      }
    }
    return false;
  };

  // Strip globally-empty asm barriers. These are a common lifter/obfuscator
  // artifact and only block later CFG/simplify passes.
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    SmallVector<CallInst *, 16> EmptyAsmCalls;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (IsTriviallyEmptyInlineAsm(CI)) {
          EmptyAsmCalls.push_back(CI);
        }
      }
    }

    for (CallInst *CI : EmptyAsmCalls) {
      if (!CI->getType()->isVoidTy()) {
        CI->replaceAllUsesWith(UndefValue::get(CI->getType()));
      }
      CI->eraseFromParent();
      Changed = true;
    }
  }

  // Rename only an asm-backed McSema launcher. A normal native main must stay.
  if (Function *MainF = M.getFunction("main"); HasInlineAsm(MainF) &&
                                             !M.getFunction("old_main")) {
    MainF->setName("old_main");
    Changed = true;
  }

  // ONLY strip inline assembly from old_main to avoid breaking callback wrappers
  if (Function *OldMainF = M.getFunction("old_main")) {
    SmallVector<CallInst *, 16> AsmCalls;
    for (BasicBlock &BB : *OldMainF) {
      for (Instruction &I : BB) {
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          if (CI->isInlineAsm()) {
            AsmCalls.push_back(CI);
          }
        }
      }
    }
    for (CallInst *CI : AsmCalls) {
      if (!CI->getType()->isVoidTy()) {
        CI->replaceAllUsesWith(UndefValue::get(CI->getType()));
      }
      CI->eraseFromParent();
      Changed = true;
    }
  }

  return Changed;
}

} // namespace brighten_repair
