#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

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
  std::string MemoryPromotionFailure;
  Value *InitialStateValue = nullptr;
  ConstantInt *Initial = nullptr;
  BasicBlock *EntryPred = nullptr, *Latch = nullptr;
  DominatorTree DispatcherDT(*F);
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
    }
  }
  if (!Initial && InitialStateValue && EntryPred)
    Initial = asTransitionConstant(InitialStateValue, EntryPred);
  // Keep the compact direct-SSA engine for a constant-seeded dispatcher that
  // carries no semantic header state.  This plumbing engine is needed for the
  // single-PHI shape only when the seed is dynamic or belongs to a nested
  // outer recurrence.
  if (Initial && SwitchBlock == Header &&
      std::next(Header->phis().begin()) == Header->phis().end())
    return Reject("constant-single-header-phi");
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
      LatchState = PHINode::Create(
          LatchStateLoad->getType(), Incoming.size(),
          "deobf.memory.latch.state", LatchStateLoad->getIterator());
      for (const auto &[IncomingValue, Pred] : Incoming)
        LatchState->addIncoming(IncomingValue, Pred);
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
        OuterSink = Pred;
      }
    }
    auto *OuterEntryBr = OuterEntry
                             ? dyn_cast<BranchInst>(OuterEntry->getTerminator())
                             : nullptr;
    auto *OuterSinkBr = OuterSink
                            ? dyn_cast<BranchInst>(OuterSink->getTerminator())
                            : nullptr;
    if (!OuterInitial || !OuterEntry || !OuterSinkState || !OuterSink ||
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
      SmallPtrSet<Value *, 16> SeenSinkValues;
      if (!CollectSinkPhis(SinkValue, SeenSinkValues))
        return Reject("nested-outer-phi-pair");
      OuterPhis.push_back(&OuterPhi);
    }
    for (PHINode &SinkPhi : OuterSink->phis()) {
      if (!UsedOuterSinkPhis.contains(&SinkPhi))
        return Reject("nested-unpaired-outer-sink-phi");
      OuterSinkPhis.push_back(&SinkPhi);
    }
    if (!UsedOuterSinkPhis.contains(OuterSinkState))
      return Reject("nested-outer-state-not-paired");
    HasNestedOuter = true;
  }

  SmallVector<PHINode *, 8> HeaderPhis;
  SmallVector<PHINode *, 8> LatchPhis;
  for (PHINode &HP : Header->phis()) {
    if (HP.getNumIncomingValues() != 2 ||
        HP.getBasicBlockIndex(EntryPred) < 0 ||
        HP.getBasicBlockIndex(Latch) < 0)
      return Reject("header-phi-shape");
    auto *LP = dyn_cast<PHINode>(HP.getIncomingValueForBlock(Latch));
    if (!LP || LP->getParent() != Latch) return Reject("latch-phi-pair");
    HeaderPhis.push_back(&HP);
    LatchPhis.push_back(LP);
  }
  llvm::sort(LatchPhis);
  LatchPhis.erase(std::unique(LatchPhis.begin(), LatchPhis.end()),
                   LatchPhis.end());
  for (PHINode &LP : Latch->phis())
    if (!llvm::is_contained(LatchPhis, &LP))
      return Reject("unpaired-latch-phi");

  DenseMap<APInt, BasicBlock *> CaseMap;
  DenseMap<APInt, bool> CaseViaDefault;
  SmallPtrSet<BasicBlock *, 32> CaseEntries;
  DenseMap<BasicBlock *, APInt> CaseRawStates;
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
        if (TargetPhi.getBasicBlockIndex(Header) < 0)
          return Reject("case-phi-without-dispatch-input");
        if (SeenCaseEntryPhis.insert(&TargetPhi).second)
          CaseEntryPhis.push_back(&TargetPhi);
      }
    CaseMap[Encoded] = Target;
    CaseViaDefault[Encoded] = Lookup != &SI;
    CaseEntries.insert(Target);
    if (auto Raw = decodeStateExpr(SI.getCondition(), State, Encoded)) {
      auto It = CaseRawStates.find(Target);
      if (It == CaseRawStates.end())
        CaseRawStates.try_emplace(Target, *Raw);
      else if (It->second != *Raw)
        AmbiguousCaseRawStates.insert(Target);
    }
  }
  for (BasicBlock *Target : AmbiguousCaseRawStates)
    CaseRawStates.erase(Target);
  if (CaseMap.size() < 4) return Reject("case-map");

  // With one lookup switch, its unmatched destination can be a real
  // initialization/case body rather than a pure comparison shard.  Preserve
  // that body as an explicit case entry; switch semantics prove it is the
  // exact target for every state absent from the case table.  Multi-shard
  // lookup chains stay on the ordered resolver path above.
  BasicBlock *DirectDefaultTarget = nullptr;
  if (LookupSwitches.size() == 1) {
    BasicBlock *Target = SI.getDefaultDest();
    if (Target != OuterSink && Target != Latch) {
      for (PHINode &TargetPhi : Target->phis()) {
        if (TargetPhi.getBasicBlockIndex(Header) < 0)
          return Reject("default-case-phi-without-dispatch-input");
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
  DenseMap<BasicBlock *, BasicBlock *> ReturningRootBySource;
  for (BasicBlock *Source : predecessors(Latch)) {
    SmallVector<BasicBlock *, 16> Work{Source};
    SmallPtrSet<BasicBlock *, 32> Seen;
    BasicBlock *Root = nullptr;
    while (!Work.empty() && Seen.size() <= 64) {
      BasicBlock *BB = Work.pop_back_val();
      if (!Seen.insert(BB).second) continue;
      if (CaseEntries.contains(BB)) {
        if (Root && Root != BB) return Reject("ambiguous-case-root");
        Root = BB;
        continue;
      }
      if (BB == Header || BB == Latch) continue;
      for (BasicBlock *Pred : predecessors(BB)) Work.push_back(Pred);
    }
    if (!Root) continue;
    ReturningCases.push_back(Source);
    ReturningRoots.insert(Root);
    ReturningRootBySource[Source] = Root;
    if (auto It = CaseRawStates.find(Root); It != CaseRawStates.end())
      ReturningRawStates.try_emplace(Source, It->second);
  }
  if (ReturningCases.empty()) return Reject("no-returning-cases");
  // Whole-function reachability is too broad here: a genuine nested-CFF exit
  // can reach this header again only after returning to an outer dispatcher
  // and starting a later invocation.  It is a returning case for this loop
  // only when it reaches the latch without first crossing the header.
  auto ReachesLatchLocally = [&](BasicBlock *Start) -> std::optional<bool> {
    SmallVector<BasicBlock *, 32> Work{Start};
    SmallPtrSet<BasicBlock *, 32> Seen;
    while (!Work.empty()) {
      BasicBlock *BB = Work.pop_back_val();
      if (!Seen.insert(BB).second) continue;
      if (Seen.size() > 256) return std::nullopt;
      for (BasicBlock *Succ : successors(BB)) {
        if (Succ == Latch) return true;
        if (Succ != Header) Work.push_back(Succ);
      }
    }
    return false;
  };
  for (BasicBlock *CaseEntry : CaseEntries) {
    if (ReturningRoots.contains(CaseEntry)) continue;
    std::optional<bool> Reaches = ReachesLatchLocally(CaseEntry);
    if (!Reaches || *Reaches) return Reject("unclassified-returning-case");
  }
  for (PHINode *LP : LatchPhis)
    for (BasicBlock *CaseBB : ReturningCases)
      if (LP->getBasicBlockIndex(CaseBB) < 0) return Reject("latch-input");

  struct ResolvedDirectPath {
    BasicBlock *Target = nullptr;
    bool ViaDefault = false;
  };
  BasicBlock *DefaultGuard = SI.getDefaultDest();
  auto *DefaultGuardBr = dyn_cast<BranchInst>(DefaultGuard->getTerminator());
  bool DefaultGuardCloneable =
      DefaultGuardBr && DefaultGuardBr->isConditional() &&
      DefaultGuard->phis().empty() &&
      llvm::all_of(*DefaultGuard, [&](Instruction &I) {
        return &I == DefaultGuardBr || isa<DbgInfoIntrinsic>(I) ||
               (!I.mayReadOrWriteMemory() && !I.mayHaveSideEffects());
      });
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
      if (Depth > 8 || RawIt == ReturningRawStates.end())
        return std::nullopt;
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
      auto TrueRaw = EvaluateAtCaseState(Sel->getTrueValue(), 0);
      auto FalseRaw = EvaluateAtCaseState(Sel->getFalseValue(), 0);
      if (!TrueRaw || !FalseRaw) {
        Proved = false;
      } else {
        T.Condition = Sel->getCondition();
        ResolvedDirectPath TruePath = ResolveRaw(*TrueRaw);
        ResolvedDirectPath FalsePath = ResolveRaw(*FalseRaw);
        T.TrueTarget = TruePath.Target;
        T.TrueViaDefault = TruePath.ViaDefault;
        T.FalseTarget = FalsePath.Target;
        T.FalseViaDefault = FalsePath.ViaDefault;
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
      unsigned ExecutionBudget = 128;
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
      bool Finite = RawIt != ReturningRawStates.end() &&
                    enumerateTransitionValues(
                        FiniteExpr, nullptr, RawIt->second, NoBindings,
                        FiniteValues, ExecutionBudget) &&
                    FiniteValues.size() >= 2;
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
  if (Initial) {
    SmallVector<BasicBlock *, 32> Work;
    SmallPtrSet<BasicBlock *, 32> ReachableRoots;
    if (CaseEntries.contains(InitialTarget)) Work.push_back(InitialTarget);
    while (!Work.empty()) {
      BasicBlock *Root = Work.pop_back_val();
      if (!ReachableRoots.insert(Root).second) continue;
      if (ReachableRoots.size() > CaseEntries.size())
        return Reject("reachable-transition-closure-overflow");
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
        if (Pred != Header && !LookupOwners.contains(Pred))
          return Reject((Twine("seed-induction-external-case-entry:case=") +
                         CaseEntry->getName() + ";pred=" + Pred->getName())
                            .str());
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
      auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
      if (!TC || !FC) return std::nullopt;
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
    if (!OuterInitialTarget || OuterInitialTarget == OuterSink)
      return Reject("nested-initial-target");
    // Reuse InitialTarget for the outer function-entry bypass.
    InitialTarget = OuterInitialTarget;
    InitialPath = OuterInitialPath;
    int HeaderIndex = OuterSinkState->getBasicBlockIndex(Header);
    if (HeaderIndex >= 0) {
      HeaderTrampolineTransition = BuildOuterTransition(
          Header, OuterSinkState->getIncomingValue(HeaderIndex));
      if (!HeaderTrampolineTransition)
        return Reject("nested-header-trampoline-transition");
    }
    bool InnerTargetsOuterSink = llvm::any_of(
        Transitions, [&](const ProvenTransition &T) {
          if (T.TrueTarget == OuterSink || T.FalseTarget == OuterSink)
            return true;
          return llvm::is_contained(T.FiniteTargets, OuterSink);
        });
    if (InnerTargetsOuterSink && !HeaderTrampolineTransition)
      return Reject("nested-outer-sink-without-trampoline-input");
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

  SmallVector<Instruction *, 32> LatchBody, HeaderBody, OuterSinkBody,
      OuterBody, DefaultBody;
  for (Instruction &I : *Latch)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      LatchBody.push_back(&I);
  for (Instruction &I : *Header)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      HeaderBody.push_back(&I);
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
    BasicBlock *Target = MaterializeDefaultPath(
        InitialTarget, InitialPath.ViaDefault, Map, "entry");
    BranchInst::Create(Target, Old->getIterator());
    Old->eraseFromParent();
  } else if (HasNestedOuter) {
    Instruction *Old = OuterEntry->getTerminator();
    DenseMap<const Value *, Value *> Map;
    cloneBlockPlumbing(OuterBody, Old, Map);
    cloneBlockPlumbing(HeaderBody, Old, Map);
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
          T.FiniteState, FiniteTargets.front(),
          T.FiniteRawValues.size() - 1, Old->getIterator());
      for (unsigned I = 1; I != T.FiniteRawValues.size(); ++I)
        FiniteSwitch->addCase(
            ConstantInt::get(T.FiniteState->getContext(),
                             T.FiniteRawValues[I]),
            FiniteTargets[I]);
    } else if (T.Condition)
      BranchInst::Create(TrueTarget, FalseTarget, T.Condition,
                         Old->getIterator());
    else
      BranchInst::Create(TrueTarget, Old->getIterator());
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
    cloneBlockPlumbing(OuterSinkBody, Old, Map);
    cloneBlockPlumbing(OuterBody, Old, Map);
    cloneBlockPlumbing(HeaderBody, Old, Map);
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
    } else if (T.Condition)
      BranchInst::Create(TrueTarget, FalseTarget, T.Condition,
                         Old->getIterator());
    else
      BranchInst::Create(TrueTarget, Old->getIterator());
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
