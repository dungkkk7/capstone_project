#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

// General funnel-form CFF recovery.  Native cleanup commonly canonicalizes a
// flattened loop as case tails -> semantic sink PHIs -> outer loop PHIs -> a
// self-defaulting switch.  Every loop-carried component is significant; lower
// all sink/outer/case-entry PHIs with LLVM's exact reg2mem utilities, then
// clone the complete sink->outer->header plumbing on each proved state edge.
// Trampoline states are preserved as additional plumbing rounds rather than
// collapsed to a target-only shortcut.
bool tryRecoverGeneralFunnelPlumbingDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  Function *F = Header->getParent();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() == Header ||
      !Header->hasNPredecessors(2))
    return false;
  BasicBlock *Outer = State->getParent();
  auto *OuterBr = dyn_cast<BranchInst>(Outer->getTerminator());
  if (!OuterBr || !OuterBr->isUnconditional() ||
      OuterBr->getSuccessor(0) != Header ||
      State->getNumIncomingValues() != 2)
    return false;

  BasicBlock *EntryPred = nullptr, *Sink = nullptr;
  ConstantInt *Initial = nullptr;
  PHINode *SinkState = nullptr;
  for (unsigned I = 0; I != State->getNumIncomingValues(); ++I) {
    Value *Incoming = State->getIncomingValue(I);
    BasicBlock *Pred = State->getIncomingBlock(I);
    if (auto *PN = dyn_cast<PHINode>(Incoming);
        PN && PN->getParent() == Pred) {
      SinkState = PN;
      Sink = Pred;
      continue;
    }
    Initial = asTransitionConstant(Incoming, Pred);
    EntryPred = Pred;
  }
  if (!Initial || !EntryPred || !SinkState || !Sink ||
      EntryPred == Sink)
    return false;
  auto *EntryBr = dyn_cast<BranchInst>(EntryPred->getTerminator());
  auto *SinkBr = dyn_cast<BranchInst>(Sink->getTerminator());
  if (!EntryBr || !EntryBr->isUnconditional() ||
      EntryBr->getSuccessor(0) != Outer || !SinkBr ||
      !SinkBr->isUnconditional() || SinkBr->getSuccessor(0) != Outer)
    return false;

  // The lookup can be one self-defaulting switch or an optimizer-partitioned
  // ring of switch tables and peeled equality cases.  Collect the complete
  // ring before interpreting any state.  Every intermediate lookup block is
  // required to be semantic-free and single-entry, so bypassing it cannot
  // discard program work.
  SmallVector<SwitchInst *, 8> Shards;
  SmallPtrSet<BasicBlock *, 16> LookupBlocks;
  struct EqualityLookupCase {
    ConstantInt *Key = nullptr;
    BasicBlock *Target = nullptr;
    BasicBlock *Owner = nullptr;
  };
  SmallVector<EqualityLookupCase, 8> EqualityCases;
  BasicBlock *Current = Header;
  BasicBlock *Previous = nullptr;
  bool ClosedLookupRing = false;
  for (unsigned Depth = 0; Depth != 32; ++Depth) {
    if (!LookupBlocks.insert(Current).second) return false;
    if (Previous &&
        (!Current->hasNPredecessors(1) ||
         *pred_begin(Current) != Previous))
      return false;

    BasicBlock *Next = nullptr;
    if (auto *Shard = dyn_cast<SwitchInst>(Current->getTerminator())) {
      if (Shards.size() == 8 || Shard->getCondition() != SI.getCondition())
        return false;
      if (Current != Header)
        for (Instruction &I : *Current)
          if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I)) return false;
      Shards.push_back(Shard);
      Next = Shard->getDefaultDest();
    } else {
      auto *Br = dyn_cast<BranchInst>(Current->getTerminator());
      auto *Cmp = Br && Br->isConditional()
                      ? dyn_cast<ICmpInst>(Br->getCondition())
                      : nullptr;
      if (!Cmp || (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
                   Cmp->getPredicate() != ICmpInst::ICMP_NE))
        return false;
      ConstantInt *EncodedKey = dyn_cast<ConstantInt>(Cmp->getOperand(1));
      Value *Compared = Cmp->getOperand(0);
      if (!EncodedKey) {
        EncodedKey = dyn_cast<ConstantInt>(Cmp->getOperand(0));
        Compared = Cmp->getOperand(1);
      }
      if (!EncodedKey) return false;
      auto RawKey = decodeStateExpr(Compared, State, EncodedKey->getValue());
      if (!RawKey || RawKey->getBitWidth() !=
                         cast<IntegerType>(State->getType())->getBitWidth())
        return false;
      ConstantInt *Key = cast<ConstantInt>(
          ConstantInt::get(State->getType(), *RawKey));
      for (Instruction &I : *Current)
        if (&I != Cmp && !I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
          return false;
      unsigned MatchIndex = Cmp->getPredicate() == ICmpInst::ICMP_EQ ? 0 : 1;
      EqualityCases.push_back(
          {Key, Br->getSuccessor(MatchIndex), Current});
      Next = Br->getSuccessor(1 - MatchIndex);
    }
    if (Next == Header) {
      ClosedLookupRing = true;
      break;
    }
    Previous = Current;
    Current = Next;
  }
  if (!ClosedLookupRing || Shards.empty()) return false;
  bool IsPartitionedLookup = LookupBlocks.size() > 1;

  SmallVector<PHINode *, 16> OuterPhis, SinkPhis;
  SmallPtrSet<PHINode *, 16> UsedSinkPhis;
  for (PHINode &OuterPhi : Outer->phis()) {
    if (OuterPhi.getNumIncomingValues() != 2 ||
        OuterPhi.getBasicBlockIndex(EntryPred) < 0 ||
        OuterPhi.getBasicBlockIndex(Sink) < 0)
      return false;
    auto *SinkPhi = dyn_cast<PHINode>(
        OuterPhi.getIncomingValueForBlock(Sink));
    if (!SinkPhi || SinkPhi->getParent() != Sink ||
        !UsedSinkPhis.insert(SinkPhi).second)
      return false;
    OuterPhis.push_back(&OuterPhi);
    SinkPhis.push_back(SinkPhi);
  }
  for (PHINode &SinkPhi : Sink->phis())
    if (!UsedSinkPhis.contains(&SinkPhi)) return false;
  if (!UsedSinkPhis.contains(SinkState)) return false;

  DenseMap<APInt, BasicBlock *> CaseMap;
  DenseMap<APInt, BasicBlock *> CaseOwner;
  SmallVector<PHINode *, 32> CaseEntryPhis;
  SmallPtrSet<PHINode *, 32> SeenCaseEntryPhis;
  auto AddCase = [&](ConstantInt *KeyValue, BasicBlock *Target,
                     BasicBlock *Owner) {
    APInt Key = KeyValue->getValue();
    if (CaseMap.count(Key) || LookupBlocks.contains(Target)) return false;
    // Sink PHIs are owned and demoted by the recurrence itself.  A lookup
    // case targeting Sink is a trampoline, not an independent case-entry PHI
    // set; adding it here would schedule the same PHI for demotion twice.
    if (Target != Sink)
      for (PHINode &TargetPhi : Target->phis()) {
        if (TargetPhi.getBasicBlockIndex(Owner) < 0) return false;
        if (SeenCaseEntryPhis.insert(&TargetPhi).second)
          CaseEntryPhis.push_back(&TargetPhi);
      }
    CaseMap[Key] = Target;
    CaseOwner[Key] = Owner;
    return true;
  };
  for (SwitchInst *Shard : Shards)
    for (auto Case : Shard->cases())
      if (!AddCase(Case.getCaseValue(), Case.getCaseSuccessor(),
                   Shard->getParent()))
        return false;
  for (const EqualityLookupCase &Case : EqualityCases)
    if (!AddCase(Case.Key, Case.Target, Case.Owner)) return false;
  if (CaseMap.size() < 4) return false;

  struct ResolvedFunnelPath {
    BasicBlock *Target = nullptr;
    SmallVector<BasicBlock *, 8> TrampolineOwners;
  };
  auto Resolve = [&](ConstantInt *Raw) -> std::optional<ResolvedFunnelPath> {
    ResolvedFunnelPath Result;
    SmallPtrSet<BasicBlock *, 8> SeenOwners;
    for (unsigned Depth = 0; Depth != 8; ++Depth) {
      auto Encoded = evalStateExpr(SI.getCondition(), State, Raw->getValue());
      if (!Encoded) return std::nullopt;
      auto It = CaseMap.find(*Encoded);
      if (It == CaseMap.end()) return std::nullopt;
      BasicBlock *Target = It->second;
      if (Target != Sink) {
        Result.Target = Target;
        return Result;
      }
      BasicBlock *Owner = CaseOwner.lookup(*Encoded);
      if (!Owner || !SeenOwners.insert(Owner).second) return std::nullopt;
      auto *Next = asTransitionConstant(
          SinkState->getIncomingValueForBlock(Owner), Owner);
      if (!Next) return std::nullopt;
      Result.TrampolineOwners.push_back(Owner);
      Raw = Next;
    }
    return std::nullopt;
  };
  std::optional<ResolvedFunnelPath> InitialPath = Resolve(Initial);
  if (!InitialPath) return false;

  struct FunnelTransition {
    BasicBlock *Source = nullptr;
    Value *Condition = nullptr;
    ResolvedFunnelPath TruePath;
    std::optional<ResolvedFunnelPath> FalsePath;
  };
  SmallVector<FunnelTransition, 64> Transitions;
  for (BasicBlock *Source : predecessors(Sink)) {
    if (LookupBlocks.contains(Source)) continue;
    int Index = SinkState->getBasicBlockIndex(Source);
    if (Index < 0) return false;
    auto *Br = dyn_cast<BranchInst>(Source->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Sink)
      return false;
    Value *Raw = SinkState->getIncomingValue(Index);
    FunnelTransition Transition;
    Transition.Source = Source;
    if (auto *C = asTransitionConstant(Raw, Source)) {
      auto Path = Resolve(C);
      if (!Path) return false;
      Transition.TruePath = *Path;
    } else if (auto *Select = dyn_cast<SelectInst>(Raw)) {
      auto *TC = dyn_cast<ConstantInt>(Select->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Select->getFalseValue());
      if (!TC || !FC) return false;
      auto TruePath = Resolve(TC), FalsePath = Resolve(FC);
      if (!TruePath || !FalsePath) return false;
      Transition.Condition = Select->getCondition();
      Transition.TruePath = *TruePath;
      Transition.FalsePath = *FalsePath;
    } else {
      return false;
    }
    Transitions.push_back(std::move(Transition));
  }
  if (Transitions.empty()) return false;

  Instruction *AllocaPoint = &*F->getEntryBlock().getFirstInsertionPt();
  for (PHINode *CasePhi : CaseEntryPhis)
    DemotePHIToStack(CasePhi, AllocaPoint->getIterator());
  for (PHINode *SinkPhi : SinkPhis)
    DemotePHIToStack(SinkPhi, AllocaPoint->getIterator());
  for (PHINode *OuterPhi : OuterPhis)
    DemotePHIToStack(OuterPhi, AllocaPoint->getIterator());

  SmallVector<Instruction *, 64> OuterBeforeLiveOutDemotion;
  for (Instruction &I : *Outer)
    if (!I.isTerminator() && !isa<DbgInfoIntrinsic>(I))
      OuterBeforeLiveOutDemotion.push_back(&I);
  for (Instruction *I : OuterBeforeLiveOutDemotion) {
    if (I->getType()->isVoidTy() || I->use_empty()) continue;
    bool UsedOutside = llvm::any_of(I->users(), [&](User *U) {
      auto *UseI = dyn_cast<Instruction>(U);
      return UseI && UseI->getParent() != Outer;
    });
    if (UsedOutside)
      DemoteRegToStack(*I, false, AllocaPoint->getIterator());
  }

  SmallVector<Instruction *, 64> SinkBody, OuterBody, HeaderBody;
  for (Instruction &I : *Sink)
    if (!isa<PHINode>(I) && !I.isTerminator() &&
        !isa<DbgInfoIntrinsic>(I))
      SinkBody.push_back(&I);
  for (Instruction &I : *Outer)
    if (!isa<PHINode>(I) && !I.isTerminator() &&
        !isa<DbgInfoIntrinsic>(I))
      OuterBody.push_back(&I);
  for (Instruction &I : *Header)
    if (!isa<PHINode>(I) && !I.isTerminator() &&
        !isa<DbgInfoIntrinsic>(I))
      HeaderBody.push_back(&I);

  auto CloneReturningRound = [&](Instruction *Before,
                                 DenseMap<const Value *, Value *> &Map) {
    cloneBlockPlumbing(SinkBody, Before, Map);
    cloneBlockPlumbing(OuterBody, Before, Map);
    cloneBlockPlumbing(HeaderBody, Before, Map);
  };
  auto CloneTrampolines = [&](ArrayRef<BasicBlock *> Owners,
                              Instruction *Before,
                              DenseMap<const Value *, Value *> &Map) {
    for (BasicBlock *Owner : Owners) {
      // Reg2mem inserts Sink-PHI edge stores in the owning lookup shard.  The
      // first header body is already cloned by the surrounding round; other
      // owners must have their newly inserted private stores cloned here.
      if (Owner != Header) {
        SmallVector<Instruction *, 16> OwnerBody;
        for (Instruction &I : *Owner)
          if (!isa<PHINode>(I) && !I.isTerminator() &&
              !isa<DbgInfoIntrinsic>(I))
            OwnerBody.push_back(&I);
        cloneBlockPlumbing(OwnerBody, Before, Map);
      }
      CloneReturningRound(Before, Map);
    }
  };

  {
    Instruction *Old = EntryPred->getTerminator();
    DenseMap<const Value *, Value *> Map;
    cloneBlockPlumbing(OuterBody, Old, Map);
    cloneBlockPlumbing(HeaderBody, Old, Map);
    CloneTrampolines(InitialPath->TrampolineOwners, Old, Map);
    BranchInst::Create(InitialPath->Target, Old->getIterator());
    Old->eraseFromParent();
  }
  unsigned PathSerial = 0;
  for (const FunnelTransition &Transition : Transitions) {
    Instruction *Old = Transition.Source->getTerminator();
    DenseMap<const Value *, Value *> Map;
    CloneReturningRound(Old, Map);
    auto Materialize = [&](const ResolvedFunnelPath &Path,
                           StringRef Suffix) -> BasicBlock * {
      if (Path.TrampolineOwners.empty()) return Path.Target;
      BasicBlock *PathBlock = BasicBlock::Create(
          F->getContext(), "deobf.funnel.plumbing." + Suffix + "." +
                               Twine(PathSerial++),
          F, Path.Target);
      BranchInst *PathBranch = BranchInst::Create(Path.Target, PathBlock);
      DenseMap<const Value *, Value *> PathMap = Map;
      CloneTrampolines(Path.TrampolineOwners, PathBranch, PathMap);
      return PathBlock;
    };
    BasicBlock *TrueTarget = Materialize(Transition.TruePath, "true");
    if (Transition.Condition) {
      BasicBlock *FalseTarget = Materialize(*Transition.FalsePath, "false");
      BranchInst::Create(TrueTarget, FalseTarget, Transition.Condition,
                         Old->getIterator());
    } else {
      BranchInst::Create(TrueTarget, Old->getIterator());
    }
    Old->eraseFromParent();
    Proofs.push_back(
        {F->getName().str(), "cff_transition",
         Transition.Source->getName().str(),
         IsPartitionedLookup ? "partitioned_general_funnel_ssa_plumbing"
                             : "general_funnel_ssa_plumbing",
         "proved"});
  }
  std::string HeaderName = Header->getName().str();
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  ProofRecord Record{
      F->getName().str(), "cff_dispatcher", HeaderName,
      IsPartitionedLookup ? "complete_partitioned_general_funnel_ssa_plumbing"
                          : "complete_general_funnel_ssa_plumbing",
      "proved"};
  if (IsPartitionedLookup)
    Record.Dependencies.push_back("unique_cyclic_union_of_lookup_tables");
  Record.Dependencies.push_back("complete_sink_phi_coverage");
  Record.Dependencies.push_back("llvm_sink_outer_case_phi_demotion");
  Record.Dependencies.push_back("exact_sink_outer_header_clone");
  Record.Dependencies.push_back("all_state_transitions_resolved");
  Record.Dependencies.push_back("trampoline_rounds_preserved");
  Proofs.push_back(std::move(Record));
  return true;
}

} // namespace brighten_ollvm_deobf
