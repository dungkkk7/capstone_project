#include "RuleEngineInternal.h"
#include "RuleEngineSupport.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/InstIterator.h"

namespace deobfuscate095::rule_detail {

using namespace llvm;

bool foldConstantControl(Module &M, RuleEngineStats &Stats) {
  SmallVector<BranchInst *, 128> Branches;
  SmallVector<SelectInst *, 128> Selects;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F)) {
      if (auto *BI = dyn_cast<BranchInst>(&I);
          BI && BI->isConditional())
        Branches.push_back(BI);
      else if (auto *SI = dyn_cast<SelectInst>(&I))
        Selects.push_back(SI);
    }
  }

  bool Changed = false;
  for (BranchInst *BI : Branches) {
    if (!BI->getParent())
      continue;
    auto *Condition =
        dyn_cast<ConstantInt>(BI->getCondition());
    if (!Condition)
      continue;
    replaceBranch(*BI, !Condition->isZero());
    ++Stats.BranchRewrites;
    Changed = true;
  }

  for (SelectInst *SI : Selects) {
    if (!SI->getParent())
      continue;
    auto *Condition =
        dyn_cast<ConstantInt>(SI->getCondition());
    if (!Condition)
      continue;
    Value *Replacement = Condition->isZero()
                             ? SI->getFalseValue()
                             : SI->getTrueValue();
    SI->replaceAllUsesWith(Replacement);
    SI->eraseFromParent();
    ++Stats.SelectRewrites;
    Changed = true;
  }
  return Changed;
}

} // namespace deobfuscate095::rule_detail
