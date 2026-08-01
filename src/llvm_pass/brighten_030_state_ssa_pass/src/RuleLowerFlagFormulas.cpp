#include "BrightenStateSSAPass.h"
#include "StateSlotLayout.h"
#include "StateOffsetResolver.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

#include <climits>
#include <cstdint>
#include <optional>

namespace brighten_state_ssa {

using namespace llvm;

namespace {

// ===================================================================
// Flag formula pattern matching
// ===================================================================

enum class FlagFormulaKind {
  ZeroFlag,       // icmp eq result, 0
  SignFlag,       // lshr result, (bitwidth-1)
  CarryConstZero, // constant 0
  CarryConstOne,  // constant 1
  CarryComputed,  // zext(i1 icmp ult ...)
  OverflowComputed, // complex pattern
  ParityComputed,   // xor chain
  Unknown,
};

static FlagFormulaKind ClassifyFlagValue(Value *V, Value **OutI1) {
  *OutI1 = nullptr;

  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    if (CI->isZero()) return FlagFormulaKind::CarryConstZero;
    if (CI->isOne()) return FlagFormulaKind::CarryConstOne;
    return FlagFormulaKind::Unknown;
  }

  if (auto *ZExt = dyn_cast<ZExtInst>(V)) {
    Value *Src = ZExt->getOperand(0);
    if (Src->getType()->isIntegerTy(1)) {
      if (auto *ICmp = dyn_cast<ICmpInst>(Src)) {
        if (ICmp->getPredicate() == ICmpInst::ICMP_EQ) {
          if (auto *RHS = dyn_cast<ConstantInt>(ICmp->getOperand(1))) {
            if (RHS->isZero()) {
              *OutI1 = Src;
              return FlagFormulaKind::ZeroFlag;
            }
          }
        }
        if (ICmp->getPredicate() == ICmpInst::ICMP_ULT) {
          *OutI1 = Src;
          return FlagFormulaKind::CarryComputed;
        }
        if (ICmp->getPredicate() == ICmpInst::ICMP_UGT) {
          *OutI1 = Src;
          return FlagFormulaKind::OverflowComputed;
        }
      }
      if (auto *OrInst = dyn_cast<BinaryOperator>(Src)) {
        if (OrInst->getOpcode() == Instruction::Or) {
          *OutI1 = Src;
          return FlagFormulaKind::CarryComputed;
        }
      }
      *OutI1 = Src;
      return FlagFormulaKind::CarryComputed;
    }
  }

  if (auto *Trunc = dyn_cast<TruncInst>(V)) {
    Value *TruncSrc = Trunc->getOperand(0);
    if (auto *LShr = dyn_cast<BinaryOperator>(TruncSrc)) {
      if (LShr->getOpcode() == Instruction::LShr) {
        if (auto *ShAmt = dyn_cast<ConstantInt>(LShr->getOperand(1))) {
          unsigned Shift = ShAmt->getZExtValue();
          unsigned SrcBits = LShr->getOperand(0)->getType()->getIntegerBitWidth();
          if (Shift == SrcBits - 1) {
            *OutI1 = nullptr;
            return FlagFormulaKind::SignFlag;
          }
        }
      }
    }
  }

  return FlagFormulaKind::Unknown;
}

} // namespace

// ===================================================================
// Flag formula lowering
// ===================================================================

bool BrightenStateSSAPass::LowerKnownFlagComputations(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");
  if (!StateGV) return false;

  DiscoveredFlagLayout FlagLayout = DiscoverFlagSlots(M);
  if (!FlagLayout.Valid) return false;

  // Step 2: Scan module for flag loads (supporting both Global & Arg0 bases)
  DenseSet<uint64_t> FlagOffsetsWithLoads;
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *LI = dyn_cast<LoadInst>(&I);
        if (!LI) continue;
        auto Resolved = ResolveStateOffset(LI->getPointerOperand(), DL, F, StateGV);
        if (!Resolved) continue;
        if (IsFlagOffset(FlagLayout, Resolved->Offset))
          FlagOffsetsWithLoads.insert(Resolved->Offset);
      }
    }
  }

  // Do not remove a State flag store merely because this module has no
  // constant-offset load.  State can be observed through a dynamic access,
  // callback, or linked runtime.  Once State is truly localized, LLVM DSE can
  // prove deadness without this whole-program escape assumption.
  unsigned DeadCount = 0;

  // Step 4: Intra-block flag forwarding (guarded by call & unknown write invalidation)
  unsigned ForwardedCount = 0;

  for (Function &F : M) {
    if (F.isDeclaration() || !IsLiftedFunction(F)) continue;
    if (FunctionHasUnsupportedStateBoundary(F, StateGV, DL)) continue;

    for (BasicBlock &BB : F) {
      DenseMap<uint64_t, Value *> LastFlagI8;

      for (auto It = BB.begin(); It != BB.end();) {
        Instruction &I = *It++;

        if (auto *SI = dyn_cast<StoreInst>(&I)) {
          if (SI->isVolatile() || SI->isAtomic()) {
            LastFlagI8.clear();
            continue;
          }
          auto Resolved = ResolveStateOffset(SI->getPointerOperand(), DL, F, StateGV);

          if (Resolved && IsFlagOffset(FlagLayout, Resolved->Offset)) {
            if (FlagOffsetsWithLoads.count(Resolved->Offset)) {
              LastFlagI8[Resolved->Offset] = SI->getValueOperand();
            }
          } else {
            // Unknown memory write or write to non-flag slot: invalidate all forwarding
            LastFlagI8.clear();
          }
          continue;
        }

        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          if (LI->isVolatile() || LI->isAtomic()) {
            LastFlagI8.clear();
            continue;
          }
          auto Resolved = ResolveStateOffset(LI->getPointerOperand(), DL, F, StateGV);
          if (!Resolved || !IsFlagOffset(FlagLayout, Resolved->Offset)) continue;

          auto It8 = LastFlagI8.find(Resolved->Offset);
          if (It8 != LastFlagI8.end() && It8->second) {
            Value *Replacement = It8->second;
            if (Replacement->getType() == LI->getType()) {
              LI->replaceAllUsesWith(Replacement);
              LI->eraseFromParent();
              ForwardedCount++;
              Changed = true;
              continue;
            }
          }
        }

        // Call invalidates all tracked state
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          if (!CI->isInlineAsm()) {
            LastFlagI8.clear();
          }
        }
      }
    }
  }

  if (DeadCount || ForwardedCount) {
    errs() << "[brighten-state-ssa] flag-lower: removed " << DeadCount
           << " dead flag stores, forwarded " << ForwardedCount
           << " flag loads\n";
  }

  return Changed;
}

} // namespace brighten_state_ssa
