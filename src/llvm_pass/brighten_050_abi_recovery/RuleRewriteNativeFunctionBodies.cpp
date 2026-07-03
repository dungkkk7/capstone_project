#include "BrightenABIRecoveryPass.h"

#include "llvm/IR/CFG.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/raw_ostream.h"

#include <map>
#include <set>

namespace brighten_abi {

using namespace llvm;

using RegSet = std::set<ABIReg>;

static Value *NativeArgForReg(FunctionABISummary &S, ABIReg Reg) {
  unsigned Index = 0;
  if (S.HiddenState) {
    ++Index;
  }
  if (S.HiddenPC) {
    ++Index;
  }
  if (S.HiddenMemory) {
    ++Index;
  }
  for (const ABIArgInfo &Arg : S.Args) {
    if (Arg.Reg == Reg) {
      return S.NativeFn->getArg(Index);
    }
    ++Index;
  }
  return nullptr;
}

static RegSet IntersectPredOuts(BasicBlock &BB,
                                const std::map<BasicBlock *, RegSet> &Out) {
  bool First = true;
  RegSet Result;
  for (BasicBlock *Pred : predecessors(&BB)) {
    auto It = Out.find(Pred);
    RegSet PredOut = It == Out.end() ? RegSet{} : It->second;
    if (First) {
      Result = std::move(PredOut);
      First = false;
      continue;
    }
    for (auto RI = Result.begin(); RI != Result.end();) {
      if (!PredOut.count(*RI)) {
        RI = Result.erase(RI);
      } else {
        ++RI;
      }
    }
  }
  return Result;
}

static bool ReplaceLiveInLoads(FunctionABISummary &S) {
  Function &F = *S.NativeFn;
  std::map<BasicBlock *, RegSet> In;
  std::map<BasicBlock *, RegSet> Out;
  bool Changed = false;

  bool DataflowChanged = true;
  while (DataflowChanged) {
    DataflowChanged = false;
    for (BasicBlock &BB : F) {
      RegSet NewIn;
      if (&BB != &F.getEntryBlock()) {
        NewIn = IntersectPredOuts(BB, Out);
      }
      if (In[&BB] != NewIn) {
        In[&BB] = NewIn;
        DataflowChanged = true;
      }
      RegSet Def = In[&BB];
      for (Instruction &I : BB) {
        auto RA = IdentifyRegAccess(I);
        if (!RA) {
          continue;
        }
        if (RA->IsStore && IsArgumentRegister(RA->Reg)) {
          Def.insert(RA->Reg);
        }
      }
      if (Out[&BB] != Def) {
        Out[&BB] = std::move(Def);
        DataflowChanged = true;
      }
    }
  }

  SmallVector<Instruction *, 32> ToErase;
  for (BasicBlock &BB : F) {
    RegSet Def = In[&BB];
    for (Instruction &I : BB) {
      auto RA = IdentifyRegAccess(I);
      if (!RA) {
        continue;
      }
      if (RA->IsLoad && S.LiveIns.count(RA->Reg) && !Def.count(RA->Reg)) {
        auto *LI = dyn_cast<LoadInst>(&I);
        if (!LI || LI->isVolatile()) {
          continue;
        }
        Value *Arg = NativeArgForReg(S, RA->Reg);
        if (!Arg) {
          continue;
        }
        IRBuilder<> B(LI);
        Value *Replacement =
            CoerceValue(B, Arg, LI->getType(), GetRegisterName(RA->Reg));
        if (!Replacement) {
          continue;
        }
        LI->replaceAllUsesWith(Replacement);
        ToErase.push_back(LI);
        Changed = true;
      }
      if (RA->IsStore && IsArgumentRegister(RA->Reg)) {
        Def.insert(RA->Reg);
      }
    }
  }

  for (Instruction *I : ToErase) {
    I->eraseFromParent();
  }
  return Changed;
}

static bool RewriteReturns(FunctionABISummary &S) {
  Function &F = *S.NativeFn;
  SmallVector<ReturnInst *, 8> Returns;
  for (BasicBlock &BB : F) {
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator())) {
      Returns.push_back(RI);
    }
  }

  bool Changed = false;
  for (ReturnInst *RI : Returns) {
    IRBuilder<> B(RI);
    if (S.RetKind == ReturnKind::Void) {
      B.CreateRetVoid();
      RI->eraseFromParent();
      Changed = true;
      continue;
    }

    Value *RetV = FindRegisterValueBeforeReturn(RI, ABIReg::RAX);
    if (!RetV) {
      errs() << "[brighten-abi] skipped return rewrite: " << S.OriginalName
             << " reason=no-rax-value\n";
      continue;
    }
    RetV = CoerceValue(B, RetV, S.RetTy, "abi.ret");
    if (!RetV) {
      errs() << "[brighten-abi] skipped return rewrite: " << S.OriginalName
             << " reason=ret-type-conflict\n";
      continue;
    }
    B.CreateRet(RetV);
    RI->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

bool BrightenABIRecoveryPass::RewriteNativeFunctionBodies(
    ABIRecoveryContext &Ctx) {
  bool Changed = false;
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (!S->Cloned || !S->NativeFn) {
      continue;
    }
    Changed |= ReplaceLiveInLoads(*S);
    Changed |= RewriteReturns(*S);
    S->NativeBodyRewritten = true;
  }
  return Changed;
}

} // namespace brighten_abi

