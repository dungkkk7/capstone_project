#include "BrightenDevirtPass.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/CFG.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseSet.h"

namespace brighten_devirt {

using namespace llvm;

static Value *FindRAXValueInBlock(BasicBlock *BB) {
  for (auto It = BB->rbegin(); It != BB->rend(); ++It) {
    Instruction &I = *It;
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      Value *Ptr = SI->getPointerOperand()->stripPointerCasts();
      if (auto *GV = dyn_cast<GlobalValue>(Ptr)) {
        StringRef Name = GV->getName();
        if (Name.starts_with("RAX_")) {
          return SI->getValueOperand();
        }
      }
      if (auto *GEP = dyn_cast<GetElementPtrInst>(Ptr)) {
        Value *Base = GEP->getPointerOperand()->stripPointerCasts();
        if (auto *BaseGV = dyn_cast<GlobalValue>(Base)) {
          if (BaseGV->getName() == "__mcsema_reg_state") {
            if (GEP->getNumIndices() >= 3) {
              if (auto *CI = dyn_cast<ConstantInt>(GEP->getOperand(3))) {
                if (CI->getZExtValue() == 1) { // RAX slot is 1
                  return SI->getValueOperand();
                }
              }
            }
          }
        }
      }
    }
  }
  return nullptr;
}

static Value *FindRAXValueBeforeRet(ReturnInst *RI) {
  BasicBlock *BB = RI->getParent();
  if (Value *Val = FindRAXValueInBlock(BB)) {
    return Val;
  }
  
  // Search predecessors (up to depth 3)
  SmallVector<BasicBlock *, 8> Worklist;
  DenseSet<BasicBlock *> Visited;
  
  for (BasicBlock *Pred : predecessors(BB)) {
    Worklist.push_back(Pred);
  }
  
  int Depth = 0;
  while (!Worklist.empty() && Depth < 3) {
    int Size = Worklist.size();
    for (int i = 0; i < Size; ++i) {
      BasicBlock *Pred = Worklist.pop_back_val();
      if (!Visited.insert(Pred).second) continue;
      
      if (Value *Val = FindRAXValueInBlock(Pred)) {
        return Val;
      }
      for (BasicBlock *P : predecessors(Pred)) {
        Worklist.push_back(P);
      }
    }
    Depth++;
  }
  return nullptr;
}

bool BrightenDevirtPass::LowerRemillReturn(Module &M) {
  bool Changed = false;
  LLVMContext &Ctx = M.getContext();

  if (Function *RemillRet = M.getFunction("__remill_function_return")) {
    SmallVector<CallInst *, 16> RetCalls;
    for (User *U : RemillRet->users()) {
      if (auto *CI = dyn_cast<CallInst>(U)) {
        RetCalls.push_back(CI);
      }
    }

    for (CallInst *CI : RetCalls) {
      Value *MemArg = CI->getArgOperand(2);
      Function *F = CI->getFunction();
      
      CI->replaceAllUsesWith(MemArg);
      
      Value *OldRetVal = nullptr;
      ReturnInst *TheRet = nullptr;
      for (BasicBlock &BB : *F) {
        if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator())) {
          OldRetVal = RI->getReturnValue();
          TheRet = RI;
          break;
        }
      }

      if (TheRet) {
        TheRet->setOperand(0, MemArg);
        if (OldRetVal && OldRetVal != MemArg) {
          if (auto *OldI = dyn_cast<Instruction>(OldRetVal)) {
            if (OldI->use_empty()) {
              OldI->eraseFromParent();
            }
          }
        }
      }

      CI->eraseFromParent();
      Changed = true;
    }
  }

  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    
    for (BasicBlock &BB : F) {
      Instruction *Term = BB.getTerminator();
      if (auto *RI = dyn_cast<ReturnInst>(Term)) {
        if (Value *RAXVal = FindRAXValueBeforeRet(RI)) {
          Metadata *MDs[] = { ValueAsMetadata::get(RAXVal) };
          MDNode *Node = MDNode::get(Ctx, MDs);
          RI->setMetadata("brighten.return_rax", Node);
          Changed = true;
        }
      }
    }
  }

  return Changed;
}

} // namespace brighten_devirt
