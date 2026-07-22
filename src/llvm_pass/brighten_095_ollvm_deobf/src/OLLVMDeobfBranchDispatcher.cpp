#include "OLLVMDeobfInternal.h"

#include "llvm/Transforms/Utils/Cloning.h"

namespace brighten_ollvm_deobf {
namespace {

class BranchBodyTransaction {
  Function &Target;
  Function *Backup = nullptr;
  ValueToValueMapTy BackupMap;
  GlobalValue::LinkageTypes OriginalLinkage;

public:
  explicit BranchBodyTransaction(Function &F)
      : Target(F), OriginalLinkage(F.getLinkage()) {
    Backup = CloneFunction(&F, BackupMap);
    Backup->setName(F.getName() + ".branch.dispatch.rollback");
  }
  ~BranchBodyTransaction() {
    if (Backup)
      Backup->eraseFromParent();
  }
  void commit() {
    Backup->eraseFromParent();
    Backup = nullptr;
  }
  void rollback() {
    auto TargetArg = Target.arg_begin();
    for (Argument &BackupArg : Backup->args()) {
      BackupArg.replaceAllUsesWith(&*TargetArg);
      ++TargetArg;
    }
    Backup->replaceAllUsesWith(&Target);
    Target.deleteBody();
    Target.setLinkage(OriginalLinkage);
    Target.splice(Target.end(), Backup);
    Backup->eraseFromParent();
    Backup = nullptr;
  }
};

struct BranchDispatcherShape {
  PHINode *State = nullptr;
  PHINode *OuterState = nullptr;
  PHINode *Transition = nullptr;
  ConstantInt *Seed = nullptr;
  SmallVector<ConstantInt *, 2> LocalSeeds;
};

static std::optional<BranchDispatcherShape> matchBranchDispatcher(PHINode &PN) {
  if (!PN.getType()->isIntegerTy() || PN.getNumIncomingValues() < 2 ||
      PN.getNumIncomingValues() > 4)
    return std::nullopt;
  auto *HeaderBranch = dyn_cast<BranchInst>(PN.getParent()->getTerminator());
  if (!HeaderBranch || !HeaderBranch->isConditional())
    return std::nullopt;

  PHINode *Outer = nullptr;
  SmallVector<ConstantInt *, 2> LocalSeeds;
  for (Value *Incoming : PN.incoming_values()) {
    if (auto *Other = dyn_cast<PHINode>(Incoming)) {
      if (Outer && Outer != Other)
        return std::nullopt;
      Outer = Other;
    } else if (auto *C = dyn_cast<ConstantInt>(Incoming)) {
      LocalSeeds.push_back(C);
    } else {
      return std::nullopt;
    }
  }
  if (!Outer || LocalSeeds.empty() || Outer->getType() != PN.getType() ||
      Outer->getNumIncomingValues() != 2)
    return std::nullopt;

  ConstantInt *Seed = nullptr;
  PHINode *Transition = nullptr;
  for (Value *Incoming : Outer->incoming_values()) {
    if (auto *C = dyn_cast<ConstantInt>(Incoming))
      Seed = C;
    else if (auto *P = dyn_cast<PHINode>(Incoming))
      Transition = P;
  }
  if (!Seed || !Transition || Transition->getType() != PN.getType() ||
      Transition->getNumIncomingValues() < 3 ||
      Transition->getNumIncomingValues() > 256)
    return std::nullopt;
  auto *Backedge = dyn_cast<BranchInst>(Transition->getParent()->getTerminator());
  if (!Backedge || !Backedge->isUnconditional() ||
      Backedge->getSuccessor(0) != Outer->getParent())
    return std::nullopt;

  return BranchDispatcherShape{&PN, Outer, Transition, Seed,
                               std::move(LocalSeeds)};
}

static BasicBlock *evaluateDecisionTree(PHINode &State, const APInt &Raw) {
  BasicBlock *Current = State.getParent();
  SmallPtrSet<BasicBlock *, 32> Seen;
  for (unsigned Steps = 0; Steps != 256; ++Steps) {
    if (!Seen.insert(Current).second)
      return nullptr;

    bool HasEffect = false;
    for (Instruction &I : *Current) {
      if (isa<PHINode>(I) || I.isTerminator() || isa<DbgInfoIntrinsic>(I))
        continue;
      if (I.mayHaveSideEffects()) {
        HasEffect = true;
        break;
      }
    }
    if (HasEffect)
      return Current;

    Instruction *Term = Current->getTerminator();
    if (auto *BI = dyn_cast<BranchInst>(Term)) {
      if (BI->isUnconditional()) {
        Current = BI->getSuccessor(0);
        continue;
      }
      auto Taken = evalStatePredicate(BI->getCondition(), &State, Raw);
      if (!Taken)
        return Current == State.getParent() ? nullptr : Current;
      Current = BI->getSuccessor(*Taken ? 0 : 1);
      continue;
    }
    if (auto *SI = dyn_cast<SwitchInst>(Term)) {
      auto Encoded = evalStateExpr(SI->getCondition(), &State, Raw);
      if (!Encoded)
        return Current == State.getParent() ? nullptr : Current;
      BasicBlock *Next = SI->getDefaultDest();
      for (const auto &Case : SI->cases())
        if (Case.getCaseValue()->getValue() == *Encoded) {
          Next = Case.getCaseSuccessor();
          break;
        }
      Current = Next;
      continue;
    }
    return Current == State.getParent() ? nullptr : Current;
  }
  return nullptr;
}

static bool enumerateStateValues(Value *V, PHINode &State, const APInt &Raw,
                                 SmallVectorImpl<APInt> &Out,
                                 unsigned Depth = 0) {
  if (!V || Depth > 32 || Out.size() > 256)
    return false;
  if (auto Exact = evalStateExpr(V, &State, Raw))
    return appendUniqueTransitionValue(Out, *Exact, 256);
  if (auto *Select = dyn_cast<SelectInst>(V))
    return enumerateStateValues(Select->getTrueValue(), State, Raw, Out,
                                Depth + 1) &&
           enumerateStateValues(Select->getFalseValue(), State, Raw, Out,
                                Depth + 1);
  if (auto *PN = dyn_cast<PHINode>(V)) {
    for (Value *Incoming : PN->incoming_values())
      if (!enumerateStateValues(Incoming, State, Raw, Out, Depth + 1))
        return false;
    return true;
  }
  return false;
}

static bool collectLeafTransitions(BasicBlock &Leaf,
                                   const BranchDispatcherShape &Shape,
                                   Loop &StateLoop,
                                   SmallVectorImpl<Value *> &Expressions) {
  SmallVector<BasicBlock *, 64> Work{&Leaf};
  SmallPtrSet<BasicBlock *, 32> Seen;
  while (!Work.empty()) {
    BasicBlock *BB = Work.pop_back_val();
    if (!Seen.insert(BB).second)
      continue;
    if (!StateLoop.contains(BB))
      continue;
    if (Seen.size() > 512 || BB == Shape.State->getParent() ||
        BB == Shape.OuterState->getParent())
      return false;
    for (BasicBlock *Succ : successors(BB)) {
      if (Succ == Shape.Transition->getParent()) {
        int Index = Shape.Transition->getBasicBlockIndex(BB);
        if (Index < 0)
          return false;
        Expressions.push_back(Shape.Transition->getIncomingValue(Index));
        continue;
      }
      Work.push_back(Succ);
    }
  }
  // A dispatcher case may leave the flattened loop (return, resume an outer
  // dispatcher, or enter a noreturn path) instead of producing another state.
  // The traversal above already rejects any path that re-enters this state
  // machine without crossing its transition PHI, so an empty set is a proved
  // terminal case rather than a missing transition.
  return true;
}

static bool appendState(SmallVectorImpl<APInt> &States, const APInt &State) {
  return appendUniqueTransitionValue(States, State, 256);
}

static bool recoverOneFiniteBranchDispatcher(
    Function &F, BranchDispatcherShape Shape, Metrics &M,
    SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<APInt, 64> States;
  if (!appendState(States, Shape.Seed->getValue()))
    return false;
  for (ConstantInt *Seed : Shape.LocalSeeds)
    if (!appendState(States, Seed->getValue()))
      return false;

  DenseMap<APInt, BasicBlock *> Targets;
  DominatorTree DT(F);
  LoopInfo LI(DT);
  Loop *StateLoop = LI.getLoopFor(Shape.State->getParent());
  while (StateLoop &&
         !StateLoop->contains(Shape.Transition->getParent()))
    StateLoop = StateLoop->getParentLoop();
  if (!StateLoop)
    return false;
  for (unsigned Cursor = 0; Cursor < States.size(); ++Cursor) {
    APInt Raw = States[Cursor];
    BasicBlock *Leaf = evaluateDecisionTree(*Shape.State, Raw);
    if (!Leaf || !Leaf->phis().empty())
      return false;
    Targets.try_emplace(Raw, Leaf);

    SmallVector<Value *, 16> Expressions;
    if (!collectLeafTransitions(*Leaf, Shape, *StateLoop, Expressions))
      return false;
    for (Value *Expression : Expressions) {
      SmallVector<APInt, 4> NextValues;
      if (!enumerateStateValues(Expression, *Shape.State, Raw, NextValues) ||
          NextValues.empty())
        return false;
      for (const APInt &Next : NextValues)
        if (!appendState(States, Next))
          return false;
    }
  }
  if (States.size() < 4 || Targets.size() != States.size())
    return false;

  std::string OldText = valueText(F);
  BranchBodyTransaction Transaction(F);
  BasicBlock *Header = Shape.State->getParent();
  Instruction *OldTerm = Header->getTerminator();
  BasicBlock *Fallback = Header->splitBasicBlock(
      OldTerm->getIterator(), Header->getName() + ".decision.fallback");
  Header->getTerminator()->eraseFromParent();
  BasicBlock *Invalid = BasicBlock::Create(F.getContext(),
                                           "dispatch.invalid", &F);
  new UnreachableInst(F.getContext(), Invalid);
  auto *Dispatch = SwitchInst::Create(Shape.State, Invalid, States.size(),
                                      Header);
  for (const APInt &Raw : States)
    Dispatch->addCase(cast<ConstantInt>(ConstantInt::get(
                          cast<IntegerType>(Shape.State->getType()), Raw)),
                      Targets.lookup(Raw));

  removeUnreachableBlocks(F);
  std::string Diagnostic;
  raw_string_ostream OS(Diagnostic);
  if (verifyFunction(F, &OS)) {
    OS.flush();
    Transaction.rollback();
    ++M.VerifierFailures;
    return false;
  }
  Transaction.commit();
  ++M.DispatchersRecovered;
  ProofRecord Proof{F.getName().str(), "cff_dispatcher",
                    Header->getName().str(),
                    "finite_branch_state_induction", "proved"};
  Proof.OldHash = hashText(OldText);
  Proof.NewHash = hashText(valueText(F));
  Proof.ProofQueryHash = hashText(
      "finite-state-closure:" + std::to_string(States.size()));
  Proof.Dependencies.push_back("concrete_apint_decision_evaluation");
  Proof.Dependencies.push_back("closed_transition_state_induction");
  Proof.Dependencies.push_back("llvm_verify_function");
  Proofs.push_back(std::move(Proof));
  (void)Fallback;
  return true;
}

} // namespace

bool recoverFiniteBranchDispatchers(
    Function &F, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  SmallVector<WeakTrackingVH, 16> Work;
  for (BasicBlock &BB : F)
    for (PHINode &PN : BB.phis())
      if (matchBranchDispatcher(PN))
        Work.emplace_back(&PN);

  bool Changed = false;
  for (WeakTrackingVH &Handle : Work) {
    auto *PN = dyn_cast_or_null<PHINode>(Handle);
    if (!PN || !PN->getParent())
      continue;
    auto Shape = matchBranchDispatcher(*PN);
    if (!Shape)
      continue;
    Changed |= recoverOneFiniteBranchDispatcher(F, *Shape, M, Proofs);
  }
  return Changed;
}

} // namespace brighten_ollvm_deobf
