#include "BrightenABIRecoveryPass.h"

#include "llvm/Support/raw_ostream.h"

namespace brighten_abi {

using namespace llvm;

static bool HasDirectSelfCall(Function &F) {
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB) {
        continue;
      }
      if (ResolveCalledFunction(CB->getCalledOperand()) == &F) {
        return true;
      }
    }
  }
  return false;
}

static void InferHiddenArgs(FunctionABISummary &S) {
  Function &F = *S.RemillFn;
  S.HiddenState = !F.getArg(0)->use_empty();
  S.HiddenPC = !F.getArg(1)->use_empty();
  S.HiddenMemory = !F.getArg(2)->use_empty();
}

static void InferArgs(FunctionABISummary &S, ABIRecoveryContext &Ctx) {
  for (ABIReg Reg : GetSysVArgumentOrder()) {
    if (!IsArgumentRegister(Reg) || IsIgnoredAsArgument(Reg)) {
      continue;
    }

    bool LiveIn = S.LiveIns.count(Reg);
    bool StoreEvidence = S.CallsiteArgTypes.count(Reg);
    if (!LiveIn && !StoreEvidence) {
      continue;
    }

    ABIArgInfo Arg;
    Arg.Reg = Reg;
    Arg.LiveIn = LiveIn;
    Arg.CallsiteEvidence = StoreEvidence;
    Arg.LoadCount = S.LiveInLoadCounts[Reg];
    Arg.StoreEvidenceCount = StoreEvidence ? 1 : 0;
    Arg.Ty = MergeABIType(S.LiveInTypes[Reg], S.CallsiteArgTypes[Reg], Ctx.DL);
    if (!Arg.Ty) {
      Arg.Ty = DefaultArgumentType(Ctx.M.getContext(), Reg);
    }
    S.Args.push_back(Arg);
  }
}

static void InferReturn(FunctionABISummary &S, ABIRecoveryContext &Ctx) {
  if (S.HasCompleteReturnValues &&
      (S.ReturnObservedByCaller || S.HasReturnMetadata ||
       S.OriginalName.find("_main") != std::string::npos)) {
    // SysV returns a 128-bit integer in RDX:RAX.  Return metadata alone only
    // proves the primary RAX value; require one caller to directly consume
    // both registers before turning mutable lifted register state into a
    // composite native ABI return.
    // A surviving RDX value is often just an incoming third argument carried
    // through the lifted State.  Treat it as the high half of an i128 return
    // only when the callee has its own RDX live-out definition and RDX is not
    // part of the recovered input ABI.
    S.RetKind = S.HasCompleteRDXValues &&
                        S.LiveOutStores.count(ABIReg::RDX) != 0 &&
                        !S.LiveIns.count(ABIReg::RDX) &&
                        S.ReturnRDXRAXObservedBySameCallsite
                    ? ReturnKind::IntRDXRAX
                    : ReturnKind::IntRAX;
  } else {
    S.RetKind = ReturnKind::Void;
  }
  S.RetTy = DefaultReturnType(Ctx.M.getContext(), S.RetKind);
}

bool BrightenABIRecoveryPass::InferFunctionABISignatures(
    ABIRecoveryContext &Ctx) {
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (S->SkipNative) {
      errs() << "[brighten-abi] skipped: " << S->OriginalName
             << " reason=" << S->SkipReason << "\n";
      continue;
    }
    // Recursive lifted functions are still recoverable.  The native clone is
    // created first, then RewriteKnownCallsites retargets the cloned body's
    // self-call to that native clone.  Skipping recursion here leaves a live
    // lifted State/pc/memory ABI in otherwise recoverable modules.
    S->Recursive = HasDirectSelfCall(*S->RemillFn);

    InferHiddenArgs(*S);
    InferArgs(*S, Ctx);
    InferReturn(*S, Ctx);
    DebugLiveIns(*S);
    DebugReturn(*S);
  }
  return false;
}

} // namespace brighten_abi
