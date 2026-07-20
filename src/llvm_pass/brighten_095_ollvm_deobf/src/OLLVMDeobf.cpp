#include "OLLVMDeobf.h"
#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

cl::opt<std::string> ReportPath(
    "ollvm-deobf-report", cl::desc("Write the OLLVM proof ledger as JSON"),
    cl::init(""));

bool rewriteFunction(Function &F, MemorySSA &MSSA, Metrics &M,
                            SmallVectorImpl<ProofRecord> &Proofs) {
  bool Changed = false;
  for (unsigned Round = 0; Round != 16; ++Round) {
    bool RoundChanged = false;
    SmallVector<BinaryOperator *, 64> Work;
    for (Instruction &I : instructions(F))
      if (auto *BO = dyn_cast<BinaryOperator>(&I))
        Work.push_back(BO);
    for (BinaryOperator *BO : Work) {
      if (!BO->getParent()) continue;
      bool InstSub = false;
      Value *Replacement = matchCanonicalRewrite(*BO, InstSub);
      if (!Replacement || Replacement == BO) continue;
      std::string Origin = valueName(*BO);
      std::string OldText = valueText(*BO);
      std::string NewText = valueText(*Replacement);
      std::string QueryHash = hashText(OldText + "\n!=\n" + NewText);
      if (!hasSamePoisonSupport(BO, Replacement)) {
        ++M.PoisonSupportRejects;
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
        continue;
      }
      SimplifyQuery SQ(F.getParent()->getDataLayout());
      bool LLVMProvedIdentity = simplifyInstruction(BO, SQ) == Replacement;
      if (!LLVMProvedIdentity && !proveEquivalentSMT(BO, Replacement)) {
        // Address reconstruction deliberately introduces integer affine
        // expressions feeding GEP/native pointer-selection cones.  Z3's BV
        // translator cannot model LLVM pointer constants in those candidates,
        // so an unknown query is not evidence of residual OLLVM MBA.
        if (feedsSyntheticNativePointerSelect(BO)) {
          if (auto *RI = dyn_cast<Instruction>(Replacement);
              RI->getParent() && RI->use_empty())
            RecursivelyDeleteTriviallyDeadInstructions(RI);
          continue;
        }
        ProofRecord Record{F.getName().str(), "rewrite_candidate", Origin,
                           "z3_bv_equivalence", "unresolved",
                           "equivalence_query_not_unsat"};
        Record.OldHash = hashText(OldText);
        Record.NewHash = hashText(NewText);
        Record.ProofQueryHash = QueryHash;
        Record.Dependencies.push_back("llvm_poison_flags_absent");
        Proofs.push_back(std::move(Record));
        if (auto *RI = dyn_cast<Instruction>(Replacement);
            RI->getParent() && RI->use_empty())
          RecursivelyDeleteTriviallyDeadInstructions(RI);
        continue;
      }
      BO->replaceAllUsesWith(Replacement);
      if (BO->use_empty()) BO->eraseFromParent();
      ++M.BVRewrites;
      if (InstSub) ++M.InstSubRewrites;
      ProofRecord Record{F.getName().str(),
                         InstSub ? "instsub_rewrite" : "bv_canonicalize",
                         Origin,
                         LLVMProvedIdentity ? "llvm_instruction_simplify"
                                            : "z3_bv_equivalence_unsat",
                         "proved"};
      Record.OldHash = hashText(OldText);
      Record.NewHash = hashText(NewText);
      Record.ProofQueryHash = QueryHash;
      Record.Dependencies.push_back("llvm_poison_flags_absent");
      Proofs.push_back(std::move(Record));
      Changed = RoundChanged = true;
    }
    if (!RoundChanged) break;
  }

  Changed |= rewriteX86FlagCones(F, M, Proofs);
  Changed |= rewriteDeMorganCastRegions(F, M, Proofs);
  Changed |= rewriteRotateRegions(F, M, Proofs);

  SmallVector<BranchInst *, 16> Branches;
  for (BasicBlock &BB : F)
    if (auto *BI = dyn_cast<BranchInst>(BB.getTerminator());
        BI && BI->isConditional())
      Branches.push_back(BI);
  DominatorTree DT(F);
  DenseMap<const LoadInst *, Value *> ReachingLoadValues =
      buildMemorySSAReachingValues(F, MSSA, M);
  struct ProvenStateLoad {
    WeakTrackingVH Handle;
    bool HasLiveIn = false;
  };
  SmallVector<ProvenStateLoad, 8> ProvenStateLoads;
  SmallVector<WeakTrackingVH, 8> PredecessorJoinStateLoads;
  SmallPtrSet<LoadInst *, 8> SeenStateLoads;
  DenseMap<PHINode *, unsigned> LargeSwitchesPerState;
  SmallPtrSet<PHINode *, 8> SelfLoopDispatchStates;
  for (BasicBlock &BB : F) {
    auto *Switch = dyn_cast<SwitchInst>(BB.getTerminator());
    if (!Switch || Switch->getNumCases() < 4) continue;
    // Before generic O3/mem2reg, lifted CFF commonly dispatches directly on
    // one frame-cell load.  Normalize that exact memory recurrence here,
    // while the original loop has not yet been peeled or duplicated.  The
    // proof requires every reaching definition to be an exact same-cell store
    // and rejects live-on-entry or unknown clobbers.
    if (auto *Load = dyn_cast<LoadInst>(Switch->getCondition());
        Load && SeenStateLoads.insert(Load).second) {
      bool HasLiveIn = false;
      if (proveExactStateCellDefinitions(*Load, MSSA, &HasLiveIn))
        ProvenStateLoads.push_back({WeakTrackingVH(Load), HasLiveIn});
      if (Switch->getDefaultDest() == Switch->getParent())
        PredecessorJoinStateLoads.push_back(WeakTrackingVH(Load));
    }
    PHINode *State = findStateRoot(Switch->getCondition());
    if (State) {
      ++LargeSwitchesPerState[State];
      if (Switch->getDefaultDest() == Switch->getParent())
        SelfLoopDispatchStates.insert(State);
    }
  }
  for (const auto &[State, Count] : LargeSwitchesPerState) {
    if (Count < 2 && !SelfLoopDispatchStates.contains(State)) continue;
    for (Value *Incoming : State->incoming_values()) {
      auto *Load = dyn_cast<LoadInst>(Incoming);
      if (!Load || !SeenStateLoads.insert(Load).second) continue;
      bool HasLiveIn = false;
      if (proveExactStateCellDefinitions(*Load, MSSA, &HasLiveIn))
        ProvenStateLoads.push_back({WeakTrackingVH(Load), HasLiveIn});
      if (SelfLoopDispatchStates.contains(State))
        PredecessorJoinStateLoads.push_back(WeakTrackingVH(Load));
    }
  }
  struct ProvenBranch {
    BranchInst *BI = nullptr;
    bool TakenTrue = false;
    std::string Engine;
    std::string ConstraintCertificate;
    unsigned ConstraintCount = 0;
    unsigned MemoryLoadsResolved = 0;
    unsigned PathStateITEsResolved = 0;
    unsigned SwitchPathStateITEsResolved = 0;
    unsigned InductivePhisResolved = 0;
    bool CyclicPredicateInduction = false;
  };
  SmallVector<ProvenBranch, 16> ProvenBranches;
  for (BranchInst *BI : Branches) {
    std::optional<bool> Proof = proveBoolean(BI->getCondition());
    std::string ProofEngine = "adjacent_product_parity";
    std::string ConstraintCertificate;
    unsigned ConstraintCount = 0;
    unsigned MemoryLoadsResolved = 0;
    unsigned PathStateITEsResolved = 0;
    unsigned SwitchPathStateITEsResolved = 0;
    unsigned InductivePhisResolved = 0;
    bool CyclicPredicateInduction = false;
    if (!Proof) {
      SmallVector<PathConstraint, 16> Constraints =
          collectDominatingConstraints(*BI, DT);
      auto SMTProof = proveBooleanSMT(BI->getCondition(), Constraints,
                                      &ReachingLoadValues);
      if (SMTProof) {
        Proof = SMTProof->Value;
        ConstraintCount = SMTProof->ConstraintCount;
        ConstraintCertificate = std::move(SMTProof->ConstraintCertificate);
        MemoryLoadsResolved = SMTProof->MemoryLoadsResolved;
        SwitchPathStateITEsResolved =
            SMTProof->SwitchPathStateITEsResolved;
        InductivePhisResolved = SMTProof->InductivePhisResolved;
        PathStateITEsResolved = SMTProof->PathStateITEsResolved +
                                SwitchPathStateITEsResolved;
        if (InductivePhisResolved && MemoryLoadsResolved && ConstraintCount)
          ProofEngine =
              "z3_memoryssa_inductive_constant_phi_with_dominating_constraints_unsat";
        else if (InductivePhisResolved && MemoryLoadsResolved)
          ProofEngine = "z3_memoryssa_inductive_constant_phi_unsat";
        else if (InductivePhisResolved && ConstraintCount)
          ProofEngine =
              "z3_inductive_constant_phi_with_dominating_constraints_unsat";
        else if (InductivePhisResolved)
          ProofEngine = "z3_inductive_constant_phi_unsat";
        else if (MemoryLoadsResolved && PathStateITEsResolved && ConstraintCount)
          ProofEngine =
              "z3_memoryssa_path_state_ite_with_dominating_constraints_unsat";
        else if (MemoryLoadsResolved && PathStateITEsResolved)
          ProofEngine = "z3_memoryssa_path_state_ite_unsat";
        else if (PathStateITEsResolved && ConstraintCount)
          ProofEngine =
              "z3_path_state_ite_with_dominating_constraints_unsat";
        else if (PathStateITEsResolved)
          ProofEngine = "z3_path_state_ite_unsat";
        else if (MemoryLoadsResolved && ConstraintCount)
          ProofEngine =
              "z3_memoryssa_with_dominating_constraints_unsat";
        else if (MemoryLoadsResolved)
          ProofEngine = "z3_memoryssa_bitvector_unsat";
        else if (ConstraintCount)
          ProofEngine = "z3_bitvector_with_dominating_constraints_unsat";
        else
          ProofEngine = "z3_bitvector_unsat";
      }
    }
    if (!Proof) {
      auto CyclicProof = proveBooleanCyclicInduction(BI->getCondition());
      if (CyclicProof) {
        Proof = CyclicProof->Value;
        ProofEngine = "z3_cyclic_predicate_induction_unsat";
        ConstraintCertificate = std::move(CyclicProof->Certificate);
        InductivePhisResolved = 1;
        CyclicPredicateInduction = true;
      }
    }
    if (!Proof) continue;
    ProvenBranches.push_back({BI, *Proof, std::move(ProofEngine),
                              std::move(ConstraintCertificate),
                              ConstraintCount, MemoryLoadsResolved,
                              PathStateITEsResolved,
                              SwitchPathStateITEsResolved,
                              InductivePhisResolved,
                              CyclicPredicateInduction});
  }
  for (const ProvenBranch &Proven : ProvenBranches) {
    BranchInst *BI = Proven.BI;
    bool Proof = Proven.TakenTrue;
    BasicBlock *Taken = BI->getSuccessor(Proof ? 0 : 1);
    BasicBlock *Dead = BI->getSuccessor(Proof ? 1 : 0);
    if (Dead != Taken)
      Dead->removePredecessor(BI->getParent());
    std::string Origin = BI->getParent()->getName().str();
    std::string ConditionText = valueText(*BI->getCondition());
    std::string TargetText = ("branch:" + Taken->getName()).str();
    BranchInst::Create(Taken, BI->getIterator());
    BI->eraseFromParent();
    ++M.OpaqueEdgesPruned;
    if (Proven.ConstraintCount) ++M.PathConstrainedOpaqueEdges;
    ProofRecord Record{F.getName().str(), "opaque_edge", Origin,
                       Proven.Engine, "proved"};
    Record.OldHash = hashText(ConditionText);
    Record.NewHash = hashText(TargetText);
    Record.ProofQueryHash =
        hashText(ConditionText + (Proof ? "\nprove:true\n" : "\nprove:false\n") +
                 Proven.ConstraintCertificate);
    Record.Dependencies.push_back("fixed_width_bitvector_semantics");
    if (Proven.ConstraintCount) {
      Record.Dependencies.push_back("dominating_path_constraints_sat");
      Record.Dependencies.push_back(
          "path_constraint_count=" + std::to_string(Proven.ConstraintCount));
    }
    if (Proven.MemoryLoadsResolved) {
      ++M.MemorySSAConstrainedOpaqueEdges;
      Record.Dependencies.push_back("memoryssa_exact_reaching_store");
      Record.Dependencies.push_back(
          "memoryssa_load_count=" +
          std::to_string(Proven.MemoryLoadsResolved));
    }
    if (Proven.PathStateITEsResolved) {
      ++M.PathStateITEOpaqueEdges;
      if (Proven.PathStateITEsResolved >
          Proven.SwitchPathStateITEsResolved)
        Record.Dependencies.push_back("exact_two_arm_diamond_phi_ite");
      if (Proven.SwitchPathStateITEsResolved)
        Record.Dependencies.push_back("exact_multi_arm_switch_funnel_phi_ite");
      Record.Dependencies.push_back(
          "path_state_ite_count=" +
          std::to_string(Proven.PathStateITEsResolved));
    }
    if (Proven.InductivePhisResolved) {
      ++M.InductivePhiOpaqueEdges;
      if (Proven.CyclicPredicateInduction) {
        Record.Dependencies.push_back(
            "all_external_seeds_establish_predicate");
        Record.Dependencies.push_back(
            "all_backedge_recurrences_preserve_predicate_by_z3_induction");
      } else {
        Record.Dependencies.push_back(
            "inductive_seed_from_non_backedge_constant");
        Record.Dependencies.push_back(
            "all_backedge_recurrences_preserve_seed");
      }
      Record.Dependencies.push_back(
          "inductive_phi_count=" +
          std::to_string(Proven.InductivePhisResolved));
    }
    Proofs.push_back(std::move(Record));
    Changed = true;
  }
  bool PromotedStateCell = false;
  for (ProvenStateLoad &Candidate : ProvenStateLoads)
    if (auto *Load = dyn_cast_or_null<LoadInst>(Candidate.Handle))
      PromotedStateCell |= promoteExactStateCellLoad(
          *Load, Candidate.HasLiveIn, M, Proofs);
  for (WeakTrackingVH &Candidate : PredecessorJoinStateLoads)
    if (auto *Load = dyn_cast_or_null<LoadInst>(Candidate))
      PromotedStateCell |=
          promoteExactPredecessorJoinStateLoad(*Load, M, Proofs);
  if (PromotedStateCell)
    for (BasicBlock &BB : F)
      EliminateDuplicatePHINodes(&BB);
  Changed |= eliminatePredecessorEquivalentPHIs(F);
  Changed |= PromotedStateCell;
  return Changed;
}

PreservedAnalyses OLLVMDeobfPass::run(Module &M,
                                      ModuleAnalysisManager &MAM) {
  Metrics Stats;
  LiftProfile Inventory = inventoryModule(M);
  importExistingInventory(M, Inventory);
  SmallVector<ProofRecord, 64> Proofs;
  importExistingProofs(M, Stats, Proofs);
  bool Changed = false;
  FunctionAnalysisManager &FAM =
      MAM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    ++Stats.Functions;
    for (BasicBlock &BB : F)
      if (auto *SI = dyn_cast<SwitchInst>(BB.getTerminator())) {
        ++Stats.Switches;
        if (SI->getNumCases() >= 4) ++Stats.LargeSwitches;
    }
    MemorySSA &MSSA = FAM.getResult<MemorySSAAnalysis>(F).getMSSA();
    Changed |= sanitizeLiftedFunction(F, Stats, Proofs);
    Changed |= rewriteFunction(F, MSSA, Stats, Proofs);
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootGeneralBVRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootAffineBVRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    Changed |= rewriteAffineBVRegions(F, Stats, Proofs);
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootAffineBVRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootACBitVectorRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    Changed |= rewriteACBitVectorRegions(F, Stats, Proofs);
    for (unsigned Transaction = 0; Transaction != 32; ++Transaction) {
      bool Local = rewriteMultiRootACBitVectorRegions(F, Stats, Proofs);
      Changed |= Local;
      if (!Local) break;
    }
    Changed |= recoverCompareLadders(F, Stats, Proofs);
    Changed |= recoverDispatchers(F, Stats, Proofs);
  }
  reconcileDispatcherProofs(M, Stats, Proofs);
  addModuleMetadata(M, Stats, Inventory, Proofs);
  Changed = true; // inventory and proof metadata are intentionally emitted.
  if (verifyModule(M, &errs())) {
    ++Stats.VerifierFailures;
    report_fatal_error("OLLVM deobfuscation produced invalid IR");
  }
  writeReport(M, Stats, Inventory, Proofs);
  errs() << "ollvm-deobf: functions=" << Stats.Functions
         << " switches=" << Stats.Switches
         << " bv_rewrites=" << Stats.BVRewrites
         << " instsub_rewrites=" << Stats.InstSubRewrites
         << " egraph_rewrites=" << Stats.EGraphRewrites
         << " opaque_edges_pruned=" << Stats.OpaqueEdgesPruned << '\n';
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_ollvm_deobf
