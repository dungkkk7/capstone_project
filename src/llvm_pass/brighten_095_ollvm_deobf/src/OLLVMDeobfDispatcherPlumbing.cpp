#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

bool validatePlumbingStage(const PlumbingStage &Stage) {
  for (Instruction &I : *Stage.Block) {
    if (isa<PHINode>(I) || I.isTerminator() || isa<DbgInfoIntrinsic>(I))
      continue;
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI || SI->isAtomic() || SI->isVolatile()) return false;
    for (Value *Op : SI->operands())
      if (auto *OI = dyn_cast<Instruction>(Op);
          OI && OI->getParent() == Stage.Block && OI != Stage.StatePhi)
        return false;
  }
  return true;
}

void clonePlumbingStage(const PlumbingStage &Stage,
                               Instruction *InsertBefore) {
  for (Instruction &I : *Stage.Block) {
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI) continue;
    Value *Stored = SI->getValueOperand();
    if (Stored == Stage.StatePhi) Stored = Stage.EdgeValue;
    IRBuilder<> B(InsertBefore);
    StoreInst *Clone = B.CreateStore(Stored, SI->getPointerOperand());
    Clone->setAlignment(SI->getAlign());
    Clone->copyMetadata(*SI);
  }
}

void cloneBlockPlumbing(ArrayRef<Instruction *> Body,
                               Instruction *InsertBefore,
                               DenseMap<const Value *, Value *> &Map) {
  for (Instruction *I : Body) {
    Instruction *Clone = I->clone();
    for (unsigned O = 0; O != Clone->getNumOperands(); ++O) {
      auto It = Map.find(Clone->getOperand(O));
      if (It != Map.end()) Clone->setOperand(O, It->second);
    }
    if (!Clone->getType()->isVoidTy())
      Clone->setName(I->getName() + ".deobf.plumbing");
    Clone->insertBefore(InsertBefore->getIterator());
    Map[I] = Clone;
  }
}

} // namespace brighten_ollvm_deobf
