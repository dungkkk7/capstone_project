#include "NativeCleanup.h"
#include "NativeStateSSA.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Transforms/Utils/Cloning.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <string>
#include <algorithm>
#include <functional>
#include <limits>
#include <map>
#include <optional>
#include <set>

using namespace llvm;

namespace brighten_native_cleanup {
namespace {

static cl::opt<bool> NativeStrict(
    "brighten-native-strict",
    cl::desc("Fail unless the complete module satisfies the native IR contract"),
    cl::init(false));

static cl::opt<bool> NativeStateSSA(
    "brighten-native-state-ssa",
    cl::desc("Lower native functions from State pointer ABI to SSA slots"),
    cl::init(false));

static bool isLiftedFunctionName(StringRef Name) {
  return Name.starts_with("__remill_") ||
         Name.starts_with("__mcsema_") ||
         Name.starts_with("__translate_guest_pointer") ||
         Name.contains(".remill") ||
         Name == "main_wrapper" || Name == "start_wrapper" ||
         (Name.starts_with("callback_") && Name.ends_with("_wrapper")) ||
         Name.starts_with("ext_");
}

static bool isLiftedGlobalName(StringRef Name) {
  return Name.starts_with("seg_") || Name.starts_with("data_") ||
         Name.starts_with("native_data_") ||
         Name.starts_with("addr_carrier_cand_") ||
         Name.starts_with("__lifter_guest_stack") ||
         Name.starts_with("__mcsema_reg_state") ||
         Name.starts_with("RAX_") || Name.starts_with("RSP_") ||
         Name.starts_with("RBP_") || Name.starts_with("RIP_") ||
         Name.starts_with("RDI_") || Name.starts_with("RSI_") ||
         Name.starts_with("RDX_") || Name.starts_with("RCX_") ||
         Name.starts_with("R8_") || Name.starts_with("R9_") ||
         Name.starts_with("CF_") || Name.starts_with("ZF_") ||
         Name.starts_with("SF_") || Name.starts_with("OF_") ||
         Name.starts_with("AF_") || Name.starts_with("PF_");
}

static bool isStateType(Type *Ty) {
  auto *ST = dyn_cast_or_null<StructType>(Ty);
  if (!ST || !ST->hasName())
    return false;
  StringRef Name = ST->getName();
  return Name == "State" || Name.ends_with(".State") ||
         Name.contains("struct.State") || Name.contains("ArchState") ||
         Name.ends_with(".state_result");
}

static bool isLiftedABI(Function &F) {
  if (F.arg_size() != 3 || !F.getReturnType()->isPointerTy())
    return false;
  auto It = F.arg_begin();
  Type *StateTy = (It++)->getType();
  Type *PCTy = (It++)->getType();
  Type *MemoryTy = (It++)->getType();
  return StateTy->isPointerTy() && PCTy->isIntegerTy(64) &&
         MemoryTy->isPointerTy();
}

static bool isAddressArtifact(Value *V) {
  V = V ? V->stripPointerCasts() : nullptr;
  auto *GV = dyn_cast_or_null<GlobalValue>(V);
  if (!GV)
    return false;
  StringRef Name = GV->getName();
  return isLiftedGlobalName(Name) || Name.starts_with("data_") ||
         Name.starts_with("seg_") || Name.starts_with("sub_") ||
         Name.starts_with("ext_");
}

static bool containsUndefined(Value *V) {
  if (!V)
    return false;
  if (isa<UndefValue>(V) || isa<PoisonValue>(V))
    return true;
  auto *C = dyn_cast<Constant>(V);
  if (!C)
    return false;
  for (Value *Op : C->operands()) {
    if (containsUndefined(Op))
      return true;
  }
  return false;
}

static void addFinding(SmallVectorImpl<std::string> &Findings,
                       StringRef Category, StringRef Name) {
  std::string Finding;
  raw_string_ostream OS(Finding);
  OS << Category << ": " << Name;
  for (const std::string &Existing : Findings)
    if (Existing == Finding)
      return;
  Findings.push_back(Finding);
}

// McSema dispatchers can pass undef/poison arguments to a lifted ABI callee
// even after those arguments have become dead.  Rewrite only proven-dead
// arguments; live values and poison used elsewhere remain diagnosed by the
// strict verifier.
static unsigned canonicalizeDeadLiftedArguments(Module &M) {
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
static unsigned canonicalizeEquivalentPhiUndefined(Module &M) {
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
static unsigned freezeUndefinedInstructionOperands(Module &M) {
  unsigned Frozen = 0;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (!isa<ShuffleVectorInst>(&I) && !isa<InsertElementInst>(&I) && !isa<ExtractElementInst>(&I))
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
static Constant *definedScaffold(Constant *C) {
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

static unsigned lowerFullyOverwrittenUndefinedScaffolds(Module &M) {
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

static bool isVectorLaneUnobserved(Value *V, unsigned Lane,
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
static unsigned lowerUnobservedUndefinedShuffleLanes(Module &M) {
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
static unsigned lowerSingleLaneVectorBroadcasts(Module &M) {
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

static bool isNativePointerValue(Value *V, SmallPtrSetImpl<Value *> &Visited);

static bool isNativeStateSlot(Value *V) {
  auto *GEP = dyn_cast<GEPOperator>(V ? V->stripPointerCasts() : nullptr);
  if (!GEP)
    return false;
  auto *BaseArg = dyn_cast<Argument>(GEP->getPointerOperand());
  if (!BaseArg || BaseArg->getArgNo() != 0 ||
      !BaseArg->getType()->isPointerTy())
    return false;

  const DataLayout &DL = BaseArg->getParent()->getParent()->getDataLayout();
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = GEP->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (Base != BaseArg || Offset.isNegative())
    return false;
  uint64_t Bytes = Offset.getZExtValue();
  // State-SSA lays out the CPU register/flag region at this offset range.
  // The bridge has already normalized pointer-valued ABI registers and the
  // entrypoint initializes RSP from a native alloca, so values loaded from
  // this region and used for memory addresses are native pointer integers.
  return Bytes >= 2065 && Bytes < 2500;
}

static bool isNativeInteger(Value *V, SmallPtrSetImpl<Value *> &Visited) {
  if (!V)
    return false;
  // A loop-carried state PHI can revisit itself.  The first traversal must
  // establish a non-constant native source; revisiting that SSA cycle does
  // not introduce a new unknown source.
  if (!Visited.insert(V).second)
    return true;
  if (isa<ConstantInt>(V))
    return false;

  if (auto *Arg = dyn_cast<Argument>(V)) {
    StringRef Name = Arg->getName();
    return Name.starts_with("arg_RDI") || Name.starts_with("arg_RSI") ||
           Name.starts_with("arg_RDX") || Name.starts_with("arg_RCX") ||
           Name.starts_with("arg_R8") || Name.starts_with("arg_R9");
  }

  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    return isNativePointerValue(PTI->getPointerOperand(), Visited);
  if (auto *LI = dyn_cast<LoadInst>(V))
    return isNativeStateSlot(LI->getPointerOperand());
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    bool HasDynamic = false;
    for (Value *Op : BO->operands()) {
      if (isa<ConstantInt>(Op))
        continue;
      HasDynamic = true;
      if (!isNativeInteger(Op, Visited))
        return false;
    }
    return HasDynamic;
  }
  if (auto *Cast = dyn_cast<CastInst>(V))
    return isNativeInteger(Cast->getOperand(0), Visited);
  if (auto *PN = dyn_cast<PHINode>(V)) {
    bool HasDynamic = false;
    for (Value *Incoming : PN->incoming_values())
      if (isa<ConstantInt>(Incoming))
        continue;
      else if (!isNativeInteger(Incoming, Visited))
        return false;
      else
        HasDynamic = true;
    return HasDynamic;
  }
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    bool TrueOK = isa<ConstantInt>(Sel->getTrueValue()) ||
                  isNativeInteger(Sel->getTrueValue(), Visited);
    bool FalseOK = isa<ConstantInt>(Sel->getFalseValue()) ||
                   isNativeInteger(Sel->getFalseValue(), Visited);
    return TrueOK && FalseOK;
  }
  return false;
}

static bool isNativePointerValue(Value *V,
                                 SmallPtrSetImpl<Value *> &Visited) {
  if (!V || !Visited.insert(V).second)
    return false;
  if (isa<AllocaInst>(V) || isa<Argument>(V))
    return V->getType()->isPointerTy();
  if (auto *GV = dyn_cast<GlobalValue>(V))
    return !isAddressArtifact(GV);
  if (auto *GEP = dyn_cast<GEPOperator>(V))
    return isNativePointerValue(GEP->getPointerOperand(), Visited);
  if (auto *PN = dyn_cast<PHINode>(V)) {
    for (Value *Incoming : PN->incoming_values())
      if (!isNativePointerValue(Incoming, Visited))
        return false;
    return true;
  }
  if (auto *Sel = dyn_cast<SelectInst>(V))
    return isNativePointerValue(Sel->getTrueValue(), Visited) &&
           isNativePointerValue(Sel->getFalseValue(), Visited);
  if (auto *CB = dyn_cast<CallBase>(V)) {
    Function *Callee = CB->getCalledFunction();
    return V->getType()->isPointerTy() &&
           (!Callee || !Callee->getName().starts_with(
                           "__translate_guest_pointer"));
  }
  return false;
}

static std::optional<std::pair<GlobalVariable *, uint64_t>>
FindRecoveredGlobalForGuestAddress(Module &M, uint64_t Address);

static Value *lowerNativeStackInteger(IRBuilder<> &B, Value *Integer,
                                      Function &F);

static unsigned lowerProvenNativePointerTranslations(Module &M,
                                                      bool &Changed) {
  Function *Translator = M.getFunction("__translate_guest_pointer");
  if (!Translator || Translator->isDeclaration())
    return 0;

  SmallVector<CallInst *, 128> Calls;
  for (Function &F : M) {
    if (&F == Translator)
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (CI && CI->getCalledFunction() == Translator)
          Calls.push_back(CI);
      }
    }
  }

  unsigned Lowered = 0;
  struct DynamicGuestAddress {
    GlobalVariable *Segment = nullptr;
    uint64_t Offset = 0;
    Value *Dynamic = nullptr;
  };

  auto FindDynamicGuestAddress = [&](Value *V, auto &&Self)
      -> std::optional<DynamicGuestAddress> {
    if (!V)
      return std::nullopt;
    if (auto *Cast = dyn_cast<CastInst>(V))
      return Self(Cast->getOperand(0), Self);
    auto *BO = dyn_cast<BinaryOperator>(V);
    if (!BO || BO->getOpcode() != Instruction::Add ||
        !BO->getType()->isIntegerTy())
      return std::nullopt;

    auto Direct = [&](Value *ConstantSide, Value *DynamicSide)
        -> std::optional<DynamicGuestAddress> {
      if (auto *CI = dyn_cast<ConstantInt>(ConstantSide)) {
        auto Match =
            FindRecoveredGlobalForGuestAddress(M, CI->getZExtValue());
        if (!Match)
          return std::nullopt;
        return DynamicGuestAddress{Match->first, Match->second, DynamicSide};
      }

      Value *PointerBase = nullptr;
      if (auto *CE = dyn_cast<ConstantExpr>(ConstantSide)) {
        if (CE->getOpcode() == Instruction::PtrToInt)
          PointerBase = CE->getOperand(0);
      } else if (auto *PTI = dyn_cast<PtrToIntInst>(ConstantSide)) {
        PointerBase = PTI->getPointerOperand();
      }
      auto *GV = dyn_cast_or_null<GlobalVariable>(
          PointerBase ? PointerBase->stripPointerCasts() : nullptr);
      if (!GV || GV->isDeclaration())
        return std::nullopt;
      return DynamicGuestAddress{GV, 0, DynamicSide};
    };
    if (auto Match = Direct(BO->getOperand(0), BO->getOperand(1)))
      return Match;
    if (auto Match = Direct(BO->getOperand(1), BO->getOperand(0)))
      return Match;

    auto Left = Self(BO->getOperand(0), Self);
    auto Right = Self(BO->getOperand(1), Self);
    if (Left && !Right) {
      IRBuilder<> B(BO);
      Left->Dynamic = B.CreateAdd(Left->Dynamic, BO->getOperand(1),
                                  "native.translated.offset");
      return Left;
    }
    if (Right && !Left) {
      IRBuilder<> B(BO);
      Right->Dynamic = B.CreateAdd(Right->Dynamic, BO->getOperand(0),
                                   "native.translated.offset");
      return Right;
    }
    return std::nullopt;
  };

  for (CallInst *CI : Calls) {
    if (CI->arg_size() != 1)
      continue;
    Value *Address = CI->getArgOperand(0);
    Value *RoundTripPointer = nullptr;
    if (auto *CE = dyn_cast<ConstantExpr>(Address)) {
      if (CE->getOpcode() == Instruction::PtrToInt)
        RoundTripPointer = CE->getOperand(0);
    } else if (auto *PTI = dyn_cast<PtrToIntInst>(Address)) {
      RoundTripPointer = PTI->getPointerOperand();
    }
    if (RoundTripPointer) {
      IRBuilder<> B(CI);
      Value *NativePtr = RoundTripPointer;
      if (NativePtr->getType() != CI->getType())
        NativePtr = B.CreatePointerCast(NativePtr, CI->getType(),
                                        "native.pointer.cast");
      CI->replaceAllUsesWith(NativePtr);
      CI->eraseFromParent();
      ++Lowered;
      Changed = true;
      continue;
    }
    if (auto *ConstantAddress = dyn_cast<ConstantInt>(Address)) {
      uint64_t GuestAddress = ConstantAddress->getZExtValue();
      GlobalVariable *NativeData = nullptr;
      uint64_t Offset = 0;
      for (GlobalVariable &GV : M.globals()) {
        StringRef Name = GV.getName();
        if (!Name.starts_with("native_data_") || GV.isDeclaration())
          continue;
        StringRef BaseText =
            Name.drop_front(StringRef("native_data_").size());
        uint64_t Base = 0;
        if (BaseText.getAsInteger(16, Base) || GuestAddress < Base)
          continue;
        uint64_t CandidateOffset = GuestAddress - Base;
        uint64_t Size = M.getDataLayout()
                            .getTypeAllocSize(GV.getValueType())
                            .getFixedValue();
        if (CandidateOffset >= Size)
          continue;
        NativeData = &GV;
        Offset = CandidateOffset;
        break;
      }
      if (NativeData) {
        IRBuilder<> B(CI);
        Value *NativePtr = B.CreateConstGEP1_64(
            B.getInt8Ty(), NativeData, Offset, "native.data.ptr");
        CI->replaceAllUsesWith(NativePtr);
        CI->eraseFromParent();
        ++Lowered;
        Changed = true;
        continue;
      }
    }
    if (auto Match = FindDynamicGuestAddress(Address, FindDynamicGuestAddress)) {
      IRBuilder<> B(CI);
      // A numeric RSP/RBP expression can accidentally look like guest base
      // zero after the lifted translator is inlined.  Its provenance is
      // stronger than the numeric range match: rebase it on the explicit
      // native stack anchor instead of manufacturing a pointer into an ELF
      // header/data blob.
      Value *NativePtr = lowerNativeStackInteger(B, Address, *CI->getFunction());
      if (!NativePtr) {
        Value *Offset = Match->Dynamic;
        if (Match->Offset != 0)
          Offset = B.CreateAdd(Offset, B.getInt64(Match->Offset),
                               "native.translated.segment.offset");
        if (!Offset->getType()->isIntegerTy(64))
          Offset = B.CreateZExtOrTrunc(Offset, B.getInt64Ty(),
                                       "native.translated.offset.ext");
        NativePtr = B.CreateGEP(B.getInt8Ty(), Match->Segment, Offset,
                                "native.translated.segment.ptr");
      }
      CI->replaceAllUsesWith(NativePtr);
      CI->eraseFromParent();
      ++Lowered;
      Changed = true;
      continue;
    }
    // Preserve the original translator fallback for an address whose guest
    // range is not statically recoverable.  This is intentionally a dynamic
    // inttoptr: native integers (heap pointers, stack pointers, callbacks)
    // already use host addresses at this point, while recovered data and
    // explicit guest-base arithmetic took the native GEP paths above.
    IRBuilder<> B(CI);
    Value *NativePtr =
        B.CreateIntToPtr(Address, CI->getType(), "native.dynamic.pointer");
    CI->replaceAllUsesWith(NativePtr);
    CI->eraseFromParent();
    ++Lowered;
    Changed = true;
  }

  if (Translator->use_empty()) {
    Translator->eraseFromParent();
    Changed = true;
  }
  return Lowered;
}

static bool IsNativeVarargSaveSlot(Value *Ptr) {
  auto *GEP = dyn_cast<GEPOperator>(Ptr ? Ptr->stripPointerCasts() : nullptr);
  if (!GEP || GEP->getNumIndices() == 0)
    return false;
  auto *AI = dyn_cast<AllocaInst>(GEP->getPointerOperand()->stripPointerCasts());
  if (!AI || !AI->getName().contains("reg_save_area"))
    return false;
  auto It = GEP->idx_end();
  --It;
  auto *Offset = dyn_cast<ConstantInt>(*It);
  if (!Offset)
    return false;
  uint64_t ByteOffset = Offset->getZExtValue();
  return ByteOffset <= 40 && (ByteOffset % 8) == 0;
}

// A lifted stack pointer is carried as an integer state slot until the final
// native ABI lowering.  Preserve that provenance even when arithmetic has
// been folded or split across several SSA instructions.
static bool containsNativeStackInteger(
    Value *V, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  StringRef Name = V->getName();
  if (Name.contains("state_2312") || Name.contains("state_2328") ||
      Name.contains("state_in_2312") || Name.contains("state_in_2328") ||
      Name.contains("new_rsp") || Name.contains("new_rbp"))
    return true;
  if (auto *LI = dyn_cast<LoadInst>(V)) {
    if (auto *GEP = dyn_cast<GEPOperator>(LI->getPointerOperand())) {
      auto *State = dyn_cast<GlobalVariable>(
          GEP->getPointerOperand()->stripPointerCasts());
      if (State && State->getName().contains("__mcsema_reg_state") &&
          GEP->getNumIndices() != 0) {
        auto It = GEP->idx_end();
        --It;
        if (auto *Offset = dyn_cast<ConstantInt>(*It))
          if (Offset->equalsInt(2312) || Offset->equalsInt(2328))
            return true;
      }
    }
  }
  auto *I = dyn_cast<Instruction>(V);
  if (!I)
    return false;
  for (Value *Op : I->operands())
    if (Op->getType()->isIntegerTy() &&
        containsNativeStackInteger(Op, Seen))
      return true;
  return false;
}

static Argument *findNativeStackArgument(Function &F) {
  for (Argument &Arg : F.args())
    if ((Arg.getName() == "native_stack" || Arg.getName() == "frame_base") &&
        Arg.getType()->isPointerTy())
      return &Arg;
  return nullptr;
}

// Native entry wrappers have no frame_base parameter, but State-SSA preserves
// their real stack backing as an entry-block frame_storage alloca.  It is a
// valid anchor for rebasing the remaining integer RSP/RBP values because it
// dominates every use in that wrapper.
static Value *findNativeStackAnchor(Function &F) {
  if (Argument *Arg = findNativeStackArgument(F))
    return Arg;
  if (F.empty())
    return nullptr;
  for (Instruction &I : F.getEntryBlock()) {
    if (!I.getType()->isPointerTy())
      continue;
    StringRef Name = I.getName();
    if (Name.starts_with("frame_storage") ||
        Name.starts_with("native_stack_storage"))
      return &I;
  }
  // A module-level frame backing is used only for a native entry wrapper that
  // has no stack argument.  Prefer an explicitly named owner before using a
  // unique fallback; multiple entry backings otherwise require provenance.
  std::string BackingName = "frame_storage_backing.";
  BackingName += F.getName().str();
  if (GlobalVariable *NamedBacking =
          F.getParent()->getNamedGlobal(BackingName))
    return NamedBacking;
  GlobalVariable *OnlyBacking = nullptr;
  for (GlobalVariable &GV : F.getParent()->globals()) {
    if (!GV.getName().starts_with("frame_storage_backing."))
      continue;
    if (OnlyBacking)
      return nullptr;
    OnlyBacking = &GV;
  }
  return OnlyBacking;
}

static Value *findInitialStateStackInteger(Function &F) {
  if (F.empty())
    return nullptr;
  const DataLayout &DL = F.getParent()->getDataLayout();

  // The entry stack anchor is the value seeded into architectural RSP.  RBP
  // is not an interchangeable baseline: it is commonly zero at the native
  // boundary and is established by the lifted prologue only afterwards.  If
  // an RSP-derived address is rebased against that initial RBP load, the
  // resulting GEP contains the full host pointer as an offset from the local
  // frame (frame + rsp), which is immediately out of bounds.
  //
  // Prefer the explicit RSP seed store.  State-SSA entry lowering deliberately
  // emits this store before the recovered body, while an optimizing pipeline
  // may have no corresponding load left at all.
  for (Instruction &I : F.getEntryBlock()) {
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI || !SI->getValueOperand()->getType()->isIntegerTy(64))
      continue;
    auto *GEP = dyn_cast<GEPOperator>(SI->getPointerOperand());
    if (!GEP)
      continue;
    auto *State = dyn_cast<GlobalVariable>(
        GEP->getPointerOperand()->stripPointerCasts());
    if (!State || !State->getName().contains("__mcsema_reg_state"))
      continue;
    APInt Offset(64, 0);
    if (GEP->accumulateConstantOffset(DL, Offset) && Offset == 2312)
      return SI->getValueOperand();
  }

  // Older inputs can expose the pre-seeded RSP only as a load.  Keep that
  // compatibility path restricted to RSP; choosing the first RSP-or-RBP load
  // made the result depend on instruction order and corrupted valid frames.
  for (Instruction &I : F.getEntryBlock()) {
    auto *LI = dyn_cast<LoadInst>(&I);
    if (!LI || !LI->getType()->isIntegerTy(64))
      continue;
    auto *GEP = dyn_cast<GEPOperator>(LI->getPointerOperand());
    if (!GEP)
      continue;
    auto *State = dyn_cast<GlobalVariable>(
        GEP->getPointerOperand()->stripPointerCasts());
    if (!State || !State->getName().contains("__mcsema_reg_state"))
      continue;
    APInt Offset(64, 0);
    if (GEP->accumulateConstantOffset(DL, Offset) && Offset == 2312)
      return LI;
  }
  return nullptr;
}

static bool isNativeStackPointer(Value *V,
                                 SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  StringRef Name = V->getName();
  if (Name == "native_stack" || Name == "frame_base" ||
      Name.starts_with("native_stack_top") ||
      Name.starts_with("frame_top") ||
      Name.starts_with("native_stack_storage") ||
      Name.starts_with("frame_storage"))
    return true;
  if (auto *GV = dyn_cast<GlobalVariable>(V->stripPointerCasts()))
    return GV->getName().starts_with("frame_storage_backing.");
  if (auto *GEP = dyn_cast<GEPOperator>(V))
    return isNativeStackPointer(GEP->getPointerOperand(), Seen);
  return false;
}

// Relative-stack functions normally carry byte offsets.  A late cleanup can,
// however, encounter an RSP-derived value that was materialized before
// relativization and therefore still contains ptrtoint(frame_top).  Treating
// that absolute carrier as an offset produces frame_top + frame_top + delta.
static bool containsNativeStackAnchorInteger(
    Value *V, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  Value *Pointer = nullptr;
  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    Pointer = PTI->getPointerOperand();
  else if (auto *CE = dyn_cast<ConstantExpr>(V);
           CE && CE->getOpcode() == Instruction::PtrToInt)
    Pointer = CE->getOperand(0);
  if (Pointer) {
    SmallPtrSet<Value *, 8> PointerSeen;
    if (isNativeStackPointer(Pointer, PointerSeen))
      return true;
  }
  if (auto *I = dyn_cast<Instruction>(V)) {
    for (Value *Op : I->operands())
      if (Op->getType()->isIntegerTy() &&
          containsNativeStackAnchorInteger(Op, Seen))
        return true;
  } else if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    for (Value *Op : CE->operands())
      if (Op->getType()->isIntegerTy() &&
          containsNativeStackAnchorInteger(Op, Seen))
        return true;
  }
  return false;
}

static Value *lowerNativeStackInteger(IRBuilder<> &B, Value *Integer,
                                      Function &F) {
  Value *NativeStack = findNativeStackAnchor(F);
  if (!NativeStack || !Integer || !Integer->getType()->isIntegerTy())
    return nullptr;
  SmallPtrSet<Value *, 32> Seen;
  bool HasStackProvenance = containsNativeStackInteger(Integer, Seen);
  bool RelativeStack = F.hasFnAttribute("brighten.relative-stack");
  if (!HasStackProvenance) {
    auto *CI = dyn_cast<ConstantInt>(Integer);
    if (!RelativeStack || !CI || !CI->getValue().isSignedIntN(19))
      return nullptr;
  }
  Value *Address = Integer;
  if (!Address->getType()->isIntegerTy(64))
    Address = B.CreateZExtOrTrunc(Address, B.getInt64Ty(),
                                  "native.stack.address");
  if (RelativeStack) {
    SmallPtrSet<Value *, 32> AnchorSeen;
    if (containsNativeStackAnchorInteger(Address, AnchorSeen)) {
      Value *Anchor = B.CreatePtrToInt(NativeStack, B.getInt64Ty(),
                                       "native.stack.anchor");
      Address = B.CreateSub(Address, Anchor,
                            "native.stack.absolute.delta");
    }
    return B.CreateGEP(B.getInt8Ty(), NativeStack, Address,
                       "native.frame.gep");
  }
  // Entrypoint-native functions without a frame argument still read their
  // initial RSP/RBP from the canonical State global.  Rebase against that
  // entry value, not against the backing object's host address: algebraic
  // folding of `backing + (rsp - backing)` otherwise recreates inttoptr(rsp)
  // and loses the recovered frame provenance before entrypoint seeding.
  if (!findNativeStackArgument(F)) {
    if (Value *InitialStack = findInitialStateStackInteger(F)) {
      Value *FrameTop = NativeStack;
      if (auto *GV = dyn_cast<GlobalVariable>(NativeStack);
          GV && GV->getName().starts_with("frame_storage_backing."))
        FrameTop = B.CreateConstGEP1_64(B.getInt8Ty(), NativeStack,
                                        16 * 1024 * 1024 - 64 * 1024,
                                        "native.stack.top");
      Value *Delta = B.CreateSub(Address, InitialStack,
                                 "native.stack.entry.delta");
      return B.CreateGEP(B.getInt8Ty(), FrameTop, Delta,
                         "native.stack.gep");
    }
  }
  Value *Anchor = B.CreatePtrToInt(NativeStack, B.getInt64Ty(),
                                   "native.stack.anchor");
  Value *Delta = B.CreateSub(Address, Anchor, "native.stack.delta");
  return B.CreateGEP(B.getInt8Ty(), NativeStack, Delta, "native.stack.gep");
}

// O3 can leave an internal RSP/RBP value as a direct inttoptr after the
// translator and external-call rewrites have already run.  Lower only values
// with explicit stack provenance; arbitrary dynamic inttoptr values still
// represent native heap/data/callback pointers and must remain untouched.
static unsigned lowerRawNativeStackIntToPtrs(Module &M, bool &Changed) {
  SmallVector<IntToPtrInst *, 32> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration() || !findNativeStackAnchor(F))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        SmallPtrSet<Value *, 32> Seen;
        if (containsNativeStackInteger(ITP->getOperand(0), Seen))
          Candidates.push_back(ITP);
      }
    }
  }

  unsigned Lowered = 0;
  for (IntToPtrInst *ITP : Candidates) {
    if (!ITP->getParent())
      continue;
    IRBuilder<> B(ITP);
    Value *NativePtr = lowerNativeStackInteger(
        B, ITP->getOperand(0), *ITP->getFunction());
    if (!NativePtr)
      continue;
    if (NativePtr->getType() != ITP->getType())
      NativePtr = B.CreatePointerCast(NativePtr, ITP->getType(),
                                      "native.stack.pointer");
    ITP->replaceAllUsesWith(NativePtr);
    ITP->eraseFromParent();
    ++Lowered;
    Changed = true;
  }
  return Lowered;
}

// The first translator cleanup runs before State-SSA introduces the explicit
// native_stack argument.  Repair the remaining translated GEPs afterwards,
// using the guest range metadata to reconstruct the original integer address.
static unsigned rewriteNativeDataStackGEPs(Module &M, bool &Changed) {
  SmallVector<GetElementPtrInst *, 64> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *GEP = dyn_cast<GetElementPtrInst>(&I);
        if (!GEP || GEP->getNumIndices() != 1)
          continue;
        auto *GV = dyn_cast<GlobalVariable>(
            GEP->getPointerOperand()->stripPointerCasts());
        if (!GV || !GV->getName().starts_with("native_data_"))
          continue;
        if (!isa<IntegerType>(GEP->getSourceElementType()) ||
            !GEP->getSourceElementType()->isIntegerTy(8))
          continue;
        if (isa<ConstantInt>(GEP->getOperand(1)))
          continue;
        Candidates.push_back(GEP);
      }
    }
  }

  unsigned Rewritten = 0;
  for (GetElementPtrInst *GEP : Candidates) {
    auto *GV = dyn_cast<GlobalVariable>(
        GEP->getPointerOperand()->stripPointerCasts());
    if (!GV || !GEP->getParent())
      continue;
    MDNode *Range = GV->getMetadata("brighten.guest.range");
    if (!Range || Range->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    if (!Begin)
      continue;

    IRBuilder<> B(GEP);
    Value *GuestAddress = GEP->getOperand(1);
    if (Begin->getZExtValue() != 0)
      GuestAddress = B.CreateAdd(
          GuestAddress, B.getInt64(Begin->getZExtValue()),
          "native.translated.guest.address");
    Value *NativePtr = lowerNativeStackInteger(
        B, GuestAddress, *GEP->getFunction());
    if (!NativePtr)
      continue;
    GEP->replaceAllUsesWith(NativePtr);
    GEP->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

// Forward declaration: the format-string helpers below share the same
// byte-preserving reader used by recovered segment materialization.
static bool readConstantByte(Constant *C, const DataLayout &DL,
                             uint64_t Offset, uint8_t &Byte);

static std::optional<std::pair<GlobalVariable *, uint64_t>>
resolveConstantGlobalPointer(Value *V, const DataLayout &DL,
                             unsigned Depth = 0) {
  if (!V || Depth > 8)
    return std::nullopt;

  if (auto *GV = dyn_cast<GlobalVariable>(V->stripPointerCasts()))
    return std::make_pair(GV, uint64_t(0));

  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    APInt Offset(DL.getPointerSizeInBits(0), 0, true);
    Value *Base = GEP->stripAndAccumulateConstantOffsets(DL, Offset, true);
    if (!Base || Offset.isNegative())
      return std::nullopt;
    auto Match = resolveConstantGlobalPointer(Base, DL, Depth + 1);
    if (!Match)
      return std::nullopt;
    Match->second += Offset.getZExtValue();
    return Match;
  }

  if (auto *Cast = dyn_cast<CastInst>(V))
    return resolveConstantGlobalPointer(Cast->getOperand(0), DL, Depth + 1);
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->isCast() || CE->getOpcode() == Instruction::GetElementPtr)
      return resolveConstantGlobalPointer(CE->getOperand(0), DL, Depth + 1);
  }
  return std::nullopt;
}

static std::optional<std::string>
readConstantFormatString(Value *Format, const DataLayout &DL) {
  auto Match = resolveConstantGlobalPointer(Format, DL);
  if (!Match || !Match->first->hasInitializer())
    return std::nullopt;

  std::string Result;
  for (uint64_t I = Match->second; I < Match->second + 4096; ++I) {
    uint8_t Byte = 0;
    if (!readConstantByte(Match->first->getInitializer(), DL, I, Byte))
      return std::nullopt;
    if (Byte == 0)
      return Result;
    Result.push_back(static_cast<char>(Byte));
  }
  return std::nullopt;
}

static AllocaInst *getRootAlloca(Value *V) {
  if (!V)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *AI = dyn_cast<AllocaInst>(V))
    return AI;
  if (auto *GEP = dyn_cast<GEPOperator>(V))
    return dyn_cast<AllocaInst>(GEP->getPointerOperand()->stripPointerCasts());
  return nullptr;
}

static std::optional<uint64_t> getConstantGEPByteOffset(Value *Ptr,
                                                         AllocaInst *Root,
                                                         const DataLayout &DL) {
  auto *GEP = dyn_cast<GEPOperator>(Ptr ? Ptr->stripPointerCasts() : nullptr);
  if (!GEP || !Root)
    return std::nullopt;
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = GEP->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (Base != Root || Offset.isNegative())
    return std::nullopt;
  return Offset.getZExtValue();
}

// Return the GP save-area offsets that are pointer arguments for one
// printf/scanf format.  The bridge stores every GP register as i64, so the
// cleanup pass must not translate numeric printf arguments as if they were
// guest addresses.
static void collectFormatPointerSlots(StringRef Format, bool IsScanf,
                                      unsigned FirstVarargOffset,
                                      SmallVectorImpl<unsigned> &Slots) {
  unsigned ArgIndex = 0;
  for (size_t I = 0; I < Format.size();) {
    if (Format[I] != '%') {
      ++I;
      continue;
    }
    ++I;
    if (I >= Format.size())
      break;
    if (Format[I] == '%') {
      ++I;
      continue;
    }

    bool Suppressed = false;
    if (IsScanf && Format[I] == '*') {
      Suppressed = true;
      ++I;
    }

    // printf flags / scanf assignment modifiers.
    while (I < Format.size() &&
           (Format[I] == '-' || Format[I] == '+' || Format[I] == ' ' ||
            Format[I] == '#' || Format[I] == '0' || Format[I] == '\''))
      ++I;

    if (I < Format.size() && Format[I] == '*') {
      ++ArgIndex;
      ++I;
    } else {
      while (I < Format.size() && Format[I] >= '0' && Format[I] <= '9')
        ++I;
    }

    if (!IsScanf && I < Format.size() && Format[I] == '.') {
      ++I;
      if (I < Format.size() && Format[I] == '*') {
        ++ArgIndex;
        ++I;
      } else {
        while (I < Format.size() && Format[I] >= '0' && Format[I] <= '9')
          ++I;
      }
    }

    while (I < Format.size() &&
           (Format[I] == 'h' || Format[I] == 'l' || Format[I] == 'j' ||
            Format[I] == 'z' || Format[I] == 't' || Format[I] == 'L' ||
            Format[I] == 'q'))
      ++I;
    if (I >= Format.size())
      break;

    char Conversion = Format[I++];
    bool TakesArgument = IsScanf || Conversion != 'm';
    if (!TakesArgument)
      continue;
    if (!Suppressed) {
      bool IsPointer = IsScanf || Conversion == 's' || Conversion == 'p' ||
                       Conversion == 'n';
      if (IsPointer)
        Slots.push_back(FirstVarargOffset + ArgIndex * 8);
      ++ArgIndex;
    }
  }
}

static std::optional<std::pair<GlobalVariable *, uint64_t>>
FindRecoveredGlobalForGuestAddress(Module &M, uint64_t Address) {
  // Prefer byte-preserving full-segment copies over a small recovered object:
  // dynamic guest indices may legally move beyond the object boundary even
  // when the original constant base was also used to recover a scalar/array.
  for (GlobalVariable &GV : M.globals()) {
    if (!GV.getName().starts_with("native_data_"))
      continue;
    MDNode *Range = GV.getMetadata("brighten.guest.range");
    if (!Range || Range->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *EndMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(1));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    auto *End = EndMD ? dyn_cast<ConstantInt>(EndMD->getValue()) : nullptr;
    if (!Begin || !End)
      continue;
    uint64_t GuestBegin = Begin->getZExtValue();
    uint64_t GuestEnd = End->getZExtValue();
    if (Address >= GuestBegin && Address < GuestEnd)
      return std::make_pair(&GV, Address - GuestBegin);
  }
  for (GlobalVariable &GV : M.globals()) {
    MDNode *Range = GV.getMetadata("brighten.guest.range");
    if (!Range || Range->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *EndMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(1));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    auto *End = EndMD ? dyn_cast<ConstantInt>(EndMD->getValue()) : nullptr;
    if (!Begin || !End)
      continue;
    uint64_t GuestBegin = Begin->getZExtValue();
    uint64_t GuestEnd = End->getZExtValue();
    if (Address >= GuestBegin && Address < GuestEnd)
      return std::make_pair(&GV, Address - GuestBegin);
  }
  return std::nullopt;
}

static std::optional<std::pair<GlobalVariable *, uint64_t>>
FindNativeSegmentForGuestRange(Module &M, uint64_t Begin, uint64_t End) {
  for (GlobalVariable &GV : M.globals()) {
    if (!GV.getName().starts_with("native_data_"))
      continue;
    MDNode *Range = GV.getMetadata("brighten.guest.range");
    if (!Range || Range->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *EndMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(1));
    auto *SegmentBegin =
        BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    auto *SegmentEnd =
        EndMD ? dyn_cast<ConstantInt>(EndMD->getValue()) : nullptr;
    if (!SegmentBegin || !SegmentEnd)
      continue;
    uint64_t GuestBegin = SegmentBegin->getZExtValue();
    uint64_t GuestEnd = SegmentEnd->getZExtValue();
    if (Begin >= GuestBegin && End <= GuestEnd)
      return std::make_pair(&GV, Begin - GuestBegin);
  }
  return std::nullopt;
}

// A recovered object and the byte-preserving native segment must not become
// two different host allocations for the same guest address range.  This is
// especially important when a fixed access uses the recovered object while a
// dynamic access uses the full segment (e.g. the p00009 scanf/primes case).
static unsigned rewriteRecoveredGlobalsToNativeSegments(Module &M,
                                                         bool &Changed) {
  SmallVector<std::pair<GlobalVariable *, GlobalVariable *>, 32> Replacements;
  SmallVector<std::pair<GlobalVariable *, uint64_t>, 32> Offsets;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.getName().starts_with("native_data_") || GV.isDeclaration())
      continue;
    MDNode *Range = GV.getMetadata("brighten.guest.range");
    if (!Range || Range->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *EndMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(1));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    auto *End = EndMD ? dyn_cast<ConstantInt>(EndMD->getValue()) : nullptr;
    if (!Begin || !End)
      continue;
    uint64_t GuestBegin = Begin->getZExtValue();
    uint64_t GuestEnd = End->getZExtValue();
    auto Match = FindNativeSegmentForGuestRange(M, GuestBegin, GuestEnd);
    if (!Match)
      continue;
    Replacements.emplace_back(&GV, Match->first);
    Offsets.emplace_back(Match->first, Match->second);
  }

  unsigned Rewritten = 0;
  for (size_t I = 0; I < Replacements.size(); ++I) {
    GlobalVariable *Old = Replacements[I].first;
    GlobalVariable *NativeData = Replacements[I].second;
    IRBuilder<> B(M.getContext());
    Constant *Offset = B.getInt64(Offsets[I].second);
    Constant *NativePtr = ConstantExpr::getGetElementPtr(
        B.getInt8Ty(), NativeData, {Offset});
    Old->replaceAllUsesWith(NativePtr);
    if (Old->use_empty()) {
      Old->eraseFromParent();
      ++Rewritten;
      Changed = true;
    }
  }
  return Rewritten;
}

static unsigned inlineGuestPointerTranslators(Module &M, bool &Changed) {
  unsigned Inlined = 0;
  for (;;) {
    Function *Translator = M.getFunction("__translate_guest_pointer");
    if (!Translator || Translator->isDeclaration())
      break;
    SmallVector<CallInst *, 64> Calls;
    for (Function &F : M) {
      if (&F == Translator || F.isDeclaration())
        continue;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          auto *CI = dyn_cast<CallInst>(&I);
          if (CI && CI->getCalledFunction() == Translator)
            Calls.push_back(CI);
        }
      }
    }
    if (Calls.empty())
      break;
    for (CallInst *CI : Calls) {
      InlineFunctionInfo IFI;
      InlineResult Result = InlineFunction(*CI, IFI);
      if (Result.isSuccess()) {
        ++Inlined;
        Changed = true;
      }
    }
  }
  return Inlined;
}

static unsigned rewriteRemainingDataAliasesToNativeSegments(Module &M,
                                                            bool &Changed) {
  SmallVector<std::pair<GlobalAlias *, GlobalVariable *>, 32> Replacements;
  SmallVector<uint64_t, 32> Offsets;
  for (GlobalAlias &GA : M.aliases()) {
    StringRef Name = GA.getName();
    if (!Name.starts_with("data_"))
      continue;
    uint64_t GuestAddress = 0;
    if (Name.drop_front(StringRef("data_").size()).getAsInteger(16,
                                                                  GuestAddress))
      continue;
    auto Match = FindRecoveredGlobalForGuestAddress(M, GuestAddress);
    if (Match) {
      Replacements.emplace_back(&GA, Match->first);
      Offsets.push_back(Match->second);
      continue;
    }

    // Some late aliases share storage with dynamic guest-pointer accesses
    // that still address the residual segment.  They must remain one host
    // allocation: copying an alias suffix makes libc write one object while
    // dynamic code reads another.  Remove the lifted alias but retain and
    // canonicalize that single residual allocation as native storage.
    auto *GEP = dyn_cast<GEPOperator>(GA.getAliasee());
    if (!GEP)
      continue;
    auto *Segment = dyn_cast<GlobalVariable>(
        GEP->getOperand(0)->stripPointerCasts());
    if (!Segment ||
        (!Segment->getName().starts_with("seg_") &&
         !Segment->getName().starts_with("native_residual_")))
      continue;
    APInt ByteOffset(M.getDataLayout().getIndexSizeInBits(0), 0);
    if (!GEP->accumulateConstantOffset(M.getDataLayout(), ByteOffset))
      continue;
    if (Segment->getName().starts_with("seg_")) {
      std::string NativeName =
          ("native_residual_" + Segment->getName().drop_front(4)).str();
      Segment->setName(NativeName);
    }
    Replacements.emplace_back(&GA, Segment);
    Offsets.push_back(ByteOffset.getZExtValue());
  }

  unsigned Rewritten = 0;
  for (size_t I = 0; I < Replacements.size(); ++I) {
    GlobalAlias *Alias = Replacements[I].first;
    GlobalVariable *NativeData = Replacements[I].second;
    LLVMContext &Ctx = M.getContext();
    Constant *Offset = ConstantInt::get(Type::getInt64Ty(Ctx), Offsets[I]);
    Constant *NativePtr = ConstantExpr::getGetElementPtr(
        Type::getInt8Ty(Ctx), NativeData, {Offset});
    Alias->replaceAllUsesWith(NativePtr);
    if (Alias->use_empty()) {
      Alias->eraseFromParent();
      ++Rewritten;
      Changed = true;
    }
  }
  return Rewritten;
}

// State/ABI lowering can recreate a constant guest pointer as a ConstantExpr
// after global-data recovery has already consumed the original alias.  Keep
// the final native gate honest by rebasing such operands through the recovered
// object's guest-range metadata instead of leaving a fixed guest address in
// the output module.
static unsigned rewriteConstantGuestPointerOperands(Module &M,
                                                    bool &Changed) {
  struct Pending {
    Instruction *I;
    unsigned OperandNo;
    ConstantExpr *Expr;
    GlobalVariable *GV;
    uint64_t Offset;
  };
  SmallVector<Pending, 32> Work;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo) {
          auto *CE = dyn_cast<ConstantExpr>(I.getOperand(OpNo));
          if (!CE || CE->getOpcode() != Instruction::IntToPtr)
            continue;
          auto *Addr = dyn_cast<ConstantInt>(CE->getOperand(0));
          if (!Addr)
            continue;
          auto Match = FindRecoveredGlobalForGuestAddress(
              M, Addr->getZExtValue());
          if (!Match)
            continue;
          Work.push_back({&I, OpNo, CE, Match->first, Match->second});
        }
      }
    }
  }

  unsigned Rewritten = 0;
  LLVMContext &Ctx = M.getContext();
  for (const Pending &P : Work) {
    Constant *NativePtr = ConstantExpr::getGetElementPtr(
        Type::getInt8Ty(Ctx), P.GV,
        {ConstantInt::get(Type::getInt64Ty(Ctx), P.Offset)});
    if (NativePtr->getType() != P.Expr->getType())
      NativePtr = ConstantExpr::getPointerCast(NativePtr, P.Expr->getType());
    P.I->setOperand(P.OperandNo, NativePtr);
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

// A RIP carrier can survive as a constant data alias even after every real
// code/data use has disappeared.  Preserve the incoming RIP slot value in
// that dead carrier instead of manufacturing zero or retaining an ELF
// segment blob.  The rewrite is intentionally narrow: every alias use must
// be a ptrtoint feeding a PHI named for state slot 2472 (RIP).
static unsigned rewriteDeadRIPDataAliases(Module &M, bool &Changed) {
  SmallVector<GlobalAlias *, 8> Candidates;
  for (GlobalAlias &GA : M.aliases()) {
    if (!GA.getName().starts_with("data_") || GA.use_empty())
      continue;
    bool Eligible = true;
    bool Found = false;
    SmallVector<std::pair<ConstantExpr *, Argument *>, 8> Replacements;
    for (User *U : GA.users()) {
      auto *CE = dyn_cast<ConstantExpr>(U);
      if (!CE || CE->getOpcode() != Instruction::PtrToInt ||
          !CE->getType()->isIntegerTy(64)) {
        Eligible = false;
        break;
      }
      for (User *CEUser : CE->users()) {
        auto *PN = dyn_cast<PHINode>(CEUser);
        if (!PN || !PN->getName().starts_with("state_2472")) {
          Eligible = false;
          break;
        }
        Argument *IncomingRIP = nullptr;
        for (Argument &Arg : PN->getFunction()->args()) {
          if (Arg.getName() == "state_in_2472") {
            IncomingRIP = &Arg;
            break;
          }
        }
        if (!IncomingRIP) {
          Eligible = false;
          break;
        }
        Replacements.emplace_back(CE, IncomingRIP);
        Found = true;
      }
      if (!Eligible)
        break;
    }
    if (!Eligible || !Found)
      continue;
    for (auto [CE, IncomingRIP] : Replacements) {
      SmallVector<User *, 8> Users;
      for (User *CEUser : CE->users())
        Users.push_back(CEUser);
      for (User *CEUser : Users)
        CEUser->replaceUsesOfWith(CE, IncomingRIP);
    }
    if (GA.use_empty())
      Candidates.push_back(&GA);
  }

  for (GlobalAlias *GA : Candidates) {
    GA->eraseFromParent();
    Changed = true;
  }
  return Candidates.size();
}

// McSema can encode a flattened-state integer as ptrtoint(data_<addr>) when
// the number happens to lie in a broad BSS segment.  At PHI/select/arithmetic
// identity carriers that is a guest numeric value, not a native pointer.  Do
// not rebase it through a recovered object: replace it with the original guest
// integer so the old alias and segment can disappear without changing control
// flow under ASLR.
static unsigned rewriteGuestAddressIdentityAliasIntegers(Module &M,
                                                         bool &Changed) {
  unsigned Rewritten = 0;
  for (GlobalAlias &GA : M.aliases()) {
    if (!GA.getName().starts_with("data_"))
      continue;
    uint64_t GuestAddress = 0;
    if (GA.getName().drop_front(StringRef("data_").size())
            .getAsInteger(16, GuestAddress))
      continue;

    SmallVector<ConstantExpr *, 8> AliasIntegers;
    for (User *AliasUser : GA.users()) {
      auto *CE = dyn_cast<ConstantExpr>(AliasUser);
      if (CE && CE->getOpcode() == Instruction::PtrToInt &&
          CE->getType()->isIntegerTy())
        AliasIntegers.push_back(CE);
    }

    for (ConstantExpr *AliasInteger : AliasIntegers) {
      auto FeedsPointerMaterialization = [](Value *Root) {
        SmallVector<Value *, 16> Pending{Root};
        SmallPtrSet<Value *, 32> Seen;
        while (!Pending.empty()) {
          Value *V = Pending.pop_back_val();
          if (!Seen.insert(V).second)
            continue;
          for (User *U : V->users()) {
            // Integer pointer carriers commonly cross a recovered ABI call
            // boundary and are converted back to pointers in the callee.
            // Without interprocedural proof, treating such an argument as a
            // numeric identity leaks fixed guest addresses into PIE code.
            if (isa<CallBase>(U))
              return true;
            if (isa<IntToPtrInst>(U))
              return true;
            if (auto *CE = dyn_cast<ConstantExpr>(U)) {
              if (CE->getOpcode() == Instruction::IntToPtr)
                return true;
              if (CE->getType()->isIntegerTy())
                Pending.push_back(CE);
              continue;
            }
            if (isa<BinaryOperator>(U) || isa<PHINode>(U) ||
                isa<SelectInst>(U) || isa<CastInst>(U))
              Pending.push_back(cast<Value>(U));
          }
        }
        return false;
      };
      if (FeedsPointerMaterialization(AliasInteger))
        continue;
      SmallVector<Instruction *, 8> IdentityInstructions;
      bool AllUsesAreIdentity = true;
      for (User *Consumer : AliasInteger->users()) {
        bool IsIdentityCarrier = isa<PHINode>(Consumer) ||
                                 isa<SelectInst>(Consumer) ||
                                 isa<BinaryOperator>(Consumer) ||
                                 isa<ICmpInst>(Consumer) ||
                                 isa<SwitchInst>(Consumer);
        if (auto *Nested = dyn_cast<ConstantExpr>(Consumer)) {
          IsIdentityCarrier = Nested->getType()->isIntegerTy() ||
                              Nested->getOpcode() ==
                                  Instruction::GetElementPtr;
        }
        if (!IsIdentityCarrier) {
          AllUsesAreIdentity = false;
          continue;
        }
        if (auto *I = dyn_cast<Instruction>(Consumer))
          IdentityInstructions.push_back(I);
      }

      Constant *GuestConstant =
          ConstantInt::get(AliasInteger->getType(), GuestAddress);
      if (AllUsesAreIdentity) {
        unsigned Uses = AliasInteger->getNumUses();
        AliasInteger->replaceAllUsesWith(GuestConstant);
        Rewritten += Uses;
        Changed |= Uses != 0;
        continue;
      }
      // Never mutate a ConstantExpr consumer in place: constants are uniqued
      // by LLVM and partial operand replacement can corrupt the constant-use
      // graph.  Mixed-use aliases are rewritten only at instruction users.
      for (Instruction *Consumer : IdentityInstructions) {
        Consumer->replaceUsesOfWith(AliasInteger, GuestConstant);
        ++Rewritten;
        Changed = true;
      }
    }
  }
  return Rewritten;
}

struct GuestAddressExpression {
  GlobalVariable *Segment = nullptr;
  uint64_t SegmentOffset = 0;
  Value *DynamicOffset = nullptr;
};

// Recover the guest address represented by a constant pointer expression
// after global-data recovery has materialized the backing object.  LLVM keeps
// ptrtoint(@recovered_object) as a ConstantExpr in some pipelines, while
// other optimization orders fold the same provenance to ConstantInt.  The
// dynamic-address matcher must understand both forms; otherwise an otherwise
// valid recovered object is discarded before it can be used to rebase an
// inttoptr.
static std::optional<uint64_t>
findConstantRecoveredGuestAddress(Module &M, Value *V, unsigned Depth = 0) {
  if (!V || Depth > 8)
    return std::nullopt;
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return CI->getZExtValue();

  if (auto *GV = dyn_cast<GlobalVariable>(V->stripPointerCasts())) {
    MDNode *Range = GV->getMetadata("brighten.guest.range");
    if (!Range || Range->getNumOperands() != 2)
      return std::nullopt;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    if (Begin)
      return Begin->getZExtValue();
    return std::nullopt;
  }

  if (auto *GA = dyn_cast<GlobalAlias>(V->stripPointerCasts())) {
    StringRef Name = GA->getName();
    if (Name.starts_with("data_")) {
      uint64_t Address = 0;
      if (!Name.drop_front(StringRef("data_").size())
               .getAsInteger(16, Address))
        return Address;
    }
    return findConstantRecoveredGuestAddress(M, GA->getAliasee(), Depth + 1);
  }

  auto *CE = dyn_cast<ConstantExpr>(V);
  if (!CE)
    return std::nullopt;
  if (CE->isCast() || CE->getOpcode() == Instruction::PtrToInt)
    return findConstantRecoveredGuestAddress(M, CE->getOperand(0), Depth + 1);
  if (CE->getOpcode() != Instruction::GetElementPtr)
    return std::nullopt;

  auto Base = findConstantRecoveredGuestAddress(M, CE->getOperand(0),
                                                Depth + 1);
  if (!Base)
    return std::nullopt;
  auto *GEP = cast<GEPOperator>(CE);
  APInt Offset(M.getDataLayout().getPointerSizeInBits(0), 0, true);
  if (!GEP->accumulateConstantOffset(M.getDataLayout(), Offset) ||
      Offset.isNegative())
    return std::nullopt;
  return *Base + Offset.getZExtValue();
}

// Recover a guest-base-plus-dynamic-offset expression even when the lifted
// arithmetic is split across several SSA adds.  This is deliberately limited
// to integer add/cast trees and a constant known to fall inside a recovered
// segment; ordinary native integers cannot satisfy that condition.
static std::optional<GuestAddressExpression>
findGuestAddressExpression(Module &M, Value *V, IRBuilder<> &B,
                           unsigned Depth = 0) {
  if (!V || Depth > 8)
    return std::nullopt;
  if (auto *Cast = dyn_cast<CastInst>(V))
    return findGuestAddressExpression(M, Cast->getOperand(0), B, Depth + 1);

  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || BO->getOpcode() != Instruction::Add ||
      !BO->getType()->isIntegerTy())
    return std::nullopt;

  auto MakeDirect = [&](Value *ConstantSide,
                        Value *DynamicSide)
      -> std::optional<GuestAddressExpression> {
    auto GuestAddress = findConstantRecoveredGuestAddress(M, ConstantSide);
    if (!GuestAddress)
      return std::nullopt;
    auto Match = FindRecoveredGlobalForGuestAddress(M, *GuestAddress);
    if (!Match)
      return std::nullopt;
    return GuestAddressExpression{Match->first, Match->second, DynamicSide};
  };

  if (auto Direct = MakeDirect(BO->getOperand(0), BO->getOperand(1)))
    return Direct;
  if (auto Direct = MakeDirect(BO->getOperand(1), BO->getOperand(0)))
    return Direct;

  auto Left = findGuestAddressExpression(M, BO->getOperand(0), B, Depth + 1);
  auto Right = findGuestAddressExpression(M, BO->getOperand(1), B, Depth + 1);
  if (Left && !Right) {
    Value *Extra = BO->getOperand(1);
    Left->DynamicOffset = B.CreateAdd(Left->DynamicOffset, Extra,
                                      "native.scanf.address.offset");
    return Left;
  }
  if (Right && !Left) {
    Value *Extra = BO->getOperand(0);
    Right->DynamicOffset = B.CreateAdd(Right->DynamicOffset, Extra,
                                       "native.scanf.address.offset");
    return Right;
  }
  return std::nullopt;
}

static unsigned rewriteNativeScanfVarargAddresses(Module &M,
                                                   bool &Changed) {
  SmallVector<StoreInst *, 64> Stores;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<StoreInst>(&I);
        if (!SI || !IsNativeVarargSaveSlot(SI->getPointerOperand()))
          continue;
        Stores.push_back(SI);
      }
    }
  }

  unsigned Rewritten = 0;
  for (StoreInst *SI : Stores) {
    // The address is often materialized in a separate SSA instruction, e.g.
    //   %idx = mul i64 %n, 44
    //   %addr = add i64 %idx, 0x405de8
    //   store i64 %addr, %reg_save_area+8
    // so inspect the stored SSA value itself rather than requiring the store
    // operand to be a BinaryOperator.
    IRBuilder<> B(SI);
    auto Address = findGuestAddressExpression(M, SI->getValueOperand(), B);
    if (!Address || !Address->Segment || !Address->DynamicOffset)
      continue;
    Value *Offset = Address->DynamicOffset;
    if (Address->SegmentOffset != 0)
      Offset = B.CreateAdd(Offset, B.getInt64(Address->SegmentOffset),
                           "native.vararg.offset");
    if (!Offset->getType()->isIntegerTy(64))
      Offset = B.CreateZExtOrTrunc(Offset, B.getInt64Ty(),
                                   "native.vararg.offset.ext");
    Value *NativePtr = B.CreateGEP(B.getInt8Ty(), Address->Segment, Offset,
                                   "native.vararg.ptr");
    Value *NativeAddr = B.CreatePtrToInt(NativePtr,
                                         SI->getValueOperand()->getType(),
                                         "native.vararg.addr");
    SI->setOperand(0, NativeAddr);
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

// Some lifted memory operations keep the guest address arithmetic intact
// until after the State ABI has been lowered.  In particular, array accesses
// such as guest_base + index * element_size become an inttoptr of an add
// instruction rather than a scanf save-slot store.  Leaving those pointers
// as guest virtual addresses makes the native binary dereference unmapped
// addresses (or, worse, a different host mapping).  Rewrite only expressions
// whose addend is proven to lie in a recovered guest segment; native heap and
// native-stack pointer arithmetic does not match this rule.
static unsigned rewriteDynamicGuestAddressIntToPtr(Module &M,
                                                     bool &Changed) {
  SmallVector<IntToPtrInst *, 128> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        Candidates.push_back(ITP);
      }
    }
  }

  unsigned Rewritten = 0;
  for (IntToPtrInst *ITP : Candidates) {
    if (!ITP->getParent())
      continue;

    IRBuilder<> B(ITP);
    auto Address = findGuestAddressExpression(M, ITP->getOperand(0), B);
    if (!Address || !Address->Segment || !Address->DynamicOffset)
      continue;

    Value *Offset = Address->DynamicOffset;
    if (!Offset->getType()->isIntegerTy(64))
      Offset = B.CreateZExtOrTrunc(Offset, B.getInt64Ty(),
                                  "native.guest.offset.ext");
    if (Address->SegmentOffset != 0)
      Offset = B.CreateAdd(Offset, B.getInt64(Address->SegmentOffset),
                          "native.guest.offset");
    Value *NativePtr = B.CreateGEP(B.getInt8Ty(), Address->Segment, Offset,
                                   "native.guest.ptr");
    if (NativePtr->getType() != ITP->getType())
      NativePtr = B.CreatePointerCast(NativePtr, ITP->getType(),
                                      "native.guest.ptr.cast");
    ITP->replaceAllUsesWith(NativePtr);
    ITP->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

// The external-call bridge runs before global recovery and therefore may
// leave an integer-typed libc argument as `guest_base + dynamic_index` after
// the translator call has been simplified away.  At that point the argument
// is still an integer because McSema's declaration uses i64 for pointers.
// Repair the call operand directly once the recovered segment metadata is
// available.  This covers the common memcmp/strcmp family without touching
// ordinary native heap or stack integers.
static bool isRecoveredPointerExternalArgument(StringRef Name,
                                               unsigned Index) {
  // McSema lowers variadic arguments to the same i64 carrier.  For printf
  // and scanf the format string determines whether a value is numeric or a
  // pointer; passing a native fallback through the mapper is value-preserving
  // for numeric integers and fixes the %s / %p / scanf pointer cases.
  if (Name == "printf" || Name == "__isoc99_scanf" || Name == "scanf")
    return true;
  if (Name == "free" || Name == "puts" || Name == "printf" ||
      Name == "__isoc99_scanf" || Name == "scanf" || Name == "strlen" ||
      Name == "strcmp" || Name == "strncmp" || Name == "strcpy" ||
      Name == "strncpy" || Name == "strcat" || Name == "strncat" ||
      Name == "strstr" || Name == "strchr" || Name == "strrchr" ||
      Name == "memcpy" || Name == "memmove" || Name == "memcmp")
    return Index < 2;
  if (Name == "memset")
    return Index == 0;
  if (Name == "fgets")
    return Index == 0 || Index == 2;
  if (Name == "fread" || Name == "fwrite")
    return Index == 0 || Index == 3;
  if (Name == "realloc")
    return Index == 0;
  return false;
}

static Function *getOrCreateRecoveredDataPointerMapper(Module &M) {
  if (Function *Existing = M.getFunction("__brighten_native_data_pointer"))
    return Existing;

  struct Range {
    GlobalVariable *GV;
    uint64_t Begin;
    uint64_t End;
  };
  SmallVector<Range, 16> Ranges;
  for (GlobalVariable &GV : M.globals()) {
    MDNode *RangeMD = GV.getMetadata("brighten.guest.range");
    if (!RangeMD || RangeMD->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(RangeMD->getOperand(0));
    auto *EndMD = dyn_cast<ConstantAsMetadata>(RangeMD->getOperand(1));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    auto *End = EndMD ? dyn_cast<ConstantInt>(EndMD->getValue()) : nullptr;
    if (!Begin || !End)
      continue;
    bool Duplicate = false;
    for (const Range &R : Ranges)
      Duplicate |= R.Begin == Begin->getZExtValue() &&
                   R.End == End->getZExtValue();
    if (!Duplicate)
      Ranges.push_back({&GV, Begin->getZExtValue(), End->getZExtValue()});
  }
  if (Ranges.empty())
    return nullptr;

  LLVMContext &Ctx = M.getContext();
  Type *I64 = Type::getInt64Ty(Ctx);
  Type *PtrTy = PointerType::getUnqual(Ctx);
  Function *Mapper = Function::Create(
      FunctionType::get(PtrTy, {I64}, false), GlobalValue::InternalLinkage,
      "__brighten_native_data_pointer", M);
  Mapper->setDSOLocal(true);
  Argument *Address = Mapper->getArg(0);
  Address->setName("guest_or_native_address");
  BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", Mapper);
  IRBuilder<> EntryBuilder(Entry);
  BasicBlock *Current = Entry;
  for (size_t I = 0; I < Ranges.size(); ++I) {
    BasicBlock *Hit = BasicBlock::Create(Ctx, "data.hit", Mapper);
    BasicBlock *Next = BasicBlock::Create(Ctx, "data.next", Mapper);
    IRBuilder<> B(Current);
    Value *AtOrAfter = B.CreateICmpUGE(Address, B.getInt64(Ranges[I].Begin));
    Value *BeforeEnd = B.CreateICmpULT(Address, B.getInt64(Ranges[I].End));
    Value *InRange = B.CreateAnd(AtOrAfter, BeforeEnd);
    B.CreateCondBr(InRange, Hit, Next);

    IRBuilder<> HitBuilder(Hit);
    Value *Offset = HitBuilder.CreateSub(Address, HitBuilder.getInt64(Ranges[I].Begin));
    Value *NativePtr = HitBuilder.CreateGEP(
        HitBuilder.getInt8Ty(), Ranges[I].GV, Offset, "native.data.dynamic.ptr");
    HitBuilder.CreateRet(NativePtr);
    Current = Next;
  }
  IRBuilder<> Fallback(Current);
  Fallback.CreateRet(Fallback.CreateIntToPtr(Address, PtrTy,
                                              "native.address.fallback"));
  return Mapper;
}

// Lower a guest-address integer at the use site.  Keeping the range dispatch
// inline avoids introducing a native helper whose only purpose is to translate
// the old guest address space; the final IR then contains ordinary native GEPs
// and a dynamic native-pointer fallback for values that are already native.
static Value *materializeRecoveredDataPointer(Module &M, IRBuilder<> &B,
                                              Value *Address) {
  if (!Address || !Address->getType()->isIntegerTy())
    return nullptr;

  LLVMContext &Ctx = M.getContext();
  Type *I64 = Type::getInt64Ty(Ctx);
  Value *Address64 = Address;
  if (Address64->getType() != I64)
    Address64 = B.CreateZExtOrTrunc(Address64, I64, "native.data.address");

  struct Range {
    GlobalVariable *GV;
    uint64_t Begin;
    uint64_t End;
  };
  SmallVector<Range, 16> Ranges;
  for (GlobalVariable &GV : M.globals()) {
    MDNode *RangeMD = GV.getMetadata("brighten.guest.range");
    if (!RangeMD || RangeMD->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(RangeMD->getOperand(0));
    auto *EndMD = dyn_cast<ConstantAsMetadata>(RangeMD->getOperand(1));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue())
                          : nullptr;
    auto *End = EndMD ? dyn_cast<ConstantInt>(EndMD->getValue()) : nullptr;
    if (!Begin || !End || Begin->getZExtValue() >= End->getZExtValue())
      continue;
    Ranges.push_back({&GV, Begin->getZExtValue(), End->getZExtValue()});
  }
  if (Ranges.empty())
    return B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                            "native.address.fallback");

  Value *Result = B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                                   "native.address.fallback");
  for (auto It = Ranges.rbegin(); It != Ranges.rend(); ++It) {
    Value *AtOrAfter = B.CreateICmpUGE(Address64, B.getInt64(It->Begin));
    Value *BeforeEnd = B.CreateICmpULT(Address64, B.getInt64(It->End));
    Value *InRange = B.CreateAnd(AtOrAfter, BeforeEnd);
    Value *Offset = B.CreateSub(Address64, B.getInt64(It->Begin));
    Value *NativePtr = B.CreateGEP(B.getInt8Ty(), It->GV, Offset,
                                   "native.data.dynamic.ptr");
    Result = B.CreateSelect(InRange, NativePtr, Result,
                            "native.data.pointer.select");
  }
  return Result;
}

// Frame lowering preserves the contents of a guest stack slot, but that slot
// can itself hold a guest BSS pointer.  The later load then becomes an
// inttoptr whose operand has no remaining constant-expression provenance, so
// rewriteDynamicGuestAddressIntToPtr cannot recognize it.  Resolve every
// residual generic-pointer conversion against the recovered ranges after the
// stack-specific rewrite has run.  Native addresses retain their original
// behavior through materializeRecoveredDataPointer's fallback arm.
static unsigned rewriteResidualRecoveredDataIntToPtrs(Module &M,
                                                       bool &Changed) {
  bool HasRanges = false;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.getMetadata("brighten.guest.range")) {
      HasRanges = true;
      break;
    }
  }
  if (!HasRanges)
    return 0;

  SmallVector<IntToPtrInst *, 128> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy() ||
            ITP->getType()->getPointerAddressSpace() != 0 ||
            ITP->getName().starts_with("native.address.fallback"))
          continue;
        Candidates.push_back(ITP);
      }
    }
  }

  unsigned Rewritten = 0;
  for (IntToPtrInst *ITP : Candidates) {
    if (!ITP->getParent())
      continue;
    IRBuilder<> B(ITP);
    Value *NativePtr =
        materializeRecoveredDataPointer(M, B, ITP->getOperand(0));
    if (!NativePtr)
      continue;
    if (NativePtr->getType() != ITP->getType())
      NativePtr = B.CreatePointerCast(NativePtr, ITP->getType(),
                                      "native.residual.ptr.cast");
    ITP->replaceAllUsesWith(NativePtr);
    ITP->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

static unsigned rewriteRecoveredExternalPointerArguments(Module &M,
                                                          bool &Changed) {
  unsigned Rewritten = 0;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!CB || !Callee || !Callee->isDeclaration())
          continue;
        StringRef Name = Callee->getName();
        for (unsigned Index = 0; Index < CB->arg_size(); ++Index) {
          if (!isRecoveredPointerExternalArgument(Name, Index))
            continue;
          Value *Arg = CB->getArgOperand(Index);
          IRBuilder<> B(CB);
          if (Arg->getType()->isPointerTy()) {
            Value *GuestAddress = nullptr;
            if (auto *ITP = dyn_cast<IntToPtrInst>(Arg))
              GuestAddress = ITP->getOperand(0);
            else if (auto *CE = dyn_cast<ConstantExpr>(Arg)) {
              if (CE->getOpcode() == Instruction::IntToPtr)
                GuestAddress = CE->getOperand(0);
            }
            if (!GuestAddress || !GuestAddress->getType()->isIntegerTy())
              continue;
            Value *NativePtr = lowerNativeStackInteger(
                B, GuestAddress, *CB->getFunction());
            if (!NativePtr)
              NativePtr = materializeRecoveredDataPointer(M, B, GuestAddress);
            if (!NativePtr)
              continue;
            CB->setArgOperand(Index, NativePtr);
            ++Rewritten;
            Changed = true;
            continue;
          }
          if (!Arg->getType()->isIntegerTy())
            continue;
          // A recovered string/global already has a real native address.  It
          // is commonly carried through McSema's integer pointer carrier as
          // ptrtoint(native_object); sending it through the guest-range
          // mapper would needlessly resurrect every temporary segment copy.
          if (auto *PTI = dyn_cast<PtrToIntInst>(Arg)) {
            SmallPtrSet<Value *, 16> Seen;
            if (isNativePointerValue(PTI->getPointerOperand(), Seen))
              continue;
          } else if (auto *CE = dyn_cast<ConstantExpr>(Arg)) {
            if (CE->getOpcode() == Instruction::PtrToInt) {
              SmallPtrSet<Value *, 16> Seen;
              if (isNativePointerValue(CE->getOperand(0), Seen))
                continue;
            }
          }
          Value *NativePtr = lowerNativeStackInteger(
              B, Arg, *CB->getFunction());
          if (!NativePtr)
            NativePtr = materializeRecoveredDataPointer(M, B, Arg);
          if (!NativePtr)
            continue;
          Value *NativeAddr = B.CreatePtrToInt(
              NativePtr, Arg->getType(), "native.external.addr");
          CB->setArgOperand(Index, NativeAddr);
          ++Rewritten;
          Changed = true;
        }
      }
    }
  }
  return Rewritten;
}

static unsigned rewriteRecoveredVarargSaveSlots(Module &M, bool &Changed) {
  struct FormatRule {
    AllocaInst *RegSaveArea = nullptr;
    SmallVector<unsigned, 8> PointerOffsets;
  };

  const DataLayout &DL = M.getDataLayout();
  SmallVector<FormatRule, 32> Rules;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!CB || !Callee || CB->arg_empty())
          continue;
        StringRef Name = Callee->getName();
        bool IsScanf = Name == "vscanf" || Name == "vfscanf" ||
                       Name == "vsscanf";
        bool IsPrintf = Name == "vprintf" || Name == "vfprintf" ||
                        Name == "vsprintf" || Name == "vsnprintf";
        if (!IsScanf && !IsPrintf)
          continue;

        unsigned FormatIndex = 0;
        unsigned FixedArguments = 1;
        if (Name == "vfprintf" || Name == "vfscanf") {
          FormatIndex = 1;
          FixedArguments = 2;
        } else if (Name == "vsprintf" || Name == "vsscanf") {
          FormatIndex = 1;
          FixedArguments = 2;
        } else if (Name == "vsnprintf") {
          FormatIndex = 2;
          FixedArguments = 3;
        }
        if (FormatIndex >= CB->arg_size() - 1)
          continue;
        auto Format = readConstantFormatString(CB->getArgOperand(FormatIndex),
                                               DL);
        if (!Format)
          continue;

        AllocaInst *VAList = getRootAlloca(CB->getArgOperand(CB->arg_size() - 1));
        if (!VAList)
          continue;
        AllocaInst *RegSaveArea = nullptr;
        for (BasicBlock &ScanBB : F) {
          for (Instruction &ScanI : ScanBB) {
            auto *SI = dyn_cast<StoreInst>(&ScanI);
            if (!SI)
              continue;
            auto Offset = getConstantGEPByteOffset(
                SI->getPointerOperand(), VAList, DL);
            if (Offset && *Offset == 16) {
              RegSaveArea = getRootAlloca(SI->getValueOperand());
              break;
            }
          }
          if (RegSaveArea)
            break;
        }
        if (!RegSaveArea) {
          // Some optimized lifted forms hide the store of va_list.reg_save_area
          // behind a cast/phi.  The save area is still an explicit alloca in
          // this function; use it as a conservative fallback for scanf-only
          // pointer slots rather than leaving guest addresses in va_list.
          for (BasicBlock &FallbackBB : F) {
            for (Instruction &FallbackI : FallbackBB) {
              auto *AI = dyn_cast<AllocaInst>(&FallbackI);
              if (AI && AI->getName().contains("reg_save_area")) {
                RegSaveArea = AI;
                break;
              }
            }
            if (RegSaveArea)
              break;
          }
        }
        if (!RegSaveArea)
          continue;

        FormatRule Rule;
        Rule.RegSaveArea = RegSaveArea;
        collectFormatPointerSlots(*Format, IsScanf, FixedArguments * 8,
                                  Rule.PointerOffsets);
        if (IsScanf) {
          // Every non-suppressed scanf conversion consumes a pointer.  Keep
          // the first GP slots covered even when format provenance was folded
          // and the parser could not recover a conversion list.
          for (unsigned Offset = FixedArguments * 8; Offset <= 40;
               Offset += 8)
            Rule.PointerOffsets.push_back(Offset);
        }
        Rules.push_back(Rule);
      }
    }
  }

  unsigned Rewritten = 0;
  SmallPtrSet<StoreInst *, 32> Seen;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<StoreInst>(&I);
        if (!SI || !IsNativeVarargSaveSlot(SI->getPointerOperand()))
          continue;
        auto *SlotRoot = getRootAlloca(SI->getPointerOperand());
        auto SlotOffset = getConstantGEPByteOffset(
            SI->getPointerOperand(), SlotRoot, DL);
        if (!SlotRoot || !SlotOffset)
          continue;

        bool IsPointerSlot = false;
        for (const FormatRule &Rule : Rules) {
          if (Rule.RegSaveArea != SlotRoot)
            continue;
          for (unsigned PointerOffset : Rule.PointerOffsets) {
            if (PointerOffset == *SlotOffset) {
              IsPointerSlot = true;
              break;
            }
          }
          if (IsPointerSlot)
            break;
        }
        if (!IsPointerSlot || !Seen.insert(SI).second)
          continue;

        Value *Stored = SI->getValueOperand();
        IRBuilder<> B(SI);
        if (Stored->getType()->isIntegerTy()) {
          // Global-data recovery may already have converted this slot to
          // ptrtoint(native_object).  Feeding that native address through the
          // guest-range mapper again rebases it a second time and produces an
          // invalid pointer such as native_base + (native_addr - guest_base).
          Value *NativeCarrier = nullptr;
          if (auto *PTI = dyn_cast<PtrToIntInst>(Stored))
            NativeCarrier = PTI->getPointerOperand();
          else if (auto *CE = dyn_cast<ConstantExpr>(Stored)) {
            if (CE->getOpcode() == Instruction::PtrToInt)
              NativeCarrier = CE->getOperand(0);
          }
          if (NativeCarrier) {
            SmallPtrSet<Value *, 16> NativeSeen;
            if (isNativePointerValue(NativeCarrier, NativeSeen))
              continue;
          }
          // scanf destination slots may carry either a guest-stack address or
          // a recovered BSS/global address.  Resolve the exact recovered data
          // object first: a State-derived global integer can otherwise look
          // stack-provenant and gets rebased into frame_storage_backing, so
          // scanf writes input where the program never reads it.
          Value *NativePtr = materializeRecoveredDataPointer(M, B, Stored);
          if (!NativePtr)
            NativePtr = lowerNativeStackInteger(
                B, Stored, *SI->getFunction());
          if (!NativePtr)
            continue;
          Value *NativeAddr = B.CreatePtrToInt(NativePtr, Stored->getType(),
                                               "native.vararg.address");
          SI->setOperand(0, NativeAddr);
          ++Rewritten;
          Changed = true;
        } else if (Stored->getType()->isPointerTy()) {
          Value *GuestAddress = nullptr;
          if (auto *ITP = dyn_cast<IntToPtrInst>(Stored))
            GuestAddress = ITP->getOperand(0);
          else if (auto *CE = dyn_cast<ConstantExpr>(Stored)) {
            if (CE->getOpcode() == Instruction::IntToPtr)
              GuestAddress = CE->getOperand(0);
          }
          if (!GuestAddress || !GuestAddress->getType()->isIntegerTy())
            continue;
          Value *NativePtr = materializeRecoveredDataPointer(
              M, B, GuestAddress);
          if (!NativePtr)
            continue;
          SI->setOperand(0, NativePtr);
          ++Rewritten;
          Changed = true;
        }
    }
  }
  }
  return Rewritten;
}

// A malloc-family call writes the native pointer into RAX.  After the lifted
// state is converted to explicit ABI arguments, some McSema-produced bodies
// still read the incoming `state_in_2216` value instead of the allocator
// result.  Restore that ordinary SSA dataflow before pointer cleanup.
static unsigned repairNativeAllocatorRAX(Module &M, bool &Changed) {
  unsigned Rewritten = 0;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    Argument *RAXArg = nullptr;
    for (Argument &Arg : F.args()) {
      if (Arg.getName() == "state_in_2216" ||
          Arg.getName() == "arg_RAX") {
        RAXArg = &Arg;
        break;
      }
    }
    if (!RAXArg || !RAXArg->getType()->isIntegerTy())
      continue;

    DominatorTree DT(F);
    SmallVector<CallInst *, 8> Allocators;
    SmallVector<CallInst *, 8> DeallocatorReturns;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee)
          continue;
        StringRef Name = Callee->getName();
        if (CI->getType()->isPointerTy() &&
            (Name == "malloc" || Name == "calloc" || Name == "realloc"))
          Allocators.push_back(CI);
        else if (CI->getType()->isIntegerTy() && Name == "free")
          DeallocatorReturns.push_back(CI);
      }
    }

    // Choose the nearest dominating allocator for each RAX use.  Replacing
    // all dominated uses once per allocator is order-dependent: with
    // calloc(); calloc(); use(RAX), the first pass consumes the use before the
    // second pass can associate it with the second allocation.  The native
    // value in RAX is a normal SSA definition, so the selected definition must
    // be the latest allocator that dominates that use.
    DenseMap<CallInst *, Value *> Results;
    SmallVector<Use *, 16> RAXUses;
    for (Use &U : RAXArg->uses())
      RAXUses.push_back(&U);
    for (Use *UPtr : RAXUses) {
      Use &U = *UPtr;
      auto *UserI = dyn_cast<Instruction>(U.getUser());
      if (!UserI)
        continue;

      CallInst *Best = nullptr;
      for (CallInst *Allocator : Allocators) {
        if (Allocator->getParent() == UserI->getParent() &&
            !Allocator->comesBefore(UserI))
          continue;
        if (!DT.dominates(Allocator, UserI))
          continue;
        if (!Best || DT.dominates(Best, Allocator)) {
          Best = Allocator;
          continue;
        }
        // DominatorTree normally orders two definitions that both dominate a
        // use.  Keep an explicit same-block fallback for LLVM versions where
        // the relation is not exposed through the instruction overload.
        if (Best->getParent() == Allocator->getParent() &&
            Best->comesBefore(Allocator))
          Best = Allocator;
      }
      if (!Best)
        continue;

      Value *&Result = Results[Best];
      if (!Result) {
        Instruction *InsertBefore = Best->getNextNode();
        IRBuilder<> B(Best->getParent());
        if (InsertBefore)
          B.SetInsertPoint(InsertBefore);
        else
          B.SetInsertPoint(Best->getParent());
        Result = B.CreatePtrToInt(Best, RAXArg->getType(),
                                  "native.allocator.rax");
      }
      U.set(Result);
      ++Rewritten;
      Changed = true;
    }

    // Before the external bridge can prove a native pointer argument, a
    // preserved lifted `free` may still return an integer carrier.  In the
    // original machine code that carrier is not a C return value; it is the
    // stale RAX value until a following allocator writes RAX.  Associate such
    // uses with the nearest allocator that occurs after the free and before
    // the use.  This handles free(); calloc(); use(RAX) without encoding a
    // function or slot from a particular binary.
    for (CallInst *FreeCall : DeallocatorReturns) {
      SmallVector<Use *, 8> FreeUses;
      for (Use &U : FreeCall->uses())
        FreeUses.push_back(&U);
      for (Use *UPtr : FreeUses) {
        Use &U = *UPtr;
        auto *UserI = dyn_cast<Instruction>(U.getUser());
        if (!UserI)
          continue;

        CallInst *Best = nullptr;
        for (CallInst *Allocator : Allocators) {
          if (FreeCall->getParent() == Allocator->getParent()) {
            if (!FreeCall->comesBefore(Allocator))
              continue;
          } else if (!DT.dominates(FreeCall, Allocator)) {
            continue;
          }
          if (Allocator->getParent() == UserI->getParent() &&
              !Allocator->comesBefore(UserI))
            continue;
          if (!DT.dominates(Allocator, UserI))
            continue;
          if (!Best || DT.dominates(Best, Allocator) ||
              (Best->getParent() == Allocator->getParent() &&
               Best->comesBefore(Allocator)))
            Best = Allocator;
        }
        if (!Best)
          continue;

        Value *&Result = Results[Best];
        if (!Result) {
          Instruction *InsertBefore = Best->getNextNode();
          IRBuilder<> B(Best->getParent());
          if (InsertBefore)
            B.SetInsertPoint(InsertBefore);
          else
            B.SetInsertPoint(Best->getParent());
          Result = B.CreatePtrToInt(Best, RAXArg->getType(),
                                    "native.allocator.rax");
        }
        U.set(Result);
        ++Rewritten;
        Changed = true;
      }
    }
  }
  return Rewritten;
}

static unsigned eraseBrightenReturnMarkers(Module &M, bool &Changed);

// A preserved external wrapper can leave a direct libc declaration with the
// lifter's integer carrier ABI, e.g. `i64 @free(i64)` or
// `i64 @memset(i64, i64, i64)`.  Once the State ABI is gone those declarations
// are not merely ugly: LLVM is allowed to optimize them differently from the
// real C ABI.  Normalize the small, stable libc ABI surface here, after all
// pointer-carrier lowering has happened.
static FunctionType *nativeExternalType(Module &M, StringRef Name) {
  if (Name.ends_with(".lifted_abi"))
    Name = Name.drop_back(StringRef(".lifted_abi").size());
  LLVMContext &Ctx = M.getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  Type *I64 = Type::getInt64Ty(Ctx);
  Type *F64 = Type::getDoubleTy(Ctx);
  Type *Ptr = PointerType::getUnqual(Ctx);
  auto Fixed = [&](Type *Ret, ArrayRef<Type *> Params,
                   bool VarArg = false) {
    return FunctionType::get(Ret, Params, VarArg);
  };

  if (Name == "free")
    return Fixed(Type::getVoidTy(Ctx), {Ptr});
  if (Name == "malloc")
    return Fixed(Ptr, {I64});
  if (Name == "calloc")
    return Fixed(Ptr, {I64, I64});
  if (Name == "realloc")
    return Fixed(Ptr, {Ptr, I64});
  if (Name == "memset")
    return Fixed(Ptr, {Ptr, I32, I64});
  if (Name == "memcpy" || Name == "memmove")
    return Fixed(Ptr, {Ptr, Ptr, I64});
  if (Name == "puts")
    return Fixed(I32, {Ptr});
  if (Name == "strlen")
    return Fixed(I64, {Ptr});
  if (Name == "strcmp")
    return Fixed(I32, {Ptr, Ptr});
  if (Name == "strstr")
    return Fixed(Ptr, {Ptr, Ptr});
  if (Name == "strncmp")
    return Fixed(I32, {Ptr, Ptr, I64});
  if (Name == "getchar")
    return Fixed(I32, {});
  if (Name == "gets")
    return Fixed(Ptr, {Ptr});
  if (Name == "fgets")
    return Fixed(Ptr, {Ptr, I32, Ptr});
  if (Name == "strtok")
    return Fixed(Ptr, {Ptr, Ptr});
  if (Name == "sqrt")
    return Fixed(F64, {F64});
  if (Name == "hypot" || Name == "atan2" || Name == "pow")
    return Fixed(F64, {F64, F64});
  if (Name == "printf" || Name == "scanf" || Name == "__isoc99_scanf")
    return Fixed(I32, {Ptr}, true);
  if (Name == "vprintf" || Name == "vscanf" ||
      Name == "__isoc99_vscanf")
    return Fixed(I32, {Ptr, Ptr});
  if (Name == "__cxa_finalize")
    return Fixed(Type::getVoidTy(Ctx), {Ptr});
  if (Name == "exit")
    return Fixed(Type::getVoidTy(Ctx), {I32});
  if (Name == "abort")
    return Fixed(Type::getVoidTy(Ctx), {});
  return nullptr;
}

static Value *coerceNativeExternalValue(IRBuilder<> &B, Value *V, Type *Dst) {
  if (!V || !Dst)
    return nullptr;
  if (V->getType() == Dst)
    return V;
  Type *Src = V->getType();
  if (Src->isIntegerTy() && Dst->isPointerTy()) {
    // ABI normalization runs after the first stack-address lowering pass.
    // Do not re-materialize a proven RSP/RBP-derived value as inttoptr here:
    // external arguments such as sprintf/strlen destinations may still be
    // represented by an integer stack address at this late boundary.
    if (BasicBlock *BB = B.GetInsertBlock()) {
      if (Value *NativeStackPtr = lowerNativeStackInteger(
              B, V, *BB->getParent()))
        return NativeStackPtr;
    }
    return B.CreateIntToPtr(V, Dst, "native.external.inttoptr");
  }
  if (Src->isPointerTy() && Dst->isIntegerTy())
    return B.CreatePtrToInt(V, Dst, "native.external.ptrtoint");
  if (Src->isIntegerTy() && Dst->isIntegerTy()) {
    unsigned SW = Src->getIntegerBitWidth();
    unsigned DW = Dst->getIntegerBitWidth();
    if (SW > DW)
      return B.CreateTrunc(V, Dst, "native.external.trunc");
    return B.CreateZExt(V, Dst, "native.external.zext");
  }
  return nullptr;
}

static unsigned normalizeNativeExternalABIs(Module &M, bool &Changed,
                                             SmallVectorImpl<std::string> *Findings) {
  SmallVector<CallInst *, 128> Calls;
  for (Function &F : M) {
    // The Remill dispatcher can survive until late cleanup when a guest uses
    // a runtime function pointer.  Its libc arms still need the real C ABI;
    // otherwise the dispatcher itself pins declarations such as
    // vscanf.lifted_abi even after all direct lifted wrappers are gone.
    if (F.isDeclaration() ||
        (isLiftedFunctionName(F.getName()) &&
         F.getName() != "__remill_function_call"))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee || !nativeExternalType(M, Callee->getName()))
          continue;
        Calls.push_back(CI);
      }
    }
  }

  unsigned Rewritten = 0;
  SmallVector<std::pair<Function *, Function *>, 16> LiftedDeclarations;
  for (CallInst *OldCall : Calls) {
    if (!OldCall->getParent())
      continue;
    Function *OldCallee = OldCall->getCalledFunction();
    if (!OldCallee)
      continue;
    StringRef ExternalName = OldCallee->getName();
    StringRef CanonicalName = ExternalName;
    if (CanonicalName.ends_with(".lifted_abi"))
      CanonicalName = CanonicalName.drop_back(StringRef(".lifted_abi").size());
    FunctionType *Expected = nativeExternalType(M, CanonicalName);
    if (!Expected || OldCallee->getFunctionType() == Expected)
      continue;

    // A void ABI has no return value.  Do not invent one for a lifted use:
    // using a deallocator's incidental RAX contents is undefined at the C
    // level and must be reported as an unsupported native contract.
    if (Expected->getReturnType()->isVoidTy() && !OldCall->use_empty()) {
      if (Findings)
        addFinding(*Findings, "external ABI result used", OldCallee->getName());
      continue;
    }

    Function *NativeCallee = M.getFunction(CanonicalName);
    if (NativeCallee == OldCallee) {
      if (!OldCallee->getName().ends_with(".lifted_abi")) {
        std::string OldName = OldCallee->getName().str();
        OldCallee->setName(OldName + ".lifted_abi");
      }
      NativeCallee = Function::Create(Expected, GlobalValue::ExternalLinkage,
                                      CanonicalName, &M);
      NativeCallee->setCallingConv(OldCall->getCallingConv());
    }
    if (!NativeCallee || NativeCallee->getFunctionType() != Expected)
      continue;
    if (OldCallee != NativeCallee &&
        OldCallee->getName().ends_with(".lifted_abi"))
      LiftedDeclarations.emplace_back(OldCallee, NativeCallee);

    IRBuilder<> B(OldCall);
    SmallVector<Value *, 16> Args;
    bool Valid = OldCall->arg_size() >= Expected->getNumParams();
    for (unsigned I = 0; Valid && I < Expected->getNumParams(); ++I) {
      Value *Arg = coerceNativeExternalValue(
          B, OldCall->getArgOperand(I), Expected->getParamType(I));
      if (!Arg)
        Valid = false;
      else
        Args.push_back(Arg);
    }
    if (!Valid)
      continue;
    if (Expected->isVarArg())
      for (unsigned I = Expected->getNumParams(); I < OldCall->arg_size(); ++I)
        Args.push_back(OldCall->getArgOperand(I));
    else if (OldCall->arg_size() != Expected->getNumParams())
      continue;

    CallInst *NewCall = B.CreateCall(NativeCallee, Args,
                                     Expected->getReturnType()->isVoidTy()
                                         ? ""
                                         : "native.external.ret");
    NewCall->setCallingConv(NativeCallee->getCallingConv());
    if (!OldCall->use_empty()) {
      Value *Replacement = coerceNativeExternalValue(
          B, NewCall, OldCall->getType());
      if (!Replacement)
        continue;
      OldCall->replaceAllUsesWith(Replacement);
    }
    OldCall->eraseFromParent();
    Changed = true;
    ++Rewritten;
  }

  // Relocation tables in a residual native data allocation may still name
  // the lifted declaration after every executable callsite was normalized.
  // Rebase only declarations whose complete use graph ends in globals; a
  // constant-expression call user would still require ABI conversion.
  auto HasOnlyGlobalConstantUsers = [](Value *Root) {
    SmallVector<Value *, 16> Work{Root};
    SmallPtrSet<Value *, 32> Seen;
    while (!Work.empty()) {
      Value *V = Work.pop_back_val();
      if (!Seen.insert(V).second)
        continue;
      for (User *U : V->users()) {
        if (isa<GlobalVariable>(U))
          continue;
        if (isa<Constant>(U)) {
          Work.push_back(cast<Value>(U));
          continue;
        }
        return false;
      }
    }
    return true;
  };
  LiftedDeclarations.clear();
  for (Function &F : M) {
    if (!F.getName().ends_with(".lifted_abi"))
      continue;
    StringRef Canonical =
        F.getName().drop_back(StringRef(".lifted_abi").size());
    if (Function *Native = M.getFunction(Canonical))
      LiftedDeclarations.emplace_back(&F, Native);
  }
  for (auto [Lifted, Native] : LiftedDeclarations) {
    if (!Lifted->getParent() || !HasOnlyGlobalConstantUsers(Lifted))
      continue;
    Lifted->replaceAllUsesWith(Native);
    if (Lifted->use_empty())
      Lifted->eraseFromParent();
    Changed = true;
  }
  return Rewritten;
}

static bool parseStateSlotName(StringRef Name, StringRef Prefix,
                               uint64_t &Offset) {
  if (!Name.starts_with(Prefix))
    return false;
  StringRef Suffix = Name.drop_front(Prefix.size());
  if (Suffix.empty() || Suffix.getAsInteger(10, Offset))
    return false;
  return true;
}

static bool isStateOutputValue(Value *V, uint64_t Offset,
                               SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  uint64_t ValueOffset = 0;
  StringRef Name = V->getName();
  if (parseStateSlotName(Name, "state_out.", ValueOffset) &&
      ValueOffset == Offset)
    return true;
  if (parseStateSlotName(Name, "state_out_", ValueOffset) &&
      ValueOffset == Offset)
    return true;
  if (auto *I = dyn_cast<Instruction>(V)) {
    for (Value *Op : I->operands())
      if (isStateOutputValue(Op, Offset, Seen))
        return true;
  }
  return false;
}

static std::optional<unsigned>
findStateOutputIndex(Value *Aggregate, uint64_t Offset,
                     SmallPtrSetImpl<Value *> &Seen) {
  if (!Aggregate || !Seen.insert(Aggregate).second)
    return std::nullopt;
  if (auto *IV = dyn_cast<InsertValueInst>(Aggregate)) {
    ArrayRef<unsigned> Indices = IV->getIndices();
    if (Indices.size() == 1) {
      SmallPtrSet<Value *, 16> ValueSeen;
      if (isStateOutputValue(IV->getInsertedValueOperand(), Offset,
                             ValueSeen))
        return Indices.front();
    }
    return findStateOutputIndex(IV->getAggregateOperand(), Offset, Seen);
  }
  if (auto *PN = dyn_cast<PHINode>(Aggregate)) {
    for (Value *Incoming : PN->incoming_values())
      if (auto Index = findStateOutputIndex(Incoming, Offset, Seen))
        return Index;
  }
  return std::nullopt;
}

// RBP is callee-saved in the native ABI and is also the anchor used by the
// recovered stack model.  A lifted return can accidentally populate the RBP
// output slot from a transient stack load instead of carrying the incoming
// RBP forward.  The output field is located from the State-SSA slot name,
// not from a function name or a fixed aggregate index.
static unsigned preserveNativeRBPOutputs(Module &M, bool &Changed) {
  unsigned Rewritten = 0;
  for (Function &F : M) {
    Argument *RBP = nullptr;
    uint64_t RBPOffset = 0;
    for (Argument &Arg : F.args()) {
      uint64_t Offset = 0;
      if (parseStateSlotName(Arg.getName(), "state_in_", Offset) &&
          Arg.getType()->isIntegerTy(64) &&
          Arg.getName().contains("2328")) {
        RBP = &Arg;
        RBPOffset = Offset;
        break;
      }
    }
    auto *ResultTy = dyn_cast<StructType>(F.getReturnType());
    if (!RBP || !ResultTy)
      continue;
    SmallVector<ReturnInst *, 8> Returns;
    for (BasicBlock &BB : F)
      if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator()))
        Returns.push_back(RI);
    for (ReturnInst *RI : Returns) {
      if (RI->getReturnValue()->getType() != ResultTy)
        continue;
      SmallPtrSet<Value *, 32> AggregateSeen;
      auto OutputIndex = findStateOutputIndex(RI->getReturnValue(), RBPOffset,
                                              AggregateSeen);
      if (!OutputIndex || *OutputIndex >= ResultTy->getNumElements() ||
          !ResultTy->getElementType(*OutputIndex)->isIntegerTy(64))
        continue;
      IRBuilder<> B(RI);
      Value *Fixed = B.CreateInsertValue(RI->getReturnValue(), RBP,
                                         {*OutputIndex},
                                          "native.rbp.return");
      RI->setOperand(0, Fixed);
      ++Rewritten;
      Changed = true;
    }
  }
  return Rewritten;
}

static unsigned inlineExternalLiftedWrappers(Module &M, bool &Changed) {
  SmallVector<Function *, 16> Wrappers;
  for (Function &F : M) {
    if (!F.isDeclaration() && F.getName().starts_with("ext_"))
      Wrappers.push_back(&F);
  }

  unsigned Inlined = 0;
  for (Function *Wrapper : Wrappers) {
    SmallVector<CallBase *, 16> Calls;
    for (User *U : Wrapper->users()) {
      if (auto *CB = dyn_cast<CallBase>(U))
        Calls.push_back(CB);
    }
    for (CallBase *CB : Calls) {
      InlineFunctionInfo IFI;
      InlineResult Result = InlineFunction(*CB, IFI);
      if (Result.isSuccess()) {
        ++Inlined;
        Changed = true;
      }
    }
  }
  return Inlined;
}

static bool readConstantByte(Constant *C, const DataLayout &DL,
                             uint64_t Offset, uint8_t &Byte) {
  if (!C)
    return false;
  if (isa<ConstantAggregateZero>(C)) {
    Byte = 0;
    return true;
  }
  if (auto *CI = dyn_cast<ConstantInt>(C)) {
    if (Offset != 0 || CI->getType()->getPrimitiveSizeInBits() != 8)
      return false;
    Byte = static_cast<uint8_t>(CI->getZExtValue());
    return true;
  }
  if (auto *CDS = dyn_cast<ConstantDataSequential>(C)) {
    Type *ElementTy = CDS->getElementType();
    uint64_t ElementBytes = DL.getTypeAllocSize(ElementTy).getFixedValue();
    if (!ElementBytes || Offset / ElementBytes >= CDS->getNumElements())
      return false;
    uint64_t Element = Offset / ElementBytes;
    uint64_t InElement = Offset % ElementBytes;
    if (ElementTy->isIntegerTy(8) && InElement == 0) {
      Byte = static_cast<uint8_t>(CDS->getElementAsInteger(Element));
      return true;
    }
    return false;
  }
  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    StructType *ST = CS->getType();
    const StructLayout *Layout = DL.getStructLayout(ST);
    for (unsigned I = 0; I < CS->getNumOperands(); ++I) {
      uint64_t Begin = Layout->getElementOffset(I);
      uint64_t End = I + 1 < CS->getNumOperands()
                         ? Layout->getElementOffset(I + 1)
                         : DL.getTypeAllocSize(ST).getFixedValue();
      if (Offset >= Begin && Offset < End)
        return readConstantByte(CS->getOperand(I), DL, Offset - Begin, Byte);
    }
    return false;
  }
  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    ArrayType *AT = CA->getType();
    uint64_t ElementBytes =
        DL.getTypeAllocSize(AT->getElementType()).getFixedValue();
    if (!ElementBytes)
      return false;
    uint64_t I = Offset / ElementBytes;
    if (I >= CA->getNumOperands())
      return false;
    return readConstantByte(CA->getOperand(I), DL, Offset % ElementBytes,
                            Byte);
  }
  return false;
}

static std::optional<uint64_t> segmentPointerOffset(Value *V,
                                                     GlobalVariable *Segment,
                                                     const DataLayout &DL) {
  auto *GEP = dyn_cast<GEPOperator>(V ? V->stripPointerCasts() : nullptr);
  if (!GEP)
    return std::nullopt;
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = GEP->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (Base != Segment || Offset.isNegative())
    return std::nullopt;
  return Offset.getZExtValue();
}

static unsigned materializeNativeSegmentPointers(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  std::map<std::pair<GlobalVariable *, uint64_t>, GlobalVariable *> Materialized;
  unsigned Replaced = 0;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo) {
          auto *CE = dyn_cast<ConstantExpr>(I.getOperand(OpNo));
          bool DirectPtrToInt = isa<PtrToIntInst>(&I) && OpNo == 0 && CE &&
                                CE->getOpcode() == Instruction::GetElementPtr;
          if (!CE || (CE->getOpcode() != Instruction::PtrToInt &&
                      !DirectPtrToInt))
            continue;
          auto *GEP = DirectPtrToInt
                          ? cast<GEPOperator>(CE)
                          : dyn_cast<GEPOperator>(CE->getOperand(0));
          if (!GEP)
            continue;

          GlobalVariable *Segment = nullptr;
          uint64_t Offset = 0;
          for (GlobalVariable &GV : M.globals()) {
            if (!GV.getName().starts_with("seg_"))
              continue;
            if (auto Found = segmentPointerOffset(GEP, &GV, DL)) {
              Segment = &GV;
              Offset = *Found;
              break;
            }
          }
          if (!Segment)
            continue;

          auto Key = std::make_pair(Segment, Offset);
          GlobalVariable *NativeData = nullptr;
          auto It = Materialized.find(Key);
          if (It != Materialized.end()) {
            NativeData = It->second;
          } else {
            if (!Segment->hasInitializer())
              continue;
            SmallVector<uint8_t, 256> Bytes;
            uint64_t Available = DL.getTypeAllocSize(Segment->getValueType())
                                     .getFixedValue();
            if (Offset >= Available)
              continue;
            Available -= Offset;
            if (Available > 256)
              Available = 256;
            // `seg_` denotes arbitrary guest memory, not necessarily a C
            // string.  Stopping at the first NUL truncated integer tables
            // (for example `{0, 1, 2, ...}`) to one byte and made later
            // indexed loads undefined.  Retain the bounded segment window;
            // native callers still see the same terminating NUL when this
            // is in fact a string.
            for (uint64_t I = 0; I < Available; ++I) {
              uint8_t Byte = 0;
              if (!readConstantByte(Segment->getInitializer(), DL,
                                    Offset + I, Byte))
                break;
              Bytes.push_back(Byte);
            }
            if (Bytes.empty())
              continue;
            StringRef Data(reinterpret_cast<const char *>(Bytes.data()),
                           Bytes.size());
            auto *Init = ConstantDataArray::getString(M.getContext(), Data,
                                                       false);
            NativeData = new GlobalVariable(
                M, Init->getType(), true, GlobalValue::InternalLinkage, Init,
                "native_data");
            NativeData->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
            NativeData->setAlignment(Align(1));
            Materialized.emplace(Key, NativeData);
          }

          if (DirectPtrToInt)
            I.setOperand(OpNo, NativeData);
          else
            I.setOperand(OpNo, ConstantExpr::getPtrToInt(
                                  NativeData, I.getOperand(OpNo)->getType()));
          ++Replaced;
          Changed = true;
        }
      }
    }
  }
  return Replaced;
}

static unsigned rewriteExactNativeSegmentGEPs(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  unsigned Replaced = 0;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo) {
          auto *GEP = dyn_cast<GEPOperator>(I.getOperand(OpNo));
          if (!GEP || !isa<ConstantExpr>(GEP))
            continue;
          GlobalVariable *Segment = nullptr;
          for (GlobalVariable &GV : M.globals()) {
            if (GV.getName().starts_with("seg_") &&
                segmentPointerOffset(GEP, &GV, DL)) {
              Segment = &GV;
              break;
            }
          }
          if (!Segment)
            continue;
          GlobalVariable *NativeData = nullptr;
          for (GlobalVariable &GV : M.globals()) {
            if (GV.getName().starts_with("native_data_") &&
                GV.getValueType() == Segment->getValueType()) {
              NativeData = &GV;
              break;
            }
          }
          if (!NativeData)
            continue;
          SmallVector<Constant *, 8> Indices;
          bool AllConstant = true;
          for (unsigned I = 1; I < GEP->getNumOperands(); ++I) {
            auto *C = dyn_cast<Constant>(GEP->getOperand(I));
            if (!C) {
              AllConstant = false;
              break;
            }
            Indices.push_back(C);
          }
          if (!AllConstant)
            continue;
          Constant *NativeGEP = ConstantExpr::getGetElementPtr(
              GEP->getSourceElementType(), NativeData, Indices,
              GEP->isInBounds());
          I.setOperand(OpNo, NativeGEP);
          ++Replaced;
          Changed = true;
        }
      }
    }
  }
  return Replaced;
}

static bool isRemillMetadataName(StringRef Name) {
  return Name.starts_with("remill.") || Name.starts_with("mcsema.") ||
         Name.starts_with("brighten.guest.");
}

static bool isGuestStackRegister(Value *V,
                                 SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  StringRef Name = V->getName();
  if (Name.contains("state_2312") || Name.contains("state_2328") ||
      Name.contains("state_in_2312") || Name.contains("state_in_2328") ||
      Name.contains("new_rsp") || Name.contains("new_rbp"))
    return true;
  if (auto *BO = dyn_cast<BinaryOperator>(V))
    return isGuestStackRegister(BO->getOperand(0), Seen) ||
           isGuestStackRegister(BO->getOperand(1), Seen);
  if (auto *PN = dyn_cast<PHINode>(V))
    for (Value *Incoming : PN->incoming_values())
      if (isGuestStackRegister(Incoming, Seen))
        return true;
  if (auto *SI = dyn_cast<SelectInst>(V))
    return isGuestStackRegister(SI->getTrueValue(), Seen) ||
           isGuestStackRegister(SI->getFalseValue(), Seen);
  return false;
}

static unsigned eraseDeadStateAllocas(Module &M, bool &Changed) {
  unsigned Erased = 0;
  SmallVector<AllocaInst *, 16> DeadAllocas;
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    for (Instruction &I : F.getEntryBlock()) {
      auto *AI = dyn_cast<AllocaInst>(&I);
      if (!AI) continue;
      bool IsStateCandidate = AI->getName().contains("state") || AI->getName().contains("State");
      if (!IsStateCandidate) {
        if (auto *ST = dyn_cast<StructType>(AI->getAllocatedType())) {
          if (ST->hasName() && ST->getName().contains("State"))
            IsStateCandidate = true;
        }
      }
      if (!IsStateCandidate) continue;

      bool OnlyDeadUsers = true;
      SmallVector<Instruction *, 8> UsersToErase;
      for (User *U : AI->users()) {
        auto *UserInst = dyn_cast<Instruction>(U);
        if (!UserInst) { OnlyDeadUsers = false; break; }
        if (auto *CI = dyn_cast<CallInst>(UserInst)) {
          if (Function *Callee = CI->getCalledFunction()) {
            if (Callee->getIntrinsicID() == Intrinsic::memset) {
              UsersToErase.push_back(CI);
              continue;
            }
          }
        }
        if (auto *SI = dyn_cast<StoreInst>(UserInst)) {
          UsersToErase.push_back(SI);
          continue;
        }
        if (auto *GEP = dyn_cast<GetElementPtrInst>(UserInst)) {
          bool GEPDead = true;
          for (User *GU : GEP->users()) {
            if (auto *GSI = dyn_cast<StoreInst>(GU)) {
              UsersToErase.push_back(GSI);
            } else {
              GEPDead = false; break;
            }
          }
          if (GEPDead) {
            UsersToErase.push_back(GEP);
            continue;
          }
        }
        if (UserInst->use_empty()) {
          UsersToErase.push_back(UserInst);
          continue;
        }
        OnlyDeadUsers = false;
        break;
      }

      if (OnlyDeadUsers) {
        DeadAllocas.push_back(AI);
        for (Instruction *UI : UsersToErase) {
          if (UI->getParent())
            UI->eraseFromParent();
        }
      }
    }
  }

  for (AllocaInst *AI : DeadAllocas) {
    AI->eraseFromParent();
    ++Erased;
    Changed = true;
  }
  return Erased;
}

static void collectNativeContractViolations(
    Module &M, SmallVectorImpl<std::string> &Findings) {
  for (StructType *ST : M.getIdentifiedStructTypes()) {
    if (isStateType(ST))
      addFinding(Findings, "state type", ST->getName());
    if (ST->hasName() && ST->getName().starts_with("seg_"))
      addFinding(Findings, "raw segment type", ST->getName());
  }

  for (Function &F : M) {
    StringRef Name = F.getName();
    if (Name == "main" &&
        ((F.arg_size() != 2 && F.arg_size() != 3) ||
         !F.getReturnType()->isIntegerTy(32) ||
         !F.getArg(0)->getType()->isIntegerTy(32) ||
         !F.getArg(1)->getType()->isPointerTy() ||
         (F.arg_size() == 3 && !F.getArg(2)->getType()->isPointerTy())))
      addFinding(Findings, "native entrypoint ABI", Name);
    if ((Name == "main" || Name.starts_with("native_entry_impl")) &&
        !F.isDeclaration() && F.size() == 1 &&
        F.getEntryBlock().size() == 1 &&
        isa<UnreachableInst>(F.getEntryBlock().getTerminator()))
      addFinding(Findings, "collapsed unreachable native entrypoint", Name);
    if (isLiftedFunctionName(Name) || isLiftedABI(F))
      addFinding(Findings, "lifted function/ABI", Name);
    if (Name.ends_with(".native") ||
        (F.arg_size() && F.getArg(0)->getType()->isPointerTy() &&
         F.getArg(0)->getName() == "state"))
      addFinding(Findings, "State-pointer native ABI", Name);
    if (auto *ST = dyn_cast<StructType>(F.getReturnType()))
      if (ST->hasName() && ST->getName().ends_with(".state_result"))
        addFinding(Findings, "State-slot aggregate return ABI", Name);
    for (Argument &A : F.args()) {
      if (A.getName() == "native_stack" || A.getName() == "frame_base")
        addFinding(Findings, "guest stack function ABI", Name);
    }
    if (F.hasMetadata("remill.function.type") ||
        F.hasMetadata("remill.function") || F.hasMetadata("mcsema.function"))
      addFinding(Findings, "lifter metadata", Name);

    bool HasDispatcherLikeCFG = false;
    for (BasicBlock &BB : F) {
      if (BB.getName().starts_with("inst_")) {
        HasDispatcherLikeCFG = true;
        break;
      }
      auto *SI = dyn_cast<SwitchInst>(BB.getTerminator());
      auto *StatePhi = SI ? dyn_cast<PHINode>(SI->getCondition()) : nullptr;
      if (!SI || !StatePhi || SI->getNumCases() < 2 ||
          SI->getDefaultDest() != &BB)
        continue;
      // OLLVM-style flattening uses a loop-carried pseudo-random state and a
      // self-looping default arm.  A source-language switch may legitimately
      // be sparse, so require both that structural signature and a non-dense
      // case set before rejecting it as a dispatcher.
      APInt Min = SI->case_begin()->getCaseValue()->getValue();
      APInt Max = Min;
      for (auto Case : SI->cases()) {
        const APInt &V = Case.getCaseValue()->getValue();
        if (V.slt(Min)) Min = V;
        if (V.sgt(Max)) Max = V;
      }
      APInt Span = Max - Min;
      if (Span.ugt(SI->getNumCases() * 4)) {
        HasDispatcherLikeCFG = true;
        break;
      }
    }
    if (HasDispatcherLikeCFG)
      addFinding(Findings, "guest CFG / flattened dispatcher model", Name);

    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (Use &Op : I.operands()) {
          if (containsUndefined(Op.get())) {
            addFinding(Findings, "undef/poison", F.getName());
            break;
          }
        }
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
          if (isa<ConstantInt>(ITP->getOperand(0)))
            addFinding(Findings, "constant guest address", F.getName());
          if (ITP->getName().starts_with("native.ptr") ||
              ITP->getName().starts_with("native.stack"))
            addFinding(Findings, "generated guest address conversion",
                       F.getName());
        }
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (isa<InlineAsm>(CB->getCalledOperand()))
            addFinding(Findings, "inline assembly", F.getName());
        }
        if (auto *PTI = dyn_cast<PtrToIntInst>(&I)) {
          if (isAddressArtifact(PTI->getPointerOperand()))
            addFinding(Findings, "lifted address conversion", F.getName());
          // The names used by stack lowering also cover a host frame anchor
          // while constructing a native GEP delta.  Reject only a conversion
          // whose source is not already a proven native pointer; otherwise a
          // legitimate `ptrtoint %frame_base` is indistinguishable by name
          // from a lifted numeric guest-stack carrier.
          if (PTI->getName().starts_with("native.stack")) {
            SmallPtrSet<Value *, 16> PointerSeen;
            if (!isNativePointerValue(PTI->getPointerOperand(), PointerSeen))
              addFinding(Findings, "guest stack address integer carrier",
                         F.getName());
          }
        }
        if (auto *AI = dyn_cast<AllocaInst>(&I)) {
          if (auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType()))
            if (AT->getNumElements() >= 1024 * 1024 &&
                AT->getElementType()->isIntegerTy(8) &&
                !AI->getName().starts_with("frame_storage") &&
                !AI->getName().starts_with("native_stack_storage"))
              addFinding(Findings, "fake guest stack allocation", F.getName());
          if (AI->getName().starts_with("native_stack") ||
              AI->getName().starts_with("frame_storage"))
            addFinding(Findings, "guest stack backing allocation", F.getName());
        }
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
          SmallPtrSet<Value *, 16> AddressSeen;
          if (isGuestStackRegister(ITP->getOperand(0), AddressSeen))
            addFinding(Findings, "guest stack integer-to-pointer", F.getName());
        }
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (Function *Callee = CB->getCalledFunction()) {
            StringRef ExternalName = Callee->getName();
            StringRef CanonicalName = ExternalName;
            if (CanonicalName.ends_with(".lifted_abi"))
              CanonicalName = CanonicalName.drop_back(StringRef(".lifted_abi").size());
            if (FunctionType *Expected = nativeExternalType(M, CanonicalName)) {
              if (Callee->getName().ends_with(".lifted_abi") ||
                  CB->getFunctionType() != Expected)
                addFinding(Findings, "external ABI mismatch", ExternalName);
            }
            if (Callee->getIntrinsicID() == Intrinsic::sideeffect &&
                CB->getOperandBundle("brighten_return_rax").has_value())
              addFinding(Findings, "transient RAX return marker",
                         F.getName());
            if (Callee->getName() == "__brighten_native_data_pointer")
              addFinding(Findings, "segment pointer mapper", F.getName());
            if (isLiftedFunctionName(Callee->getName()))
              addFinding(Findings, "lifted call", Callee->getName());
          }
        }
      }
    }
  }

  for (GlobalAlias &GA : M.aliases()) {
    StringRef Name = GA.getName();
    if (isLiftedGlobalName(Name) || Name.starts_with("data_"))
      addFinding(Findings, "lifted alias", Name);
  }
  for (GlobalVariable &GV : M.globals()) {
    StringRef Name = GV.getName();
    if (isLiftedGlobalName(Name) || Name.starts_with("seg_") ||
        Name.starts_with("__lifter_guest_stack"))
      addFinding(Findings, "lifted global", Name);
    if (Name.starts_with("frame_storage_backing."))
      addFinding(Findings, "guest stack backing global", Name);
    if (GV.hasInitializer() && containsUndefined(GV.getInitializer()))
      addFinding(Findings, "undef/poison global", Name);
    if (GV.getMetadata("brighten.guest.range"))
      addFinding(Findings, "guest address-range metadata", Name);
  }

  for (NamedMDNode &NMD : M.named_metadata()) {
    if (isRemillMetadataName(NMD.getName()))
      addFinding(Findings, "lifter named metadata", NMD.getName());
  }
}

static unsigned countStateGlobals(Module &M) {
  unsigned Count = 0;
  for (GlobalVariable &GV : M.globals())
    Count += GV.getName().contains("__mcsema_reg_state");
  for (GlobalAlias &GA : M.aliases())
    Count += GA.getName().contains("__mcsema_reg_state");
  return Count;
}

static void reportNativeContract(Module &M, unsigned RemovedFunctions,
                                 unsigned RemovedGlobals,
                                 bool EnforceStrict) {
  unsigned NativeFunctions = 0;
  unsigned RemillCalls = 0;
  unsigned StateGlobals = countStateGlobals(M);
  unsigned SegmentGlobals = 0;
  unsigned PoisonOperands = 0;
  unsigned UndefOperands = 0;
  unsigned InlineAsmCalls = 0;
  unsigned PtrToIntOps = 0;
  unsigned IntToPtrOps = 0;

  for (Function &F : M) {
    NativeFunctions += F.getName().ends_with(".native");
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        PtrToIntOps += isa<PtrToIntInst>(&I);
        IntToPtrOps += isa<IntToPtrInst>(&I);
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          if (Function *Callee = CB->getCalledFunction())
            RemillCalls += Callee->getName().starts_with("__remill_") ||
                           Callee->getName().starts_with("__mcsema_");
          InlineAsmCalls += isa<InlineAsm>(CB->getCalledOperand());
        }
        for (Use &Op : I.operands()) {
          PoisonOperands += isa<PoisonValue>(Op.get());
          UndefOperands += isa<UndefValue>(Op.get());
        }
      }
    }
  }
  for (GlobalVariable &GV : M.globals())
    SegmentGlobals += GV.getName().starts_with("seg_");

  SmallVector<std::string, 32> Violations;
  collectNativeContractViolations(M, Violations);
  errs() << "brighten-native-cleanup report:\n"
         << "  native functions: " << NativeFunctions << "\n"
         << "  unused lifted functions removed: " << RemovedFunctions << "\n"
         << "  unused lifted globals removed: " << RemovedGlobals << "\n"
         << "  remaining State globals/aliases: " << StateGlobals << "\n"
         << "  remaining segment globals: " << SegmentGlobals << "\n"
         << "  remaining Remill/McSema calls: " << RemillCalls << "\n"
         << "  poison operands: " << PoisonOperands << "\n"
         << "  undef operands: " << UndefOperands << "\n"
         << "  inline-asm calls: " << InlineAsmCalls << "\n"
         << "  ptrtoint/inttoptr: " << PtrToIntOps << "/" << IntToPtrOps
         << "\n"
         << "  native contract violations: " << Violations.size() << "\n";

  // Keep the final verifier useful even when strict aborts are intentionally
  // disabled for corpus development.  The Python driver persists these
  // findings beside the output, so a successfully emitted module cannot be
  // mistaken for one that satisfies the fully-native contract.
  if (EnforceStrict)
    for (StringRef Finding : Violations)
      errs() << "  native contract finding: " << Finding << "\n";

  if (NativeStrict && EnforceStrict && !Violations.empty()) {
    errs() << "brighten-native-cleanup strict verification failed:\n";
    for (StringRef Finding : Violations)
      errs() << "  - " << Finding << "\n";
    report_fatal_error("module does not satisfy fully-native LLVM IR contract");
  }
}

static void stripRemillMetadata(Module &M, bool &Changed,
                                bool StripGuestRanges = true) {
  SmallVector<unsigned, 8> Kinds;
  LLVMContext &Ctx = M.getContext();
  for (StringRef Name : {StringRef("remill.function.type"),
                         StringRef("remill.function"),
                         StringRef("mcsema.function")}) {
    unsigned Kind = Ctx.getMDKindID(Name);
    Kinds.push_back(Kind);
  }
  if (StripGuestRanges)
    Kinds.push_back(Ctx.getMDKindID("brighten.guest.range"));

  for (Function &F : M) {
    for (unsigned Kind : Kinds) {
      if (F.getMetadata(Kind)) {
        F.setMetadata(Kind, nullptr);
        Changed = true;
      }
    }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (unsigned Kind : Kinds) {
          if (I.getMetadata(Kind)) {
            I.setMetadata(Kind, nullptr);
            Changed = true;
          }
        }
      }
    }
  }

  for (GlobalVariable &GV : M.globals()) {
    for (unsigned Kind : Kinds) {
      if (GV.getMetadata(Kind)) {
        GV.setMetadata(Kind, nullptr);
        Changed = true;
      }
    }
  }

  SmallVector<NamedMDNode *, 8> DeadNamedMetadata;
  for (NamedMDNode &NMD : M.named_metadata()) {
    if (isRemillMetadataName(NMD.getName()))
      DeadNamedMetadata.push_back(&NMD);
  }
  for (NamedMDNode *NMD : DeadNamedMetadata) {
    NMD->eraseFromParent();
    Changed = true;
  }
}

static void foldExactPointerRoundTrips(Module &M, bool &Changed) {
  SmallVector<IntToPtrInst *, 16> RoundTrips;
  SmallVector<PtrToIntInst *, 16> IntegerRoundTrips;
  for (Function &F : M)
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
          Value *Integer = ITP->getOperand(0);
          bool Exact = false;
          if (auto *PTI = dyn_cast<PtrToIntInst>(Integer))
            Exact = PTI->getPointerOperand()->getType()->getPointerAddressSpace() ==
                    ITP->getType()->getPointerAddressSpace();
          else if (auto *CE = dyn_cast<ConstantExpr>(Integer))
            Exact = CE->getOpcode() == Instruction::PtrToInt &&
                    CE->getOperand(0)->getType()->getPointerAddressSpace() ==
                        ITP->getType()->getPointerAddressSpace();
          if (Exact)
            RoundTrips.push_back(ITP);
        }
        if (auto *PTI = dyn_cast<PtrToIntInst>(&I)) {
          auto *ITP = dyn_cast<IntToPtrInst>(PTI->getPointerOperand());
          if (ITP && ITP->getOperand(0)->getType() == PTI->getType()) {
            Value *Inner = ITP->getOperand(0);
            bool FoldedByPointerRoundTrip = isa<PtrToIntInst>(Inner);
            if (auto *CE = dyn_cast<ConstantExpr>(Inner))
              FoldedByPointerRoundTrip |=
                  CE->getOpcode() == Instruction::PtrToInt;
            if (!FoldedByPointerRoundTrip)
              IntegerRoundTrips.push_back(PTI);
          }
        }
      }

  for (IntToPtrInst *ITP : RoundTrips) {
    Value *Integer = ITP->getOperand(0);
    Value *Pointer = isa<PtrToIntInst>(Integer)
                         ? cast<PtrToIntInst>(Integer)->getPointerOperand()
                         : cast<ConstantExpr>(Integer)->getOperand(0);
    ITP->replaceAllUsesWith(Pointer);
    ITP->eraseFromParent();
    Changed = true;
  }
  for (PtrToIntInst *PTI : IntegerRoundTrips) {
    auto *ITP = cast<IntToPtrInst>(PTI->getPointerOperand());
    PTI->replaceAllUsesWith(ITP->getOperand(0));
    PTI->eraseFromParent();
    if (ITP->use_empty())
      ITP->eraseFromParent();
    Changed = true;
  }
}

// The devirt/ABI passes use this intrinsic only as an analysis marker while
// recovering the value returned in guest RAX.  It is not part of the native
// program semantics and must not survive the final lowering boundary: an
// operand bundle is still a hidden use of the lifted return value and keeps
// the old return-state protocol visible in otherwise native IR.
static unsigned eraseBrightenReturnMarkers(Module &M, bool &Changed) {
  SmallVector<CallBase *, 64> Markers;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        if (!Callee || Callee->getIntrinsicID() != Intrinsic::sideeffect ||
            !CB->getOperandBundle("brighten_return_rax").has_value())
          continue;
        Markers.push_back(CB);
      }
    }
  }

  for (CallBase *Marker : Markers) {
    Marker->eraseFromParent();
    Changed = true;
  }
  return Markers.size();
}

static unsigned eraseUnusedLiftedFunctions(Module &M, bool &Changed) {
  SmallVector<Function *, 32> Dead;
  for (Function &F : M) {
    if (F.isIntrinsic() || !F.use_empty())
      continue;
    if ((isLiftedFunctionName(F.getName()) ||
         isLiftedABI(F) ||
         F.getName().ends_with(".native") ||
         F.getName().starts_with("sub_") ||
         F.getName().starts_with("callback_sub_") ||
         F.getName() == ".init_proc_wrapper") &&
        F.getName() != "main")
      Dead.push_back(&F);
  }
  for (Function *F : Dead) {
    F->eraseFromParent();
    Changed = true;
  }
  return Dead.size();
}

static Function *resolveCallbackFunction(Value *V,
                                         SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *F = dyn_cast<Function>(V))
    return F;
  if (auto *GV = dyn_cast<GlobalVariable>(V)) {
    if (GV->hasInitializer())
      return resolveCallbackFunction(GV->getInitializer(), Seen);
  }
  if (auto *C = dyn_cast<Constant>(V)) {
    for (Value *Op : C->operands())
      if (Function *F = resolveCallbackFunction(Op, Seen))
        return F;
  }
  return nullptr;
}

static Value *coerceCallbackArgument(IRBuilder<> &B, Value *V, Type *Ty,
                                     const Twine &Name) {
  if (!V || !Ty)
    return nullptr;
  if (V->getType() == Ty)
    return V;
  if (V->getType()->isPointerTy() && Ty->isIntegerTy())
    return B.CreatePtrToInt(V, Ty, Name);
  if (V->getType()->isIntegerTy() && Ty->isPointerTy())
    return B.CreateIntToPtr(V, Ty, Name);
  if (V->getType()->isIntegerTy() && Ty->isIntegerTy()) {
    unsigned SW = V->getType()->getIntegerBitWidth();
    unsigned DW = Ty->getIntegerBitWidth();
    if (SW > DW)
      return B.CreateTrunc(V, Ty, Name);
    return B.CreateZExt(V, Ty, Name);
  }
  return nullptr;
}

// McSema represents a C callback as a naked guest trampoline plus a helper
// with the lifted (State, pc, memory) ABI.  Once the target body has already
// been recovered to a native SSA call, make the callback itself native too:
// qsort-style callbacks receive only their real arguments, while the
// recovered body gets a bounded native stack anchor and the two stack-register
// values it needs.  This removes the trampoline/helper pair without inventing
// a guest State object.
static unsigned lowerNativeCallbackTrampolines(Module &M, bool &Changed) {
  SmallVector<Function *, 16> Trampolines;
  for (Function &F : M) {
    if (F.isDeclaration() || F.getName() == "main" ||
        !F.hasFnAttribute(Attribute::Naked))
      continue;
    bool HasInlineAsm = false;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CB = dyn_cast<CallBase>(&I))
          HasInlineAsm |= isa<InlineAsm>(CB->getCalledOperand());
    if (HasInlineAsm)
      Trampolines.push_back(&F);
  }

  unsigned Lowered = 0;
  for (Function *Trampoline : Trampolines) {
    Function *Wrapper = nullptr;
    for (BasicBlock &BB : *Trampoline) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || !isa<InlineAsm>(CB->getCalledOperand()))
          continue;
        for (Use &Arg : CB->args()) {
          SmallPtrSet<Value *, 16> Seen;
          Function *Candidate = resolveCallbackFunction(Arg.get(), Seen);
          if (Candidate && Candidate != Trampoline &&
              Candidate->getName().ends_with("_wrapper") &&
              isLiftedABI(*Candidate)) {
            Wrapper = Candidate;
            break;
          }
        }
        if (Wrapper)
          break;
      }
      if (Wrapper)
        break;
    }
    if (!Wrapper)
      continue;

    CallBase *NativeCall = nullptr;
    for (BasicBlock &BB : *Wrapper) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (Callee && !Callee->isIntrinsic() && Callee != Wrapper) {
          NativeCall = CB;
          break;
        }
      }
      if (NativeCall)
        break;
    }
    if (!NativeCall)
      continue;
    Function *NativeTarget = NativeCall->getCalledFunction();
    if (!NativeTarget)
      continue;

    LLVMContext &Ctx = M.getContext();
    Type *PtrTy = PointerType::getUnqual(Ctx);
    FunctionType *AdapterTy =
        FunctionType::get(Type::getInt32Ty(Ctx), {PtrTy, PtrTy}, false);
    std::string AdapterName =
        (Trampoline->getName() + ".native_callback").str();
    Function *Adapter = Function::Create(
        AdapterTy, GlobalValue::InternalLinkage,
        AdapterName, M);
    Adapter->setCallingConv(Trampoline->getCallingConv());
    Adapter->setDSOLocal(true);
    Adapter->getArg(0)->setName("lhs");
    Adapter->getArg(1)->setName("rhs");
    BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", Adapter);
    IRBuilder<> B(Entry);
    AllocaInst *Stack =
        B.CreateAlloca(B.getInt8Ty(), B.getInt64(64 * 1024),
                       "callback_stack");
    Stack->setAlignment(Align(16));
    Value *StackTop = B.CreateConstGEP1_64(B.getInt8Ty(), Stack,
                                           64 * 1024 - 256,
                                           "callback_stack_top");
    Value *StackInt = B.CreatePtrToInt(StackTop, B.getInt64Ty(),
                                       "callback_stack_int");

    SmallVector<Value *, 32> Args;
    for (unsigned I = 0; I < NativeCall->arg_size(); ++I) {
      Type *Ty = NativeCall->getCalledFunction()->getFunctionType()
                     ->getParamType(I);
      Value *V = nullptr;
      if (I == 0 || NativeTarget->getArg(I)->getName() == "native_stack") {
        V = StackTop;
      } else {
        StringRef ArgName = NativeTarget->getArg(I)->getName();
        if (ArgName == "arg_RDI")
          V = Adapter->getArg(0);
        else if (ArgName == "arg_RSI")
          V = Adapter->getArg(1);
        else if (ArgName == "state_in_2312" ||
                 ArgName == "state_in_2328")
          V = StackInt;
        else
          V = Constant::getNullValue(Ty);
      }
      V = coerceCallbackArgument(B, V, Ty, "callback.arg");
      if (!V)
        break;
      Args.push_back(V);
    }
    if (Args.size() != NativeCall->arg_size()) {
      Adapter->eraseFromParent();
      continue;
    }

    CallInst *Call = B.CreateCall(NativeTarget, Args, "callback.native.call");
    Call->setCallingConv(NativeTarget->getCallingConv());
    Value *Ret = Call;
    if (auto *ST = dyn_cast<StructType>(Call->getType())) {
      if (ST->getNumElements() == 0) {
        B.CreateRet(ConstantInt::get(Type::getInt32Ty(Ctx), 0));
        continue;
      }
      Ret = B.CreateExtractValue(Call, {0}, "callback.ret");
    }
    if (Ret->getType()->isPointerTy())
      Ret = B.CreatePtrToInt(Ret, B.getInt64Ty(), "callback.ret.bits");
    if (Ret->getType()->isIntegerTy()) {
      unsigned Width = Ret->getType()->getIntegerBitWidth();
      if (Width > 32)
        Ret = B.CreateTrunc(Ret, B.getInt32Ty(), "callback.ret.i32");
      else if (Width < 32)
        Ret = B.CreateZExt(Ret, B.getInt32Ty(), "callback.ret.i32");
    }
    if (!Ret->getType()->isIntegerTy(32)) {
      Adapter->eraseFromParent();
      continue;
    }
    B.CreateRet(Ret);

    Trampoline->replaceAllUsesWith(Adapter);
    if (Trampoline->use_empty() && Trampoline->getParent())
      Trampoline->eraseFromParent();
    Changed = true;
    ++Lowered;
  }
  return Lowered;
}

static unsigned eraseDeadInlineAsmTrampolines(Module &M, bool &Changed) {
  SmallVector<Function *, 16> Dead;
  for (Function &F : M) {
    if (F.isDeclaration() || F.getName() == "main" || !F.hasFnAttribute(Attribute::Naked))
      continue;
    bool HasInlineAsm = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CB = dyn_cast<CallBase>(&I))
          HasInlineAsm |= isa<InlineAsm>(CB->getCalledOperand());
      }
    }
    if (HasInlineAsm && F.use_empty())
      Dead.push_back(&F);
  }
  for (Function *F : Dead) {
    F->eraseFromParent();
    Changed = true;
  }
  return Dead.size();
}

static unsigned eraseUnusedInlineAsmCalls(Module &M, bool &Changed) {
  SmallVector<CallBase *, 16> Dead;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || !isa<InlineAsm>(CB->getCalledOperand()) || !CB->use_empty())
          continue;
        Dead.push_back(CB);
      }
    }
  }
  for (CallBase *CB : Dead) {
    CB->eraseFromParent();
    Changed = true;
  }
  return Dead.size();
}

static unsigned eraseUnusedInternalGlobals(Module &M, bool &Changed) {
  SmallVector<GlobalVariable *, 32> Dead;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.hasLocalLinkage() && GV.use_empty())
      Dead.push_back(&GV);
  }
  for (GlobalVariable *GV : Dead) {
    GV->eraseFromParent();
    Changed = true;
  }
  return Dead.size();
}

static unsigned eraseUnusedNativeDataArtifacts(Module &M, bool &Changed) {
  unsigned Removed = 0;

  // Global-data recovery keeps temporary segment copies alive through
  // llvm.used until this final pass.  Drop only those temporary entries; do
  // not disturb unrelated compiler-used roots.
  for (StringRef UsedName : {StringRef("llvm.used"),
                             StringRef("llvm.compiler.used")}) {
    GlobalVariable *Used = M.getGlobalVariable(UsedName);
    auto *Array = Used ? dyn_cast<ConstantArray>(Used->getInitializer())
                       : nullptr;
    if (!Array)
      continue;
    SmallVector<Constant *, 32> Kept;
    for (Value *Operand : Array->operands()) {
      Value *Stripped = Operand->stripPointerCasts();
      auto *GV = dyn_cast<GlobalVariable>(Stripped);
      if (GV && GV->getName().starts_with("native_data_"))
        continue;
      Kept.push_back(cast<Constant>(Operand));
    }
    if (Kept.size() == Array->getNumOperands())
      continue;
    if (Kept.empty()) {
      Used->eraseFromParent();
    } else {
      ArrayType *Ty = ArrayType::get(Array->getType()->getElementType(),
                                     Kept.size());
      Used->setInitializer(ConstantArray::get(Ty, Kept));
    }
    Changed = true;
  }

  if (Function *Mapper = M.getFunction("__brighten_native_data_pointer")) {
    if (Mapper->use_empty()) {
      Mapper->eraseFromParent();
      ++Removed;
      Changed = true;
    }
  }

  SmallVector<GlobalVariable *, 32> DeadGlobals;
  for (GlobalVariable &GV : M.globals()) {
    if (!GV.getName().starts_with("native_data_"))
      continue;
    GV.removeDeadConstantUsers();
    if (GV.use_empty())
      DeadGlobals.push_back(&GV);
  }
  for (GlobalVariable *GV : DeadGlobals) {
    GV->eraseFromParent();
    ++Removed;
    Changed = true;
  }

  // LLVM keeps identified struct types in the module context even after their
  // last global/instruction reference is gone. Clear names of dead/unused
  // State, segment, and result struct types so textual IR remains clean.
  SmallPtrSet<Type *, 32> UsedTypes;
  for (GlobalVariable &GV : M.globals()) {
    UsedTypes.insert(GV.getValueType());
  }
  for (Function &F : M) {
    UsedTypes.insert(F.getReturnType());
    for (Argument &A : F.args())
      UsedTypes.insert(A.getType());
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        UsedTypes.insert(I.getType());
        if (auto *AI = dyn_cast<AllocaInst>(&I))
          UsedTypes.insert(AI->getAllocatedType());
        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I))
          UsedTypes.insert(GEP->getSourceElementType());
        for (Value *Op : I.operands())
          UsedTypes.insert(Op->getType());
      }
    }
  }

  for (StructType *ST : M.getIdentifiedStructTypes()) {
    if (!ST->hasName())
      continue;
    StringRef Name = ST->getName();
    if (Name.starts_with("seg_") || Name.contains("State") ||
        Name.contains("ArchState") || Name.contains("VectorReg") ||
        Name.contains("GPR") || Name.contains("MMX") ||
        Name.contains("FPU") || Name.contains("Segments") ||
        Name.contains("native_result") || Name.contains("state_result")) {
      if (!UsedTypes.count(ST))
        ST->setName("");
    }
  }
  return Removed;
}

// Compatibility boundary retained until pass 040 has proven and recovered
// every stack region consumed by the native entry call. This must disappear
// with the remaining residual frame users; strict mode rejects its backing so
// it cannot be mistaken for fully-native output.
static GlobalVariable *ensureNativeEntrypointStackStorage(Module &M) {
  Function *Main = M.getFunction("main");
  if (!Main || Main->isDeclaration() || Main->arg_size() == 2)
    return nullptr;
  if (Main->arg_size() < 2 || !Main->getReturnType()->isIntegerTy(32) ||
      !Main->getArg(0)->getType()->isIntegerTy(32) ||
      !Main->getArg(1)->getType()->isPointerTy())
    return nullptr;

  bool CallsNative = false;
  for (BasicBlock &BB : *Main)
    for (Instruction &I : BB)
      if (auto *CB = dyn_cast<CallBase>(&I))
        if (Function *Callee = CB->getCalledFunction();
            Callee && Callee->getName().ends_with(".native")) {
          CallsNative = true;
          break;
        }
  if (!CallsNative)
    return nullptr;

  LLVMContext &Ctx = M.getContext();
  constexpr uint64_t NativeStackBytes = 16 * 1024 * 1024;
  auto *StorageTy = ArrayType::get(Type::getInt8Ty(Ctx), NativeStackBytes);
  GlobalVariable *Storage = M.getNamedGlobal("frame_storage_backing.main");
  if (!Storage) {
    Storage = new GlobalVariable(M, StorageTy, false,
                                 GlobalValue::InternalLinkage,
                                 ConstantAggregateZero::get(StorageTy),
                                 "frame_storage_backing.main");
    Storage->setAlignment(Align(16));
    Storage->setMetadata("brighten.compat.fake_stack", MDNode::get(Ctx, {}));
  }
  return Storage;
}

static bool normalizeNativeEntrypoint(Module &M, bool &Changed) {
  Function *Main = M.getFunction("main");
  GlobalVariable *Storage = ensureNativeEntrypointStackStorage(M);
  if (!Main || !Storage)
    return false;

  LLVMContext &Ctx = M.getContext();
  constexpr uint64_t NativeStackBytes = 16 * 1024 * 1024;
  constexpr uint64_t NativeStackTop = NativeStackBytes - 64 * 1024;
  auto *StorageTy = ArrayType::get(Type::getInt8Ty(Ctx), NativeStackBytes);
  GlobalVariable *CanonicalState = nullptr;
  for (GlobalVariable &GV : M.globals())
    if (GV.getName().contains("__mcsema_reg_state")) {
      CanonicalState = &GV;
      break;
    }
  for (BasicBlock &BB : *Main) {
    for (Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      Function *Callee = CB ? CB->getCalledFunction() : nullptr;
      if (!CB || !Callee || !Callee->getName().ends_with(".native"))
        continue;
      Value *State = CanonicalState;
      if (!Callee->arg_empty() && Callee->getArg(0)->getName() == "state" &&
          !CB->arg_empty() && CB->getArgOperand(0)->getType()->isPointerTy() &&
          !isa<ConstantPointerNull>(CB->getArgOperand(0)))
        State = CB->getArgOperand(0);
      if (!State)
        continue;
      IRBuilder<> B(CB);
      Value *Base = B.CreateInBoundsGEP(
          StorageTy, Storage, {B.getInt32(0), B.getInt32(0)},
          "native_entry_stack_storage");
      Value *Top = B.CreateConstGEP1_64(B.getInt8Ty(), Base, NativeStackTop,
                                        "native_entry_stack_top");
      Value *TopInt = B.CreatePtrToInt(Top, B.getInt64Ty(),
                                      "native_entry_stack_int");
      for (uint64_t Offset : {uint64_t(2312), uint64_t(2328)}) {
        Value *Slot = B.CreateGEP(B.getInt8Ty(), State, B.getInt64(Offset));
        auto *Seed = B.CreateStore(TopInt, Slot);
        Seed->setVolatile(true);
      }
    }
  }

  FunctionType *ImplTy = Main->getFunctionType();
  std::string ImplName = "native_entry_impl";
  for (unsigned Suffix = 0; M.getFunction(ImplName); ++Suffix)
    ImplName = "native_entry_impl." + std::to_string(Suffix + 1);
  Main->setName(ImplName);
  Main->setLinkage(GlobalValue::InternalLinkage);
  Main->setDSOLocal(true);

  FunctionType *EntryTy = FunctionType::get(
      Type::getInt32Ty(Ctx),
      {Type::getInt32Ty(Ctx), PointerType::getUnqual(Ctx), PointerType::getUnqual(Ctx)}, false);
  Function *Entry = Function::Create(EntryTy, GlobalValue::ExternalLinkage,
                                     "main", M);
  Entry->setCallingConv(Main->getCallingConv());
  Entry->setDSOLocal(true);
  Entry->setVisibility(Main->getVisibility());

  IRBuilder<> B(BasicBlock::Create(Ctx, "entry", Entry));
  SmallVector<Value *, 4> Args;
  Args.push_back(Entry->getArg(0));
  Args.push_back(Entry->getArg(1));
  if (ImplTy->getNumParams() > 2)
    Args.push_back(Entry->getArg(2));
  for (unsigned I = 3; I < ImplTy->getNumParams(); ++I)
    Args.push_back(Constant::getNullValue(ImplTy->getParamType(I)));
  CallInst *Call = B.CreateCall(Main, Args, "native.entry.impl");
  Call->setCallingConv(Main->getCallingConv());
  B.CreateRet(Call);
  Changed = true;
  errs() << "  native entrypoint normalized to main(i32, ptr)\n";
  return true;
}

// The recovered entrypoint owns the concrete State and guest-stack backing
// allocations. Inlining a State-ABI callee through that boundary lets O3
// scalarize partially-defined State slots into `undef` pointer operands. A
// dereference of one of those operands is UB, after which SimplifyCFG may
// legally replace the entire entrypoint with `unreachable`. Keep only this
// ABI boundary opaque; callees remain available for normal optimization.
static unsigned preserveNativeEntrypointStateBoundary(Module &M,
                                                       bool &Changed) {
  Function *Main = M.getFunction("main");
  if (!Main || Main->isDeclaration())
    return 0;

  unsigned Preserved = 0;
  for (BasicBlock &BB : *Main) {
    for (Instruction &I : BB) {
      auto *CB = dyn_cast<CallBase>(&I);
      if (!CB)
        continue;
      // Proxy cleanup may leave an indirect or bitcast callsite pending later
      // canonicalization.  This boundary only needs direct native callees;
      // walking an unstable ConstantExpr cast chain here can dereference a
      // value invalidated by the preceding cleanup mutations.
      Function *Callee = CB->getCalledFunction();
      if (!Callee || Callee->isDeclaration() ||
          Callee->hasFnAttribute(Attribute::NoInline))
        continue;

      bool IsStateBoundary = isLiftedABI(*Callee) ||
          (Callee->getName().ends_with(".native") && Callee->arg_size() &&
           Callee->getArg(0)->getType()->isPointerTy());
      if (!IsStateBoundary)
        continue;

      Callee->addFnAttr(Attribute::NoInline);
      ++Preserved;
      Changed = true;
    }
  }
  return Preserved;
}

// Keep recovered native-to-native calls visible until the final State-SSA
// cleanup.  A recovered helper may use the guest RSP/RBP to address its own
// frame even when those registers are absent from its simplified C-like ABI.
// Inlining such a helper into its caller before State-SSA collapses the two
// guest frame identities onto the same backing object.  Once that happens,
// later stack relativization cannot distinguish a callee local from a caller
// local.  The final cleanup rewrites these calls with explicit frame/RSP/RBP
// carriers, after which normal code generation can optimize their bodies
// without losing the nested-frame boundary.
static unsigned preserveNestedNativeFrameBoundaries(Module &M,
                                                     bool &Changed) {
  unsigned Preserved = 0;
  for (Function &Caller : M) {
    if (Caller.isDeclaration() || !Caller.getName().ends_with(".native"))
      continue;

    for (BasicBlock &BB : Caller) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!Callee || Callee == &Caller || Callee->isDeclaration() ||
            !Callee->getName().ends_with(".native") ||
            Callee->hasFnAttribute(Attribute::NoInline))
          continue;
        // The callee owns the nested guest frame.  Marking the caller would
        // only stop the caller from moving upward; it would still allow this
        // callee body (and its frame) to collapse into the caller.
        Callee->addFnAttr(Attribute::NoInline);
        ++Preserved;
        Changed = true;
      }
    }
  }
  return Preserved;
}

static bool IsStartupOnlyUse(User *U, Function *Target) {
  if (auto *CB = dyn_cast<CallBase>(U)) {
    Function *Caller = CB->getFunction();
    return Caller && (Caller->getName() == "__remill_function_call" ||
                      Caller->getName() == "__remill_jump");
  }

  auto *PN = dyn_cast<PHINode>(U);
  if (!PN || PN->getFunction()->getName() != "__translate_guest_pointer")
    return false;
  for (Value *Incoming : PN->incoming_values()) {
    if (Incoming->stripPointerCasts() == Target)
      return true;
  }
  return false;
}

static bool RemoveTargetFromDispatcher(Function &Dispatcher,
                                       Function *Target) {
  if (Dispatcher.isDeclaration() || !Target)
    return false;

  SmallVector<BasicBlock *, 4> DeadBlocks;
  bool Changed = false;
  for (BasicBlock &BB : Dispatcher) {
    auto *SI = dyn_cast<SwitchInst>(BB.getTerminator());
    if (!SI)
      continue;

    for (int I = static_cast<int>(SI->getNumCases()) - 1; I >= 0; --I) {
      auto Case = SI->case_begin() + I;
      BasicBlock *CaseBB = Case->getCaseSuccessor();
      bool CallsTarget = false;
      for (Instruction &Inst : *CaseBB) {
        if (auto *CB = dyn_cast<CallBase>(&Inst)) {
          if (CB->getCalledOperand()->stripPointerCasts() == Target) {
            CallsTarget = true;
            break;
          }
        }
      }
      if (!CallsTarget)
        continue;
      SI->removeCase(Case);
      DeadBlocks.push_back(CaseBB);
      Changed = true;
    }
  }

  for (BasicBlock *BB : DeadBlocks) {
    if (pred_empty(BB))
      BB->eraseFromParent();
  }
  return Changed;
}

static bool RemoveTargetFromGuestPointerTranslator(Module &M,
                                                    Function *Target,
                                                    uint64_t GuestPC) {
  Function *Translator = M.getFunction("__translate_guest_pointer");
  if (!Translator || Translator->isDeclaration() || !Target)
    return false;

  bool Changed = false;
  SmallVector<BasicBlock *, 4> DeadBlocks;
  for (BasicBlock &BB : *Translator) {
    auto *SI = dyn_cast<SwitchInst>(BB.getTerminator());
    if (!SI)
      continue;

    for (int I = static_cast<int>(SI->getNumCases()) - 1; I >= 0; --I) {
      auto Case = SI->case_begin() + I;
      if (Case->getCaseValue()->getZExtValue() != GuestPC)
        continue;

      BasicBlock *CaseBB = Case->getCaseSuccessor();
      PHINode *Result = nullptr;
      for (BasicBlock &Candidate : *Translator) {
        for (Instruction &Inst : Candidate) {
          auto *PN = dyn_cast<PHINode>(&Inst);
          if (!PN)
            continue;
          for (unsigned Incoming = 0; Incoming < PN->getNumIncomingValues();
               ++Incoming) {
            if (PN->getIncomingBlock(Incoming) == CaseBB &&
                PN->getIncomingValue(Incoming)->stripPointerCasts() ==
                    Target) {
              Result = PN;
              break;
            }
          }
          if (Result)
            break;
        }
        if (Result)
          break;
      }
      if (!Result)
        continue;

      Result->removeIncomingValue(CaseBB, false);
      SI->removeCase(Case);
      DeadBlocks.push_back(CaseBB);
      Changed = true;
    }
  }

  for (BasicBlock *BB : DeadBlocks) {
    if (pred_empty(BB))
      BB->eraseFromParent();
  }
  return Changed;
}

// Once `main` is the only native entrypoint, a synthetic sub_*_start routine
// is dead if its only two kinds of uses are the Remill dispatch tables and the
// guest-pointer translator.  Remove those proven-dead edges before generic
// dead-function cleanup; this also prevents the startup path from keeping
// __remill_function_call alive.
static unsigned eraseDeadSyntheticStartupDispatch(Module &M, bool &Changed) {
  if (!M.getFunction("main"))
    return 0;

  SmallVector<Function *, 8> Candidates;
  for (Function &F : M) {
    StringRef Name = F.getName();
    if (F.isDeclaration() || !Name.starts_with("sub_") ||
        !Name.ends_with("_start") || !isLiftedABI(F))
      continue;

    StringRef Rest = Name.drop_front(4);
    size_t Sep = Rest.find('_');
    if (Sep == StringRef::npos)
      continue;
    uint64_t GuestPC = 0;
    if (Rest.substr(0, Sep).getAsInteger(16, GuestPC))
      continue;

    bool OnlyStartupUses = true;
    for (User *U : F.users()) {
      if (!IsStartupOnlyUse(U, &F)) {
        OnlyStartupUses = false;
        break;
      }
    }
    if (OnlyStartupUses)
      Candidates.push_back(&F);
  }

  unsigned Removed = 0;
  for (Function *Target : Candidates) {
    StringRef Name = Target->getName();
    StringRef Rest = Name.drop_front(4);
    uint64_t GuestPC = 0;
    Rest.substr(0, Rest.find('_')).getAsInteger(16, GuestPC);

    bool LocalChanged = false;
    for (StringRef DispatcherName : {StringRef("__remill_function_call"),
                                     StringRef("__remill_jump")}) {
      if (Function *Dispatcher = M.getFunction(DispatcherName))
        LocalChanged |= RemoveTargetFromDispatcher(*Dispatcher, Target);
    }
    LocalChanged |= RemoveTargetFromGuestPointerTranslator(M, Target, GuestPC);
    if (!LocalChanged || !Target->use_empty())
      continue;

    Target->eraseFromParent();
    Changed = true;
    ++Removed;
    errs() << "  synthetic startup dispatch removed: " << Name << "\n";
  }
  return Removed;
}

static unsigned eraseUnusedLiftedGlobals(Module &M, bool &Changed) {
  SmallVector<GlobalAlias *, 32> DeadAliases;
  for (GlobalAlias &GA : M.aliases()) {
    GA.removeDeadConstantUsers();
    if (GA.hasLocalLinkage() && GA.use_empty() &&
        isLiftedGlobalName(GA.getName()))
      DeadAliases.push_back(&GA);
  }
  for (GlobalAlias *GA : DeadAliases) {
    GA->eraseFromParent();
    Changed = true;
  }

  SmallVector<GlobalVariable *, 32> DeadGlobals;
  for (GlobalVariable &GV : M.globals()) {
    if (isLiftedGlobalName(GV.getName()))
      GV.removeDeadConstantUsers();
    if (GV.hasLocalLinkage() && GV.use_empty() &&
        isLiftedGlobalName(GV.getName()))
      DeadGlobals.push_back(&GV);
  }
  for (GlobalVariable *GV : DeadGlobals) {
    GV->eraseFromParent();
    Changed = true;
  }
  return DeadAliases.size() + DeadGlobals.size();
}

static unsigned eraseDeadStateGlobals(Module &M, bool &Changed) {
  SmallVector<GlobalAlias *, 8> DeadAliases;
  for (GlobalAlias &GA : M.aliases()) {
    GA.removeDeadConstantUsers();
    if (GA.getName().contains("__mcsema_reg_state") && GA.use_empty())
      DeadAliases.push_back(&GA);
  }
  for (GlobalAlias *GA : DeadAliases) {
    GA->eraseFromParent();
    Changed = true;
  }

  SmallVector<GlobalVariable *, 8> DeadGlobals;
  for (GlobalVariable &GV : M.globals()) {
    if (!GV.getName().contains("__mcsema_reg_state"))
      continue;
    GV.removeDeadConstantUsers();
    if (GV.use_empty())
      DeadGlobals.push_back(&GV);
  }
  for (GlobalVariable *GV : DeadGlobals) {
    GV->eraseFromParent();
    Changed = true;
  }
  return DeadAliases.size() + DeadGlobals.size();
}

static bool constantContainsStateGlobal(Constant *C, GlobalVariable *GV,
                                        SmallPtrSetImpl<Constant *> &Seen) {
  if (!C || !Seen.insert(C).second)
    return false;
  if (C == GV)
    return true;
  for (Value *Op : C->operands())
    if (auto *Nested = dyn_cast<Constant>(Op))
      if (constantContainsStateGlobal(Nested, GV, Seen))
        return true;
  return false;
}

static bool collectStateGlobalInstructionUsers(
    Value *V, Function *&Owner, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return true;
  for (User *U : V->users()) {
    if (auto *C = dyn_cast<Constant>(U)) {
      if (!collectStateGlobalInstructionUsers(C, Owner, Seen))
        return false;
      continue;
    }
    auto *I = dyn_cast<Instruction>(U);
    if (!I)
      return false;
    if (!Owner)
      Owner = I->getFunction();
    else if (Owner != I->getFunction())
      return false;
    if (isa<CallBase>(I) || isa<PtrToIntInst>(I) || isa<ReturnInst>(I))
      return false;
    if (auto *SI = dyn_cast<StoreInst>(I))
      if (SI->getValueOperand() == V)
        return false;
    if (I->getType()->isPointerTy())
      if (!collectStateGlobalInstructionUsers(I, Owner, Seen))
        return false;
  }
  return true;
}

static Value *materializeStateConstantForAlloca(Constant *C,
                                                GlobalVariable *GV,
                                                AllocaInst *Storage,
                                                Instruction *InsertBefore) {
  if (C == GV)
    return Storage;
  auto *CE = dyn_cast<ConstantExpr>(C);
  if (!CE)
    return C;
  Instruction *Materialized = CE->getAsInstruction();
  for (unsigned I = 0; I < CE->getNumOperands(); ++I) {
    auto *Nested = dyn_cast<Constant>(CE->getOperand(I));
    if (!Nested)
      continue;
    SmallPtrSet<Constant *, 16> Seen;
    if (!constantContainsStateGlobal(Nested, GV, Seen))
      continue;
    Value *Replacement = materializeStateConstantForAlloca(
        Nested, GV, Storage, InsertBefore);
    Materialized->setOperand(I, Replacement);
  }
  Materialized->insertBefore(InsertBefore->getIterator());
  return Materialized;
}

// Once startup/dispatcher functions have been removed, a private McSema State
// object often has users in exactly one native entry function.  Keeping it as
// a global prevents SROA and makes the final IR retain a hidden register file.
// Localize only a non-escaping, single-owner object; O3 can then split its
// constant slots and promote them to ordinary SSA values.
static unsigned localizePrivateStateGlobals(Module &M, bool &Changed) {
  SmallVector<GlobalVariable *, 8> Candidates;
  for (GlobalVariable &GV : M.globals()) {
    if (!GV.getName().contains("__mcsema_reg_state") || GV.isThreadLocal() ||
        !GV.hasInitializer() || containsUndefined(GV.getInitializer()))
      continue;
    Function *Owner = nullptr;
    SmallPtrSet<Value *, 32> Seen;
    if (collectStateGlobalInstructionUsers(&GV, Owner, Seen) && Owner &&
        !Owner->isDeclaration())
      Candidates.push_back(&GV);
  }

  unsigned Localized = 0;
  for (GlobalVariable *GV : Candidates) {
    Function *Owner = nullptr;
    SmallPtrSet<Value *, 32> Seen;
    if (!collectStateGlobalInstructionUsers(GV, Owner, Seen) || !Owner)
      continue;
    IRBuilder<> EB(&*Owner->getEntryBlock().getFirstInsertionPt());
    AllocaInst *Storage = EB.CreateAlloca(GV->getValueType(), nullptr,
                                          "native_state_storage");
    Storage->setAlignment(GV->getAlign().valueOrOne());
    EB.CreateStore(GV->getInitializer(), Storage);

    SmallVector<Instruction *, 128> Instructions;
    for (BasicBlock &BB : *Owner)
      for (Instruction &I : BB)
        Instructions.push_back(&I);
    for (Instruction *I : Instructions) {
      for (unsigned OpNo = 0; OpNo < I->getNumOperands(); ++OpNo) {
        auto *C = dyn_cast<Constant>(I->getOperand(OpNo));
        if (!C)
          continue;
        SmallPtrSet<Constant *, 16> ConstantSeen;
        if (!constantContainsStateGlobal(C, GV, ConstantSeen))
          continue;
        Instruction *InsertBefore = I;
        if (auto *PN = dyn_cast<PHINode>(I)) {
          unsigned Incoming = PN->getIncomingValueNumForOperand(OpNo);
          InsertBefore = PN->getIncomingBlock(Incoming)->getTerminator();
        }
        I->setOperand(OpNo, materializeStateConstantForAlloca(
                                C, GV, Storage, InsertBefore));
      }
    }
    GV->removeDeadConstantUsers();
    if (!GV->use_empty())
      continue;
    GV->eraseFromParent();
    if (isAllocaPromotable(Storage)) {
      DominatorTree DT(*Owner);
      SmallVector<AllocaInst *, 1> Allocas{Storage};
      PromoteMemToReg(Allocas, DT);
    }
    ++Localized;
    Changed = true;
  }
  return Localized;
}

// A McSema module can export both `main` and a synthetic `start`.  Once the
// native entrypoint has been rewritten, keeping the latter makes the module
// expose two competing startup paths and retains a fake State/stack setup.
// Remove it only when the module has a real main and no IR user depends on
// the synthetic symbol; an externally consumed start-only module is left
// untouched and will be diagnosed by strict mode instead.
static unsigned eraseDeadMcsemaEntrypoint(Module &M, bool &Changed) {
  Function *Main = M.getFunction("main");
  Function *Start = M.getFunction("start");
  if (!Main) {
    return 0;
  }

  unsigned Removed = 0;
  auto DropSyntheticConstantUsers = [&](Function *F) {
    if (!F)
      return;
    SmallVector<Use *, 16> ConstantUses;
    for (Use &U : F->uses())
      if (isa<Constant>(U.getUser()) &&
          !isa<GlobalValue>(U.getUser()))
        ConstantUses.push_back(&U);
    for (Use *U : ConstantUses) {
      U->set(Constant::getNullValue(U->get()->getType()));
      Changed = true;
    }
  };

  // The ELF image global embeds addresses of the synthetic startup symbols.
  // Once `main` is the sole entrypoint those constant references are dead
  // data, but they still count as LLVM users and would pin the functions.
  DropSyntheticConstantUsers(Start);
  DropSyntheticConstantUsers(M.getFunction(".init_proc"));
  if (Start && Start->use_empty() && !Start->isDeclaration()) {
    Start->eraseFromParent();
    Changed = true;
    ++Removed;
  }

  for (StringRef Name : {StringRef("start_wrapper"), StringRef(".init_proc")}) {
    if (Function *F = M.getFunction(Name)) {
      if (F->use_empty() && !F->isDeclaration()) {
        F->eraseFromParent();
        Changed = true;
        ++Removed;
      }
    }
  }

  // __mcsema_early_init is a McSema TLS guard with no application-visible
  // result.  Remove calls from surviving native callbacks, then let the
  // normal dead-function cleanup erase the definition if it becomes unused.
  if (Function *Init = M.getFunction("__mcsema_early_init")) {
    SmallVector<CallBase *, 16> Calls;
    for (User *U : Init->users()) {
      if (auto *CB = dyn_cast<CallBase>(U))
        Calls.push_back(CB);
    }
    for (CallBase *CB : Calls) {
      if (!CB->getType()->isVoidTy())
        continue;
      CB->eraseFromParent();
      Changed = true;
      ++Removed;
    }
    if (Init->use_empty() && !Init->isDeclaration()) {
      Init->eraseFromParent();
      Changed = true;
      ++Removed;
    }
  }
  return Removed;
}

// Replace a fake module-wide guest stack with a real, exactly-sized native
// frame only when the complete pointer-use graph is statically auditable.
// This deliberately handles the small constant-address subset first.  Any
// integer carrier, dynamic GEP, call/escape, cross-function use, or observable
// zero-initialized read rejects the whole backing transaction.
struct ProvenFrameAccess {
  Instruction *Inst = nullptr;
  unsigned PointerOperand = 0;
  int64_t Begin = 0;
  int64_t End = 0;
  bool Reads = false;
  bool Writes = false;
};

static bool addSignedOffset(int64_t Base, int64_t Delta, int64_t &Result) {
  if ((Delta > 0 && Base > std::numeric_limits<int64_t>::max() - Delta) ||
      (Delta < 0 && Base < std::numeric_limits<int64_t>::min() - Delta))
    return false;
  Result = Base + Delta;
  return true;
}

static bool proveConstantFrameBacking(GlobalVariable &Backing,
                                      SmallVectorImpl<ProvenFrameAccess> &Out,
                                      Function *&Owner, uint64_t &ObjectSize) {
  auto *AT = dyn_cast<ArrayType>(Backing.getValueType());
  if (!AT || !AT->getElementType()->isIntegerTy(8) ||
      !Backing.hasInternalLinkage() || !Backing.hasInitializer() ||
      !Backing.getInitializer()->isNullValue())
    return false;

  ObjectSize = AT->getNumElements();
  if (!ObjectSize || ObjectSize > uint64_t(std::numeric_limits<int64_t>::max()))
    return false;
  const DataLayout &DL = Backing.getParent()->getDataLayout();
  std::set<std::pair<Value *, int64_t>> Visited;

  std::function<bool(Value *, int64_t)> Walk = [&](Value *Pointer,
                                                    int64_t Offset) {
    if (!Visited.insert({Pointer, Offset}).second)
      return true;
    for (User *U : Pointer->users()) {
      if (auto *GEP = dyn_cast<GEPOperator>(U)) {
        if (GEP->getPointerOperand() != Pointer)
          return false;
        unsigned Bits = DL.getIndexSizeInBits(GEP->getPointerAddressSpace());
        APInt Delta(Bits, 0, true);
        if (!GEP->accumulateConstantOffset(DL, Delta) ||
            !Delta.isSignedIntN(64))
          return false;
        int64_t Next = 0;
        if (!addSignedOffset(Offset, Delta.getSExtValue(), Next) ||
            !Walk(cast<Value>(U), Next))
          return false;
        continue;
      }
      if (auto *BC = dyn_cast<BitCastOperator>(U)) {
        if (BC->getOperand(0) != Pointer || !Walk(cast<Value>(U), Offset))
          return false;
        continue;
      }

      auto AddAccess = [&](Instruction *I, unsigned PointerOperand,
                           Type *AccessTy, bool Reads, bool Writes) {
        TypeSize Size = DL.getTypeStoreSize(AccessTy);
        if (Size.isScalable() || Size.getFixedValue() == 0 ||
            Size.getFixedValue() > uint64_t(std::numeric_limits<int64_t>::max()))
          return false;
        int64_t End = 0;
        if (Offset < 0 ||
            !addSignedOffset(Offset, int64_t(Size.getFixedValue()), End) ||
            uint64_t(End) > ObjectSize)
          return false;
        Function *F = I->getFunction();
        if (!F || (Owner && Owner != F))
          return false;
        Owner = F;
        Out.push_back({I, PointerOperand, Offset, End, Reads, Writes});
        return true;
      };

      if (auto *LI = dyn_cast<LoadInst>(U)) {
        if (LI->getPointerOperand() != Pointer || LI->isVolatile() ||
            LI->isAtomic() || !AddAccess(LI, 0, LI->getType(), true, false))
          return false;
        continue;
      }
      if (auto *SI = dyn_cast<StoreInst>(U)) {
        if (SI->getValueOperand() == Pointer ||
            SI->getPointerOperand() != Pointer || SI->isVolatile() ||
            SI->isAtomic() ||
            !AddAccess(SI, 1, SI->getValueOperand()->getType(), false, true))
          return false;
        continue;
      }
      // Calls (including memory intrinsics) are intentionally left for the
      // affine/nocapture phase.  Accepting them here would need length and
      // capture proofs, not a name-based exception.
      return false;
    }
    return true;
  };

  return Walk(&Backing, 0) && Owner && !Out.empty();
}

static bool readsAreDominatedByWrites(ArrayRef<ProvenFrameAccess> Accesses,
                                      Function &Owner) {
  DominatorTree DT(Owner);
  for (const ProvenFrameAccess &Read : Accesses) {
    if (!Read.Reads)
      continue;
    SmallVector<std::pair<int64_t, int64_t>, 8> Covered;
    for (const ProvenFrameAccess &Write : Accesses) {
      if (!Write.Writes || Write.Inst == Read.Inst ||
          !DT.dominates(Write.Inst, Read.Inst))
        continue;
      int64_t Begin = std::max(Read.Begin, Write.Begin);
      int64_t End = std::min(Read.End, Write.End);
      if (Begin < End)
        Covered.push_back({Begin, End});
    }
    llvm::sort(Covered);
    int64_t Cursor = Read.Begin;
    for (auto [Begin, End] : Covered) {
      if (Begin > Cursor)
        break;
      Cursor = std::max(Cursor, End);
      if (Cursor >= Read.End)
        break;
    }
    // The old backing is zero-initialized.  A byte not definitely written on
    // every path cannot become an uninitialized native-stack byte.
    if (Cursor < Read.End)
      return false;
  }
  return true;
}

static unsigned compactProvenConstantFrameBackings(Module &M, bool &Changed) {
  SmallVector<GlobalVariable *, 8> Candidates;
  for (GlobalVariable &GV : M.globals())
    if (GV.getName().starts_with("frame_storage_backing."))
      Candidates.push_back(&GV);

  unsigned Compacted = 0;
  for (GlobalVariable *Backing : Candidates) {
    SmallVector<ProvenFrameAccess, 16> Accesses;
    Function *Owner = nullptr;
    uint64_t ObjectSize = 0;
    if (!proveConstantFrameBacking(*Backing, Accesses, Owner, ObjectSize) ||
        !readsAreDominatedByWrites(Accesses, *Owner))
      continue;

    int64_t Min = Accesses.front().Begin;
    int64_t Max = Accesses.front().End;
    Align FrameAlign = Backing->getAlign().valueOrOne();
    for (const ProvenFrameAccess &Access : Accesses) {
      Min = std::min(Min, Access.Begin);
      Max = std::max(Max, Access.End);
      if (auto *LI = dyn_cast<LoadInst>(Access.Inst))
        FrameAlign = std::max(FrameAlign, LI->getAlign());
      else if (auto *SI = dyn_cast<StoreInst>(Access.Inst))
        FrameAlign = std::max(FrameAlign, SI->getAlign());
    }
    uint64_t FrameSize = uint64_t(Max - Min);
    if (!FrameSize)
      continue;
    ArrayType *FrameTy = ArrayType::get(Type::getInt8Ty(M.getContext()),
                                        FrameSize);
    IRBuilder<> EntryBuilder(&*Owner->getEntryBlock().getFirstInsertionPt());
    AllocaInst *Frame = EntryBuilder.CreateAlloca(
        FrameTy, nullptr, Backing->getName() + ".native_frame");
    Frame->setAlignment(FrameAlign);

    for (const ProvenFrameAccess &Access : Accesses) {
      IRBuilder<> B(Access.Inst);
      Value *Local = B.CreateInBoundsGEP(
          FrameTy, Frame,
          {B.getInt64(0), B.getInt64(uint64_t(Access.Begin - Min))},
          "native.frame.slot");
      Access.Inst->setOperand(Access.PointerOperand, Local);
    }
    Backing->removeDeadConstantUsers();
    if (!Backing->use_empty())
      report_fatal_error("proven frame compaction left an unexpected use");
    Backing->eraseFromParent();
    ++Compacted;
    Changed = true;
  }
  return Compacted;
}

} // namespace

bool NativeCleanupPass::cleanupModule(Module &M, bool EnforceStrict) {
  // The final pipeline element is a verifier, not a second recovery pass.
  // Running the mutation pipeline again after O3 hides phase-ownership bugs.
  if (EnforceStrict) {
    reportNativeContract(M, 0, 0, true);
    return false;
  }

  bool Changed = false;
  SmallVector<std::string, 32> Violations;
  // Recovered guest ranges are required by the later scanf/external-pointer
  // lowering.  Strip them only after every such use has been materialized.
  stripRemillMetadata(M, Changed, false);

  unsigned DeadArguments = canonicalizeDeadLiftedArguments(M);
  if (DeadArguments) {
    Changed = true;
    errs() << "  dead lifted poison arguments canonicalized: " << DeadArguments
           << "\n";
  }

  unsigned RecoveredPhiValues = canonicalizeEquivalentPhiUndefined(M);
  if (RecoveredPhiValues) {
    Changed = true;
    errs() << "  equivalent PHI undef/poison values recovered: "
           << RecoveredPhiValues << "\n";
  }

  unsigned FrozenUndefined = freezeUndefinedInstructionOperands(M);
  if (FrozenUndefined) {
    Changed = true;
    errs() << "  undef/poison operands frozen: " << FrozenUndefined << "\n";
  }
  unsigned UndefinedScaffolds = lowerFullyOverwrittenUndefinedScaffolds(M);
  if (UndefinedScaffolds) {
    Changed = true;
    errs() << "  fully-overwritten undef/poison scaffolds normalized: "
           << UndefinedScaffolds << "\n";
  }
  unsigned UndefinedShuffleLanes = lowerUnobservedUndefinedShuffleLanes(M);
  if (UndefinedShuffleLanes) {
    Changed = true;
    errs() << "  unobserved undef/poison shuffle lanes normalized: "
           << UndefinedShuffleLanes << "\n";
  }
  unsigned VectorBroadcasts = lowerSingleLaneVectorBroadcasts(M);
  if (VectorBroadcasts) {
    Changed = true;
    errs() << "  single-lane vector broadcasts normalized: "
           << VectorBroadcasts << "\n";
  }

  // Pointer-translation lowering needs the entry stack anchor to exist before
  // it rewrites State-derived RSP/RBP addresses.  The entrypoint normalization
  // itself remains late so cleanup still sees the original public `main`.
  ensureNativeEntrypointStackStorage(M);
  unsigned NativeTranslations =
      rewriteNativeScanfVarargAddresses(M, Changed);
  NativeTranslations += lowerProvenNativePointerTranslations(M, Changed);
  if (NativeTranslations)
    errs() << "  proven native pointer translations lowered: "
           << NativeTranslations << "\n";

  unsigned InlinedExternWrappers = inlineExternalLiftedWrappers(M, Changed);
  if (InlinedExternWrappers)
    errs() << "  external lifted wrappers inlined: "
           << InlinedExternWrappers << "\n";

  // Normalize libc arms in a surviving runtime-PC dispatcher before
  // State-SSA plans and rewrites its call graph.  Deferring this until after
  // State-SSA makes RewriteExternalNativeCalls reject the dispatcher plan
  // transaction on lifted variadic declarations such as vscanf.lifted_abi.
  unsigned EarlyNativeExternalABIs =
      normalizeNativeExternalABIs(M, Changed, &Violations);
  if (EarlyNativeExternalABIs)
    errs() << "  early native libc call ABIs normalized: "
           << EarlyNativeExternalABIs << "\n";

  unsigned NativeDataPointers = materializeNativeSegmentPointers(M, Changed);
  if (NativeDataPointers)
    errs() << "  segment pointers materialized as native data: "
           << NativeDataPointers << "\n";

  // Strict mode is the production contract: do not let the old internal
  // State-pointer ABI survive merely because the optional optimization flag
  // was omitted.
  if (NativeStateSSA || NativeStrict) {
    bool StateSSAChanged = lowerNativeStateABI(M);
    if (StateSSAChanged) {
      Changed = true;
      errs() << "  native State ABI lowered to explicit SSA slots\n";
    }
    // Entrypoint wrappers can contain scratch State/stack buffers even when
    // no additional `.native` function needed an SSA clone in this pass.
    if (lowerNativeMainStateBuffer(M)) {
      Changed = true;
      errs() << "  native entrypoint State scratch buffer removed\n";
    }
    if (lowerNativeMainStackBuffer(M)) {
      Changed = true;
      errs() << "  oversized guest stack scratch buffer lowered\n";
    }

    if (lowerNativeStackAddresses(M))
      Changed = true;
    unsigned NativeDataStackPointers = rewriteNativeDataStackGEPs(M, Changed);
    if (NativeDataStackPointers)
      errs() << "  translated stack GEPs rebased on native_stack: "
             << NativeDataStackPointers << "\n";
    if (cleanupNativeDeadInstructions(M))
      Changed = true;

    unsigned PreservedRBP = preserveNativeRBPOutputs(M, Changed);
    if (PreservedRBP)
      errs() << "  callee-saved native RBP outputs preserved: "
             << PreservedRBP << "\n";

    // Remove the analysis-only return markers before ABI normalization.  They
    // are hidden LLVM uses of old external call results and would otherwise
    // make a dead `free` return look live.
    unsigned EarlyReturnMarkers = eraseBrightenReturnMarkers(M, Changed);
    if (EarlyReturnMarkers)
      errs() << "  early transient RAX return markers erased: "
             << EarlyReturnMarkers << "\n";

    unsigned AllocatorRAX = repairNativeAllocatorRAX(M, Changed);
    if (AllocatorRAX)
      errs() << "  allocator return values restored in native RAX SSA: "
             << AllocatorRAX << "\n";

    unsigned NativeExternalABIs = normalizeNativeExternalABIs(
        M, Changed, &Violations);
    if (NativeExternalABIs)
      errs() << "  native libc call ABIs normalized: " << NativeExternalABIs
             << "\n";

    // State-ABI lowering can synthesize the final guest-base + dynamic-index
    // expression after the first cleanup sweep.  Rewrite its scanf save-slot
    // use after that lowering as well, while the recovered-global provenance
    // metadata is still available.
    unsigned LateScanfPointers = rewriteNativeScanfVarargAddresses(M, Changed);
    if (LateScanfPointers)
      errs() << "  late native scanf pointer addresses lowered: "
             << LateScanfPointers << "\n";
    // Keep recovered typed globals as distinct native objects.  Replacing
    // them with a byte-preserving whole-segment copy destroys the very type
    // recovery this phase established and reintroduces ELF image blobs.
    unsigned ExternalPointers =
        rewriteRecoveredExternalPointerArguments(M, Changed);
    if (ExternalPointers)
      errs() << "  recovered external pointer arguments lowered: "
             << ExternalPointers << "\n";
    unsigned VarargPointers = rewriteRecoveredVarargSaveSlots(M, Changed);
    if (VarargPointers)
      errs() << "  recovered variadic pointer save slots lowered: "
             << VarargPointers << "\n";
    unsigned LateGuestPointers = rewriteDynamicGuestAddressIntToPtr(M, Changed);
    if (LateGuestPointers)
      errs() << "  late dynamic guest pointers lowered: " << LateGuestPointers
             << "\n";
    unsigned RawNativeStackPointers = lowerRawNativeStackIntToPtrs(M, Changed);
    if (RawNativeStackPointers)
      errs() << "  raw guest stack inttoptrs lowered: "
             << RawNativeStackPointers << "\n";
    unsigned ResidualGuestPointers =
        rewriteResidualRecoveredDataIntToPtrs(M, Changed);
    if (ResidualGuestPointers)
      errs() << "  residual guest data inttoptrs lowered: "
             << ResidualGuestPointers << "\n";
  }

  unsigned DeadStateAllocas = eraseDeadStateAllocas(M, Changed);
  if (DeadStateAllocas)
    errs() << "  dead State allocas erased: " << DeadStateAllocas << "\n";
  unsigned ReturnMarkers = eraseBrightenReturnMarkers(M, Changed);
  if (ReturnMarkers)
    errs() << "  transient RAX return markers erased: " << ReturnMarkers
           << "\n";

  unsigned DeadRIPAliases = rewriteDeadRIPDataAliases(M, Changed);
  if (DeadRIPAliases)
    errs() << "  dead RIP data carriers replaced by incoming RIP: "
           << DeadRIPAliases << "\n";

  unsigned GuestIdentityAliases =
      rewriteGuestAddressIdentityAliasIntegers(M, Changed);
  if (GuestIdentityAliases)
    errs() << "  guest address identity aliases lowered: "
           << GuestIdentityAliases << "\n";

  unsigned DataAliases = rewriteRemainingDataAliasesToNativeSegments(M, Changed);
  if (DataAliases)
    errs() << "  remaining guest data aliases lowered: " << DataAliases << "\n";

  unsigned ConstantGuestPointers =
      rewriteConstantGuestPointerOperands(M, Changed);
  if (ConstantGuestPointers)
    errs() << "  constant guest pointers lowered: " << ConstantGuestPointers
           << "\n";

  unsigned ExactNativeSegmentGEPs =
      rewriteExactNativeSegmentGEPs(M, Changed);
  if (ExactNativeSegmentGEPs)
    errs() << "  exact native segment GEPs rewritten: "
           << ExactNativeSegmentGEPs << "\n";

  unsigned EntrypointArtifacts = eraseDeadMcsemaEntrypoint(M, Changed);
  if (EntrypointArtifacts) {
    errs() << "  McSema entrypoint artifacts removed: "
           << EntrypointArtifacts << "\n";
  }

  unsigned StartupDispatches = eraseDeadSyntheticStartupDispatch(M, Changed);
  if (StartupDispatches) {
    errs() << "  synthetic startup dispatches removed: "
           << StartupDispatches << "\n";
  }

  lowerNativeCallbackTrampolines(M, Changed);
  eraseDeadInlineAsmTrampolines(M, Changed);
  eraseUnusedInlineAsmCalls(M, Changed);
  eraseUnusedInternalGlobals(M, Changed);

  unsigned RemovedFunctions = 0;
  // Removing a native clone can make its Remill dispatcher dead, which can
  // in turn make another lifted helper dead.  Iterate to a fixed point so a
  // single cleanup pass does not leave a second-order dispatcher behind.
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedFunctions(M, Changed);
    RemovedFunctions += RemovedThisRound;
    if (!RemovedThisRound)
      break;
  }
  unsigned PreservedEntrypointBoundary =
      preserveNativeEntrypointStateBoundary(M, Changed);
  if (PreservedEntrypointBoundary)
    errs() << "  native entry State-ABI boundaries kept opaque: "
           << PreservedEntrypointBoundary << "\n";
  unsigned PreservedNestedBoundaries =
      preserveNestedNativeFrameBoundaries(M, Changed);
  if (PreservedNestedBoundaries)
    errs() << "  nested native frame boundaries kept opaque: "
           << PreservedNestedBoundaries << "\n";
  normalizeNativeEntrypoint(M, Changed);
  unsigned CompactedFrames = compactProvenConstantFrameBackings(M, Changed);
  if (CompactedFrames)
    errs() << "  proven fake stack backings converted to native frames: "
           << CompactedFrames << "\n";
  // Run the proven startup cleanup once more after dead lifted-function
  // cleanup; otherwise `.init_proc`/`start` can remain externally visible
  // roots and keep their State global alive. Entrypoint ABI recovery belongs
  // to pass 050, and cleanup must never fabricate a guest-stack backing store.
  unsigned LateEntrypointArtifacts = eraseDeadMcsemaEntrypoint(M, Changed);
  if (LateEntrypointArtifacts) {
    RemovedFunctions += LateEntrypointArtifacts;
    errs() << "  late McSema entrypoint artifacts removed: "
           << LateEntrypointArtifacts << "\n";
  }
  unsigned LateStartupDispatches =
      eraseDeadSyntheticStartupDispatch(M, Changed);
  if (LateStartupDispatches) {
    RemovedFunctions += LateStartupDispatches;
    errs() << "  late synthetic startup dispatches removed: "
           << LateStartupDispatches << "\n";
  }
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedFunctions(M, Changed);
    RemovedFunctions += RemovedThisRound;
    if (!RemovedThisRound)
      break;
  }
  unsigned LocalizedStateGlobals = localizePrivateStateGlobals(M, Changed);
  if (LocalizedStateGlobals)
    errs() << "  private State globals localized: "
           << LocalizedStateGlobals << "\n";
  unsigned RemovedGlobals = 0;
  unsigned RemovedStateGlobals = 0;
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedGlobals(M, Changed);
    unsigned RemovedStateThisRound = eraseDeadStateGlobals(M, Changed);
    RemovedGlobals += RemovedThisRound;
    RemovedStateGlobals += RemovedStateThisRound;
    if (!RemovedThisRound && !RemovedStateThisRound)
      break;
  }
  eraseUnusedInternalGlobals(M, Changed);
  unsigned NativeDataArtifacts = eraseUnusedNativeDataArtifacts(M, Changed);
  if (NativeDataArtifacts)
    errs() << "  unused native segment artifacts removed: "
           << NativeDataArtifacts << "\n";
  for (;;) {
    unsigned RemovedThisRound = eraseUnusedLiftedFunctions(M, Changed);
    RemovedFunctions += RemovedThisRound;
    if (!RemovedThisRound)
      break;
  }
  if (RemovedStateGlobals)
    errs() << "  dead State globals removed: " << RemovedStateGlobals << "\n";

  // No recovery step below this point consumes guest-range provenance; remove
  // it now so the final NativeStrict contract remains metadata-free.
  stripRemillMetadata(M, Changed);
  foldExactPointerRoundTrips(M, Changed);
  reportNativeContract(M, RemovedFunctions, RemovedGlobals, false);

  return Changed;
}

} // namespace brighten_native_cleanup
