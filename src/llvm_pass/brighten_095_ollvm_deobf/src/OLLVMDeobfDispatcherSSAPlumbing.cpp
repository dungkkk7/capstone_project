#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

// Recover the finite direct-backedge form produced after loop rotation and
// jump threading:
//
//   header:
//     %state = phi [ %seed, %entry ], [ %next, %backedge ]
//     switch %state, ...
//   backedge:
//     %next = select/phi/... from a proved finite constant set
//     br header
//
// Unlike the general plumbing form, this shape has no latch PHI.  Retain the
// exact initial switch, but replace its only cyclic edge with a finite switch
// over %next.  Header and case-entry PHIs are demoted before cloning so the
// new edge executes the same per-dispatch plumbing and carries identical
// values.  The transaction fails closed unless every possible next value has
// an exact switch target.
static bool tryRecoverFiniteDirectBackedgeDispatcher(
    SwitchInst &SI, PHINode &State, Value *InitialState,
    BasicBlock *EntryPred, Value *BackedgeState, BasicBlock *Backedge,
    Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  Function *F = Header->getParent();
  if (!InitialState || !EntryPred || !BackedgeState || !Backedge ||
      Header == Backedge || !Header->hasNPredecessors(2))
    return false;
  auto *BackedgeBr = dyn_cast<BranchInst>(Backedge->getTerminator());
  if (!BackedgeBr || !BackedgeBr->isUnconditional() ||
      BackedgeBr->getSuccessor(0) != Header ||
      BackedgeState->getType() != State.getType() ||
      !BackedgeState->getType()->isIntegerTy())
    return false;

  DominatorTree DT(*F);
  auto *BackedgeI = dyn_cast<Instruction>(BackedgeState);
  if (!BackedgeI || !DT.dominates(BackedgeI, BackedgeBr)) return false;
  for (User *U : State.users()) {
    auto *UseI = dyn_cast<Instruction>(U);
    if (!UseI || UseI->getParent() != Header) return false;
  }

  SmallVector<PHINode *, 8> HeaderPhis;
  for (PHINode &HP : Header->phis()) {
    if (HP.getNumIncomingValues() != 2 ||
        HP.getBasicBlockIndex(EntryPred) < 0 ||
        HP.getBasicBlockIndex(Backedge) < 0)
      return false;
    HeaderPhis.push_back(&HP);
  }

  SmallVector<APInt, 8> RawValues;
  DenseMap<const Value *, APInt> Bindings;
  unsigned ExecutionBudget = 256;
  APInt DummyState(State.getType()->getIntegerBitWidth(), 0);
  if (!enumerateTransitionValues(BackedgeState, nullptr, DummyState, Bindings,
                                 RawValues, ExecutionBudget) ||
      RawValues.empty())
    return false;

  DenseMap<APInt, BasicBlock *> CaseMap;
  for (auto Case : SI.cases())
    CaseMap.try_emplace(Case.getCaseValue()->getValue(),
                        Case.getCaseSuccessor());
  if (CaseMap.size() < 2) return false;

  SmallVector<BasicBlock *, 8> Targets;
  SmallVector<PHINode *, 16> CaseEntryPhis;
  SmallPtrSet<PHINode *, 16> SeenCaseEntryPhis;
  for (const APInt &Raw : RawValues) {
    auto Encoded = evalStateExpr(SI.getCondition(), &State, Raw);
    if (!Encoded) return false;
    auto It = CaseMap.find(*Encoded);
    if (It == CaseMap.end()) return false;
    BasicBlock *Target = It->second;
    // A finite transition back into dispatcher plumbing would retain the
    // cycle.  Leave such shapes to the more general recurrence engines.
    if (Target == Header || Target == Backedge) return false;
    for (PHINode &PN : Target->phis()) {
      if (PN.getBasicBlockIndex(Header) < 0) return false;
      if (SeenCaseEntryPhis.insert(&PN).second)
        CaseEntryPhis.push_back(&PN);
    }
    Targets.push_back(Target);
  }

  std::string OldFunctionText = valueText(*F);
  Instruction *AllocaPoint = &*F->getEntryBlock().getFirstInsertionPt();
  for (PHINode *PN : CaseEntryPhis)
    DemotePHIToStack(PN, AllocaPoint->getIterator());
  for (PHINode *PN : HeaderPhis)
    DemotePHIToStack(PN, AllocaPoint->getIterator());

  SmallVector<Instruction *, 16> HeaderBeforeDemotion;
  for (Instruction &I : *Header)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      HeaderBeforeDemotion.push_back(&I);
  for (Instruction *I : HeaderBeforeDemotion) {
    if (I->getType()->isVoidTy() || I->use_empty()) continue;
    bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
      auto *UI = dyn_cast<Instruction>(U);
      return UI && UI->getParent() != Header;
    });
    if (UsedOutside)
      DemoteRegToStack(*I, false, AllocaPoint->getIterator());
  }

  SmallVector<Instruction *, 32> HeaderBody;
  for (Instruction &I : *Header)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      HeaderBody.push_back(&I);

  Instruction *OldTerminator = Backedge->getTerminator();
  std::string OldTerminatorText = valueText(*OldTerminator);
  DenseMap<const Value *, Value *> Map;
  cloneBlockPlumbing(HeaderBody, OldTerminator, Map);
  Value *FiniteState = BackedgeState;
  if (auto It = Map.find(FiniteState); It != Map.end())
    FiniteState = It->second;
  auto *FiniteSwitch = SwitchInst::Create(
      FiniteState, Targets.front(), RawValues.size() - 1,
      OldTerminator->getIterator());
  for (unsigned I = 1; I != RawValues.size(); ++I)
    FiniteSwitch->addCase(ConstantInt::get(State.getContext(), RawValues[I]),
                          Targets[I]);
  OldTerminator->eraseFromParent();

  // The retained switch now performs only the exact initial/dynamic entry
  // dispatch.  It no longer owns a state recurrence; teach the inventory not
  // to reclassify an outer-loop path back to this entry as residual CFF.
  SI.setMetadata("ollvm.deobf.dynamic_entry_dispatch",
                 MDNode::get(F->getContext(), {}));
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  ProofRecord Transition{F->getName().str(), "cff_transition",
                         Backedge->getName().str(),
                         "finite_direct_backedge_exact_plumbing", "proved"};
  Transition.OldHash = hashText(OldTerminatorText);
  Transition.NewHash = hashText(valueText(*Backedge->getTerminator()));
  Transition.Dependencies.push_back("exhaustive_acyclic_finite_transition_set");
  Transition.Dependencies.push_back("llvm_phi_demotion");
  Transition.Dependencies.push_back("exact_header_clone");
  Proofs.push_back(std::move(Transition));

  ProofRecord Dispatcher{F->getName().str(), "cff_dispatcher",
                         Header->getName().str(),
                         "finite_direct_backedge_transition_set", "proved"};
  Dispatcher.OldHash = hashText(OldFunctionText);
  Dispatcher.NewHash = hashText(valueText(*F));
  Dispatcher.Dependencies.push_back("initial_exact_switch_retained");
  Dispatcher.Dependencies.push_back("complete_finite_backedge_value_set");
  Proofs.push_back(std::move(Dispatcher));
  return true;
}

bool tryRecoverSSAPlumbingDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs,
    std::string *RejectionReason) {
  BasicBlock *SwitchBlock = SI.getParent();
  auto Reject = [&](StringRef Reason) {
    if (RejectionReason) *RejectionReason = Reason.str();
    return false;
  };
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getNumIncomingValues() != 2)
    return Reject("state-root");
  // A sparse equality case may be peeled in front of the first switch shard.
  // Anchor the recurrence at the state PHI rather than at that later shard.
  BasicBlock *Header = State->getParent();
  Function *F = Header->getParent();
  if (SwitchBlock->getParent() != F)
    return Reject("state-root-function");
  PHINode *LatchState = nullptr;
  LoadInst *LatchStateLoad = nullptr;
  Value *DirectBackedgeState = nullptr;
  std::string MemoryPromotionFailure;
  Value *InitialStateValue = nullptr;
  ConstantInt *Initial = nullptr;
  BasicBlock *EntryPred = nullptr, *Latch = nullptr;
  DominatorTree DispatcherDT(*F);
  LoopInfo DispatcherLI(DispatcherDT);
  Loop *DispatcherLoop = DispatcherLI.getLoopFor(Header);
  for (unsigned I = 0; I != 2; ++I) {
    Value *V = State->getIncomingValue(I);
    BasicBlock *IncomingBlock = State->getIncomingBlock(I);
    if (auto *C = dyn_cast<ConstantInt>(V)) {
      Initial = C;
      InitialStateValue = C;
      EntryPred = IncomingBlock;
    } else if (auto *PN = dyn_cast<PHINode>(V)) {
      // Nested dispatchers commonly receive their first state through an
      // outer-loop PHI.  Dominance, rather than the value kind, distinguishes
      // that seed arm from the inner dispatcher latch arm.
      if (!DispatcherDT.dominates(Header, IncomingBlock)) {
        InitialStateValue = PN;
        EntryPred = IncomingBlock;
      } else {
        LatchState = PN;
        Latch = IncomingBlock;
      }
    } else if (auto *LI = dyn_cast<LoadInst>(V)) {
      // Classify the load after seeing the other arm.  Native cleanup can
      // materialize an entry-state load from a locally initialized frame
      // slot, while memory-form CFF uses a load on the cyclic latch arm.
      BasicBlock *IncomingBlock = State->getIncomingBlock(I);
      if (!DispatcherDT.dominates(Header, IncomingBlock)) {
        InitialStateValue = LI;
        EntryPred = IncomingBlock;
      } else {
        LatchStateLoad = LI;
        Latch = IncomingBlock;
      }
    } else if (!DispatcherDT.dominates(Header, IncomingBlock)) {
      InitialStateValue = V;
      EntryPred = IncomingBlock;
    } else {
      DirectBackedgeState = V;
      Latch = IncomingBlock;
    }
  }
  if (!Initial && InitialStateValue && EntryPred)
    Initial = asTransitionConstant(InitialStateValue, EntryPred);
  // Keep the compact direct-SSA engine for a constant-seeded dispatcher that
  // carries no semantic header state.  This plumbing engine is needed for the
  // single-PHI shape only when the seed is dynamic or belongs to a nested
  // outer recurrence.  The exception is a default-linked lookup shard: its
  // memory join must first become SSA so the complete partitioned engine can
  // prove the union of all case tables.
  auto *DefaultLookup =
      dyn_cast<SwitchInst>(SI.getDefaultDest()->getTerminator());
  bool HasPartitionedLookupShard =
      DefaultLookup && DefaultLookup->getCondition() == SI.getCondition();
  if (Initial && SwitchBlock == Header &&
      (!LatchStateLoad || !HasPartitionedLookupShard) &&
      std::next(Header->phis().begin()) == Header->phis().end())
    return Reject("constant-single-header-phi");
  if (InitialStateValue && DirectBackedgeState && Latch &&
      tryRecoverFiniteDirectBackedgeDispatcher(
          SI, *State, InitialStateValue, EntryPred, DirectBackedgeState, Latch,
          M, Proofs))
    return true;
  // Late pointer canonicalization can expose a complete memory recurrence
  // only after the broad State-SSA sweep has run. Promote that exact join load
  // to a latch PHI. The dispatcher default edge carries the current state;
  // every other predecessor must have one exact reaching store.
  if (InitialStateValue && !LatchState && LatchStateLoad && Latch &&
      LatchStateLoad->getParent() == Latch &&
      !LatchStateLoad->isAtomic() && !LatchStateLoad->isVolatile()) {
    bool Safe = true;
    for (Instruction &I : *Latch) {
      if (&I == LatchStateLoad) break;
      if (!isa<PHINode>(I) && !isa<DbgInfoIntrinsic>(I) &&
          I.mayWriteToMemory()) {
        Safe = false;
        MemoryPromotionFailure = "write-before-latch-state-load";
        break;
      }
    }
    DenseMap<BasicBlock *, APInt> MemoryCaseStates;
    SmallPtrSet<BasicBlock *, 8> AmbiguousMemoryCaseStates;
    for (BasicBlock &LookupBlock : *F) {
      auto *Lookup = dyn_cast<SwitchInst>(LookupBlock.getTerminator());
      if (!Lookup || Lookup->getCondition() != SI.getCondition()) continue;
      for (auto Case : Lookup->cases()) {
        auto Raw = decodeStateExpr(SI.getCondition(), State,
                                   Case.getCaseValue()->getValue());
        if (!Raw) continue;
        BasicBlock *Target = Case.getCaseSuccessor();
        auto It = MemoryCaseStates.find(Target);
        if (It == MemoryCaseStates.end())
          MemoryCaseStates.try_emplace(Target, *Raw);
        else if (It->second != *Raw)
          AmbiguousMemoryCaseStates.insert(Target);
      }
    }
    for (BasicBlock *Target : AmbiguousMemoryCaseStates)
      MemoryCaseStates.erase(Target);

    SmallVector<std::pair<Value *, BasicBlock *>, 64> Incoming;
    for (BasicBlock *Pred : predecessors(Latch)) {
      unsigned EdgeCount = 0;
      for (BasicBlock *Succ : successors(Pred)) EdgeCount += Succ == Latch;
      if (EdgeCount != 1) {
        Safe = false;
        MemoryPromotionFailure =
            (Twine("non-unique-latch-edge:") + Pred->getName()).str();
        break;
      }
      bool HitBarrier = false;
      StoreInst *Store = findReachingStateStore(
          Pred, LatchStateLoad->getPointerOperand(), LatchStateLoad->getType(),
          Header, 0, &HitBarrier);
      PHINode *MergedState = nullptr;
      if (!Store && !HitBarrier)
        MergedState = buildMergedReachingStateValue(
            Pred, LatchStateLoad->getPointerOperand(),
            LatchStateLoad->getType(), Header, Latch, MemoryCaseStates,
            State);
      if (Pred == Header && !Store && !HitBarrier) {
        Incoming.push_back({State, Pred});
        continue;
      }
      if ((!Store && !MergedState) || HitBarrier ||
          (Store && (Store->isAtomic() || Store->isVolatile() ||
                     Store->getValueOperand()->getType() !=
                         LatchStateLoad->getType() ||
                     !sameFrameAddress(Store->getPointerOperand(),
                                       LatchStateLoad->getPointerOperand())))) {
        Safe = false;
        MemoryPromotionFailure =
            (Twine("unproved-reaching-state:") + Pred->getName() +
             (HitBarrier ? ":alias-barrier" : ":no-exact-store"))
                .str();
        break;
      }
      Incoming.push_back(
          {Store ? Store->getValueOperand() : static_cast<Value *>(MergedState),
           Pred});
    }
    if (Safe && Incoming.size() == pred_size(Latch)) {
      // Do not wrap an already complete predecessor-join PHI in a trivial
      // one-input PHI.  Keeping the exact join as the state family root makes
      // partitioned lookup shards and their returning case predecessors
      // visible to the complete recovery engine.
      if (Incoming.size() == 1)
        if (auto *Merged = dyn_cast<PHINode>(Incoming.front().first);
            Merged && Merged->getParent() == Incoming.front().second)
          LatchState = Merged;
      if (!LatchState) {
        LatchState = PHINode::Create(
            LatchStateLoad->getType(), Incoming.size(),
            "deobf.memory.latch.state", LatchStateLoad->getIterator());
        for (const auto &[IncomingValue, Pred] : Incoming)
          LatchState->addIncoming(IncomingValue, Pred);
      }
      LatchStateLoad->replaceAllUsesWith(LatchState);
      LatchStateLoad->eraseFromParent();
      ++M.MemorySSAPhisResolved;
      ProofRecord Promotion{F->getName().str(), "cff_state_promotion",
                            Header->getName().str(),
                            "exact_memory_join_to_latch_phi", "proved"};
      Promotion.Dependencies.push_back("complete_predecessor_coverage");
      Promotion.Dependencies.push_back("exact_reaching_state_stores");
      Promotion.Dependencies.push_back("default_self_edge_state_passthrough");
      Proofs.push_back(std::move(Promotion));

      // The promotion exposes the canonical all-SSA partitioned state
      // machine.  Complete that recovery in the same transaction when this
      // candidate is the state header.  Otherwise a later shard could observe
      // the promoted PHI after this engine reports failure, violating the
      // mutation-free failure contract and forcing a rollback of an exact
      // promotion.
      if (SwitchBlock == Header) {
        bool PartitionedRecovered =
            tryRecoverPartitionedSSADispatcher(SI, M, Proofs);
        if (PartitionedRecovered) return true;
      }
    }
  }
  if (!InitialStateValue || !LatchState || LatchState->getParent() != Latch ||
      !Header->hasNPredecessors(2))
    return Reject(MemoryPromotionFailure.empty()
                      ? "entry-latch-shape"
                      : (Twine("entry-latch-shape;") +
                         MemoryPromotionFailure).str());
  // Whole-function reachability is too broad for an inlined/nested region:
  // Header may reach a later outer path which eventually invokes this region
  // again, without EntryPred belonging to this dispatcher's recurrence.  A
  // genuine inner latch/outer recurrence entry is dominated by Header; an
  // external dynamic seed is not.
  // A PHI seed is an explicit outer recurrence and must still take the nested
  // recovery path even when its outer header is not dominated by the inner
  // dispatcher (the canonical shared-switch shape).
  bool HasExplicitOuterState = isa<PHINode>(InitialStateValue);
  bool DynamicEntryIsOneShot =
      !Initial && !HasExplicitOuterState &&
      !DispatcherDT.dominates(Header, EntryPred);
  auto *EntryBr = dyn_cast<BranchInst>(EntryPred->getTerminator());
  auto *LatchBr = dyn_cast<BranchInst>(Latch->getTerminator());
  if (!EntryBr || !EntryBr->isUnconditional() ||
      EntryBr->getSuccessor(0) != Header || !LatchBr)
    return Reject("entry-latch-branches");

  // A common flattened-loop form reserves one state value for function/loop
  // exit.  The latch tests that exact value and returns to the dispatcher for
  // every other state.  Treat the reserved value as one additional resolved
  // transition target instead of rejecting the whole dispatcher merely
  // because its latch is conditional.
  ConstantInt *TerminalState = nullptr;
  BasicBlock *TerminalTarget = nullptr;
  if (LatchBr->isUnconditional()) {
    if (LatchBr->getSuccessor(0) != Header)
      return Reject("latch-does-not-return-to-header");
  } else {
    unsigned HeaderSuccessor = LatchBr->getSuccessor(0) == Header
                                   ? 0
                                   : LatchBr->getSuccessor(1) == Header ? 1 : 2;
    if (HeaderSuccessor > 1)
      return Reject("conditional-latch-without-header-edge");
    auto *Cmp = dyn_cast<ICmpInst>(LatchBr->getCondition());
    if (!Cmp || !Cmp->isEquality())
      return Reject("unsupported-terminal-latch-condition");
    Value *Other = nullptr;
    if (Cmp->getOperand(0) == LatchState)
      Other = Cmp->getOperand(1);
    else if (Cmp->getOperand(1) == LatchState)
      Other = Cmp->getOperand(0);
    TerminalState = dyn_cast_or_null<ConstantInt>(Other);
    if (!TerminalState)
      return Reject("terminal-latch-state-not-constant");
    bool TrueMeansEqual = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
    unsigned EqualSuccessor = TrueMeansEqual ? 0 : 1;
    if (EqualSuccessor == HeaderSuccessor)
      return Reject("terminal-state-returns-to-dispatcher");
    TerminalTarget = LatchBr->getSuccessor(EqualSuccessor);
    if (TerminalTarget == Header)
      return Reject("terminal-target-is-dispatcher");
  }

  // A shared-switch nested dispatcher feeds the inner header from an outer
  // two-level recurrence.  Record that recurrence now so both levels can be
  // removed in one exact transaction; otherwise demoting only the inner PHIs
  // leaves a memory-form outer dispatcher behind.
  BasicBlock *Outer = nullptr, *OuterEntry = nullptr, *OuterSink = nullptr;
  PHINode *OuterState = nullptr, *OuterSinkState = nullptr;
  Value *OuterSinkStateValue = nullptr;
  ConstantInt *OuterInitial = nullptr;
  SmallVector<PHINode *, 8> OuterPhis, OuterSinkPhis;
  bool HasNestedOuter = false;
  if (!Initial && !DynamicEntryIsOneShot) {
    Outer = EntryPred;
    OuterState = dyn_cast<PHINode>(InitialStateValue);
    if (!OuterState || OuterState->getParent() != Outer ||
        OuterState->getNumIncomingValues() != 2)
      return Reject("nested-outer-state");
    for (unsigned I = 0; I != 2; ++I) {
      Value *V = OuterState->getIncomingValue(I);
      BasicBlock *Pred = OuterState->getIncomingBlock(I);
      if (auto *C = dyn_cast<ConstantInt>(V)) {
        OuterInitial = C;
        OuterEntry = Pred;
      } else if (auto *PN = dyn_cast<PHINode>(V);
                 PN && PN->getParent() == Pred) {
        OuterSinkState = PN;
        OuterSinkStateValue = PN;
        OuterSink = Pred;
      } else if (auto *I = dyn_cast<Instruction>(V);
                 I && I->getParent() == Pred) {
        // Loop rotation can fold the complete outer state funnel into the
        // backedge block itself.  Keep that finite direct value as the sink
        // state; it is proved and rewritten transactionally below.
        OuterSinkStateValue = I;
        OuterSink = Pred;
      }
    }
    auto *OuterEntryBr = OuterEntry
                             ? dyn_cast<BranchInst>(OuterEntry->getTerminator())
                             : nullptr;
    auto *OuterSinkBr = OuterSink
                            ? dyn_cast<BranchInst>(OuterSink->getTerminator())
                            : nullptr;
    if (!OuterInitial || !OuterEntry || !OuterSinkStateValue || !OuterSink ||
        !OuterEntryBr || !OuterEntryBr->isUnconditional() ||
        OuterEntryBr->getSuccessor(0) != Outer || !OuterSinkBr ||
        !OuterSinkBr->isUnconditional() ||
        OuterSinkBr->getSuccessor(0) != Outer)
      return Reject("nested-outer-shape");
    SmallPtrSet<PHINode *, 8> UsedOuterSinkPhis;
    std::function<bool(Value *, SmallPtrSetImpl<Value *> &)> CollectSinkPhis;
    CollectSinkPhis = [&](Value *V, SmallPtrSetImpl<Value *> &Seen) {
      if (!Seen.insert(V).second) return true;
      if (auto *PN = dyn_cast<PHINode>(V)) {
        if (PN->getParent() == OuterSink) UsedOuterSinkPhis.insert(PN);
        return true;
      }
      auto *I = dyn_cast<Instruction>(V);
      if (!I || I->getParent() != OuterSink) return true;
      if (I->isTerminator() || I->mayReadOrWriteMemory() ||
          I->mayHaveSideEffects())
        return false;
      for (Value *Operand : I->operands())
        if (!CollectSinkPhis(Operand, Seen)) return false;
      return true;
    };
    for (PHINode &OuterPhi : Outer->phis()) {
      if (OuterPhi.getNumIncomingValues() != 2 ||
          OuterPhi.getBasicBlockIndex(OuterEntry) < 0 ||
          OuterPhi.getBasicBlockIndex(OuterSink) < 0)
        return Reject("nested-outer-phi-shape");
      Value *SinkValue = OuterPhi.getIncomingValueForBlock(OuterSink);
      if (OuterSinkState) {
        SmallPtrSet<Value *, 16> SeenSinkValues;
        if (!CollectSinkPhis(SinkValue, SeenSinkValues))
          return Reject("nested-outer-phi-pair");
      } else if (auto *SinkI = dyn_cast<Instruction>(SinkValue);
                 SinkI && !DispatcherDT.dominates(
                              SinkI, OuterSink->getTerminator())) {
        // Direct sinks execute in place and therefore may contain real loads
        // and other semantic work.  Only edge availability is required; no
        // body is speculated or cloned.
        return Reject("nested-direct-outer-value-availability");
      }
      OuterPhis.push_back(&OuterPhi);
    }
    if (OuterSinkState) {
      for (PHINode &SinkPhi : OuterSink->phis()) {
        if (!UsedOuterSinkPhis.contains(&SinkPhi))
          return Reject("nested-unpaired-outer-sink-phi");
        OuterSinkPhis.push_back(&SinkPhi);
      }
      if (!UsedOuterSinkPhis.contains(OuterSinkState))
        return Reject("nested-outer-state-not-paired");
    }
    HasNestedOuter = true;
  }

  SmallVector<PHINode *, 8> HeaderPhis;
  SmallVector<PHINode *, 8> LatchPhis;
  SmallPtrSet<PHINode *, 8> UsedLatchPhis;
  std::function<bool(Value *, SmallPtrSetImpl<Value *> &)> CollectLatchPhis;
  CollectLatchPhis = [&](Value *V, SmallPtrSetImpl<Value *> &Seen) {
    if (!Seen.insert(V).second) return true;
    if (auto *PN = dyn_cast<PHINode>(V)) {
      if (PN->getParent() == Latch) UsedLatchPhis.insert(PN);
      return true;
    }
    auto *I = dyn_cast<Instruction>(V);
    if (!I || I->getParent() != Latch) return true;
    // The expression is cloned onto each proved transition edge after its
    // dependent latch PHIs are demoted.  Only side-effect-free SSA plumbing
    // may move this way; memory and poison-sensitive operations fail closed.
    if (I->isTerminator() || I->mayReadOrWriteMemory() ||
        I->mayHaveSideEffects() || hasPoisonGeneratingFlags(I))
      return false;
    for (Value *Operand : I->operands())
      if (!CollectLatchPhis(Operand, Seen)) return false;
    return true;
  };
  for (PHINode &HP : Header->phis()) {
    if (HP.getNumIncomingValues() != 2 ||
        HP.getBasicBlockIndex(EntryPred) < 0 ||
        HP.getBasicBlockIndex(Latch) < 0)
      return Reject("header-phi-shape");
    SmallPtrSet<Value *, 16> SeenLatchValues;
    if (!CollectLatchPhis(HP.getIncomingValueForBlock(Latch),
                          SeenLatchValues))
      return Reject("latch-phi-expression");
    HeaderPhis.push_back(&HP);
  }
  for (PHINode &LP : Latch->phis()) {
    if (!UsedLatchPhis.contains(&LP))
      return Reject("unpaired-latch-phi");
    LatchPhis.push_back(&LP);
  }

  DenseMap<APInt, BasicBlock *> CaseMap;
  DenseMap<APInt, bool> CaseViaDefault;
  SmallPtrSet<BasicBlock *, 32> CaseEntries;
  DenseMap<BasicBlock *, APInt> CaseRawStates;
  DenseMap<BasicBlock *, SmallVector<APInt, 4>> CaseRawStateSets;
  SmallPtrSet<BasicBlock *, 8> AmbiguousCaseRawStates;
  SmallVector<PHINode *, 32> CaseEntryPhis;
  SmallPtrSet<PHINode *, 32> SeenCaseEntryPhis;
  SmallVector<SwitchInst *, 8> LookupSwitches{&SI};
  SmallPtrSet<BasicBlock *, 8> LookupOwners;
  LookupOwners.insert(SI.getParent());
  BasicBlock *LookupCursor = SI.getDefaultDest();
  SmallPtrSet<BasicBlock *, 16> SeenLookupBlocks;
  for (unsigned Depth = 0; Depth != 8 && LookupCursor; ++Depth) {
    if (!SeenLookupBlocks.insert(LookupCursor).second) break;
    if (auto *Shard = dyn_cast<SwitchInst>(LookupCursor->getTerminator())) {
      if (Shard->getCondition() != SI.getCondition()) break;
      bool BodyIsPure = llvm::all_of(*LookupCursor, [&](Instruction &I) {
        return I.isTerminator() || isa<DbgInfoIntrinsic>(I) ||
               (!I.mayReadOrWriteMemory() && !I.mayHaveSideEffects());
      });
      if (!BodyIsPure) break;
      LookupSwitches.push_back(Shard);
      LookupOwners.insert(Shard->getParent());
      LookupCursor = Shard->getDefaultDest();
      continue;
    }
    auto *Guard = dyn_cast<BranchInst>(LookupCursor->getTerminator());
    if (!Guard || !Guard->isConditional()) break;
    BasicBlock *NextShard = nullptr;
    for (BasicBlock *Succ : successors(LookupCursor))
      if (auto *SuccSwitch = dyn_cast<SwitchInst>(Succ->getTerminator());
          SuccSwitch && SuccSwitch->getCondition() == SI.getCondition()) {
        if (NextShard) {
          NextShard = nullptr;
          break;
        }
        NextShard = Succ;
      }
    if (!NextShard) break;
    LookupCursor = NextShard;
  }
  SmallVector<BasicBlock *, 8> AdditionalLookupOwners;
  SmallPtrSet<BasicBlock *, 8> SeenAdditionalLookupOwners;
  for (SwitchInst *Lookup : LookupSwitches) {
    BasicBlock *Owner = Lookup->getParent();
    if (Owner == Header || !SeenAdditionalLookupOwners.insert(Owner).second)
      continue;
    bool Cloneable = llvm::all_of(*Owner, [&](Instruction &I) {
      return I.isTerminator() || isa<DbgInfoIntrinsic>(I) ||
             (!I.mayReadOrWriteMemory() && !I.mayHaveSideEffects() &&
              !hasPoisonGeneratingFlags(&I));
    });
    if (!Cloneable) return Reject("lookup-owner-plumbing-not-cloneable");
    AdditionalLookupOwners.push_back(Owner);
  }
  for (SwitchInst *Lookup : LookupSwitches)
    for (auto Case : Lookup->cases()) {
    APInt Encoded = Case.getCaseValue()->getValue();
    // Lookup shards are evaluated in this exact order.  A repeated key in a
    // later shard is shadowed by the first occurrence; rejecting the whole
    // dispatcher as a non-unique set confuses ordered switch semantics with a
    // mathematical union.  Preserve the first reachable mapping exactly.
    if (CaseMap.count(Encoded)) continue;
    BasicBlock *Target = Case.getCaseSuccessor();
    // A trampoline state may dispatch straight to either recurrence sink.
    // Their PHIs are paired and demoted by the latch/outer-sink machinery;
    // they are not ordinary case-entry PHIs and need no direct switch input.
    if (Target != OuterSink && Target != Latch)
      for (PHINode &TargetPhi : Target->phis()) {
        if (TargetPhi.getBasicBlockIndex(Lookup->getParent()) < 0)
          return Reject((Twine("case-phi-without-dispatch-input:target=") +
                         Target->getName() + ";phi=" + TargetPhi.getName())
                            .str());
        if (SeenCaseEntryPhis.insert(&TargetPhi).second)
          CaseEntryPhis.push_back(&TargetPhi);
      }
    CaseMap[Encoded] = Target;
    CaseViaDefault[Encoded] = Lookup != &SI;
    if (Target != OuterSink && Target != Latch)
      CaseEntries.insert(Target);
    if (auto Raw = decodeStateExpr(SI.getCondition(), State, Encoded)) {
      auto &RawSet = CaseRawStateSets[Target];
      if (!llvm::is_contained(RawSet, *Raw)) RawSet.push_back(*Raw);
      auto It = CaseRawStates.find(Target);
      if (It == CaseRawStates.end())
        CaseRawStates.try_emplace(Target, *Raw);
      else if (It->second != *Raw)
        AmbiguousCaseRawStates.insert(Target);
    }
  }
  // Loop rotation frequently peels one equality state in the PHI header and
  // sends every unequal value to the first switch shard.  Register that exact
  // equality as the first ordered lookup case; otherwise the true initial
  // state appears absent from the shard's case table.
  if (SwitchBlock != Header) {
    auto *HeaderBr = dyn_cast<BranchInst>(Header->getTerminator());
    auto *HeaderCmp = HeaderBr && HeaderBr->isConditional()
                          ? dyn_cast<ICmpInst>(HeaderBr->getCondition())
                          : nullptr;
    if (HeaderCmp && HeaderCmp->isEquality()) {
      ConstantInt *ComparedConstant = nullptr;
      Value *ComparedExpr = nullptr;
      if ((ComparedConstant = dyn_cast<ConstantInt>(HeaderCmp->getOperand(0))))
        ComparedExpr = HeaderCmp->getOperand(1);
      else if ((ComparedConstant =
                    dyn_cast<ConstantInt>(HeaderCmp->getOperand(1))))
        ComparedExpr = HeaderCmp->getOperand(0);
      std::optional<APInt> PeeledRaw;
      if (ComparedConstant && ComparedExpr == State)
        PeeledRaw = ComparedConstant->getValue();
      else if (ComparedConstant && ComparedExpr)
        PeeledRaw = decodeStateExpr(ComparedExpr, State,
                                    ComparedConstant->getValue());
      if (PeeledRaw) {
        unsigned EqualSuccessor =
            HeaderCmp->getPredicate() == ICmpInst::ICMP_EQ ? 0 : 1;
        BasicBlock *EqualTarget = HeaderBr->getSuccessor(EqualSuccessor);
        BasicBlock *UnequalTarget = HeaderBr->getSuccessor(1 - EqualSuccessor);
        if (UnequalTarget == SwitchBlock && EqualTarget != Header &&
            EqualTarget != Latch) {
          auto Encoded = evalStateExpr(SI.getCondition(), State, *PeeledRaw);
          if (Encoded) {
            for (PHINode &TargetPhi : EqualTarget->phis()) {
              if (TargetPhi.getBasicBlockIndex(Header) < 0)
                return Reject(
                    (Twine("peeled-case-phi-without-header-input:target=") +
                     EqualTarget->getName() + ";phi=" +
                     TargetPhi.getName())
                        .str());
              if (SeenCaseEntryPhis.insert(&TargetPhi).second)
                CaseEntryPhis.push_back(&TargetPhi);
            }
            CaseMap[*Encoded] = EqualTarget;
            CaseViaDefault[*Encoded] = false;
            CaseEntries.insert(EqualTarget);
            auto &RawSet = CaseRawStateSets[EqualTarget];
            if (!llvm::is_contained(RawSet, *PeeledRaw))
              RawSet.push_back(*PeeledRaw);
            CaseRawStates.erase(EqualTarget);
            CaseRawStates.try_emplace(EqualTarget, *PeeledRaw);
          }
        }
      }
    }
  }
  for (BasicBlock *Target : AmbiguousCaseRawStates)
    CaseRawStates.erase(Target);
  if (CaseMap.size() < 4) return Reject("case-map");

  // A pure, side-effect-free conditional default (an affine equality "peel"
  // guard) is not a case body: the resolver clones it and routes each state to
  // its exact guard successor.  Registering that guard as a case entry would
  // demand it be a unique returning root, which it is not -- it falls through
  // into a shared case tail.  Classify it as cloneable plumbing here so the
  // resolver, not the structural case-entry contract, proves the default edge.
  BasicBlock *DefaultGuard = SI.getDefaultDest();
  auto *DefaultGuardBr = dyn_cast<BranchInst>(DefaultGuard->getTerminator());
  bool DefaultGuardCloneable =
      DefaultGuardBr && DefaultGuardBr->isConditional() &&
      DefaultGuard->phis().empty() &&
      llvm::all_of(*DefaultGuard, [&](Instruction &I) {
        return &I == DefaultGuardBr || isa<DbgInfoIntrinsic>(I) ||
               (!I.mayReadOrWriteMemory() && !I.mayHaveSideEffects());
      });

  // With one lookup switch, its unmatched destination can be a real
  // initialization/case body rather than a pure comparison shard.  Preserve
  // that body as an explicit case entry; switch semantics prove it is the
  // exact target for every state absent from the case table.  Multi-shard
  // lookup chains stay on the ordered resolver path above.
  BasicBlock *DirectDefaultTarget = nullptr;
  if (LookupSwitches.size() == 1 && !DefaultGuardCloneable) {
    BasicBlock *Target = SI.getDefaultDest();
    // A memory-form mirror dispatcher commonly occupies the unmatched edge
    // and cycles locally while reloading the same state.  It is fallback
    // lookup plumbing, not a semantic default case.  Exclude any local cycle
    // proved without crossing this dispatcher's header/latch; resolution will
    // still fail closed if a reachable state actually needs that default.
    bool HasLocalDefaultCycle = false;
    bool HasDefaultSelfLoop = false;
    SmallVector<BasicBlock *, 16> DefaultWork;
    SmallPtrSet<BasicBlock *, 32> SeenDefault;
    for (BasicBlock *Succ : successors(Target)) {
      if (Succ == Target) {
        HasLocalDefaultCycle = true;
        HasDefaultSelfLoop = true;
      }
      else if (Succ != Header && Succ != Latch) DefaultWork.push_back(Succ);
    }
    while (!HasLocalDefaultCycle && !DefaultWork.empty()) {
      BasicBlock *BB = DefaultWork.pop_back_val();
      if (!SeenDefault.insert(BB).second) continue;
      for (BasicBlock *Succ : successors(BB)) {
        if (Succ == Target) {
          HasLocalDefaultCycle = true;
          break;
        }
        if (Succ != Header && Succ != Latch) DefaultWork.push_back(Succ);
      }
    }
    if (HasDefaultSelfLoop && llvm::all_of(predecessors(Target),
                                           [&](BasicBlock *Pred) {
                                             return Pred == Header ||
                                                    Pred == Target;
                                           }))
      // A self-looping unmatched dispatcher with no independent predecessor
      // is owned lookup plumbing.  Its edges cannot enter a pruned case once
      // the proved primary transition closure makes the default unreachable.
      LookupOwners.insert(Target);
    if (!HasLocalDefaultCycle && Target != OuterSink && Target != Latch) {
      for (PHINode &TargetPhi : Target->phis()) {
        if (TargetPhi.getBasicBlockIndex(SI.getParent()) < 0)
          return Reject(
              (Twine("default-case-phi-without-dispatch-input:target=") +
               Target->getName() + ";phi=" + TargetPhi.getName())
                  .str());
        if (SeenCaseEntryPhis.insert(&TargetPhi).second)
          CaseEntryPhis.push_back(&TargetPhi);
      }
      CaseEntries.insert(Target);
      DirectDefaultTarget = Target;
    }
  }

  // A case may contain internal branches (for example a checked libc call)
  // before reaching the latch.  Classify each latch predecessor by walking
  // backward to one unique switch case entry.  The default predecessor has no
  // such root and is intentionally excluded.
  SmallVector<BasicBlock *, 32> ReturningCases;
  SmallPtrSet<BasicBlock *, 32> ReturningRoots;
  DenseMap<BasicBlock *, APInt> ReturningRawStates;
  DenseMap<BasicBlock *, SmallVector<APInt, 4>> ReturningRawStateSets;
  DenseMap<BasicBlock *, BasicBlock *> ReturningRootBySource;
  SmallPtrSet<BasicBlock *, 8> SourcesWithUnknownRawRoots;
  bool HasAmbiguousReturningRoots = false;
  for (BasicBlock *Source : predecessors(Latch)) {
    SmallVector<BasicBlock *, 16> Work{Source};
    SmallPtrSet<BasicBlock *, 32> Seen;
    SmallPtrSet<BasicBlock *, 4> Roots;
    while (!Work.empty() && Seen.size() <= 64) {
      BasicBlock *BB = Work.pop_back_val();
      if (!Seen.insert(BB).second) continue;
      if (CaseEntries.contains(BB)) {
        Roots.insert(BB);
        continue;
      }
      if (BB == Header || BB == Latch) continue;
      for (BasicBlock *Pred : predecessors(BB)) Work.push_back(Pred);
    }
    if (Roots.empty()) continue;
    ReturningCases.push_back(Source);
    auto &RawSet = ReturningRawStateSets[Source];
    bool AllRootsDecoded = true;
    for (BasicBlock *Root : Roots) {
      ReturningRoots.insert(Root);
      auto It = CaseRawStateSets.find(Root);
      if (It == CaseRawStateSets.end() || It->second.empty()) {
        AllRootsDecoded = false;
        continue;
      }
      for (const APInt &Raw : It->second)
        if (!llvm::is_contained(RawSet, Raw)) RawSet.push_back(Raw);
    }
    if (Roots.size() == 1) {
      BasicBlock *Root = *Roots.begin();
      ReturningRootBySource[Source] = Root;
      if (RawSet.size() == 1)
        ReturningRawStates.try_emplace(Source, RawSet.front());
      else if (!RawSet.empty())
        HasAmbiguousReturningRoots = true;
      // An unmatched default root has no decoded raw state.  That is unknown,
      // not ambiguous: with a concrete seed it may still be excluded by the
      // closed transition induction below.  If any reachable transition does
      // resolve to this root, its missing proof is demanded and rejects the
      // transaction.  Dynamic seeds still take the exhaustive path.
    } else {
      // Shared case tails are normal after SimplifyCFG.  Their source PHI is
      // proved against the union of every incoming raw state below, and seed
      // pruning is disabled in favour of an exhaustive transition proof.
      HasAmbiguousReturningRoots = true;
    }
    if (!AllRootsDecoded) SourcesWithUnknownRawRoots.insert(Source);
  }
  if (ReturningCases.empty()) return Reject("no-returning-cases");
  // Whole-function reachability is too broad here: a genuine nested-CFF exit
  // can reach this header again only after returning to an outer dispatcher
  // and starting a later invocation.  It is a returning case for this loop
  // only when it reaches the latch without first crossing the header.
  auto CollectForwardedCaseEntries = [&](BasicBlock *Start,
                                         SmallVectorImpl<BasicBlock *> &Out) {
    if (DispatcherLoop && !DispatcherLoop->contains(Start)) return true;
    SmallVector<BasicBlock *, 32> Work{Start};
    SmallPtrSet<BasicBlock *, 32> Seen;
    while (!Work.empty() && Seen.size() <= 128) {
      BasicBlock *BB = Work.pop_back_val();
      if (!Seen.insert(BB).second) continue;
      // A switch case may be a semantic prefix for another case.  Stop at the
      // second case entry: its own complete transition proof owns everything
      // from there to the latch.  Treating the prefix as another latch root
      // both double-counts that transition and rejects valid case-to-case
      // lowering produced by SimplifyCFG.
      if (BB != Start && CaseEntries.contains(BB)) {
        if (!llvm::is_contained(Out, BB)) Out.push_back(BB);
        continue;
      }
      for (BasicBlock *Succ : successors(BB)) {
        if (Succ != Header && Succ != Latch &&
            (!DispatcherLoop || DispatcherLoop->contains(Succ)))
          Work.push_back(Succ);
      }
    }
    return Seen.size() <= 128;
  };
  auto ReachesLatchLocally = [&](BasicBlock *Start) {
    if (DispatcherLoop && !DispatcherLoop->contains(Start)) return false;
    SmallVector<BasicBlock *, 32> Work{Start};
    SmallPtrSet<BasicBlock *, 32> Seen;
    while (!Work.empty() && Seen.size() <= 128) {
      BasicBlock *BB = Work.pop_back_val();
      if (!Seen.insert(BB).second) continue;
      if (BB != Start && CaseEntries.contains(BB)) continue;
      for (BasicBlock *Succ : successors(BB)) {
        if (Succ == Latch) return true;
        if (Succ != Header &&
            (!DispatcherLoop || DispatcherLoop->contains(Succ)))
          Work.push_back(Succ);
      }
    }
    return false;
  };
  for (BasicBlock *CaseEntry : CaseEntries) {
    if (ReturningRoots.contains(CaseEntry)) continue;
    if (ReachesLatchLocally(CaseEntry))
      return Reject((Twine("unclassified-returning-case:case=") +
                     CaseEntry->getName() +
                     ";reason=reaches-latch-without-unique-case-root")
                        .str());
  }
  for (PHINode *LP : LatchPhis)
    for (BasicBlock *CaseBB : ReturningCases)
      if (LP->getBasicBlockIndex(CaseBB) < 0) return Reject("latch-input");

  struct ResolvedDirectPath {
    BasicBlock *Target = nullptr;
    bool ViaDefault = false;
  };
  std::function<ResolvedDirectPath(const APInt &, unsigned)> ResolveRawImpl;
  ResolveRawImpl = [&](const APInt &Raw,
                       unsigned Depth) -> ResolvedDirectPath {
    if (Depth > 8) return {};
    if (TerminalState && Raw == TerminalState->getValue())
      return {TerminalTarget, false};
    auto Encoded = evalStateExpr(SI.getCondition(), State, Raw);
    if (!Encoded) return {};
    auto It = CaseMap.find(*Encoded);
    if (It == CaseMap.end()) {
      if (!DefaultGuardCloneable)
        return DirectDefaultTarget
                   ? ResolvedDirectPath{DirectDefaultTarget, false}
                   : ResolvedDirectPath{};
      auto Taken = evalStatePredicate(DefaultGuardBr->getCondition(), State,
                                      Raw, 0);
      if (!Taken) return {};
      return {DefaultGuardBr->getSuccessor(*Taken ? 0 : 1), true};
    }
    BasicBlock *Target = It->second;
    // Optimizers often retain a dispatcher-owned trampoline case whose only
    // effect is to feed one exact constant into the latch PHI.  Resolve that
    // state transitively; otherwise a nominally complete rewrite leaves the
    // lookup cycle reachable through the trampoline.
    if (Target == Latch) {
      int Index = LatchState->getBasicBlockIndex(SwitchBlock);
      if (Index < 0) return {};
      ConstantInt *Next = asTransitionConstant(
          LatchState->getIncomingValue(Index), SwitchBlock);
      if (!Next || Next->getValue() == Raw) return {};
      return ResolveRawImpl(Next->getValue(), Depth + 1);
    }
    return {Target, CaseViaDefault.lookup(*Encoded)};
  };
  auto ResolveRaw = [&](const APInt &Raw) -> ResolvedDirectPath {
    return ResolveRawImpl(Raw, 0);
  };
  auto Resolve = [&](ConstantInt *Raw) -> ResolvedDirectPath {
    return ResolveRaw(Raw->getValue());
  };
  ResolvedDirectPath InitialPath = Initial ? Resolve(Initial)
                                           : ResolvedDirectPath{};
  BasicBlock *InitialTarget = InitialPath.Target;
  if (Initial && !InitialTarget) return Reject("initial-target");

  struct TransitionCandidate {
    BasicBlock *Root = nullptr;
    BasicBlock *Source = nullptr;
    std::optional<ProvenTransition> Transition;
  };
  SmallVector<TransitionCandidate, 32> TransitionCandidates;
  for (BasicBlock *CaseBB : ReturningCases) {
    int Index = LatchState->getBasicBlockIndex(CaseBB);
    if (Index < 0) return Reject("state-latch-input");
    Value *Next = LatchState->getIncomingValue(Index);
    auto RawIt = ReturningRawStates.find(CaseBB);
    std::function<std::optional<APInt>(Value *, unsigned)> EvaluateAtCaseState;
    EvaluateAtCaseState = [&](Value *V,
                              unsigned Depth) -> std::optional<APInt> {
      if (Depth > 8 || !V->getType()->isIntegerTy()) return std::nullopt;
      // A shared semantic tail can be reached from several dispatcher cases,
      // so it has no single entry-state binding.  Its transition arms are
      // nevertheless often state-independent constants (or constant-foldable
      // expressions).  Prove that fact directly before requiring a raw-state
      // specialization.  Evaluation with a null state root cannot accidentally
      // consume the dispatcher PHI: any such dependency fails closed.
      APInt Dummy(V->getType()->getIntegerBitWidth(), 0);
      if (auto Independent = evalTransitionExpr(V, nullptr, Dummy))
        return Independent;
      if (RawIt == ReturningRawStates.end()) return std::nullopt;
      if (auto Result = evalStateExpr(V, State, RawIt->second)) return Result;
      auto *LI = dyn_cast<LoadInst>(V);
      if (!LI) return std::nullopt;
      bool HitBarrier = false;
      StoreInst *Store = findReachingStateStore(
          CaseBB, LI->getPointerOperand(), LI->getType(), Header, 0,
          &HitBarrier);
      if (!Store || HitBarrier || Store->isAtomic() || Store->isVolatile() ||
          Store->getValueOperand()->getType() != LI->getType())
        return std::nullopt;
      return EvaluateAtCaseState(Store->getValueOperand(), Depth + 1);
    };
    ProvenTransition T;
    T.Source = CaseBB;
    bool Proved = true;
    if (auto *C = asTransitionConstant(Next, CaseBB)) {
      ResolvedDirectPath Path = Resolve(C);
      T.TrueTarget = Path.Target;
      T.TrueViaDefault = Path.ViaDefault;
    } else if (auto *Sel = dyn_cast<SelectInst>(Next)) {
      // This select is the state update on CaseBB's edge into the latch.  It
      // normally lives in CaseBB, but the next state is frequently computed in
      // a block that dominates CaseBB -- the returning root, a side-effect
      // continuation between the root and CaseBB, or the loop preheader/entry
      // where an entry-dependent state seed is chosen once.  In every such case
      // the select's condition dominates CaseBB, so the direct conditional edge
      // inserted at CaseBB reuses it as exact IR.  A select in the dispatcher
      // header itself is still rejected: that block carries the loop-carried
      // dispatch-state PHI and is re-evaluated every iteration, so its decision
      // is dispatcher logic, not a single case-local state update.
      BasicBlock *SelBB = Sel->getParent();
      bool SelUsable =
          SelBB == CaseBB ||
          (SelBB != Header && DispatcherDT.dominates(SelBB, CaseBB));
      if (!SelUsable) {
        Proved = false;
      } else {
        auto TrueRaw = EvaluateAtCaseState(Sel->getTrueValue(), 0);
        auto FalseRaw = EvaluateAtCaseState(Sel->getFalseValue(), 0);
        if (!TrueRaw || !FalseRaw) {
          Proved = false;
        } else {
          T.Selector = Sel;
          T.Condition = Sel->getCondition();
          ResolvedDirectPath TruePath = ResolveRaw(*TrueRaw);
          ResolvedDirectPath FalsePath = ResolveRaw(*FalseRaw);
          T.TrueTarget = TruePath.Target;
          T.TrueViaDefault = TruePath.ViaDefault;
          T.FalseTarget = FalsePath.Target;
          T.FalseViaDefault = FalsePath.ViaDefault;
        }
      }
    } else if (auto Specialized = EvaluateAtCaseState(Next, 0)) {
      ResolvedDirectPath Path = ResolveRaw(*Specialized);
      T.TrueTarget = Path.Target;
      T.TrueViaDefault = Path.ViaDefault;
    } else {
      // A case-local PHI/select can encode more than two next states.  Prove
      // its complete acyclic value set structurally, then replace the loop
      // dispatcher with one direct finite switch at the transition source.
      // Unsupported values, cycles, poison-generating operations, loads that
      // cannot be evaluated, and outcome explosion all fail closed.
      SmallVector<APInt, 8> FiniteValues;
      DenseMap<const Value *, APInt> NoBindings;
      // Shared tails require one bounded proof per incoming arm/raw-state
      // pair.  This is an instruction-visit budget, not a solver timeout.
      unsigned ExecutionBudget = 2048;
      Value *FiniteExpr = Next;
      if (auto *LI = dyn_cast<LoadInst>(Next)) {
        bool HitBarrier = false;
        if (StoreInst *Store = findReachingStateStore(
                CaseBB, LI->getPointerOperand(), LI->getType(), Header, 0,
                &HitBarrier);
            Store && !HitBarrier && !Store->isAtomic() &&
            !Store->isVolatile() &&
            Store->getValueOperand()->getType() == LI->getType())
          FiniteExpr = Store->getValueOperand();
      }
      bool Finite = false;
      auto StateSetIt = ReturningRawStateSets.find(CaseBB);
      if (SourcesWithUnknownRawRoots.contains(CaseBB)) {
        // A shared tail can merge explicit switch cases with the unmatched
        // default.  Prove each source-PHI arm using only the raw states of the
        // case roots that can actually reach that incoming edge.  An arm fed
        // by an unbounded default is accepted only when it is independently
        // finite without binding the dispatcher state.
        auto *SourcePhi = dyn_cast<PHINode>(FiniteExpr);
        Finite = SourcePhi && SourcePhi->getParent() == CaseBB;
        for (unsigned ArmIndex = 0;
             Finite && ArmIndex != SourcePhi->getNumIncomingValues();
             ++ArmIndex) {
          BasicBlock *ArmPred = SourcePhi->getIncomingBlock(ArmIndex);
          SmallVector<BasicBlock *, 16> RootWork{ArmPred};
          SmallPtrSet<BasicBlock *, 32> SeenArm;
          SmallPtrSet<BasicBlock *, 8> ArmRoots;
          while (!RootWork.empty()) {
            BasicBlock *BB = RootWork.pop_back_val();
            if (!SeenArm.insert(BB).second) continue;
            if (CaseEntries.contains(BB)) {
              ArmRoots.insert(BB);
              continue;
            }
            if (BB == Header || BB == Latch || BB == CaseBB) continue;
            for (BasicBlock *Pred : predecessors(BB))
              RootWork.push_back(Pred);
          }
          if (ArmRoots.empty()) {
            Finite = false;
            break;
          }
          SmallVector<APInt, 8> ArmRawStates;
          bool HasUnknownRoot = false;
          for (BasicBlock *Root : ArmRoots) {
            auto It = CaseRawStateSets.find(Root);
            if (It == CaseRawStateSets.end() || It->second.empty()) {
              HasUnknownRoot = true;
              continue;
            }
            for (const APInt &Raw : It->second)
              if (!llvm::is_contained(ArmRawStates, Raw))
                ArmRawStates.push_back(Raw);
          }
          Value *Arm = SourcePhi->getIncomingValue(ArmIndex);
          if (HasUnknownRoot) {
            APInt Dummy(Arm->getType()->getIntegerBitWidth(), 0);
            if (!enumerateTransitionValues(
                    Arm, nullptr, Dummy, NoBindings, FiniteValues,
                    ExecutionBudget)) {
              Finite = false;
            }
          } else {
            if (ArmRawStates.empty()) Finite = false;
            for (const APInt &EntryRaw : ArmRawStates)
              if (Finite && !enumerateTransitionValues(
                                Arm, State, EntryRaw, NoBindings,
                                FiniteValues, ExecutionBudget)) {
                Finite = false;
              }
          }
        }
        Finite &= !FiniteValues.empty();
      } else if (StateSetIt != ReturningRawStateSets.end() &&
          !StateSetIt->second.empty()) {
        Finite = true;
        for (const APInt &EntryRaw : StateSetIt->second)
          if (!enumerateTransitionValues(
                  FiniteExpr, State, EntryRaw, NoBindings, FiniteValues,
                  ExecutionBudget)) {
            Finite = false;
            break;
          }
        Finite &= !FiniteValues.empty();
      }
      if (Finite) {
        for (const APInt &Raw : FiniteValues) {
          ResolvedDirectPath Path = ResolveRaw(Raw);
          if (!Path.Target) {
            Finite = false;
            break;
          }
          T.FiniteTargets.push_back(Path.Target);
          T.FiniteViaDefault.push_back(Path.ViaDefault);
        }
      }
      if (Finite) {
        T.FiniteState = FiniteExpr;
        T.FiniteRawValues = std::move(FiniteValues);
        T.TrueTarget = T.FiniteTargets.front();
      } else {
        Proved = false;
      }
    }
    if (!T.TrueTarget || (T.Condition && !T.FalseTarget))
      Proved = false;
    TransitionCandidate Candidate;
    Candidate.Root = ReturningRootBySource.lookup(CaseBB);
    Candidate.Source = CaseBB;
    if (Proved) Candidate.Transition = T;
    TransitionCandidates.push_back(std::move(Candidate));
  }

  // Prove the transition closure from the actual seed instead of demanding
  // transitions for syntactically present but unreachable bogus cases.  CFF
  // routinely contains dead switch entries whose next state intentionally
  // falls into the default cycle.  They are removable only when induction
  // from the seed never reaches their case root.  Dynamic/nested seeds cannot
  // establish that base case and therefore retain the exhaustive requirement.
  SmallVector<ProvenTransition, 32> Transitions;
  bool ReachabilityPruned = false;
  std::function<bool(BasicBlock *, unsigned,
                     SmallPtrSetImpl<BasicBlock *> &)>
      IsOwnedLookupPlumbing;
  IsOwnedLookupPlumbing =
      [&](BasicBlock *BB, unsigned Depth,
          SmallPtrSetImpl<BasicBlock *> &Active) -> bool {
    if (LookupOwners.contains(BB)) return true;
    if (Depth > 8 || !Active.insert(BB).second || BB->phis().begin() !=
                                                        BB->phis().end())
      return false;
    bool Transparent = llvm::all_of(*BB, [&](Instruction &I) {
      return I.isTerminator() || isa<DbgInfoIntrinsic>(I);
    });
    if (!Transparent || pred_empty(BB)) {
      Active.erase(BB);
      return false;
    }
    for (BasicBlock *Pred : predecessors(BB))
      if (!IsOwnedLookupPlumbing(Pred, Depth + 1, Active)) {
        Active.erase(BB);
        return false;
      }
    Active.erase(BB);
    return true;
  };
  if (Initial && !HasAmbiguousReturningRoots) {
    SmallVector<BasicBlock *, 32> Work;
    SmallPtrSet<BasicBlock *, 32> ReachableRoots;
    if (CaseEntries.contains(InitialTarget)) Work.push_back(InitialTarget);
    while (!Work.empty()) {
      BasicBlock *Root = Work.pop_back_val();
      if (!ReachableRoots.insert(Root).second) continue;
      if (ReachableRoots.size() > CaseEntries.size())
        return Reject("reachable-transition-closure-overflow");
      SmallVector<BasicBlock *, 4> ForwardedRoots;
      if (!CollectForwardedCaseEntries(Root, ForwardedRoots))
        return Reject("case-forwarding-closure-overflow");
      Work.append(ForwardedRoots.begin(), ForwardedRoots.end());
      for (const TransitionCandidate &Candidate : TransitionCandidates) {
        if (Candidate.Root != Root) continue;
        if (!Candidate.Transition)
          return Reject((Twine("reachable-unproved-transition:") +
                         Candidate.Source->getName()).str());
        const ProvenTransition &T = *Candidate.Transition;
        Transitions.push_back(T);
        if (CaseEntries.contains(T.TrueTarget)) Work.push_back(T.TrueTarget);
        if (T.FalseTarget && CaseEntries.contains(T.FalseTarget))
          Work.push_back(T.FalseTarget);
        for (BasicBlock *Target : T.FiniteTargets)
          if (CaseEntries.contains(Target)) Work.push_back(Target);
      }
    }
    // Seed induction is a closed-world argument only for roots it intends to
    // prune.  A supposedly unreachable root with an external predecessor can
    // be entered without following the dispatcher recurrence.  Reachable
    // roots may legitimately be shared with another proved nested path.
    for (BasicBlock *CaseEntry : CaseEntries) {
      if (ReachableRoots.contains(CaseEntry)) continue;
      for (BasicBlock *Pred : predecessors(CaseEntry))
        // The switch can live in a semantic-free shard immediately after the
        // state-PHI header.  An edge from that shard is still dispatcher
        // lookup plumbing, not an independent external entry into the case.
        if (Pred != Header) {
          // Edges among roots that are all outside the seed-reachable closure
          // do not create an independent entry.  Every such root is audited
          // by this same loop, so any genuinely external predecessor still
          // rejects the transaction.
          if (CaseEntries.contains(Pred) &&
              !ReachableRoots.contains(Pred))
            continue;
          SmallPtrSet<BasicBlock *, 16> ActiveOwned;
          if (IsOwnedLookupPlumbing(Pred, 0, ActiveOwned)) continue;
          return Reject((Twine("seed-induction-external-case-entry:case=") +
                         CaseEntry->getName() + ";pred=" + Pred->getName())
                            .str());
        }
    }
    ReachabilityPruned =
        Transitions.size() != TransitionCandidates.size();
  } else {
    for (const TransitionCandidate &Candidate : TransitionCandidates) {
      if (!Candidate.Transition)
        return Reject((Twine("dynamic-entry-unproved-transition:") +
                       Candidate.Source->getName()).str());
      Transitions.push_back(*Candidate.Transition);
    }
  }
  if (Transitions.empty() && CaseEntries.contains(InitialTarget))
    return Reject("reachable-case-without-transition");

  SmallVector<ProvenTransition, 8> OuterTransitions;
  std::optional<ProvenTransition> HeaderTrampolineTransition;
  auto BuildOuterTransition = [&](BasicBlock *Source,
                                  Value *Raw) -> std::optional<ProvenTransition> {
    ProvenTransition T;
    T.Source = Source;
    if (auto *C = asTransitionConstant(Raw, Source)) {
      ResolvedDirectPath Path = Resolve(C);
      T.TrueTarget = Path.Target;
      T.TrueViaDefault = Path.ViaDefault;
    } else if (auto *Sel = dyn_cast<SelectInst>(Raw)) {
      if (Sel->getParent() != Source) return std::nullopt;
      auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
      if (!TC || !FC) return std::nullopt;
      T.Selector = Sel;
      T.Condition = Sel->getCondition();
      ResolvedDirectPath TruePath = Resolve(TC);
      ResolvedDirectPath FalsePath = Resolve(FC);
      T.TrueTarget = TruePath.Target;
      T.TrueViaDefault = TruePath.ViaDefault;
      T.FalseTarget = FalsePath.Target;
      T.FalseViaDefault = FalsePath.ViaDefault;
    } else {
      // Outer cleanup frequently folds several case tails through another
      // PHI/select funnel before the recurrence sink.  Enumerate that complete
      // acyclic value graph instead of requiring the join itself to be a
      // select.  The enumerator visits every PHI/select arm and fails closed
      // on cycles, unsupported expressions, or outcome explosion.
      if (!Raw->getType()->isIntegerTy()) return std::nullopt;
      SmallVector<APInt, 8> Values;
      DenseMap<const Value *, APInt> Bindings;
      unsigned Budget = 512;
      APInt DummyState(Raw->getType()->getIntegerBitWidth(), 0);
      if (!enumerateTransitionValues(Raw, nullptr, DummyState, Bindings,
                                     Values, Budget) ||
          Values.empty())
        return std::nullopt;
      T.FiniteState = Raw;
      for (const APInt &Value : Values) {
        ResolvedDirectPath Path = ResolveRaw(Value);
        if (!Path.Target || Path.Target == OuterSink) return std::nullopt;
        T.FiniteRawValues.push_back(Value);
        T.FiniteTargets.push_back(Path.Target);
        T.FiniteViaDefault.push_back(Path.ViaDefault);
      }
      T.TrueTarget = T.FiniteTargets.front();
      T.TrueViaDefault = T.FiniteViaDefault.front();
    }
    // A second trip through the outer sink would require another dispatcher
    // round.  The supported nested form has one header-owned trampoline and
    // all actual outer sources resolve directly to real case entries.
    if (!T.TrueTarget || T.TrueTarget == OuterSink ||
        (T.Condition && (!T.FalseTarget || T.FalseTarget == OuterSink)))
      return std::nullopt;
    return T;
  };
  if (HasNestedOuter) {
    ResolvedDirectPath OuterInitialPath = Resolve(OuterInitial);
    BasicBlock *OuterInitialTarget = OuterInitialPath.Target;
    if (!OuterInitialTarget ||
        (OuterInitialTarget == OuterSink && OuterSinkState))
      return Reject("nested-initial-target");
    // Reuse InitialTarget for the outer function-entry bypass.
    InitialTarget = OuterInitialTarget;
    InitialPath = OuterInitialPath;
    if (OuterSinkState) {
      int HeaderIndex = OuterSinkState->getBasicBlockIndex(Header);
      if (HeaderIndex >= 0) {
        HeaderTrampolineTransition = BuildOuterTransition(
            Header, OuterSinkState->getIncomingValue(HeaderIndex));
        if (!HeaderTrampolineTransition)
          return Reject("nested-header-trampoline-transition");
      }
    }
    bool InnerTargetsOuterSink = llvm::any_of(
        Transitions, [&](const ProvenTransition &T) {
          if (T.TrueTarget == OuterSink || T.FalseTarget == OuterSink)
            return true;
          return llvm::is_contained(T.FiniteTargets, OuterSink);
        });
    if (InnerTargetsOuterSink && !HeaderTrampolineTransition &&
        OuterSinkState)
      return Reject("nested-outer-sink-without-trampoline-input");
    if (!OuterSinkState) {
      auto Transition = BuildOuterTransition(OuterSink, OuterSinkStateValue);
      if (!Transition)
        return Reject((Twine("nested-direct-outer-transition:source=") +
                       OuterSink->getName() + ";raw=" +
                       valueText(*OuterSinkStateValue))
                          .str());
      OuterTransitions.push_back(*Transition);
    } else {
      for (BasicBlock *Source : predecessors(OuterSink)) {
        if (Source == Header) continue;
        auto *Br = dyn_cast<BranchInst>(Source->getTerminator());
        int Index = OuterSinkState->getBasicBlockIndex(Source);
        if (!Br || !Br->isUnconditional() ||
            Br->getSuccessor(0) != OuterSink || Index < 0)
          return Reject("nested-outer-source-shape");
        auto Transition = BuildOuterTransition(
            Source, OuterSinkState->getIncomingValue(Index));
        if (!Transition)
          return Reject((Twine("nested-outer-transition:source=") +
                         Source->getName() + ";raw=" +
                         valueText(*OuterSinkState->getIncomingValue(Index)))
                            .str());
        OuterTransitions.push_back(*Transition);
      }
    }
    if (OuterTransitions.empty()) return Reject("nested-no-outer-transitions");
  }

  std::string OldFunctionText = valueText(*F);
  std::string TransitionCertificate;
  raw_string_ostream CertificateOS(TransitionCertificate);
  if (Initial)
    CertificateOS << "entry:" << Initial->getValue() << "->"
                  << valueName(*InitialTarget) << '\n';
  else
    CertificateOS << "entry:dynamic->retained_exact_switch\n";
  for (const ProvenTransition &T : Transitions) {
    CertificateOS << valueName(*T.Source) << "->"
                  << valueName(*T.TrueTarget);
    if (T.FalseTarget) CertificateOS << "," << valueName(*T.FalseTarget);
    CertificateOS << '\n';
  }
  CertificateOS.flush();

  // All structural and transition checks completed.  From this point every
  // mutation is an exact LLVM utility lowering or a clone of executed IR.
  Instruction *AllocaPoint = &*F->getEntryBlock().getFirstInsertionPt();
  // A switch case can enter a semantic join PHI.  Demoting that PHI inserts
  // its dispatcher-edge store in HeaderBody; cloning HeaderBody on every
  // proved edge preserves the exact incoming value, while stores for
  // non-selected targets touch only private allocas and are unobservable.
  for (PHINode *CasePhi : CaseEntryPhis)
    DemotePHIToStack(CasePhi, AllocaPoint->getIterator());
  for (PHINode *SinkPhi : OuterSinkPhis)
    DemotePHIToStack(SinkPhi, AllocaPoint->getIterator());
  for (PHINode *OuterPhi : OuterPhis)
    DemotePHIToStack(OuterPhi, AllocaPoint->getIterator());
  for (PHINode *LP : LatchPhis)
    DemotePHIToStack(LP, AllocaPoint->getIterator());
  for (PHINode *HP : HeaderPhis)
    DemotePHIToStack(HP, AllocaPoint->getIterator());
  // A split lookup owner can itself retain loop-carried PHIs (for example an
  // accumulator updated on its unmatched self-edge).  Raw cloning would place
  // those PHIs in arbitrary transition blocks with stale incoming blocks.
  // Demote them first so the cloned owner body consists only of ordinary
  // loads/computations/stores and reproduces the exact edge semantics.
  for (BasicBlock *Owner : AdditionalLookupOwners) {
    SmallVector<PHINode *, 8> OwnerPhis;
    for (PHINode &PN : Owner->phis()) OwnerPhis.push_back(&PN);
    for (PHINode *PN : OwnerPhis)
      DemotePHIToStack(PN, AllocaPoint->getIterator());
  }

  for (BasicBlock *Owner : AdditionalLookupOwners) {
    SmallVector<Instruction *, 16> OwnerBeforeDemotion;
    for (Instruction &I : *Owner)
      if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
        OwnerBeforeDemotion.push_back(&I);
    for (Instruction *I : OwnerBeforeDemotion) {
      if (I->getType()->isVoidTy() || I->use_empty()) continue;
      bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
        auto *UI = dyn_cast<Instruction>(U);
        return UI && UI->getParent() != Owner;
      });
      if (UsedOutside)
        DemoteRegToStack(*I, false, AllocaPoint->getIterator());
    }
  }

  // Conditional terminal latches can expose loop-carried values directly to
  // the exit block.  PHI demotion materializes their reloads in Latch; after
  // bypassing Latch those SSA reloads would otherwise become unreachable and
  // LLVM would replace the exit use with poison.  Spill every latch-produced
  // live-out before cloning so each direct transition writes the same private
  // slot and the original exit reload remains dominated and exact.
  SmallVector<Instruction *, 16> LatchBeforeLiveOutDemotion;
  for (Instruction &I : *Latch)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      LatchBeforeLiveOutDemotion.push_back(&I);
  for (Instruction *I : LatchBeforeLiveOutDemotion) {
    if (I->getType()->isVoidTy() || I->use_empty()) continue;
    bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
      auto *UI = dyn_cast<Instruction>(U);
      return UI && UI->getParent() != Latch;
    });
    if (UsedOutside)
      DemoteRegToStack(*I, false, AllocaPoint->getIterator());
  }

  SmallVector<Instruction *, 16> HeaderBeforeDemotion;
  for (Instruction &I : *Header)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      HeaderBeforeDemotion.push_back(&I);
  for (Instruction *I : HeaderBeforeDemotion) {
    if (I->getType()->isVoidTy() || I->use_empty()) continue;
    bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
      auto *UI = dyn_cast<Instruction>(U);
      return UI && UI->getParent() != Header;
    });
    if (UsedOutside)
      DemoteRegToStack(*I, false, AllocaPoint->getIterator());
  }

  if (HasNestedOuter) {
    SmallVector<Instruction *, 32> OuterBeforeDemotion;
    for (Instruction &I : *Outer)
      if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
        OuterBeforeDemotion.push_back(&I);
    for (Instruction *I : OuterBeforeDemotion) {
      if (I->getType()->isVoidTy() || I->use_empty()) continue;
      bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
        auto *UI = dyn_cast<Instruction>(U);
        return UI && UI->getParent() != Outer;
      });
      if (UsedOutside)
        DemoteRegToStack(*I, false, AllocaPoint->getIterator());
    }
  }

  bool HasDefaultPaths = InitialPath.ViaDefault;
  auto TransitionUsesDefault = [](const ProvenTransition &T) {
    return T.TrueViaDefault || T.FalseViaDefault ||
           llvm::is_contained(T.FiniteViaDefault, true);
  };
  HasDefaultPaths |= llvm::any_of(Transitions, TransitionUsesDefault);
  HasDefaultPaths |= llvm::any_of(OuterTransitions, TransitionUsesDefault);
  if (HasDefaultPaths) {
    // Values computed by the default guard can feed terminal/fallback code.
    // Demote those live-outs first so each cloned default path writes the same
    // private slots and all downstream uses receive exact SSA-safe reloads.
    SmallVector<Instruction *, 32> DefaultBeforeDemotion;
    for (Instruction &I : *DefaultGuard)
      if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
        DefaultBeforeDemotion.push_back(&I);
    for (Instruction *I : DefaultBeforeDemotion) {
      if (I->getType()->isVoidTy() || I->use_empty()) continue;
      bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
        auto *UI = dyn_cast<Instruction>(U);
        return UI && UI->getParent() != DefaultGuard;
      });
      if (UsedOutside)
        DemoteRegToStack(*I, false, AllocaPoint->getIterator());
    }
  }

  // PHI/reg2mem lowering can replace a saved select condition with a reload
  // in the transition source.  Refresh every condition after all demotions;
  // using the pre-demotion Value * is precisely what creates non-dominating
  // branch operands when the old dispatcher blocks become unreachable.
  auto RefreshTransitionCondition = [](ProvenTransition &T) {
    if (T.Selector) T.Condition = T.Selector->getCondition();
  };
  for (ProvenTransition &T : Transitions) RefreshTransitionCondition(T);
  for (ProvenTransition &T : OuterTransitions) RefreshTransitionCondition(T);
  if (HeaderTrampolineTransition)
    RefreshTransitionCondition(*HeaderTrampolineTransition);

  SmallVector<Instruction *, 32> LatchBody, HeaderBody, LookupOwnerBody,
      OuterSinkBody, OuterBody, DefaultBody;
  for (Instruction &I : *Latch)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      LatchBody.push_back(&I);
  for (Instruction &I : *Header)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      HeaderBody.push_back(&I);
  for (BasicBlock *Owner : AdditionalLookupOwners)
    for (Instruction &I : *Owner)
      if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
        LookupOwnerBody.push_back(&I);
  if (HasDefaultPaths)
    for (Instruction &I : *DefaultGuard)
      if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
        DefaultBody.push_back(&I);
  if (HasNestedOuter) {
    for (Instruction &I : *OuterSink)
      if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
        OuterSinkBody.push_back(&I);
    for (Instruction &I : *Outer)
      if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
        OuterBody.push_back(&I);
  }

  unsigned DefaultPathSerial = 0;
  auto MaterializeDefaultPath =
      [&](BasicBlock *Target, bool ViaDefault,
          DenseMap<const Value *, Value *> &ParentMap,
          StringRef Suffix) -> BasicBlock * {
    if (!ViaDefault) return Target;
    BasicBlock *PathBlock = BasicBlock::Create(
        F->getContext(), "deobf.default." + Suffix + "." +
                             Twine(DefaultPathSerial++),
        F, Target);
    BranchInst *Placeholder = BranchInst::Create(Target, PathBlock);
    DenseMap<const Value *, Value *> Map = ParentMap;
    cloneBlockPlumbing(DefaultBody, Placeholder, Map);
    return PathBlock;
  };

  if (Initial) {
    Instruction *Old = EntryPred->getTerminator();
    DenseMap<const Value *, Value *> Map;
    cloneBlockPlumbing(HeaderBody, Old, Map);
    cloneBlockPlumbing(LookupOwnerBody, Old, Map);
    BasicBlock *Target = MaterializeDefaultPath(
        InitialTarget, InitialPath.ViaDefault, Map, "entry");
    BranchInst::Create(Target, Old->getIterator());
    Old->eraseFromParent();
  } else if (HasNestedOuter) {
    Instruction *Old = OuterEntry->getTerminator();
    DenseMap<const Value *, Value *> Map;
    cloneBlockPlumbing(OuterBody, Old, Map);
    cloneBlockPlumbing(HeaderBody, Old, Map);
    cloneBlockPlumbing(LookupOwnerBody, Old, Map);
    BasicBlock *Target = MaterializeDefaultPath(
        InitialTarget, InitialPath.ViaDefault, Map, "outer.entry");
    BranchInst::Create(Target, Old->getIterator());
    Old->eraseFromParent();
  }
  std::string FunctionName = F->getName().str();
  std::string HeaderName = Header->getName().str();
  unsigned NestedPathSerial = 0;
  auto MaterializeNestedTarget =
      [&](BasicBlock *Target, DenseMap<const Value *, Value *> &ParentMap,
          StringRef Suffix) -> BasicBlock * {
    if (!HasNestedOuter || Target != OuterSink) return Target;
    if (!HeaderTrampolineTransition) return Target;
    BasicBlock *PathBlock = BasicBlock::Create(
        F->getContext(), "deobf.nested.outer." + Suffix + "." +
                             Twine(NestedPathSerial++),
        F, HeaderTrampolineTransition->TrueTarget);
    BranchInst *Placeholder =
        BranchInst::Create(HeaderTrampolineTransition->TrueTarget, PathBlock);
    DenseMap<const Value *, Value *> Map = ParentMap;
    cloneBlockPlumbing(OuterSinkBody, Placeholder, Map);
    cloneBlockPlumbing(OuterBody, Placeholder, Map);
    cloneBlockPlumbing(HeaderBody, Placeholder, Map);
    cloneBlockPlumbing(LookupOwnerBody, Placeholder, Map);
    if (HeaderTrampolineTransition->Condition) {
      Value *Condition = HeaderTrampolineTransition->Condition;
      if (auto It = Map.find(Condition); It != Map.end()) Condition = It->second;
      BranchInst::Create(HeaderTrampolineTransition->TrueTarget,
                         HeaderTrampolineTransition->FalseTarget, Condition,
                         Placeholder->getIterator());
      Placeholder->eraseFromParent();
    }
    return PathBlock;
  };
  for (const ProvenTransition &T : Transitions) {
    Instruction *Old = T.Source->getTerminator();
    std::string OldTerminatorText = valueText(*Old);
    DenseMap<const Value *, Value *> Map;
    cloneBlockPlumbing(LatchBody, Old, Map);
    cloneBlockPlumbing(HeaderBody, Old, Map);
    cloneBlockPlumbing(LookupOwnerBody, Old, Map);
    BasicBlock *TrueTarget =
        MaterializeNestedTarget(T.TrueTarget, Map, "inner.true");
    BasicBlock *FalseTarget = T.FalseTarget
                                  ? MaterializeNestedTarget(
                                        T.FalseTarget, Map, "inner.false")
                                  : nullptr;
    TrueTarget = MaterializeDefaultPath(
        TrueTarget, T.TrueViaDefault, Map, "inner.true");
    if (FalseTarget)
      FalseTarget = MaterializeDefaultPath(
          FalseTarget, T.FalseViaDefault, Map, "inner.false");
    if (T.FiniteState) {
      Value *FiniteState = T.FiniteState;
      if (auto It = Map.find(FiniteState); It != Map.end())
        FiniteState = It->second;
      SmallVector<BasicBlock *, 8> FiniteTargets;
      for (unsigned I = 0; I != T.FiniteTargets.size(); ++I) {
        BasicBlock *Target = MaterializeNestedTarget(
            T.FiniteTargets[I], Map, "inner.finite");
        bool ViaDefault = I < T.FiniteViaDefault.size() &&
                          T.FiniteViaDefault[I];
        FiniteTargets.push_back(MaterializeDefaultPath(
            Target, ViaDefault, Map, "inner.finite"));
      }
      auto *FiniteSwitch = SwitchInst::Create(
          FiniteState, FiniteTargets.front(),
          T.FiniteRawValues.size() - 1, Old->getIterator());
      for (unsigned I = 1; I != T.FiniteRawValues.size(); ++I)
        FiniteSwitch->addCase(
            ConstantInt::get(T.FiniteState->getContext(),
                             T.FiniteRawValues[I]),
            FiniteTargets[I]);
    } else if (T.Condition) {
      Value *Condition = T.Condition;
      if (auto It = Map.find(Condition); It != Map.end())
        Condition = It->second;
      BranchInst::Create(TrueTarget, FalseTarget, Condition,
                         Old->getIterator());
    } else {
      BranchInst::Create(TrueTarget, Old->getIterator());
    }
    Old->eraseFromParent();
    Instruction *NewTerminator = T.Source->getTerminator();
    ProofRecord TransitionRecord{
        FunctionName, "cff_transition", valueName(*T.Source),
        "ssa_phi_demotion_exact_plumbing", "proved"};
    TransitionRecord.OldHash = hashText(OldTerminatorText);
    TransitionRecord.NewHash = hashText(valueText(*NewTerminator));
    TransitionRecord.ProofQueryHash = hashText(TransitionCertificate);
    TransitionRecord.Dependencies.push_back("llvm_phi_demotion");
    TransitionRecord.Dependencies.push_back("exact_latch_header_clone");
    if (T.FiniteState)
      TransitionRecord.Dependencies.push_back(
          "exhaustive_acyclic_finite_transition_set");
    Proofs.push_back(std::move(TransitionRecord));
  }
  for (const ProvenTransition &T : OuterTransitions) {
    Instruction *Old = T.Source->getTerminator();
    DenseMap<const Value *, Value *> Map;
    // A direct outer state is computed in OuterSink itself, so its semantic
    // body has already executed at this terminator.  PHI-sink transitions are
    // placed on predecessors and still need the exact sink-body clone.
    if (T.Source != OuterSink)
      cloneBlockPlumbing(OuterSinkBody, Old, Map);
    cloneBlockPlumbing(OuterBody, Old, Map);
    cloneBlockPlumbing(HeaderBody, Old, Map);
    cloneBlockPlumbing(LookupOwnerBody, Old, Map);
    BasicBlock *TrueTarget = MaterializeDefaultPath(
        T.TrueTarget, T.TrueViaDefault, Map, "outer.true");
    BasicBlock *FalseTarget = T.FalseTarget
                                  ? MaterializeDefaultPath(
                                        T.FalseTarget, T.FalseViaDefault, Map,
                                        "outer.false")
                                  : nullptr;
    if (T.FiniteState) {
      Value *FiniteState = T.FiniteState;
      if (auto It = Map.find(FiniteState); It != Map.end())
        FiniteState = It->second;
      SmallVector<BasicBlock *, 8> FiniteTargets;
      for (unsigned I = 0; I != T.FiniteTargets.size(); ++I) {
        bool ViaDefault = I < T.FiniteViaDefault.size() &&
                          T.FiniteViaDefault[I];
        FiniteTargets.push_back(MaterializeDefaultPath(
            T.FiniteTargets[I], ViaDefault, Map, "outer.finite"));
      }
      auto *FiniteSwitch = SwitchInst::Create(
          FiniteState, FiniteTargets.front(),
          T.FiniteRawValues.size() - 1, Old->getIterator());
      for (unsigned I = 1; I != T.FiniteRawValues.size(); ++I)
        FiniteSwitch->addCase(
            ConstantInt::get(FiniteState->getContext(),
                             T.FiniteRawValues[I]),
            FiniteTargets[I]);
    } else if (T.Condition) {
      Value *Condition = T.Condition;
      if (auto It = Map.find(Condition); It != Map.end())
        Condition = It->second;
      BranchInst::Create(TrueTarget, FalseTarget, Condition,
                         Old->getIterator());
    } else {
      BranchInst::Create(TrueTarget, Old->getIterator());
    }
    Old->eraseFromParent();
    ProofRecord OuterRecord{FunctionName, "cff_transition",
                            valueName(*T.Source),
                            "nested_outer_ssa_exact_plumbing", "proved"};
    OuterRecord.Dependencies.push_back("llvm_phi_demotion");
    OuterRecord.Dependencies.push_back("exact_outer_sink_header_clone");
    if (T.FiniteState)
      OuterRecord.Dependencies.push_back(
          "exhaustive_outer_phi_funnel_transition_set");
    Proofs.push_back(std::move(OuterRecord));
  }
  if (DynamicEntryIsOneShot)
    for (SwitchInst *Lookup : LookupSwitches)
      Lookup->setMetadata("ollvm.deobf.dynamic_entry_dispatch",
                          MDNode::get(F->getContext(), {}));
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  ProofRecord Record{FunctionName, "cff_dispatcher", HeaderName,
                     "complete_ssa_transition_and_plumbing_set", "proved"};
  Record.OldHash = hashText(OldFunctionText);
  Record.NewHash = hashText(valueText(*F));
  Record.ProofQueryHash = hashText(TransitionCertificate);
  Record.Dependencies.push_back("llvm_phi_demotion");
  Record.Dependencies.push_back("exact_latch_header_clone");
  if (ReachabilityPruned)
    Record.Dependencies.push_back("seed_reachable_transition_induction");
  if (TerminalState)
    Record.Dependencies.push_back("exact_terminal_latch_state_transition");
  if (HasNestedOuter) {
    Record.Dependencies.push_back("complete_nested_outer_transition_set");
    Record.Dependencies.push_back("exact_outer_sink_header_clone");
  }
  if (DynamicEntryIsOneShot)
    Record.Dependencies.push_back("dynamic_entry_exact_switch_retained");
  Proofs.push_back(std::move(Record));
  return true;
}

} // namespace brighten_ollvm_deobf
