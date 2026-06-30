// Fix x87 pseudo double loads.
// - Theo doi ST0..ST7 va raw bits
// - Gop/restore double values cho bieu thuc FP
#include "BrightenRepairPass.h"

#include <array>
#include <vector>

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

namespace brighten_repair {

using namespace llvm;

namespace {

using STState = std::array<Value *, 8>;

static std::optional<unsigned> GetSTIndex(Value *Ptr) {
  auto *GA = dyn_cast<GlobalAlias>(Ptr->stripPointerCasts());
  if (!GA || !GA->getName().starts_with("ST")) {
    return std::nullopt;
  }

  StringRef Name = GA->getName();
  if (Name.size() < 4 || Name[2] < '0' || Name[2] > '7' || Name[3] != '_') {
    return std::nullopt;
  }
  return static_cast<unsigned>(Name[2] - '0');
}

static bool IsIgnorableCall(CallBase *CB) {
  if (isa<IntrinsicInst>(CB)) {
    return true;
  }
  if (CB->isInlineAsm()) {
    return true;
  }
  Function *Callee = CB->getCalledFunction();
  if (Callee && (Callee->getName() == "fegetround" ||
                 Callee->getName() == "fesetround")) {
    return true;
  }
  return Callee && Callee->onlyReadsMemory();
}

static Value *GetDoubleFromRawBits(Value *V,
                                   const DenseMap<Value *, Value *> &RawBits) {
  if (auto It = RawBits.find(V); It != RawBits.end()) {
    return It->second;
  }

  auto *Op = dyn_cast<Operator>(V);
  if (!Op || Op->getOpcode() != Instruction::BitCast || Op->getNumOperands() != 1) {
    return nullptr;
  }

  Value *Src = Op->getOperand(0);
  return Src->getType()->isDoubleTy() ? Src : nullptr;
}

static Value *ResolveDouble(Value *V, const DenseMap<Value *, Value *> &Aliases) {
  SmallPtrSet<Value *, 4> Seen;
  while (V) {
    auto It = Aliases.find(V);
    if (It == Aliases.end() || !Seen.insert(V).second) {
      return V;
    }
    V = It->second;
  }
  return V;
}

static bool IsFPTopTwoResult(Value *V, const STState &CurrentDouble,
                             const DenseMap<Value *, Value *> &Aliases) {
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || !BO->getType()->isDoubleTy()) {
    return false;
  }

  unsigned Opcode = BO->getOpcode();
  if (Opcode != Instruction::FAdd && Opcode != Instruction::FSub &&
      Opcode != Instruction::FMul && Opcode != Instruction::FDiv) {
    return false;
  }

  Value *Op0 = ResolveDouble(BO->getOperand(0), Aliases);
  Value *Op1 = ResolveDouble(BO->getOperand(1), Aliases);
  return CurrentDouble[0] && CurrentDouble[1] &&
         ((Op0 == CurrentDouble[0] && Op1 == CurrentDouble[1]) ||
          (Op0 == CurrentDouble[1] && Op1 == CurrentDouble[0]));
}

static void PopIntoST0(STState &CurrentDouble, Value *NewTop) {
  CurrentDouble[0] = NewTop;
  for (unsigned I = 1; I + 1 < CurrentDouble.size(); ++I) {
    CurrentDouble[I] = CurrentDouble[I + 1];
  }
  CurrentDouble.back() = nullptr;
}

static void PushRawST0(STState &RawBits) {
  for (int I = 7; I > 0; --I) {
    RawBits[I] = RawBits[I - 1];
  }
  RawBits[0] = nullptr;
}

static void PopRawIntoST0(STState &RawBits) {
  RawBits[0] = nullptr;
  for (unsigned I = 1; I + 1 < RawBits.size(); ++I) {
    RawBits[I] = RawBits[I + 1];
  }
  RawBits.back() = nullptr;
}

static STState MergePredecessorState(BasicBlock &BB,
                                     const DenseMap<BasicBlock *, STState> &Out) {
  STState In{};
  bool First = true;
  for (BasicBlock *Pred : predecessors(&BB)) {
    auto It = Out.find(Pred);
    if (It == Out.end()) {
      return STState{};
    }
    if (First) {
      In = It->second;
      First = false;
      continue;
    }
    for (unsigned I = 0; I < In.size(); ++I) {
      if (In[I] != It->second[I]) {
        In[I] = nullptr;
      }
    }
  }
  return First ? STState{} : In;
}

static Value *GetOrCreateMergedDouble(BasicBlock &BB, unsigned ST,
                                      Type *DoubleTy,
                                      const DenseMap<BasicBlock *, STState> *Out,
                                      DenseMap<BasicBlock *, STState> *MergeCache) {
  if (!Out || !MergeCache) {
    return nullptr;
  }

  STState &Cached = (*MergeCache)[&BB];
  if (Cached[ST]) {
    return Cached[ST];
  }

  SmallVector<std::pair<BasicBlock *, Value *>, 4> Incoming;
  Value *FirstValue = nullptr;
  bool AllSame = true;
  for (BasicBlock *Pred : predecessors(&BB)) {
    if (Pred == &BB) {
      return nullptr;
    }

    auto It = Out->find(Pred);
    if (It == Out->end()) {
      return nullptr;
    }

    Value *PredValue = It->second[ST];
    if (!PredValue || PredValue->getType() != DoubleTy) {
      return nullptr;
    }

    if (!FirstValue) {
      FirstValue = PredValue;
    } else if (PredValue != FirstValue) {
      AllSame = false;
    }
    Incoming.push_back({Pred, PredValue});
  }

  if (Incoming.empty()) {
    return nullptr;
  }

  if (AllSame) {
    Cached[ST] = FirstValue;
    return FirstValue;
  }

  auto InsertPt = BB.getFirstInsertionPt();
  if (InsertPt == BB.end()) {
    return nullptr;
  }

  PHINode *Phi = PHINode::Create(DoubleTy, Incoming.size(),
                                 Twine("refine.x87.st") + Twine(ST), &*InsertPt);
  for (auto [Pred, PredValue] : Incoming) {
    Phi->addIncoming(PredValue, Pred);
  }
  Cached[ST] = Phi;
  return Phi;
}

static void TransferBlock(BasicBlock &BB, STState &CurrentDouble, Type *DoubleTy,
                          Type *X87Ty, bool Rewrite,
                          std::vector<Instruction *> &Dead, bool &Changed,
                          const DenseMap<BasicBlock *, STState> *OutStates = nullptr,
                          DenseMap<BasicBlock *, STState> *MergeCache = nullptr) {
  DenseMap<Value *, Value *> RawBits;
  DenseMap<Value *, unsigned> RawSTIndex;
  DenseMap<Value *, Value *> DoubleAliases;
  STState RawSlotBits{};
  bool SawExplicitPushShift = false;
  bool PreserveLogicalRawSlots = false;

  for (Instruction &I : BB) {
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      auto ST = GetSTIndex(SI->getPointerOperand());
      if (!ST) {
        continue;
      }
      if (SI->getValueOperand()->getType() == DoubleTy) {
        Value *Stored = ResolveDouble(SI->getValueOperand(), DoubleAliases);
        if (*ST == 1 && IsFPTopTwoResult(SI->getValueOperand(), CurrentDouble,
                                         DoubleAliases)) {
          // x87 opcodes like FADDP/FMULP store into ST1 and then pop ST0, so
          // the computed value becomes the new logical ST0.
          PopIntoST0(CurrentDouble, Stored);
          PopRawIntoST0(RawSlotBits);
          PreserveLogicalRawSlots = true;
        } else if (*ST == 0 && CurrentDouble[0] && !SawExplicitPushShift) {
          for (int I = 7; I > 0; --I) {
            CurrentDouble[I] = CurrentDouble[I - 1];
          }
          CurrentDouble[0] = Stored;
          PushRawST0(RawSlotBits);
        } else {
          CurrentDouble[*ST] = Stored;
          RawSlotBits[*ST] = nullptr;
        }
        SawExplicitPushShift = false;
      } else if (SI->getValueOperand()->getType()->isIntegerTy(64)) {
        auto RawSrc = RawSTIndex.find(SI->getValueOperand());
        if (PreserveLogicalRawSlots && RawSrc != RawSTIndex.end()) {
          continue;
        }
        if (RawSrc != RawSTIndex.end() && *ST > RawSrc->second) {
          SawExplicitPushShift = true;
        }
        RawSlotBits[*ST] = SI->getValueOperand();
        PreserveLogicalRawSlots = false;
        CurrentDouble[*ST] = GetDoubleFromRawBits(SI->getValueOperand(), RawBits);
      } else {
        CurrentDouble[*ST] = nullptr;
        RawSlotBits[*ST] = nullptr;
        PreserveLogicalRawSlots = false;
      }
      continue;
    }

    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      auto ST = GetSTIndex(LI->getPointerOperand());
      if (ST && LI->getType()->isIntegerTy(64)) {
        if (CurrentDouble[*ST]) {
          RawBits[LI] = CurrentDouble[*ST];
        }
        RawSTIndex[LI] = *ST;
        if (!PreserveLogicalRawSlots) {
          RawSlotBits[*ST] = LI;
        }
        continue;
      }
      if (ST && LI->getType() == X87Ty && !CurrentDouble[*ST] &&
          !RawSlotBits[*ST] && Rewrite) {
        CurrentDouble[*ST] =
            GetOrCreateMergedDouble(BB, *ST, DoubleTy, OutStates, MergeCache);
      }

      if (!ST || LI->getType() != X87Ty ||
          (!CurrentDouble[*ST] && !RawSlotBits[*ST])) {
        continue;
      }

      SmallVector<FPTruncInst *, 4> Truncs;
      for (User *U : LI->users()) {
        auto *FPT = dyn_cast<FPTruncInst>(U);
        if (FPT && FPT->getType() == DoubleTy) {
          Truncs.push_back(FPT);
        }
      }
      for (FPTruncInst *FPT : Truncs) {
        if (CurrentDouble[*ST]) {
          DoubleAliases[FPT] = CurrentDouble[*ST];
        }
      }
      if (!Rewrite) {
        continue;
      }
      if (!Truncs.empty()) {
        Dead.push_back(LI);
      }
      for (FPTruncInst *FPT : Truncs) {
        Value *Replacement = CurrentDouble[*ST];
        if (!Replacement) {
          IRBuilder<> B(FPT);
          Replacement = B.CreateBitCast(RawSlotBits[*ST], DoubleTy);
        }
        FPT->replaceAllUsesWith(Replacement);
        Dead.push_back(FPT);
        Changed = true;
      }
      PreserveLogicalRawSlots = false;
      continue;
    }

    auto *CB = dyn_cast<CallBase>(&I);
    if (CB && !IsIgnorableCall(CB)) {
      CurrentDouble.fill(nullptr);
      RawBits.clear();
      RawSTIndex.clear();
      DoubleAliases.clear();
      RawSlotBits = STState{};
      SawExplicitPushShift = false;
      PreserveLogicalRawSlots = false;
    }
  }
}

}  // namespace

bool BrightenRepairPass::RepairMcSemaX87PseudoDoubleLoads(Module &M) {
  Type *DoubleTy = Type::getDoubleTy(M.getContext());
  Type *X87Ty = Type::getX86_FP80Ty(M.getContext());

  bool Changed = false;
  std::vector<Instruction *> Dead;

  for (Function &F : M) {
    if (F.empty()) {
      continue;
    }

    DenseMap<BasicBlock *, STState> In;
    DenseMap<BasicBlock *, STState> Out;
    for (BasicBlock &BB : F) {
      In[&BB] = STState{};
      Out[&BB] = STState{};
    }

    bool LocalChanged = true;
    while (LocalChanged) {
      LocalChanged = false;
      for (BasicBlock &BB : F) {
        STState NewIn = MergePredecessorState(BB, Out);
        if (NewIn != In[&BB]) {
          In[&BB] = NewIn;
          LocalChanged = true;
        }

        STState NewOut = In[&BB];
        bool IgnoredChanged = false;
        TransferBlock(BB, NewOut, DoubleTy, X87Ty, false, Dead, IgnoredChanged);
        if (NewOut != Out[&BB]) {
          Out[&BB] = NewOut;
          LocalChanged = true;
        }
      }
    }

    DenseMap<BasicBlock *, STState> MergeCache;
    for (BasicBlock &BB : F) {
      STState CurrentDouble = In[&BB];
      TransferBlock(BB, CurrentDouble, DoubleTy, X87Ty, true, Dead, Changed,
                    &Out, &MergeCache);
    }

    // McSema emits pseudo-FPU state in a mostly linearized block order. Some
    // loops/joins still defeat conservative predecessor intersection even when
    // the generated block order preserves the concrete ST value. Use a narrow
    // linear fallback only for ST pseudo-register rewrites.
    STState LinearState{};
    for (BasicBlock &BB : F) {
      TransferBlock(BB, LinearState, DoubleTy, X87Ty, true, Dead, Changed);
    }
  }

  SmallPtrSet<Instruction *, 32> SeenDead;
  std::vector<Instruction *> UniqueDead;
  for (Instruction *I : Dead) {
    if (SeenDead.insert(I).second) {
      UniqueDead.push_back(I);
    }
  }

  for (Instruction *I : llvm::reverse(UniqueDead)) {
    if (I->use_empty()) {
      I->eraseFromParent();
    }
  }

  return Changed;
}

}  // namespace brighten_repair
