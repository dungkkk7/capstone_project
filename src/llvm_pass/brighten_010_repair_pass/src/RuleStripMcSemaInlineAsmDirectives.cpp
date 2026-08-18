// Strip McSema inline asm directives/markers that do not carry runtime semantics.
#include "BrightenRepairPass.h"

#include <string>

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

namespace brighten_repair {

using namespace llvm;

static bool IsSafeDirectiveLine(StringRef Line) {
  Line = Line.trim();
  if (Line.empty() || Line.starts_with("#")) {
    return true;
  }
  return Line.starts_with(".cfi_") || Line.starts_with(".loc") ||
         Line.starts_with(".file") || Line.starts_with(".type") ||
         Line.starts_with(".size") || Line.starts_with(".p2align") ||
         Line.starts_with(".intel_syntax") || Line.starts_with(".att_syntax");
}

static bool IsSafeDirectiveAsm(StringRef Asm) {
  if (Asm.trim().empty()) {
    return true;
  }

  SmallVector<StringRef, 8> Lines;
  Asm.split(Lines, '\n', -1, true);
  for (StringRef Line : Lines) {
    if (!IsSafeDirectiveLine(Line)) {
      return false;
    }
  }
  return true;
}

static bool FilterModuleInlineAsm(Module &M) {
  StringRef Asm = M.getModuleInlineAsm();
  if (Asm.empty()) {
    return false;
  }

  bool Changed = false;
  std::string Kept;
  SmallVector<StringRef, 16> Lines;
  Asm.split(Lines, '\n', -1, true);

  for (StringRef Line : Lines) {
    if (IsSafeDirectiveLine(Line)) {
      Changed = true;
      continue;
    }
    if (!Kept.empty()) {
      Kept.push_back('\n');
    }
    Kept.append(Line.str());
  }

  if (Changed) {
    M.setModuleInlineAsm(Kept);
  }
  return Changed;
}

static void EraseInlineAsmCall(CallBase *CB) {
  if (auto *CI = dyn_cast<CallInst>(CB)) {
    CI->eraseFromParent();
    return;
  }

  if (auto *II = dyn_cast<InvokeInst>(CB)) {
    BasicBlock *BB = II->getParent();
    BasicBlock *UnwindDest = II->getUnwindDest();
    BranchInst::Create(II->getNormalDest(), II->getIterator());
    UnwindDest->removePredecessor(BB);
    II->eraseFromParent();
    return;
  }

  if (auto *CBI = dyn_cast<CallBrInst>(CB)) {
    BasicBlock *BB = CBI->getParent();
    BasicBlock *DefaultDest = CBI->getDefaultDest();
    for (BasicBlock *Dest : CBI->getIndirectDests()) {
      if (Dest != DefaultDest) {
        Dest->removePredecessor(BB);
      }
    }
    BranchInst::Create(DefaultDest, CBI->getIterator());
    CBI->eraseFromParent();
  }
}

bool BrightenRepairPass::StripMcSemaInlineAsmDirectives(Module &M) {
  bool Changed = FilterModuleInlineAsm(M);

  SmallVector<CallBase *, 32> ToErase;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || !CB->isInlineAsm()) {
          continue;
        }

        auto *IA = dyn_cast<InlineAsm>(CB->getCalledOperand());
        if (!IA || !IsSafeDirectiveAsm(IA->getAsmString())) {
          continue;
        }

        if (!CB->getType()->isVoidTy() && !CB->use_empty()) {
          continue;
        }
        ToErase.push_back(CB);
      }
    }
  }

  for (CallBase *CB : ToErase) {
    EraseInlineAsmCall(CB);
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair
