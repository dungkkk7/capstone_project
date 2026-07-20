#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

// Recover a dispatcher as one cyclic lookup region rather than assigning an
// entry/latch role to each switch independently.  Native cleanup is free to
// split one flattened lookup table into several default-linked switches and
// to insert forwarding PHIs between them.  In that form there is no single
// canonical "header": external seeds may enter any shard and all case tails
// may return through a many-way PHI funnel into another shard.
//
// This engine proves the following transaction before changing the CFG:
//   * default edges form a closed ring of switch shards, or a single lookup
//     terminates unknown states in an exact non-returning self-loop;
//   * every shard state is the exact forwarded state of the previous shard;
//   * every external state input is either an entry edge or an exact PHI
//     funnel; transitions have a finite proved state set, while a genuinely
//     acyclic external entry may retain its exact dynamic discriminator;
//   * lookup is resolved in ring order (so duplicate keys are not guessed);
//   * every skipped PHI and instruction has an exact value on the cloned path.
//
// The commit clones the complete funnel/shard plumbing into private edge
// blocks and translates target PHIs from the original switch owner.  Thus no
// state store, semantic PHI, or side effect is silently discarded.
bool tryRecoverCyclicStateFamilyDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs,
    std::string *Rejection) {
  struct Diagnostic {
    std::string *Output = nullptr;
    std::string Stage = "initialization";
    bool Success = false;
    ~Diagnostic() {
      if (!Success && Output && Output->empty()) *Output = Stage;
    }
  } Diag{Rejection};
  Function *F = SI.getFunction();
  if (!F) return false;

  struct Shard {
    BasicBlock *Block = nullptr;
    SwitchInst *Lookup = nullptr;
    Value *Expression = nullptr;
    PHINode *State = nullptr;
    BasicBlock *Default = nullptr;
    bool Transparent = false;
    DenseMap<APInt, BasicBlock *> Cases;
  };
  SmallVector<Shard, 8> Shards;
  SmallPtrSet<BasicBlock *, 16> ShardBlocks;
  Diag.Stage = "lookup-region-discovery";
  BasicBlock *Current = SI.getParent();
  unsigned SwitchCount = 0;
  BasicBlock *TerminalUnknownSink = nullptr;
  for (unsigned Depth = 0; Depth != 32; ++Depth) {
    BasicBlock *BB = Current;
    if (!ShardBlocks.insert(BB).second) return false;
    Shards.emplace_back();
    Shard &S = Shards.back();
    S.Block = BB;
    if (auto *Lookup = dyn_cast<SwitchInst>(BB->getTerminator())) {
      ++SwitchCount;
      S.Lookup = Lookup;
      S.Expression = Lookup->getCondition();
      S.Default = Lookup->getDefaultDest();
    } else if (auto *Br = dyn_cast<BranchInst>(BB->getTerminator());
               Br && Br->isUnconditional()) {
      // Optimizers place PHI-only preheaders/backedges between lookup shards.
      // Their exact state carrier is recovered from the successor PHI after
      // the complete ring has been collected.
      S.Transparent = true;
      S.Default = Br->getSuccessor(0);
    } else {
      auto *GuardBr = dyn_cast<BranchInst>(BB->getTerminator());
      auto *Cmp = GuardBr && GuardBr->isConditional()
                      ? dyn_cast<ICmpInst>(GuardBr->getCondition())
                      : nullptr;
      if (!Cmp || !Cmp->isEquality()) return false;
      ConstantInt *Key = dyn_cast<ConstantInt>(Cmp->getOperand(1));
      S.Expression = Cmp->getOperand(0);
      if (!Key) {
        Key = dyn_cast<ConstantInt>(Cmp->getOperand(0));
        S.Expression = Cmp->getOperand(1);
      }
      if (!Key) return false;
      S.State = findStateRoot(S.Expression);
      if (!S.State) return false;
      auto Raw = decodeStateExpr(S.Expression, S.State, Key->getValue());
      if (!Raw) return false;
      unsigned Match = Cmp->getPredicate() == ICmpInst::ICMP_EQ ? 0 : 1;
      S.Cases[*Raw] = GuardBr->getSuccessor(Match);
      S.Default = GuardBr->getSuccessor(1 - Match);
    }
    if (!S.Transparent) {
      if (!S.State) S.State = findStateRoot(S.Expression);
      if (!S.State || !S.State->getType()->isIntegerTy()) return false;
    }
    if (S.Default == SI.getParent()) break;
    if (Shards.size() == 1) {
      auto *TerminalBr = dyn_cast<BranchInst>(S.Default->getTerminator());
      if (TerminalBr && TerminalBr->isUnconditional() &&
          TerminalBr->getSuccessor(0) == S.Default) {
        TerminalUnknownSink = S.Default;
        break;
      }
    }
    Current = S.Default;
  }
  if (SwitchCount == 0 ||
      (Shards.back().Default != SI.getParent() && !TerminalUnknownSink))
    return false;

  // Resolve transparent nodes backwards.  The next shard's state PHI names
  // the exact value carried by the transparent predecessor, which must itself
  // be an integer PHI defined in that predecessor.  This is structural SSA
  // identity, not a block-name or state-number heuristic.
  Diag.Stage = "transparent-state-carrier-resolution";
  for (unsigned Pass = 0; Pass != Shards.size(); ++Pass) {
    bool Progress = false;
    for (unsigned I = 0; I != Shards.size(); ++I) {
      Shard &S = Shards[I];
      if (!S.Transparent || S.State) continue;
      Shard &To = Shards[(I + 1) % Shards.size()];
      if (!To.State || To.State->getParent() != To.Block) continue;
      int Incoming = To.State->getBasicBlockIndex(S.Block);
      if (Incoming < 0) return false;
      auto *Carrier = dyn_cast<PHINode>(To.State->getIncomingValue(Incoming));
      if (!Carrier || Carrier->getParent() != S.Block ||
          !Carrier->getType()->isIntegerTy())
        return false;
      S.State = Carrier;
      S.Expression = Carrier;
      Progress = true;
    }
    if (!Progress) break;
  }
  for (const Shard &S : Shards)
    if (!S.State) return false;

  Diag.Stage = "state-family-forwarding-proof";
  // The state reaching the next shard must be exactly the previous raw state.
  // The lookup expression itself may be affine/encoded and is decoded below.
  for (unsigned I = 0; I != Shards.size(); ++I) {
    Shard &From = Shards[I];
    Shard &To = Shards[(I + 1) % Shards.size()];
    if (To.State == From.State) {
      // Sharing one SSA state across consecutive lookup shards is valid while
      // the definition dominates both shards.  On the wrap edge into the
      // state PHI's own block, however, the PHI may receive a different
      // loop-carried transition value.  Treating that edge as transparent
      // would recover only the entry and strand the real recurrence.
      if (To.State->getParent() == To.Block) {
        int Incoming = To.State->getBasicBlockIndex(From.Block);
        if (Incoming < 0 ||
            To.State->getIncomingValue(Incoming) != From.State)
          return false;
      }
      continue;
    }
    if (To.State->getParent() != To.Block) return false;
    int Incoming = To.State->getBasicBlockIndex(From.Block);
    if (Incoming < 0 ||
        To.State->getIncomingValue(Incoming) != From.State)
      return false;
  }

  Diag.Stage = "ordered-case-table-decoding";
  for (Shard &S : Shards) {
    if (!S.Lookup) continue;
    for (auto Case : S.Lookup->cases()) {
      auto Raw = decodeStateExpr(S.Expression, S.State,
                                 Case.getCaseValue()->getValue());
      if (!Raw || Raw->getBitWidth() !=
                      S.State->getType()->getIntegerBitWidth())
        return false;
      auto It = S.Cases.find(*Raw);
      if (It != S.Cases.end() && It->second != Case.getCaseSuccessor())
        return false;
      S.Cases[*Raw] = Case.getCaseSuccessor();
    }
  }

  struct Funnel {
    BasicBlock *Block = nullptr;
    PHINode *State = nullptr;
    unsigned StartShard = 0;
  };
  SmallVector<Funnel, 4> Funnels;
  DenseMap<BasicBlock *, unsigned> FunnelByBlock;
  struct Origin {
    BasicBlock *Source = nullptr;
    BasicBlock *OldSuccessor = nullptr;
    Value *RawState = nullptr;
    unsigned StartShard = 0;
    BasicBlock *FunnelBlock = nullptr;
    bool IsEntry = false;
    unsigned SuccessorIndex = 0;
  };
  SmallVector<Origin, 64> Origins;

  auto AddOrigin = [&](BasicBlock *Source, BasicBlock *OldSuccessor,
                       Value *RawState, unsigned StartShard,
                       BasicBlock *FunnelBlock, bool IsEntry) {
    if (!Source || !OldSuccessor || !RawState) return false;
    Instruction *Terminator = Source->getTerminator();
    unsigned SuccessorIndex = Terminator->getNumSuccessors();
    unsigned MatchingEdges = 0;
    for (unsigned I = 0; I != Terminator->getNumSuccessors(); ++I)
      if (Terminator->getSuccessor(I) == OldSuccessor) {
        SuccessorIndex = I;
        ++MatchingEdges;
      }
    if (MatchingEdges != 1) return false;
    if (llvm::any_of(Origins, [&](const Origin &Existing) {
          return Existing.Source == Source &&
                 Existing.SuccessorIndex == SuccessorIndex;
        }))
      return false;
    Origins.push_back({Source, OldSuccessor, RawState, StartShard,
                       FunnelBlock, IsEntry, SuccessorIndex});
    return true;
  };

  Diag.Stage = "external-state-frontier-discovery";
  // Find all inputs not belonging to the lookup ring.  A PHI defined in its
  // predecessor is an explicit return funnel; every other value is an entry
  // seed.  Shared state PHIs are inspected only at their defining shard.
  DominatorTree FrontierDT(*F);
  LoopInfo FrontierLoops(FrontierDT);
  SmallPtrSet<PHINode *, 8> SeenStates;
  for (unsigned I = 0; I != Shards.size(); ++I) {
    PHINode *State = Shards[I].State;
    if (!SeenStates.insert(State).second) continue;

    // SROA/loop canonicalization may place the state PHI in a dedicated
    // pre-dispatch block instead of the switch block itself.  That block is
    // the funnel: its PHI enumerates the exact entry and backedge states, and
    // its sole edge enters this lookup shard.  Treating its predecessors as
    // direct shard predecessors loses the intervening CFG edge and rejects a
    // valid memory-to-SSA recurrence.
    if (State->getParent() != Shards[I].Block) {
      BasicBlock *FunnelBlock = State->getParent();
      auto *Br = dyn_cast<BranchInst>(FunnelBlock->getTerminator());
      if (ShardBlocks.contains(FunnelBlock) || !Br ||
          !Br->isUnconditional() ||
          Br->getSuccessor(0) != Shards[I].Block)
        return false;
      unsigned FunnelIndex = Funnels.size();
      if (auto Existing = FunnelByBlock.find(FunnelBlock);
          Existing != FunnelByBlock.end()) {
        FunnelIndex = Existing->second;
        if (Funnels[FunnelIndex].State != State ||
            Funnels[FunnelIndex].StartShard != I)
          return false;
      } else {
        FunnelByBlock[FunnelBlock] = FunnelIndex;
        Funnels.push_back({FunnelBlock, State, I});
      }
      continue;
    }
    for (unsigned J = 0; J != State->getNumIncomingValues(); ++J) {
      BasicBlock *Pred = State->getIncomingBlock(J);
      if (ShardBlocks.contains(Pred)) continue;
      Value *Incoming = State->getIncomingValue(J);
      auto *FunnelState = dyn_cast<PHINode>(Incoming);
      if (FunnelState && FunnelState->getParent() == Pred) {
        auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
        if (!Br || !Br->isUnconditional() ||
            Br->getSuccessor(0) != Shards[I].Block)
          return false;
        unsigned FunnelIndex = Funnels.size();
        if (auto Existing = FunnelByBlock.find(Pred);
            Existing != FunnelByBlock.end()) {
          FunnelIndex = Existing->second;
          if (Funnels[FunnelIndex].State != FunnelState ||
              Funnels[FunnelIndex].StartShard != I)
            return false;
        } else {
          FunnelByBlock[Pred] = FunnelIndex;
          Funnels.push_back({Pred, FunnelState, I});
        }
        continue;
      }
      bool IsEntry = !FrontierDT.dominates(Shards[I].Block, Pred);
      if (!AddOrigin(Pred, Shards[I].Block, Incoming, I,
                     nullptr, IsEntry))
        return false;
    }
  }
  Diag.Stage = "funnel-predecessor-expansion";
  for (unsigned FunnelCursor = 0; FunnelCursor != Funnels.size();
       ++FunnelCursor) {
    Funnel CurrentFunnel = Funnels[FunnelCursor];
    for (BasicBlock *Pred : predecessors(CurrentFunnel.Block)) {
      if (ShardBlocks.contains(Pred)) continue;
      Diag.Stage = (Twine("funnel-predecessor-expansion:block=") +
                    CurrentFunnel.Block->getName() + ";pred=" + Pred->getName())
                       .str();
      int Index = CurrentFunnel.State->getBasicBlockIndex(Pred);
      if (Index < 0) return false;
      Value *Incoming = CurrentFunnel.State->getIncomingValue(Index);
      if (auto *NestedState = dyn_cast<PHINode>(Incoming);
          NestedState && NestedState->getParent() == Pred) {
        auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
        if (!Br || !Br->isUnconditional() ||
            Br->getSuccessor(0) != CurrentFunnel.Block)
          return false;
        if (auto Existing = FunnelByBlock.find(Pred);
            Existing != FunnelByBlock.end()) {
          const Funnel &Known = Funnels[Existing->second];
          if (Known.State != NestedState ||
              Known.StartShard != CurrentFunnel.StartShard)
            return false;
        } else {
          FunnelByBlock[Pred] = Funnels.size();
          Funnels.push_back({Pred, NestedState, CurrentFunnel.StartShard});
        }
        continue;
      }
      bool IsEntry =
          !FrontierDT.dominates(Shards[CurrentFunnel.StartShard].Block, Pred);
      if (!AddOrigin(Pred, CurrentFunnel.Block, Incoming,
                     CurrentFunnel.StartShard, CurrentFunnel.Block, IsEntry))
        return false;
    }
  }
  if (Origins.empty()) return false;

  struct PathStep {
    BasicBlock *Block = nullptr;
    BasicBlock *IncomingBlock = nullptr;
  };
  struct ResolvedPath {
    SmallVector<PathStep, 24> Steps;
    BasicBlock *Target = nullptr;
    BasicBlock *Owner = nullptr;
  };
  auto FindFunnel = [&](BasicBlock *BB) -> const Funnel * {
    auto It = FunnelByBlock.find(BB);
    return It == FunnelByBlock.end() ? nullptr : &Funnels[It->second];
  };

  std::function<std::optional<ResolvedPath>(const APInt &, unsigned,
                                             BasicBlock *, BasicBlock *,
                                             unsigned)> Resolve;
  Resolve = [&](const APInt &Raw, unsigned StartShard,
                BasicBlock *PrefixBlock, BasicBlock *PrefixIncoming,
                unsigned Depth) -> std::optional<ResolvedPath> {
    if (Depth > 12) return std::nullopt;
    ResolvedPath Result;
    unsigned Index = StartShard;
    BasicBlock *Incoming = PrefixIncoming;
    BasicBlock *Prefix = PrefixBlock;
    SmallPtrSet<BasicBlock *, 8> SeenPrefix;
    while (Prefix) {
      if (!SeenPrefix.insert(Prefix).second) return std::nullopt;
      Result.Steps.push_back({Prefix, Incoming});
      auto *Br = dyn_cast<BranchInst>(Prefix->getTerminator());
      if (!Br || !Br->isUnconditional()) return std::nullopt;
      BasicBlock *Next = Br->getSuccessor(0);
      Incoming = Prefix;
      if (Next == Shards[StartShard].Block) break;
      if (!FunnelByBlock.count(Next)) return std::nullopt;
      Prefix = Next;
    }
    for (unsigned Visited = 0; Visited != Shards.size(); ++Visited) {
      Shard &S = Shards[Index];
      Result.Steps.push_back({S.Block, Incoming});
      auto It = S.Cases.find(Raw);
      if (It != S.Cases.end()) {
        BasicBlock *Target = It->second;
        if (const Funnel *NextFunnel = FindFunnel(Target)) {
          int PhiIndex = NextFunnel->State->getBasicBlockIndex(
              S.Block);
          if (PhiIndex < 0) return std::nullopt;
          ConstantInt *Next = asTransitionConstant(
              NextFunnel->State->getIncomingValue(PhiIndex),
              S.Block);
          if (!Next) return std::nullopt;
          auto Tail = Resolve(Next->getValue(), NextFunnel->StartShard,
                              NextFunnel->Block, S.Block,
                              Depth + 1);
          if (!Tail) return std::nullopt;
          Result.Steps.append(Tail->Steps.begin(), Tail->Steps.end());
          Result.Target = Tail->Target;
          Result.Owner = Tail->Owner;
          return Result;
        }
        if (ShardBlocks.contains(Target)) return std::nullopt;
        Result.Target = Target;
        Result.Owner = S.Block;
        return Result;
      }
      Incoming = S.Block;
      Index = (Index + 1) % Shards.size();
    }
    return std::nullopt;
  };

  struct Variant {
    APInt Raw;
    ResolvedPath Path;
  };
  struct OriginPlan {
    Origin *Input = nullptr;
    Value *Condition = nullptr;
    Value *FiniteState = nullptr;
    bool DynamicEntry = false;
    SmallVector<Variant, 2> Variants;
  };
  Diag.Stage = "finite-transition-preflight";
  SmallVector<OriginPlan, 64> Plans;
  for (Origin &O : Origins) {
    OriginPlan Plan;
    Plan.Input = &O;
    SmallVector<APInt, 2> RawValues;
    if (auto *C = asTransitionConstant(O.RawState, O.Source)) {
      RawValues.push_back(C->getValue());
    } else if (auto *Select = dyn_cast<SelectInst>(O.RawState)) {
      auto *True = asTransitionConstant(Select->getTrueValue(), O.Source);
      auto *False = asTransitionConstant(Select->getFalseValue(), O.Source);
      if (!True || !False) {
        Diag.Stage = (Twine("finite-select-nonconstant:source=") +
                      O.Source->getName())
                         .str();
        return false;
      }
      Plan.Condition = Select->getCondition();
      RawValues.push_back(True->getValue());
      RawValues.push_back(False->getValue());
    } else {
      if (!O.RawState->getType()->isIntegerTy()) return false;
      Plan.FiniteState = O.RawState;
      DenseMap<const Value *, APInt> Bindings;
      unsigned Budget = 512;
      APInt Dummy(O.RawState->getType()->getIntegerBitWidth(), 0);
      if (!enumerateTransitionValues(O.RawState, nullptr, Dummy, Bindings,
                                     RawValues, Budget) ||
          RawValues.empty()) {
        // An unconstrained entry state is still recoverable exactly.  Every
        // state named by the lookup ring is routed directly to its resolved
        // case, while every other value retains the original infinite lookup
        // cycle.  Dynamic transition states are not accepted here: only an
        // external entry can use this exact-switch fallback.  In particular,
        // never retain a value defined by the lookup/funnel region itself:
        // deleting that region can remove its dominance over the rewritten
        // entry even when the old incoming edge was valid SSA.
        auto *StateDef = dyn_cast<Instruction>(O.RawState);
        if (!O.IsEntry || FrontierLoops.getLoopFor(O.Source)) {
          Diag.Stage = (Twine("finite-transition-unbounded:source=") +
                        O.Source->getName())
                           .str();
          return false;
        }
        if (StateDef &&
            (ShardBlocks.contains(StateDef->getParent()) ||
             FunnelByBlock.count(StateDef->getParent()))) {
          Diag.Stage =
              (Twine("dynamic-entry-region-defined:source=") +
               O.Source->getName() + ";def=" + StateDef->getName())
                  .str();
          return false;
        }
        Plan.DynamicEntry = true;
        RawValues.clear();
        for (const Shard &S : Shards)
          for (const auto &[Raw, Target] : S.Cases)
            if (!llvm::is_contained(RawValues, Raw)) RawValues.push_back(Raw);
        if (RawValues.empty()) return false;
      }
    }
    // A retained finite-state discriminator must survive removal of the
    // lookup region.  A region-local PHI can dominate the old incoming edge
    // yet stop dominating the source after direct case edges are installed.
    // Reject that shape transactionally; a specialized complete-transition
    // engine may still recover it without retaining the obsolete SSA value.
    if (Plan.FiniteState)
      if (auto *StateDef = dyn_cast<Instruction>(Plan.FiniteState);
          StateDef &&
          (ShardBlocks.contains(StateDef->getParent()) ||
           FunnelByBlock.count(StateDef->getParent()))) {
        Diag.Stage =
            (Twine("finite-state-region-defined:source=") +
             O.Source->getName() + ";def=" + StateDef->getName())
                .str();
        return false;
      }
    for (const APInt &Raw : RawValues) {
      auto Path = Resolve(Raw, O.StartShard, O.FunnelBlock, O.Source, 0);
      if (!Path || !Path->Target || !Path->Owner) {
        Diag.Stage = (Twine("finite-transition-unresolved:source=") +
                      O.Source->getName() + ";state=" +
                      Twine(Raw.getLimitedValue()))
                         .str();
        return false;
      }
      // Preflight exact PHI translation for every skipped block and target.
      for (const PathStep &Step : Path->Steps)
        for (PHINode &Phi : Step.Block->phis())
          if (Phi.getBasicBlockIndex(Step.IncomingBlock) < 0) {
            Diag.Stage = (Twine("finite-step-phi-uncovered:block=") +
                          Step.Block->getName() + ";incoming=" +
                          Step.IncomingBlock->getName())
                             .str();
            return false;
          }
      for (PHINode &Phi : Path->Target->phis())
        if (Phi.getBasicBlockIndex(Path->Owner) < 0) {
          Diag.Stage = (Twine("finite-target-phi-uncovered:target=") +
                        Path->Target->getName() + ";owner=" +
                        Path->Owner->getName())
                           .str();
          return false;
        }
      Plan.Variants.push_back({Raw, std::move(*Path)});
    }
    if (Plan.Variants.empty()) return false;
    Plans.push_back(std::move(Plan));
  }

  SmallPtrSet<BasicBlock *, 32> FinalTargets;
  for (const OriginPlan &Plan : Plans)
    for (const Variant &V : Plan.Variants) FinalTargets.insert(V.Path.Target);
  SmallPtrSet<BasicBlock *, 16> RegionBlocks(ShardBlocks.begin(),
                                             ShardBlocks.end());
  for (const Funnel &Funnel : Funnels) RegionBlocks.insert(Funnel.Block);
  SmallPtrSet<BasicBlock *, 32> PotentialCaseTargets(FinalTargets.begin(),
                                                      FinalTargets.end());
  for (const Shard &S : Shards)
    for (const auto &[Raw, Target] : S.Cases)
      if (!RegionBlocks.contains(Target)) PotentialCaseTargets.insert(Target);
  DenseMap<BasicBlock *, SmallVector<Instruction *, 4>>
      RequiredSourceLiveIns;
  DenseMap<BasicBlock *, DenseMap<Instruction *, BasicBlock *>>
      SourceCarrierOwners;
  auto ReachesWithoutRegion = [&](BasicBlock *Start,
                                  BasicBlock *Goal) -> bool {
    SmallVector<BasicBlock *, 32> Work{Start};
    SmallPtrSet<BasicBlock *, 32> Seen;
    while (!Work.empty() && Seen.size() <= 512) {
      BasicBlock *BB = Work.pop_back_val();
      if (!Seen.insert(BB).second) continue;
      if (BB == Goal) return true;
      for (BasicBlock *Succ : successors(BB))
        if (!RegionBlocks.contains(Succ)) Work.push_back(Succ);
    }
    return false;
  };

  // Cloning a path is only exact when every region-local operand has already
  // been produced by an earlier cloned step.  When the value reaches a case
  // source through the old dispatcher, record it as an explicit source
  // live-in; a case-entry bridge is built below and seeds the cloned path.
  // Merely retaining the old definition is unsound because removing the
  // dispatcher can remove its dominance and turn it into poison.
  Diag.Stage = "path-ssa-closure-preflight";
  DominatorTree RegionDT(*F);
  for (const OriginPlan &Plan : Plans) {
    Instruction *SourceTerminator = Plan.Input->Source->getTerminator();
    for (const Variant &V : Plan.Variants) {
      SmallPtrSet<const Value *, 32> Available;
      if (auto It = SourceCarrierOwners.find(Plan.Input->Source);
          It != SourceCarrierOwners.end())
        for (auto &[Def, Owner] : It->second) Available.insert(Def);
      auto RequireAvailable = [&](Value *Operand,
                                  const Twine &Context) -> bool {
        auto *Def = dyn_cast<Instruction>(Operand);
        if (!Def || !ShardBlocks.contains(Def->getParent()) &&
                        !FunnelByBlock.count(Def->getParent()))
          return true;
        if (Available.contains(Def)) return true;
        BasicBlock *OwnerTarget = nullptr;
        for (BasicBlock *Target : PotentialCaseTargets) {
          if (!ReachesWithoutRegion(Target, Plan.Input->Source)) continue;
          if (!OwnerTarget || RegionDT.dominates(OwnerTarget, Target)) {
            OwnerTarget = Target;
          } else if (!RegionDT.dominates(Target, OwnerTarget)) {
            OwnerTarget = nullptr;
            break;
          }
        }
        if (OwnerTarget && RegionDT.dominates(Def, SourceTerminator)) {
          auto &LiveIns = RequiredSourceLiveIns[OwnerTarget];
          if (!llvm::is_contained(LiveIns, Def)) LiveIns.push_back(Def);
          SourceCarrierOwners[Plan.Input->Source][Def] = OwnerTarget;
          Available.insert(Def);
          return true;
        }
        Diag.Stage = (Twine("path-ssa-unavailable:") + Context +
                      ";def=" + Def->getName() +
                      ";source=" + Plan.Input->Source->getName())
                         .str();
        return false;
      };
      for (const PathStep &Step : V.Path.Steps) {
        for (PHINode &Phi : Step.Block->phis()) {
          Value *Incoming =
              Phi.getIncomingValueForBlock(Step.IncomingBlock);
          if (!RequireAvailable(Incoming,
                                Twine("phi=") + Phi.getName()))
            return false;
          Available.insert(&Phi);
        }
        for (Instruction &I : *Step.Block) {
          if (isa<PHINode>(I) || I.isTerminator() ||
              isa<DbgInfoIntrinsic>(I))
            continue;
          for (Value *Operand : I.operands())
            if (!RequireAvailable(Operand,
                                  Twine("instruction=") + I.getName()))
              return false;
          Available.insert(&I);
        }
      }
      for (PHINode &Phi : V.Path.Target->phis()) {
        Value *Incoming = Phi.getIncomingValueForBlock(V.Path.Owner);
        if (!RequireAvailable(Incoming,
                              Twine("target-phi=") + Phi.getName()))
          return false;
      }
    }
  }

  // A switch-owned SSA value can be used directly in a case body because the
  // original lookup owner dominates that body.  Direct edges remove that
  // dominance.  Materialize an explicit case-entry PHI for every such live-in
  // and prove its value on all old and new incoming paths.  Uses beyond the
  // immediate case entry are rejected here rather than repaired by guessing.
  Diag.Stage = "case-livein-preflight";
  DenseMap<BasicBlock *, SmallVector<Instruction *, 4>> TargetLiveIns;
  for (auto &[Target, LiveIns] : RequiredSourceLiveIns)
    TargetLiveIns[Target].append(LiveIns.begin(), LiveIns.end());
  DenseMap<Instruction *, SmallVector<Use *, 8>> ExternalUses;
  auto FedOnlyByRegion = [&](BasicBlock *Start) {
    SmallVector<BasicBlock *, 16> Work{Start};
    SmallPtrSet<BasicBlock *, 16> Seen;
    while (!Work.empty() && Seen.size() <= 128) {
      BasicBlock *BB = Work.pop_back_val();
      if (!Seen.insert(BB).second) continue;
      if (RegionBlocks.contains(BB)) continue;
      if (FinalTargets.contains(BB) || pred_empty(BB)) return false;
      for (BasicBlock *Pred : predecessors(BB)) Work.push_back(Pred);
    }
    return Work.empty();
  };
  for (BasicBlock *RegionBlock : RegionBlocks) {
    for (Instruction &Def : *RegionBlock) {
      if (Def.getType()->isVoidTy()) continue;
      for (Use &OperandUse : Def.uses()) {
        auto *UseI = dyn_cast<Instruction>(OperandUse.getUser());
        if (!UseI || RegionBlocks.contains(UseI->getParent())) continue;
        BasicBlock *UseBlock = UseI->getParent();
        // An incoming owned by a region predecessor disappears together with
        // that predecessor.  It is not live on any newly constructed edge and
        // must not be mistaken for an uncovered downstream live-in.
        if (auto *UsePhi = dyn_cast<PHINode>(UseI)) {
          unsigned IncomingIndex = OperandUse.getOperandNo();
          if (IncomingIndex < UsePhi->getNumIncomingValues() &&
              FedOnlyByRegion(UsePhi->getIncomingBlock(IncomingIndex)))
            continue;
        }
        if (!isa<PHINode>(UseI) && FedOnlyByRegion(UseBlock)) continue;
        // A PHI in the immediate target is already translated from its exact
        // original lookup owner for every new edge.
        if (isa<PHINode>(UseI) && FinalTargets.contains(UseBlock)) continue;
        SmallVector<BasicBlock *, 8> ReachingTargets;
        for (BasicBlock *Target : FinalTargets) {
          bool ReachesUse = false;
          if (auto *UsePhi = dyn_cast<PHINode>(UseI)) {
            for (unsigned I = 0; I != UsePhi->getNumIncomingValues(); ++I)
              if (&UsePhi->getOperandUse(I) == &OperandUse &&
                  ReachesWithoutRegion(Target,
                                       UsePhi->getIncomingBlock(I)))
                ReachesUse = true;
          } else {
            ReachesUse = ReachesWithoutRegion(Target, UseBlock);
          }
          if (ReachesUse) ReachingTargets.push_back(Target);
        }
        if (ReachingTargets.empty()) {
          Diag.Stage = (Twine("case-livein-unproved-owner:def=") +
                        Def.getName() + ";use=" + UseBlock->getName())
                           .str();
          return false;
        }
        for (BasicBlock *Target : ReachingTargets)
          if (!llvm::is_contained(TargetLiveIns[Target], &Def))
            TargetLiveIns[Target].push_back(&Def);
        ExternalUses[&Def].push_back(&OperandUse);
      }
    }
  }

  // A centralized dispatcher PHI is a carrier network: a value needed by a
  // downstream case must be present at every predecessor case that can take a
  // newly constructed edge into it.  Propagate those requirements backwards
  // to a fixed point over the exact transition plans.  Each propagated value
  // becomes a case-entry bridge below, so loop-carried semantic state remains
  // in SSA after the dispatcher ceases to dominate the case bodies.
  //
  // This is deliberately structural.  We only propagate a value that the old
  // dispatcher definition proves to dominate the source terminator, and only
  // through a source that is itself an exact case entry.  Entry paths without
  // such a proof remain rejected rather than receiving poison/undef.
  Diag.Stage = "case-livein-carrier-fixed-point";
  bool CarrierChanged = true;
  unsigned CarrierRounds = 0;
  while (CarrierChanged) {
    if (++CarrierRounds > 1024) {
      Diag.Stage = "case-livein-carrier-fixed-point-budget";
      return false;
    }
    CarrierChanged = false;
    for (const OriginPlan &Plan : Plans) {
      Instruction *SourceTerminator = Plan.Input->Source->getTerminator();
      for (const Variant &V : Plan.Variants) {
        auto TargetIt = TargetLiveIns.find(V.Path.Target);
        if (TargetIt == TargetLiveIns.end()) continue;
        SmallVector<Instruction *, 8> Needed(TargetIt->second.begin(),
                                              TargetIt->second.end());
        SmallPtrSet<const Value *, 32> Available;
        if (auto It = SourceCarrierOwners.find(Plan.Input->Source);
            It != SourceCarrierOwners.end())
          for (auto &[Def, Owner] : It->second) Available.insert(Def);
        for (const PathStep &Step : V.Path.Steps) {
          for (PHINode &Phi : Step.Block->phis())
            Available.insert(&Phi);
          for (Instruction &I : *Step.Block)
            if (!isa<PHINode>(I) && !I.isTerminator() &&
                !isa<DbgInfoIntrinsic>(I))
              Available.insert(&I);
        }
        for (Instruction *Def : Needed) {
          if (Available.contains(Def) ||
              !RegionBlocks.contains(Def->getParent()))
            continue;
          BasicBlock *Source = Plan.Input->Source;
          BasicBlock *OwnerTarget = nullptr;
          for (BasicBlock *Candidate : PotentialCaseTargets) {
            if (!ReachesWithoutRegion(Candidate, Source)) continue;
            if (!OwnerTarget || RegionDT.dominates(OwnerTarget, Candidate)) {
              OwnerTarget = Candidate;
            } else if (!RegionDT.dominates(Candidate, OwnerTarget)) {
              OwnerTarget = nullptr;
              break;
            }
          }
          if (!OwnerTarget || RegionBlocks.contains(OwnerTarget) ||
              !RegionDT.dominates(Def, SourceTerminator)) {
            Diag.Stage = (Twine("case-livein-untranslated:def=") +
                          Def->getName() + ";target=" +
                          V.Path.Target->getName() + ";source=" +
                          Source->getName())
                             .str();
            return false;
          }
          auto &SourceLiveIns = TargetLiveIns[OwnerTarget];
          if (!llvm::is_contained(SourceLiveIns, Def)) {
            SourceLiveIns.push_back(Def);
            CarrierChanged = true;
          }
          SourceCarrierOwners[Source][Def] = OwnerTarget;
        }
      }
    }
  }

  for (auto &[Target, LiveIns] : TargetLiveIns) {
    for (BasicBlock *Pred : predecessors(Target)) {
      if (!ShardBlocks.contains(Pred)) {
        Diag.Stage = (Twine("case-livein-external-predecessor:target=") +
                      Target->getName() + ";pred=" + Pred->getName())
                         .str();
        return false;
      }
      for (Instruction *Def : LiveIns)
        if (!RegionDT.dominates(Def, Pred->getTerminator())) {
          Diag.Stage = (Twine("case-livein-nondominating:def=") +
                        Def->getName() + ";target=" + Target->getName() +
                        ";pred=" + Pred->getName())
                           .str();
          return false;
        }
    }
  }

  // Every bridge must have an exact translated value on every new incoming
  // edge.  Re-simulate all paths with their source bridges in scope so the
  // commit phase never falls back to an obsolete region-local definition.
  Diag.Stage = "case-livein-path-coverage";
  for (const OriginPlan &Plan : Plans) {
    for (const Variant &V : Plan.Variants) {
      SmallPtrSet<const Value *, 32> Available;
      if (auto It = SourceCarrierOwners.find(Plan.Input->Source);
          It != SourceCarrierOwners.end())
        for (auto &[Def, Owner] : It->second) Available.insert(Def);
      auto IsAvailable = [&](Value *Input) {
        auto *Def = dyn_cast<Instruction>(Input);
        return !Def || !RegionBlocks.contains(Def->getParent()) ||
               Available.contains(Def);
      };
      for (const PathStep &Step : V.Path.Steps) {
        for (PHINode &Phi : Step.Block->phis()) {
          if (!IsAvailable(
                  Phi.getIncomingValueForBlock(Step.IncomingBlock))) {
            Diag.Stage = (Twine("case-livein-path-phi:def=") +
                          Phi.getName() + ";source=" +
                          Plan.Input->Source->getName())
                             .str();
            return false;
          }
          Available.insert(&Phi);
        }
        for (Instruction &I : *Step.Block) {
          if (isa<PHINode>(I) || I.isTerminator() ||
              isa<DbgInfoIntrinsic>(I))
            continue;
          for (Value *Operand : I.operands())
            if (!IsAvailable(Operand)) {
              Diag.Stage = (Twine("case-livein-path-instruction:def=") +
                            I.getName() + ";source=" +
                            Plan.Input->Source->getName())
                               .str();
              return false;
            }
          Available.insert(&I);
        }
      }
      if (auto It = TargetLiveIns.find(V.Path.Target);
          It != TargetLiveIns.end())
        for (Instruction *Def : It->second)
          if (!IsAvailable(Def)) {
            Diag.Stage = (Twine("case-livein-untranslated:def=") +
                          Def->getName() + ";target=" +
                          V.Path.Target->getName() + ";source=" +
                          Plan.Input->Source->getName())
                             .str();
            return false;
          }
    }
  }

  auto Translate = [](Value *V, DenseMap<const Value *, Value *> &Map) {
    auto It = Map.find(V);
    return It == Map.end() ? V : It->second;
  };
  auto CloneStep = [&](const PathStep &Step, Instruction *Before,
                       DenseMap<const Value *, Value *> &Map) {
    for (PHINode &Phi : Step.Block->phis())
      Map[&Phi] = Translate(
          Phi.getIncomingValueForBlock(Step.IncomingBlock), Map);
    for (Instruction &I : *Step.Block) {
      if (isa<PHINode>(I) || I.isTerminator() || isa<DbgInfoIntrinsic>(I))
        continue;
      Instruction *Clone = I.clone();
      for (unsigned Op = 0; Op != Clone->getNumOperands(); ++Op)
        Clone->setOperand(Op, Translate(Clone->getOperand(Op), Map));
      if (!Clone->getType()->isVoidTy())
        Clone->setName(I.getName() + ".deobf.region");
      Clone->insertBefore(Before->getIterator());
      Map[&I] = Clone;
    }
  };

  DenseMap<BasicBlock *, DenseMap<const Value *, PHINode *>> LiveInPhis;
  for (auto &[Target, LiveIns] : TargetLiveIns) {
    for (Instruction *Def : LiveIns) {
      PHINode *Bridge = PHINode::Create(
          Def->getType(), pred_size(Target) + 4,
          Def->getName() + ".deobf.region.livein", Target->begin());
      SmallVector<BasicBlock *, 4> OldPreds(predecessors(Target));
      for (BasicBlock *Pred : OldPreds) Bridge->addIncoming(Def, Pred);
      LiveInPhis[Target][Def] = Bridge;
    }
  }

  Diag.Stage = "transaction-commit";
  unsigned Serial = 0;
  for (OriginPlan &Plan : Plans) {
    Origin &O = *Plan.Input;
    SmallVector<BasicBlock *, 2> Targets;
    for (Variant &V : Plan.Variants) {
      BasicBlock *Edge = BasicBlock::Create(
          F->getContext(), "deobf.region.edge." + Twine(Serial++), F,
          V.Path.Target);
      BranchInst *EdgeBranch = BranchInst::Create(V.Path.Target, Edge);
      DenseMap<const Value *, Value *> Map;
      if (auto It = SourceCarrierOwners.find(O.Source);
          It != SourceCarrierOwners.end())
        for (auto &[Def, Owner] : It->second) {
          auto OwnerIt = LiveInPhis.find(Owner);
          if (OwnerIt == LiveInPhis.end() || !OwnerIt->second.count(Def))
            report_fatal_error("missing cyclic region source carrier");
          Map[Def] = OwnerIt->second.lookup(Def);
        }
      for (const PathStep &Step : V.Path.Steps)
        CloneStep(Step, EdgeBranch, Map);
      for (PHINode &Phi : V.Path.Target->phis()) {
        if (Phi.getName().contains(".deobf.region.livein")) continue;
        Value *Incoming = Phi.getIncomingValueForBlock(V.Path.Owner);
        Value *Translated = Translate(Incoming, Map);
        if (Translated->getType() != Phi.getType())
          report_fatal_error("cyclic region target PHI translation type mismatch");
        Phi.addIncoming(Translated, Edge);
      }
      if (auto It = LiveInPhis.find(V.Path.Target); It != LiveInPhis.end())
        for (auto &[Def, Bridge] : It->second) {
          Value *Translated = Translate(const_cast<Value *>(Def), Map);
          if (Translated->getType() != Bridge->getType())
            report_fatal_error(
                "cyclic region live-in translation type mismatch");
          Bridge->addIncoming(Translated, Edge);
        }
      Targets.push_back(Edge);
    }
    Instruction *Old = O.Source->getTerminator();
    Instruction *Replace = Old;
    bool WholeTerminator = Old->getNumSuccessors() == 1;
    if (!WholeTerminator) {
      BasicBlock *Dispatch = BasicBlock::Create(
          F->getContext(), "deobf.region.dispatch." + Twine(Serial++), F,
          Targets.front());
      Replace = BranchInst::Create(Targets.front(), Dispatch);
      Old->setSuccessor(O.SuccessorIndex, Dispatch);
      // Keep one-input PHIs alive until every planned edge has been committed;
      // later plans still reference their exact incoming values.
      O.OldSuccessor->removePredecessor(O.Source, true);
    } else {
      O.OldSuccessor->removePredecessor(O.Source, true);
    }
    if (Plan.DynamicEntry) {
      BasicBlock *UnknownStateLoop = BasicBlock::Create(
          F->getContext(), "deobf.region.dynamic.unknown." + Twine(Serial++),
          F, Targets.front());
      BranchInst::Create(UnknownStateLoop, UnknownStateLoop);
      auto *DynamicSwitch = SwitchInst::Create(
          Plan.FiniteState, UnknownStateLoop, Targets.size(),
          Replace->getIterator());
      for (unsigned I = 0; I != Targets.size(); ++I)
        DynamicSwitch->addCase(
            ConstantInt::get(Plan.FiniteState->getContext(),
                             Plan.Variants[I].Raw),
            Targets[I]);
    } else if (Plan.FiniteState) {
      auto *FiniteSwitch = SwitchInst::Create(
          Plan.FiniteState, Targets.front(), Targets.size() - 1,
          Replace->getIterator());
      for (unsigned I = 1; I != Targets.size(); ++I)
        FiniteSwitch->addCase(
            ConstantInt::get(Plan.FiniteState->getContext(),
                             Plan.Variants[I].Raw),
            Targets[I]);
    } else if (Plan.Condition)
      BranchInst::Create(Targets[0], Targets[1], Plan.Condition,
                         Replace->getIterator());
    else
      BranchInst::Create(Targets[0], Replace->getIterator());
    Replace->eraseFromParent();
    Proofs.push_back({F->getName().str(), "cff_transition",
                      O.Source->getName().str(),
                      O.IsEntry ? "cyclic_state_family_entry"
                                : "cyclic_state_family_transition",
                      "proved"});
  }

  // Case bodies may reconverge after entering through several dispatcher
  // targets.  Rebuild the value at those joins from all exact case-entry
  // bridges instead of selecting one arbitrary dominating target.
  for (auto &[Def, Uses] : ExternalUses) {
    SmallVector<PHINode *, 8> InsertedPhis;
    SSAUpdater Updater(&InsertedPhis);
    std::string SSAName =
        (Twine(Def->getName()) + ".deobf.region.ssa").str();
    Updater.Initialize(Def->getType(), SSAName);
    if (Def->getParent()) Updater.AddAvailableValue(Def->getParent(), Def);
    for (auto &[Target, Values] : LiveInPhis)
      if (PHINode *Bridge = Values.lookup(Def))
        Updater.AddAvailableValue(Target, Bridge);
    for (Use *OperandUse : Uses) {
      if (!OperandUse || OperandUse->get() != Def) continue;
      auto *UseI = dyn_cast<Instruction>(OperandUse->getUser());
      if (!UseI || RegionBlocks.contains(UseI->getParent())) continue;
      Updater.RewriteUseAfterInsertions(*OperandUse);
    }
    for (PHINode *Phi : InsertedPhis)
      for (Value *Incoming : Phi->incoming_values())
        if (isa<PoisonValue>(Incoming))
          report_fatal_error(
              "cyclic region SSAUpdater produced an uncovered path");
  }

  std::string Origin = SI.getParent()->getName().str();
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  ProofRecord Record{F->getName().str(), "cff_dispatcher", Origin,
                     "complete_cyclic_state_family_region", "proved"};
  Record.Dependencies.push_back(
      TerminalUnknownSink ? "exact_terminal_unknown_state_sink"
                          : "closed_default_linked_lookup_ring");
  Record.Dependencies.push_back("exact_forwarded_state_family");
  Record.Dependencies.push_back("ordered_lookup_resolution");
  Record.Dependencies.push_back("complete_external_edge_coverage");
  Record.Dependencies.push_back("exact_phi_and_plumbing_translation");
  Record.Dependencies.push_back("multi_entry_case_join_ssa_reconstruction");
  if (llvm::any_of(Plans,
                   [](const OriginPlan &Plan) { return Plan.DynamicEntry; }))
    Record.Dependencies.push_back("dynamic_entry_exact_switch_retained");
  Proofs.push_back(std::move(Record));
  Diag.Success = true;
  return true;
}

} // namespace brighten_ollvm_deobf
