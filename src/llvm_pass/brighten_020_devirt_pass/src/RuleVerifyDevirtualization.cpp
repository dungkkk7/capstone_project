#include "BrightenDevirtPass.h"

#include "llvm/ADT/Twine.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

static bool IsCallTo(CallBase *CB, Function *F) {
  return F && ResolveCalledFunction(CB->getCalledOperand()) == F;
}

struct VerifyStats {
  unsigned DynamicCalls = 0;
  unsigned DynamicJumps = 0;
  unsigned UnresolvedConstCalls = 0;
  unsigned UnresolvedConstJumps = 0;
  unsigned CallbackRefs = 0;
  unsigned DispatchersNeeded = 0;
};

static void VerifyRemillCalls(Module &M, Function *Target, StringRef Kind,
                              VerifyStats &Stats) {
  if (!Target) {
    return;
  }

  bool IsJump = Kind.ends_with("jump");

  const DataLayout &DL = M.getDataLayout();
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || !IsCallTo(CB, Target) || CB->arg_size() < 2) {
          continue;
        }

        auto PC = ExtractConstantPC(CB->getArgOperand(1), DL);
        if (PC) {
          if (IsJump) {
            ++Stats.UnresolvedConstJumps;
          } else {
            ++Stats.UnresolvedConstCalls;
          }
          errs() << "[devirt] WARNING: unresolved constant " << Kind
                 << " PC = 0x" << Twine::utohexstr(*PC) << "\n";
        } else {
          if (IsJump) {
            ++Stats.DynamicJumps;
          } else {
            ++Stats.DynamicCalls;
          }
          errs() << "[devirt] INFO: dynamic remill "
                 << (IsJump ? "jump" : "call") << " preserved\n";
        }
      }
    }
  }
}

bool BrightenDevirtPass::VerifyDevirtualization(Module &M) {
  VerifyStats Stats;
  VerifyRemillCalls(M, M.getFunction("__remill_function_call"),
                    "__remill_function_call", Stats);
  VerifyRemillCalls(M, M.getFunction("__remill_jump"), "__remill_jump",
                    Stats);

  for (Function &F : M) {
    if (F.getName().starts_with("callback_sub_") && !F.use_empty()) {
      ++Stats.CallbackRefs;
      errs() << "[devirt] callback thunk still referenced: @" << F.getName()
             << "\n";
    }
  }

  static const char *Dispatchers[] = {
      "__remill_function_call", "__remill_jump", "__remill_function_return",
      "__lifter_refine_noop_call"};
  for (const char *Name : Dispatchers) {
    if (Function *F = M.getFunction(Name)) {
      if (!F->use_empty()) {
        ++Stats.DispatchersNeeded;
        errs() << "[devirt] remill dispatcher still needed: @" << Name << "\n";
      }
    }
  }

  if (Function *Attach = M.getFunction("__mcsema_attach_call")) {
    if (!Attach->use_empty() || Attach->isDeclaration()) {
      errs() << "[devirt] ERROR: unresolved __mcsema_attach_call remains\n";
    }
  }

  unsigned MainLike = 0;
  for (Function &F : M) {
    if (F.getName() == "main" || F.getName().starts_with("main.")) {
      ++MainLike;
    }
  }
  if (MainLike > 1) {
    errs() << "[devirt] ERROR: duplicate @main-like functions detected\n";
  }

  errs() << "[devirt] summary: dynamic_calls=" << Stats.DynamicCalls
         << ", dynamic_jumps=" << Stats.DynamicJumps
         << ", unresolved_const_calls=" << Stats.UnresolvedConstCalls
         << ", unresolved_const_jumps=" << Stats.UnresolvedConstJumps
         << ", callback_refs=" << Stats.CallbackRefs
         << ", dispatchers_needed=" << Stats.DispatchersNeeded << "\n";

  return false;
}

} // namespace brighten_devirt
