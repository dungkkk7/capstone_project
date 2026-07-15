#include "BrightenExternCallBridgePass.h"

#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_extern {

using namespace llvm;

static constexpr uint64_t kGPArgOffsets[] = {2296, 2280, 2264, 2248, 2344, 2360};

static std::optional<uint64_t> IdentifyStateOffset(Value *Ptr) {
  if (!Ptr) return std::nullopt;
  Value *Stripped = Ptr->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalValue>(Stripped)) {
    StringRef Name = GV->getName();
    if (Name == "RAX" || Name == "rax") return 2216;
    if (Name == "RDI" || Name == "rdi") return 2296;
    if (Name == "RSI" || Name == "rsi") return 2280;
    if (Name == "RDX" || Name == "rdx") return 2264;
    if (Name == "RCX" || Name == "rcx") return 2248;
    if (Name == "R8" || Name == "r8") return 2344;
    if (Name == "R9" || Name == "r9") return 2360;
  }
  Module *M = nullptr;
  if (auto *I = dyn_cast<Instruction>(Stripped)) M = I->getModule();
  else if (auto *GV = dyn_cast<GlobalValue>(Stripped)) M = GV->getParent();
  if (!M) return std::nullopt;
  const DataLayout &DL = M->getDataLayout();
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Stripped->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (!Base || Offset.isNegative()) return std::nullopt;
  Base = Base->stripPointerCasts();
  if (auto *Alias = dyn_cast<GlobalAlias>(Base))
    if (Constant *Aliasee = Alias->getAliasee())
      Base = Aliasee->stripPointerCasts();
  auto *GV = dyn_cast<GlobalValue>(Base);
  if (!GV || GV->getName() != "__mcsema_reg_state") return std::nullopt;
  return Offset.getZExtValue();
}

static bool IsArgRegOffset(uint64_t Off) {
  for (uint64_t R : kGPArgOffsets)
    if (R == Off) return true;
  return false;
}

// FIX #10: Clean up dead register stores that were setting up args for
// rewritten external calls. Also remove stale .old declarations.
bool BrightenExternCallBridgePass::CleanupExternalCallArtifacts(
    ExternCallContext &Ctx) {
  bool Changed = false;

  // Pass 1: Find stores to argument registers that have no remaining loads
  // in the same basic block after the store. These are likely dead setup
  // stores for calls that have been rewritten.
  for (Function &F : Ctx.M) {
    if (F.isDeclaration()) continue;
    SmallVector<StoreInst *, 32> DeadStores;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<StoreInst>(&I);
        if (!SI) continue;

        auto Off = IdentifyStateOffset(SI->getPointerOperand());
        if (!Off || !IsArgRegOffset(*Off)) continue;

        // Check if there's any load from this register after this store
        // in the same block. If not, it's dead.
        bool HasLoad = false;
        for (auto It = std::next(SI->getIterator()); It != BB.end(); ++It) {
          if (auto *LI = dyn_cast<LoadInst>(&*It)) {
            auto LOff = IdentifyStateOffset(LI->getPointerOperand());
            if (LOff && *LOff == *Off) {
              HasLoad = true;
              break;
            }
          }
          // Stop at calls — they might read from state
          if (isa<CallBase>(&*It)) {
            HasLoad = true;
            break;
          }
        }

        if (!HasLoad)
          DeadStores.push_back(SI);
      }
    }

    // FIX: Disabled store deletion to prevent deleting potentially live registers
    // without dataflow liveness analysis.
    (void)DeadStores;
  }

  // Pass 2: Remove stale .old declarations
  SmallVector<Function *, 8> OldDecls;
  for (Function &F : Ctx.M) {
    if (F.isDeclaration() && F.getName().ends_with(".old") && F.use_empty())
      OldDecls.push_back(&F);
  }
  for (Function *F : OldDecls) {
    F->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

bool BrightenExternCallBridgePass::VerifyExternalCallRecovery(
    ExternCallContext &Ctx) {
  bool HasError = false;

  for (auto &CS : Ctx.Callsites) {
    if (CS->Rewritten && !CS->Target.Resolved) {
      errs() << "[brighten-extern] VERIFY ERROR: rewritten call has "
                "unresolved target in "
             << CS->Caller->getName() << "\n";
      HasError = true;
      ++Ctx.Report.VerifierErrors;
    }
    if (Ctx.Mode == ExternRecoveryMode::NativeStrict && !CS->Rewritten) {
      errs() << "[brighten-extern] VERIFY ERROR: NativeStrict preserved "
                "external callsite in "
             << CS->Caller->getName() << " -> "
             << (CS->Target.SymbolName.empty() ? "<unresolved>"
                                                : CS->Target.SymbolName)
             << " reason="
             << (CS->SkipReason.empty() ? "not-rewritten" : CS->SkipReason)
             << "\n";
      HasError = true;
      ++Ctx.Report.VerifierErrors;
    }
  }

  // FIX #3 verification: check vararg count accounts for scanf suppression
  for (auto &CS : Ctx.Callsites) {
    if (!CS->Rewritten || !CS->Target.Signature) continue;
    const LibcSignature &Sig = *CS->Target.Signature;
    if (!Sig.IsVarArg || !CS->Vararg.FormatResolved) continue;

    unsigned ExpectedVarargs = 0;
    for (auto &Spec : CS->Vararg.Specifiers) {
      if (Spec.ConsumesArg) ++ExpectedVarargs;
    }
    unsigned FixedCount = Sig.FixedParams.size();
    unsigned TotalArgs = CS->Args.size();
    unsigned ActualVarargs = TotalArgs > FixedCount ? TotalArgs - FixedCount : 0;

    if (ActualVarargs < ExpectedVarargs) {
      errs() << "[brighten-extern] VERIFY ERROR: " << CS->Target.SymbolName
             << " vararg count mismatch: expected>=" << ExpectedVarargs
             << " got=" << ActualVarargs << "\n";
      HasError = true;
      ++Ctx.Report.VerifierErrors;
    }
  }

  if (Ctx.Mode == ExternRecoveryMode::NativeStrict) {
    for (auto &CS : Ctx.Callsites) {
      if (!CS->Rewritten) continue;
      for (auto &Arg : CS->Args) {
        if (Arg.IsFallbackTranslated) {
          errs() << "[brighten-extern] VERIFY ERROR: NativeStrict mode but "
                    "fallback translation used in "
                 << CS->Caller->getName() << " -> "
                 << CS->Target.SymbolName << "\n";
          HasError = true;
          ++Ctx.Report.VerifierErrors;
        }
      }
    }
  }

  std::string ErrStr;
  raw_string_ostream ErrOS(ErrStr);
  if (verifyModule(Ctx.M, &ErrOS)) {
    errs() << "[brighten-extern] VERIFY ERROR: LLVM module verifier failed:\n"
           << ErrStr << "\n";
    HasError = true;
    ++Ctx.Report.VerifierErrors;
  }

  return HasError;
}

} // namespace brighten_extern
