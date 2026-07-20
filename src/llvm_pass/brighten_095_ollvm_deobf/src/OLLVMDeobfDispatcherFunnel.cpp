#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

bool tryRecoverFunnelDispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() == Header ||
      !SI.getDefaultDest()->hasNPredecessors(2))
    return false;
  // The default must be the header's self-loop, not a semantic default path.
  if (SI.getDefaultDest() != Header) return false;
  BasicBlock *Outer = State->getParent();
  auto *OuterBr = dyn_cast<BranchInst>(Outer->getTerminator());
  if (!OuterBr || !OuterBr->isUnconditional() ||
      OuterBr->getSuccessor(0) != Header)
    return false;

  DenseMap<APInt, BasicBlock *> CaseMap;
  for (auto Case : SI.cases()) {
    BasicBlock *Target = Case.getCaseSuccessor();
    CaseMap[Case.getCaseValue()->getValue()] = Target;
  }
  if (CaseMap.size() < 4) return false;

  SmallVector<FunnelEdge, 16> Edges;
  for (unsigned I = 0; I != State->getNumIncomingValues(); ++I) {
    Value *Incoming = State->getIncomingValue(I);
    BasicBlock *Pred = State->getIncomingBlock(I);
    if (auto *SinkPhi = dyn_cast<PHINode>(Incoming)) {
      BasicBlock *Sink = SinkPhi->getParent();
      auto *SinkBr = dyn_cast<BranchInst>(Sink->getTerminator());
      if (SinkBr && SinkBr->isUnconditional() &&
          SinkBr->getSuccessor(0) == Outer) {
        for (unsigned J = 0; J != SinkPhi->getNumIncomingValues(); ++J) {
          BasicBlock *Source = SinkPhi->getIncomingBlock(J);
          if (Source == Header) continue; // handled as a case-table chain below
          auto *Br = dyn_cast<BranchInst>(Source->getTerminator());
          if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Sink)
            return false;
          FunnelEdge E;
          E.Source = Source;
          E.RawState = SinkPhi->getIncomingValue(J);
          E.Stages.push_back({Sink, SinkPhi, E.RawState});
          E.Stages.push_back({Outer, State, E.RawState});
          Edges.push_back(std::move(E));
        }
        continue;
      }
    }
    auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Outer)
      return false;
    FunnelEdge E;
    E.Source = Pred;
    E.RawState = Incoming;
    E.Stages.push_back({Outer, State, Incoming});
    Edges.push_back(std::move(E));
  }
  if (Edges.empty()) return false;

  auto ResolveConstant = [&](ConstantInt *Raw, FunnelEdge &E) -> BasicBlock * {
    SmallPtrSet<BasicBlock *, 4> Seen;
    for (unsigned Depth = 0; Depth != 8; ++Depth) {
      auto Encoded = evalStateExpr(SI.getCondition(), State, Raw->getValue());
      if (!Encoded) return nullptr;
      auto It = CaseMap.find(*Encoded);
      if (It == CaseMap.end()) return nullptr;
      BasicBlock *Target = It->second;
      if (!Seen.insert(Target).second) return nullptr;
      // A case may deliberately route back through the state sink.  Resolve
      // its header-specific PHI input and preserve both state stores.
      PHINode *SinkPhi = nullptr;
      for (Instruction &I : *Target) {
        auto *PN = dyn_cast<PHINode>(&I);
        if (!PN) break;
        if (PN->getBasicBlockIndex(Header) >= 0) { SinkPhi = PN; break; }
      }
      auto *TargetBr = dyn_cast<BranchInst>(Target->getTerminator());
      if (!SinkPhi || !TargetBr || !TargetBr->isUnconditional() ||
          TargetBr->getSuccessor(0) != Outer) {
        if (Target->phis().begin() != Target->phis().end()) return nullptr;
        return Target;
      }
      auto *Next = dyn_cast<ConstantInt>(
          SinkPhi->getIncomingValueForBlock(Header));
      if (!Next) return nullptr;
      E.Stages.push_back({Target, SinkPhi, Next});
      E.Stages.push_back({Outer, State, Next});
      Raw = Next;
    }
    return nullptr;
  };

  for (FunnelEdge &E : Edges) {
    for (const PlumbingStage &Stage : E.Stages)
      if (!validatePlumbingStage(Stage)) return false;
    if (auto *Sel = dyn_cast<SelectInst>(E.RawState)) {
      auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
      if (!TC || !FC) return false;
      FunnelEdge TrueProbe = E, FalseProbe = E;
      E.TrueTarget = ResolveConstant(TC, TrueProbe);
      E.FalseTarget = ResolveConstant(FC, FalseProbe);
      // Branch-dependent extra state plumbing cannot be hoisted safely.
      if (TrueProbe.Stages.size() != E.Stages.size() ||
          FalseProbe.Stages.size() != E.Stages.size())
        return false;
      E.Condition = Sel->getCondition();
    } else {
      ConstantInt *C = asTransitionConstant(E.RawState, E.Source);
      if (!C) return false;
      E.TrueTarget = ResolveConstant(C, E);
    }
    if (!E.TrueTarget || (E.Condition && !E.FalseTarget)) return false;
    for (const PlumbingStage &Stage : E.Stages)
      if (!validatePlumbingStage(Stage)) return false;
  }

  std::string FunctionName = Header->getParent()->getName().str();
  std::string HeaderName = Header->getName().str();
  Function *F = Header->getParent();
  for (FunnelEdge &E : Edges) {
    Instruction *Old = E.Source->getTerminator();
    for (const PlumbingStage &Stage : E.Stages)
      clonePlumbingStage(Stage, Old);
    if (E.Condition)
      BranchInst::Create(E.TrueTarget, E.FalseTarget, E.Condition,
                         Old->getIterator());
    else
      BranchInst::Create(E.TrueTarget, Old->getIterator());
    Old->eraseFromParent();
    Proofs.push_back({FunctionName, "cff_transition",
                      E.Source->getName().str(), "funnel_transition_set",
                      "proved"});
  }
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  Proofs.push_back({FunctionName, "cff_dispatcher", HeaderName,
                    "complete_funnel_transition_set", "proved"});
  return true;
}

} // namespace brighten_ollvm_deobf
