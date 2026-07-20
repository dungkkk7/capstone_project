#include "BrightenABIRecoveryPass.h"

#include "llvm/IR/CFG.h"

#include <map>
#include <set>

namespace brighten_abi {

using namespace llvm;

using RegSet = std::set<ABIReg>;

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

static void AnalyzeOne(FunctionABISummary &S, const DataLayout &DL) {
  Function &F = *S.RemillFn;
  std::map<BasicBlock *, RegSet> In;
  std::map<BasicBlock *, RegSet> Out;

  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (BasicBlock &BB : F) {
      RegSet NewIn;
      if (&BB != &F.getEntryBlock()) {
        NewIn = IntersectPredOuts(BB, Out);
      }
      if (In[&BB] != NewIn) {
        In[&BB] = NewIn;
        Changed = true;
      }

      RegSet Def = In[&BB];
      for (Instruction &I : BB) {
        auto RA = IdentifyRegAccess(I);
        if (!RA) {
          continue;
        }

        if (RA->IsLoad && IsArgumentRegister(RA->Reg) &&
            !IsIgnoredAsArgument(RA->Reg) && !Def.count(RA->Reg)) {
          S.LiveIns.insert(RA->Reg);
          S.LiveInTypes[RA->Reg] =
              MergeABIType(S.LiveInTypes[RA->Reg], RA->AccessType, DL);
          ++S.LiveInLoadCounts[RA->Reg];
        }

        if (RA->IsStore && IsArgumentRegister(RA->Reg)) {
          Def.insert(RA->Reg);
        }
      }

      if (Out[&BB] != Def) {
        Out[&BB] = std::move(Def);
        Changed = true;
      }
    }
  }
}

bool BrightenABIRecoveryPass::AnalyzeFunctionLiveIns(ABIRecoveryContext &Ctx) {
  for (FunctionABISummary *S : Ctx.Summaries) {
    AnalyzeOne(*S, Ctx.DL);
  }
  return false;
}

} // namespace brighten_abi

