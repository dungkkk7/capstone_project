#include "OLLVMDeobfInternal.h"

namespace brighten_ollvm_deobf {

std::optional<APInt> evalTransitionExpr(Value *V, Value *StatePointer,
                                               const APInt &EntryState,
                                               unsigned Depth,
                                               const DenseMap<const Value *,
                                                              APInt> *Bindings) {
  if (Depth > 32) return std::nullopt;
  if (Bindings) {
    auto It = Bindings->find(V);
    if (It != Bindings->end()) return It->second;
  }
  // StatePointer historically denoted a memory state cell, but SSA
  // dispatchers pass their state PHI directly.  Bind that exact integer root
  // to the case's decoded raw state before recursively evaluating its update.
  if (V == StatePointer && V->getType()->isIntegerTy(EntryState.getBitWidth()))
    return EntryState;
  if (auto *C = dyn_cast<ConstantInt>(V)) return C->getValue();
  if (auto *Arg = dyn_cast<Argument>(V)) {
    if (!Bindings) return std::nullopt;
    auto It = Bindings->find(Arg);
    return It == Bindings->end() ? std::nullopt
                                 : std::optional<APInt>(It->second);
  }
  if (auto *LI = dyn_cast<LoadInst>(V)) {
    if (StatePointer && !LI->isAtomic() && !LI->isVolatile() &&
        sameFrameAddress(LI->getPointerOperand(), StatePointer))
      return EntryState;
    if (LI->isAtomic() || LI->isVolatile()) return std::nullopt;
    if (auto *GV = dyn_cast<GlobalVariable>(
            LI->getPointerOperand()->stripPointerCasts());
        GV && GV->isConstant() && GV->hasDefinitiveInitializer()) {
      auto *CI = dyn_cast<ConstantInt>(GV->getInitializer());
      if (CI && CI->getType() == LI->getType()) return CI->getValue();
    }
    // Model a second frame object only when its reaching definition is an
    // exact local store.  Intervening writes are crossed solely when their
    // identified byte ranges are proven disjoint; unknown aliasing remains a
    // hard symbolic-execution barrier.
    const DataLayout &DL = LI->getModule()->getDataLayout();
    IntAffine LoadAddress = parsePointerAffine(LI->getPointerOperand());
    TypeSize LoadSize = DL.getTypeStoreSize(LI->getType());
    if (!unitAffineRoot(LoadAddress) || LoadSize.isScalable())
      return std::nullopt;
    for (auto It = LI->getIterator(); It != LI->getParent()->begin();) {
      --It;
      auto *SI = dyn_cast<StoreInst>(&*It);
      if (!SI) {
        if (It->mayWriteToMemory()) return std::nullopt;
        continue;
      }
      if (SI->isAtomic() || SI->isVolatile()) return std::nullopt;
      TypeSize StoreSize = DL.getTypeStoreSize(
          SI->getValueOperand()->getType());
      if (sameFrameAddress(SI->getPointerOperand(), LI->getPointerOperand())) {
        if (StoreSize.isScalable() || StoreSize != LoadSize ||
            !SI->getValueOperand()->getType()->isIntegerTy() ||
            SI->getValueOperand()->getType() != LI->getType())
          return std::nullopt;
        return evalTransitionExpr(SI->getValueOperand(), StatePointer,
                                  EntryState, Depth + 1, Bindings);
      }
      IntAffine StoreAddress = parsePointerAffine(SI->getPointerOperand());
      if (!StoreAddress.Valid || StoreAddress.Terms.empty() ||
          StoreSize.isScalable())
        return std::nullopt;
      if (!sameAffineTerms(StoreAddress, LoadAddress)) {
        if (definitelyDistinctAffineObjects(StoreAddress, LoadAddress))
          continue;
        return std::nullopt;
      }
      uint64_t LoadBytes = LoadSize.getFixedValue();
      uint64_t StoreBytes = StoreSize.getFixedValue();
      if (LoadBytes > uint64_t(std::numeric_limits<int64_t>::max()) ||
          StoreBytes > uint64_t(std::numeric_limits<int64_t>::max()))
        return std::nullopt;
      int64_t LoadBegin = LoadAddress.Offset.getSExtValue();
      int64_t StoreBegin = StoreAddress.Offset.getSExtValue();
      if (LoadBegin > std::numeric_limits<int64_t>::max() -
                          int64_t(LoadBytes) ||
          StoreBegin > std::numeric_limits<int64_t>::max() -
                           int64_t(StoreBytes))
        return std::nullopt;
      int64_t LoadEnd = LoadBegin + int64_t(LoadBytes);
      int64_t StoreEnd = StoreBegin + int64_t(StoreBytes);
      if (StoreEnd <= LoadBegin || LoadEnd <= StoreBegin) continue;
      return std::nullopt;
    }
    // Continue through predecessor blocks with a bounded persistent-object
    // map.  A merge is accepted only when every incoming path reaches the
    // same exact APInt value; cycles, path-dependent values, and any unknown
    // aliasing write remain barriers.
    SmallPtrSet<BasicBlock *, 16> SeenBlocks;
    std::function<std::optional<APInt>(BasicBlock *, unsigned)> FindInBlock;
    FindInBlock = [&](BasicBlock *BB,
                      unsigned BlockDepth) -> std::optional<APInt> {
      if (!BB || BlockDepth > 12 || !SeenBlocks.insert(BB).second)
        return std::nullopt;
      for (auto It = BB->rbegin(), End = BB->rend(); It != End; ++It) {
        auto *SI = dyn_cast<StoreInst>(&*It);
        if (!SI) {
          if (It->mayWriteToMemory()) return std::nullopt;
          continue;
        }
        if (SI->isAtomic() || SI->isVolatile()) return std::nullopt;
        TypeSize StoreSize =
            DL.getTypeStoreSize(SI->getValueOperand()->getType());
        if (sameFrameAddress(SI->getPointerOperand(),
                             LI->getPointerOperand())) {
          if (StoreSize.isScalable() || StoreSize != LoadSize ||
              !SI->getValueOperand()->getType()->isIntegerTy() ||
              SI->getValueOperand()->getType() != LI->getType())
            return std::nullopt;
          return evalTransitionExpr(SI->getValueOperand(), StatePointer,
                                    EntryState, Depth + 1, Bindings);
        }
        IntAffine StoreAddress = parsePointerAffine(SI->getPointerOperand());
        if (!StoreAddress.Valid || StoreAddress.Terms.empty() ||
            StoreSize.isScalable())
          return std::nullopt;
        if (!sameAffineTerms(StoreAddress, LoadAddress)) {
          if (definitelyDistinctAffineObjects(StoreAddress, LoadAddress))
            continue;
          return std::nullopt;
        }
        uint64_t LoadBytes = LoadSize.getFixedValue();
        uint64_t StoreBytes = StoreSize.getFixedValue();
        if (LoadBytes > uint64_t(std::numeric_limits<int64_t>::max()) ||
            StoreBytes > uint64_t(std::numeric_limits<int64_t>::max()))
          return std::nullopt;
        int64_t LoadBegin = LoadAddress.Offset.getSExtValue();
        int64_t StoreBegin = StoreAddress.Offset.getSExtValue();
        if (LoadBegin > std::numeric_limits<int64_t>::max() -
                            int64_t(LoadBytes) ||
            StoreBegin > std::numeric_limits<int64_t>::max() -
                             int64_t(StoreBytes))
          return std::nullopt;
        int64_t LoadEnd = LoadBegin + int64_t(LoadBytes);
        int64_t StoreEnd = StoreBegin + int64_t(StoreBytes);
        if (StoreEnd <= LoadBegin || LoadEnd <= StoreBegin) continue;
        return std::nullopt;
      }
      std::optional<APInt> Common;
      unsigned PredCount = 0;
      for (BasicBlock *Pred : predecessors(BB)) {
        if (++PredCount > 8) return std::nullopt;
        auto Incoming = FindInBlock(Pred, BlockDepth + 1);
        if (!Incoming) return std::nullopt;
        if (Common && *Common != *Incoming) return std::nullopt;
        Common = std::move(Incoming);
      }
      return Common;
    };
    std::optional<APInt> Common;
    unsigned PredCount = 0;
    for (BasicBlock *Pred : predecessors(LI->getParent())) {
      if (++PredCount > 8) return std::nullopt;
      auto Incoming = FindInBlock(Pred, 0);
      if (!Incoming) return std::nullopt;
      if (Common && *Common != *Incoming) return std::nullopt;
      Common = std::move(Incoming);
    }
    return Common;
  }
  if (auto *II = dyn_cast<IntrinsicInst>(V)) {
    Intrinsic::ID ID = II->getIntrinsicID();
    auto Op = evalTransitionExpr(II->getArgOperand(0), StatePointer,
                                 EntryState, Depth + 1, Bindings);
    if (!Op) return std::nullopt;
    if (ID == Intrinsic::bswap)
      return Op->getBitWidth() % 16 == 0
                 ? std::optional<APInt>(Op->byteSwap())
                 : std::nullopt;
    if (ID == Intrinsic::bitreverse) return Op->reverseBits();
    if (ID == Intrinsic::ctpop)
      return APInt(Op->getBitWidth(), Op->popcount());
    if ((ID == Intrinsic::fshl || ID == Intrinsic::fshr) &&
        II->getArgOperand(0) == II->getArgOperand(1)) {
      auto Amount = evalTransitionExpr(II->getArgOperand(2), StatePointer,
                                       EntryState, Depth + 1, Bindings);
      if (!Amount) return std::nullopt;
      unsigned Rotate = unsigned(Amount->urem(Op->getBitWidth()));
      return ID == Intrinsic::fshl ? Op->rotl(Rotate) : Op->rotr(Rotate);
    }
    return std::nullopt;
  }
  if (auto *CB = dyn_cast<CallBase>(V)) {
    Function *Callee = CB->getCalledFunction();
    if (!Callee || Callee->isDeclaration() || Callee->isVarArg() ||
        !Callee->getReturnType()->isIntegerTy() ||
        CB->arg_size() != Callee->arg_size() ||
        (!Callee->doesNotAccessMemory() && !Callee->onlyReadsMemory()) ||
        Callee->size() != 1)
      return std::nullopt;
    auto *RI = dyn_cast<ReturnInst>(Callee->front().getTerminator());
    if (!RI || !RI->getReturnValue()) return std::nullopt;
    DenseMap<const Value *, APInt> LocalBindings;
    unsigned ArgNo = 0;
    for (Argument &Formal : Callee->args()) {
      auto Actual = evalTransitionExpr(CB->getArgOperand(ArgNo++),
                                       StatePointer, EntryState, Depth + 1,
                                       Bindings);
      if (!Actual || !Formal.getType()->isIntegerTy() ||
          Actual->getBitWidth() != Formal.getType()->getIntegerBitWidth())
        return std::nullopt;
      LocalBindings.try_emplace(&Formal, *Actual);
    }
    return evalTransitionExpr(RI->getReturnValue(), StatePointer, EntryState,
                              Depth + 1, &LocalBindings);
  }
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (hasPoisonGeneratingFlags(BO)) return std::nullopt;
    auto L = evalTransitionExpr(BO->getOperand(0), StatePointer, EntryState,
                                Depth + 1, Bindings);
    auto R = evalTransitionExpr(BO->getOperand(1), StatePointer, EntryState,
                                Depth + 1, Bindings);
    if (!L || !R || L->getBitWidth() != R->getBitWidth()) return std::nullopt;
    switch (BO->getOpcode()) {
    case Instruction::Add: return *L + *R;
    case Instruction::Sub: return *L - *R;
    case Instruction::Mul: return *L * *R;
    case Instruction::And: return *L & *R;
    case Instruction::Or: return *L | *R;
    case Instruction::Xor: return *L ^ *R;
    case Instruction::Shl:
      if (R->uge(L->getBitWidth())) return std::nullopt;
      return L->shl(R->getZExtValue());
    case Instruction::LShr:
      if (R->uge(L->getBitWidth())) return std::nullopt;
      return L->lshr(R->getZExtValue());
    case Instruction::AShr:
      if (R->uge(L->getBitWidth())) return std::nullopt;
      return L->ashr(R->getZExtValue());
    default: return std::nullopt;
    }
  }
  if (auto *Cmp = dyn_cast<ICmpInst>(V)) {
    auto L = evalTransitionExpr(Cmp->getOperand(0), StatePointer, EntryState,
                                Depth + 1, Bindings);
    auto R = evalTransitionExpr(Cmp->getOperand(1), StatePointer, EntryState,
                                Depth + 1, Bindings);
    if (!L || !R || L->getBitWidth() != R->getBitWidth()) return std::nullopt;
    return APInt(1, ICmpInst::compare(*L, *R, Cmp->getPredicate()));
  }
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    auto C = evalTransitionExpr(Sel->getCondition(), StatePointer, EntryState,
                                Depth + 1, Bindings);
    if (!C || C->getBitWidth() != 1) return std::nullopt;
    return evalTransitionExpr(C->isZero() ? Sel->getFalseValue()
                                          : Sel->getTrueValue(),
                              StatePointer, EntryState, Depth + 1, Bindings);
  }
  if (auto *Cast = dyn_cast<CastInst>(V)) {
    if (!Cast->getType()->isIntegerTy() || !Cast->getSrcTy()->isIntegerTy())
      return std::nullopt;
    auto Op = evalTransitionExpr(Cast->getOperand(0), StatePointer, EntryState,
                                 Depth + 1, Bindings);
    if (!Op) return std::nullopt;
    unsigned Width = Cast->getType()->getIntegerBitWidth();
    switch (Cast->getOpcode()) {
    case Instruction::Trunc:
      if (cast<TruncInst>(Cast)->hasNoUnsignedWrap()) return std::nullopt;
      return Op->trunc(Width);
    case Instruction::ZExt: return Op->zext(Width);
    case Instruction::SExt: return Op->sext(Width);
    case Instruction::BitCast:
      if (Width == Op->getBitWidth()) return *Op;
      return std::nullopt;
    default: return std::nullopt;
    }
  }
  if (auto *Freeze = dyn_cast<FreezeInst>(V))
    return evalTransitionExpr(Freeze->getOperand(0), StatePointer, EntryState,
                              Depth + 1, Bindings);
  return std::nullopt;
}

Value *findUnboundTransitionChoice(
    Value *V, const DenseMap<const Value *, APInt> &Bindings,
    SmallPtrSetImpl<Value *> &Seen, unsigned Depth) {
  if (!V || Depth > 48 || Bindings.count(V) || isa<Constant>(V) ||
      isa<Argument>(V) || !Seen.insert(V).second)
    return nullptr;
  if ((isa<SelectInst>(V) || isa<PHINode>(V)) &&
      V->getType()->isIntegerTy())
    return V;
  auto *U = dyn_cast<User>(V);
  if (!U) return nullptr;
  for (Value *Op : U->operands())
    if (Value *Choice =
            findUnboundTransitionChoice(Op, Bindings, Seen, Depth + 1))
      return Choice;
  return nullptr;
}

bool appendUniqueTransitionValue(SmallVectorImpl<APInt> &Values,
                                        const APInt &Value,
                                        unsigned Limit) {
  if (llvm::is_contained(Values, Value)) return true;
  if (Values.size() >= Limit) return false;
  Values.push_back(Value);
  return true;
}

// Bounded acyclic executor for transition expressions containing nested
// select/PHI forks.  It enumerates every structurally possible arm, binds the
// chosen PHI/select value, then reuses the exact APInt evaluator for the whole
// expression.  Cyclic choices, unsupported operations, and outcome explosion
// fail closed.
bool enumerateTransitionValues(
    Value *Root, Value *StatePointer, const APInt &EntryState,
    const DenseMap<const Value *, APInt> &Bindings,
    SmallVectorImpl<APInt> &Values, unsigned &Budget, unsigned Depth,
    SmallPtrSetImpl<Value *> *ActiveChoices) {
  if (Depth > 32 || Budget == 0) return false;
  --Budget;
  if (auto Constant = evalTransitionExpr(Root, StatePointer, EntryState, 0,
                                         &Bindings))
    return appendUniqueTransitionValue(Values, *Constant);

  SmallPtrSet<Value *, 32> Seen;
  Value *Choice = findUnboundTransitionChoice(Root, Bindings, Seen);
  if (!Choice) return false;
  SmallPtrSet<Value *, 8> LocalActive;
  if (!ActiveChoices) ActiveChoices = &LocalActive;
  if (!ActiveChoices->insert(Choice).second) return false;

  SmallVector<Value *, 8> Arms;
  if (auto *Sel = dyn_cast<SelectInst>(Choice)) {
    Arms.push_back(Sel->getTrueValue());
    Arms.push_back(Sel->getFalseValue());
  } else {
    auto *Phi = cast<PHINode>(Choice);
    if (Phi->getNumIncomingValues() < 2 ||
        Phi->getNumIncomingValues() > 16) {
      ActiveChoices->erase(Choice);
      return false;
    }
    for (Value *Incoming : Phi->incoming_values()) Arms.push_back(Incoming);
  }

  bool Complete = true;
  for (Value *Arm : Arms) {
    SmallVector<APInt, 8> ArmValues;
    if (!enumerateTransitionValues(Arm, StatePointer, EntryState, Bindings,
                                   ArmValues, Budget, Depth + 1,
                                   ActiveChoices) ||
        ArmValues.empty()) {
      Complete = false;
      break;
    }
    for (const APInt &ArmValue : ArmValues) {
      if (!Choice->getType()->isIntegerTy(ArmValue.getBitWidth())) {
        Complete = false;
        break;
      }
      DenseMap<const Value *, APInt> Extended(Bindings);
      Extended[Choice] = ArmValue;
      if (!enumerateTransitionValues(Root, StatePointer, EntryState, Extended,
                                     Values, Budget, Depth + 1,
                                     ActiveChoices)) {
        Complete = false;
        break;
      }
    }
    if (!Complete) break;
  }
  ActiveChoices->erase(Choice);
  return Complete;
}

bool proveFiniteTransitionSetSMT(Value *Root,
                                        ArrayRef<APInt> Values,
                                        std::string &Certificate) {
  if (!Root || !Root->getType()->isIntegerTy() || Values.empty()) return false;
  try {
    z3::context Ctx;
    Z3BVTranslator Translator(Ctx);
    auto Expr = Translator.translate(Root);
    if (!Expr || !Expr->is_bv() ||
        Expr->get_sort().bv_size() !=
            Root->getType()->getIntegerBitWidth())
      return false;
    z3::expr Outside = Ctx.bool_val(true);
    raw_string_ostream OS(Certificate);
    OS << valueText(*Root) << "\nnot-in{";
    for (unsigned I = 0; I != Values.size(); ++I) {
      if (Values[I].getBitWidth() !=
          Root->getType()->getIntegerBitWidth())
        return false;
      SmallString<80> Text;
      Values[I].toString(Text, 10, false);
      z3::expr Constant = Ctx.bv_val(
          Text.c_str(), Root->getType()->getIntegerBitWidth());
      Outside = Outside && (*Expr != Constant);
      if (I) OS << ',';
      OS << Text;
    }
    OS << "}\n" << Translator.getSliceCertificate();
    OS.flush();
    z3::params Params(Ctx);
    Params.set("timeout", 1500u);
    z3::solver Solver(Ctx);
    Solver.set(Params);
    Solver.add(Outside);
    return Solver.check() == z3::unsat;
  } catch (const z3::exception &) {
    return false;
  }
}

ConstantInt *findLocalReachingConstant(LoadInst &LI,
                                               BasicBlock *Source) {
  if (LI.getParent() != Source) return nullptr;
  for (auto It = LI.getIterator(); It != Source->begin();) {
    --It;
    if (auto *SI = dyn_cast<StoreInst>(&*It)) {
      if (sameFrameAddress(SI->getPointerOperand(), LI.getPointerOperand()))
        return dyn_cast<ConstantInt>(SI->getValueOperand());
      continue;
    }
    if (It->mayWriteToMemory())
      return nullptr;
  }
  return nullptr;
}

ConstantInt *asTransitionConstant(Value *V, BasicBlock *Source) {
  if (auto *C = dyn_cast<ConstantInt>(V)) return C;
  if (auto *LI = dyn_cast<LoadInst>(V))
    return findLocalReachingConstant(*LI, Source);
  return nullptr;
}

} // namespace brighten_ollvm_deobf
