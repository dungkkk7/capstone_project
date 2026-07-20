#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

// Conservative SSA-CFF recovery.  It commits only when the initial state and
// every case transition are constants (or a select of constants), all encoded
// targets exist in the case table, and case entries need no dispatcher PHIs.
bool tryRecoverSSADispatcher(SwitchInst &SI, Metrics &M,
                                    SmallVectorImpl<ProofRecord> &Proofs) {
  BasicBlock *Header = SI.getParent();
  Function *ParentFunction = Header->getParent();
  std::string FunctionName = ParentFunction->getName().str();
  std::string HeaderName = Header->getName().str();
  PHINode *State = findStateRoot(SI.getCondition());
  if (!State || State->getParent() != Header || State->getNumIncomingValues() != 2)
    return false;
  for (User *U : State->users()) {
    auto *UseI = dyn_cast<Instruction>(U);
    if (!UseI || UseI->getParent() != Header) return false;
  }

  PHINode *LatchState = nullptr;
  ConstantInt *Initial = nullptr;
  BasicBlock *EntryPred = nullptr, *Latch = nullptr;
  for (unsigned I = 0; I != 2; ++I) {
    Value *V = State->getIncomingValue(I);
    if (auto *C = dyn_cast<ConstantInt>(V)) {
      Initial = C;
      EntryPred = State->getIncomingBlock(I);
    } else if (auto *PN = dyn_cast<PHINode>(V)) {
      LatchState = PN;
      Latch = State->getIncomingBlock(I);
    }
  }
  if (!Initial || !LatchState || LatchState->getParent() != Latch)
    return false;
  auto *LatchBr = dyn_cast<BranchInst>(Latch->getTerminator());
  if (!LatchBr || !LatchBr->isUnconditional() ||
      LatchBr->getSuccessor(0) != Header)
    return false;

  SmallVector<BasicBlock *, 16> CaseBlocks;
  DenseMap<APInt, BasicBlock *> CaseMap;
  for (auto Case : SI.cases()) {
    BasicBlock *BB = Case.getCaseSuccessor();
    if (BB->phis().begin() != BB->phis().end()) return false;
    auto *Br = dyn_cast<BranchInst>(BB->getTerminator());
    if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Latch)
      return false;
    CaseMap[Case.getCaseValue()->getValue()] = BB;
    CaseBlocks.push_back(BB);
  }
  if (CaseBlocks.size() < 4 || LatchState->getNumIncomingValues() != CaseBlocks.size())
    return false;
  // Default ladders require the symbolic resolver and are deliberately not
  // guessed by this MVP.  It must be reachable only from this switch.
  BasicBlock *Default = SI.getDefaultDest();
  if (!Default->hasNPredecessors(1)) return false;

  auto Resolve = [&](ConstantInt *Raw) -> BasicBlock * {
    auto Encoded = evalStateExpr(SI.getCondition(), State, Raw->getValue());
    if (!Encoded) return nullptr;
    auto It = CaseMap.find(*Encoded);
    return It == CaseMap.end() ? nullptr : It->second;
  };
  BasicBlock *InitialTarget = Resolve(Initial);
  if (!InitialTarget) return false;

  SmallVector<ProvenTransition, 16> Transitions;
  for (BasicBlock *CaseBB : CaseBlocks) {
    int Index = LatchState->getBasicBlockIndex(CaseBB);
    if (Index < 0) return false;
    Value *Next = LatchState->getIncomingValue(Index);
    ProvenTransition T;
    T.Source = CaseBB;
    if (auto *C = dyn_cast<ConstantInt>(Next)) {
      T.TrueTarget = Resolve(C);
    } else if (auto *Sel = dyn_cast<SelectInst>(Next)) {
      auto *TC = dyn_cast<ConstantInt>(Sel->getTrueValue());
      auto *FC = dyn_cast<ConstantInt>(Sel->getFalseValue());
      if (!TC || !FC) return false;
      T.Condition = Sel->getCondition();
      T.TrueTarget = Resolve(TC);
      T.FalseTarget = Resolve(FC);
    } else {
      return false;
    }
    if (!T.TrueTarget || (T.Condition && !T.FalseTarget)) return false;
    Transitions.push_back(T);
  }

  auto *EntryTerm = EntryPred->getTerminator();
  bool FoundHeaderEdge = false;
  for (unsigned I = 0; I != EntryTerm->getNumSuccessors(); ++I)
    if (EntryTerm->getSuccessor(I) == Header) {
      EntryTerm->setSuccessor(I, InitialTarget);
      FoundHeaderEdge = true;
    }
  if (!FoundHeaderEdge) return false;
  for (const ProvenTransition &T : Transitions) {
    Instruction *Old = T.Source->getTerminator();
    if (T.Condition)
      BranchInst::Create(T.TrueTarget, T.FalseTarget, T.Condition,
                         Old->getIterator());
    else
      BranchInst::Create(T.TrueTarget, Old->getIterator());
    Old->eraseFromParent();
    Proofs.push_back({FunctionName, "cff_transition",
                      T.Source->getName().str(), "ssa_constant_transition",
                      "proved"});
  }
  removeUnreachableBlocks(*ParentFunction);
  ++M.DispatchersRecovered;
  Proofs.push_back({FunctionName, "cff_dispatcher", HeaderName,
                    "complete_transition_set",
                    "proved"});
  return true;
}

bool canCloneHeaderPlumbing(BasicBlock *Header, PHINode *State) {
  SmallPtrSet<const Value *, 16> Available;
  Available.insert(State);
  for (Instruction &I : *Header) {
    if (&I == State || isa<DbgInfoIntrinsic>(I)) continue;
    if (isa<PHINode>(I)) return false;
    if (I.isTerminator()) return isa<SwitchInst>(I);
    if (hasPoisonGeneratingFlags(&I)) return false;
    if (auto *TI = dyn_cast<TruncInst>(&I); TI && TI->hasNoUnsignedWrap())
      return false;
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (SI->isAtomic() || SI->isVolatile()) return false;
    } else if (!isa<BinaryOperator>(I) && !isa<CastInst>(I) &&
               !isa<ICmpInst>(I) && !isa<SelectInst>(I) &&
               !isa<FreezeInst>(I)) {
      return false;
    }
    for (Value *Op : I.operands()) {
      auto *OI = dyn_cast<Instruction>(Op);
      if (OI && OI->getParent() == Header && !Available.contains(OI))
        return false;
    }
    Available.insert(&I);
  }
  return false;
}

void cloneHeaderPlumbing(BasicBlock *Header, PHINode *State,
                                Value *RawState, Instruction *InsertBefore,
                                DenseMap<const Value *, Value *> *ResultMap) {
  DenseMap<const Value *, Value *> Map;
  Map[State] = RawState;
  for (Instruction &I : *Header) {
    if (&I == State || isa<PHINode>(I) || isa<DbgInfoIntrinsic>(I)) continue;
    if (I.isTerminator()) break;
    Instruction *Clone = I.clone();
    for (unsigned O = 0; O != Clone->getNumOperands(); ++O) {
      auto It = Map.find(Clone->getOperand(O));
      if (It != Map.end()) Clone->setOperand(O, It->second);
    }
    if (!Clone->getType()->isVoidTy())
      Clone->setName(I.getName() + ".deobf.edge");
    Clone->insertBefore(InsertBefore->getIterator());
    Map[&I] = Clone;
  }
  if (ResultMap) *ResultMap = std::move(Map);
}

bool canCloneDefaultEntry(BasicBlock *Default) {
  if (!Default || !Default->phis().empty()) return false;
  if (!isa<BranchInst>(Default->getTerminator()) &&
      !isa<SwitchInst>(Default->getTerminator()))
    return false;
  for (BasicBlock *Succ : successors(Default))
    if (!Succ->phis().empty()) return false;
  return true;
}

BasicBlock *cloneDefaultEntry(
    BasicBlock *Default, DenseMap<const Value *, Value *> Map,
    StringRef Suffix) {
  BasicBlock *Clone = BasicBlock::Create(
      Default->getContext(), Default->getName() + Suffix,
      Default->getParent(), Default);
  for (Instruction &I : *Default) {
    Instruction *Copy = I.clone();
    for (unsigned O = 0; O != Copy->getNumOperands(); ++O) {
      auto It = Map.find(Copy->getOperand(O));
      if (It != Map.end()) Copy->setOperand(O, It->second);
    }
    if (!Copy->getType()->isVoidTy())
      Copy->setName(I.getName() + ".deobf.default");
    Copy->insertInto(Clone, Clone->end());
    Map[&I] = Copy;
  }
  return Clone;
}

} // namespace brighten_ollvm_deobf
