#include "BrightenDevirtPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/ValueMapper.h"

namespace brighten_devirt {

using namespace llvm;

// Remove only the degenerate form of a flattened dispatcher for which every
// incoming CFG edge already proves the next state.  This is deliberately not
// a heuristic based on block names, case-count, or "random-looking" constants:
// a normal program switch with even one dynamic incoming state is preserved.
//
// More general OLLVM dispatchers also carry application values through the
// hub.  Rewriting those requires SSA reconstruction in each case region.  The
// proof below refuses such hubs instead of silently changing loop semantics.
static BasicBlock *DestinationFor(SwitchInst *SW, ConstantInt *State) {
  auto Case = SW->findCaseValue(State);
  return Case == SW->case_default() ? SW->getDefaultDest()
                                    : Case->getCaseSuccessor();
}

struct SelectorStep {
  BinaryOperator *Op;
  ConstantInt *Constant;
  unsigned VariableOperand;
};

static PHINode *FindConstantTransitionState(
    Value *Selector, BasicBlock *Hub, SmallVectorImpl<SelectorStep> &Steps,
    SmallPtrSetImpl<Instruction *> &SelectorInstructions) {
  Value *Current = Selector;
  while (auto *BO = dyn_cast<BinaryOperator>(Current)) {
    if (BO->getParent() != Hub || !BO->hasOneUse())
      return nullptr;
    switch (BO->getOpcode()) {
    case Instruction::Add:
    case Instruction::Sub:
    case Instruction::Mul:
    case Instruction::Xor:
      break;
    default:
      return nullptr;
    }
    // Removing an overflowing nsw/nuw expression could mask poison/UB.
    if (auto *OBO = dyn_cast<OverflowingBinaryOperator>(BO))
      if (OBO->hasNoSignedWrap() || OBO->hasNoUnsignedWrap())
        return nullptr;

    auto *C0 = dyn_cast<ConstantInt>(BO->getOperand(0));
    auto *C1 = dyn_cast<ConstantInt>(BO->getOperand(1));
    if (!!C0 == !!C1)
      return nullptr;
    unsigned VariableOperand = C0 ? 1 : 0;
    ConstantInt *C = C0 ? C0 : C1;
    Steps.push_back({BO, C, VariableOperand});
    SelectorInstructions.insert(BO);
    Current = BO->getOperand(VariableOperand);
  }

  auto *State = dyn_cast<PHINode>(Current);
  if (!State || State->getParent() != Hub || !State->hasOneUse())
    return nullptr;
  SelectorInstructions.insert(State);
  return State;
}

static ConstantInt *EvaluateSelector(ConstantInt *State,
                                     ArrayRef<SelectorStep> Steps) {
  APInt Value = State->getValue();
  for (const SelectorStep &Step : reverse(Steps)) {
    const APInt &C = Step.Constant->getValue();
    APInt LHS = Step.VariableOperand == 0 ? Value : C;
    APInt RHS = Step.VariableOperand == 0 ? C : Value;
    switch (Step.Op->getOpcode()) {
    case Instruction::Add:
      Value = LHS + RHS;
      break;
    case Instruction::Sub:
      Value = LHS - RHS;
      break;
    case Instruction::Mul:
      Value = LHS * RHS;
      break;
    case Instruction::Xor:
      Value = LHS ^ RHS;
      break;
    default:
      llvm_unreachable("selector opcode was validated");
    }
  }
  return ConstantInt::get(State->getContext(), Value);
}

static BasicBlock *ResolveDispatcherDestination(
    SwitchInst *SW, ConstantInt *State, Value *SwitchCondition,
    BasicBlock *&DispatchPred) {
  SmallPtrSet<BasicBlock *, 8> Seen;
  SwitchInst *Current = SW;
  while (Seen.insert(Current->getParent()).second) {
    auto Case = Current->findCaseValue(State);
    if (Case != Current->case_default()) {
      DispatchPred = Current->getParent();
      return Case->getCaseSuccessor();
    }

    BasicBlock *Default = Current->getDefaultDest();
    auto *Nested = dyn_cast<SwitchInst>(Default->getTerminator());
    if (!Nested || Nested->getCondition() != SwitchCondition)
      return nullptr;
    // Threading directly to a nested case may bypass only a pure dispatch
    // block.  Any PHI, calculation, or side effect requires region cloning
    // and is left on the fallback path.
    for (Instruction &I : *Default)
      if (&I != Nested)
        return nullptr;
    Current = Nested;
  }
  return nullptr;
}

bool BrightenDevirtPass::LowerProvenConstantStateSwitches(Module &M) {
  SmallVector<SwitchInst *, 16> Worklist;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      if (auto *SW = dyn_cast<SwitchInst>(BB.getTerminator()))
        Worklist.push_back(SW);
  }

  bool Changed = false;
  for (SwitchInst *SW : Worklist) {
    BasicBlock *Hub = SW->getParent();
    SmallVector<SelectorStep, 4> SelectorSteps;
    SmallPtrSet<Instruction *, 8> SelectorInstructions;
    PHINode *State = FindConstantTransitionState(
        SW->getCondition(), Hub, SelectorSteps, SelectorInstructions);
    if (!State)
      continue;

    // The hub may contain dead PHIs, but no carried live value or side effect.
    // This makes bypassing it a local CFG equivalence, with no SSA repair.
    bool SafeHub = true;
    for (Instruction &I : *Hub) {
      if (&I == SW || SelectorInstructions.contains(&I))
        continue;
      auto *PN = dyn_cast<PHINode>(&I);
      if (!PN || !PN->use_empty()) {
        SafeHub = false;
        break;
      }
    }
    if (!SafeHub || State->getNumIncomingValues() == 0)
      continue;

    struct Rewrite {
      BranchInst *Branch;
      BasicBlock *Destination;
    };
    SmallVector<Rewrite, 16> Rewrites;
    bool Proven = true;
    for (unsigned I = 0, E = State->getNumIncomingValues(); I != E; ++I) {
      auto *C = dyn_cast<ConstantInt>(State->getIncomingValue(I));
      BasicBlock *Pred = State->getIncomingBlock(I);
      auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
      if (!C || !Br || !Br->isUnconditional() || Br->getSuccessor(0) != Hub) {
        Proven = false;
        break;
      }
      ConstantInt *Selector = EvaluateSelector(C, SelectorSteps);
      BasicBlock *Dest = DestinationFor(SW, Selector);
      if (Dest == Hub) {
        Proven = false;
        break;
      }
      Rewrites.push_back({Br, Dest});
    }
    if (!Proven)
      continue;

    // No successor PHI can mention Hub: a switch may have multiple edges to
    // one destination, for which LLVM requires one PHI incoming per block, and
    // deleting Hub would need edge-sensitive values.  Refuse before mutation.
    bool HasSuccessorPhi = false;
    for (BasicBlock *Succ : successors(Hub)) {
      if (isa<PHINode>(Succ->begin())) {
        HasSuccessorPhi = true;
        break;
      }
    }
    if (HasSuccessorPhi)
      continue;

    for (const Rewrite &R : Rewrites)
      R.Branch->setSuccessor(0, R.Destination);

    SW->eraseFromParent();
    for (const SelectorStep &Step : SelectorSteps)
      Step.Op->eraseFromParent();
    State->eraseFromParent();
    while (!Hub->empty())
      Hub->begin()->eraseFromParent();
    Hub->eraseFromParent();
    Changed = true;
    errs() << "[devirt] removed transition-proven constant state switch in @"
           << Rewrites.front().Branch->getFunction()->getName() << "\n";
  }
  return Changed;
}

// Thread the proven transitions of the late OLLVM region-SSA shape:
//
//   header(carried PHIs) -> switch hub -> case region -> latch(PHIs) -> header
//
// Unlike the early constant-state rule, this form carries application values.
// Each threaded edge therefore clones the latch/header side effects and
// materializes edge-specific carried PHIs in the destination case.
// Non-constant transitions continue through the original latch and switch,
// preserving the dynamic fallback.  Every structural and type check is
// completed before the first CFG mutation.
bool BrightenDevirtPass::LowerRegionSSAStateSwitches(Module &M) {
  struct CandidateRewrite {
    BasicBlock *Pred = nullptr;
    BasicBlock *Dest = nullptr;
    BasicBlock *DispatchPred = nullptr;
    BasicBlock *Thread = nullptr;
    Value *BranchCondition = nullptr;
    bool ConditionValue = false;
    bool FromLatch = true;
    SmallVector<Value *, 16> Outgoing;
    SmallVector<Value *, 16> LatchOutgoing;
  };

  bool Changed = false;
  SmallVector<SwitchInst *, 16> Switches;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (BasicBlock &BB : F)
        if (auto *SW = dyn_cast<SwitchInst>(BB.getTerminator()))
          Switches.push_back(SW);

  for (SwitchInst *SW : Switches) {
    if (!SW->getParent())
      continue;
    BasicBlock *Hub = SW->getParent();

    SmallVector<SelectorStep, 4> SelectorSteps;
    SmallPtrSet<Instruction *, 8> SelectorInstructions;
    Value *Current = SW->getCondition();
    bool Affine = true;
    while (auto *BO = dyn_cast<BinaryOperator>(Current)) {
      BasicBlock *Owner = BO->getParent();
      auto *OwnerBr = dyn_cast<BranchInst>(Owner->getTerminator());
      if (Owner != Hub &&
          (!OwnerBr || !OwnerBr->isUnconditional() ||
           OwnerBr->getSuccessor(0) != Hub)) {
        Affine = false;
        break;
      }
      switch (BO->getOpcode()) {
      case Instruction::Add:
      case Instruction::Sub:
      case Instruction::Mul:
      case Instruction::Xor:
        break;
      default:
        Affine = false;
        break;
      }
      if (!Affine)
        break;
      if (auto *OBO = dyn_cast<OverflowingBinaryOperator>(BO))
        if (OBO->hasNoSignedWrap() || OBO->hasNoUnsignedWrap()) {
          Affine = false;
          break;
        }
      auto *C0 = dyn_cast<ConstantInt>(BO->getOperand(0));
      auto *C1 = dyn_cast<ConstantInt>(BO->getOperand(1));
      if (!!C0 == !!C1) {
        Affine = false;
        break;
      }
      unsigned VariableOperand = C0 ? 1 : 0;
      SelectorSteps.push_back({BO, C0 ? C0 : C1, VariableOperand});
      Current = BO->getOperand(VariableOperand);
    }
    auto *Selector = Affine ? dyn_cast<PHINode>(Current) : nullptr;
    if (!Selector)
      continue;
    BasicBlock *Header = Selector->getParent();
    Function *F = Header->getParent();
    DominatorTree DT(*F);
    bool SelfHub = Header == Hub;
    auto *HeaderBr = dyn_cast<BranchInst>(Header->getTerminator());
    if (!SelfHub &&
        (!HeaderBr || !HeaderBr->isUnconditional() ||
         HeaderBr->getSuccessor(0) != Hub))
      continue;

    BasicBlock *Latch = nullptr;
    PHINode *LatchSelector = nullptr;
    for (unsigned I = 0; I < Selector->getNumIncomingValues(); ++I) {
      auto *PN = dyn_cast<PHINode>(Selector->getIncomingValue(I));
      BasicBlock *Incoming = Selector->getIncomingBlock(I);
      auto *Br = dyn_cast<BranchInst>(Incoming->getTerminator());
      if (!PN || PN->getParent() != Incoming || !Br ||
          !Br->isUnconditional() || Br->getSuccessor(0) != Header)
        continue;
      if (Latch) {
        Latch = nullptr;
        break;
      }
      Latch = Incoming;
      LatchSelector = PN;
    }
    if (!Latch || !LatchSelector || pred_empty(Latch))
      continue;

    SmallVector<PHINode *, 16> HeaderPhis;
    SmallVector<PHINode *, 16> LatchPhis;
    bool Valid = true;
    for (PHINode &HP : Header->phis()) {
      Value *Incoming = HP.getIncomingValueForBlock(Latch);
      auto *LP = dyn_cast_or_null<PHINode>(Incoming);
      if (!LP || LP->getParent() != Latch || LP->getType() != HP.getType()) {
        Valid = false;
        break;
      }
      HeaderPhis.push_back(&HP);
      LatchPhis.push_back(LP);
    }
    if (!Valid || HeaderPhis.empty())
      continue;

    SmallVector<PHINode *, 16> AllLatchPhis;
    for (PHINode &LP : Latch->phis())
      AllLatchPhis.push_back(&LP);

    auto PayloadIsCloneable = [](BasicBlock *BB) {
      for (Instruction &I : *BB) {
        if (isa<PHINode>(I) || I.isTerminator())
          continue;
        if (I.isEHPad())
          return false;
        if (auto *CB = dyn_cast<CallBase>(&I); CB && CB->cannotDuplicate())
          return false;
      }
      return true;
    };
    if (!PayloadIsCloneable(Latch) ||
        (!SelfHub && !PayloadIsCloneable(Header)) ||
        !PayloadIsCloneable(Hub))
      continue;

    SmallVector<CandidateRewrite, 32> Rewrites;
    // A new region.thread edge bypasses Header and Hub on later iterations.
    // A value carried from Header can dominate the old latch->header edge yet
    // fail to dominate this new edge.  Until we model dominance in the
    // rewritten CFG, accept only edge-local instruction values (or values
    // without an instruction definition).
    auto IsSafeThreadInput = [&](Value *V, BasicBlock *Pred) {
      auto *I = dyn_cast<Instruction>(V);
      if (!I)
        return true;
      if (I->getParent() == Header || I->getParent() != Pred)
        return false;
      return DT.dominates(I, Pred->getTerminator());
    };
    auto AddArm = [&](BasicBlock *Pred, ConstantInt *State,
                      Value *BranchCondition, bool ConditionValue,
                      bool FromLatch) {
        ConstantInt *Condition = EvaluateSelector(State, SelectorSteps);
        BasicBlock *DispatchPred = nullptr;
        BasicBlock *Dest = ResolveDispatcherDestination(
            SW, Condition, SW->getCondition(), DispatchPred);
        if (!Dest || !DispatchPred ||
            Dest == Hub || Dest == Header || Dest == Latch)
          return false;
        // This region-SSA subset handles a single case block.  A case with
        // internal successors needs region-wide renaming and stays on the
        // fallback dispatcher.
        auto *DestBr = dyn_cast<BranchInst>(Dest->getTerminator());
        if (DestBr && (!DestBr->isUnconditional() ||
                       DestBr->getSuccessor(0) != Latch))
          return false;
        if (!DestBr && !isa<ReturnInst>(Dest->getTerminator()) &&
            !isa<ResumeInst>(Dest->getTerminator()))
          return false;

        CandidateRewrite R;
        R.Pred = Pred;
        R.Dest = Dest;
        R.DispatchPred = DispatchPred;
        R.BranchCondition = BranchCondition;
        R.ConditionValue = ConditionValue;
        R.FromLatch = FromLatch;
        if (FromLatch) {
          for (PHINode *LP : AllLatchPhis) {
            Value *Outgoing = LP->getIncomingValueForBlock(Pred);
            if (!Outgoing || !IsSafeThreadInput(Outgoing, Pred)) {
              // An unsafe carried value would need a post-rewrite SSA proof.
              // Reject the entire candidate before any CFG mutation.
              Valid = false;
              return false;
            }
            R.LatchOutgoing.push_back(Outgoing);
          }
        }
        for (unsigned I = 0; I < HeaderPhis.size(); ++I) {
          Value *Outgoing = nullptr;
          if (HeaderPhis[I] == Selector)
            Outgoing = State;
          else if (FromLatch)
            Outgoing = LatchPhis[I]->getIncomingValueForBlock(Pred);
          else
            Outgoing = HeaderPhis[I]->getIncomingValueForBlock(Pred);
          if (!Outgoing || !IsSafeThreadInput(Outgoing, Pred)) {
            Valid = false;
            return false;
          }
          // Cross-carried register swaps require simultaneous parallel-copy
          // lowering. Refuse them transactionally. Header/self-carried values
          // are rejected above because their old dominance does not survive
          // the newly-created direct edge.
          if (auto *Other = dyn_cast_or_null<PHINode>(Outgoing))
            if (Other->getParent() == Header && Other != HeaderPhis[I]) {
              Valid = false;
              return false;
            }
          R.Outgoing.push_back(Outgoing);
        }
        Rewrites.push_back(std::move(R));
        return true;
      };

    for (BasicBlock *Pred : predecessors(Latch)) {
      auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
      Value *NextState = LatchSelector->getIncomingValueForBlock(Pred);
      if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Latch ||
          !NextState)
        continue;

      size_t RewriteBegin = Rewrites.size();
      bool Added = false;
      if (auto *State = dyn_cast<ConstantInt>(NextState)) {
        Added = AddArm(Pred, State, nullptr, false, true);
      } else if (auto *Select = dyn_cast<SelectInst>(NextState);
                 SelfHub && HeaderPhis.size() == 1 &&
                 Select && Select->getParent() == Pred) {
        // Splitting a select transition with additional carried values needs
        // a proof that every value is identical on both arms.  Keep that form
        // on the fallback path until the parallel-copy proof is explicit.
        auto *TrueState = dyn_cast<ConstantInt>(Select->getTrueValue());
        auto *FalseState = dyn_cast<ConstantInt>(Select->getFalseValue());
        if (TrueState && FalseState) {
          Added = AddArm(Pred, TrueState, Select->getCondition(), true, true) &&
                  AddArm(Pred, FalseState, Select->getCondition(), false, true);
        }
      }
      if (!Added)
        Rewrites.resize(RewriteBegin);
      if (!Valid)
        break;
    }
    if (!Valid)
      continue;

    // A constant entry state is just as provable as a constant latch
    // transition.  Thread it through cloned header/hub side effects so that,
    // once every reachable transition is direct, the residual default loop
    // becomes unreachable and normal CFG cleanup can erase the dispatcher.
    if (SelfHub)
      for (unsigned I = 0; I < Selector->getNumIncomingValues(); ++I) {
        BasicBlock *Pred = Selector->getIncomingBlock(I);
        if (Pred == Latch)
          continue;
        auto *State = dyn_cast<ConstantInt>(Selector->getIncomingValue(I));
        auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
        if (!State || !Br || !Br->isUnconditional() ||
            Br->getSuccessor(0) != Header)
          continue;
        size_t RewriteBegin = Rewrites.size();
        if (!AddArm(Pred, State, nullptr, false, false))
          Rewrites.resize(RewriteBegin);
        if (!Valid)
          break;
      }
    if (!Valid || Rewrites.empty())
      continue;

    // Existing destination PHIs must have an unambiguous value on the old
    // dispatcher edge so the new threaded edge can be populated before
    // mutation.  A nested default switch is itself the predecessor.
    for (CandidateRewrite &R : Rewrites)
      for (PHINode &PN : R.Dest->phis())
        if (PN.getBasicBlockIndex(R.DispatchPred) < 0)
          Valid = false;
    if (!Valid)
      continue;

    // Mutation begins only after the complete candidate has validated.
    for (CandidateRewrite &R : Rewrites) {
      R.Thread = BasicBlock::Create(M.getContext(), "region.thread", Hub->getParent(),
                                    R.Dest);
      ValueToValueMapTy VMap;
      if (R.FromLatch)
        for (unsigned I = 0; I < AllLatchPhis.size(); ++I)
          VMap[AllLatchPhis[I]] = R.LatchOutgoing[I];
      for (unsigned I = 0; I < HeaderPhis.size(); ++I) {
        VMap[HeaderPhis[I]] = R.Outgoing[I];
      }

      auto CloneBody = [&](BasicBlock *BB) {
        for (Instruction &I : *BB) {
          if (isa<PHINode>(I) || I.isTerminator())
            continue;
          Instruction *Clone = I.clone();
          RemapInstruction(Clone, VMap,
                           RF_NoModuleLevelChanges | RF_IgnoreMissingLocals);
          Clone->insertInto(R.Thread, R.Thread->end());
          VMap[&I] = Clone;
        }
      };
      if (R.FromLatch)
        CloneBody(Latch);
      if (!SelfHub)
        CloneBody(Header);
      CloneBody(Hub);

      for (PHINode &PN : R.Dest->phis()) {
        Value *Old = PN.getIncomingValueForBlock(R.DispatchPred);
        Value *Mapped = MapValue(Old, VMap,
                                 RF_NoModuleLevelChanges |
                                     RF_IgnoreMissingLocals);
        PN.addIncoming(Mapped ? Mapped : Old, R.Thread);
      }
      BranchInst::Create(R.Dest, R.Thread);
    }

    SmallPtrSet<BasicBlock *, 32> RewiredPreds;
    for (CandidateRewrite &R : Rewrites) {
      if (!RewiredPreds.insert(R.Pred).second)
        continue;
      auto *OldBr = cast<BranchInst>(R.Pred->getTerminator());
      if (!R.BranchCondition) {
        OldBr->setSuccessor(0, R.Thread);
        continue;
      }
      CandidateRewrite *TrueArm = nullptr;
      CandidateRewrite *FalseArm = nullptr;
      for (CandidateRewrite &Arm : Rewrites) {
        if (Arm.Pred != R.Pred ||
            Arm.BranchCondition != R.BranchCondition)
          continue;
        (Arm.ConditionValue ? TrueArm : FalseArm) = &Arm;
      }
      assert(TrueArm && FalseArm &&
             "validated select transition lost one branch arm");
      BranchInst::Create(TrueArm->Thread, FalseArm->Thread,
                         R.BranchCondition, OldBr);
      OldBr->eraseFromParent();
    }

    SmallPtrSet<BasicBlock *, 32> RemovedLatchPreds;
    for (CandidateRewrite &R : Rewrites)
      if (R.FromLatch)
        RemovedLatchPreds.insert(R.Pred);
    for (PHINode &LP : Latch->phis())
      for (BasicBlock *Pred : RemovedLatchPreds)
        LP.removeIncomingValue(Pred, false);
    SmallPtrSet<BasicBlock *, 8> RemovedHeaderPreds;
    for (CandidateRewrite &R : Rewrites)
      if (!R.FromLatch)
        RemovedHeaderPreds.insert(R.Pred);
    for (PHINode *HP : HeaderPhis)
      for (BasicBlock *Pred : RemovedHeaderPreds)
        HP->removeIncomingValue(Pred, false);

    // Materialize the carried value at each directly-entered case.  Header
    // still dominates the case syntactically through the preserved fallback,
    // so dominance repair alone is insufficient: the new edge represents the
    // next loop iteration and must select the latch outgoing value.
    for (unsigned I = 0; I < HeaderPhis.size(); ++I) {
      PHINode *HP = HeaderPhis[I];
      SmallPtrSet<BasicBlock *, 16> SeenDestinations;
      for (CandidateRewrite &R : Rewrites) {
        BasicBlock *Dest = R.Dest;
        if (!SeenDestinations.insert(Dest).second)
          continue;
        PHINode *Carried = PHINode::Create(
            HP->getType(), pred_size(Dest), HP->getName() + ".region",
            Dest->getFirstInsertionPt());
        for (BasicBlock *Pred : predecessors(Dest)) {
          Value *Incoming = HP;
          for (CandidateRewrite &Edge : Rewrites)
            if (Edge.Thread == Pred && Edge.Dest == Dest) {
              Incoming = Edge.Outgoing[I];
              break;
            }
          Carried->addIncoming(Incoming, Pred);
        }

        SmallVector<Use *, 16> LocalUses;
        for (Use &U : HP->uses()) {
          auto *UserI = dyn_cast<Instruction>(U.getUser());
          if (UserI && UserI->getParent() == Dest && UserI != Carried &&
              !isa<PHINode>(UserI))
            LocalUses.push_back(&U);
        }
        for (Use *U : LocalUses)
          U->set(Carried);
      }
    }

    Changed = true;
    errs() << "[devirt] threaded " << RewiredPreds.size()
           << " proven region-SSA transition(s) in @"
           << Hub->getParent()->getName() << "\n";
  }
  return Changed;
}

} // namespace brighten_devirt
