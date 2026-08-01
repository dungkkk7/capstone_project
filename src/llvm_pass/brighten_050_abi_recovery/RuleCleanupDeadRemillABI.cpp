#include "BrightenABIRecoveryPass.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/ADT/SmallPtrSet.h"

namespace brighten_abi {

using namespace llvm;

static void PruneDispatcherCases(Module &M, Function *Dispatcher) {
  if (!Dispatcher || Dispatcher->isDeclaration()) return;

  BasicBlock *Entry = &Dispatcher->getEntryBlock();
  auto *SI = dyn_cast_or_null<SwitchInst>(Entry->getTerminator());
  if (!SI) return;

  SmallPtrSet<BasicBlock *, 16> TargetBBsToRemove;

  for (int i = (int)SI->getNumCases() - 1; i >= 0; --i) {
    auto Case = SI->case_begin() + i;
    BasicBlock *Successor = Case->getCaseSuccessor();
    Function *CalledFn = nullptr;
    for (Instruction &I : *Successor) {
      if (auto *CI = dyn_cast<CallInst>(&I)) {
        CalledFn = ResolveCalledFunction(CI->getCalledOperand());
        if (CalledFn) break;
      }
    }

    if (!CalledFn) continue;

    bool HasExternalUses = false;
    if (CalledFn->hasAddressTaken()) {
      HasExternalUses = true;
    } else {
      for (User *U : CalledFn->users()) {
        auto *I = dyn_cast<Instruction>(U);
        if (!I) {
          HasExternalUses = true;
          break;
        }
        Function *UserF = I->getFunction();
        if (UserF && UserF->getName() != "__remill_function_call" &&
            UserF->getName() != "__remill_jump") {
          HasExternalUses = true;
          break;
        }
      }
    }

    if (!HasExternalUses) {
      SI->removeCase(Case);
      TargetBBsToRemove.insert(Successor);
    }
  }

  for (BasicBlock *BB : TargetBBsToRemove) {
    // A dead dispatcher case may contain an internal SSA dependency chain.
    // Erase it backwards, but reject the case if any value escapes the block;
    // replacing such an escape with null changes observable behavior.
    bool Escapes = false;
    for (Instruction &I : *BB) {
      for (User *U : I.users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || UI->getParent() != BB) {
          Escapes = true;
          break;
        }
      }
      if (Escapes) break;
    }
    if (Escapes)
      continue;
    while (!BB->empty())
      BB->back().eraseFromParent();
    BB->eraseFromParent();
  }
}

bool BrightenABIRecoveryPass::CleanupDeadRemillABI(ABIRecoveryContext &Ctx) {
  Function *FuncCall = Ctx.M.getFunction("__remill_function_call");
  Function *JumpCall = Ctx.M.getFunction("__remill_jump");

  // if (FuncCall) PruneDispatcherCases(Ctx.M, FuncCall);
  // if (JumpCall) PruneDispatcherCases(Ctx.M, JumpCall);

  bool Changed = false;
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (S->WrapperFn && S->WrapperFn->use_empty()) {
      errs() << "[brighten-abi] cleanup: erase unused wrapper "
             << S->WrapperFn->getName() << "\n";
      S->WrapperFn->eraseFromParent();
      S->WrapperFn = nullptr;
      Changed = true;
    }
    if (S->RemillFn && S->RemillFn->use_empty()) {
      errs() << "[brighten-abi] cleanup: erase unused remill "
             << S->RemillFn->getName() << "\n";
      S->RemillFn->eraseFromParent();
      S->RemillFn = nullptr;
      Changed = true;
    }
  }

  SmallVector<GlobalVariable *, 4> DeadState;
  for (GlobalVariable &GV : Ctx.M.globals()) {
    if (!GV.getName().contains("__mcsema_reg_state") ||
        !GV.hasLocalLinkage())
      continue;
    GV.removeDeadConstantUsers();
    if (GV.use_empty())
      DeadState.push_back(&GV);
  }
  for (GlobalVariable *GV : DeadState) {
    errs() << "[brighten-abi] cleanup: erase dead shared State "
           << GV->getName() << "\n";
    GV->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_abi
