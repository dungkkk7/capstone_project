#include "BrightenStateSSAPass.h"
#include "StateSlotLayout.h"
#include "StateOffsetResolver.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
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
// Helper to peel ZExt i1 -> i8
// ===================================================================
// ===================================================================
// Helper to extract bool i1 from integer value safely using icmp ne 0
// ===================================================================
static Value *BoolFromInt(Value *V, IRBuilder<> &B) {
  if (V->getType()->isIntegerTy(1))
    return V;
  auto *IT = dyn_cast<IntegerType>(V->getType());
  if (!IT)
    return nullptr;
  return B.CreateICmpNE(V, ConstantInt::get(V->getType(), 0));
}

// ===================================================================
// Helper to check if value is a bitwise AND with mask 1 (e.g. and i8 X, 1)
// ===================================================================
static bool IsAndMaskOne(Value *V) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::And)
    return false;
  auto *C0 = dyn_cast<ConstantInt>(BO->getOperand(0));
  auto *C1 = dyn_cast<ConstantInt>(BO->getOperand(1));
  return (C0 && C0->isOne()) || (C1 && C1->isOne());
}

// ===================================================================
// Helper to check if a constant is a boolean byte (0 or 1)
// ===================================================================
static bool IsBoolByteConstant(Value *V) {
  auto *CI = dyn_cast<ConstantInt>(V);
  return CI && (CI->isZero() || CI->isOne());
}

static Value *PeelZExtI1(Value *V) {
  if (auto *Z = dyn_cast<ZExtInst>(V)) {
    if (Z->getOperand(0)->getType()->isIntegerTy(1)) {
      return Z->getOperand(0);
    }
  }
  return nullptr;
}

// ===================================================================
// Helper to check if a value is a load from a flag offset
// ===================================================================
static bool IsLoadFromFlag(Value *V, const DataLayout &DL, Function &F,
                           GlobalVariable *StateGV,
                           const DiscoveredFlagLayout &FlagLayout) {
  if (auto *LI = dyn_cast<LoadInst>(V)) {
    auto Resolved = ResolveStateOffset(LI->getPointerOperand(), DL, F, StateGV);
    if (Resolved && IsFlagOffset(FlagLayout, Resolved->Offset)) {
      return true;
    }
  }
  return false;
}

// ===================================================================
// Helper to construct equivalent i1 value from an i8 value
// ===================================================================
static Value *GetOrCreateI1Value(Value *V, IRBuilder<> &B,
                                 const DenseMap<PHINode *, PHINode *> &PhiMap,
                                 const DataLayout &DL, Function &F,
                                 GlobalVariable *StateGV,
                                 const DiscoveredFlagLayout &FlagLayout) {
  // 1. If it's a zext i1 -> i8, peel it
  if (Value *Peeled = PeelZExtI1(V)) {
    return Peeled;
  }

  // 2. If it's a constant
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    return B.getInt1(!CI->isZero());
  }

  // 3. If it's an i8 PHI that has been mapped to i1 PHI
  if (auto *PN = dyn_cast<PHINode>(V)) {
    auto It = PhiMap.find(PN);
    if (It != PhiMap.end()) {
      return It->second;
    }
  }

  // 4. Truncate (lshr Result, MSB) -> i8 patterns (Sign Flag)
  if (auto *Trunc = dyn_cast<TruncInst>(V)) {
    Value *Src = Trunc->getOperand(0);
    if (auto *LShr = dyn_cast<BinaryOperator>(Src)) {
      if (LShr->getOpcode() == Instruction::LShr) {
        if (auto *ShAmt = dyn_cast<ConstantInt>(LShr->getOperand(1))) {
          unsigned Shift = ShAmt->getZExtValue();
          unsigned SrcBits = LShr->getOperand(0)->getType()->getIntegerBitWidth();
          if (Shift == SrcBits - 1) {
            return B.CreateICmpSLT(LShr->getOperand(0), ConstantInt::get(LShr->getOperand(0)->getType(), 0));
          }
        }
      }
    }
  }

  // 5. Load from a flag offset
  if (IsLoadFromFlag(V, DL, F, StateGV, FlagLayout)) {
    return BoolFromInt(V, B);
  }

  // 6. Bitwise AND with mask 1
  if (IsAndMaskOne(V)) {
    return BoolFromInt(V, B);
  }

  // Fallback: safe conversion using icmp ne
  return BoolFromInt(V, B);
}

// ===================================================================
// RuleCanonicalizeFlagSSA
//
// Analyzes i8 PHI nodes representing flags and transforms them into
// true i1 PHI nodes.
// ===================================================================
static bool CanonicalizeFlagSSA(Function &F, const DataLayout &DL,
                                GlobalVariable *StateGV,
                                const DiscoveredFlagLayout &FlagLayout) {
  bool Changed = false;
  SmallVector<PHINode *, 16> FlagPhis;

  // Step 1: Collect all i8 PHI nodes
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto *PN = dyn_cast<PHINode>(&I)) {
        if (PN->getType()->isIntegerTy(8)) {
          FlagPhis.push_back(PN);
        }
      }
    }
  }

  if (FlagPhis.empty()) return false;

  // Step 2: Determine which PHI nodes are canonical flag PHIs.
  DenseSet<PHINode *> CanonicalPhis;
  bool SetChanged = true;

  while (SetChanged) {
    SetChanged = false;
    for (PHINode *PN : FlagPhis) {
      if (CanonicalPhis.count(PN)) continue;

      bool AllIncomingSafe = true;
      for (unsigned i = 0; i < PN->getNumIncomingValues(); ++i) {
        Value *InVal = PN->getIncomingValue(i);

        if (PeelZExtI1(InVal)) continue;
        if (IsBoolByteConstant(InVal)) continue;
        // A flag State slot is stored as i8 but is not an LLVM i1 contract.
        // Boundary/initial State can contain any byte value, and users other
        // than a zero-test may observe that exact byte.  Do not normalize a
        // raw load to 0/1 merely because its offset is flag-shaped.
        if (IsAndMaskOne(InVal)) continue;

        if (auto *InPN = dyn_cast<PHINode>(InVal)) {
          if (CanonicalPhis.count(InPN) || InPN == PN) continue;
        }

        // SF pattern check
        if (auto *Trunc = dyn_cast<TruncInst>(InVal)) {
          Value *Src = Trunc->getOperand(0);
          if (auto *LShr = dyn_cast<BinaryOperator>(Src)) {
            if (LShr->getOpcode() == Instruction::LShr) {
              if (auto *ShAmt = dyn_cast<ConstantInt>(LShr->getOperand(1))) {
                unsigned Shift = ShAmt->getZExtValue();
                unsigned SrcBits = LShr->getOperand(0)->getType()->getIntegerBitWidth();
                if (Shift == SrcBits - 1) continue;
              }
            }
          }
        }

        AllIncomingSafe = false;
        break;
      }

      if (AllIncomingSafe) {
        CanonicalPhis.insert(PN);
        SetChanged = true;
      }
    }
  }

  if (CanonicalPhis.empty()) return false;

  // Step 3: Create new i1 PHIs and populate their incoming values
  DenseMap<PHINode *, PHINode *> PhiMap;
  for (PHINode *PN : CanonicalPhis) {
    IRBuilder<> B(PN);
    PHINode *NewPN = B.CreatePHI(B.getInt1Ty(), PN->getNumIncomingValues(),
                                 PN->getName() + ".i1");
    PhiMap[PN] = NewPN;
  }

  for (PHINode *PN : CanonicalPhis) {
    PHINode *NewPN = PhiMap[PN];
    for (unsigned i = 0; i < PN->getNumIncomingValues(); ++i) {
      Value *InVal = PN->getIncomingValue(i);
      BasicBlock *InBB = PN->getIncomingBlock(i);
      IRBuilder<> B(InBB->getTerminator());

      Value *I1Val = GetOrCreateI1Value(InVal, B, PhiMap, DL, F, StateGV, FlagLayout);
      NewPN->addIncoming(I1Val, InBB);
    }
  }

  // Step 4: Replace usages of the old i8 PHIs
  unsigned CanonicalizedCount = 0;
  for (PHINode *PN : CanonicalPhis) {
    PHINode *NewPN = PhiMap[PN];
    SmallVector<Instruction *, 8> UsersToReplace;

    for (User *U : PN->users()) {
      if (auto *UI = dyn_cast<Instruction>(U)) {
        UsersToReplace.push_back(UI);
      }
    }

    for (Instruction *UI : UsersToReplace) {
      // If used in icmp ne/eq %flag, 0 -> replace with %flag.i1 directly
      if (auto *ICmp = dyn_cast<ICmpInst>(UI)) {
        bool IsEQ = ICmp->getPredicate() == ICmpInst::ICMP_EQ;
        bool IsNE = ICmp->getPredicate() == ICmpInst::ICMP_NE;
        if (IsEQ || IsNE) {
          Value *RHS = ICmp->getOperand(1);
          if (auto *CI = dyn_cast<ConstantInt>(RHS)) {
            if (CI->isZero()) {
              IRBuilder<> B(ICmp);
              Value *Replacement = IsNE ? (Value *)NewPN : B.CreateNot(NewPN);
              ICmp->replaceAllUsesWith(Replacement);
              ICmp->eraseFromParent();
              continue;
            }
          }
        }
      }

      // If used as store back to State memory (boundary flush) -> zext back to i8
      if (auto *SI = dyn_cast<StoreInst>(UI)) {
        if (SI->getValueOperand() == PN) {
          IRBuilder<> B(SI);
          Value *ZextVal = B.CreateZExt(NewPN, B.getInt8Ty());
          SI->setOperand(0, ZextVal);
          continue;
        }
      }

      // Fallback: replace with zext i1 -> i8
      IRBuilder<> B(UI);
      Value *ZextVal = B.CreateZExt(NewPN, B.getInt8Ty());
      UI->replaceUsesOfWith(PN, ZextVal);
    }

    if (PN->use_empty()) {
      PN->eraseFromParent();
    }
    CanonicalizedCount++;
    Changed = true;
  }

  if (CanonicalizedCount) {
    errs() << "[brighten-state-ssa] flag-canonicalize: canonicalized "
           << CanonicalizedCount << " i8 flag PHIs to i1 PHIs\n";
  }

  return Changed;
}

} // namespace

// ===================================================================
// Flag consumer simplification
// ===================================================================

bool BrightenStateSSAPass::SimplifyFlagConsumers(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");
  if (!StateGV) return false;

  DiscoveredFlagLayout FlagLayout = DiscoverFlagSlots(M);
  if (!FlagLayout.Valid) return false;

  unsigned Simplified = 0;

  for (Function &F : M) {
    if (F.isDeclaration() || !IsLiftedFunction(F)) continue;

    // 1. Run flag SSA canonicalization (cross-block PHI conversion)
    Changed |= CanonicalizeFlagSSA(F, DL, StateGV, FlagLayout);

    // 2. Intra-block simplification for other flag consumers
    for (BasicBlock &BB : F) {
      SmallVector<Instruction *, 8> ToErase;

      for (auto It = BB.begin(); It != BB.end(); ++It) {
        auto *ICmp = dyn_cast<ICmpInst>(&*It);
        if (!ICmp) continue;

        bool IsEQ = ICmp->getPredicate() == ICmpInst::ICMP_EQ;
        bool IsNE = ICmp->getPredicate() == ICmpInst::ICMP_NE;
        if (!IsEQ && !IsNE) continue;

        auto *RHS = dyn_cast<ConstantInt>(ICmp->getOperand(1));
        if (!RHS || !RHS->isZero()) {
          RHS = dyn_cast<ConstantInt>(ICmp->getOperand(0));
          if (!RHS || !RHS->isZero()) continue;
        }

        Value *Op = (ICmp->getOperand(0) == RHS) ? ICmp->getOperand(1) : ICmp->getOperand(0);
        Value *X = PeelZExtI1(Op);
        if (!X) continue;

        IRBuilder<> B(ICmp);
        Value *Result = nullptr;
        if (IsNE) {
          Result = X;
        } else {
          Result = B.CreateNot(X);
        }

        ICmp->replaceAllUsesWith(Result);
        ToErase.push_back(ICmp);
        Simplified++;
        Changed = true;
      }

      for (Instruction *I : ToErase)
        I->eraseFromParent();
    }
  }

  if (Simplified) {
    errs() << "[brighten-state-ssa] flag-simplify: simplified " << Simplified
           << " flag icmp checks directly to i1\n";
  }

  return Changed;
}

} // namespace brighten_state_ssa
