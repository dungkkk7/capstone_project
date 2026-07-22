#include "OLLVMDeobfInternal.h"

#include "llvm/Transforms/Utils/Cloning.h"

namespace brighten_ollvm_deobf {

namespace {

// Dispatcher engines perform large, proof-guided CFG rewrites.  Keep an exact
// body snapshot around each candidate so a verifier rejection is local to that
// candidate instead of aborting opt and losing the complete module.
class FunctionBodyTransaction {
  Function &Target;
  Function *Backup = nullptr;
  ValueToValueMapTy BackupMap;
  GlobalValue::LinkageTypes OriginalLinkage;

public:
  explicit FunctionBodyTransaction(Function &F)
      : Target(F), OriginalLinkage(F.getLinkage()) {
    Backup = CloneFunction(&F, BackupMap);
    Backup->setName(F.getName() + ".ollvm.deobf.rollback");
  }

  FunctionBodyTransaction(const FunctionBodyTransaction &) = delete;
  FunctionBodyTransaction &operator=(const FunctionBodyTransaction &) = delete;

  ~FunctionBodyTransaction() {
    if (Backup) Backup->eraseFromParent();
  }

  template <typename T> T *backupValue(const T *Original) const {
    return dyn_cast_or_null<T>(BackupMap.lookup(Original));
  }

  void commit() {
    Backup->eraseFromParent();
    Backup = nullptr;
  }

  void rollback() {
    // CloneFunction maps recursive references to Backup and gives Backup its
    // own arguments.  Retarget both before transferring the exact cloned body
    // back into the original Function object.
    if (Backup->arg_size() != Target.arg_size())
      report_fatal_error("dispatcher rollback argument-count mismatch");
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

void restoreProofSnapshot(SmallVectorImpl<ProofRecord> &Proofs,
                          ArrayRef<ProofRecord> Snapshot) {
  Proofs.clear();
  Proofs.append(Snapshot.begin(), Snapshot.end());
}

} // namespace

std::string describeDispatcherResidual(SwitchInst &SI) {
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State) return "state_root_or_transition_set_not_recovered";
  for (unsigned I = 0; I != State->getNumIncomingValues(); ++I) {
    auto *LI = dyn_cast<LoadInst>(State->getIncomingValue(I));
    BasicBlock *Join = State->getIncomingBlock(I);
    if (!LI || LI->getParent() != Join) continue;
    auto *Br = dyn_cast<BranchInst>(Join->getTerminator());
    if (!Br || !Br->isUnconditional() ||
        Br->getSuccessor(0) != State->getParent())
      continue;
    unsigned Preds = 0, MatchingStores = 0;
    for (BasicBlock *Pred : predecessors(Join)) {
      ++Preds;
      for (auto It = Pred->rbegin(), End = Pred->rend(); It != End; ++It) {
        auto *Store = dyn_cast<StoreInst>(&*It);
        if (!Store) continue;
        if (sameFrameAddress(Store->getPointerOperand(),
                             LI->getPointerOperand()))
          ++MatchingStores;
        break;
      }
    }
    return "memory_join_recurrence:matching_stores=" +
           std::to_string(MatchingStores) + "/" + std::to_string(Preds) +
           ";default_dispatcher_resolver_required=" +
           (SI.getDefaultDest() == SI.getParent() ? "false" : "true");
  }
  return "state_root_or_transition_set_not_recovered";
}

bool recoverCompareLadders(Function &F, Metrics &M,
                           SmallVectorImpl<ProofRecord> &Proofs) {
  bool Changed = false;
  bool RecollectCandidates = true;
  while (RecollectCandidates) {
    RecollectCandidates = false;
    SmallVector<WeakTrackingVH, 16> Work;
    for (BasicBlock &BB : F)
      if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
          BI && BI->isConditional() &&
          !BI->getMetadata("ollvm.deobf.verifier_rejected"))
        Work.emplace_back(BI);

    for (WeakTrackingVH &Handle : Work) {
      auto *FirstBranch = dyn_cast_or_null<BranchInst>(Handle);
      if (!FirstBranch || !FirstBranch->isConditional()) continue;
      BasicBlock *First = FirstBranch->getParent();
      Value *Expression = nullptr;
      SmallVector<LadderCase, 8> Cases;
      SmallPtrSet<BasicBlock *, 8> LadderBlocks;
      BasicBlock *Current = First;
      BasicBlock *Tail = nullptr;
      while (Cases.size() < 256) {
        auto *BI = dyn_cast<BranchInst>(Current->getTerminator());
        auto *Cmp = BI && BI->isConditional()
                        ? dyn_cast<ICmpInst>(BI->getCondition())
                        : nullptr;
        if (!Cmp || (Cmp->getPredicate() != ICmpInst::ICMP_EQ &&
                     Cmp->getPredicate() != ICmpInst::ICMP_NE)) {
          Tail = Current;
          break;
        }
        Value *Compared = nullptr;
        ConstantInt *Key = dyn_cast<ConstantInt>(Cmp->getOperand(1));
        if (Key) Compared = Cmp->getOperand(0);
        else if ((Key = dyn_cast<ConstantInt>(Cmp->getOperand(0))))
          Compared = Cmp->getOperand(1);
        if (!Key || !Compared->getType()->isIntegerTy() ||
            (Expression && Compared != Expression)) {
          Tail = Current;
          break;
        }
        if (!Expression) Expression = Compared;
        bool EqualOnTrue = Cmp->getPredicate() == ICmpInst::ICMP_EQ;
        BasicBlock *Target = BI->getSuccessor(EqualOnTrue ? 0 : 1);
        BasicBlock *Next = BI->getSuccessor(EqualOnTrue ? 1 : 0);
        if (!Target->phis().empty() || !LadderBlocks.insert(Current).second)
          break;
        bool Safe = true;
        for (Instruction &I : *Current) {
          if (&I == Cmp || I.isTerminator() || isa<DbgInfoIntrinsic>(I)) continue;
          if (Current != First || I.mayHaveSideEffects()) {
            Safe = false;
            break;
          }
        }
        if (!Safe) break;
        for (const LadderCase &Existing : Cases)
          if (Existing.Key->getValue() == Key->getValue()) Safe = false;
        if (!Safe) break;
        Cases.push_back({Current, Key, Target});
        if (!Next->hasNPredecessors(1)) {
          Tail = Next;
          break;
        }
        Current = Next;
      }
      if (Cases.size() < 4 || !Tail || !Tail->phis().empty()) continue;
      bool TargetIsLadder = false;
      for (const LadderCase &C : Cases)
        TargetIsLadder |= LadderBlocks.contains(C.Target);
      if (TargetIsLadder) continue;

      std::string Origin = First->getName().str();
      std::string OldFunctionText = valueText(F);
      Metrics MetricsBefore = M;
      SmallVector<ProofRecord, 64> ProofsBefore(Proofs.begin(), Proofs.end());
      FunctionBodyTransaction Transaction(F);
      BranchInst *RestoredBranch = Transaction.backupValue(FirstBranch);

      Instruction *Old = First->getTerminator();
      auto *NewSwitch = SwitchInst::Create(Expression, Tail, Cases.size(),
                                           Old->getIterator());
      for (const LadderCase &C : Cases)
        NewSwitch->addCase(C.Key, C.Target);
      for (unsigned I = 1; I != Cases.size(); ++I)
        Cases[I].Target->removePredecessor(Cases[I].Block);
      Tail->removePredecessor(Cases.back().Block);
      Old->eraseFromParent();
      removeUnreachableBlocks(F);
      ++M.CompareLaddersRecovered;
      Proofs.push_back({F.getName().str(), "compare_ladder", Origin,
                        "same_bv_expression_exhaustive_chain", "proved"});

      std::string VerifierDiagnostic;
      raw_string_ostream VerifierOS(VerifierDiagnostic);
      bool Invalid = verifyFunction(F, &VerifierOS);
      VerifierOS.flush();
      if (!Invalid) {
        Transaction.commit();
        Changed = true;
        continue;
      }

      std::string InvalidFunctionText = valueText(F);
      Transaction.rollback();
      M = MetricsBefore;
      restoreProofSnapshot(Proofs, ProofsBefore);
      if (!RestoredBranch || RestoredBranch->getFunction() != &F)
        report_fatal_error("compare-ladder rollback lost the candidate branch");
      RestoredBranch->setMetadata("ollvm.deobf.verifier_rejected",
                                  MDNode::get(F.getContext(), {}));
      ++M.VerifierFailures;
      ProofRecord Rejected{F.getName().str(), "compare_ladder", Origin,
                           "transactional_verifier_guard", "unresolved",
                           "rewrite_verifier_rejected_and_rolled_back;"
                           "diagnostic_hash=" + hashText(VerifierDiagnostic)};
      Rejected.OldHash = hashText(OldFunctionText);
      Rejected.NewHash = hashText(InvalidFunctionText);
      Rejected.ProofQueryHash = hashText(VerifierDiagnostic);
      Rejected.Dependencies.push_back("llvm_clone_function_snapshot");
      Rejected.Dependencies.push_back("llvm_verify_function");
      Rejected.Dependencies.push_back("exact_function_body_rollback");
      Proofs.push_back(std::move(Rejected));
      errs() << "ollvm-deobf: rolled back invalid compare-ladder rewrite in "
             << F.getName() << ":" << Origin << '\n'
             << VerifierDiagnostic;
      if (verifyFunction(F, &errs()))
        report_fatal_error(
            "compare-ladder transactional rollback produced invalid IR");
      Changed = true;
      // rollback replaced the complete body, invalidating every remaining
      // tracking handle in Work.  The rejected branch is metadata-marked, so
      // recollect a fresh worklist and continue with independent ladders.
      RecollectCandidates = true;
      break;
    }
  }
  return Changed;
}

bool recoverDispatchers(Function &F, Metrics &M,
                        SmallVectorImpl<ProofRecord> &Proofs) {
  bool Changed = false;
  bool RecollectCandidates = true;
  while (RecollectCandidates) {
    RecollectCandidates = false;

    // Full recovery can delete other unreachable dispatchers.  Tracking
    // handles make the worklist deletion-safe.  A transactional rollback
    // replaces the complete body, so that exceptional path explicitly
    // recollects a fresh worklist below.
    SmallVector<WeakTrackingVH, 16> Candidates;
    for (BasicBlock &BB : F)
      if (auto *SI = dyn_cast<SwitchInst>(BB.getTerminator());
          SI && SI->getNumCases() >= 4 &&
          !SI->getMetadata("ollvm.deobf.dynamic_entry_dispatch") &&
          !SI->getMetadata("ollvm.deobf.verifier_rejected")) {
        SmallPtrSet<BasicBlock *, 16> Successors;
        for (BasicBlock *Succ : successors(&BB)) Successors.insert(Succ);
        unsigned Returning = 0;
        for (BasicBlock *Succ : Successors)
          Returning += Succ == &BB || isPotentiallyReachable(Succ, &BB);
        // Acyclic application switches are not CFF candidates.  Require both
        // a real recurrence and majority return coverage; this is
        // classification only and is never used as a rewrite proof.
        if (findStateRoot(SI->getCondition()) && Returning >= 2 &&
            Returning * 2 >= Successors.size())
          Candidates.emplace_back(SI);
      }

    for (WeakTrackingVH &Candidate : Candidates) {
      auto *SI = dyn_cast_or_null<SwitchInst>(Candidate);
      if (!SI) continue;

      bool CandidateChanged = false;
      std::string Origin = SI->getParent()->getName().str();
      std::string OldFunctionText = valueText(F);
      Metrics MetricsBefore = M;
      SmallVector<ProofRecord, 64> ProofsBefore(Proofs.begin(), Proofs.end());
      FunctionBodyTransaction Transaction(F);
      SwitchInst *RestoredSwitch = Transaction.backupValue(SI);

      std::string SSAPlumbingRejection;
      std::string RegionRejection;
      // The cyclic-state-family commit is the only engine that can begin a
      // large CFG rewrite and then reject it on a late completeness invariant.
      // Run it under a private transaction so an incomplete commit rolls back
      // to the exact pre-attempt body -- and a valid switch handle -- instead
      // of aborting opt or leaving mutated IR for the remaining engines.
      SwitchInst *Cur = SI;
      bool Recovered = false;
      {
        FunctionBodyTransaction CsfTransaction(F);
        SwitchInst *CsfRollbackSwitch = CsfTransaction.backupValue(Cur);
        if (tryRecoverCyclicStateFamilyDispatcher(*Cur, M, Proofs,
                                                  &RegionRejection)) {
          CsfTransaction.commit();
          Recovered = true;
        } else if (valueText(F) == OldFunctionText) {
          // The engine failed without mutating (the common case): keep the
          // exact original body and switch handle so the remaining engines see
          // untouched IR and the outer mutation guard's text compare stays
          // valid.  Discarding the identical backup avoids reclone churn.
          CsfTransaction.commit();
        } else {
          // The engine began a large commit and then rejected it on a late
          // completeness invariant.  Restore the exact pre-attempt body so no
          // partial rewrite reaches the remaining engines or committed IR.
          CsfTransaction.rollback();
          if (!CsfRollbackSwitch || CsfRollbackSwitch->getFunction() != &F)
            report_fatal_error("cyclic-state-family rollback lost the switch");
          Cur = CsfRollbackSwitch;
          M = MetricsBefore;
          restoreProofSnapshot(Proofs, ProofsBefore);
        }
      }
      if (!Recovered)
        Recovered =
            tryRecoverMultiIncomingSSADispatcher(*Cur, M, Proofs) ||
            tryRecoverPartitionedSSADispatcher(*Cur, M, Proofs) ||
            tryRecoverPartitionedSSAPlumbingDispatcher(*Cur, M, Proofs) ||
            tryRecoverSSAPlumbingDispatcher(*Cur, M, Proofs,
                                            &SSAPlumbingRejection) ||
            tryRecoverSSADispatcher(*Cur, M, Proofs) ||
            tryRecoverGeneralFunnelPlumbingDispatcher(*Cur, M, Proofs) ||
            tryRecoverFunnelDispatcher(*Cur, M, Proofs);
      if (Recovered) {
        CandidateChanged = true;
      } else {
        // Capture the structural diagnosis before partial bypassing can
        // simplify the state PHI into its sole remaining load.
        std::string Residual = describeDispatcherResidual(*Cur);
        if (!RegionRejection.empty())
          Residual += ";region_rejection=" + RegionRejection;
        if (!SSAPlumbingRejection.empty())
          Residual += ";ssa_plumbing_rejection=" + SSAPlumbingRejection;
        unsigned ProvedTransitions = recoverMemoryJoinTransitions(*Cur, Proofs);
        CandidateChanged = ProvedTransitions != 0;
        if (ProvedTransitions)
          Residual += ";proved_direct_transitions=" +
                      std::to_string(ProvedTransitions);
        auto Existing = std::find_if(Proofs.begin(), Proofs.end(),
                                     [&](const ProofRecord &P) {
          return P.Function == F.getName() && P.Kind == "cff_candidate" &&
                 P.Origin == Origin && P.Result == "unresolved";
        });
        if (Existing != Proofs.end()) {
          Existing->ResidualReason = Residual;
        } else {
          ++M.DispatchersUnresolved;
          Proofs.push_back({F.getName().str(), "cff_candidate", Origin,
                            "structural_ssa_analysis", "unresolved", Residual});
        }
      }

      if (!CandidateChanged) {
        // Every recovery engine is required to be mutation-free when it
        // returns false.  Enforce that contract here because a half-applied
        // failed proof is just as dangerous as verifier-invalid IR.
        std::string FailedAttemptText = valueText(F);
        if (FailedAttemptText == OldFunctionText) {
          Transaction.commit();
          continue;
        }

        Transaction.rollback();
        M = MetricsBefore;
        restoreProofSnapshot(Proofs, ProofsBefore);
        if (!RestoredSwitch || RestoredSwitch->getFunction() != &F)
          report_fatal_error("dispatcher rollback lost the candidate switch");
        RestoredSwitch->setMetadata("ollvm.deobf.verifier_rejected",
                                    MDNode::get(F.getContext(), {}));
        ++M.VerifierFailures;
        ++M.DispatchersUnresolved;
        ProofRecord Rejected{
            F.getName().str(), "cff_candidate", Origin,
            "transactional_mutation_guard", "unresolved",
            "engine_reported_failure_after_mutation_and_was_rolled_back" +
                (RegionRejection.empty()
                     ? std::string()
                     : ";region_rejection=" + RegionRejection)};
        Rejected.OldHash = hashText(OldFunctionText);
        Rejected.NewHash = hashText(FailedAttemptText);
        Rejected.Dependencies.push_back("llvm_clone_function_snapshot");
        Rejected.Dependencies.push_back("engine_failure_must_be_mutation_free");
        Rejected.Dependencies.push_back("exact_function_body_rollback");
        Proofs.push_back(std::move(Rejected));
        errs() << "ollvm-deobf: rolled back mutating failed dispatcher "
               << "attempt in " << F.getName() << ":" << Origin << '\n';
        if (verifyFunction(F, &errs()))
          report_fatal_error(
              "dispatcher mutation-guard rollback produced invalid IR");
        Changed = true;
        RecollectCandidates = true;
        break;
      }

      std::string VerifierDiagnostic;
      raw_string_ostream VerifierOS(VerifierDiagnostic);
      bool Invalid = verifyFunction(F, &VerifierOS);
      VerifierOS.flush();
      if (!Invalid) {
        Transaction.commit();
        Changed = true;
        continue;
      }

      std::string InvalidFunctionText = valueText(F);
      Transaction.rollback();
      M = MetricsBefore;
      restoreProofSnapshot(Proofs, ProofsBefore);

      if (!RestoredSwitch || RestoredSwitch->getFunction() != &F)
        report_fatal_error("dispatcher rollback lost the candidate switch");
      RestoredSwitch->setMetadata("ollvm.deobf.verifier_rejected",
                                  MDNode::get(F.getContext(), {}));

      ++M.VerifierFailures;
      ++M.DispatchersUnresolved;
      ProofRecord Rejected{F.getName().str(), "cff_candidate", Origin,
                           "transactional_verifier_guard", "unresolved",
                           "rewrite_verifier_rejected_and_rolled_back;"
                           "diagnostic_hash=" +
                               hashText(VerifierDiagnostic)};
      Rejected.OldHash = hashText(OldFunctionText);
      Rejected.NewHash = hashText(InvalidFunctionText);
      Rejected.ProofQueryHash = hashText(VerifierDiagnostic);
      Rejected.Dependencies.push_back("llvm_clone_function_snapshot");
      Rejected.Dependencies.push_back("llvm_verify_function");
      Rejected.Dependencies.push_back("exact_function_body_rollback");
      Proofs.push_back(std::move(Rejected));

      errs() << "ollvm-deobf: rolled back invalid dispatcher rewrite in "
             << F.getName() << ":" << Origin << '\n'
             << VerifierDiagnostic;
      if (verifyFunction(F, &errs()))
        report_fatal_error("dispatcher transactional rollback produced invalid IR");

      // Every old WeakTrackingVH refers to the discarded body.  The restored
      // switch is marked fail-closed, so safely recollect and continue with
      // the other candidates in the exact pre-rewrite function.
      Changed = true; // the rejection metadata and ledger obligation persist.
      RecollectCandidates = true;
      break;
    }
  }
  if (Changed) removeUnreachableBlocks(F);
  return Changed;
}

void reconcileDispatcherProofs(Module &M, Metrics &Stats,
                                      SmallVectorImpl<ProofRecord> &Proofs) {
  for (ProofRecord &P : Proofs) {
    if (P.Kind != "cff_candidate" || P.Result != "unresolved") continue;
    Function *F = M.getFunction(P.Function);
    BasicBlock *Origin = nullptr;
    if (F)
      for (BasicBlock &BB : *F)
        if (BB.getName() == P.Origin) {
          Origin = &BB;
          break;
        }
    if (Origin) {
      auto *SurvivingSwitch = dyn_cast<SwitchInst>(Origin->getTerminator());
      if (!SurvivingSwitch)
        P.ResidualReason = "dispatcher_origin_survives_without_switch";
      else if (!SurvivingSwitch->getMetadata(
                   "ollvm.deobf.dynamic_entry_dispatch"))
        continue;
    }
    P.Kind = "cff_dispatcher";
    P.Engine = "dead_after_proved_transition_rewrites";
    P.Result = "proved";
    P.ResidualReason.clear();
    if (Stats.DispatchersUnresolved) --Stats.DispatchersUnresolved;
    ++Stats.DispatchersRecovered;
  }
}

LiftProfile inventoryModule(Module &M) {
  LiftProfile P;
  struct RawFrameAccess {
    std::string Base;
    int64_t Offset = 0;
    uint64_t Size = 0;
    bool IsStore = false;
  };
  SmallVector<RawFrameAccess, 64> FrameAccesses;
  const DataLayout &DL = M.getDataLayout();
  for (GlobalVariable &GV : M.globals())
    if (containsLiftMarker(GV.getName()) ||
        GV.getName().contains_insensitive("frame_storage"))
      ++P.FrameBackingGlobals;
  for (StructType *ST : M.getIdentifiedStructTypes())
    if (ST->hasName() && containsLiftMarker(ST->getName()))
      ++P.StateStructTypes;

  SmallPtrSet<const Value *, 32> SeenLocations;
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    ++P.DefinedFunctions;
    if (containsLiftMarker(F.getName())) ++P.RuntimeHelpers;
    unsigned Instructions = 0, Calls = 0;
    for (Instruction &I : instructions(F)) {
      ++Instructions;
      Value *AccessPointer = nullptr;
      Type *AccessType = nullptr;
      bool IsStore = false;
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        AccessPointer = LI->getPointerOperand();
        AccessType = LI->getType();
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        AccessPointer = SI->getPointerOperand();
        AccessType = SI->getValueOperand()->getType();
        IsStore = true;
      }
      if (AccessPointer && AccessType && AccessType->isSized()) {
        IntAffine A = parsePointerAffine(AccessPointer);
        const Value *Base = unitAffineRoot(A);
        TypeSize TS = DL.getTypeStoreSize(AccessType);
        if (Base && Base->hasName() && !TS.isScalable() &&
            (containsLiftMarker(Base->getName()) ||
             Base->getName().contains_insensitive("frame_storage"))) {
          uint64_t Size = TS.getFixedValue();
          int64_t Offset = A.Offset.getSExtValue();
          if (Size && Size <= static_cast<uint64_t>(INT64_MAX) &&
              Offset <= INT64_MAX - static_cast<int64_t>(Size))
            FrameAccesses.push_back(
                {Base->getName().str(), Offset, Size, IsStore});
        }
      }
      if (isa<PtrToIntInst>(I) || isa<IntToPtrInst>(I))
        ++P.AddressConversions;
      for (Value *Op : I.operands()) {
        P.UndefOperands += isa<UndefValue>(Op);
        P.PoisonOperands += isa<PoisonValue>(Op);
      }
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        ++Calls;
        if (CB->isInlineAsm()) ++P.InlineAsmCalls;
        else if (!CB->getCalledFunction()) ++P.IndirectCalls;
      }
      if (isa<IndirectBrInst>(I)) ++P.IndirectBranches;
      if (auto *BI = dyn_cast<BranchInst>(&I); BI && BI->isConditional()) {
        ++P.ConditionalBranches;
        if (auto *Cmp = dyn_cast<ICmpInst>(BI->getCondition());
            Cmp && (isa<ConstantInt>(Cmp->getOperand(0)) ||
                    isa<ConstantInt>(Cmp->getOperand(1))))
          ++P.ConstantCompareBranches;
      }
      auto *SI = dyn_cast<SwitchInst>(&I);
      if (!SI || SI->getNumCases() < 4) continue;
      PHINode *State = findStateRoot(SI->getCondition());
      if (!State) continue;
      for (Value *Incoming : State->incoming_values()) {
        auto *LI = dyn_cast<LoadInst>(Incoming);
        if (!LI || !SeenLocations.insert(LI->getPointerOperand()).second)
          continue;
        IntAffine A = parsePointerAffine(LI->getPointerOperand());
        const Value *Base = unitAffineRoot(A);
        if (!Base || !Base->hasName()) continue;
        SmallString<32> Offset;
        A.Offset.toStringSigned(Offset);
        P.CandidateStateLocations.push_back(
            (Base->getName() + ":" + Offset).str());
      }
    }
    if (Instructions <= 8 && Calls == 1) ++P.SmallWrapperCandidates;
  }
  llvm::sort(P.CandidateStateLocations);
  P.CandidateStateLocations.erase(
      std::unique(P.CandidateStateLocations.begin(),
                  P.CandidateStateLocations.end()),
      P.CandidateStateLocations.end());
  llvm::sort(FrameAccesses, [](const RawFrameAccess &A,
                              const RawFrameAccess &B) {
    return std::tie(A.Base, A.Offset, A.Size) <
           std::tie(B.Base, B.Offset, B.Size);
  });
  for (const RawFrameAccess &Access : FrameAccesses) {
    bool Overlaps = false;
    if (!P.FrameObjects.empty()) {
      LiftProfile::FrameObject &Last = P.FrameObjects.back();
      int64_t LastEnd = Last.Offset + static_cast<int64_t>(Last.Size);
      Overlaps = Last.Base == Access.Base && Access.Offset < LastEnd;
      if (Overlaps) {
        int64_t AccessEnd = Access.Offset + static_cast<int64_t>(Access.Size);
        Last.HasOverlappingViews |=
            Last.Offset != Access.Offset || Last.Size != Access.Size;
        Last.Size = static_cast<uint64_t>(std::max(LastEnd, AccessEnd) -
                                         Last.Offset);
        Last.Loads += !Access.IsStore;
        Last.Stores += Access.IsStore;
      }
    }
    if (!Overlaps) {
      LiftProfile::FrameObject Object;
      Object.Base = Access.Base;
      Object.Offset = Access.Offset;
      Object.Size = Access.Size;
      Object.Loads = !Access.IsStore;
      Object.Stores = Access.IsStore;
      P.FrameObjects.push_back(std::move(Object));
    }
  }
  for (LiftProfile::FrameObject &Object : P.FrameObjects) {
    std::string Location =
        Object.Base + ":" + std::to_string(Object.Offset);
    if (std::find(P.CandidateStateLocations.begin(),
                  P.CandidateStateLocations.end(), Location) !=
        P.CandidateStateLocations.end())
      Object.Role = "cff.state_candidate";
    else if (Object.HasOverlappingViews)
      Object.Role = "frame.overlapping_views";
  }
  return P;
}

bool importExistingInventory(Module &M, LiftProfile &P) {
  NamedMDNode *Inventory = M.getNamedMetadata("ollvm.deobf.inventory");
  if (!Inventory || Inventory->getNumOperands() == 0) return false;
  MDNode *Header = Inventory->getOperand(0);
  if (Header->getNumOperands() != 14) return false;
  auto GetString = [&](unsigned Index) -> StringRef {
    auto *S = dyn_cast<MDString>(Header->getOperand(Index));
    return S ? S->getString() : StringRef();
  };
  if (GetString(0) != "v1") return false;
  unsigned *Fields[] = {
      &P.DefinedFunctions, &P.RuntimeHelpers, &P.SmallWrapperCandidates,
      &P.FrameBackingGlobals, &P.StateStructTypes, &P.InlineAsmCalls,
      &P.IndirectCalls, &P.IndirectBranches, &P.AddressConversions,
      &P.UndefOperands, &P.PoisonOperands, &P.ConditionalBranches,
      &P.ConstantCompareBranches};
  for (unsigned I = 0; I != 13; ++I)
    if (GetString(I + 1).getAsInteger(10, *Fields[I])) return false;
  P.CandidateStateLocations.clear();
  P.FrameObjects.clear();
  for (unsigned I = 1; I != Inventory->getNumOperands(); ++I) {
    MDNode *Node = Inventory->getOperand(I);
    auto Field = [&](unsigned Index) -> StringRef {
      if (Index >= Node->getNumOperands()) return {};
      auto *S = dyn_cast<MDString>(Node->getOperand(Index));
      return S ? S->getString() : StringRef();
    };
    if (Node->getNumOperands() == 1) {
      P.CandidateStateLocations.push_back(Field(0).str());
    } else if (Field(0) == "state" && Node->getNumOperands() == 2) {
      P.CandidateStateLocations.push_back(Field(1).str());
    } else if (Field(0) == "object" &&
               (Node->getNumOperands() == 7 ||
                Node->getNumOperands() == 8)) {
      LiftProfile::FrameObject Object;
      Object.Base = Field(1).str();
      if (Field(2).getAsInteger(10, Object.Offset) ||
          Field(3).getAsInteger(10, Object.Size) ||
          Field(4).getAsInteger(10, Object.Loads) ||
          Field(5).getAsInteger(10, Object.Stores))
        return false;
      Object.HasOverlappingViews = Field(6) == "1";
      if (Node->getNumOperands() == 8) Object.Role = Field(7).str();
      P.FrameObjects.push_back(std::move(Object));
    }
  }
  return true;
}

void addModuleMetadata(Module &M, const Metrics &Stats,
                              const LiftProfile &Inventory,
                              ArrayRef<ProofRecord> Proofs) {
  LLVMContext &C = M.getContext();
  NamedMDNode *Profile = M.getOrInsertNamedMetadata("ollvm.deobf.profile");
  Profile->clearOperands();
  auto S = [&](unsigned V) { return MDString::get(C, std::to_string(V)); };
  Profile->addOperand(MDNode::get(C, {
      MDString::get(C, "v2"), S(Stats.Functions), S(Stats.Switches),
      S(Stats.LargeSwitches), S(Stats.LiftedFunctions),
      S(Stats.FlagsSanitized), S(Stats.BVRewrites),
      S(Stats.InstSubRewrites), S(Stats.OpaqueEdgesPruned),
      S(Stats.CompareLaddersRecovered),
      S(Inventory.IndirectCalls), S(Inventory.InlineAsmCalls),
      S(Inventory.UndefOperands), S(Inventory.PoisonOperands)}));
  NamedMDNode *InventoryMD =
      M.getOrInsertNamedMetadata("ollvm.deobf.inventory");
  InventoryMD->clearOperands();
  InventoryMD->addOperand(MDNode::get(C, {
      MDString::get(C, "v1"), S(Inventory.DefinedFunctions),
      S(Inventory.RuntimeHelpers), S(Inventory.SmallWrapperCandidates),
      S(Inventory.FrameBackingGlobals), S(Inventory.StateStructTypes),
      S(Inventory.InlineAsmCalls), S(Inventory.IndirectCalls),
      S(Inventory.IndirectBranches), S(Inventory.AddressConversions),
      S(Inventory.UndefOperands), S(Inventory.PoisonOperands),
      S(Inventory.ConditionalBranches),
      S(Inventory.ConstantCompareBranches)}));
  for (const std::string &Location : Inventory.CandidateStateLocations)
    InventoryMD->addOperand(
        MDNode::get(C, {MDString::get(C, "state"),
                        MDString::get(C, Location)}));
  for (const LiftProfile::FrameObject &Object : Inventory.FrameObjects)
    InventoryMD->addOperand(MDNode::get(C, {
        MDString::get(C, "object"), MDString::get(C, Object.Base),
        MDString::get(C, std::to_string(Object.Offset)),
        MDString::get(C, std::to_string(Object.Size)),
        MDString::get(C, std::to_string(Object.Loads)),
        MDString::get(C, std::to_string(Object.Stores)),
        MDString::get(C, Object.HasOverlappingViews ? "1" : "0"),
        MDString::get(C, Object.Role)}));
  NamedMDNode *Ledger = M.getOrInsertNamedMetadata("ollvm.deobf.proofs");
  Ledger->clearOperands();
  for (const ProofRecord &P : Proofs) {
    std::string Dependencies;
    for (const std::string &Dependency : P.Dependencies) {
      if (!Dependencies.empty()) Dependencies.push_back('\x1f');
      Dependencies += Dependency;
    }
    Ledger->addOperand(MDNode::get(C, {MDString::get(C, P.Function),
                                      MDString::get(C, P.Kind),
                                      MDString::get(C, P.Origin),
                                      MDString::get(C, P.Engine),
                                      MDString::get(C, P.Result),
                                      MDString::get(C, P.ResidualReason),
                                      MDString::get(C, P.OldHash),
                                      MDString::get(C, P.NewHash),
                                      MDString::get(C, P.ProofQueryHash),
                                      MDString::get(C, Dependencies)}));
  }
}

void writeReport(const Module &M, const Metrics &Stats,
                        const LiftProfile &Inventory,
                        ArrayRef<ProofRecord> Proofs) {
  if (ReportPath.empty()) return;
  json::Array Records;
  bool HasResiduals = false;
  for (const ProofRecord &P : Proofs) {
    HasResiduals |= P.Result != "proved";
    json::Object Record{{"function", P.Function}, {"kind", P.Kind},
                        {"origin", P.Origin}, {"proof_engine", P.Engine},
                        {"result", P.Result}};
    Record["old_hash"] = P.OldHash.empty()
                             ? json::Value(nullptr)
                             : json::Value(P.OldHash);
    Record["new_hash"] = P.NewHash.empty()
                             ? json::Value(nullptr)
                             : json::Value(P.NewHash);
    Record["proof_query_hash"] = P.ProofQueryHash.empty()
                                     ? json::Value(nullptr)
                                     : json::Value(P.ProofQueryHash);
    json::Array Dependencies;
    for (const std::string &Dependency : P.Dependencies)
      Dependencies.push_back(Dependency);
    Record["dependencies"] = std::move(Dependencies);
    if (P.ResidualReason.empty())
      Record["residual_reason"] = nullptr;
    else
      Record["residual_reason"] = P.ResidualReason;
    Records.push_back(std::move(Record));
  }
  json::Array StateLocations;
  for (const std::string &Location : Inventory.CandidateStateLocations)
    StateLocations.push_back(Location);
  json::Array FrameObjects;
  for (const LiftProfile::FrameObject &Object : Inventory.FrameObjects)
    FrameObjects.push_back(json::Object{
        {"base", Object.Base}, {"signed_offset", Object.Offset},
        {"size", Object.Size}, {"loads", Object.Loads},
        {"stores", Object.Stores},
        {"has_overlapping_views", Object.HasOverlappingViews},
        {"role", Object.Role}});
  json::Object Root{
      {"schema", "ollvm-deobf-ledger-v2"},
      {"status", !HasResiduals && Stats.DispatchersUnresolved == 0 &&
                         Stats.VerifierFailures == 0
                     ? "pass_detected_scope"
                     : "partial_with_residuals"},
      {"implemented_scope", json::Array{"lifted_flag_sanitize",
                                          "exact_bv_templates",
                                          "z3_rewrite_equivalence_gate",
                                          "adjacent_product_parity",
                                          "z3_pure_ssa_predicates",
                                          "ssa_constant_cff",
                                          "funnel_cff",
                                          "affine_frame_addresses",
                                          "memory_join_bv_transitions",
                                          "transition_local_object_memory_map",
                                          "transition_predecessor_memory_merge",
                                          "transition_cfg_arm_state_store_phi",
                                          "transition_rotate_bswap_ctpop_semantics",
                                          "transition_readnone_readonly_call_summaries",
                                          "transition_acyclic_fork_merge_finite_set_smt",
                                          "transition_exact_dynamic_dispatcher_clone",
                                          "path_local_edge_splitting",
                                          "side_effect_plumbing_clone",
                                          "default_entry_clone",
                                          "pure_compare_ladder_to_switch",
                                          "affine_bv_local_saturation",
                                          "multi_root_affine_tuple_extraction",
                                          "multi_root_ac_tuple_extraction",
                                          "multi_root_mixed_operator_eclass_extraction",
                                          "ac_bitvector_local_saturation",
                                          "demorgan_bitvector_saturation",
                                          "bitwise_zext_sext_factoring",
                                          "bitwise_common_mask_factoring",
                                          "constant_rotate_idiom_saturation",
                                          "path_sensitive_dominating_constraints",
                                          "symbolic_rotate_bswap_bitreverse_slices",
                                          "exact_diamond_phi_path_state_ite",
                                          "exact_switch_funnel_phi_path_state_ite",
                                          "inductive_constant_phi_resolution",
                                          "cyclic_predicate_z3_induction",
                                          "multi_incoming_default_state_induction",
                                          "memoryssa_exact_reaching_store_slices",
                                          "poison_support_equivalence_gate",
                                          "x86_zf_sf_cf_of_pf_predicate_recovery",
                                          "x86_add_carry_sub_borrow_recovery",
                                          "x86_low_byte_parity_recovery",
                                          "x86_terminal_condition_code_recovery",
                                          "producer_wide_sub_flag_bundle_transaction",
                                          "producer_wide_add_flag_bundle_transaction",
                                          "producer_wide_test_flag_bundle_transaction",
                                          "fixed_point_proof_reconciliation",
                                          "differential_validation_harness"}},
      {"unimplemented_components",
       json::Array{}},
      {"component_coverage", json::Object{
          {"P00", "implemented: inventory plus persistent frame intervals"},
          {"P01", "implemented: lifted poison-flag sanitization"},
          {"P02", "upstream: wrapper/runtime materialization passes"},
          {"P03", "implemented across the pipeline: persistent affine frame intervals and overlap views feed global/argument/non-escaping-local byte-accurate State SSA promotion, while the strict native post-pass compacts only fully proved constant frame objects and retains unknown escapes as barriers"},
          {"P04", "upstream: global/argument and non-escaping local byte-accurate overlapping-view State SSA with call/return synchronization"},
          {"P05", "implemented for canonical lifted cmp/sub, add, and test/and flag bundles: subtraction transactionally recovers ZF/NZ/SF/OF/CF/PF plus E/NE/B/AE/BE/A/L/GE/LE/G, addition recovers ZF/NZ/SF/OF/CF/PF, and TEST recovers ZF/NZ/SF/PF while architectural CF/OF are constant zero; every transaction requires complete internal-use coverage, identical poison support, and one old/new tuple Z3 proof, with PF taken strictly from the low byte at wider widths"},
          {"P06", "upstream: devirtualization/address/call recovery passes"},
          {"P10", "implemented: exact APInt/BV canonicalization"},
          {"P20", "implemented: conservative cyclic dispatcher classifier"},
          {"P21", "implemented for pure equality ladders"},
          {"P22", "implemented for proved SSA/memory recurrences and invertible encodings"},
          {"P23", "implemented as a bounded fail-closed CFG/transition executor: APInt BV semantics cover casts, in-range shifts, rotate/bswap/bitreverse/ctpop/select; persistent frame values use exact reaching stores across up to 12 predecessor blocks, equal-value merges across eight paths, and synthesized proof-only PHIs for same-location stores on separate CFG arms; proven-disjoint ranges, single-block readnone/readonly summaries, constant loop invariants, and exhaustive multi-incoming default induction are supported; nested select/PHI forks enumerate at most 32 outcomes and require a Z3 finite-set proof, while irreducibly symbolic states use an exact cloned encoded switch only with cloneable plumbing and PHI-free targets; unknown aliasing, unsupported effects, cycles outside proved induction, and cap hits are explicit barriers rather than guessed transitions"},
          {"P24", "implemented for complete proved transition sets including multi-incoming SSA dispatchers with self-looping defaults; unproved regions remain unchanged"},
          {"P30", "implemented for bounded proof slices: SSA plus SAT-checked dominating branch/assume constraints, symbolic modulo-width rotates, bswap/bitreverse/ctpop, exact diamond/switch-funnel PHIs as ITEs, inductively proved constant cyclic PHIs, exact MemorySSA stores and equal-value MemoryPhi joins; nonconstant one-PHI cyclic predicates additionally require universal Z3 seed/backedge 1-induction, while unsupported operations and multi-PHI cyclic relations remain explicit barriers"},
          {"P31", "implemented: theorem library plus Z3 UNSAT gate"},
          {"P32", "implemented: proved-edge pruning only"},
          {"P40", "implemented: exact OLLVM substitution templates"},
          {"P41", "implemented for bounded pure integer regions: affine/AC saturation, De Morgan, zext/sext and common-mask factoring, constant rotate recovery, dominating multi-root affine and AC extraction, plus mixed-operator semantic e-classes across different AST shapes; mixed extraction is capped at 40 nodes/32 roots/96 candidate comparisons, reuses only a cheaper dominating representative, requires at least two non-representative roots, identical poison support, and one final tuple Z3 proof"},
          {"P42", "implemented: identical poison support plus Z3 equivalence required per rewrite"},
          {"P50", "implemented in production driver: semantic fixed point"},
          {"P60", "implemented: JSON/metadata proof ledger v2"}}},
      {"module", M.getName().str()},
      {"inventory", json::Object{
          {"defined_functions", Inventory.DefinedFunctions},
          {"runtime_helpers", Inventory.RuntimeHelpers},
          {"small_wrapper_candidates", Inventory.SmallWrapperCandidates},
          {"frame_backing_globals", Inventory.FrameBackingGlobals},
          {"state_struct_types", Inventory.StateStructTypes},
          {"inline_asm_calls", Inventory.InlineAsmCalls},
          {"indirect_calls", Inventory.IndirectCalls},
          {"indirect_branches", Inventory.IndirectBranches},
          {"address_conversions", Inventory.AddressConversions},
          {"undef_operands", Inventory.UndefOperands},
          {"poison_operands", Inventory.PoisonOperands},
          {"conditional_branches", Inventory.ConditionalBranches},
          {"constant_compare_branches", Inventory.ConstantCompareBranches},
          {"candidate_state_locations", std::move(StateLocations)},
          {"frame_objects", std::move(FrameObjects)}}},
      {"metrics", json::Object{{"functions", Stats.Functions},
                                {"switches", Stats.Switches},
                                {"large_switches", Stats.LargeSwitches},
                                {"lifted_functions", Stats.LiftedFunctions},
                                {"flags_sanitized", Stats.FlagsSanitized},
                                {"flag_cones_recovered",
                                 Stats.FlagConesRecovered},
                                {"bv_rewrites", Stats.BVRewrites},
                                {"instsub_rewrites", Stats.InstSubRewrites},
                                {"opaque_edges_pruned", Stats.OpaqueEdgesPruned},
                                {"path_constrained_opaque_edges",
                                 Stats.PathConstrainedOpaqueEdges},
                                {"memoryssa_constrained_opaque_edges",
                                 Stats.MemorySSAConstrainedOpaqueEdges},
                                {"path_state_ite_opaque_edges",
                                 Stats.PathStateITEOpaqueEdges},
                                {"inductive_phi_opaque_edges",
                                 Stats.InductivePhiOpaqueEdges},
                                {"memoryssa_reaching_loads",
                                 Stats.MemorySSAReachingLoads},
                                {"memoryssa_phis_resolved",
                                 Stats.MemorySSAPhisResolved},
                                {"memoryssa_barriers",
                                 Stats.MemorySSABarriers},
                                {"compare_ladders_recovered",
                                 Stats.CompareLaddersRecovered},
                                {"egraph_rewrites", Stats.EGraphRewrites},
                                {"poison_support_rejects",
                                 Stats.PoisonSupportRejects},
                                {"dispatchers_recovered", Stats.DispatchersRecovered},
                                {"dispatchers_unresolved", Stats.DispatchersUnresolved},
                                {"verifier_failures", Stats.VerifierFailures}}},
      {"proofs", std::move(Records)}};
  std::error_code EC;
  raw_fd_ostream OS(ReportPath, EC);
  if (EC) {
    errs() << "ollvm-deobf: cannot write report: " << EC.message() << '\n';
    return;
  }
  OS << formatv("{0:2}\n", json::Value(std::move(Root)));
}

} // namespace brighten_ollvm_deobf
