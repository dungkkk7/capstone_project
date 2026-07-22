#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

Value *resolveMemorySSAValue(
    MemoryAccess *Access, LoadInst &LI, MemorySSA &MSSA,
    MemorySSAWalker &Walker, SmallPtrSetImpl<MemoryAccess *> &Seen,
    bool &UsedPhi, unsigned Depth) {
  if (!Access || Depth > 16 || !Seen.insert(Access).second ||
      MSSA.isLiveOnEntryDef(Access))
    return nullptr;
  if (auto *Def = dyn_cast<MemoryDef>(Access)) {
    auto *SI = dyn_cast_or_null<StoreInst>(Def->getMemoryInst());
    if (!SI || SI->isVolatile() || SI->isAtomic() ||
        !sameFrameAddress(SI->getPointerOperand(), LI.getPointerOperand()) ||
        SI->getValueOperand()->getType() != LI.getType())
      return nullptr;
    return SI->getValueOperand();
  }
  auto *Phi = dyn_cast<MemoryPhi>(Access);
  if (!Phi || Phi->getNumIncomingValues() == 0) return nullptr;
  UsedPhi = true;
  Value *Common = nullptr;
  MemoryLocation Location = MemoryLocation::get(&LI);
  for (Use &IncomingUse : Phi->incoming_values()) {
    auto *Incoming = cast<MemoryAccess>(IncomingUse.get());
    MemoryAccess *Clobber =
        Walker.getClobberingMemoryAccess(Incoming, Location);
    SmallPtrSet<MemoryAccess *, 16> ArmSeen;
    ArmSeen.insert(Seen.begin(), Seen.end());
    Value *Arm = resolveMemorySSAValue(Clobber, LI, MSSA, Walker, ArmSeen,
                                       UsedPhi, Depth + 1);
    if (!Arm) return nullptr;
    if (!Common) Common = Arm;
    else if (Common != Arm) {
      auto *LC = dyn_cast<Constant>(Common);
      auto *RC = dyn_cast<Constant>(Arm);
      if (!LC || !RC || LC != RC) return nullptr;
    }
  }
  return Common;
}

DenseMap<const LoadInst *, Value *>
buildMemorySSAReachingValues(Function &F, MemorySSA &MSSA, Metrics &M) {
  DenseMap<const LoadInst *, Value *> Reaching;
  MSSA.ensureOptimizedUses();
  MemorySSAWalker *Walker = MSSA.getWalker();
  for (Instruction &I : instructions(F)) {
    auto *LI = dyn_cast<LoadInst>(&I);
    if (!LI) continue;
    if (LI->isVolatile() || LI->isAtomic()) {
      ++M.MemorySSABarriers;
      continue;
    }
    MemoryAccess *Clobber = Walker->getClobberingMemoryAccess(LI);
    if (!Clobber || MSSA.isLiveOnEntryDef(Clobber)) continue;
    SmallPtrSet<MemoryAccess *, 16> Seen;
    bool UsedPhi = false;
    Value *ReachingValue = resolveMemorySSAValue(
        Clobber, *LI, MSSA, *Walker, Seen, UsedPhi);
    if (!ReachingValue) {
      ++M.MemorySSABarriers;
      continue;
    }
    Reaching.try_emplace(LI, ReachingValue);
    ++M.MemorySSAReachingLoads;
    if (UsedPhi) ++M.MemorySSAPhisResolved;
  }
  return Reaching;
}

// A flattened state cell is sometimes funneled through several switch shards
// before its sole loop load.  Requiring stores to be direct predecessors of
// that load makes promotion depend on the CFG layout.  Instead, use MemorySSA
// to prove that every clobber reaching the load is an exact, same-width store
// to the same frame cell.  MemoryPhi cycles are accepted only as graph edges;
// every concrete definition still has to pass the exact-store check.  A
// LiveOnEntry arm is accepted only when promotion can seed the shadow state
// on every external loop-entry edge before the first dispatcher iteration.
bool proveExactStateCellDefinitions(LoadInst &LI, MemorySSA &MSSA,
                                           bool *HasLiveIn,
                                           std::string *Rejection) {
  if (LI.isAtomic() || LI.isVolatile() ||
      !LI.getType()->isIntegerTy()) {
    if (Rejection) *Rejection = "non_plain_integer_load";
    return false;
  }
  MemorySSAWalker *Walker = MSSA.getWalker();
  MemoryAccess *Root = Walker->getClobberingMemoryAccess(&LI);
  MemoryLocation Location = MemoryLocation::get(&LI);
  SmallPtrSet<MemoryAccess *, 32> Seen;
  bool SawStore = false;
  bool SawLiveIn = false;
  std::function<bool(MemoryAccess *)> Visit = [&](MemoryAccess *Access) {
    if (!Access) {
      if (Rejection) *Rejection = "missing_memoryssa_access";
      return false;
    }
    if (MSSA.isLiveOnEntryDef(Access)) {
      SawLiveIn = true;
      return true;
    }
    if (!Seen.insert(Access).second) return true;
    if (Seen.size() > 2048) return false;
    if (auto *Def = dyn_cast<MemoryDef>(Access)) {
      auto *Store = dyn_cast_or_null<StoreInst>(Def->getMemoryInst());
      if (!Store || Store->isAtomic() || Store->isVolatile()) {
        if (Rejection) {
          if (!Store) *Rejection = "reaching_definition_is_not_store";
          else *Rejection = "atomic_or_volatile_reaching_store";
        }
        return false;
      }
      bool SameAddress = sameFrameAddress(Store->getPointerOperand(),
                                          LI.getPointerOperand());
      bool EntryEquivalent =
          !SameAddress && sameFrameAddressAlongUniquePath(
                              Store->getPointerOperand(),
                              LI.getPointerOperand(), Store->getParent(),
                              LI.getParent());
      if (!SameAddress && !EntryEquivalent) {
        if (!frameAccessesProvablyDisjoint(
                Store->getPointerOperand(), Store->getValueOperand()->getType(),
                LI.getPointerOperand(), LI.getType(),
                LI.getModule()->getDataLayout())) {
          if (Rejection)
            *Rejection = "reaching_store_address_mismatch:store=" +
                         valueName(*Store->getPointerOperand()) +
                         ";load=" + valueName(*LI.getPointerOperand());
          return false;
        }
        MemoryAccess *Prior = Walker->getClobberingMemoryAccess(
            Def->getDefiningAccess(), Location);
        return Visit(Prior);
      }
      if (Store->getValueOperand()->getType() != LI.getType()) {
        if (Rejection) *Rejection = "reaching_store_width_mismatch";
        return false;
      }
      SawStore = true;
      SawLiveIn |= EntryEquivalent;
      return true;
    }
    auto *Phi = dyn_cast<MemoryPhi>(Access);
    if (!Phi || Phi->getNumIncomingValues() == 0) {
      if (Rejection) *Rejection = "unsupported_memoryssa_node";
      return false;
    }
    for (Use &IncomingUse : Phi->incoming_values()) {
      auto *Incoming = cast<MemoryAccess>(IncomingUse.get());
      if (!Visit(Walker->getClobberingMemoryAccess(Incoming, Location)))
        return false;
    }
    return true;
  };
  bool Exact = Visit(Root) && SawStore;
  if (!Exact && Rejection && Rejection->empty())
    *Rejection = SawLiveIn ? "live_in_without_visible_exact_store"
                           : "no_exact_reaching_store";
  if (HasLiveIn) *HasLiveIn = Exact && SawLiveIn;
  return Exact;
}

// Clone only the pure address-expression cone needed to evaluate a dispatcher
// cell on an incoming edge.  Header PHIs are substituted with that edge's
// incoming values.  This provides the dynamic live-in seed without hoisting a
// potentially trapping load onto paths that never enter the dispatcher.
Value *materializeAddressOnEntryEdge(
    Value *V, BasicBlock *Header, BasicBlock *Pred, Instruction *Before,
    DominatorTree &DT, DenseMap<Value *, Value *> &Mapped,
    unsigned Depth) {
  if (!V || Depth > 32) return nullptr;
  auto It = Mapped.find(V);
  if (It != Mapped.end()) return It->second;
  if (isa<Constant>(V) || isa<Argument>(V)) return V;
  auto *I = dyn_cast<Instruction>(V);
  if (!I) return nullptr;
  if (I->getParent() != Header)
    return DT.dominates(I, Before) ? V : nullptr;
  if (auto *Phi = dyn_cast<PHINode>(I)) {
    int Index = Phi->getBasicBlockIndex(Pred);
    if (Index < 0) return nullptr;
    Value *Incoming = Phi->getIncomingValue(Index);
    Value *Result = materializeAddressOnEntryEdge(
        Incoming, Header, Pred, Before, DT, Mapped, Depth + 1);
    if (Result) Mapped[V] = Result;
    return Result;
  }
  if (I->isTerminator() || I->mayReadOrWriteMemory() || I->mayHaveSideEffects())
    return nullptr;
  Instruction *Copy = I->clone();
  for (unsigned O = 0; O != Copy->getNumOperands(); ++O) {
    Value *Operand = materializeAddressOnEntryEdge(
        Copy->getOperand(O), Header, Pred, Before, DT, Mapped, Depth + 1);
    if (!Operand) {
      Copy->deleteValue();
      return nullptr;
    }
    Copy->setOperand(O, Operand);
  }
  Copy->setName(I->getName() + ".deobf.entry");
  Copy->insertBefore(Before->getIterator());
  Mapped[V] = Copy;
  return Copy;
}

// Mirror exact stores into a private alloca and let LLVM's standard mem2reg
// construct the complete cyclic SSA recurrence.  Original frame stores stay
// in place, so this transformation changes only the proved dispatcher load
// and cannot hide memory from other consumers.
bool promoteExactStateCellLoad(
    LoadInst &LI, bool HasLiveIn, Metrics &M,
    SmallVectorImpl<ProofRecord> &Proofs) {
  Function &F = *LI.getFunction();
  SmallVector<StoreInst *, 256> Stores;
  for (Instruction &I : instructions(F)) {
    auto *Store = dyn_cast<StoreInst>(&I);
    if (!Store || Store->isAtomic() || Store->isVolatile() ||
        Store->getValueOperand()->getType() != LI.getType() ||
        (!sameFrameAddress(Store->getPointerOperand(),
                           LI.getPointerOperand()) &&
         !sameFrameAddressAlongUniquePath(
             Store->getPointerOperand(), LI.getPointerOperand(),
             Store->getParent(), LI.getParent())))
      continue;
    Stores.push_back(Store);
  }
  if (Stores.empty()) return false;

  DominatorTree DT(F);
  LoopInfo Loops(DT);
  Loop *DispatcherLoop = Loops.getLoopFor(LI.getParent());
  if (!DispatcherLoop)
    return false;

  SmallVector<BasicBlock *, 4> EntryPreds;
  if (DispatcherLoop->getHeader() == LI.getParent()) {
    for (BasicBlock *Pred : predecessors(LI.getParent()))
      if (!DispatcherLoop->contains(Pred)) {
        auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
        if (!Br || !Br->isUnconditional() ||
            Br->getSuccessor(0) != LI.getParent())
          return false;
        EntryPreds.push_back(Pred);
      }
    if (EntryPreds.empty() || (!HasLiveIn && EntryPreds.size() > 1))
      return false;
  } else {
    // Nested dispatcher shards commonly load the same state cell from an
    // interior block.  There is no single edge on which to materialize a
    // live-in seed, so only accept this layout when MemorySSA proved that
    // every reaching definition is an exact store (HasLiveIn == false).
    if (HasLiveIn)
      return false;
    if (!DispatcherLoop->contains(LI.getParent()))
      return false;
  }

  IRBuilder<> EntryBuilder(&*F.getEntryBlock().getFirstInsertionPt());
  AllocaInst *Shadow = EntryBuilder.CreateAlloca(
      LI.getType(), nullptr, "deobf.dispatch.state.cell");

  if (HasLiveIn) {
    for (BasicBlock *Pred : EntryPreds) {
      Instruction *Before = Pred->getTerminator();
      DenseMap<Value *, Value *> Mapped;
      Value *EntryPointer = materializeAddressOnEntryEdge(
          LI.getPointerOperand(), LI.getParent(), Pred, Before, DT, Mapped);
      if (!EntryPointer) {
        Shadow->eraseFromParent();
        for (auto &[Original, Clone] : Mapped)
          if (auto *CloneI = dyn_cast<Instruction>(Clone);
              CloneI && CloneI != Original && CloneI->use_empty())
            RecursivelyDeleteTriviallyDeadInstructions(CloneI);
        return false;
      }
      IRBuilder<> B(Before);
      LoadInst *Seed = B.CreateLoad(LI.getType(), EntryPointer,
                                    "deobf.dispatch.state.livein");
      Seed->setAlignment(LI.getAlign());
      B.CreateStore(Seed, Shadow);
    }
  }
  for (StoreInst *Store : Stores) {
    IRBuilder<> B(Store->getParent());
    B.SetInsertPoint(Store->getParent(), std::next(Store->getIterator()));
    B.CreateStore(Store->getValueOperand(), Shadow);
  }
  std::string Origin = valueName(LI);
  LI.setOperand(0, Shadow);
  DT.recalculate(F);
  SmallVector<AllocaInst *, 1> Allocas{Shadow};
  PromoteMemToReg(Allocas, DT);
  ++M.MemorySSAPhisResolved;
  ProofRecord Record{F.getName().str(), "cff_state_promotion", Origin,
                     "memoryssa_exact_cell_mem2reg", "proved"};
  Record.Dependencies.push_back("all_reaching_defs_exact_same_cell_stores");
  Record.Dependencies.push_back(HasLiveIn
                                    ? "dynamic_live_in_seeded_on_all_loop_entries"
                                    : "no_live_on_entry_or_unknown_clobber");
  Record.Dependencies.push_back("original_memory_stores_preserved");
  Proofs.push_back(std::move(Record));
  return true;
}

bool eliminatePredecessorEquivalentPHIs(Function &F) {
  bool Changed = false;
  for (BasicBlock &BB : F) {
    SmallVector<PHINode *, 16> Phis;
    for (PHINode &Phi : BB.phis()) Phis.push_back(&Phi);
    for (unsigned I = 0; I != Phis.size(); ++I) {
      PHINode *Representative = Phis[I];
      if (!Representative) continue;
      for (unsigned J = I + 1; J != Phis.size(); ++J) {
        PHINode *Candidate = Phis[J];
        if (!Candidate || Candidate->getType() != Representative->getType() ||
            Candidate->getNumIncomingValues() !=
                Representative->getNumIncomingValues())
          continue;
        bool Equal = true;
        for (unsigned K = 0; K != Representative->getNumIncomingValues(); ++K) {
          BasicBlock *Pred = Representative->getIncomingBlock(K);
          int CandidateIndex = Candidate->getBasicBlockIndex(Pred);
          if (CandidateIndex < 0 ||
              Candidate->getIncomingValue(CandidateIndex) !=
                  Representative->getIncomingValue(K)) {
            Equal = false;
            break;
          }
        }
        if (!Equal) continue;
        Candidate->replaceAllUsesWith(Representative);
        Candidate->eraseFromParent();
        Phis[J] = nullptr;
        Changed = true;
      }
    }
  }
  return Changed;
}

} // namespace brighten_ollvm_deobf
