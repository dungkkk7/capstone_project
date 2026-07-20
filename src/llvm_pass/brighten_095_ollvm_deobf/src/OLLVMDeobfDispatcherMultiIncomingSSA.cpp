#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

// Recover a dispatcher whose state is already one PHI input per returning
// case.  A self-looping default is removable only by an exhaustive induction:
// at least one non-header seed reaches a returning source, every non-default
// incoming state resolves to a real case, and the default has no predecessor
// other than the dispatcher.  Thus the default is unreachable at the base and
// remains unreachable after every proved transition.
bool tryRecoverMultiIncomingSSADispatcher(
    SwitchInst &SI, Metrics &M, SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  Function *F = Header->getParent();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() != Header ||
      State->getNumIncomingValues() < 3)
    return false;

  BasicBlock *Default = SI.getDefaultDest();
  auto *DefaultBr = dyn_cast<BranchInst>(Default->getTerminator());
  if (!Default->hasNPredecessors(1) ||
      *pred_begin(Default) != Header || !DefaultBr ||
      !DefaultBr->isUnconditional() || DefaultBr->getSuccessor(0) != Header ||
      State->getBasicBlockIndex(Default) < 0)
    return false;

  DenseMap<APInt, BasicBlock *> CaseMap;
  for (auto Case : SI.cases()) {
    BasicBlock *Target = Case.getCaseSuccessor();
    if (Target == Default || Target == Header || !Target->phis().empty())
      return false;
    CaseMap[Case.getCaseValue()->getValue()] = Target;
  }
  if (CaseMap.size() < 4) return false;

  for (PHINode &PN : Header->phis())
    for (User *U : PN.users()) {
      auto *UI = dyn_cast<Instruction>(U);
      if (!UI || UI->getParent() != Header) return false;
    }
  SmallVector<Instruction *, 16> HeaderBody;
  for (Instruction &I : *Header)
    if (!isa<PHINode>(I) && !I.isTerminator() && !isa<DbgInfoIntrinsic>(I)) {
      for (User *U : I.users()) {
        auto *UI = dyn_cast<Instruction>(U);
        if (!UI || UI->getParent() != Header) return false;
      }
      HeaderBody.push_back(&I);
    }

  auto Resolve = [&](ConstantInt *Raw) -> BasicBlock * {
    auto Encoded = evalStateExpr(SI.getCondition(), State, Raw->getValue());
    if (!Encoded) return nullptr;
    auto It = CaseMap.find(*Encoded);
    return It == CaseMap.end() ? nullptr : It->second;
  };

  SmallVector<ProvenTransition, 32> Transitions;
  bool HasExternalSeed = false;
  DominatorTree DispatcherDT(*F);
  for (unsigned I = 0; I != State->getNumIncomingValues(); ++I) {
    BasicBlock *Pred = State->getIncomingBlock(I);
    if (Pred == Default) continue;
    auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Header)
      return false;
    for (BasicBlock *PredPred : predecessors(Pred))
      // Whole-function reachability is too broad for nested dispatchers: a
      // later outer-loop invocation can make Header reach the entry seed.
      // Dominance captures the local dispatcher region instead.  A genuine
      // case path is dominated by Header; an alternate seed edge is not.
      if (PredPred != Header && !DispatcherDT.dominates(Header, PredPred))
        HasExternalSeed = true;

    Value *Raw = State->getIncomingValue(I);
    ProvenTransition T;
    T.Source = Pred;
    if (auto *C = asTransitionConstant(Raw, Pred)) {
      T.TrueTarget = Resolve(C);
    } else if (auto *Sel = dyn_cast<SelectInst>(Raw)) {
      auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
      if (!TC || !FC) return false;
      T.Condition = Sel->getCondition();
      T.TrueTarget = Resolve(TC);
      T.FalseTarget = Resolve(FC);
    } else {
      return false;
    }
    if (!T.TrueTarget || (T.Condition && !T.FalseTarget))
      return false;
    Transitions.push_back(T);
  }
  if (!HasExternalSeed || Transitions.empty()) return false;
  for (const ProvenTransition &T : Transitions)
    for (PHINode &PN : Header->phis())
      if (PN.getBasicBlockIndex(T.Source) < 0) return false;

  std::string OldFunctionText = valueText(*F);
  std::string HeaderName = Header->getName().str();
  std::string Certificate;
  raw_string_ostream CertificateOS(Certificate);
  CertificateOS << "default:" << valueName(*Default)
                << ":header-only-self-loop\n";
  for (const ProvenTransition &T : Transitions) {
    CertificateOS << valueName(*T.Source) << "->"
                  << valueName(*T.TrueTarget);
    if (T.FalseTarget) CertificateOS << ',' << valueName(*T.FalseTarget);
    if (T.FiniteState) {
      CertificateOS << ";finite{";
      for (unsigned I = 0; I != T.FiniteRawValues.size(); ++I) {
        if (I) CertificateOS << ',';
        CertificateOS << T.FiniteRawValues[I] << "->"
                      << valueName(*T.FiniteTargets[I]);
      }
      CertificateOS << '}';
    }
    CertificateOS << '\n';
  }
  CertificateOS.flush();

  std::string FunctionName = F->getName().str();
  for (const ProvenTransition &T : Transitions) {
    Instruction *Old = T.Source->getTerminator();
    std::string OldText = valueText(*Old);
    DenseMap<const Value *, Value *> Map;
    for (PHINode &PN : Header->phis()) {
      int Index = PN.getBasicBlockIndex(T.Source);
      assert(Index >= 0 && "preflighted header PHI input disappeared");
      Map[&PN] = PN.getIncomingValue(Index);
    }
    cloneBlockPlumbing(HeaderBody, Old, Map);
    if (T.Condition)
      BranchInst::Create(T.TrueTarget, T.FalseTarget, T.Condition,
                         Old->getIterator());
    else
      BranchInst::Create(T.TrueTarget, Old->getIterator());
    Old->eraseFromParent();
    ProofRecord Edge{FunctionName, "cff_transition", valueName(*T.Source),
                     "multi_incoming_ssa_default_induction", "proved"};
    Edge.OldHash = hashText(OldText);
    Edge.NewHash = hashText(valueText(*T.Source->getTerminator()));
    Edge.ProofQueryHash = hashText(Certificate);
    Edge.Dependencies.push_back("exhaustive_known_state_induction");
    Edge.Dependencies.push_back("exact_header_plumbing_clone");
    Proofs.push_back(std::move(Edge));
  }
  removeUnreachableBlocks(*F);
  ++M.DispatchersRecovered;
  ProofRecord Record{FunctionName, "cff_dispatcher", HeaderName,
                     "multi_incoming_ssa_default_induction", "proved"};
  Record.OldHash = hashText(OldFunctionText);
  Record.NewHash = hashText(valueText(*F));
  Record.ProofQueryHash = hashText(Certificate);
  Record.Dependencies.push_back("external_seed_exists");
  Record.Dependencies.push_back("exhaustive_known_state_induction");
  Record.Dependencies.push_back("default_only_header_predecessor");
  Record.Dependencies.push_back("exact_header_plumbing_clone");
  Proofs.push_back(std::move(Record));
  return true;
}

} // namespace brighten_ollvm_deobf
