#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

// OLLVM can partition one dispatcher table into a default-linked chain of
// switches over the same SSA state.  Case bodies from every shard reconverge
// at one mem2reg latch PHI, while the last default returns to the first shard.
// Recover the state machine from the union of the exact case tables.  No
// range/order heuristic is used: keys must be unique, all returning paths must
// reach the one latch PHI, and every initial/next value must resolve to a real
// case before any CFG mutation is committed.
bool tryRecoverPartitionedSSADispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  Function *F = Header->getParent();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() != Header ||
      State->getNumIncomingValues() != 2 ||
      std::next(Header->phis().begin()) != Header->phis().end())
    return false;

  ConstantInt *Initial = nullptr;
  BasicBlock *EntryPred = nullptr, *Backedge = nullptr;
  PHINode *LatchState = nullptr;
  for (unsigned I = 0; I != 2; ++I) {
    Value *Incoming = State->getIncomingValue(I);
    if (auto *C = dyn_cast<ConstantInt>(Incoming)) {
      Initial = C;
      EntryPred = State->getIncomingBlock(I);
    } else if (auto *PN = dyn_cast<PHINode>(Incoming)) {
      LatchState = PN;
      Backedge = State->getIncomingBlock(I);
    }
  }
  if (!Initial || !EntryPred || !LatchState || !Backedge)
    return false;
  auto *EntryBr = dyn_cast<BranchInst>(EntryPred->getTerminator());
  if (!EntryBr || !EntryBr->isUnconditional() ||
      EntryBr->getSuccessor(0) != Header)
    return false;

  SmallVector<SwitchInst *, 8> Shards;
  SmallPtrSet<BasicBlock *, 8> ShardBlocks;
  SwitchInst *Current = &SI;
  while (Current && Shards.size() != 8) {
    BasicBlock *Block = Current->getParent();
    if (!ShardBlocks.insert(Block).second ||
        Current->getCondition() != SI.getCondition())
      return false;
    for (Instruction &I : *Block)
      if (!isa<PHINode>(I) && !I.isTerminator() &&
          !isa<DbgInfoIntrinsic>(I))
        if (Block != Header) return false;
    Shards.push_back(Current);
    BasicBlock *Default = Current->getDefaultDest();
    if (Default == Header) break;
    Current = dyn_cast<SwitchInst>(Default->getTerminator());
  }
  BasicBlock *ReturnBlock = Shards.back()->getDefaultDest();
  if (ReturnBlock != Header) {
    auto *ReturnBr = dyn_cast<BranchInst>(ReturnBlock->getTerminator());
    if (ReturnBlock != Backedge || !llvm::is_contained(
            predecessors(ReturnBlock), Shards.back()->getParent()) || !ReturnBr ||
        !ReturnBr->isUnconditional() || ReturnBr->getSuccessor(0) != Header)
      return false;
    for (Instruction &I : *ReturnBlock)
      if (!isa<PHINode>(I) && !I.isTerminator() &&
          !isa<DbgInfoIntrinsic>(I))
        return false;
  }
  if (Shards.size() < 2 ||
      (!ShardBlocks.contains(LatchState->getParent()) &&
       LatchState->getParent() != ReturnBlock))
    return false;
  for (User *U : State->users()) {
    auto *UseI = dyn_cast<Instruction>(U);
    if (!UseI || (UseI != LatchState &&
                  !ShardBlocks.contains(UseI->getParent())))
      return false;
  }
  for (User *U : LatchState->users())
    if (U != State)
      return false;

  DenseMap<APInt, BasicBlock *> CaseMap;
  for (SwitchInst *Shard : Shards)
    for (auto Case : Shard->cases()) {
      APInt Key = Case.getCaseValue()->getValue();
      if (CaseMap.count(Key)) return false;
      BasicBlock *Target = Case.getCaseSuccessor();
      if (!Target->phis().empty() || ShardBlocks.contains(Target))
        return false;
      CaseMap[Key] = Target;
    }
  if (CaseMap.size() < 4) return false;

  BasicBlock *Join = LatchState->getParent();
  unsigned JoinIndex = Shards.size();
  for (unsigned I = 0; I != Shards.size(); ++I)
    if (Shards[I]->getParent() == Join) JoinIndex = I;
  if (Join == ReturnBlock)
    JoinIndex = Shards.size();
  else if (JoinIndex == 0 || JoinIndex == Shards.size())
    return false;
  for (unsigned I = 1; I != Shards.size(); ++I) {
    BasicBlock *Block = Shards[I]->getParent();
    BasicBlock *Previous = Shards[I - 1]->getParent();
    if (I == JoinIndex) {
      if (LatchState->getBasicBlockIndex(Previous) < 0) return false;
      continue;
    }
    if (!Block->hasNPredecessors(1) || *pred_begin(Block) != Previous)
      return false;
  }

  SmallVector<BasicBlock *, 64> ReturningSources;
  for (BasicBlock *Source : predecessors(Join)) {
    if (ShardBlocks.contains(Source)) continue;
    if (LatchState->getBasicBlockIndex(Source) < 0) return false;
    ReturningSources.push_back(Source);
  }
  if (ReturningSources.empty()) return false;

  auto Resolve = [&](ConstantInt *Raw) -> BasicBlock * {
    auto Encoded = evalStateExpr(SI.getCondition(), State, Raw->getValue());
    if (!Encoded) return nullptr;
    auto It = CaseMap.find(*Encoded);
    return It == CaseMap.end() ? nullptr : It->second;
  };
  BasicBlock *InitialTarget = Resolve(Initial);
  if (!InitialTarget) return false;

  SmallVector<ProvenTransition, 64> Transitions;
  for (BasicBlock *Source : ReturningSources) {
    Value *Next = LatchState->getIncomingValueForBlock(Source);
    ProvenTransition Transition;
    Transition.Source = Source;
    if (auto *C = dyn_cast<ConstantInt>(Next)) {
      Transition.TrueTarget = Resolve(C);
    } else if (auto *Select = dyn_cast<SelectInst>(Next)) {
      auto *TC = dyn_cast<ConstantInt>(Select->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Select->getFalseValue());
      if (!TC || !FC) return false;
      Transition.Condition = Select->getCondition();
      Transition.TrueTarget = Resolve(TC);
      Transition.FalseTarget = Resolve(FC);
    } else {
      return false;
    }
    if (!Transition.TrueTarget ||
        (Transition.Condition && !Transition.FalseTarget))
      return false;
    auto *OldBranch = dyn_cast<BranchInst>(Source->getTerminator());
    if (!OldBranch) return false;
    if (OldBranch->isUnconditional()) {
      if (OldBranch->getSuccessor(0) != Join) return false;
    } else {
      if (!Transition.Condition) return false;
      bool SameCondition =
          OldBranch->getCondition() == Transition.Condition ||
          proveEquivalentSMT(OldBranch->getCondition(), Transition.Condition);
      bool InvertedCondition = false;
      if (!SameCondition) {
        auto *NotCondition = BinaryOperator::CreateNot(
            Transition.Condition, "deobf.partition.not", OldBranch->getIterator());
        InvertedCondition =
            proveEquivalentSMT(OldBranch->getCondition(), NotCondition);
        NotCondition->eraseFromParent();
      }
      if (!SameCondition && !InvertedCondition)
        return false;
      bool TrueIsJoin = OldBranch->getSuccessor(0) == Join;
      bool FalseIsJoin = OldBranch->getSuccessor(1) == Join;
      if (TrueIsJoin == FalseIsJoin) return false;
      BasicBlock *Direct = OldBranch->getSuccessor(TrueIsJoin ? 1 : 0);
      bool SelectTrueOnDirect = SameCondition ? !TrueIsJoin : TrueIsJoin;
      BasicBlock *Expected = SelectTrueOnDirect ? Transition.TrueTarget
                                                : Transition.FalseTarget;
      if (Direct != Expected)
        return false;
    }
    Transitions.push_back(Transition);
  }

  SmallVector<Instruction *, 16> HeaderBody;
  for (Instruction &I : *Header)
    if (!isa<PHINode>(I) && !I.isTerminator() &&
        !isa<DbgInfoIntrinsic>(I)) {
      for (User *U : I.users()) {
        auto *UseI = dyn_cast<Instruction>(U);
        if (!UseI || !ShardBlocks.contains(UseI->getParent())) return false;
      }
      HeaderBody.push_back(&I);
    }

  {
    Instruction *Old = EntryPred->getTerminator();
    DenseMap<const Value *, Value *> Map;
    Map[State] = Initial;
    cloneBlockPlumbing(HeaderBody, Old, Map);
    BranchInst::Create(InitialTarget, Old->getIterator());
    Old->eraseFromParent();
  }
  for (const ProvenTransition &Transition : Transitions) {
    Instruction *Old = Transition.Source->getTerminator();
    Value *Next = LatchState->getIncomingValueForBlock(Transition.Source);
    DenseMap<const Value *, Value *> Map;
    Map[State] = Next;
    cloneBlockPlumbing(HeaderBody, Old, Map);
    if (Transition.Condition)
      BranchInst::Create(Transition.TrueTarget, Transition.FalseTarget,
                         Transition.Condition, Old->getIterator());
    else
      BranchInst::Create(Transition.TrueTarget, Old->getIterator());
    Old->eraseFromParent();
    Proofs.push_back({F->getName().str(), "cff_transition",
                      Transition.Source->getName().str(),
                      "partitioned_ssa_exact_transition", "proved"});
  }
  std::string HeaderName = Header->getName().str();
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  ProofRecord Record{F->getName().str(), "cff_dispatcher", HeaderName,
                     "complete_partitioned_ssa_transition_set", "proved"};
  Record.Dependencies.push_back("unique_union_of_switch_case_tables");
  Record.Dependencies.push_back("complete_returning_case_coverage");
  Record.Dependencies.push_back("all_initial_and_next_states_resolved");
  Record.Dependencies.push_back("direct_edges_match_z3_proved_state_selects");
  Proofs.push_back(std::move(Record));
  return true;
}

} // namespace brighten_ollvm_deobf
