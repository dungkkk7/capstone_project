#include "BrightenDevirtPass.h"

#include "llvm/ADT/Twine.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

namespace {

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

static void VerifyRemillCalls(Module &M, Function *Target, bool IsJump,
                              VerifyStats &Stats) {
  if (!Target)
    return;
  const DataLayout &DL = M.getDataLayout();
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || !IsCallTo(CB, Target) || CB->arg_size() < 2)
          continue;
        auto PC = ExtractConstantPC(CB->getArgOperand(1), DL);
        if (PC) {
          if (IsJump)
            ++Stats.UnresolvedConstJumps;
          else
            ++Stats.UnresolvedConstCalls;
          errs() << "[devirt] unresolved constant "
                 << (IsJump ? "jump" : "call") << " PC 0x"
                 << Twine::utohexstr(*PC) << "\n";
        } else if (IsJump) {
          ++Stats.DynamicJumps;
        } else {
          ++Stats.DynamicCalls;
        }
      }
    }
  }
}

} // namespace

bool BrightenDevirtPass::VerifyDevirtualization(Module &M) {
  VerifyStats Stats;
  VerifyRemillCalls(M, M.getFunction("__remill_function_call"), false, Stats);
  VerifyRemillCalls(M, M.getFunction("__remill_jump"), true, Stats);

  for (Function &F : M)
    if (F.getName().starts_with("callback_sub_") && !F.use_empty())
      ++Stats.CallbackRefs;

  static const char *Dispatchers[] = {
      "__remill_function_call", "__remill_jump", "__remill_function_return",
      "__lifter_refine_noop_call"};
  for (const char *Name : Dispatchers)
    if (Function *F = M.getFunction(Name); F && !F->use_empty())
      ++Stats.DispatchersNeeded;

  errs() << "[devirt-v2] summary: dynamic_calls=" << Stats.DynamicCalls
         << ", dynamic_jumps=" << Stats.DynamicJumps
         << ", unresolved_const_calls=" << Stats.UnresolvedConstCalls
         << ", unresolved_const_jumps=" << Stats.UnresolvedConstJumps
         << ", callback_refs=" << Stats.CallbackRefs
         << ", dispatchers_needed=" << Stats.DispatchersNeeded << "\n";
  return false;
}

} // namespace brighten_devirt
