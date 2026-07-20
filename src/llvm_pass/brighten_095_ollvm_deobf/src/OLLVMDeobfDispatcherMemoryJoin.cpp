#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

StoreInst *findReachingStateStore(BasicBlock *Source,
                                         Value *StatePointer,
                                         Type *StateType,
                                         BasicBlock *Header,
                                         unsigned Depth,
                                         bool *HitBarrier) {
  if (Depth > 8) return nullptr;
  for (auto It = Source->rbegin(), End = Source->rend(); It != End; ++It) {
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (!SI) {
      if (It->mayWriteToMemory()) {
        if (HitBarrier) *HitBarrier = true;
        return nullptr;
      }
      continue;
    }
    if (sameFrameAddress(SI->getPointerOperand(), StatePointer) ||
        sameFrameAddressAlongUniquePath(SI->getPointerOperand(), StatePointer,
                                        SI->getParent(), Header))
      return SI;
    IntAffine Stored = parsePointerAffine(SI->getPointerOperand());
    IntAffine State = parsePointerAffine(StatePointer);
    if (!Stored.Valid || !State.Valid || Stored.Terms.empty() ||
        State.Terms.empty()) {
      if (HitBarrier) *HitBarrier = true;
      return nullptr;
    }
    // Distinct identified globals cannot alias.  Continue through their
    // stores while remaining conservative for every unidentified object.
    if (definitelyDistinctAffineObjects(Stored, State)) continue;
    if (!sameAffineTerms(Stored, State)) {
      if (HitBarrier) *HitBarrier = true;
      return nullptr;
    }
    if (Stored.Offset != State.Offset) {
      const DataLayout &DL = Source->getModule()->getDataLayout();
      TypeSize StoreSize = DL.getTypeStoreSize(SI->getValueOperand()->getType());
      TypeSize StateSize = DL.getTypeStoreSize(StateType);
      bool NonOverlapping = false;
      if (!StoreSize.isScalable() && !StateSize.isScalable() &&
          Stored.Offset.isSignedIntN(64) && State.Offset.isSignedIntN(64)) {
        int64_t StoreBegin = Stored.Offset.getSExtValue();
        int64_t StateBegin = State.Offset.getSExtValue();
        uint64_t StoreBytes = StoreSize.getFixedValue();
        uint64_t StateBytes = StateSize.getFixedValue();
        if (StoreBytes <= uint64_t(std::numeric_limits<int64_t>::max()) &&
            StateBytes <= uint64_t(std::numeric_limits<int64_t>::max()) &&
            StoreBegin <= std::numeric_limits<int64_t>::max() -
                              int64_t(StoreBytes) &&
            StateBegin <= std::numeric_limits<int64_t>::max() -
                              int64_t(StateBytes)) {
          int64_t StoreEnd = StoreBegin + int64_t(StoreBytes);
          int64_t StateEnd = StateBegin + int64_t(StateBytes);
          NonOverlapping = StoreEnd <= StateBegin || StateEnd <= StoreBegin;
        }
      }
      if (NonOverlapping) continue;
      if (HitBarrier) *HitBarrier = true;
      return nullptr;
    }
  }
  if (Source->hasNPredecessors(1))
    return findReachingStateStore(*pred_begin(Source), StatePointer, StateType,
                                  Header, Depth + 1, HitBarrier);
  return nullptr;
}

PHINode *buildMergedReachingStateValue(
    BasicBlock *Merge, Value *StatePointer, Type *StateType,
    BasicBlock *Header, BasicBlock *Join,
    const DenseMap<BasicBlock *, APInt> &CaseStates,
    Value *CurrentState) {
  if (!Merge || !StateType || !StateType->isIntegerTy()) return nullptr;
  SmallVector<std::pair<Value *, BasicBlock *>, 8> Incoming;
  for (Instruction &I : *Merge) {
    if (isa<PHINode>(I) || isa<DbgInfoIntrinsic>(I) || I.isTerminator())
      continue;
    if (I.mayWriteToMemory()) return nullptr;
  }
  for (BasicBlock *Pred : predecessors(Merge)) {
    unsigned EdgeCount = 0;
    for (BasicBlock *Succ : successors(Pred)) EdgeCount += Succ == Merge;
    if (EdgeCount != 1 || Incoming.size() == 8) return nullptr;
    bool HitBarrier = false;
    StoreInst *Store =
        findReachingStateStore(Pred, StatePointer, StateType, Header, 0,
                               &HitBarrier);
    if (Store) {
      if (HitBarrier || Store->isAtomic() || Store->isVolatile() ||
          Store->getValueOperand()->getType() != StateType ||
          !sameFrameAddress(Store->getPointerOperand(), StatePointer))
        return nullptr;
      Incoming.push_back({Store->getValueOperand(), Pred});
      continue;
    }
    // No reaching write and no alias barrier means this edge preserves the
    // dispatcher state it entered with.  Materialize that exact raw case
    // value instead of rejecting a partially-stored memory join.
    if (HitBarrier) return nullptr;
    if (CurrentState) {
      auto *Lookup = dyn_cast<SwitchInst>(Pred->getTerminator());
      if (Pred == Header ||
          (Lookup && Lookup->getCondition() == CurrentState)) {
        Incoming.push_back({CurrentState, Pred});
        continue;
      }
    }
    auto EntryState =
        findUniqueCaseEntryState(Pred, Header, Join, CaseStates);
    if (!EntryState || EntryState->getBitWidth() !=
                           cast<IntegerType>(StateType)->getBitWidth())
      return nullptr;
    Incoming.push_back({ConstantInt::get(StateType, *EntryState), Pred});
  }
  if (Incoming.size() < 2) return nullptr;
  auto *Merged = PHINode::Create(StateType, Incoming.size(),
                                 "deobf.merged.state",
                                 Merge->getFirstNonPHIIt());
  for (const auto &[Value, Pred] : Incoming) Merged->addIncoming(Value, Pred);
  return Merged;
}

// Promote a loop-header state load when whole-function MemorySSA is too
// conservative because unrelated lifted-frame stores share an unidentified
// base.  This proof is edge-local: every predecessor must have one exact
// reaching same-width store, possibly through a side-effect-free PHI merge,
// and address equality must hold after substituting the PHIs on the unique
// path into the load block.  No live-on-entry arm or alias barrier is crossed.
bool promoteExactPredecessorJoinStateLoad(
    LoadInst &LI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  if (LI.isAtomic() || LI.isVolatile() ||
      !LI.getType()->isIntegerTy())
    return false;
  BasicBlock *Header = LI.getParent();
  Function *F = Header->getParent();
  DominatorTree DT(*F);
  LoopInfo Loops(DT);
  Loop *L = Loops.getLoopFor(Header);
  if (!L || L->getHeader() != Header || pred_size(Header) < 2) return false;

  DenseMap<BasicBlock *, APInt> NoCaseStates;
  SmallVector<std::pair<Value *, BasicBlock *>, 8> Incoming;
  SmallVector<PHINode *, 4> TemporaryMerges;
  auto RollBack = [&]() {
    for (PHINode *Phi : reverse(TemporaryMerges))
      if (Phi && Phi->use_empty()) Phi->eraseFromParent();
  };
  for (BasicBlock *Pred : predecessors(Header)) {
    unsigned EdgeCount = 0;
    for (BasicBlock *Succ : successors(Pred)) EdgeCount += Succ == Header;
    if (EdgeCount != 1) {
      RollBack();
      return false;
    }
    bool HitBarrier = false;
    StoreInst *Store = findReachingStateStore(
        Pred, LI.getPointerOperand(), LI.getType(), Header, 0, &HitBarrier);
    Value *Reaching = Store ? Store->getValueOperand() : nullptr;
    if (!Reaching && !HitBarrier) {
      PHINode *Merged = buildMergedReachingStateValue(
          Pred, LI.getPointerOperand(), LI.getType(), Header, Header,
          NoCaseStates, nullptr);
      if (Merged) {
        TemporaryMerges.push_back(Merged);
        Reaching = Merged;
      }
    }
    if (!Reaching || HitBarrier || Reaching->getType() != LI.getType()) {
      RollBack();
      return false;
    }
    Incoming.push_back({Reaching, Pred});
  }
  if (Incoming.size() < 2) {
    RollBack();
    return false;
  }

  PHINode *State = PHINode::Create(
      LI.getType(), Incoming.size(), "deobf.dispatch.state.edge.ph",
      Header->getFirstNonPHIIt());
  for (const auto &[Value, Pred] : Incoming) State->addIncoming(Value, Pred);
  std::string Origin = valueName(LI);
  LI.replaceAllUsesWith(State);
  LI.eraseFromParent();
  ++M.MemorySSAPhisResolved;
  ProofRecord Record{F->getName().str(), "cff_state_promotion", Origin,
                     "exact_predecessor_join_state_phi", "proved"};
  Record.Dependencies.push_back("complete_predecessor_coverage");
  Record.Dependencies.push_back("unique_path_phi_address_substitution");
  Record.Dependencies.push_back("exact_same_width_reaching_stores");
  Record.Dependencies.push_back("no_alias_or_memory_barrier_crossed");
  Proofs.push_back(std::move(Record));
  return true;
}

std::optional<APInt> findUniqueCaseEntryState(
    BasicBlock *Source, BasicBlock *Header, BasicBlock *Join,
    const DenseMap<BasicBlock *, APInt> &CaseStates) {
  SmallVector<BasicBlock *, 16> Work{Source};
  SmallPtrSet<BasicBlock *, 32> Seen;
  std::optional<APInt> Found;
  while (!Work.empty() && Seen.size() <= 64) {
    BasicBlock *BB = Work.pop_back_val();
    if (!Seen.insert(BB).second) continue;
    auto It = CaseStates.find(BB);
    if (It != CaseStates.end()) {
      if (Found && *Found != It->second) return std::nullopt;
      Found = It->second;
      continue;
    }
    if (BB == Header || BB == Join) continue;
    for (BasicBlock *Pred : predecessors(BB))
      Work.push_back(Pred);
  }
  return Found;
}

// Proves and bypasses the subset of a memory-join dispatcher whose reaching
// state definitions are constants or selects of constants.  The central
// dispatcher remains for every unproved predecessor; this is the minimal
// residual form required by the design, not a completeness claim.
unsigned recoverMemoryJoinTransitions(
    SwitchInst &SI, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() != Header ||
      !canCloneHeaderPlumbing(Header, State))
    return 0;
  // This partial bypass clones only the current header.  A partitioned lookup
  // has later shards that still consume the header PHI; removing incoming
  // edges can then fold that PHI to a latch-local value which does not
  // dominate those shards.  Such a chain must be handled transactionally by
  // a complete partitioned-dispatcher engine.
  for (User *U : State->users()) {
    auto *UseI = dyn_cast<Instruction>(U);
    if (!UseI || UseI->getParent() != Header) return 0;
  }

  DenseMap<APInt, BasicBlock *> CaseMap;
  DenseMap<BasicBlock *, APInt> CaseStates;
  SmallPtrSet<BasicBlock *, 8> AmbiguousCaseStates;
  for (auto Case : SI.cases())
    CaseMap[Case.getCaseValue()->getValue()] = Case.getCaseSuccessor();
  if (CaseMap.size() < 4) return 0;
  for (auto Case : SI.cases()) {
    auto Raw = decodeStateExpr(SI.getCondition(), State,
                               Case.getCaseValue()->getValue());
    if (!Raw) continue;
    BasicBlock *Target = Case.getCaseSuccessor();
    auto It = CaseStates.find(Target);
    if (It == CaseStates.end())
      CaseStates.try_emplace(Target, *Raw);
    else if (It->second != *Raw)
      AmbiguousCaseStates.insert(Target);
  }
  for (BasicBlock *BB : AmbiguousCaseStates) CaseStates.erase(BB);
  auto Resolve = [&](const APInt &Raw) -> BasicBlock * {
    auto Encoded = evalStateExpr(SI.getCondition(), State, Raw);
    if (!Encoded) return nullptr;
    auto It = CaseMap.find(*Encoded);
    if (It == CaseMap.end() ||
        It->second->phis().begin() != It->second->phis().end())
      return nullptr;
    return It->second;
  };
  const bool DefaultCloneable = canCloneDefaultEntry(SI.getDefaultDest());
  const bool ExactSwitchTargetsCloneable =
      DefaultCloneable && llvm::all_of(successors(Header), [](BasicBlock *BB) {
        return BB->phis().empty();
      });

  SmallVector<MemoryJoinEdge, 64> Edges;
  for (unsigned I = 0; I != State->getNumIncomingValues(); ++I) {
    Value *Incoming = State->getIncomingValue(I);
    BasicBlock *Pred = State->getIncomingBlock(I);
    if (auto *Initial = dyn_cast<ConstantInt>(Incoming)) {
      auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
      BasicBlock *Target = Resolve(Initial->getValue());
      if (Br && Br->isUnconditional() && Br->getSuccessor(0) == Header &&
          Target) {
        MemoryJoinEdge E;
        E.Source = Pred;
        E.Through = Header;
        E.RawState = Initial;
        E.TrueTarget = Target;
        Edges.push_back(std::move(E));
      }
      continue;
    }
    auto *LI = dyn_cast<LoadInst>(Incoming);
    if (!LI || LI->isAtomic() || LI->isVolatile() || LI->getParent() != Pred)
      continue;
    IntAffine StateAddress = parsePointerAffine(LI->getPointerOperand());
    if (!StateAddress.Valid || StateAddress.Terms.empty())
      continue;
    auto *JoinBr = dyn_cast<BranchInst>(Pred->getTerminator());
    if (!JoinBr || !JoinBr->isUnconditional() ||
        JoinBr->getSuccessor(0) != Header)
      continue;
    for (BasicBlock *Source : predecessors(Pred)) {
      auto *Br = dyn_cast<BranchInst>(Source->getTerminator());
      if (!Br) continue;
      unsigned EdgeIndex = 0, EdgeCount = 0;
      for (unsigned S = 0; S != Br->getNumSuccessors(); ++S)
        if (Br->getSuccessor(S) == Pred) {
          EdgeIndex = S;
          ++EdgeCount;
        }
      if (EdgeCount != 1) continue;
      bool HitBarrier = false;
      StoreInst *Store = findReachingStateStore(
          Source, LI->getPointerOperand(), LI->getType(), Header, 0,
          &HitBarrier);
      PHINode *MergedState = nullptr;
      if (!Store && !HitBarrier)
        MergedState = buildMergedReachingStateValue(
            Source, LI->getPointerOperand(), LI->getType(), Header, Pred,
            CaseStates, State);
      if (!Store && !MergedState) {
        if (HitBarrier)
          Proofs.push_back({Header->getParent()->getName().str(),
                            "cff_transition_candidate", Source->getName().str(),
                            "memory_join_bv_evaluator", "barrier",
                            "unknown_memory_write_or_alias_barrier"});
        continue;
      }
      Value *Raw = Store ? Store->getValueOperand()
                         : static_cast<Value *>(MergedState);
      auto EntryState = findUniqueCaseEntryState(Source, Header, Pred,
                                                 CaseStates);
      std::optional<APInt> RawConstant;
      if (auto *C = dyn_cast<ConstantInt>(Raw))
        RawConstant = C->getValue();
      else if (EntryState)
        RawConstant = evalTransitionExpr(Raw, LI->getPointerOperand(),
                                         *EntryState);
      if (RawConstant) {
        MemoryJoinEdge E;
        E.Source = Source;
        E.Through = Pred;
        E.RawState = Raw;
        E.SuccessorIndex = EdgeIndex;
        E.TrueTarget = Resolve(*RawConstant);
        if (!E.TrueTarget && DefaultCloneable) {
          E.TrueTarget = SI.getDefaultDest();
          E.TrueViaDefault = true;
        }
        if (E.TrueTarget) {
          Edges.push_back(std::move(E));
        } else {
          Proofs.push_back({Header->getParent()->getName().str(),
                            "cff_transition_candidate", Source->getName().str(),
                            "memory_join_bv_evaluator", "unresolved",
                            "default_entry_not_safely_cloneable"});
          if (MergedState && MergedState->use_empty())
            MergedState->eraseFromParent();
        }
        continue;
      }
      auto *Sel = dyn_cast<SelectInst>(Raw);
      if (!Sel) {
        SmallVector<APInt, 8> FiniteValues;
        DenseMap<const Value *, APInt> NoBindings;
        unsigned ExecutionBudget = 128;
        std::string Certificate;
        bool Finite = EntryState &&
                      enumerateTransitionValues(
                          Raw, LI->getPointerOperand(), *EntryState,
                          NoBindings, FiniteValues, ExecutionBudget) &&
                      FiniteValues.size() >= 2 &&
                      proveFiniteTransitionSetSMT(Raw, FiniteValues,
                                                  Certificate);
        MemoryJoinEdge E;
        if (Finite) {
          E.Source = Source;
          E.Through = Pred;
          E.RawState = Raw;
          E.SuccessorIndex = EdgeIndex;
          E.FiniteRawValues = FiniteValues;
          E.FiniteSetCertificate = std::move(Certificate);
          for (const APInt &Value : FiniteValues) {
            BasicBlock *Target = Resolve(Value);
            bool ViaDefault = false;
            if (!Target && DefaultCloneable) {
              Target = SI.getDefaultDest();
              ViaDefault = true;
            }
            if (!Target) {
              Finite = false;
              break;
            }
            E.FiniteTargets.push_back(Target);
            E.FiniteViaDefault.push_back(ViaDefault);
          }
        }
        if (Finite) {
          Edges.push_back(std::move(E));
          continue;
        }
        if (EntryState && ExactSwitchTargetsCloneable) {
          E = MemoryJoinEdge();
          E.Source = Source;
          E.Through = Pred;
          E.RawState = Raw;
          E.SuccessorIndex = EdgeIndex;
          E.ExactSwitchClone = true;
          Edges.push_back(std::move(E));
          continue;
        }
        Proofs.push_back({
            Header->getParent()->getName().str(),
            "cff_transition_candidate", Source->getName().str(),
            "memory_join_finite_set_executor", "unresolved",
            EntryState
                ? "transition_set_not_exhaustive_or_smt_membership_unproved"
                : "case_entry_state_not_unique"});
        if (MergedState && MergedState->use_empty())
          MergedState->eraseFromParent();
        continue;
      }
      auto EvalArm = [&](Value *Arm) -> std::optional<APInt> {
        if (auto *C = dyn_cast<ConstantInt>(Arm)) return C->getValue();
        if (!EntryState) return std::nullopt;
        return evalTransitionExpr(Arm, LI->getPointerOperand(), *EntryState);
      };
      auto TC = EvalArm(Sel->getTrueValue());
      auto FC = EvalArm(Sel->getFalseValue());
      if (!TC || !FC) {
        Proofs.push_back({Header->getParent()->getName().str(),
                          "cff_transition_candidate", Source->getName().str(),
                          "memory_join_bv_evaluator", "unresolved",
                          "ite_arm_not_reduced_to_constant"});
        if (MergedState && MergedState->use_empty())
          MergedState->eraseFromParent();
        continue;
      }
      MemoryJoinEdge E;
      E.Source = Source;
      E.Through = Pred;
      E.RawState = Raw;
      E.Condition = Sel->getCondition();
      E.SuccessorIndex = EdgeIndex;
      E.TrueTarget = Resolve(*TC);
      E.FalseTarget = Resolve(*FC);
      if (!E.TrueTarget && DefaultCloneable) {
        E.TrueTarget = SI.getDefaultDest();
        E.TrueViaDefault = true;
      }
      if (!E.FalseTarget && DefaultCloneable) {
        E.FalseTarget = SI.getDefaultDest();
        E.FalseViaDefault = true;
      }
      if (E.TrueTarget && E.FalseTarget)
        Edges.push_back(std::move(E));
      else
        Proofs.push_back({Header->getParent()->getName().str(),
                          "cff_transition_candidate", Source->getName().str(),
                          "memory_join_bv_evaluator", "unresolved",
                          "ite_default_entry_not_safely_cloneable"});
      if ((!E.TrueTarget || !E.FalseTarget) && MergedState &&
          MergedState->use_empty())
        MergedState->eraseFromParent();
    }
  }
  if (Edges.empty()) return 0;

  std::string FunctionName = Header->getParent()->getName().str();
  // Clone every copy of the dispatcher plumbing before removing any incoming
  // edge.  removePredecessor() may simplify (and delete) the state PHI.
  for (MemoryJoinEdge &E : Edges) {
    Instruction *Old = E.Source->getTerminator();
    if (Old->getNumSuccessors() == 1) {
      cloneHeaderPlumbing(Header, State, E.RawState, Old, &E.HeaderMap);
    } else {
      E.EdgeBlock = BasicBlock::Create(
          Header->getContext(), E.Source->getName() + ".deobf.dispatch.edge",
          Header->getParent(), E.Through);
      Instruction *Temporary = BranchInst::Create(E.Through, E.EdgeBlock);
      cloneHeaderPlumbing(Header, State, E.RawState, Temporary, &E.HeaderMap);
    }
    bool FiniteUsesDefault = llvm::is_contained(E.FiniteViaDefault, true);
    if (E.TrueViaDefault || E.FalseViaDefault || FiniteUsesDefault ||
        E.ExactSwitchClone) {
      std::string Suffix = ".deobf.from." + E.Source->getName().str();
      E.DefaultClone = cloneDefaultEntry(
          SI.getDefaultDest(), E.HeaderMap, Suffix);
      if (E.TrueViaDefault) E.TrueTarget = E.DefaultClone;
      if (E.FalseViaDefault) E.FalseTarget = E.DefaultClone;
      for (unsigned I = 0; I != E.FiniteTargets.size(); ++I)
        if (E.FiniteViaDefault[I]) E.FiniteTargets[I] = E.DefaultClone;
    }
  }
  for (MemoryJoinEdge &E : Edges) {
    Instruction *Old = E.Source->getTerminator();
    E.Through->removePredecessor(E.Source);
    Instruction *Replace = Old;
    if (E.EdgeBlock) {
      Old->setSuccessor(E.SuccessorIndex, E.EdgeBlock);
      Replace = E.EdgeBlock->getTerminator();
    }
    if (E.ExactSwitchClone) {
      Value *Condition = E.HeaderMap.lookup(SI.getCondition());
      if (!Condition)
        report_fatal_error("exact dispatcher clone lost mapped condition");
      auto *ExactSwitch = SwitchInst::Create(
          Condition, E.DefaultClone, SI.getNumCases(), Replace->getIterator());
      for (auto Case : SI.cases())
        ExactSwitch->addCase(Case.getCaseValue(), Case.getCaseSuccessor());
    } else if (!E.FiniteRawValues.empty()) {
      auto *FiniteSwitch = SwitchInst::Create(
          E.RawState, E.FiniteTargets.front(),
          E.FiniteRawValues.size() - 1, Replace->getIterator());
      for (unsigned I = 1; I != E.FiniteRawValues.size(); ++I)
        FiniteSwitch->addCase(
            ConstantInt::get(E.RawState->getContext(), E.FiniteRawValues[I]),
            E.FiniteTargets[I]);
    } else if (E.Condition)
      BranchInst::Create(E.TrueTarget, E.FalseTarget, E.Condition,
                         Replace->getIterator());
    else
      BranchInst::Create(E.TrueTarget, Replace->getIterator());
    Replace->eraseFromParent();
    if (E.ExactSwitchClone) {
      ProofRecord Record{FunctionName, "cff_transition",
                         E.Source->getName().str(),
                         "memory_join_exact_dispatcher_clone", "proved"};
      Record.ProofQueryHash = hashText(valueText(SI));
      Record.Dependencies.push_back("exact_header_plumbing_clone");
      Record.Dependencies.push_back("exhaustive_original_switch_cases");
      Record.Dependencies.push_back("exact_default_entry_clone");
      Proofs.push_back(std::move(Record));
    } else if (!E.FiniteRawValues.empty()) {
      ProofRecord Record{FunctionName, "cff_transition",
                         E.Source->getName().str(),
                         "memory_join_finite_set_z3_unsat", "proved"};
      Record.ProofQueryHash = hashText(E.FiniteSetCertificate);
      Record.Dependencies.push_back("bounded_acyclic_fork_merge_enumeration");
      Record.Dependencies.push_back("exhaustive_transition_set_smt_membership");
      Record.Dependencies.push_back("exact_header_plumbing_clone");
      Proofs.push_back(std::move(Record));
    } else {
      Proofs.push_back({FunctionName, "cff_transition",
                        E.Source->getName().str(),
                        (E.TrueViaDefault || E.FalseViaDefault)
                            ? "memory_join_default_entry_clone"
                            : "memory_join_constant_or_select",
                        "proved"});
    }
  }
  return Edges.size();
}

} // namespace brighten_ollvm_deobf
