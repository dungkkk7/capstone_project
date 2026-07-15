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
#include "llvm/Transforms/Utils/SSAUpdater.h"
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
// Each threaded edge therefore clones the latch/header side effects and uses
// SSAUpdater to synthesize merge PHIs in the destination region.  Non-constant
// transitions continue through the original latch and switch, preserving the
// dynamic fallback.  Every structural and type check is completed before the
// first CFG mutation.
bool BrightenDevirtPass::LowerRegionSSAStateSwitches(Module &M) {
  struct CandidateRewrite {
    BasicBlock *Pred = nullptr;
    BasicBlock *Dest = nullptr;
    BasicBlock *Thread = nullptr;
    SmallVector<Value *, 16> Outgoing;
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
    BasicBlock *Header = Selector ? Selector->getParent() : nullptr;
    auto *HeaderBr = Header ? dyn_cast<BranchInst>(Header->getTerminator())
                            : nullptr;
    if (!Selector || Header == Hub || !HeaderBr ||
        !HeaderBr->isUnconditional() || HeaderBr->getSuccessor(0) != Hub)
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

    SmallVector<CandidateRewrite, 32> Rewrites;
    for (BasicBlock *Pred : predecessors(Latch)) {
      auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
      auto *State = dyn_cast_or_null<ConstantInt>(
          LatchSelector->getIncomingValueForBlock(Pred));
      if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Latch ||
          !State)
        continue;
      ConstantInt *Condition = EvaluateSelector(State, SelectorSteps);
      auto Case = SW->findCaseValue(Condition);
      if (Case == SW->case_default())
        continue;
      BasicBlock *Dest = Case->getCaseSuccessor();
      if (Dest == Hub || Dest == Header || Dest == Latch)
        continue;
      // This first region-SSA subset handles a single case block.  A case
      // with internal successors needs region-wide renaming rather than a
      // destination PHI and is deliberately left on the fallback dispatcher.
      auto *DestBr = dyn_cast<BranchInst>(Dest->getTerminator());
      if (DestBr && (!DestBr->isUnconditional() ||
                     DestBr->getSuccessor(0) != Latch))
        continue;
      if (!DestBr && !isa<ReturnInst>(Dest->getTerminator()) &&
          !isa<ResumeInst>(Dest->getTerminator()))
        continue;

      CandidateRewrite R;
      R.Pred = Pred;
      R.Dest = Dest;
      for (unsigned I = 0; I < HeaderPhis.size(); ++I) {
        Value *Outgoing = LatchPhis[I]->getIncomingValueForBlock(Pred);
        // Cross-carried register swaps require simultaneous parallel-copy
        // lowering.  Refuse them transactionally; self-carried and newly
        // computed values are handled by SSAUpdater below.
        if (auto *Other = dyn_cast_or_null<PHINode>(Outgoing))
          if (Other->getParent() == Header && Other != HeaderPhis[I]) {
            Valid = false;
            break;
          }
        R.Outgoing.push_back(Outgoing);
      }
      if (!Valid)
        break;
      Rewrites.push_back(std::move(R));
    }
    if (!Valid || Rewrites.empty())
      continue;

    // Existing destination PHIs must have an unambiguous value on the old
    // hub edge so the new threaded edge can be populated before mutation.
    for (CandidateRewrite &R : Rewrites)
      for (PHINode &PN : R.Dest->phis())
        if (PN.getBasicBlockIndex(Hub) < 0)
          Valid = false;
    if (!Valid)
      continue;

    // Mutation begins only after the complete candidate has validated.
    for (CandidateRewrite &R : Rewrites) {
      R.Thread = BasicBlock::Create(M.getContext(), "region.thread", Hub->getParent(),
                                    R.Dest);
      ValueToValueMapTy VMap;
      for (PHINode &LP : Latch->phis())
        VMap[&LP] = LP.getIncomingValueForBlock(R.Pred);
      for (unsigned I = 0; I < HeaderPhis.size(); ++I)
        VMap[HeaderPhis[I]] = R.Outgoing[I];

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
      CloneBody(Latch);
      CloneBody(Header);
      CloneBody(Hub);

      for (PHINode &PN : R.Dest->phis()) {
        Value *Old = PN.getIncomingValueForBlock(Hub);
        Value *Mapped = MapValue(Old, VMap,
                                 RF_NoModuleLevelChanges |
                                     RF_IgnoreMissingLocals);
        PN.addIncoming(Mapped ? Mapped : Old, R.Thread);
      }
      BranchInst::Create(R.Dest, R.Thread);
      cast<BranchInst>(R.Pred->getTerminator())->setSuccessor(0, R.Thread);
    }

    for (PHINode &LP : Latch->phis())
      for (CandidateRewrite &R : Rewrites)
        LP.removeIncomingValue(R.Pred, false);

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
    errs() << "[devirt] threaded " << Rewrites.size()
           << " proven region-SSA transition(s) in @"
           << Hub->getParent()->getName() << "\n";
  }
  return Changed;
}

} // namespace brighten_devirt
