#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

// Partitioned dispatchers with live semantic state use a two-level latch:
// case paths merge into a funnel PHI block, then a compact latch PHI block
// feeds the header PHIs.  Demote only the latch/header PHIs with LLVM's exact
// utility and clone the complete funnel->latch->header plumbing on each
// proved transition.  This preserves every semantic state component while
// removing the dispatcher lookup cycle.
bool tryRecoverPartitionedSSAPlumbingDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getNumIncomingValues() != 2)
    return false;
  BasicBlock *Header = State->getParent();
  Function *F = Header->getParent();
  if (SI.getFunction() != F)
    return false;

  ConstantInt *Initial = nullptr;
  BasicBlock *EntryPred = nullptr, *Latch = nullptr;
  PHINode *LatchState = nullptr;
  for (unsigned I = 0; I != 2; ++I) {
    Value *Incoming = State->getIncomingValue(I);
    BasicBlock *IncomingBlock = State->getIncomingBlock(I);
    if (auto *C = asTransitionConstant(Incoming, IncomingBlock)) {
      Initial = C;
      EntryPred = IncomingBlock;
    } else if (auto *PN = dyn_cast<PHINode>(Incoming)) {
      LatchState = PN;
      Latch = IncomingBlock;
    }
  }
  if (!Initial || !EntryPred || !LatchState || !Latch ||
      LatchState->getParent() != Latch || !Header->hasNPredecessors(2))
    return false;
  auto *EntryBr = dyn_cast<BranchInst>(EntryPred->getTerminator());
  auto *LatchBr = dyn_cast<BranchInst>(Latch->getTerminator());
  if (!EntryBr || !EntryBr->isUnconditional() ||
      EntryBr->getSuccessor(0) != Header || !LatchBr ||
      LatchBr->getNumSuccessors() == 0)
    return false;

  // The compact latch may reserve one exact state for leaving the flattened
  // region.  Accept only the canonical equality test between LatchState and a
  // constant, with the other edge returning to Header.  This is the same
  // fail-closed terminal-state proof used by the direct SSA plumbing engine.
  ConstantInt *TerminalState = nullptr;
  BasicBlock *TerminalTarget = nullptr;
  if (LatchBr->isUnconditional()) {
    if (LatchBr->getSuccessor(0) != Header) return false;
  } else {
    unsigned HeaderSuccessor = LatchBr->getSuccessor(0) == Header
                                   ? 0
                                   : LatchBr->getSuccessor(1) == Header ? 1 : 2;
    if (HeaderSuccessor > 1) return false;
    auto *Cmp = dyn_cast<ICmpInst>(LatchBr->getCondition());
    if (!Cmp || !Cmp->isEquality()) return false;
    Value *Other = nullptr;
    if (Cmp->getOperand(0) == LatchState)
      Other = Cmp->getOperand(1);
    else if (Cmp->getOperand(1) == LatchState)
      Other = Cmp->getOperand(0);
    TerminalState = dyn_cast_or_null<ConstantInt>(Other);
    if (!TerminalState) return false;
    bool TrueMeansEqual = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
    unsigned EqualSuccessor = TrueMeansEqual ? 0 : 1;
    if (EqualSuccessor == HeaderSuccessor) return false;
    TerminalTarget = LatchBr->getSuccessor(EqualSuccessor);
    if (TerminalTarget == Header) return false;
  }

  SmallVector<SwitchInst *, 8> Shards;
  SmallPtrSet<BasicBlock *, 32> ShardBlocks;
  struct EqualityShardCase {
    ConstantInt *Key = nullptr;
    BasicBlock *Target = nullptr;
    BasicBlock *Owner = nullptr;
  };
  SmallVector<EqualityShardCase, 8> EqualityCases;
  BasicBlock *CurrentBlock = Header;
  BasicBlock *PreviousBlock = nullptr;
  bool ReachedLatch = false;
  for (unsigned Depth = 0; Depth != 32; ++Depth) {
    if (!ShardBlocks.insert(CurrentBlock).second) return false;
    if (PreviousBlock &&
        (!CurrentBlock->hasNPredecessors(1) ||
         *pred_begin(CurrentBlock) != PreviousBlock))
      return false;

    BasicBlock *Next = nullptr;
    if (auto *Shard = dyn_cast<SwitchInst>(CurrentBlock->getTerminator())) {
      if (Shards.size() == 8 || Shard->getCondition() != SI.getCondition())
        return false;
      if (CurrentBlock != Header)
        for (Instruction &I : *CurrentBlock)
          if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I)) return false;
      Shards.push_back(Shard);
      Next = Shard->getDefaultDest();
    } else {
      // Optimisation may peel one or more sparse switch cases into equality
      // branches between switch table shards.  They are still part of the
      // same exhaustive dispatcher lookup chain and must be collected rather
      // than making the entire partitioned dispatcher unrecognisable.
      auto *Br = dyn_cast<BranchInst>(CurrentBlock->getTerminator());
      auto *Cmp = Br && Br->isConditional()
                      ? dyn_cast<ICmpInst>(Br->getCondition())
                      : nullptr;
      if (!Cmp || (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
                   Cmp->getPredicate() != ICmpInst::ICMP_NE))
        return false;
      ConstantInt *Key = dyn_cast<ConstantInt>(Cmp->getOperand(1));
      Value *Compared = Cmp->getOperand(0);
      if (!Key) {
        Key = dyn_cast<ConstantInt>(Cmp->getOperand(0));
        Compared = Cmp->getOperand(1);
      }
      if (!Key || Compared != SI.getCondition()) return false;
      if (CurrentBlock != Header)
        for (Instruction &I : *CurrentBlock)
          if (&I != Cmp && !I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
            return false;
      unsigned MatchIndex = Cmp->getPredicate() == ICmpInst::ICMP_EQ ? 0 : 1;
      EqualityCases.push_back(
          {Key, Br->getSuccessor(MatchIndex), CurrentBlock});
      Next = Br->getSuccessor(1 - MatchIndex);
    }
    if (Next == Latch) {
      ReachedLatch = true;
      break;
    }
    PreviousBlock = CurrentBlock;
    CurrentBlock = Next;
  }
  // A single switch followed by a complete semantic funnel is the same
  // recurrence as the multi-shard form; partitioning is an optimizer detail,
  // not part of the proof obligation.
  // recoverDispatchers visits every large switch in the function.  Only the
  // first switch in this lookup chain owns the rewrite; accepting a later
  // shard would replay the whole-chain mutation after earlier CFG changes and
  // can leave a surviving shard using a latch value that no longer dominates
  // it.  Equality blocks before the first switch remain supported.
  if (Shards.empty() || Shards.front() != &SI || !ReachedLatch)
    return false;

  DenseMap<APInt, BasicBlock *> CaseMap;
  DenseMap<APInt, BasicBlock *> CaseOwner;
  SmallPtrSet<BasicBlock *, 4> PhiCaseTargets;
  for (SwitchInst *Shard : Shards)
    for (auto Case : Shard->cases()) {
      APInt Key = Case.getCaseValue()->getValue();
      BasicBlock *Target = Case.getCaseSuccessor();
      if (CaseMap.count(Key) || ShardBlocks.contains(Target))
        return false;
      if (!Target->phis().empty()) PhiCaseTargets.insert(Target);
      CaseMap[Key] = Target;
      CaseOwner[Key] = Shard->getParent();
    }
  for (const EqualityShardCase &Case : EqualityCases) {
    APInt Key = Case.Key->getValue();
    if (CaseMap.count(Key) || ShardBlocks.contains(Case.Target)) return false;
    if (!Case.Target->phis().empty()) PhiCaseTargets.insert(Case.Target);
    CaseMap[Key] = Case.Target;
    CaseOwner[Key] = Case.Owner;
  }
  if (CaseMap.size() < 4) return false;

  SmallVector<PHINode *, 16> HeaderPhis;
  SmallVector<PHINode *, 16> LatchPhis;
  for (PHINode &HeaderPhi : Header->phis()) {
    if (HeaderPhi.getNumIncomingValues() != 2 ||
        HeaderPhi.getBasicBlockIndex(EntryPred) < 0 ||
        HeaderPhi.getBasicBlockIndex(Latch) < 0)
      return false;
    // A loop-carried component need not be forwarded by a latch PHI
    // directly.  Optimisation commonly folds its update into a pure latch
    // instruction (for example, an or/add fed by a latch PHI).  Requiring a
    // one-to-one HeaderPhi->LatchPhi pairing rejects that valid canonical
    // SSA shape.  The complete latch body is cloned below, so accepting a
    // value defined in the latch is exact; values from any other block would
    // require unsupported cross-block scheduling and remain rejected.
    Value *LatchIncoming = HeaderPhi.getIncomingValueForBlock(Latch);
    if (auto *LatchInstruction = dyn_cast<Instruction>(LatchIncoming);
        !LatchInstruction || LatchInstruction->getParent() != Latch)
      return false;
    HeaderPhis.push_back(&HeaderPhi);
  }
  for (PHINode &LatchPhi : Latch->phis())
    LatchPhis.push_back(&LatchPhi);
  if (!llvm::is_contained(LatchPhis, LatchState)) return false;

  BasicBlock *LastShard = Shards.back()->getParent();
  BasicBlock *Funnel = nullptr;
  for (BasicBlock *Pred : predecessors(Latch)) {
    if (Pred == LastShard) continue;
    if (Funnel) return false;
    Funnel = Pred;
  }
  if (!Funnel || !llvm::is_contained(predecessors(Latch), LastShard))
    return false;
  auto *FunnelBr = dyn_cast<BranchInst>(Funnel->getTerminator());
  if (!FunnelBr || !FunnelBr->isUnconditional() ||
      FunnelBr->getSuccessor(0) != Latch)
    return false;

  DenseMap<PHINode *, PHINode *> LatchToFunnel;
  SmallPtrSet<PHINode *, 16> UsedFunnelPhis;
  for (PHINode *LatchPhi : LatchPhis) {
    if (LatchPhi->getBasicBlockIndex(Funnel) < 0 ||
        LatchPhi->getBasicBlockIndex(LastShard) < 0)
      return false;
    auto *FunnelPhi = dyn_cast<PHINode>(
        LatchPhi->getIncomingValueForBlock(Funnel));
    if (!FunnelPhi || FunnelPhi->getParent() != Funnel ||
        !UsedFunnelPhis.insert(FunnelPhi).second)
      return false;
    LatchToFunnel[LatchPhi] = FunnelPhi;
  }
  for (PHINode &FunnelPhi : Funnel->phis())
    if (!UsedFunnelPhis.contains(&FunnelPhi)) return false;
  PHINode *StateFunnel = LatchToFunnel.lookup(LatchState);
  if (!StateFunnel) return false;
  for (BasicBlock *PhiTarget : PhiCaseTargets)
    if (PhiTarget != Funnel) return false;

  struct ResolvedPlumbingPath {
    BasicBlock *Target = nullptr;
    SmallVector<BasicBlock *, 8> TrampolineOwners;
  };
  auto Resolve = [&](ConstantInt *Raw) -> std::optional<ResolvedPlumbingPath> {
    ResolvedPlumbingPath Result;
    APInt CurrentState = Raw->getValue();
    SmallPtrSet<BasicBlock *, 8> SeenOwners;
    for (unsigned Depth = 0; Depth != 8; ++Depth) {
      if (TerminalState && CurrentState == TerminalState->getValue()) {
        Result.Target = TerminalTarget;
        return Result;
      }
      auto Encoded = evalStateExpr(SI.getCondition(), State, CurrentState);
      if (!Encoded) return std::nullopt;
      auto It = CaseMap.find(*Encoded);
      if (It == CaseMap.end()) return std::nullopt;
      if (It->second != Funnel) {
        Result.Target = It->second;
        return Result;
      }
      BasicBlock *Owner = CaseOwner.lookup(*Encoded);
      if (!Owner || !SeenOwners.insert(Owner).second) return std::nullopt;
      auto *Next = dyn_cast_or_null<ConstantInt>(
          StateFunnel->getIncomingValueForBlock(Owner));
      if (!Next) return std::nullopt;
      Result.TrampolineOwners.push_back(Owner);
      CurrentState = Next->getValue();
    }
    return std::nullopt;
  };
  std::optional<ResolvedPlumbingPath> InitialPath = Resolve(Initial);
  if (!InitialPath) return false;

  struct PlumbingTransition {
    BasicBlock *Source = nullptr;
    Value *Condition = nullptr;
    ResolvedPlumbingPath TruePath;
    std::optional<ResolvedPlumbingPath> FalsePath;
  };
  SmallVector<PlumbingTransition, 128> Transitions;
  for (BasicBlock *Source : predecessors(Funnel)) {
    // A switch shard may itself target the funnel for a trampoline state.
    // Resolve() has already proved that state's next hop through StateFunnel;
    // the shard is dispatcher plumbing, not a returning case transition.
    if (ShardBlocks.contains(Source)) continue;
    int StateIndex = StateFunnel->getBasicBlockIndex(Source);
    if (StateIndex < 0) return false;
    Value *Next = StateFunnel->getIncomingValue(StateIndex);
    PlumbingTransition Transition;
    Transition.Source = Source;
    if (auto *C = dyn_cast<ConstantInt>(Next)) {
      auto Path = Resolve(C);
      if (!Path) return false;
      Transition.TruePath = std::move(*Path);
    } else if (auto *Select = dyn_cast<SelectInst>(Next)) {
      auto *TC = dyn_cast<ConstantInt>(Select->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Select->getFalseValue());
      if (!TC || !FC) return false;
      Transition.Condition = Select->getCondition();
      auto TruePath = Resolve(TC);
      auto FalsePath = Resolve(FC);
      if (!TruePath || !FalsePath) return false;
      Transition.TruePath = std::move(*TruePath);
      Transition.FalsePath = std::move(*FalsePath);
    } else {
      return false;
    }
    auto *OldBranch = dyn_cast<BranchInst>(Source->getTerminator());
    if (!OldBranch) return false;
    if (OldBranch->isUnconditional()) {
      if (OldBranch->getSuccessor(0) != Funnel) return false;
    } else {
      if (!Transition.Condition) return false;
      bool Same = OldBranch->getCondition() == Transition.Condition ||
                  proveEquivalentSMT(OldBranch->getCondition(),
                                     Transition.Condition);
      bool Inverted = false;
      if (!Same) {
        auto *NotCondition = BinaryOperator::CreateNot(
            Transition.Condition, "deobf.partition.plumbing.not",
            OldBranch->getIterator());
        Inverted = proveEquivalentSMT(OldBranch->getCondition(), NotCondition);
        NotCondition->eraseFromParent();
      }
      if (!Same && !Inverted) return false;
      bool TrueIsFunnel = OldBranch->getSuccessor(0) == Funnel;
      bool FalseIsFunnel = OldBranch->getSuccessor(1) == Funnel;
      if (TrueIsFunnel == FalseIsFunnel) return false;
      BasicBlock *Direct =
          OldBranch->getSuccessor(TrueIsFunnel ? 1 : 0);
      bool SelectTrueOnDirect = Same ? !TrueIsFunnel : TrueIsFunnel;
      BasicBlock *Expected = SelectTrueOnDirect
                                 ? Transition.TruePath.Target
                                 : Transition.FalsePath->Target;
      if (Direct != Expected) return false;
    }
    Transitions.push_back(Transition);
  }
  if (Transitions.empty()) return false;

  Instruction *AllocaPoint = &*F->getEntryBlock().getFirstInsertionPt();
  for (PHINode *LatchPhi : LatchPhis)
    DemotePHIToStack(LatchPhi, AllocaPoint->getIterator());
  for (PHINode *HeaderPhi : HeaderPhis)
    DemotePHIToStack(HeaderPhi, AllocaPoint->getIterator());

  // A conditional terminal edge can consume values produced in the latch.
  // Once transitions bypass that latch, keep those exact live-outs available
  // through private reg2mem slots before cloning the latch body per edge.
  SmallVector<Instruction *, 16> LatchBeforeLiveOutDemotion;
  for (Instruction &I : *Latch)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      LatchBeforeLiveOutDemotion.push_back(&I);
  for (Instruction *I : LatchBeforeLiveOutDemotion) {
    if (I->getType()->isVoidTy() || I->use_empty()) continue;
    bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
      auto *UseI = dyn_cast<Instruction>(U);
      return UseI && UseI->getParent() != Latch;
    });
    if (UsedOutside)
      DemoteRegToStack(*I, false, AllocaPoint->getIterator());
  }

  // Header values can feed instructions in case blocks.  Once the dispatcher
  // header is bypassed, a cloned header definition no longer dominates those
  // existing uses.  Lower every such live-out through LLVM's reg2mem utility;
  // cloning the resulting store in HeaderBody then supplies the exact value
  // to the per-use reloads that remain in each case block.
  SmallVector<Instruction *, 64> HeaderBeforeLiveOutDemotion;
  for (Instruction &I : *Header)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      HeaderBeforeLiveOutDemotion.push_back(&I);
  for (Instruction *I : HeaderBeforeLiveOutDemotion) {
    if (I->getType()->isVoidTy() || I->use_empty()) continue;
    bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
      auto *UseI = dyn_cast<Instruction>(U);
      return UseI && UseI->getParent() != Header;
    });
    if (UsedOutside)
      DemoteRegToStack(*I, false, AllocaPoint->getIterator());
  }

  SmallVector<Instruction *, 64> FunnelBody, LatchBody, HeaderBody;
  for (Instruction &I : *Funnel)
    if (!isa<PHINode>(I) && !I.isTerminator() &&
        !isa<DbgInfoIntrinsic>(I))
      FunnelBody.push_back(&I);
  for (Instruction &I : *Latch)
    if (!isa<PHINode>(I) && !I.isTerminator() &&
        !isa<DbgInfoIntrinsic>(I))
      LatchBody.push_back(&I);
  for (Instruction &I : *Header)
    if (!isa<PHINode>(I) && !I.isTerminator() &&
        !isa<DbgInfoIntrinsic>(I))
      HeaderBody.push_back(&I);

  // Clone one exact semantic-state update round.  Map is intentionally kept
  // across rounds: funnel values owned by a dispatcher shard may reference
  // header values produced by the preceding round.
  auto CloneRound = [&](BasicBlock *Owner, Instruction *InsertBefore,
                        DenseMap<const Value *, Value *> &Map) {
    // Reg2mem may place reloads in a non-header shard for PHI operands whose
    // edge is owned by that shard.  Those reloads are real dispatcher-path
    // plumbing and must be cloned before their funnel incoming values are
    // mapped.  The preflight above proved that a shard had no original body,
    // so this cannot duplicate case semantics or side effects.
    if (Owner != Header && ShardBlocks.contains(Owner)) {
      SmallVector<Instruction *, 16> OwnerBody;
      for (Instruction &I : *Owner)
        if (!isa<PHINode>(I) && !I.isTerminator() &&
            !isa<DbgInfoIntrinsic>(I))
          OwnerBody.push_back(&I);
      cloneBlockPlumbing(OwnerBody, InsertBefore, Map);
    }
    for (PHINode &FunnelPhi : Funnel->phis()) {
      Value *Incoming = FunnelPhi.getIncomingValueForBlock(Owner);
      auto It = Map.find(Incoming);
      Map[&FunnelPhi] = It == Map.end() ? Incoming : It->second;
    }
    cloneBlockPlumbing(FunnelBody, InsertBefore, Map);
    cloneBlockPlumbing(LatchBody, InsertBefore, Map);
    cloneBlockPlumbing(HeaderBody, InsertBefore, Map);
  };

  {
    Instruction *Old = EntryPred->getTerminator();
    DenseMap<const Value *, Value *> Map;
    cloneBlockPlumbing(HeaderBody, Old, Map);
    for (BasicBlock *Owner : InitialPath->TrampolineOwners)
      CloneRound(Owner, Old, Map);
    BranchInst::Create(InitialPath->Target, Old->getIterator());
    Old->eraseFromParent();
  }
  unsigned PathSerial = 0;
  for (const PlumbingTransition &Transition : Transitions) {
    Instruction *Old = Transition.Source->getTerminator();
    DenseMap<const Value *, Value *> Map;
    CloneRound(Transition.Source, Old, Map);
    auto MaterializePath = [&](const ResolvedPlumbingPath &Path,
                               StringRef Suffix) -> BasicBlock * {
      if (Path.TrampolineOwners.empty()) return Path.Target;
      BasicBlock *PathBlock = BasicBlock::Create(
          F->getContext(), "deobf.partition.plumbing." + Suffix + "." +
                               Twine(PathSerial++),
          F, Path.Target);
      BranchInst *PathBranch = BranchInst::Create(Path.Target, PathBlock);
      DenseMap<const Value *, Value *> PathMap = Map;
      for (BasicBlock *Owner : Path.TrampolineOwners)
        CloneRound(Owner, PathBranch, PathMap);
      return PathBlock;
    };
    BasicBlock *TrueTarget =
        MaterializePath(Transition.TruePath, "true");
    if (Transition.Condition) {
      BasicBlock *FalseTarget =
          MaterializePath(*Transition.FalsePath, "false");
      BranchInst::Create(TrueTarget, FalseTarget, Transition.Condition,
                         Old->getIterator());
    } else {
      BranchInst::Create(TrueTarget, Old->getIterator());
    }
    Old->eraseFromParent();
    Proofs.push_back({F->getName().str(), "cff_transition",
                      Transition.Source->getName().str(),
                      Shards.size() == 1 ? "ssa_funnel_plumbing"
                                         : "partitioned_ssa_funnel_plumbing",
                      "proved"});
  }
  std::string HeaderName = Header->getName().str();
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  ProofRecord Record{
      F->getName().str(), "cff_dispatcher", HeaderName,
      Shards.size() == 1 ? "complete_ssa_funnel_plumbing"
                         : "complete_partitioned_ssa_funnel_plumbing",
      "proved"};
  Record.Dependencies.push_back(
      Shards.size() == 1 ? "unique_switch_case_table"
                         : "unique_union_of_switch_case_tables");
  Record.Dependencies.push_back("complete_funnel_phi_coverage");
  Record.Dependencies.push_back("llvm_latch_and_header_phi_demotion");
  Record.Dependencies.push_back("exact_funnel_latch_header_clone");
  Record.Dependencies.push_back("all_initial_and_next_states_resolved");
  if (TerminalState)
    Record.Dependencies.push_back("exact_terminal_latch_state_transition");
  Proofs.push_back(std::move(Record));
  return true;
}

} // namespace brighten_ollvm_deobf
