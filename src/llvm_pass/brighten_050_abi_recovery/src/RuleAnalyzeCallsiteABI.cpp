#include "BrightenABIRecoveryPass.h"

#include "llvm/IR/InlineAsm.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_abi {

using namespace llvm;

static bool IsBarrierCall(CallBase &CB) {
  Function *Callee = CB.getCalledFunction();
  if (!Callee) {
    return true;
  }
  if (Callee->getIntrinsicID() == Intrinsic::sideeffect) {
    return false;
  }
  StringRef Name = Callee->getName();
  return !Name.starts_with("llvm.") && !Name.starts_with("__remill_barrier");
}

static void FindStoredArgsInBlock(CallInst &CI, CallsiteABIInfo &Info,
                                  const DataLayout &DL) {
  BasicBlock *BB = CI.getParent();
  for (auto It = BasicBlock::reverse_iterator(CI.getIterator());
       It != BB->rend(); ++It) {
    Instruction &I = *It;
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (isa<InlineAsm>(CB->getCalledOperand()->stripPointerCasts()) ||
          IsBarrierCall(*CB)) {
        break;
      }
    }

    auto RA = IdentifyRegAccess(I);
    if (!RA || !RA->IsStore || !IsArgumentRegister(RA->Reg)) {
      continue;
    }
    if (!Info.StoredArgs.count(RA->Reg)) {
      Info.StoredArgs[RA->Reg] = RA->Value;
      Info.ArgTypes[RA->Reg] =
          MergeABIType(Info.ArgTypes[RA->Reg], RA->AccessType, DL);
    }
  }
}

static bool ObservesRegisterAfter(CallInst &CI, ABIReg Reg) {
  BasicBlock *BB = CI.getParent();
  for (auto It = std::next(CI.getIterator()); It != BB->end(); ++It) {
    Instruction &I = *It;
    if (auto RA = IdentifyRegAccess(I)) {
      if (RA->Reg == Reg) {
        if (RA->IsLoad) {
          return true;
        }
        if (RA->IsStore) {
          return false;
        }
      }
    }
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      Function *Callee = CB->getCalledFunction();
      if (!Callee || !Callee->getName().starts_with("llvm.")) {
        return false;
      }
    }
  }
  return false;
}

static bool HasOnlyMemoryReplacementUses(CallInst &CI,
                                         FunctionABISummary &Target) {
  if (CI.use_empty()) {
    return true;
  }
  return Target.ReturnsOriginalMemoryArg;
}

bool BrightenABIRecoveryPass::AnalyzeCallsiteABI(ABIRecoveryContext &Ctx) {
  for (Function &Caller : Ctx.M) {
    if (Caller.isDeclaration()) {
      continue;
    }
    for (BasicBlock &BB : Caller) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI) {
          continue;
        }
        Function *Target = ResolveCalledFunction(CI->getCalledOperand());
        FunctionABISummary *S = FindSummary(Ctx, Target);
        if (!S) {
          continue;
        }

        CallsiteABIInfo Info;
        Info.Call = CI;
        Info.Caller = &Caller;
        Info.Target = Target;
        FindStoredArgsInBlock(*CI, Info, Ctx.DL);
        Info.ObservesRAX = ObservesRegisterAfter(*CI, ABIReg::RAX);
        Info.ObservesRDX = ObservesRegisterAfter(*CI, ABIReg::RDX);
        Info.RewritableMemoryResult = HasOnlyMemoryReplacementUses(*CI, *S);

        for (auto &[Reg, Ty] : Info.ArgTypes) {
          S->CallsiteArgTypes[Reg] =
              MergeABIType(S->CallsiteArgTypes[Reg], Ty, Ctx.DL);
        }
        if (Info.ObservesRAX) {
          S->ReturnObservedByCaller = true;
        }
        if (Info.ObservesRDX) {
          S->ReturnRDXObservedByCaller = true;
        }
        if (Info.ObservesRAX && Info.ObservesRDX) {
          S->ReturnRDXRAXObservedBySameCallsite = true;
        }
        S->Calls.push_back(Info);
      }
    }
  }
  return false;
}

} // namespace brighten_abi
