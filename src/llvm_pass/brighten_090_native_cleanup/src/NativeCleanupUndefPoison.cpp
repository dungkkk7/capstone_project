#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

// McSema dispatchers can pass undef/poison arguments to a lifted ABI callee
// even after those arguments have become dead.  Rewrite only proven-dead
// arguments; live values and poison used elsewhere remain diagnosed by the
// strict verifier.
unsigned canonicalizeDeadLiftedArguments(Module &M) {
  unsigned Replaced = 0;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || CB->arg_size() < 2)
          continue;
        auto *Callee = dyn_cast<Function>(
            CB->getCalledOperand()->stripPointerCasts());
        if (!Callee || !isLiftedABI(*Callee))
          continue;
        for (unsigned ArgNo = 0; ArgNo < 3; ++ArgNo) {
          if (!Callee->getArg(ArgNo)->use_empty())
            continue;
          Value *Arg = CB->getArgOperand(ArgNo);
          if (!isa<UndefValue>(Arg) && !isa<PoisonValue>(Arg))
            continue;
          Type *Ty = Arg->getType();
          Constant *Zero = nullptr;
          if (Ty->isPointerTy() || Ty->isIntegerTy())
            Zero = Constant::getNullValue(Ty);
          if (!Zero)
            continue;
          CB->setArgOperand(ArgNo, Zero);
          ++Replaced;
        }
      }
    }
  }
  return Replaced;
}

// Recover a common carried value for a PHI whose missing incoming edge was
// emitted as undef/poison.  This is only applied when every defined incoming
// edge is the exact same SSA value; no arbitrary zero/null is introduced.
// Such a PHI is a state-carrier that was not written on the exceptional edge.
unsigned canonicalizeEquivalentPhiUndefined(Module &M) {
  unsigned Replaced = 0;
  for (Function &F : M) {
    std::unique_ptr<DominatorTree> DT;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *PN = dyn_cast<PHINode>(&I);
        if (!PN)
          continue;
        Value *Common = nullptr;
        bool HasUndefined = false;
        bool Consistent = true;
        for (Value *Incoming : PN->incoming_values()) {
          if (isa<UndefValue>(Incoming) || isa<PoisonValue>(Incoming)) {
            HasUndefined = true;
            continue;
          }
          if (!Common) {
            Common = Incoming;
          } else if (Common != Incoming) {
            Consistent = false;
            break;
          }
        }
        if (!HasUndefined || !Common || !Consistent)
          continue;
        bool DominatesAllIncomingEdges = true;
        if (auto *CommonInst = dyn_cast<Instruction>(Common)) {
          if (!DT)
            DT = std::make_unique<DominatorTree>(F);
          for (unsigned I = 0; I < PN->getNumIncomingValues(); ++I) {
            Value *Incoming = PN->getIncomingValue(I);
            if (!isa<UndefValue>(Incoming) && !isa<PoisonValue>(Incoming))
              continue;
            if (!DT->dominates(CommonInst, PN->getIncomingBlock(I))) {
              DominatesAllIncomingEdges = false;
              break;
            }
          }
        }
        if (!DominatesAllIncomingEdges)
          continue;
        for (unsigned I = 0; I < PN->getNumIncomingValues(); ++I) {
          Value *Incoming = PN->getIncomingValue(I);
          if (isa<UndefValue>(Incoming) || isa<PoisonValue>(Incoming)) {
            PN->setIncomingValue(I, Common);
            ++Replaced;
          }
        }
      }
    }
  }
  return Replaced;
}

// Undef/poison can survive in vector shuffle scaffolding even after all
// lifted state has been removed.  Freeze preserves the LLVM contract (the
// value remains arbitrary) while preventing poison from infecting native IR.
// PHI operands are intentionally skipped here because a freeze must be
// inserted in the predecessor block, not before the PHI itself.
unsigned freezeUndefinedInstructionOperands(Module &M) {
  unsigned Frozen = 0;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (!isa<ShuffleVectorInst>(&I) && !isa<InsertElementInst>(&I) &&
            !isa<ExtractElementInst>(&I))
          continue;
        for (Use &Op : I.operands()) {
          Value *V = Op.get();
          if (!containsUndefined(V) || !V->getType()->isFirstClassType())
            continue;
          IRBuilder<> B(&I);
          Value *Defined = B.CreateFreeze(V, "native.freeze");
          Op.set(Defined);
          ++Frozen;
        }
      }
    }
  }
  return Frozen;
}

// A State-SSA return is often assembled from an undef/poison aggregate and a
// chain of inserts.  When every undefined top-level element is overwritten
// before the chain has any other user, the scaffold is unobservable.  Make
// only those undefined elements concrete, preserving all defined elements.
// This is deliberately narrower than replacing arbitrary unknown values.
Constant *definedScaffold(Constant *C) {
  if (isa<UndefValue>(C) || isa<PoisonValue>(C))
    return Constant::getNullValue(C->getType());

  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    SmallVector<Constant *, 16> Elements;
    for (Value *Op : CS->operands())
      Elements.push_back(definedScaffold(cast<Constant>(Op)));
    return ConstantStruct::get(cast<StructType>(CS->getType()), Elements);
  }
  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    SmallVector<Constant *, 16> Elements;
    for (Value *Op : CA->operands())
      Elements.push_back(definedScaffold(cast<Constant>(Op)));
    return ConstantArray::get(cast<ArrayType>(CA->getType()), Elements);
  }
  if (auto *CV = dyn_cast<ConstantVector>(C)) {
    SmallVector<Constant *, 16> Elements;
    for (Value *Op : CV->operands())
      Elements.push_back(definedScaffold(cast<Constant>(Op)));
    return ConstantVector::get(Elements);
  }
  return C;
}

unsigned lowerFullyOverwrittenUndefinedScaffolds(Module &M) {
  SmallVector<FreezeInst *, 32> Work;
  for (Function &F : M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *FI = dyn_cast<FreezeInst>(&I))
          if (containsUndefined(FI->getOperand(0)))
            Work.push_back(FI);

  unsigned Lowered = 0;
  for (FreezeInst *FI : Work) {
    auto *C = dyn_cast<Constant>(FI->getOperand(0));
    if (!C || !FI->hasOneUse())
      continue;

    unsigned ElementCount = 0;
    if (auto *ST = dyn_cast<StructType>(C->getType()))
      ElementCount = ST->getNumElements();
    else if (auto *VT = dyn_cast<FixedVectorType>(C->getType()))
      ElementCount = VT->getNumElements();
    else
      continue;

    SmallVector<bool, 16> NeedsOverwrite(ElementCount, false);
    if (isa<UndefValue>(C) || isa<PoisonValue>(C)) {
      std::fill(NeedsOverwrite.begin(), NeedsOverwrite.end(), true);
    } else {
      if (C->getNumOperands() != ElementCount)
        continue;
      for (unsigned I = 0; I < ElementCount; ++I)
        NeedsOverwrite[I] = containsUndefined(C->getOperand(I));
    }

    auto HasPending = [&]() {
      return llvm::any_of(NeedsOverwrite, [](bool V) { return V; });
    };
    Value *Current = FI;
    bool Proven = HasPending();
    while (Proven && HasPending()) {
      if (!Current->hasOneUse()) {
        Proven = false;
        break;
      }
      User *OnlyUser = *Current->user_begin();
      unsigned Index = 0;
      if (auto *IV = dyn_cast<InsertValueInst>(OnlyUser)) {
        ArrayRef<unsigned> Indices = IV->getIndices();
        if (IV->getAggregateOperand() != Current || Indices.size() != 1) {
          Proven = false;
          break;
        }
        Index = Indices.front();
      } else if (auto *IE = dyn_cast<InsertElementInst>(OnlyUser)) {
        auto *CI = dyn_cast<ConstantInt>(IE->getOperand(2));
        if (IE->getOperand(0) != Current || !CI) {
          Proven = false;
          break;
        }
        Index = CI->getZExtValue();
      } else {
        Proven = false;
        break;
      }
      if (Index >= ElementCount) {
        Proven = false;
        break;
      }
      NeedsOverwrite[Index] = false;
      Current = cast<Value>(OnlyUser);
    }

    if (!Proven)
      continue;
    FI->setOperand(0, definedScaffold(C));
    ++Lowered;
  }
  return Lowered;
}

bool isVectorLaneUnobserved(Value *V, unsigned Lane,
                                   std::set<std::pair<Value *, unsigned>> &Seen) {
  if (!Seen.insert({V, Lane}).second)
    return true;
  for (User *U : V->users()) {
    if (auto *EE = dyn_cast<ExtractElementInst>(U)) {
      auto *CI = dyn_cast<ConstantInt>(EE->getOperand(1));
      if (!CI || CI->getZExtValue() == Lane)
        return false;
      continue;
    }
    if (auto *IE = dyn_cast<InsertElementInst>(U)) {
      if (IE->getOperand(0) != V)
        return false;
      auto *CI = dyn_cast<ConstantInt>(IE->getOperand(2));
      if (CI && CI->getZExtValue() == Lane)
        continue;
      if (!isVectorLaneUnobserved(IE, Lane, Seen))
        return false;
      continue;
    }
    if (auto *SV = dyn_cast<ShuffleVectorInst>(U)) {
      unsigned Width = cast<FixedVectorType>(V->getType())->getNumElements();
      unsigned Base = SV->getOperand(1) == V ? Width : 0;
      if (SV->getOperand(0) != V && SV->getOperand(1) != V)
        return false;
      for (unsigned Out = 0; Out < SV->getShuffleMask().size(); ++Out)
        if (SV->getMaskValue(Out) == static_cast<int>(Base + Lane) &&
            !isVectorLaneUnobserved(SV, Out, Seen))
          return false;
      continue;
    }
    if (auto *CI = dyn_cast<CastInst>(U)) {
      auto *InputTy = dyn_cast<FixedVectorType>(V->getType());
      auto *OutputTy = dyn_cast<FixedVectorType>(CI->getType());
      if (!InputTy || !OutputTy ||
          InputTy->getNumElements() != OutputTy->getNumElements() ||
          !isVectorLaneUnobserved(CI, Lane, Seen))
        return false;
      continue;
    }
    if ((isa<BinaryOperator>(U) || isa<SelectInst>(U) ||
         isa<FreezeInst>(U) || isa<PHINode>(U)) &&
        U->getType()->isVectorTy()) {
      if (!isVectorLaneUnobserved(cast<Value>(U), Lane, Seen))
        return false;
      continue;
    }
    return false;
  }
  return true;
}

// Resolve only shuffle result lanes that are proven unobservable through
// lane-preserving vector operations.  This handles SIMD scaffolding such as
// `<1, poison>` followed by a lane-wise multiply and extraction of lane zero;
// an observed poison lane remains untouched and fails strict verification.
unsigned lowerUnobservedUndefinedShuffleLanes(Module &M) {
  SmallVector<ShuffleVectorInst *, 16> Work;
  for (Function &F : M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *SV = dyn_cast<ShuffleVectorInst>(&I))
          Work.push_back(SV);

  unsigned Lowered = 0;
  for (ShuffleVectorInst *SV : Work) {
    auto *VT = dyn_cast<FixedVectorType>(SV->getType());
    if (!VT)
      continue;
    SmallVector<int, 16> Mask(SV->getShuffleMask().begin(),
                              SV->getShuffleMask().end());
    bool ChangedMask = false;
    for (unsigned Lane = 0; Lane < Mask.size(); ++Lane) {
      if (Mask[Lane] >= 0)
        continue;
      std::set<std::pair<Value *, unsigned>> Seen;
      if (!isVectorLaneUnobserved(SV, Lane, Seen))
        continue;
      Mask[Lane] = 0;
      ChangedMask = true;
    }
    if (!ChangedMask)
      continue;

    unsigned Width = VT->getNumElements();
    bool UsesSecond = llvm::any_of(Mask, [Width](int Index) {
      return Index >= static_cast<int>(Width);
    });
    Value *Second = SV->getOperand(1);
    bool UndefinedSecond = containsUndefined(Second);
    if (auto *FI = dyn_cast<FreezeInst>(Second))
      UndefinedSecond |= containsUndefined(FI->getOperand(0));
    if (!UsesSecond && UndefinedSecond)
      Second = Constant::getNullValue(Second->getType());

    IRBuilder<> B(SV);
    Value *Replacement = B.CreateShuffleVector(
        SV->getOperand(0), Second, Mask, SV->getName() + ".defined");
    Value *OldSecond = SV->getOperand(1);
    SV->replaceAllUsesWith(Replacement);
    SV->eraseFromParent();
    if (auto *FI = dyn_cast<FreezeInst>(OldSecond))
      if (FI->use_empty())
        FI->eraseFromParent();
    ++Lowered;
  }
  return Lowered;
}

// A shuffle that selects the same explicitly inserted lane for every result
// lane does not observe the remaining lanes of its input vector.  Rebuild it
// from a zero vector instead of leaving an undef/poison vector scaffold for
// the final verifier to report.  This is an exact rewrite: every observable
// lane is the original inserted scalar.
unsigned lowerSingleLaneVectorBroadcasts(Module &M) {
  SmallVector<ShuffleVectorInst *, 32> Work;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *SV = dyn_cast<ShuffleVectorInst>(&I))
          Work.push_back(SV);
  }

  unsigned Lowered = 0;
  for (ShuffleVectorInst *SV : Work) {
    auto *VecTy = dyn_cast<FixedVectorType>(SV->getType());
    if (!VecTy || VecTy->getNumElements() == 0)
      continue;
    int Selected = SV->getMaskValue(0);
    if (Selected < 0)
      continue;
    bool IsBroadcast = true;
    for (unsigned I = 1; I < VecTy->getNumElements(); ++I) {
      if (SV->getMaskValue(I) != Selected) {
        IsBroadcast = false;
        break;
      }
    }
    if (!IsBroadcast)
      continue;

    unsigned InputLanes = VecTy->getNumElements();
    unsigned OperandIndex = static_cast<unsigned>(Selected) / InputLanes;
    unsigned SourceLane = static_cast<unsigned>(Selected) % InputLanes;
    if (OperandIndex > 1)
      continue;
    auto *Insert = dyn_cast<InsertElementInst>(SV->getOperand(OperandIndex));
    auto *InsertIndex =
        Insert ? dyn_cast<ConstantInt>(Insert->getOperand(2)) : nullptr;
    if (!InsertIndex || InsertIndex->getZExtValue() != SourceLane)
      continue;

    IRBuilder<> B(SV);
    Value *Broadcast = Constant::getNullValue(VecTy);
    Value *Scalar = Insert->getOperand(1);
    for (unsigned I = 0; I < InputLanes; ++I)
      Broadcast = B.CreateInsertElement(Broadcast, Scalar, B.getInt32(I),
                                        "native.vector.splat");
    SV->replaceAllUsesWith(Broadcast);
    SV->eraseFromParent();
    ++Lowered;
  }
  return Lowered;
}

} // namespace brighten_native_cleanup
