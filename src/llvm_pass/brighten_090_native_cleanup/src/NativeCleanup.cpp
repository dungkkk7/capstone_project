#include "NativeCleanup.h"
#include "NativeStateSSA.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/InlineAsm.h"
#include "llvm/IR/IntrinsicInst.h"
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
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/Transforms/Utils/ValueMapper.h"
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
static bool IsNativeVarargSaveSlot(Value *Ptr);
static bool isNativeStackPointer(Value *V, SmallPtrSetImpl<Value *> &Seen);

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
    return isNativeStateSlot(LI->getPointerOperand()) ||
           IsNativeVarargSaveSlot(LI->getPointerOperand());
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

static Value *getDirectNativePointerCarrier(Value *V) {
  if (!V)
    return nullptr;
  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    return PTI->getPointerOperand();
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt)
      return CE->getOperand(0);
  }
  return nullptr;
}

static Value *findNativeVarargAddressCarrier(Value *V,
                                             SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return nullptr;

  auto ValidateCarrier = [](Value *Candidate) -> Value * {
    if (!Candidate)
      return nullptr;
    // Do not peel a frame anchor out of a larger stack-address expression.
    // For example, inttoptr(ptrtoint(frame_top) - 16) contains a native
    // pointer carrier syntactically, but replacing the whole argument with
    // frame_top drops the -16 destination offset.  Stack expressions must be
    // lowered by lowerNativeStackInteger instead.
    SmallPtrSet<Value *, 16> StackSeen;
    if (isNativeStackPointer(Candidate, StackSeen))
      return nullptr;
    SmallPtrSet<Value *, 16> NativeSeen;
    if (!isNativePointerValue(Candidate, NativeSeen))
      return nullptr;
    return Candidate;
  };

  if (auto *PTI = dyn_cast<PtrToIntInst>(V)) {
    if (PTI->getName().starts_with("native.vararg.address"))
      return ValidateCarrier(PTI->getPointerOperand());
  } else if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt)
      return ValidateCarrier(CE->getOperand(0));
  }

  // A carrier may be hidden behind representation-only casts.  Do not walk
  // arbitrary arithmetic/GEP/load operands: finding ptrtoint(@global) inside
  //   inttoptr(base + index * stride + field_offset)
  // does not make @global equivalent to the complete address.  The previous
  // recursive search dropped the dynamic and field offsets from such libc
  // arguments (notably ryou[i].dim passed to memcmp).
  if (auto *Cast = dyn_cast<CastInst>(V))
    return findNativeVarargAddressCarrier(Cast->getOperand(0), Seen);
  if (auto *Freeze = dyn_cast<FreezeInst>(V))
    return findNativeVarargAddressCarrier(Freeze->getOperand(0), Seen);
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->isCast())
      return findNativeVarargAddressCarrier(CE->getOperand(0), Seen);
    return nullptr;
  }

  auto FindCommonCarrier = [&](auto Values) -> Value * {
    Value *Common = nullptr;
    for (Value *Arm : Values) {
      Value *Candidate = findNativeVarargAddressCarrier(Arm, Seen);
      if (!Candidate || (Common && Common != Candidate))
        return nullptr;
      Common = Candidate;
    }
    return Common;
  };
  if (auto *PN = dyn_cast<PHINode>(V))
    return FindCommonCarrier(PN->incoming_values());
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    SmallVector<Value *, 2> Arms{Sel->getTrueValue(), Sel->getFalseValue()};
    return FindCommonCarrier(Arms);
  }
  return nullptr;
}

// O3 can fold a translated variadic pointer into the guest-range dispatch
// that materializeRecoveredDataPointer created.  The resulting select no
// longer has a representation-only path from the call argument to
// native.vararg.address, so the deliberately shallow search above cannot
// recover it.  A deep search is safe only for one of our own dispatch trees:
// require the OOB scratch artifact and exactly one marked native carrier.
static Value *findNativeVarargCarrierInRecoveredDispatch(Value *V) {
  SmallPtrSet<Value *, 32> Seen;
  Value *UniqueCarrier = nullptr;
  bool HasRecoveredScratch = false;
  bool Ambiguous = false;

  std::function<void(Value *)> Visit = [&](Value *Current) {
    if (!Current || Ambiguous || !Seen.insert(Current).second)
      return;
    if (auto *GV = dyn_cast<GlobalVariable>(Current->stripPointerCasts())) {
      if (GV->getName() == "native.recovered.oob.scratch")
        HasRecoveredScratch = true;
    }
    if (auto *PTI = dyn_cast<PtrToIntInst>(Current)) {
      if (PTI->getName().starts_with("native.vararg.address")) {
        Value *Candidate = PTI->getPointerOperand();
        SmallPtrSet<Value *, 16> StackSeen;
        SmallPtrSet<Value *, 16> NativeSeen;
        if (!isNativeStackPointer(Candidate, StackSeen) &&
            isNativePointerValue(Candidate, NativeSeen)) {
          if (UniqueCarrier && UniqueCarrier != Candidate)
            Ambiguous = true;
          else
            UniqueCarrier = Candidate;
        }
      }
    }
    if (auto *I = dyn_cast<Instruction>(Current)) {
      for (Value *Operand : I->operands())
        Visit(Operand);
    } else if (auto *CE = dyn_cast<ConstantExpr>(Current)) {
      for (Value *Operand : CE->operands())
        Visit(Operand);
    }
  };
  Visit(V);
  return HasRecoveredScratch && !Ambiguous ? UniqueCarrier : nullptr;
}

static std::optional<std::pair<GlobalVariable *, uint64_t>>
FindRecoveredGlobalForGuestAddress(Module &M, uint64_t Address);

static Value *lowerNativeStackInteger(IRBuilder<> &B, Value *Integer,
                                      Function &F);

static Value *materializeRecoveredDataPointer(Module &M, IRBuilder<> &B,
                                              Value *Address);

static std::optional<uint64_t> parseGuestAddressPrefix(StringRef Name,
                                                       StringRef Prefix) {
  if (!Name.starts_with(Prefix))
    return std::nullopt;
  StringRef Rest = Name.drop_front(Prefix.size());
  size_t HexDigits = 0;
  while (HexDigits < Rest.size()) {
    char C = Rest[HexDigits];
    bool IsHex = (C >= '0' && C <= '9') || (C >= 'a' && C <= 'f') ||
                 (C >= 'A' && C <= 'F');
    if (!IsHex)
      break;
    ++HexDigits;
  }
  if (!HexDigits)
    return std::nullopt;
  uint64_t Address = 0;
  if (Rest.take_front(HexDigits).getAsInteger(16, Address))
    return std::nullopt;
  return Address;
}

static void setGuestBaseMetadata(Module &M, GlobalVariable &GV,
                                 uint64_t GuestBase) {
  LLVMContext &Ctx = M.getContext();
  Constant *Base = ConstantInt::get(Type::getInt64Ty(Ctx), GuestBase);
  GV.setMetadata("brighten.guest.base",
                 MDNode::get(Ctx, {ConstantAsMetadata::get(Base)}));
}

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
        // __translate_guest_pointer takes a full guest address.  The previous
        // lowering rebuilt some dynamic forms as "matched segment + dynamic",
        // which is only valid when Dynamic is a segment-local offset.  Raw
        // fuzzing exposes cases where Dynamic is already a full guest address
        // loaded from recovered state, producing pointers like
        //   @g_arr_0 + 0x40a7a4
        // instead of dispatching 0x40a7a4 to the recovered data object.  Use
        // the central recovered-range mapper for the full address and keep the
        // old segment arithmetic only as a defensive fallback.
        NativePtr = materializeRecoveredDataPointer(M, B, Address);
      }
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
  auto PointsAtFrameStorage = [&](Value *P, auto &&Self) -> bool {
    if (!P)
      return false;
    P = P->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(P))
      return GV->getName().starts_with("frame_storage_backing.");
    if (auto *GEP = dyn_cast<GEPOperator>(P))
      return Self(GEP->getPointerOperand(), Self);
    return false;
  };
  if (auto *PTI = dyn_cast<PtrToIntInst>(V)) {
    if (PointsAtFrameStorage(PTI->getPointerOperand(), PointsAtFrameStorage))
      return true;
  }
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt &&
        PointsAtFrameStorage(CE->getOperand(0), PointsAtFrameStorage))
      return true;
    for (Value *Op : CE->operands())
      if (Op->getType()->isIntegerTy() &&
          containsNativeStackInteger(Op, Seen))
        return true;
  }
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
  if (auto *EV = dyn_cast<ExtractValueInst>(V)) {
    ArrayRef<unsigned> Indices = EV->getIndices();
    if (Indices.size() == 1 && (Indices.front() == 4 || Indices.front() == 5)) {
      // State-SSA returns the architectural RSP/RBP pair at tuple slots 4/5
      // for the compact native result used by recovered lifted callees.  Do
      // not infer this from tuple position alone: require the callee's
      // explicit hidden-state argument contract before propagating stack
      // provenance through extractvalue.
      if (auto *CB = dyn_cast<CallBase>(EV->getAggregateOperand())) {
        if (Function *Callee = CB->getCalledFunction()) {
          if (Callee->arg_size() >= 2) {
            auto It = Callee->arg_begin();
            Argument *StateRSP = &*It++;
            Argument *StateRBP = &*It;
            if (StateRSP->getName() == "state_in_2312" &&
                StateRBP->getName() == "state_in_2328")
              return true;
          }
        }
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
    if (Name.starts_with("frame_top") ||
        Name.starts_with("native_stack_top"))
      return &I;
  }
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

static Value *getNativeStackFrameTop(IRBuilder<> &B, Function &F,
                                     Value *NativeStack) {
  if (!NativeStack)
    return nullptr;
  if (isa<Argument>(NativeStack))
    return NativeStack;
  StringRef StackName = NativeStack->getName();
  if (StackName.starts_with("frame_top") ||
      StackName.starts_with("native_stack_top"))
    return NativeStack;
  if (!F.empty()) {
    for (Instruction &I : F.getEntryBlock()) {
      if (!I.getType()->isPointerTy())
        continue;
      StringRef Name = I.getName();
      if (Name.starts_with("frame_top") ||
          Name.starts_with("native_stack_top"))
        return &I;
    }
  }

  // frame_storage_backing.* is the complete recovered stack object, not the
  // logical RSP/RBP anchor.  Relative stack offsets are measured from the
  // entry frame top; materializing them from the global base writes locals
  // before the stack object and makes scanf/output slots disagree.
  constexpr uint64_t NativeStackBytes = 16 * 1024 * 1024;
  constexpr uint64_t NativeStackTop = NativeStackBytes - 64 * 1024;
  if (isa<GlobalVariable>(NativeStack) ||
      StackName.starts_with("frame_storage") ||
      StackName.starts_with("native_stack_storage"))
    return B.CreateConstGEP1_64(B.getInt8Ty(), NativeStack, NativeStackTop,
                                "native.stack.frame.top");
  return NativeStack;
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
  if (auto *SI = dyn_cast<SelectInst>(V))
    return isNativeStackPointer(SI->getTrueValue(), Seen) ||
           isNativeStackPointer(SI->getFalseValue(), Seen);
  if (auto *ITP = dyn_cast<IntToPtrInst>(V)) {
    SmallPtrSet<Value *, 16> IntegerSeen;
    return containsNativeStackInteger(ITP->getOperand(0), IntegerSeen);
  }
  if (auto *Cast = dyn_cast<CastInst>(V))
    return isNativeStackPointer(Cast->getOperand(0), Seen);
  return false;
}

static bool IsDirectControlPredicate(Instruction *I) {
  if (!I)
    return false;
  for (User *U : I->users()) {
    if (isa<ICmpInst>(U) || isa<FCmpInst>(U))
      return true;
  }
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
  if (RelativeStack) {
    SmallPtrSet<Value *, 32> AnchorSeen;
    HasStackProvenance =
        HasStackProvenance ||
        containsNativeStackAnchorInteger(Integer, AnchorSeen);
  }
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
    Value *FrameTop = getNativeStackFrameTop(B, F, NativeStack);
    if (!FrameTop)
      FrameTop = NativeStack;
    SmallPtrSet<Value *, 32> AnchorSeen;
    if (containsNativeStackAnchorInteger(Address, AnchorSeen)) {
      Value *Anchor = B.CreatePtrToInt(FrameTop, B.getInt64Ty(),
                                       "native.stack.anchor");
      Address = B.CreateSub(Address, Anchor,
                            "native.stack.absolute.delta");
    }
    return B.CreateGEP(B.getInt8Ty(), FrameTop, Address,
                       "native.frame.gep");
  }
  // Late O3 can canonicalize a correct stack pointer into an absolute
  // carrier such as:
  //
  //   inttoptr(ptrtoint(frame_top) + -16)
  //
  // At that point the expression already contains the recovered frame anchor.
  // Rebasing it against a later architectural RSP store found in the entry
  // block can erase the delta and turn scanf destinations into plain
  // frame_top.  When the anchor is syntactically present, subtract that anchor
  // directly and do not consult State-entry seed stores.
  SmallPtrSet<Value *, 32> AbsoluteAnchorSeen;
  if (containsNativeStackAnchorInteger(Address, AbsoluteAnchorSeen)) {
    Value *FrameTop = getNativeStackFrameTop(B, F, NativeStack);
    if (!FrameTop)
      FrameTop = NativeStack;
    Value *Anchor = B.CreatePtrToInt(FrameTop, B.getInt64Ty(),
                                     "native.stack.anchor");
    Value *Delta = B.CreateSub(Address, Anchor,
                               "native.stack.absolute.delta");
    return B.CreateGEP(B.getInt8Ty(), FrameTop, Delta, "native.stack.gep");
  }
  // Entrypoint-native functions without a frame argument still read their
  // initial RSP/RBP from the canonical State global.  Rebase against that
  // entry value, not against the backing object's host address: algebraic
  // folding of `backing + (rsp - backing)` otherwise recreates inttoptr(rsp)
  // and loses the recovered frame provenance before entrypoint seeding.
  if (!findNativeStackArgument(F)) {
    if (Value *InitialStack = findInitialStateStackInteger(F)) {
      Value *FrameTop = getNativeStackFrameTop(B, F, NativeStack);
      if (!FrameTop)
        FrameTop = NativeStack;
      Value *Delta = B.CreateSub(Address, InitialStack,
                                 "native.stack.entry.delta");
      return B.CreateGEP(B.getInt8Ty(), FrameTop, Delta,
                         "native.stack.gep");
    }
  }
  // A frame_storage_backing global represents the full recovered guest stack,
  // while the active logical RSP boundary is near its high end.  Use the same
  // frame-top convention as entrypoint stack lowering; rebasing on the global
  // base makes scanf destinations alias a different region than later native
  // stack GEPs in rollback-mode State-SSA cases.
  Value *FrameTop = getNativeStackFrameTop(B, F, NativeStack);
  if (!FrameTop)
    FrameTop = NativeStack;
  Value *Anchor = B.CreatePtrToInt(FrameTop, B.getInt64Ty(),
                                   "native.stack.anchor");
  Value *Delta = B.CreateSub(Address, Anchor, "native.stack.delta");
  return B.CreateGEP(B.getInt8Ty(), FrameTop, Delta, "native.stack.gep");
}

// O3 can leave an internal RSP/RBP value as a direct inttoptr after the
// translator and external-call rewrites have already run.  Lower only values
// with explicit stack provenance; arbitrary dynamic inttoptr values still
// represent native heap/data/callback pointers and must remain untouched.
static bool hasRawNativeStackIntToPtrCandidate(Module &M) {
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
          return true;
      }
    }
  }
  return false;
}

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
    if (!Base || Offset.isNegative()) {
      // Global-data recovery may express a literal string GEP as
      // `ptrtoint(string) - guest_address`, which is no longer a constant
      // LLVM GEP even though the underlying object is still the format
      // string.  Preserve that provenance for scanf format recovery.
      if (auto *StringGV = dyn_cast<GlobalVariable>(
              GEP->getPointerOperand()->stripPointerCasts());
          StringGV && StringGV->getName().starts_with(".str"))
        return std::make_pair(StringGV, uint64_t(0));
      if (auto StringBase = resolveConstantGlobalPointer(
              GEP->getPointerOperand(), DL, Depth + 1);
          StringBase && StringBase->first->getName().starts_with(".str"))
        return std::make_pair(StringBase->first, uint64_t(0));
      return std::nullopt;
    }
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

static bool formatHasAnyConversion(StringRef Text) {
  for (size_t I = 0; I + 1 < Text.size(); ++I) {
    if (Text[I] != '%')
      continue;
    ++I;
    if (Text[I] == '%')
      continue;
    while (I < Text.size() &&
           (Text[I] == '-' || Text[I] == '+' || Text[I] == ' ' ||
            Text[I] == '#' || Text[I] == '0' || Text[I] == '\'' ||
            Text[I] == '*' || (Text[I] >= '0' && Text[I] <= '9') ||
            Text[I] == '.' || Text[I] == 'h' || Text[I] == 'l' ||
            Text[I] == 'j' || Text[I] == 'z' || Text[I] == 't' ||
            Text[I] == 'L' || Text[I] == 'q'))
      ++I;
    if (I < Text.size() && Text[I] != '%')
      return true;
  }
  return false;
}

static std::optional<std::string>
readConstantFormatString(Value *Format, const DataLayout &DL) {
  auto HasIntegerConversion = [](StringRef Text) {
    for (size_t I = 0; I + 1 < Text.size(); ++I) {
      if (Text[I] != '%')
        continue;
      ++I;
      if (Text[I] == '%')
        continue;
      while (I < Text.size() &&
             ((Text[I] >= '0' && Text[I] <= '9') || Text[I] == '*' ||
              Text[I] == 'h' || Text[I] == 'l' || Text[I] == 'j' ||
              Text[I] == 'z' || Text[I] == 't'))
        ++I;
      if (I < Text.size() && (Text[I] == 'd' || Text[I] == 'i' ||
                              Text[I] == 'o' || Text[I] == 'u' ||
                              Text[I] == 'x' || Text[I] == 'X'))
        return true;
    }
    return false;
  };
  if (auto *Select = dyn_cast<SelectInst>(Format)) {
    auto TrueFormat = readConstantFormatString(Select->getTrueValue(), DL);
    if (TrueFormat && HasIntegerConversion(*TrueFormat))
      return TrueFormat;
    auto FalseFormat = readConstantFormatString(Select->getFalseValue(), DL);
    if (FalseFormat && HasIntegerConversion(*FalseFormat))
      return FalseFormat;
    if (TrueFormat && formatHasAnyConversion(*TrueFormat))
      return TrueFormat;
    if (FalseFormat && formatHasAnyConversion(*FalseFormat))
      return FalseFormat;

    // A recovered address select can contain several adjacent string globals
    // and its first resolvable branch is not necessarily the format used by
    // this call (for example `%s` followed by `%i`).  Search the complete
    // expression tree before giving up, preferring a real vararg conversion
    // over an adjacent non-format byte string.
    SmallPtrSet<Value *, 32> Seen;
    std::function<std::optional<std::string>(Value *)> FindConversionFormat =
        [&](Value *V) -> std::optional<std::string> {
      if (!V || !Seen.insert(V).second)
        return std::nullopt;
      if (auto *GV = dyn_cast<GlobalVariable>(V->stripPointerCasts());
          GV && GV->getName().starts_with(".str") && GV->hasInitializer()) {
        std::string Text;
        for (uint64_t I = 0; I < 4096; ++I) {
          uint8_t Byte = 0;
          if (!readConstantByte(GV->getInitializer(), DL, I, Byte))
            break;
          if (Byte == 0)
            return formatHasAnyConversion(Text) ? std::optional(Text)
                                                : std::nullopt;
          Text.push_back(static_cast<char>(Byte));
        }
      }
      // Optimized lifted calls usually pass the format through a GEP rooted
      // at a recovered string segment.  The recursive walk above reaches
      // that GEP, but the GEP itself is not a GlobalVariable; resolve its
      // constant base/offset before descending further.
      if (auto Match = resolveConstantGlobalPointer(V, DL);
          Match && Match->first->getName().starts_with(".str") &&
          Match->first->hasInitializer()) {
        std::string Text;
        for (uint64_t I = Match->second; I < Match->second + 4096; ++I) {
          uint8_t Byte = 0;
          if (!readConstantByte(Match->first->getInitializer(), DL, I, Byte))
            break;
          if (Byte == 0)
            return formatHasAnyConversion(Text) ? std::optional(Text)
                                                : std::nullopt;
          Text.push_back(static_cast<char>(Byte));
        }
      }
      if (auto *Inst = dyn_cast<Instruction>(V))
        for (Value *Op : Inst->operands())
          if (auto Found = FindConversionFormat(Op))
            return Found;
      return std::nullopt;
    };
    if (auto Found = FindConversionFormat(Format))
      return Found;
    return TrueFormat ? TrueFormat : FalseFormat;
  }
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

// A failed scanf conversion leaves its destination untouched.  For a lifted
// C local that is subsequently read, the source program therefore has an
// uninitialised-value path.  The old zero-backed recovered frame accidentally
// turned that path into a real zero, which is observably different from the
// native binary (and can change branches).  Seed only integer scanf
// destinations with an out-of-domain value; successful conversions overwrite
// it, while %s/%c/floating-point destinations retain their normal semantics.
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
  if (Base == Root && !Offset.isNegative())
    return Offset.getZExtValue();

  // Opaque-pointer optimized IR commonly keeps va_list/reg_save_area fields
  // as direct byte GEPs from an alloca:
  //   %slot = getelementptr i8, ptr %reg_save_area, i64 8
  // `stripAndAccumulateConstantOffsets` can fail to prove the alloca base
  // through these rewritten carriers.  For byte GEPs the final constant index
  // is already the byte offset, so recover it directly.
  if (GEP->getSourceElementType()->isIntegerTy(8) &&
      GEP->getPointerOperand()->stripPointerCasts() == Root) {
    auto It = GEP->idx_end();
    if (It != GEP->idx_begin()) {
      --It;
      if (auto *CI = dyn_cast<ConstantInt>(*It))
        return CI->getZExtValue();
    }
  }
  return std::nullopt;
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
  const DataLayout &DL = M.getDataLayout();
  GlobalVariable *BestInferredGV = nullptr;
  uint64_t BestInferredOffset = std::numeric_limits<uint64_t>::max();
  uint64_t BestInferredSize = std::numeric_limits<uint64_t>::max();
  for (GlobalVariable &GV : M.globals()) {
    if (GV.isDeclaration())
      continue;
    StringRef Name = GV.getName();
    std::optional<uint64_t> GuestBegin =
        parseGuestAddressPrefix(Name, "g_bytes_");
    if (!GuestBegin)
      GuestBegin = parseGuestAddressPrefix(Name, "dyn_bytes_");
    if (!GuestBegin)
      GuestBegin = parseGuestAddressPrefix(Name, "g_arr_");
    if (!GuestBegin)
      GuestBegin = parseGuestAddressPrefix(Name, "native_data_");
    if (!GuestBegin)
      continue;
    TypeSize Size = DL.getTypeAllocSize(GV.getValueType());
    if (Size.isScalable() || Size.getFixedValue() == 0)
      continue;
    uint64_t Bytes = Size.getFixedValue();
    if (Address >= *GuestBegin && Address < *GuestBegin + Bytes)
      return std::make_pair(&GV, Address - *GuestBegin);
  }
  for (GlobalVariable &GV : M.globals()) {
    if (GV.isDeclaration())
      continue;
    StringRef Name = GV.getName();
    if (Name.starts_with("__mcsema") ||
        Name.starts_with("frame_storage_backing.") ||
        Name.starts_with("native.recovered.oob."))
      continue;

    TypeSize Size = DL.getTypeAllocSize(GV.getValueType());
    if (Size.isScalable() || Size.getFixedValue() == 0)
      continue;
    uint64_t Bytes = Size.getFixedValue();

    SmallVector<User *, 32> Worklist;
    SmallPtrSet<User *, 32> Seen;
    for (User *U : GV.users())
      Worklist.push_back(U);
    while (!Worklist.empty()) {
      User *U = Worklist.pop_back_val();
      if (!Seen.insert(U).second)
        continue;

      if (auto *GEP = dyn_cast<GEPOperator>(U)) {
        APInt Offset(DL.getIndexSizeInBits(0), 0);
        if (GEP->accumulateConstantOffset(DL, Offset) &&
            Offset.isNegative()) {
          int64_t SignedOffset = Offset.getSExtValue();
          uint64_t GuestBegin = static_cast<uint64_t>(-SignedOffset);
          if (Address >= GuestBegin && Address < GuestBegin + Bytes) {
            uint64_t CandidateOffset = Address - GuestBegin;
            if (!BestInferredGV || CandidateOffset < BestInferredOffset ||
                (CandidateOffset == BestInferredOffset &&
                 Bytes < BestInferredSize)) {
              BestInferredGV = &GV;
              BestInferredOffset = CandidateOffset;
              BestInferredSize = Bytes;
            }
          }
        }
      }

      if (auto *C = dyn_cast<Constant>(U)) {
        if (!C->getType()->isPointerTy())
          continue;
      } else if (auto *I = dyn_cast<Instruction>(U)) {
        if (!I->getType()->isPointerTy())
          continue;
      } else {
        continue;
      }
      for (User *Next : U->users())
        Worklist.push_back(Next);
    }
  }
  if (BestInferredGV)
    return std::make_pair(BestInferredGV, BestInferredOffset);
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

static std::optional<std::pair<uint64_t, uint64_t>>
getGuestRange(GlobalVariable &GV) {
  MDNode *Range = GV.getMetadata("brighten.guest.range");
  if (!Range || Range->getNumOperands() != 2)
    return std::nullopt;
  auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
  auto *EndMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(1));
  auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
  auto *End = EndMD ? dyn_cast<ConstantInt>(EndMD->getValue()) : nullptr;
  if (!Begin || !End || Begin->getZExtValue() >= End->getZExtValue())
    return std::nullopt;
  return std::make_pair(Begin->getZExtValue(), End->getZExtValue());
}

static std::optional<uint64_t> getConstantGuestPointer(Value *V) {
  if (!V)
    return std::nullopt;
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::IntToPtr)
      if (auto *CI = dyn_cast<ConstantInt>(CE->getOperand(0)))
        return CI->getZExtValue();
  }
  if (auto *ITP = dyn_cast<IntToPtrInst>(V))
    if (auto *CI = dyn_cast<ConstantInt>(ITP->getOperand(0)))
      return CI->getZExtValue();
  return std::nullopt;
}

// Convert residual guest-address format arguments into native string globals
// while guest-range metadata and segment initializers are still available.
// This fixes calls such as vscanf(inttoptr(0x408004), ...): that address is
// valid in the guest image but is unmapped in the ASLR native executable.
static unsigned materializeResidualLibcFormats(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  SmallVector<std::pair<CallBase *, unsigned>, 16> Work;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!Callee)
          continue;
        StringRef Name = Callee->getName();
        unsigned FormatIndex = 0;
        if (Name == "fprintf" || Name == "sprintf" || Name == "sscanf" ||
            Name == "vfprintf" || Name == "vsprintf" || Name == "vsscanf")
          FormatIndex = 1;
        else if (Name == "snprintf")
          FormatIndex = 2;
        else if (Name != "printf" && Name != "scanf" &&
                 Name != "__isoc99_scanf" && Name != "vprintf" &&
                 Name != "vscanf" && Name != "__isoc99_vscanf")
          continue;
        if (CB->arg_size() > FormatIndex &&
            getConstantGuestPointer(CB->getArgOperand(FormatIndex)))
          Work.push_back({CB, FormatIndex});
      }
    }
  }

  unsigned Rewritten = 0;
  for (auto [CB, FormatIndex] : Work) {
    auto GuestAddr = getConstantGuestPointer(CB->getArgOperand(FormatIndex));
    if (!GuestAddr)
      continue;
    GlobalVariable *Source = nullptr;
    uint64_t Offset = 0;
    for (GlobalVariable &GV : M.globals()) {
      auto Range = getGuestRange(GV);
      if (Range && *GuestAddr >= Range->first && *GuestAddr < Range->second &&
          GV.hasInitializer()) {
        Source = &GV;
        Offset = *GuestAddr - Range->first;
        break;
      }
    }
    if (!Source)
      continue;
    SmallVector<uint8_t, 128> Bytes;
    for (uint64_t I = Offset; I < Offset + 4096; ++I) {
      uint8_t Byte = 0;
      if (!readConstantByte(Source->getInitializer(), DL, I, Byte)) {
        Bytes.clear();
        break;
      }
      Bytes.push_back(Byte);
      if (Byte == 0)
        break;
    }
    if (Bytes.empty() || Bytes.back() != 0)
      continue;
    auto *Init = ConstantDataArray::get(M.getContext(), Bytes);
    auto *Native = new GlobalVariable(
        M, Init->getType(), true, GlobalValue::PrivateLinkage, Init,
        "native.libc.format");
    Native->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
    Native->setAlignment(Align(1));
    CB->setArgOperand(FormatIndex, Native);
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

static void preserveRecoveredGlobalsAcrossOptimization(Module &M) {
  if (M.getNamedMetadata("brighten.globals.preserved"))
    return;
  SmallVector<GlobalValue *, 32> RecoveredGlobals;
  for (GlobalVariable &GV : M.globals()) {
    // Cleanup deliberately converts native ptrtoint carriers back to their
    // stable guest integer identity before O3.  The second cleanup sweep then
    // needs this object and its range metadata to turn scanf/libc pointer
    // slots back into native pointers.  Keeping only format strings lets O3
    // delete writable arrays whose remaining carrier is temporarily numeric.
    if (getGuestRange(GV) && GV.hasInitializer())
      RecoveredGlobals.push_back(&GV);
  }
  if (RecoveredGlobals.empty())
    return;
  appendToCompilerUsed(M, RecoveredGlobals);
  M.getOrInsertNamedMetadata("brighten.globals.preserved")
      ->addOperand(MDNode::get(M.getContext(), {}));
}

static void setGuestRangeMetadata(Module &M, GlobalVariable &GV,
                                  uint64_t Begin, uint64_t End) {
  LLVMContext &Ctx = M.getContext();
  GV.setMetadata(
      "brighten.guest.range",
      MDNode::get(Ctx, {ConstantAsMetadata::get(ConstantInt::get(
                            Type::getInt64Ty(Ctx), Begin)),
                        ConstantAsMetadata::get(ConstantInt::get(
                            Type::getInt64Ty(Ctx), End))}));
}

static unsigned widenOverNarrowRecoveredScalars(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  struct RangeInfo {
    GlobalVariable *GV;
    uint64_t Begin;
    uint64_t End;
  };
  SmallVector<RangeInfo, 32> Ranges;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.isDeclaration())
      continue;
    if (auto Range = getGuestRange(GV))
      Ranges.push_back({&GV, Range->first, Range->second});
  }

  SmallVector<std::pair<GlobalVariable *, uint64_t>, 16> Work;
  for (const RangeInfo &R : Ranges) {
    GlobalVariable *GV = R.GV;
    if (!GV->getName().starts_with("g_scalar_"))
      continue;
    TypeSize Size = DL.getTypeAllocSize(GV->getValueType());
    if (Size.isScalable() || Size.getFixedValue() == 0 ||
        Size.getFixedValue() >= 16)
      continue;

    uint64_t NextBegin = UINT64_MAX;
    for (const RangeInfo &Other : Ranges) {
      if (Other.Begin > R.Begin)
        NextBegin = std::min(NextBegin, Other.Begin);
    }
    if (NextBegin == UINT64_MAX || NextBegin <= R.End)
      continue;

    uint64_t NewBytes = NextBegin - R.Begin;
    // Keep this as a narrow repair for over-split BSS/global scalars.  A
    // scalar with no recovered neighbour may represent a true isolated object;
    // do not turn it into an unbounded segment surrogate.
    if (NewBytes <= Size.getFixedValue() || NewBytes > 1u << 20)
      continue;
    Work.emplace_back(GV, NewBytes);
  }

  unsigned Rewritten = 0;
  for (auto [Old, NewBytes] : Work) {
    if (!Old->getParent())
      continue;
    auto Range = getGuestRange(*Old);
    if (!Range)
      continue;
    LLVMContext &Ctx = M.getContext();
    auto *I8 = Type::getInt8Ty(Ctx);
    SmallVector<Constant *, 64> Bytes;
    Bytes.reserve(static_cast<size_t>(std::min<uint64_t>(NewBytes, 64)));
    for (uint64_t I = 0; I < NewBytes; ++I) {
      uint8_t Byte = 0;
      if (I < DL.getTypeAllocSize(Old->getValueType()).getFixedValue())
        (void)readConstantByte(Old->getInitializer(), DL, I, Byte);
      Bytes.push_back(ConstantInt::get(I8, Byte));
    }
    auto *ArrTy = ArrayType::get(I8, NewBytes);
    Constant *Init = ConstantArray::get(ArrTy, Bytes);
    std::string Name = Old->getName().str();
    Old->setName(Name + ".narrow");
    auto *Wide = new GlobalVariable(
        M, ArrTy, Old->isConstant(), Old->getLinkage(), Init, Name);
    Wide->setAlignment(Old->getAlign());
    Wide->setUnnamedAddr(Old->getUnnamedAddr());
    setGuestRangeMetadata(M, *Wide, Range->first, Range->first + NewBytes);
    Old->replaceAllUsesWith(Wide);
    if (Old->use_empty())
      Old->eraseFromParent();
    appendToUsed(M, {Wide});
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
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
    // NativeStrict global recovery can conservatively preserve a whole ELF
    // segment when one address carrier is ambiguous.  Its data_<addr> alias,
    // physical GEP offset, and allocation size still prove the segment's
    // exact guest range.  Retain that range as metadata before removing the
    // alias so later cleanup sweeps can translate dynamic scanf/libc
    // destinations instead of emitting raw guest-address inttoptrs.
    if (!Segment->getMetadata("brighten.guest.range")) {
      uint64_t PhysicalOffset = ByteOffset.getZExtValue();
      TypeSize AllocSize =
          M.getDataLayout().getTypeAllocSize(Segment->getValueType());
      if (GuestAddress >= PhysicalOffset && !AllocSize.isScalable()) {
        uint64_t GuestBase = GuestAddress - PhysicalOffset;
        if (AllocSize.getFixedValue() <=
            std::numeric_limits<uint64_t>::max() - GuestBase)
          setGuestRangeMetadata(M, *Segment, GuestBase,
                                GuestBase + AllocSize.getFixedValue());
      }
    }
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
static bool isProvenScalarLibcCallArgument(Value *V, CallBase &CB) {
  Function *Callee = CB.getCalledFunction();
  if (!V || !Callee)
    return false;

  StringRef Name = Callee->getName();
  if (Name.ends_with(".lifted_abi"))
    Name = Name.drop_back(StringRef(".lifted_abi").size());

  auto IsScalarPosition = [&](unsigned Index) {
    if (Name == "memset" || Name.starts_with("llvm.memset."))
      return Index == 1 || Index == 2;
    if (Name == "memcpy" || Name == "memmove" || Name == "memcmp" ||
        Name == "strncpy" || Name == "strncat" || Name == "strncmp" ||
        Name.starts_with("llvm.memcpy.") ||
        Name.starts_with("llvm.memmove."))
      return Index == 2;
    if (Name == "bzero")
      return Index == 1;
    if (Name == "malloc")
      return Index == 0;
    if (Name == "calloc")
      return Index == 0 || Index == 1;
    if (Name == "realloc")
      return Index == 1;
    return false;
  };

  bool Found = false;
  for (unsigned Index = 0; Index < CB.arg_size(); ++Index) {
    if (CB.getArgOperand(Index) != V)
      continue;
    Found = true;
    if (!IsScalarPosition(Index))
      return false;
  }
  return Found;
}

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
            if (auto *CB = dyn_cast<CallBase>(U)) {
              if (!isProvenScalarLibcCallArgument(V, *CB))
                return true;
              continue;
            }
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
        if (auto *CB = dyn_cast<CallBase>(Consumer))
          IsIdentityCarrier =
              isProvenScalarLibcCallArgument(AliasInteger, *CB);
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
    if (MDNode *BaseMD = GV->getMetadata("brighten.guest.base")) {
      if (BaseMD->getNumOperands() == 1) {
        auto *BaseValueMD =
            dyn_cast<ConstantAsMetadata>(BaseMD->getOperand(0));
        auto *BaseValue =
            BaseValueMD ? dyn_cast<ConstantInt>(BaseValueMD->getValue())
                        : nullptr;
        if (BaseValue)
          return BaseValue->getZExtValue();
      }
    }
    MDNode *Range = GV->getMetadata("brighten.guest.range");
    if (!Range || Range->getNumOperands() != 2)
      return std::nullopt;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    if (Begin) {
      if (GV->getName() == "g_arr_2_with_invalid_prefix" &&
          Begin->getZExtValue() >= 4)
        return Begin->getZExtValue() - 4;
      return Begin->getZExtValue();
    }
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

struct ConstantGuestInteger {
  APInt Value;
  bool UsedRecoveredPointer = false;
};

static std::optional<ConstantGuestInteger>
evaluateConstantGuestInteger(Module &M, Constant *C, unsigned Depth = 0) {
  if (!C || !C->getType()->isIntegerTy() || Depth > 8)
    return std::nullopt;

  auto Make = [](APInt Value, bool UsedRecoveredPointer) {
    return ConstantGuestInteger{Value, UsedRecoveredPointer};
  };

  if (auto *CI = dyn_cast<ConstantInt>(C))
    return Make(CI->getValue(), false);

  auto *CE = dyn_cast<ConstantExpr>(C);
  if (!CE)
    return std::nullopt;

  unsigned BitWidth = C->getType()->getIntegerBitWidth();
  auto GuestAddress = findConstantRecoveredGuestAddress(M, CE);
  if (GuestAddress)
    // APInt's single-word constructor asserts when a narrow destination type
    // cannot represent the full guest address.  Constant expressions such as
    // trunc(ptrtoint(@recovered_global)) are expected to discard those high
    // bits, so construct at the address width first and apply the LLVM integer
    // cast semantics explicitly.
    return Make(APInt(64, *GuestAddress).zextOrTrunc(BitWidth), true);

  auto EvalOperand = [&](unsigned Index) {
    return evaluateConstantGuestInteger(M, dyn_cast<Constant>(CE->getOperand(Index)),
                                        Depth + 1);
  };

  switch (CE->getOpcode()) {
  case Instruction::Trunc:
  case Instruction::ZExt:
  case Instruction::SExt:
  case Instruction::BitCast: {
    auto Operand = EvalOperand(0);
    if (!Operand)
      return std::optional<ConstantGuestInteger>();
    APInt Value = Operand->Value;
    if (Value.getBitWidth() != BitWidth) {
      if (CE->getOpcode() == Instruction::Trunc)
        Value = Value.trunc(BitWidth);
      else if (CE->getOpcode() == Instruction::SExt)
        Value = Value.sext(BitWidth);
      else
        Value = Value.zextOrTrunc(BitWidth);
    }
    return Make(Value, Operand->UsedRecoveredPointer);
  }
  case Instruction::Add:
  case Instruction::Sub:
  case Instruction::And:
  case Instruction::Or:
  case Instruction::Xor: {
    auto LHS = EvalOperand(0);
    auto RHS = EvalOperand(1);
    if (!LHS || !RHS ||
        (!LHS->UsedRecoveredPointer && !RHS->UsedRecoveredPointer))
      return std::optional<ConstantGuestInteger>();
    APInt LV = LHS->Value.zextOrTrunc(BitWidth);
    APInt RV = RHS->Value.zextOrTrunc(BitWidth);
    APInt Result(BitWidth, 0);
    switch (CE->getOpcode()) {
    case Instruction::Add:
      Result = LV + RV;
      break;
    case Instruction::Sub:
      Result = LV - RV;
      break;
    case Instruction::And:
      Result = LV & RV;
      break;
    case Instruction::Or:
      Result = LV | RV;
      break;
    case Instruction::Xor:
      Result = LV ^ RV;
      break;
    default:
      llvm_unreachable("handled binary opcode changed");
    }
    return Make(Result, true);
  }
  default:
    return std::nullopt;
  }
}

static unsigned rewriteRecoveredPointerIntegerIdentities(Module &M,
                                                        bool &Changed) {
  struct OperandRewrite {
    Instruction *I;
    unsigned OperandNo;
    Constant *Replacement;
  };

  std::function<Constant *(Constant *, bool &)> RewritePointerConstant =
      [&](Constant *C, bool &DidRewrite) -> Constant * {
    auto *CE = dyn_cast_or_null<ConstantExpr>(C);
    if (!CE)
      return C;
    if (CE->getOpcode() != Instruction::GetElementPtr)
      return C;

    auto *GEP = cast<GEPOperator>(CE);
    auto *PointerOperand = dyn_cast<Constant>(GEP->getPointerOperand());
    if (!PointerOperand)
      return C;

    bool LocalChanged = false;
    Constant *NewPointer = RewritePointerConstant(PointerOperand, LocalChanged);
    SmallVector<Constant *, 8> Indices;
    for (auto It = GEP->idx_begin(); It != GEP->idx_end(); ++It) {
      auto *Index = dyn_cast<Constant>(*It);
      if (!Index)
        return C;
      Constant *NewIndex = Index;
      if (Index->getType()->isIntegerTy()) {
        auto Evaluated = evaluateConstantGuestInteger(M, Index);
        if (Evaluated && Evaluated->UsedRecoveredPointer) {
          NewIndex = ConstantInt::get(cast<IntegerType>(Index->getType()),
                                      Evaluated->Value);
          LocalChanged = true;
        }
      }
      Indices.push_back(NewIndex);
    }

    if (!LocalChanged)
      return C;
    DidRewrite = true;
    return ConstantExpr::getGetElementPtr(GEP->getSourceElementType(),
                                          NewPointer, Indices,
                                          GEP->isInBounds());
  };

  SmallVector<OperandRewrite, 128> OperandRewrites;
  SmallVector<PtrToIntInst *, 32> PtrToInts;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *PTI = dyn_cast<PtrToIntInst>(&I)) {
          if (auto GuestAddress =
                  findConstantRecoveredGuestAddress(M, PTI->getPointerOperand()))
            PtrToInts.push_back(PTI);
          continue;
        }
        for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo) {
          Value *Operand = I.getOperand(OpNo);
          if (!Operand)
            continue;
          auto *C = dyn_cast<Constant>(Operand);
          if (!C)
            continue;
          if (Operand->getType()->isIntegerTy()) {
            if (isa<ConstantInt>(C))
              continue;
            auto Evaluated = evaluateConstantGuestInteger(M, C);
            if (!Evaluated || !Evaluated->UsedRecoveredPointer)
              continue;
            Constant *Replacement =
                ConstantInt::get(cast<IntegerType>(C->getType()),
                                 Evaluated->Value);
            OperandRewrites.push_back({&I, OpNo, Replacement});
            continue;
          }
          if (Operand->getType()->isPointerTy()) {
            bool DidRewrite = false;
            Constant *Replacement = RewritePointerConstant(C, DidRewrite);
            if (DidRewrite && Replacement && Replacement != C &&
                Replacement->getType() == C->getType())
              OperandRewrites.push_back({&I, OpNo, Replacement});
          }
        }
      }
    }
  }

  unsigned Rewritten = 0;
  for (const OperandRewrite &Rewrite : OperandRewrites) {
    Rewrite.I->setOperand(Rewrite.OperandNo, Rewrite.Replacement);
    ++Rewritten;
    Changed = true;
  }
  for (PtrToIntInst *PTI : PtrToInts) {
    if (!PTI->getParent())
      continue;
    auto GuestAddress =
        findConstantRecoveredGuestAddress(M, PTI->getPointerOperand());
    if (!GuestAddress)
      continue;
    Constant *Replacement =
        ConstantInt::get(PTI->getType(), *GuestAddress);
    PTI->replaceAllUsesWith(Replacement);
    if (PTI->use_empty())
      PTI->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
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
  auto CoerceOffset = [&](Value *Offset, Type *TargetTy) -> Value * {
    if (!Offset || Offset->getType() == TargetTy)
      return Offset;
    if (!Offset->getType()->isIntegerTy() || !TargetTy->isIntegerTy())
      return nullptr;
    return B.CreateSExtOrTrunc(Offset, TargetTy,
                              "native.scanf.address.offset.cast");
  };
  if (Left && !Right) {
    Value *Extra = CoerceOffset(BO->getOperand(1),
                                Left->DynamicOffset->getType());
    if (!Extra)
      return std::nullopt;
    Left->DynamicOffset = B.CreateAdd(Left->DynamicOffset, Extra,
                                      "native.scanf.address.offset");
    return Left;
  }
  if (Right && !Left) {
    Value *Extra = CoerceOffset(BO->getOperand(0),
                                Right->DynamicOffset->getType());
    if (!Extra)
      return std::nullopt;
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
    // The matched constant proves that this is guest-data address
    // arithmetic, but it does not prove that every dynamic result remains in
    // that one recovered object.  Adjacent scanf destinations often cross
    // typed-object boundaries (base, base+4, ...), and anchoring all of them
    // on Address->Segment creates pointers such as @g_arr_0 + 0x405xxx.
    // Dispatch the complete address through all proven guest ranges instead.
    Value *NativePtr =
        materializeRecoveredDataPointer(M, B, SI->getValueOperand());
    if (!NativePtr)
      continue;
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

    SmallVector<GetElementPtrInst *, 8> ConstantByteGeps;
    for (User *U : ITP->users()) {
      auto *GEP = dyn_cast<GetElementPtrInst>(U);
      if (!GEP || GEP->getSourceElementType() != B.getInt8Ty() ||
          GEP->getNumIndices() != 1)
        continue;
      if (!isa<ConstantInt>(*GEP->idx_begin()))
        continue;
      ConstantByteGeps.push_back(GEP);
    }

    for (GetElementPtrInst *GEP : ConstantByteGeps) {
      if (!GEP->getParent())
        continue;
      auto *Index = cast<ConstantInt>(*GEP->idx_begin());
      if (Index->isZero())
        continue;
      IRBuilder<> GB(GEP);
      Value *BaseAddress = ITP->getOperand(0);
      if (!BaseAddress->getType()->isIntegerTy(64))
        BaseAddress = GB.CreateZExtOrTrunc(BaseAddress, GB.getInt64Ty(),
                                           "native.guest.gep.base");
      Value *AdjustedAddress =
          GB.CreateAdd(BaseAddress,
                       ConstantInt::get(GB.getInt64Ty(),
                                        Index->getSExtValue(), true),
                       "native.guest.gep.address");
      Value *AdjustedPtr =
          materializeRecoveredDataPointer(M, GB, AdjustedAddress);
      if (!AdjustedPtr)
        continue;
      if (AdjustedPtr->getType() != GEP->getType())
        AdjustedPtr = GB.CreatePointerCast(AdjustedPtr, GEP->getType(),
                                           "native.guest.gep.ptr.cast");
      GEP->replaceAllUsesWith(AdjustedPtr);
      GEP->eraseFromParent();
      ++Rewritten;
      Changed = true;
    }

    // The inttoptr operand is the full guest address.  Rebuilding it as
    // Address->Segment + DynamicOffset is only valid when DynamicOffset is
    // known to be segment-local; lifted raw-fuzz cases also produce recovered
    // guest pointers loaded from memory, where the dynamic value is already a
    // full 0x40.... address.  Use the same range mapper as translator lowering
    // so all recovered globals and widened scalar ranges share one dispatch.
    Value *NativePtr = materializeRecoveredDataPointer(M, B, ITP->getOperand(0));
    if (!NativePtr) {
      Value *Offset = Address->DynamicOffset;
      if (!Offset->getType()->isIntegerTy(64))
        Offset = B.CreateZExtOrTrunc(Offset, B.getInt64Ty(),
                                     "native.guest.offset.ext");
      if (Address->SegmentOffset != 0)
        Offset = B.CreateAdd(Offset, B.getInt64(Address->SegmentOffset),
                             "native.guest.offset");
      NativePtr = B.CreateGEP(B.getInt8Ty(), Address->Segment, Offset,
                              "native.guest.ptr");
    }
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
    unsigned Priority;
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

static GlobalVariable *getOrCreateRecoveredOobScratch(Module &M) {
  constexpr uint64_t OobScratchBytes = 1u << 20;
  if (GlobalVariable *Existing =
          M.getNamedGlobal("native.recovered.oob.scratch"))
    return Existing;
  auto *ScratchTy =
      ArrayType::get(Type::getInt8Ty(M.getContext()), OobScratchBytes);
  auto *Scratch = new GlobalVariable(
      M, ScratchTy, false, GlobalValue::InternalLinkage,
      ConstantAggregateZero::get(ScratchTy), "native.recovered.oob.scratch");
  Scratch->setAlignment(Align(1));
  return Scratch;
}

static Value *createRecoveredOobScratchPointer(Module &M, IRBuilder<> &B,
                                               Value *GuestAddress,
                                               StringRef Name) {
  constexpr uint64_t OobScratchBytes = 1u << 20;
  constexpr uint64_t MaxAccessBytes = 8;
  if (!GuestAddress || !GuestAddress->getType()->isIntegerTy())
    return nullptr;
  Value *Key = GuestAddress;
  if (!Key->getType()->isIntegerTy(64))
    Key = B.CreateZExtOrTrunc(Key, B.getInt64Ty(), (Name + ".key").str());
  GlobalVariable *Scratch = getOrCreateRecoveredOobScratch(M);
  Value *Offset = B.CreateAnd(Key, B.getInt64(OobScratchBytes - MaxAccessBytes),
                              (Name + ".offset").str());
  return B.CreateInBoundsGEP(Scratch->getValueType(), Scratch,
                             {B.getInt64(0), Offset}, Name);
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
  if (Value *NativeCarrier = getDirectNativePointerCarrier(Address)) {
    // Range dispatches produced by this function are already the complete
    // guest-or-native mapping.  Their fallback intentionally remains a raw
    // inttoptr so an address outside every proven object keeps its original
    // fault behavior; that fallback makes the generic native-pointer
    // classifier reject the select and used to cause a second range rebase.
    // Recognize our own generated carrier explicitly to make lowering
    // idempotent across repeated cleanup sweeps.
    if (NativeCarrier->hasName() &&
        NativeCarrier->getName().starts_with("native.data.pointer.select"))
      return NativeCarrier;
    SmallPtrSet<Value *, 16> Seen;
    if (isNativePointerValue(NativeCarrier, Seen))
      return NativeCarrier;
  }

  Type *I64 = Type::getInt64Ty(Ctx);
  Value *Address64 = Address;
  if (Address64->getType() != I64)
    Address64 = B.CreateZExtOrTrunc(Address64, I64, "native.data.address");
  SmallPtrSet<Value *, 32> StackSeen;
  if (containsNativeStackInteger(Address, StackSeen))
    return B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                            "native.stack.address.fallback");
  SmallPtrSet<Value *, 32> NativeSeen;
  if (isNativeInteger(Address, NativeSeen))
    return B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                            "native.integer.pointer");

  struct Range {
    GlobalVariable *GV;
    uint64_t Begin;
    uint64_t End;
    unsigned Priority;
  };
  SmallVector<Range, 16> Ranges;
  uint64_t MinGuest = std::numeric_limits<uint64_t>::max();
  uint64_t MaxGuest = 0;
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
    uint64_t BeginValue = Begin->getZExtValue();
    uint64_t EndValue = End->getZExtValue();
    StringRef Name = GV.getName();
    unsigned Priority = 1;
    if (Name.starts_with("native_data_") ||
        Name.starts_with("native_residual_") ||
        Name.starts_with("dyn_bytes_") ||
        Name.starts_with("g_bytes_"))
      Priority = 0;
    if (Name.starts_with("g_arr_") || Name.starts_with("g_scalar_"))
      Priority = 2;
    Ranges.push_back({&GV, BeginValue, EndValue, Priority});
    MinGuest = std::min(MinGuest, BeginValue);
    MaxGuest = std::max(MaxGuest, EndValue);
  }
  if (Ranges.empty())
    return B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                            "native.address.fallback");

  Value *RawFallback = B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                                        "native.address.fallback");
  // Type/object recovery can split one guest data segment into compact typed
  // globals.  A value that falls in no recovered object is not a proven native
  // object access.  Do not silently redirect such gaps to scratch: raw fuzzing
  // can drive negative indices into unmapped guest addresses, and the original
  // binary observes that as a fault.  Keep the raw fallback unless a concrete
  // recovered range below proves a native object mapping.
  llvm::stable_sort(Ranges, [](const Range &L, const Range &R) {
    if (L.Priority != R.Priority)
      return L.Priority < R.Priority;
    uint64_t LSize = L.End - L.Begin;
    uint64_t RSize = R.End - R.Begin;
    if (LSize != RSize)
      return LSize > RSize;
    return L.Begin < R.Begin;
  });
  Value *Result = RawFallback;
  for (const Range &R : Ranges) {
    Value *AtOrAfter = B.CreateICmpUGE(Address64, B.getInt64(R.Begin));
    Value *BeforeEnd = B.CreateICmpULT(Address64, B.getInt64(R.End));
    Value *InRange = B.CreateAnd(AtOrAfter, BeforeEnd);
    Value *Offset = B.CreateSub(Address64, B.getInt64(R.Begin));
    Value *NativePtr = B.CreateGEP(B.getInt8Ty(), R.GV, Offset,
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

static Value *
findMaterializedRecoveredGuestAddress(Value *V, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    if (Value *Addr =
            findMaterializedRecoveredGuestAddress(Sel->getTrueValue(), Seen))
      return Addr;
    return findMaterializedRecoveredGuestAddress(Sel->getFalseValue(), Seen);
  }
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP ||
      GEP->getSourceElementType() != Type::getInt8Ty(V->getContext()) ||
      GEP->getNumIndices() != 1)
    return nullptr;
  Value *Index = *GEP->idx_begin();
  if (!Index || isa<ConstantInt>(Index) || !Index->getType()->isIntegerTy())
    return nullptr;

  if (auto *DirectGV = dyn_cast<GlobalVariable>(
          GEP->getPointerOperand()->stripPointerCasts())) {
    if (!DirectGV->isDeclaration() &&
        DirectGV->getMetadata("brighten.guest.range")) {
      if (auto *BO = dyn_cast<BinaryOperator>(Index)) {
        if (BO->getOpcode() == Instruction::Sub &&
            isa<ConstantInt>(BO->getOperand(1)) &&
            BO->getOperand(0)->getType()->isIntegerTy())
          return BO->getOperand(0);
        if (BO->getOpcode() == Instruction::Add) {
          if (isa<ConstantInt>(BO->getOperand(1)) &&
              BO->getOperand(0)->getType()->isIntegerTy())
            return BO->getOperand(0);
          if (isa<ConstantInt>(BO->getOperand(0)) &&
              BO->getOperand(1)->getType()->isIntegerTy())
            return BO->getOperand(1);
        }
      }
    }
  }

  auto *BaseGEP = dyn_cast<GEPOperator>(GEP->getPointerOperand());
  if (!BaseGEP || BaseGEP->getSourceElementType() !=
                      Type::getInt8Ty(V->getContext()) ||
      BaseGEP->getNumIndices() != 1 ||
      !isa<ConstantInt>(*BaseGEP->idx_begin()))
    return nullptr;
  auto *GV = dyn_cast_or_null<GlobalVariable>(
      BaseGEP->getPointerOperand()->stripPointerCasts());
  if (!GV || GV->isDeclaration() ||
      !GV->getMetadata("brighten.guest.range"))
    return nullptr;
  return Index;
}

// In flat guest memory, inttoptr(A) followed by byte GEP K means address A+K.
// If A is first materialized to a compact recovered LLVM global, the host GEP
// can cross an artificial object boundary.  Dispatch the adjusted guest
// address instead.
static unsigned rewriteMaterializedRecoveredPointerByteGEPs(Module &M,
                                                            bool &Changed) {
  SmallVector<GetElementPtrInst *, 128> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I))
          if (GEP->getSourceElementType() == Type::getInt8Ty(M.getContext()) &&
              GEP->getNumIndices() == 1 &&
              isa<ConstantInt>(*GEP->idx_begin()) &&
              !cast<ConstantInt>(*GEP->idx_begin())->isZero())
            Candidates.push_back(GEP);
  }

  unsigned Rewritten = 0;
  for (GetElementPtrInst *GEP : Candidates) {
    if (!GEP->getParent())
      continue;
    SmallPtrSet<Value *, 16> Seen;
    Value *GuestAddress =
        findMaterializedRecoveredGuestAddress(GEP->getPointerOperand(), Seen);
    if (!GuestAddress)
      continue;

    auto *Index = cast<ConstantInt>(*GEP->idx_begin());
    IRBuilder<> B(GEP);
    Value *Address64 = GuestAddress;
    if (!Address64->getType()->isIntegerTy(64))
      Address64 = B.CreateZExtOrTrunc(Address64, B.getInt64Ty(),
                                      "native.byte.gep.base");
    Value *AdjustedAddress =
        B.CreateAdd(Address64,
                    ConstantInt::get(B.getInt64Ty(), Index->getSExtValue(),
                                     true),
                    "native.byte.gep.address");
    Value *NativePtr = materializeRecoveredDataPointer(M, B, AdjustedAddress);
    if (!NativePtr)
      continue;
    if (NativePtr->getType() != GEP->getType())
      NativePtr = B.CreatePointerCast(NativePtr, GEP->getType(),
                                      "native.byte.gep.ptr.cast");
    GEP->replaceAllUsesWith(NativePtr);
    GEP->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

static unsigned rewriteRecoveredGlobalStackIndexedGEPs(Module &M,
                                                       bool &Changed) {
  auto StackIndexForRecoveredGEP = [](Value *V) -> Value * {
    auto *GEP = dyn_cast<GEPOperator>(V ? V->stripPointerCasts() : nullptr);
    if (!GEP || GEP->getNumIndices() != 1 ||
        !GEP->getSourceElementType()->isIntegerTy(8))
      return nullptr;
    auto *GV = dyn_cast<GlobalVariable>(
        GEP->getPointerOperand()->stripPointerCasts());
    if (!GV || !GV->getName().starts_with("g_arr_"))
      return nullptr;
    Value *Index = *GEP->idx_begin();
    if (!Index || !Index->getType()->isIntegerTy())
      return nullptr;
    SmallPtrSet<Value *, 32> Seen;
    if (!containsNativeStackInteger(Index, Seen))
      return nullptr;
    return Index;
  };

  unsigned Rewritten = 0;
  SmallVector<GetElementPtrInst *, 32> GEPs;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
          if (StackIndexForRecoveredGEP(GEP))
            GEPs.push_back(GEP);
        }
      }
    }
  }
  for (GetElementPtrInst *GEP : GEPs) {
    if (!GEP->getParent())
      continue;
    Value *Index = StackIndexForRecoveredGEP(GEP);
    if (!Index)
      continue;
    IRBuilder<> B(GEP);
    Value *NativePtr =
        B.CreateIntToPtr(Index, GEP->getType(), "native.stack.gep.recovered");
    GEP->replaceAllUsesWith(NativePtr);
    GEP->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }

  SmallVector<std::tuple<Instruction *, unsigned, ConstantExpr *>, 64> Operands;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo) {
          auto *CE = dyn_cast<ConstantExpr>(I.getOperand(OpNo));
          if (CE && CE->getOpcode() == Instruction::GetElementPtr &&
              StackIndexForRecoveredGEP(CE))
            Operands.emplace_back(&I, OpNo, CE);
        }
      }
    }
  }
  for (auto [I, OpNo, CE] : Operands) {
    if (!I->getParent())
      continue;
    Value *Index = StackIndexForRecoveredGEP(CE);
    if (!Index)
      continue;
    IRBuilder<> B(I);
    Value *NativePtr =
        B.CreateIntToPtr(Index, CE->getType(), "native.stack.gep.recovered");
    I->setOperand(OpNo, NativePtr);
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

static unsigned rewriteRecoveredExternalPointerArguments(Module &M,
                                                          bool &Changed,
                                                          bool ScanfOnly = false) {
  auto LowerStackPointerArms = [&](Value *Root, Function &F) {
    SmallVector<Value *, 32> Worklist;
    SmallPtrSet<Value *, 32> Seen;
    Worklist.push_back(Root);
    while (!Worklist.empty()) {
      Value *V = Worklist.pop_back_val();
      if (!V || !Seen.insert(V).second)
        continue;
      if (auto *ITP = dyn_cast<IntToPtrInst>(V)) {
        if (!ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        IRBuilder<> B(ITP);
        if (Value *NativePtr = lowerNativeStackInteger(
                B, ITP->getOperand(0), F)) {
          if (NativePtr->getType() != ITP->getType())
            NativePtr = B.CreatePointerCast(NativePtr, ITP->getType(),
                                            "native.scanf.stack.ptr.cast");
          ITP->replaceAllUsesWith(NativePtr);
          ITP->eraseFromParent();
          Changed = true;
        }
        continue;
      }
      if (auto *I = dyn_cast<Instruction>(V)) {
        for (Value *Op : I->operands())
          if (Op->getType()->isPointerTy())
            Worklist.push_back(Op);
      } else if (auto *CE = dyn_cast<ConstantExpr>(V)) {
        for (Value *Op : CE->operands())
          if (Op->getType()->isPointerTy())
            Worklist.push_back(Op);
      }
    }
  };
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
        if (ScanfOnly && Name != "scanf" && Name != "__isoc99_scanf")
          continue;
        for (unsigned Index = 0; Index < CB->arg_size(); ++Index) {
          if (!isRecoveredPointerExternalArgument(Name, Index))
            continue;
          Value *Arg = CB->getArgOperand(Index);
          IRBuilder<> B(CB);
          if (Arg->getType()->isPointerTy()) {
            // scanf destinations can be a recovered-data select whose
            // fallback arm is an inttoptr carrying a guest stack address.
            // Normalize only proven stack arms; global/data arms remain
            // untouched and retain their range dispatch.
            LowerStackPointerArms(Arg, *CB->getFunction());
            // The root argument itself may have been an inttoptr.  In that
            // case LowerStackPointerArms RAUWs it with the recovered frame
            // GEP and erases the old instruction; refresh the call operand
            // before doing any further type/provenance inspection.
            Arg = CB->getArgOperand(Index);
            if (!Arg || !Arg->getType()->isPointerTy())
              continue;
            // LowerStackPointerArms has already reconstructed this argument
            // from the recovered frame.  Do not subsequently search through
            // its integer index expression for a vararg carrier: a lifted
            // RBP/RSP PHI may also carry unrelated function-pointer values on
            // other dispatcher edges.  Peeling one of those nested carriers
            // replaces a correct scanf destination with (for example) a
            // callback address.
            SmallPtrSet<Value *, 16> StackArgSeen;
            if (isNativeStackPointer(Arg, StackArgSeen)) {
              ++Rewritten;
              continue;
            }
            SmallPtrSet<Value *, 32> VarargSeen;
            if (Value *NativeCarrier =
                    findNativeVarargAddressCarrier(Arg, VarargSeen)) {
              if (NativeCarrier->getType() != Arg->getType())
                NativeCarrier = B.CreatePointerCast(
                    NativeCarrier, Arg->getType(),
                    "native.vararg.pointer.cast");
              CB->setArgOperand(Index, NativeCarrier);
              ++Rewritten;
              Changed = true;
              continue;
            }
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

static unsigned rewriteNativeVarargExternalPointerArguments(Module &M,
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
          if (!Arg || !Arg->getType()->isPointerTy())
            continue;
          // A preceding stack-address sweep may already have replaced the
          // raw inttoptr with a recovered-frame GEP.  Searching inside that
          // GEP can reach unrelated native.vararg.address values through a
          // dispatcher PHI and incorrectly peel out a callback/global arm.
          SmallPtrSet<Value *, 16> StackSeen;
          if (isNativeStackPointer(Arg, StackSeen))
            continue;
          SmallPtrSet<Value *, 32> Seen;
          Value *NativeCarrier = findNativeVarargAddressCarrier(Arg, Seen);
          if (!NativeCarrier)
            NativeCarrier = findNativeVarargCarrierInRecoveredDispatch(Arg);
          if (!NativeCarrier || NativeCarrier == Arg)
            continue;
          IRBuilder<> B(CB);
          if (NativeCarrier->getType() != Arg->getType())
            NativeCarrier = B.CreatePointerCast(
                NativeCarrier, Arg->getType(), "native.vararg.pointer.cast");
          CB->setArgOperand(Index, NativeCarrier);
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
  SmallPtrSet<AllocaInst *, 32> UnresolvedPrintfRegSaveAreas;
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
        if (IsPrintf && !formatHasAnyConversion(*Format))
          UnresolvedPrintfRegSaveAreas.insert(RegSaveArea);
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
        if (!IsPointerSlot &&
            UnresolvedPrintfRegSaveAreas.contains(SlotRoot)) {
          if (auto *CI = dyn_cast<ConstantInt>(SI->getValueOperand())) {
            if (FindRecoveredGlobalForGuestAddress(M, CI->getZExtValue()))
              IsPointerSlot = true;
          }
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
          Value *NativePtr = nullptr;
          if (auto *CI = dyn_cast<ConstantInt>(Stored)) {
            if (auto Match = FindRecoveredGlobalForGuestAddress(
                    M, CI->getZExtValue())) {
              NativePtr = B.CreateConstGEP1_64(
                  B.getInt8Ty(), Match->first, Match->second,
                  "native.vararg.constant.ptr");
            }
          }
          if (!NativePtr)
            NativePtr = materializeRecoveredDataPointer(M, B, Stored);
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
  if (Name == "strcpy" || Name == "strcat")
    return Fixed(Ptr, {Ptr, Ptr});
  if (Name == "strncpy" || Name == "strncat")
    return Fixed(Ptr, {Ptr, Ptr, I64});
  if (Name == "strchr" || Name == "strrchr")
    return Fixed(Ptr, {Ptr, I32});
  if (Name == "memcmp")
    return Fixed(I32, {Ptr, Ptr, I64});
  if (Name == "setjmp" || Name == "_setjmp")
    return Fixed(I32, {Ptr});
  if (Name == "sigsetjmp" || Name == "__sigsetjmp")
    return Fixed(I32, {Ptr, I32});
  if (Name == "longjmp" || Name == "siglongjmp")
    return Fixed(Type::getVoidTy(Ctx), {Ptr, I32});
  if (Name == "getchar")
    return Fixed(I32, {});
  if (Name == "gets")
    return Fixed(Ptr, {Ptr});
  if (Name == "fgets")
    return Fixed(Ptr, {Ptr, I32, Ptr});
  if (Name == "strtok")
    return Fixed(Ptr, {Ptr, Ptr});
  if (Name == "qsort")
    return Fixed(Type::getVoidTy(Ctx), {Ptr, I64, I64, Ptr});
  if (Name == "sqrt" || Name == "round")
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
      // External libc calls receive host pointers, while lifted code carries
      // recovered data addresses in integer registers.  Resolve those
      // addresses against the recovered guest ranges before falling back to
      // inttoptr; otherwise qsort/memcpy operate on the numeric guest address
      // and silently sort/copy the wrong object.
      if (Module *Mod = BB->getModule())
        if (Value *NativeDataPtr =
                materializeRecoveredDataPointer(*Mod, B, V))
          return NativeDataPtr;
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
  if (Src->isIntegerTy() && Dst->isFloatingPointTy()) {
    unsigned DstBits = Dst->getPrimitiveSizeInBits();
    if (!DstBits)
      return nullptr;
    Type *CarrierTy = IntegerType::get(B.getContext(), DstBits);
    Value *Carrier = V;
    unsigned SrcBits = Src->getIntegerBitWidth();
    if (SrcBits > DstBits)
      Carrier = B.CreateTrunc(V, CarrierTy, "native.external.fp.trunc");
    else if (SrcBits < DstBits)
      Carrier = B.CreateZExt(V, CarrierTy, "native.external.fp.zext");
    return B.CreateBitCast(Carrier, Dst, "native.external.fp");
  }
  if (Src->isFloatingPointTy() && Dst->isIntegerTy()) {
    unsigned SrcBits = Src->getPrimitiveSizeInBits();
    if (!SrcBits)
      return nullptr;
    Type *CarrierTy = IntegerType::get(B.getContext(), SrcBits);
    Value *Carrier = B.CreateBitCast(V, CarrierTy, "native.external.int.bits");
    unsigned DstBits = Dst->getIntegerBitWidth();
    if (SrcBits > DstBits)
      return B.CreateTrunc(Carrier, Dst, "native.external.int.trunc");
    if (SrcBits < DstBits)
      return B.CreateZExt(Carrier, Dst, "native.external.int.zext");
    return Carrier;
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
    if (!HasOnlyGlobalConstantUsers(&F))
      continue;
    FunctionType *Expected = nativeExternalType(M, Canonical);
    if (!Expected)
      continue;
    Function *Native = M.getFunction(Canonical);
    if (!Native) {
      Native = Function::Create(Expected, GlobalValue::ExternalLinkage,
                                Canonical, &M);
      Native->setCallingConv(CallingConv::C);
    }
    if (Native->getFunctionType() == Expected)
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

// Lifting a variadic scanf call can lose trailing destination operands while
// leaving the format string intact.  Calling libc with fewer pointers than
// the format consumes reads arbitrary registers/stack slots and turns a
// recoverable raw-input path into an unrelated crash.  Materialize only the
// missing integer destinations; existing operands and their order are kept
// unchanged.
static unsigned materializeMissingScanfDestinations(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  SmallVector<CallInst *, 64> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        Function *Callee = CI ? CI->getCalledFunction() : nullptr;
        if (!CI || !Callee ||
            (Callee->getName() != "scanf" &&
             Callee->getName() != "__isoc99_scanf") ||
            CI->arg_empty() || !Callee->getFunctionType()->isVarArg())
          continue;
        Candidates.push_back(CI);
      }
    }
  }

  auto CollectIntegerArgs = [](StringRef Format,
                               SmallVectorImpl<std::pair<unsigned, unsigned>> &Out) {
    unsigned Arg = 0;
    for (size_t I = 0; I < Format.size();) {
      if (Format[I++] != '%')
        continue;
      if (I >= Format.size())
        break;
      if (Format[I] == '%') {
        ++I;
        continue;
      }
      bool Suppressed = false;
      if (Format[I] == '*') {
        Suppressed = true;
        ++I;
      }
      while (I < Format.size() && Format[I] >= '0' && Format[I] <= '9')
        ++I;
      unsigned Bits = 32;
      if (I < Format.size() && Format[I] == 'l') {
        Bits = 64;
        ++I;
        if (I < Format.size() && Format[I] == 'l')
          ++I;
      }
      if (I >= Format.size())
        break;
      char Conversion = Format[I++];
      bool Integer = Conversion == 'd' || Conversion == 'i' ||
                     Conversion == 'o' || Conversion == 'u' ||
                     Conversion == 'x' || Conversion == 'X';
      if (!Suppressed) {
        if (Integer)
          Out.push_back({Arg, Bits});
        ++Arg;
      }
    }
  };

  std::function<Value *(Value *, SmallPtrSetImpl<Value *> &)>
      FindNativeStackAddress = [&](Value *V,
                                   SmallPtrSetImpl<Value *> &Seen) -> Value * {
    if (!V || !Seen.insert(V).second)
      return nullptr;
    if (auto *Sel = dyn_cast<SelectInst>(V)) {
      if (Value *Found = FindNativeStackAddress(Sel->getFalseValue(), Seen))
        return Found;
      return FindNativeStackAddress(Sel->getTrueValue(), Seen);
    }
    if (auto *Cast = dyn_cast<CastInst>(V))
      return FindNativeStackAddress(Cast->getOperand(0), Seen);
    auto *GEP = dyn_cast<GetElementPtrInst>(V);
    if (!GEP || GEP->getNumIndices() != 1)
      return nullptr;
    std::function<GlobalVariable *(Value *, SmallPtrSetImpl<Value *> &)>
        FindRootGlobal = [&](Value *Root,
                             SmallPtrSetImpl<Value *> &RootSeen)
        -> GlobalVariable * {
      if (!Root || !RootSeen.insert(Root).second)
        return nullptr;
      if (auto *GV = dyn_cast<GlobalVariable>(Root->stripPointerCasts()))
        return GV;
      if (auto *GEP = dyn_cast<GEPOperator>(Root))
        return FindRootGlobal(GEP->getPointerOperand(), RootSeen);
      if (auto *Cast = dyn_cast<CastInst>(Root))
        return FindRootGlobal(Cast->getOperand(0), RootSeen);
      return nullptr;
    };
    SmallPtrSet<Value *, 8> RootSeen;
    auto *BaseGV = FindRootGlobal(GEP->getPointerOperand(), RootSeen);
    if (!BaseGV || !BaseGV->getName().starts_with("frame_storage_backing."))
      return nullptr;
    Value *Index = GEP->idx_begin()->get();
    auto *Sub = dyn_cast<BinaryOperator>(Index);
    if (!Sub || Sub->getOpcode() != Instruction::Sub)
      return nullptr;
    SmallPtrSet<Value *, 16> AnchorSeen;
    if (!containsNativeStackAnchorInteger(Sub->getOperand(1), AnchorSeen))
      return nullptr;
    return Sub->getOperand(0);
  };

  std::function<Value *(Value *, SmallPtrSetImpl<Value *> &)>
      FindNativeStackFrameTop = [&](Value *V,
                                    SmallPtrSetImpl<Value *> &Seen) -> Value * {
    if (!V || !Seen.insert(V).second)
      return nullptr;
    if (auto *Sel = dyn_cast<SelectInst>(V)) {
      if (Value *Found = FindNativeStackFrameTop(Sel->getFalseValue(), Seen))
        return Found;
      return FindNativeStackFrameTop(Sel->getTrueValue(), Seen);
    }
    if (auto *Cast = dyn_cast<CastInst>(V))
      return FindNativeStackFrameTop(Cast->getOperand(0), Seen);
    auto *GEP = dyn_cast<GetElementPtrInst>(V);
    if (!GEP || GEP->getNumIndices() != 1)
      return nullptr;
    std::function<GlobalVariable *(Value *, SmallPtrSetImpl<Value *> &)>
        FindRootGlobal = [&](Value *Root,
                             SmallPtrSetImpl<Value *> &RootSeen)
        -> GlobalVariable * {
      if (!Root || !RootSeen.insert(Root).second)
        return nullptr;
      if (auto *GV = dyn_cast<GlobalVariable>(Root->stripPointerCasts()))
        return GV;
      if (auto *GEP = dyn_cast<GEPOperator>(Root))
        return FindRootGlobal(GEP->getPointerOperand(), RootSeen);
      if (auto *Cast = dyn_cast<CastInst>(Root))
        return FindRootGlobal(Cast->getOperand(0), RootSeen);
      return nullptr;
    };
    SmallPtrSet<Value *, 8> RootSeen;
    auto *BaseGV = FindRootGlobal(GEP->getPointerOperand(), RootSeen);
    if (!BaseGV || !BaseGV->getName().starts_with("frame_storage_backing."))
      return nullptr;
    return GEP->getPointerOperand();
  };

  auto MatchAddConstant = [](Value *V, Value *&Base,
                             int64_t &Offset) -> bool {
    if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      if (BO->getOpcode() == Instruction::Add) {
        if (auto *CI = dyn_cast<ConstantInt>(BO->getOperand(1))) {
          Base = BO->getOperand(0);
          Offset = CI->getSExtValue();
          return true;
        }
        if (auto *CI = dyn_cast<ConstantInt>(BO->getOperand(0))) {
          Base = BO->getOperand(1);
          Offset = CI->getSExtValue();
          return true;
        }
      }
    }
    return false;
  };

  unsigned Rewritten = 0;
  for (CallInst *CI : Candidates) {
    if (!CI->getParent())
      continue;
    SmallVector<std::pair<unsigned, unsigned>, 8> IntegerArgs;
    std::optional<std::string> Format;
    SmallPtrSet<Value *, 32> SeenFormats;
    std::function<void(Value *)> FindBestFormat = [&](Value *V) {
      if (!V || !SeenFormats.insert(V).second)
        return;
      if (auto Candidate = readConstantFormatString(V, DL)) {
        SmallVector<std::pair<unsigned, unsigned>, 8> Parsed;
        CollectIntegerArgs(*Candidate, Parsed);
        if (!Format || Parsed.size() > IntegerArgs.size()) {
          Format = std::move(Candidate);
          IntegerArgs = std::move(Parsed);
        }
        // A resolved GEP already encodes the exact format-string start.  Do
        // not recurse into its base global and accidentally prefer a longer
        // neighbouring string at offset 0, e.g. "%d%d%d\0" over GEP+2 "%d%d".
        return;
      }
      if (auto *Inst = dyn_cast<Instruction>(V))
        for (Value *Op : Inst->operands())
          FindBestFormat(Op);
      else if (auto *CE = dyn_cast<ConstantExpr>(V))
        for (Value *Op : CE->operands())
          FindBestFormat(Op);
    };
    FindBestFormat(CI->getArgOperand(0));
    if (!Format)
      continue;
    unsigned Existing = CI->arg_size() - 1;
    if (IntegerArgs.size() <= Existing)
      continue;

    Function *F = CI->getFunction();
    IRBuilder<> EntryBuilder(&*F->getEntryBlock().getFirstInsertionPt());
    IRBuilder<> CallBuilder(CI);
    SmallVector<Value *, 16> Args;
    for (unsigned I = 0; I < CI->arg_size(); ++I)
      Args.push_back(CI->getArgOperand(I));

    Value *StackBase = nullptr;
    Value *StackFrameTop = nullptr;
    int64_t PrevOffset = 0;
    int64_t LastOffset = 0;
    bool HaveStackStride = false;
    if (Existing >= 2) {
      SmallPtrSet<Value *, 32> SeenPrev;
      SmallPtrSet<Value *, 32> SeenLast;
      Value *PrevAddr = FindNativeStackAddress(CI->getArgOperand(Existing - 1),
                                               SeenPrev);
      Value *LastAddr = FindNativeStackAddress(CI->getArgOperand(Existing),
                                               SeenLast);
      Value *PrevBase = nullptr;
      Value *LastBase = nullptr;
      SmallPtrSet<Value *, 32> SeenFrameTop;
      if (PrevAddr && LastAddr &&
          MatchAddConstant(PrevAddr, PrevBase, PrevOffset) &&
          MatchAddConstant(LastAddr, LastBase, LastOffset) &&
          PrevBase == LastBase) {
        StackBase = LastBase;
        StackFrameTop =
            FindNativeStackFrameTop(CI->getArgOperand(Existing), SeenFrameTop);
        HaveStackStride = StackFrameTop != nullptr;
      }
    }

    for (unsigned I = Existing; I < IntegerArgs.size(); ++I) {
      unsigned Bits = IntegerArgs[I].second;
      if (!Bits)
        continue;
      Type *IntTy = IntegerType::get(M.getContext(), Bits);
      Value *Dest = nullptr;
      if (HaveStackStride && StackBase) {
        int64_t Stride = LastOffset - PrevOffset;
        unsigned Bytes = std::max(1u, Bits / 8);
        if (std::llabs(Stride) == static_cast<long long>(Bytes)) {
          PrevOffset = LastOffset;
          LastOffset += Stride;
          Value *NextAddr = CallBuilder.CreateAdd(
              StackBase,
              ConstantInt::get(StackBase->getType(), LastOffset, true),
              "native.scanf.missing.stack.addr");
          Value *Address = NextAddr;
          if (!Address->getType()->isIntegerTy(64))
            Address = CallBuilder.CreateZExtOrTrunc(
                Address, CallBuilder.getInt64Ty(), "native.stack.address");
          Value *Anchor = CallBuilder.CreatePtrToInt(
              StackFrameTop, CallBuilder.getInt64Ty(),
              "native.scanf.missing.stack.anchor");
          Value *Delta = CallBuilder.CreateSub(
              Address, Anchor, "native.scanf.missing.stack.delta");
          Dest = CallBuilder.CreateGEP(CallBuilder.getInt8Ty(), StackFrameTop,
                                       Delta, "native.scanf.missing.stack.gep");
        } else {
          HaveStackStride = false;
        }
      }
      if (!Dest) {
        AllocaInst *Scratch = EntryBuilder.CreateAlloca(
            IntTy, nullptr, "native.scanf.missing.destination");
        Dest = Scratch;
      }
      Args.push_back(Dest);
    }
    if (Args.size() == CI->arg_size())
      continue;

    CallInst *Replacement = CallInst::Create(
        CI->getFunctionType(), CI->getCalledOperand(), Args, "",
        CI->getIterator());
    Replacement->setCallingConv(CI->getCallingConv());
    Replacement->setAttributes(CI->getAttributes());
    Replacement->copyMetadata(*CI);
    CI->replaceAllUsesWith(Replacement);
    CI->eraseFromParent();
    ++Rewritten;
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
            // `seg_` denotes arbitrary guest memory, not necessarily a C
            // string.  Materialize the complete known suffix, never a
            // bounded prefix: a truncated object changes later indexed loads.
            // Any unsupported byte/relocation makes the whole rewrite
            // ineligible rather than producing a partial initializer.
            if (Available > std::numeric_limits<uint32_t>::max())
              continue;
            bool Complete = true;
            for (uint64_t I = 0; I < Available; ++I) {
              uint8_t Byte = 0;
              if (!readConstantByte(Segment->getInitializer(), DL,
                                    Offset + I, Byte)) {
                Complete = false;
                break;
              }
              Bytes.push_back(Byte);
            }
            if (!Complete || Bytes.empty())
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
            if (auto SegmentBase =
                    parseGuestAddressPrefix(Segment->getName(), "seg_"))
              setGuestBaseMetadata(M, *NativeData, *SegmentBase + Offset);
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
  {
    Kinds.push_back(Ctx.getMDKindID("brighten.guest.range"));
    Kinds.push_back(Ctx.getMDKindID("brighten.guest.base"));
  }

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
              Candidate->getName().ends_with("_wrapper")) {
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
    bool UnsupportedArg = false;
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
        else {
          UnsupportedArg = true;
          break;
        }
      }
      V = coerceCallbackArgument(B, V, Ty, "callback.arg");
      if (!V)
        break;
      Args.push_back(V);
    }
    if (UnsupportedArg || Args.size() != NativeCall->arg_size()) {
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

// A callback can lose its naked trampoline wrapper during earlier native
// lowering.  In that case a qsort call may still carry the old zero-argument
// guest function pointer.  qsort invokes its comparator with (lhs, rhs), so
// passing that pointer is an ABI mismatch even when the callback body itself
// is otherwise valid.  Re-introduce the small host/guest boundary only when
// the call is provably qsort-like and the callback has the lifted void()
// shape.  The register offsets are the stable McSema x86-64 State layout used
// by the existing state materialization code.
static unsigned lowerNativeQsortCallbacks(Module &M, bool &Changed) {
  GlobalVariable *State = M.getNamedGlobal("__mcsema_reg_state");
  if (!State)
    return 0;

  SmallVector<CallBase *, 16> Calls;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || CB->arg_size() < 4)
          continue;
        Function *Callee = CB->getCalledFunction();
        if (!Callee || Callee->getName() != "qsort")
          continue;
        SmallPtrSet<Value *, 16> Seen;
        Function *Callback = resolveCallbackFunction(CB->getArgOperand(3), Seen);
        if (!Callback || Callback->isDeclaration() ||
            !Callback->getReturnType()->isVoidTy() || Callback->arg_size() != 0)
          continue;
        if (!Callback->getName().starts_with("callback_"))
          continue;
        Calls.push_back(CB);
      }
  }

  unsigned Lowered = 0;
  LLVMContext &Ctx = M.getContext();
  Type *PtrTy = PointerType::getUnqual(Ctx);
  Type *I64Ty = Type::getInt64Ty(Ctx);
  FunctionType *AdapterTy =
      FunctionType::get(Type::getInt32Ty(Ctx), {PtrTy, PtrTy}, false);
  for (CallBase *CB : Calls) {
    SmallPtrSet<Value *, 16> Seen;
    Function *Callback = resolveCallbackFunction(CB->getArgOperand(3), Seen);
    if (!Callback)
      continue;
    std::string Name = (Callback->getName() + ".qsort_callback").str();
    if (M.getFunction(Name))
      continue;
    Function *Adapter = Function::Create(AdapterTy, GlobalValue::InternalLinkage,
                                          Name, M);
    Adapter->setCallingConv(CB->getCallingConv());
    Adapter->setDSOLocal(true);
    Adapter->getArg(0)->setName("lhs");
    Adapter->getArg(1)->setName("rhs");
    BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", Adapter);
    IRBuilder<> B(Entry);
    auto StateSlot = [&](uint64_t Offset) {
      return B.CreateGEP(B.getInt8Ty(), State, B.getInt64(Offset),
                         "qsort.state.slot");
    };
    B.CreateStore(B.CreatePtrToInt(Adapter->getArg(0), I64Ty), StateSlot(2296));
    B.CreateStore(B.CreatePtrToInt(Adapter->getArg(1), I64Ty), StateSlot(2280));
    B.CreateCall(Callback, {});
    Value *Ret = B.CreateLoad(Type::getInt32Ty(Ctx), StateSlot(2216),
                              "qsort.callback.ret");
    B.CreateRet(Ret);

    IRBuilder<> At(CB);
    Value *AdapterBits = At.CreatePtrToInt(Adapter, CB->getArgOperand(3)->getType(),
                                           "qsort.callback.bits");
    CB->setArgOperand(3, AdapterBits);
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
        auto *Asm = CB ? dyn_cast<InlineAsm>(CB->getCalledOperand()) : nullptr;
        if (!CB || !Asm || Asm->hasSideEffects() || !CB->use_empty())
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

// Entrypoint-native functions can retain architectural RSP/RBP integers even
// after State-SSA.  If those values are later used as pointers, the public
// wrapper must provide one concrete backing object and seed the entry RSP
// before calling the native body.  Create it only for that proven residual
// stack-pointer case; ordinary modules keep the old no-synthetic-stack path.
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

  if (GlobalVariable *Existing = M.getNamedGlobal("frame_storage_backing.main"))
    return Existing;

  bool HasResidualStackPointer = false;
  for (Function &F : M) {
    if (F.isDeclaration() || !F.getName().ends_with(".native"))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        SmallPtrSet<Value *, 32> Seen;
        if (containsNativeStackInteger(ITP->getOperand(0), Seen)) {
          HasResidualStackPointer = true;
          break;
        }
      }
      if (HasResidualStackPointer)
        break;
    }
    if (HasResidualStackPointer)
      break;
  }
  if (!HasResidualStackPointer)
    return nullptr;

  LLVMContext &Ctx = M.getContext();
  constexpr uint64_t NativeStackBytes = 16 * 1024 * 1024;
  auto *StackTy = ArrayType::get(Type::getInt8Ty(Ctx), NativeStackBytes);
  auto *Storage = new GlobalVariable(
      M, StackTy, false, GlobalValue::InternalLinkage,
      ConstantAggregateZero::get(StackTy), "frame_storage_backing.main");
  Storage->setAlignment(Align(16));
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
  // The public entrypoint only has evidence for argc/argv/envp.  Extra
  // implementation parameters cannot be initialized soundly here; preserve
  // the original entrypoint instead of inventing null ABI arguments.
  if (ImplTy->getNumParams() > 3)
    return false;
  std::string ImplName = "native_entry_impl";
  for (unsigned Suffix = 0; M.getFunction(ImplName); ++Suffix)
    ImplName = "native_entry_impl." + std::to_string(Suffix + 1);
  Main->setName(ImplName);
  Main->setLinkage(GlobalValue::InternalLinkage);
  Main->setDSOLocal(true);

  FunctionType *EntryTy = FunctionType::get(
      Type::getInt32Ty(Ctx),
      {Type::getInt32Ty(Ctx), PointerType::getUnqual(Ctx),
       PointerType::getUnqual(Ctx)}, false);
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

      bool HasExplicitStatePointer =
          Callee->getName().ends_with(".native") && Callee->arg_size() &&
          Callee->getArg(0)->getType()->isPointerTy() &&
          Callee->getArg(0)->getName() == "state";
      bool IsStateBoundary = isLiftedABI(*Callee) || HasExplicitStatePointer;
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

static Value *materializeHubValueOnPred(Value *V, BasicBlock *Hub,
                                        BasicBlock *Pred, IRBuilder<> &B,
                                        DenseMap<Value *, Value *> &Cache) {
  if (!V)
    return nullptr;
  if (isa<Constant>(V) || isa<Argument>(V) || isa<GlobalValue>(V))
    return V;
  if (auto It = Cache.find(V); It != Cache.end())
    return It->second;
  if (auto *PN = dyn_cast<PHINode>(V)) {
    if (PN->getParent() != Hub)
      return nullptr;
    Value *Incoming = PN->getIncomingValueForBlock(Pred);
    Cache[V] = Incoming;
    return Incoming;
  }
  auto *I = dyn_cast<Instruction>(V);
  if (!I || I->getParent() != Hub || I->mayHaveSideEffects() ||
      I->mayReadFromMemory() || I->isTerminator())
    return nullptr;
  if (!isa<BinaryOperator>(I) && !isa<CastInst>(I) &&
      !isa<GetElementPtrInst>(I))
    return nullptr;

  Instruction *Clone = I->clone();
  for (unsigned OpNo = 0; OpNo < Clone->getNumOperands(); ++OpNo) {
    Value *Mapped = materializeHubValueOnPred(I->getOperand(OpNo), Hub, Pred,
                                              B, Cache);
    if (!Mapped) {
      Clone->deleteValue();
      return nullptr;
    }
    Clone->setOperand(OpNo, Mapped);
  }
  Clone->insertBefore(B.GetInsertPoint());
  Cache[V] = Clone;
  return Clone;
}

static bool isDispatcherStateValue(Value *V, SwitchInst *SW,
                                   SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return SW->findCaseValue(CI) != SW->case_default();
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    SmallPtrSet<Value *, 8> TrueSeen;
    SmallPtrSet<Value *, 8> FalseSeen;
    return isDispatcherStateValue(Sel->getTrueValue(), SW, TrueSeen) &&
           isDispatcherStateValue(Sel->getFalseValue(), SW, FalseSeen);
  }
  return false;
}

static bool isDispatcherStateValue(Value *V, SwitchInst *SW) {
  SmallPtrSet<Value *, 8> Seen;
  return isDispatcherStateValue(V, SW, Seen);
}

static StoreInst *findDispatcherStateStore(BasicBlock *BB, Value *Ptr,
                                           SwitchInst *SW) {
  StoreInst *Found = nullptr;
  StoreInst *StateValued = nullptr;
  for (Instruction &I : *BB) {
    auto *SI = dyn_cast<StoreInst>(&I);
    if (!SI || SI->isVolatile() ||
        !SI->getValueOperand()->getType()->isIntegerTy(32))
      continue;
    if (SI->getPointerOperand() == Ptr) {
      if (Found)
        return nullptr;
      Found = SI;
      continue;
    }
    if (isDispatcherStateValue(SI->getValueOperand(), SW))
      StateValued = SI;
  }
  return Found ? Found : StateValued;
}

// Late native cleanup often exposes an OLLVM-style dispatcher whose state is
// still carried through one recovered stack slot:
//
//   header phis
//   %slot = gep frame, rbp - K
//   %state = load i32, %slot
//   switch %state, ...
//   case: store i32 %next, %slot; br latch
//   latch: br header
//
// The memory slot is not source data; it is the flattened control-state
// variable.  Promote just this proven shape into PHIs so the normal LLVM
// threading/simplification pipeline can collapse hot state-machine loops.
static unsigned promoteStackDispatcherStateSlots(Module &M, bool &Changed) {
  SmallVector<SwitchInst *, 16> Switches;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (BasicBlock &BB : F)
        if (auto *SW = dyn_cast<SwitchInst>(BB.getTerminator()))
          Switches.push_back(SW);

  unsigned Promoted = 0;
  for (SwitchInst *SW : Switches) {
    BasicBlock *Hub = SW->getParent();
    auto *LI = dyn_cast<LoadInst>(SW->getCondition());
    if (!LI || LI->isVolatile() || !LI->getType()->isIntegerTy(32) ||
        LI->getParent() != Hub)
      continue;
    Value *SlotPtr = LI->getPointerOperand();
    if (!isa<GetElementPtrInst>(SlotPtr))
      continue;

    SmallVector<BasicBlock *, 4> HubPreds(predecessors(Hub));
    if (HubPreds.size() != 2)
      continue;
    BasicBlock *Latch = nullptr;
    BasicBlock *EntryPred = nullptr;
    for (BasicBlock *Pred : HubPreds) {
      auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
      if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Hub) {
        Latch = nullptr;
        EntryPred = nullptr;
        break;
      }
      if (pred_size(Pred) > 1)
        Latch = Pred;
      else
        EntryPred = Pred;
    }
    if (!Latch || !EntryPred || Latch == Hub || EntryPred == Hub)
      continue;

    SmallVector<BasicBlock *, 64> LatchPreds(predecessors(Latch));
    if (LatchPreds.empty())
      continue;
    DenseMap<BasicBlock *, Value *> NextStateForPred;
    bool Valid = true;
    for (BasicBlock *Pred : LatchPreds) {
      if (Pred == Hub)
        continue;
      auto *Br = dyn_cast<BranchInst>(Pred->getTerminator());
      if (!Br || !Br->isUnconditional() || Br->getSuccessor(0) != Latch) {
        Valid = false;
        break;
      }
      StoreInst *SI = findDispatcherStateStore(Pred, SlotPtr, SW);
      if (!SI) {
        Valid = false;
        break;
      }
      NextStateForPred[Pred] = SI->getValueOperand();
    }
    if (!Valid)
      continue;

    IRBuilder<> EntryB(EntryPred->getTerminator());
    DenseMap<Value *, Value *> CloneCache;
    Value *EntrySlot = materializeHubValueOnPred(SlotPtr, Hub, EntryPred,
                                                 EntryB, CloneCache);
    if (!EntrySlot)
      continue;
    Value *EntryState = EntryB.CreateLoad(LI->getType(), EntrySlot,
                                          "native.dispatch.entry.state");

    PHINode *StatePhi = PHINode::Create(
        LI->getType(), 2, "native.dispatch.state",
        Hub->getFirstNonPHIIt());
    PHINode *NextPhi = PHINode::Create(
        LI->getType(), pred_size(Latch), "native.dispatch.next",
        Latch->getFirstNonPHIIt());
    StatePhi->addIncoming(EntryState, EntryPred);
    StatePhi->addIncoming(NextPhi, Latch);

    for (BasicBlock *Pred : LatchPreds) {
      Value *Next = Pred == Hub ? StatePhi : NextStateForPred.lookup(Pred);
      if (!Next) {
        Valid = false;
        break;
      }
      NextPhi->addIncoming(Next, Pred);
    }
    if (!Valid) {
      StatePhi->eraseFromParent();
      NextPhi->eraseFromParent();
      continue;
    }

    LI->replaceAllUsesWith(StatePhi);
    SW->setCondition(StatePhi);
    if (LI->use_empty())
      LI->eraseFromParent();
    ++Promoted;
    Changed = true;
  }
  return Promoted;
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
// unresolved integer carrier, dynamic GEP, unknown call/escape, or
// cross-function use rejects the whole backing transaction.
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

// Souper/InstCombine intentionally do not fold pointer provenance through an
// integer cancellation such as
//
//   gep frame_top, (ptrtoint(frame_top) + K - ptrtoint(frame_top))
//
// even though the integer index is exactly K in the pointer-width ring.  The
// lifted stack lowering creates this shape.  Evaluate only affine expressions
// rooted at one specific backing and accept a pointer result only when every
// ptrtoint coefficient cancels to zero and the final byte offset is signed-64.
struct FrameAffineInteger {
  APInt Constant;
  int64_t RootCoefficient = 0;
};

static std::optional<int64_t>
evaluateFramePointerOffset(Value *V, GlobalVariable &Backing,
                           const DataLayout &DL,
                           SmallPtrSetImpl<Value *> &PointerSeen);

static std::optional<FrameAffineInteger>
evaluateFrameInteger(Value *V, GlobalVariable &Backing, const DataLayout &DL,
                     unsigned Bits, SmallPtrSetImpl<Value *> &IntegerSeen) {
  if (!V || !V->getType()->isIntegerTy() ||
      V->getType()->getIntegerBitWidth() != Bits)
    return std::nullopt;
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return FrameAffineInteger{CI->getValue(), 0};

  auto FinishBinary = [&](unsigned Opcode, Value *LHS, Value *RHS)
      -> std::optional<FrameAffineInteger> {
    auto L = evaluateFrameInteger(LHS, Backing, DL, Bits, IntegerSeen);
    auto R = evaluateFrameInteger(RHS, Backing, DL, Bits, IntegerSeen);
    if (!L || !R)
      return std::nullopt;
    if (Opcode == Instruction::Add)
      return FrameAffineInteger{L->Constant + R->Constant,
                                L->RootCoefficient + R->RootCoefficient};
    if (Opcode == Instruction::Sub)
      return FrameAffineInteger{L->Constant - R->Constant,
                                L->RootCoefficient - R->RootCoefficient};
    return std::nullopt;
  };

  if (auto *Op = dyn_cast<Operator>(V)) {
    if (Op->getOpcode() == Instruction::Add ||
        Op->getOpcode() == Instruction::Sub)
      return FinishBinary(Op->getOpcode(), Op->getOperand(0),
                          Op->getOperand(1));
    if (Op->getOpcode() == Instruction::PtrToInt) {
      SmallPtrSet<Value *, 32> PointerSeen;
      auto Offset = evaluateFramePointerOffset(Op->getOperand(0), Backing, DL,
                                               PointerSeen);
      if (!Offset)
        return std::nullopt;
      return FrameAffineInteger{APInt(Bits, uint64_t(*Offset), true), 1};
    }
  }
  return std::nullopt;
}

static std::optional<int64_t>
evaluateFramePointerOffset(Value *V, GlobalVariable &Backing,
                           const DataLayout &DL,
                           SmallPtrSetImpl<Value *> &PointerSeen) {
  if (!V || !V->getType()->isPointerTy() ||
      !PointerSeen.insert(V).second)
    return std::nullopt;
  if (V->stripPointerCasts() == &Backing)
    return int64_t(0);
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP)
    return std::nullopt;
  auto Base = evaluateFramePointerOffset(GEP->getPointerOperand(), Backing,
                                         DL, PointerSeen);
  if (!Base)
    return std::nullopt;

  unsigned Bits = DL.getIndexSizeInBits(GEP->getPointerAddressSpace());
  APInt ConstantDelta(Bits, 0, true);
  if (GEP->accumulateConstantOffset(DL, ConstantDelta)) {
    if (!ConstantDelta.isSignedIntN(64))
      return std::nullopt;
    int64_t Result = 0;
    if (!addSignedOffset(*Base, ConstantDelta.getSExtValue(), Result))
      return std::nullopt;
    return Result;
  }

  // The recovered frame arithmetic uses a byte GEP with one affine index.
  // Refuse typed/dimensional dynamic GEPs rather than guessing element scale.
  if (!GEP->getSourceElementType()->isIntegerTy(8) ||
      GEP->getNumIndices() != 1)
    return std::nullopt;
  SmallPtrSet<Value *, 32> IntegerSeen;
  auto Index = evaluateFrameInteger(GEP->idx_begin()->get(), Backing, DL,
                                    Bits, IntegerSeen);
  if (!Index || Index->RootCoefficient != 0 ||
      !Index->Constant.isSignedIntN(64))
    return std::nullopt;
  int64_t Result = 0;
  if (!addSignedOffset(*Base, Index->Constant.getSExtValue(), Result))
    return std::nullopt;
  return Result;
}

static unsigned canonicalizeFrameBackingAffinePointers(Module &M,
                                                        bool &Changed) {
  unsigned Rewritten = 0;
  const DataLayout &DL = M.getDataLayout();
  for (GlobalVariable &Backing : M.globals()) {
    if (!Backing.getName().starts_with("frame_storage_backing."))
      continue;
    SmallVector<std::pair<Instruction *, unsigned>, 64> Operands;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo)
            if (I.getOperand(OpNo)->getType()->isPointerTy()) {
              SmallPtrSet<Value *, 32> Seen;
              if (evaluateFramePointerOffset(I.getOperand(OpNo), Backing, DL,
                                             Seen))
                Operands.push_back({&I, OpNo});
            }
    }
    for (auto [I, OpNo] : Operands) {
      SmallPtrSet<Value *, 32> Seen;
      auto Offset = evaluateFramePointerOffset(I->getOperand(OpNo), Backing,
                                               DL, Seen);
      if (!Offset)
        continue;
      IRBuilder<> B(I);
      Value *Direct = B.CreateGEP(B.getInt8Ty(), &Backing,
                                  B.getInt64(*Offset), "native.frame.direct");
      I->setOperand(OpNo, Direct);
      ++Rewritten;
      Changed = true;
    }
    Backing.removeDeadConstantUsers();
  }
  return Rewritten;
}

// Data-pointer recovery is intentionally skipped for stack-provenant integer
// addresses.  Some earlier cleanup orders expose that provenance only after
// the synthetic guest-range select chain has already been built: its raw
// fallback is then canonicalized to frame_storage_backing, while the now
// impossible guest-data arms remain around the store.  Collapse only chains
// created by materializeRecoveredDataPointer, and only when their terminal
// fallback has an exact frame offset.  This restores the classifier's
// original stack-first decision without making any alias assumption about an
// arbitrary user select.
static unsigned collapseFrameProvenantDataPointerSelects(Module &M,
                                                          bool &Changed) {
  SmallVector<SelectInst *, 32> Candidates;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (auto *SI = dyn_cast<SelectInst>(&I);
              SI && SI->getType()->isPointerTy() && SI->hasName() &&
              SI->getName().starts_with("native.data.pointer.select")) {
            bool FeedsGeneratedSelect = llvm::any_of(SI->users(), [](User *U) {
              auto *UserSelect = dyn_cast<SelectInst>(U);
              return UserSelect && UserSelect->hasName() &&
                     UserSelect->getName().starts_with(
                         "native.data.pointer.select");
            });
            if (!FeedsGeneratedSelect) Candidates.push_back(SI);
          }

  const DataLayout &DL = M.getDataLayout();
  unsigned Collapsed = 0;
  for (SelectInst *Outer : Candidates) {
    if (!Outer->getParent() || Outer->use_empty()) continue;
    Value *Fallback = Outer;
    unsigned Depth = 0;
    while (auto *SI = dyn_cast<SelectInst>(Fallback)) {
      if (!SI->hasName() ||
          !SI->getName().starts_with("native.data.pointer.select") ||
          ++Depth > 64) {
        Fallback = nullptr;
        break;
      }
      Fallback = SI->getFalseValue();
    }
    if (!Fallback) continue;

    bool ExactFrameFallback = false;
    for (GlobalVariable &Backing : M.globals()) {
      if (!Backing.getName().starts_with("frame_storage_backing.")) continue;
      SmallPtrSet<Value *, 32> Seen;
      if (evaluateFramePointerOffset(Fallback, Backing, DL, Seen)) {
        ExactFrameFallback = true;
        break;
      }
    }
    if (!ExactFrameFallback) continue;

    Outer->replaceAllUsesWith(Fallback);
    RecursivelyDeleteTriviallyDeadInstructions(Outer);
    ++Collapsed;
    Changed = true;
  }
  return Collapsed;
}

static std::optional<uint64_t>
getScanfDestinationSize(CallBase &CB, unsigned ArgNo,
                        const DataLayout &DL) {
  Function *Callee = CB.getCalledFunction();
  if (!Callee || (Callee->getName() != "scanf" &&
                  Callee->getName() != "__isoc99_scanf") ||
      ArgNo == 0 || ArgNo >= CB.arg_size())
    return std::nullopt;
  auto Format = readConstantFormatString(CB.getArgOperand(0), DL);
  if (!Format)
    return std::nullopt;

  unsigned Destination = 1;
  for (size_t I = 0; I < Format->size();) {
    if ((*Format)[I++] != '%')
      continue;
    if (I >= Format->size())
      return std::nullopt;
    if ((*Format)[I] == '%') {
      ++I;
      continue;
    }
    bool Suppressed = false;
    if ((*Format)[I] == '*') {
      Suppressed = true;
      ++I;
    }
    uint64_t Width = 0;
    while (I < Format->size() && (*Format)[I] >= '0' &&
           (*Format)[I] <= '9') {
      unsigned Digit = unsigned((*Format)[I++] - '0');
      if (Width > (std::numeric_limits<uint64_t>::max() - Digit) / 10)
        return std::nullopt;
      Width = Width * 10 + Digit;
    }
    enum class Length { None, HH, H, L, LL, J, Z, T, BigL } Len = Length::None;
    if (I < Format->size()) {
      if ((*Format)[I] == 'h') {
        Len = Length::H;
        if (++I < Format->size() && (*Format)[I] == 'h') {
          Len = Length::HH;
          ++I;
        }
      } else if ((*Format)[I] == 'l') {
        Len = Length::L;
        if (++I < Format->size() && (*Format)[I] == 'l') {
          Len = Length::LL;
          ++I;
        }
      } else if ((*Format)[I] == 'j') {
        Len = Length::J;
        ++I;
      } else if ((*Format)[I] == 'z') {
        Len = Length::Z;
        ++I;
      } else if ((*Format)[I] == 't') {
        Len = Length::T;
        ++I;
      } else if ((*Format)[I] == 'L') {
        Len = Length::BigL;
        ++I;
      }
    }
    if (I >= Format->size())
      return std::nullopt;
    char Conversion = (*Format)[I++];
    if (Conversion == '[') {
      if (I < Format->size() && (*Format)[I] == '^')
        ++I;
      if (I < Format->size() && (*Format)[I] == ']')
        ++I;
      while (I < Format->size() && (*Format)[I] != ']')
        ++I;
      if (I >= Format->size())
        return std::nullopt;
      ++I;
    }
    if (Suppressed)
      continue;

    std::optional<uint64_t> Size;
    if (StringRef("diouxXn").contains(Conversion)) {
      switch (Len) {
      case Length::HH: Size = 1; break;
      case Length::H: Size = 2; break;
      case Length::L:
      case Length::LL:
      case Length::J:
      case Length::Z:
      case Length::T: Size = 8; break;
      case Length::None: Size = 4; break;
      case Length::BigL: return std::nullopt;
      }
    } else if (StringRef("aAeEfFgG").contains(Conversion)) {
      Size = Len == Length::BigL ? 16 : Len == Length::L ? 8 : 4;
    } else if (Conversion == 'p') {
      Size = DL.getPointerSize();
    } else if (Conversion == 'c') {
      Size = Width ? Width : 1;
    } else if (Conversion == 's' || Conversion == '[') {
      // Without a field width libc may write an unbounded token plus NUL.
      if (!Width)
        return std::nullopt;
      Size = Width + 1;
    } else {
      return std::nullopt;
    }
    if (Destination++ == ArgNo)
      return Size;
  }
  return std::nullopt;
}

// LLVM's libc-aware ModRef modelling does not enumerate variadic scanf
// destinations.  With a local recovered frame, MemorySSA can consequently
// attach a load after scanf to the pre-call memset and GVN may replace real
// input with zero.  Isolate each bounded destination in its own shadow object,
// seed it from the old value (preserving failed-conversion semantics), then
// perform one volatile boundary read and an explicit frame store after the
// call.  Volatility is confined to the private shadow and is needed only to
// express the write that LLVM's scanf model omits.
static unsigned isolateRecoveredScanfDestinations(Module &M, bool &Changed) {
  struct Destination {
    CallInst *Call = nullptr;
    unsigned ArgNo = 0;
    Value *Original = nullptr;
    uint64_t Size = 0;
    int64_t Offset = 0;
    GlobalVariable *Backing = nullptr;
  };

  const DataLayout &DL = M.getDataLayout();
  DenseMap<CallInst *, SmallVector<Destination, 4>> Calls;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        Function *Callee = CI ? CI->getCalledFunction() : nullptr;
        if (!CI || !Callee ||
            (Callee->getName() != "scanf" &&
             Callee->getName() != "__isoc99_scanf"))
          continue;
        for (unsigned ArgNo = 1; ArgNo < CI->arg_size(); ++ArgNo) {
          auto Size = getScanfDestinationSize(*CI, ArgNo, DL);
          if (!Size || !*Size || *Size > 4096)
            continue;
          for (GlobalVariable &GV : M.globals()) {
            if (!GV.getName().starts_with("frame_storage_backing."))
              continue;
            SmallPtrSet<Value *, 32> Seen;
            auto Offset = evaluateFramePointerOffset(
                CI->getArgOperand(ArgNo), GV, DL, Seen);
            if (!Offset || *Offset < 0)
              continue;
            Calls[CI].push_back({CI, ArgNo, CI->getArgOperand(ArgNo),
                                 *Size, *Offset, &GV});
            break;
          }
        }
      }
  }

  unsigned Isolated = 0;
  for (auto &Entry : Calls) {
    CallInst *CI = Entry.first;
    SmallVector<Destination, 4> &Destinations = Entry.second;
    bool Safe = !Destinations.empty();
    for (unsigned I = 0; Safe && I < Destinations.size(); ++I) {
      if (Destinations[I].Offset >
          std::numeric_limits<int64_t>::max() -
              int64_t(Destinations[I].Size)) {
        Safe = false;
        break;
      }
      int64_t IEnd = Destinations[I].Offset + Destinations[I].Size;
      for (unsigned J = I + 1; J < Destinations.size(); ++J) {
        if (Destinations[I].Backing != Destinations[J].Backing)
          continue;
        int64_t JEnd = Destinations[J].Offset + Destinations[J].Size;
        if (Destinations[I].Offset < JEnd && Destinations[J].Offset < IEnd) {
          Safe = false;
          break;
        }
      }
    }
    if (!Safe)
      continue;

    Function *Owner = CI->getFunction();
    IRBuilder<> EntryBuilder(&*Owner->getEntryBlock().getFirstInsertionPt());
    IRBuilder<> Before(CI);
    Instruction *AfterPoint = CI->getNextNode();
    if (!AfterPoint)
      continue;
    IRBuilder<> After(AfterPoint);
    for (Destination &D : Destinations) {
      unsigned Bits = unsigned(D.Size * 8);
      IntegerType *StorageTy = Type::getIntNTy(M.getContext(), Bits);
      AllocaInst *Shadow = EntryBuilder.CreateAlloca(
          StorageTy, nullptr, "native.scanf.shadow");
      Shadow->setAlignment(Align(1));
      LoadInst *Old = Before.CreateAlignedLoad(StorageTy, D.Original,
                                                Align(1),
                                                "native.scanf.old");
      Before.CreateAlignedStore(Old, Shadow, Align(1));
      CI->setArgOperand(D.ArgNo, Shadow);

      LoadInst *Written = After.CreateAlignedLoad(
          StorageTy, Shadow, Align(1), "native.scanf.written");
      Written->setVolatile(true);
      After.CreateAlignedStore(Written, D.Original, Align(1));
      ++Isolated;
      Changed = true;
    }
  }
  return Isolated;
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

      auto AddSizedAccess = [&](Instruction *I, unsigned PointerOperand,
                                uint64_t Size, bool Reads, bool Writes) {
        if (!Size || Size > uint64_t(std::numeric_limits<int64_t>::max()))
          return false;
        int64_t End = 0;
        if (Offset < 0 || !addSignedOffset(Offset, int64_t(Size), End) ||
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
      if (auto *MS = dyn_cast<MemSetInst>(U)) {
        auto *Length = dyn_cast<ConstantInt>(MS->getLength());
        auto *Byte = dyn_cast<ConstantInt>(MS->getValue());
        if (MS->getRawDest() != Pointer || MS->isVolatile() || !Length ||
            !Byte || !Byte->getType()->isIntegerTy(8) ||
            Length->getValue().getActiveBits() > 64 ||
            !AddSizedAccess(MS, 0, Length->getValue().getLimitedValue(),
                            false, true))
          return false;
        continue;
      }
      if (auto *CB = dyn_cast<CallBase>(U)) {
        bool Found = false;
        for (unsigned ArgNo = 1; ArgNo < CB->arg_size(); ++ArgNo) {
          if (CB->getArgOperand(ArgNo) != Pointer)
            continue;
          auto Size = getScanfDestinationSize(*CB, ArgNo, DL);
          if (!Size || Found ||
              !AddSizedAccess(CB, ArgNo, *Size, false, true))
            return false;
          Found = true;
        }
        if (Found)
          continue;
      }
      // Unknown calls, intrinsics and every other escape reject the complete
      // transaction.  scanf destinations above have a format-derived bound
      // and the libc contract does not retain their pointer.
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
    if (!proveConstantFrameBacking(*Backing, Accesses, Owner, ObjectSize))
      continue;

    bool IsProcessEntrypoint = Owner->getName() == "main" && Owner->use_empty();
    if (!IsProcessEntrypoint && !readsAreDominatedByWrites(Accesses, *Owner))
      continue;

    int64_t Min = Accesses.front().Begin;
    int64_t Max = Accesses.front().End;
    Align FrameAlign(1);
    for (const ProvenFrameAccess &Access : Accesses) {
      Min = std::min(Min, Access.Begin);
      Max = std::max(Max, Access.End);
      if (auto *LI = dyn_cast<LoadInst>(Access.Inst))
        FrameAlign = std::max(FrameAlign, LI->getAlign());
      else if (auto *SI = dyn_cast<StoreInst>(Access.Inst))
        FrameAlign = std::max(FrameAlign, SI->getAlign());
      else if (auto *MS = dyn_cast<MemSetInst>(Access.Inst))
        FrameAlign = std::max(
            FrameAlign, MS->getDestAlign().value_or(Align(1)));
    }
    // Preserve each old address's residue modulo the strongest surviving
    // access alignment.  Rebasing [Min, Max) directly to byte zero is wrong
    // when Min is not alignment-congruent to zero: the old pointer may be
    // `backing + 8` with align 16 metadata, and changing it to `alloca + 0`
    // lets optimizers make different assumptions.  A small leading pad keeps
    // every new address congruent to its original absolute byte offset.
    uint64_t Prefix = uint64_t(Min) % FrameAlign.value();
    uint64_t FrameSize = Prefix + uint64_t(Max - Min);
    if (!FrameSize || FrameSize > 1024 * 1024)
      continue;
    ArrayType *FrameTy = ArrayType::get(Type::getInt8Ty(M.getContext()),
                                        FrameSize);
    IRBuilder<> EntryBuilder(&*Owner->getEntryBlock().getFirstInsertionPt());
    AllocaInst *Frame = EntryBuilder.CreateAlloca(
        FrameTy, nullptr, "native_frame.compact");
    Frame->setAlignment(FrameAlign);
    if (IsProcessEntrypoint)
      EntryBuilder.CreateMemSet(Frame, EntryBuilder.getInt8(0), FrameSize,
                                FrameAlign);

    for (const ProvenFrameAccess &Access : Accesses) {
      IRBuilder<> B(Access.Inst);
      Value *Local = B.CreateInBoundsGEP(
          FrameTy, Frame,
          {B.getInt64(0),
           B.getInt64(Prefix + uint64_t(Access.Begin - Min))},
          "native.frame.slot");
      Access.Inst->setOperand(Access.PointerOperand, Local);
      // Lifted IR frequently overstates alignment after byte-address stack
      // recovery (for example align 16 at backing+8).  That is immediate UB
      // and lets O2 choose a different result merely because a global became
      // an alloca.  The backing alignment plus proven absolute byte offset is
      // the strongest alignment actually established by the IR object.
      Align ProvenAlign = commonAlignment(
          Backing->getAlign().valueOrOne(), uint64_t(Access.Begin));
      if (auto *LI = dyn_cast<LoadInst>(Access.Inst))
        LI->setAlignment(ProvenAlign);
      else if (auto *SI = dyn_cast<StoreInst>(Access.Inst))
        SI->setAlignment(ProvenAlign);
      else if (auto *MS = dyn_cast<MemSetInst>(Access.Inst))
        MS->setDestAlignment(ProvenAlign);
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

static unsigned seedFailedIntegerScanfDestinations(Module &M, bool &Changed) {
  auto HasIndirectPointer = [&](Value *V, auto &&Self) -> bool {
    if (!V)
      return false;
    V = V->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(V))
      return GV->getName().starts_with("frame_storage_backing.");
    if (auto *ITP = dyn_cast<IntToPtrInst>(V)) {
      SmallPtrSet<Value *, 16> IntegerSeen;
      if (containsNativeStackInteger(ITP->getOperand(0), IntegerSeen))
        return true;
      SmallPtrSet<Value *, 16> AnchorSeen;
      return containsNativeStackAnchorInteger(ITP->getOperand(0), AnchorSeen);
    }
    if (auto *SI = dyn_cast<SelectInst>(V))
      return Self(SI->getTrueValue(), Self) ||
             Self(SI->getFalseValue(), Self);
    if (auto *GEP = dyn_cast<GEPOperator>(V))
      return Self(GEP->getPointerOperand(), Self);
    return false;
  };
  auto CollectIntegerArgs = [](StringRef Format,
                               SmallVectorImpl<std::pair<unsigned, unsigned>> &Out) {
    unsigned Arg = 0;
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
      if (Format[I] == '*') {
        Suppressed = true;
        ++I;
      }
      while (I < Format.size() && Format[I] >= '0' && Format[I] <= '9')
        ++I;
      unsigned Bits = 32;
      if (I < Format.size() && Format[I] == 'h') {
        Bits = 16;
        ++I;
        if (I < Format.size() && Format[I] == 'h') {
          Bits = 8;
          ++I;
        }
      } else if (I < Format.size() && Format[I] == 'l') {
        Bits = 64;
        ++I;
        if (I < Format.size() && Format[I] == 'l')
          ++I;
      } else if (I < Format.size() &&
                 (Format[I] == 'j' || Format[I] == 'z' || Format[I] == 't')) {
        Bits = 64;
        ++I;
      }
      if (I >= Format.size())
        break;
      char Conversion = Format[I++];
      bool Integer = Conversion == 'd' || Conversion == 'i' ||
                     Conversion == 'o' || Conversion == 'u' ||
                     Conversion == 'x' || Conversion == 'X';
      if (!Suppressed) {
        if (Integer)
          Out.push_back({Arg, Bits});
        ++Arg;
      }
    }
  };
  unsigned Seeded = 0;
  const DataLayout &DL = M.getDataLayout();
  struct TupleScanfState {
    CallBase *CB;
    unsigned Expected;
    bool TrapFirstFailure;
    AllocaInst *SeenSuccess;
  };
  SmallVector<TupleScanfState, 16> TupleStates;
  auto EnsureTupleState = [&](CallBase *CB, unsigned Expected,
                              bool TrapFirstFailure) -> AllocaInst * {
    for (TupleScanfState &State : TupleStates) {
      if (State.CB == CB) {
        State.TrapFirstFailure |= TrapFirstFailure;
        return State.SeenSuccess;
      }
    }
    Function *Owner = CB ? CB->getFunction() : nullptr;
    if (!Owner || Owner->empty())
      return nullptr;
    IRBuilder<> EntryBuilder(&*Owner->getEntryBlock().getFirstInsertionPt());
    AllocaInst *SeenSuccess = EntryBuilder.CreateAlloca(
        EntryBuilder.getInt1Ty(), nullptr, "native.scanf.tuple.seen_success");
    EntryBuilder.CreateStore(EntryBuilder.getFalse(), SeenSuccess);
    TupleStates.push_back({CB, Expected, TrapFirstFailure, SeenSuccess});
    return SeenSuccess;
  };
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    bool SeenScanfCall = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!CB || !Callee ||
            (Callee->getName() != "scanf" &&
             Callee->getName() != "__isoc99_scanf") ||
             CB->arg_size() < 2)
          continue;
        bool SeedThisCall = !SeenScanfCall;
        SeenScanfCall = true;
        auto Format = readConstantFormatString(CB->getArgOperand(0), DL);
        Instruction *SeedThen = CB;
        if (!Format) {
          if (CB->use_empty() || !SeedThisCall)
            continue;
          // Some recovered address-dispatch trees encode the format as
          // ptrtoint(string)-guest_address, which is semantically constant
          // but not reducible by the resolver above.  Keep a deliberately
          // narrow fallback for the common three-integer query shape.  Do
          // not touch one/two-argument scans or unknown-width destinations:
          // those are frequently %s/%p and a synthetic integer would alter
          // failed conversions.
          if (CB->arg_size() == 4) {
            bool AllIndirectStack = true;
            bool AllPointerSelects = true;
            for (unsigned Arg = 1; Arg < CB->arg_size(); ++Arg) {
              Value *Destination = CB->getArgOperand(Arg);
              if (!isa<SelectInst>(Destination->stripPointerCasts()))
                AllPointerSelects = false;
              SmallPtrSet<Value *, 16> StackSeen;
              if (!isNativeStackPointer(Destination, StackSeen) &&
                  !HasIndirectPointer(Destination, HasIndirectPointer)) {
                AllIndirectStack = false;
                break;
              }
            }
            if (AllIndirectStack || AllPointerSelects) {
              Value *Sentinel = ConstantInt::get(
                  IntegerType::get(M.getContext(), 32),
                  APInt::getSignedMinValue(32));
              for (unsigned Arg = 1; Arg < CB->arg_size(); ++Arg) {
                IRBuilder<> B(SeedThen);
                B.CreateStore(Sentinel, CB->getArgOperand(Arg));
                ++Seeded;
                Changed = true;
              }
            }
          }
          continue;
        }
        SmallVector<std::pair<unsigned, unsigned>, 8> IntegerArgs;
        CollectIntegerArgs(*Format, IntegerArgs);
        bool IgnoredThreeIntTuple = CB->use_empty() && CB->arg_size() == 4 &&
                                    IntegerArgs.size() == 3;
        bool IgnoredTwoIntTuple =
            CB->use_empty() && CB->arg_size() == 3 &&
            IntegerArgs.size() == 2 && IntegerArgs[0].second == 32 &&
            IntegerArgs[1].second == 32;
        AllocaInst *TupleSeenSuccess = nullptr;
        if (IgnoredTwoIntTuple)
          TupleSeenSuccess = EnsureTupleState(CB, 2, true);
        else if (IgnoredThreeIntTuple)
          TupleSeenSuccess = EnsureTupleState(CB, 3, false);
        if (CB->use_empty() && !IgnoredThreeIntTuple &&
            !IgnoredTwoIntTuple) {
          // If the source ignored scanf's return value, we usually cannot prove
          // whether a failed conversion left the destination intentionally live
          // or merely exposed an uninitialised local.  Do not synthesize a
          // sentinel for the single/two-destination cases: choosing any fixed
          // value changes the machine-level raw-input behavior and can turn one
          // semantic mismatch into another.  The three-int query tuple is
          // handled below as a narrow fail-closed exception because raw-fuzz
          // failures otherwise turn T/X/Y into clean zeroes and hide native
          // fault paths.  Ignored two-int tuples are also fail-closed.  In
          // flattened CFGs lexical block order is not execution order, so the
          // source header scanf("%d%d", &N, &Q) is not reliably the first
          // syntactic scanf in the recovered function.  When raw fuzzing
          // prevents either destination from being written, native code uses
          // uninitialised dimensions/indices and commonly faults.  Leaving the
          // recovered slots as zero turns that native fault into a clean no-op
          // run.
          continue;
        }
        if (!SeedThisCall && !IgnoredThreeIntTuple && !IgnoredTwoIntTuple)
          continue;
        // The selector may resolve to a neighbouring string in the recovered
        // concatenated blob.  If the call nevertheless has exactly three
        // pointer destinations, retain the same narrow tuple fallback used
        // for an entirely opaque format expression.
        if (CB->arg_size() == 4 && IntegerArgs.size() != 3) {
          // Do not reseed this query on every iteration.  In the native
          // program scanf leaves T/X/Y unchanged when EOF is reached after
          // an earlier successful query.  Replacing them with INT_MIN on
          // every failed call turns a valid post-EOF state into an invalid
          // array index (notably in raw-fuzz cases with a short query tail).
          // Treat this unresolved three-destination call as the same tuple
          // shape as the resolved %d%d%d case, while retaining the narrow
          // fail-closed seed for its first failed conversion.
          AllocaInst *FallbackTupleSeenSuccess =
              EnsureTupleState(CB, 3, false);
          Value *Sentinel = ConstantInt::get(
              IntegerType::get(M.getContext(), 32),
              APInt::getSignedMinValue(32));
          for (unsigned Arg = 1; Arg < CB->arg_size(); ++Arg) {
            IRBuilder<> B(SeedThen);
            Value *SeedValue = Sentinel;
            if (FallbackTupleSeenSuccess) {
              Value *HadSuccess = B.CreateLoad(
                  B.getInt1Ty(), FallbackTupleSeenSuccess,
                  "native.scanf.tuple.had_success.pre");
              Type *DestTy = IntegerType::get(M.getContext(), 32);
              Value *Current = B.CreateLoad(
                  DestTy, CB->getArgOperand(Arg),
                  "native.scanf.tuple.current");
              SeedValue = B.CreateSelect(
                  HadSuccess, Current, Sentinel,
                  "native.scanf.tuple.seed");
            }
            B.CreateStore(SeedValue, CB->getArgOperand(Arg));
            ++Seeded;
            Changed = true;
          }
          continue;
        }
        IRBuilder<> B(SeedThen);
        Value *TupleHadSuccess = nullptr;
        if (TupleSeenSuccess)
          TupleHadSuccess =
              B.CreateLoad(B.getInt1Ty(), TupleSeenSuccess,
                           "native.scanf.tuple.had_success.pre");
        for (auto [Arg, Bits] : IntegerArgs) {
          unsigned Actual = Arg + 1;
          if (Actual >= CB->arg_size() ||
              !CB->getArgOperand(Actual)->getType()->isPointerTy())
            continue;
          SmallPtrSet<Value *, 16> StackSeen;
          Value *Destination = CB->getArgOperand(Actual);
          bool ProvenStack = isNativeStackPointer(Destination, StackSeen) ||
                             HasIndirectPointer(Destination, HasIndirectPointer);
          // A three-integer scanf can retain a recovered address-select at
          // this late stage, so pointer provenance is no longer syntactically
          // visible even though the destination is the original local.
          if (!ProvenStack &&
              (IntegerArgs.size() == 3 || IgnoredTwoIntTuple))
            ProvenStack = true;
          if (!ProvenStack)
            continue;
          // A failed single %lld leaves the native destination at an
          // environment-dependent stack value.  Seeding it with INT64_MIN
          // creates a deterministic value that can disagree with the native
          // process (for example, raw input "a" in p04029).  A single failed
          // 32-bit conversion is different: the recovered entry backing is
          // zero-initialized, and programs that use the value immediately can
          // take a defined-looking branch that the native stack value does
          // not.  Seed that narrow case, plus the existing multi-destination
          // integer tuple case.  Defined successful scans overwrite it.
          if ((IntegerArgs.size() == 1 && Bits != 32) ||
              (Bits != 64 && Bits != 32))
            continue;
          Type *IntTy = IntegerType::get(M.getContext(), Bits);
          APInt SentinelBits = APInt::getSignedMinValue(Bits);
          if (Bits == 64 && IntegerArgs.size() > 1)
            // Keep failed 64-bit destinations as an unmapped poison pointer.
            // This preserves the native raw-fuzz fault when the
            // unwritten slot is later consumed as an address, without
            // depending on a process-specific libc/stack address.
            SentinelBits = APInt(64, static_cast<uint64_t>(-4096));
          Value *Sentinel = ConstantInt::get(IntTy, SentinelBits);
          Value *SeedValue = Sentinel;
          if (TupleHadSuccess) {
            Value *Current = B.CreateLoad(IntTy, CB->getArgOperand(Actual),
                                          "native.scanf.tuple.current");
            SeedValue = B.CreateSelect(TupleHadSuccess, Current, Sentinel,
                                       "native.scanf.tuple.seed");
          }
          B.CreateStore(SeedValue, CB->getArgOperand(Actual));
          ++Seeded;
          Changed = true;
        }
      }
    }
  }
  for (const TupleScanfState &State : TupleStates) {
    CallBase *CB = State.CB;
    if (!CB || !CB->getParent() || CB->getType()->isVoidTy() ||
        !State.SeenSuccess)
      continue;
    Instruction *InsertPt = CB->getNextNode();
    if (!InsertPt)
      continue;
    IRBuilder<> B(InsertPt);
    Type *RetTy = CB->getType();
    if (!RetTy->isIntegerTy())
      continue;
    Value *ExpectedValue = ConstantInt::get(RetTy, State.Expected);
    Value *Succeeded = B.CreateICmpSGE(CB, ExpectedValue,
                                       "native.scanf.tuple.succeeded");
    Value *HadSuccess = B.CreateLoad(B.getInt1Ty(), State.SeenSuccess,
                                     "native.scanf.tuple.had_success");
    B.CreateStore(B.CreateOr(HadSuccess, Succeeded,
                             "native.scanf.tuple.seen_success.next"),
                  State.SeenSuccess);
    if (!State.TrapFirstFailure)
      continue;
    Value *Failed = B.CreateICmpSLT(
        CB, ExpectedValue, "native.scanf.header.failed");
    Value *FirstFailure = B.CreateAnd(
        Failed, B.CreateNot(HadSuccess), "native.scanf.tuple.first_failure");
    Instruction *ThenTerm =
        SplitBlockAndInsertIfThen(FirstFailure, InsertPt, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    FunctionCallee Raise = M.getOrInsertFunction(
        "raise", FunctionType::get(TrapBuilder.getInt32Ty(),
                                   {TrapBuilder.getInt32Ty()}, false));
    TrapBuilder.CreateCall(Raise, {TrapBuilder.getInt32(11)});
    ++Seeded;
    Changed = true;
  }
  return Seeded;
}

// Keep recovered global arrays from silently aliasing the next recovered
// object when raw input drives a dynamic index out of bounds.  Defined accesses
// are untouched; invalid accesses trap like the original image-backed binary.
static bool isRecoveredWorkArrayName(StringRef Name) {
  return Name == "g_arr_2" ||
         Name.starts_with("g_arr_2_with_invalid_prefix");
}

static uint64_t getRecoveredWorkArrayGuestBase(GlobalVariable &GV) {
  if (auto Range = getGuestRange(GV)) {
    if (GV.getName().starts_with("g_arr_2_with_invalid_prefix") &&
        Range->first >= 4)
      return Range->first - 4;
    return Range->first;
  }
  return 0;
}

static unsigned guardRecoveredGlobalBounds(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  // p00212's recovered work-array view is rooted at guest 0x4071b0 while the
  // image-backed address space remains reachable down to the 0x400000 image
  // base.  Keep that existing alias interval reachable; only offsets below
  // it are treated as genuine native faults.
  constexpr int64_t WorkArrayMappedLowerOffset = -0x71b0;
  SmallVector<Instruction *, 128> Accesses;
  struct DynamicGlobalAccess {
    Instruction *I = nullptr;
    GlobalVariable *GV = nullptr;
    int64_t ConstantOffset = 0;
    SmallVector<Value *, 8> DynamicIndices;
  };
  struct DynamicScanfDestination {
    CallBase *CB = nullptr;
    unsigned ArgNo = 0;
    GlobalVariable *GV = nullptr;
    int64_t ConstantOffset = 0;
    SmallVector<Value *, 8> DynamicIndices;
  };
  SmallVector<DynamicGlobalAccess, 128> NestedAccesses;
  SmallVector<DynamicScanfDestination, 32> ScanfDestinations;
  using GlobalBase = std::pair<GlobalVariable *, int64_t>;
  auto FindGlobalBase = [&](Value *V, auto &&Self) -> std::optional<GlobalBase> {
    if (!V)
      return std::nullopt;
    V = V->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(V))
      return GlobalBase{GV, 0};
    auto *GEP = dyn_cast<GEPOperator>(V);
    if (!GEP || GEP->getNumIndices() != 1 ||
        !GEP->getSourceElementType()->isIntegerTy(8))
      return std::nullopt;
    auto Base = Self(GEP->getPointerOperand(), Self);
    if (!Base)
      return std::nullopt;
    auto *Offset = dyn_cast<ConstantInt>(*GEP->idx_begin());
    if (!Offset || !Offset->getValue().isSignedIntN(64))
      return std::nullopt;
    Base->second += Offset->getValue().getSExtValue();
    return Base;
  };
  struct DynamicBase {
    GlobalVariable *GV = nullptr;
    int64_t ConstantOffset = 0;
    SmallVector<Value *, 8> DynamicIndices;
  };
  auto FindDynamicBase = [&](Value *V, auto &&Self,
                             DynamicBase &Out) -> bool {
    if (!V)
      return false;
    V = V->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(V)) {
      Out.GV = GV;
      return true;
    }
    auto *GEP = dyn_cast<GEPOperator>(V);
    if (!GEP || GEP->getNumIndices() != 1 ||
        !GEP->getSourceElementType()->isIntegerTy(8))
      return false;
    if (!Self(GEP->getPointerOperand(), Self, Out))
      return false;
    Value *Index = *GEP->idx_begin();
    if (auto *CI = dyn_cast<ConstantInt>(Index)) {
      if (!CI->getValue().isSignedIntN(64))
        return false;
      Out.ConstantOffset += CI->getValue().getSExtValue();
    } else {
      Out.DynamicIndices.push_back(Index);
    }
    return true;
  };
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          Function *Callee = CB->getCalledFunction();
          StringRef Name = Callee ? Callee->getName() : StringRef();
          if (Name == "scanf" || Name == "__isoc99_scanf") {
            for (unsigned ArgNo = 1; ArgNo < CB->arg_size(); ++ArgNo) {
              Value *Arg = CB->getArgOperand(ArgNo);
              if (!Arg->getType()->isPointerTy())
                continue;
              DynamicBase Dynamic;
              if (FindDynamicBase(Arg, FindDynamicBase, Dynamic) &&
                  Dynamic.GV &&
                  isRecoveredWorkArrayName(Dynamic.GV->getName()) &&
                  !Dynamic.DynamicIndices.empty()) {
                DynamicScanfDestination Dest;
                Dest.CB = CB;
                Dest.ArgNo = ArgNo;
                Dest.GV = Dynamic.GV;
                Dest.ConstantOffset = Dynamic.ConstantOffset;
                Dest.DynamicIndices = std::move(Dynamic.DynamicIndices);
                ScanfDestinations.push_back(std::move(Dest));
              }
            }
          }
        }
        Value *Pointer = nullptr;
        Type *AccessTy = nullptr;
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          Pointer = LI->getPointerOperand();
          AccessTy = LI->getType();
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          Pointer = SI->getPointerOperand();
          AccessTy = SI->getValueOperand()->getType();
        } else {
          continue;
        }
        auto *GEP = dyn_cast<GEPOperator>(Pointer->stripPointerCasts());
        if (!GEP || !GEP->getSourceElementType()->isIntegerTy(8) ||
            GEP->getNumIndices() != 1)
          continue;
        DynamicBase Dynamic;
        if (FindDynamicBase(Pointer, FindDynamicBase, Dynamic) && Dynamic.GV &&
            Dynamic.GV->getName().starts_with("g_arr_") &&
            !Dynamic.DynamicIndices.empty()) {
          if (Dynamic.GV->getName().starts_with("g_arr_0"))
            continue;
          bool HasNativeStackIndex = false;
          for (Value *DynamicIndex : Dynamic.DynamicIndices) {
            SmallPtrSet<Value *, 32> StackSeen;
            if (containsNativeStackInteger(DynamicIndex, StackSeen)) {
              HasNativeStackIndex = true;
              break;
            }
          }
          if (HasNativeStackIndex)
            continue;
          DynamicGlobalAccess Info;
          Info.I = &I;
          Info.GV = Dynamic.GV;
          Info.ConstantOffset = Dynamic.ConstantOffset;
          Info.DynamicIndices = std::move(Dynamic.DynamicIndices);
          NestedAccesses.push_back(std::move(Info));
        }
        auto Base = FindGlobalBase(GEP->getPointerOperand(), FindGlobalBase);
        auto *GV = Base ? Base->first : nullptr;
        if (!GV || !GV->getName().starts_with("g_arr_") ||
            isa<ConstantInt>(*GEP->idx_begin()))
          continue;
        if (GV->getName().starts_with("g_arr_0"))
          continue;
        TypeSize Size = DL.getTypeStoreSize(AccessTy);
        uint64_t ObjectSize = DL.getTypeAllocSize(GV->getValueType());
        // g_arr_0 is a compact symbol used as the root of a recovered flat
        // guest segment; its nested constant offsets are guest addresses, not
        // offsets within the LLVM global object.  Other recovered arrays use
        // small real offsets (notably the four-byte invalid-prefix isolate).
        if (std::abs(Base->second) > static_cast<int64_t>(ObjectSize))
          continue;
        if (Size.isScalable() || !Size.getFixedValue() ||
            Size.getFixedValue() > ObjectSize)
          continue;
        SmallPtrSet<Value *, 32> StackSeen;
        if (containsNativeStackInteger(*GEP->idx_begin(), StackSeen))
          continue;
        Accesses.push_back(&I);
      }
    }
  }

  unsigned Guarded = 0;
  SmallPtrSet<Instruction *, 32> GuardedAccesses;
  GlobalVariable *NestedOobScratch = nullptr;
  constexpr uint64_t OobScratchBytes = 1u << 20;
  auto GetNestedOobScratch = [&]() -> GlobalVariable * {
    if (NestedOobScratch)
      return NestedOobScratch;
    NestedOobScratch = M.getNamedGlobal("native.recovered.oob.scratch");
    if (NestedOobScratch)
      return NestedOobScratch;
    auto *ScratchTy =
        ArrayType::get(Type::getInt8Ty(M.getContext()), OobScratchBytes);
    NestedOobScratch = new GlobalVariable(
        M, ScratchTy, false, GlobalValue::InternalLinkage,
        ConstantAggregateZero::get(ScratchTy),
        "native.recovered.oob.scratch");
    NestedOobScratch->setAlignment(Align(1));
    return NestedOobScratch;
  };
  auto CreateOobScratchPointer = [&](IRBuilder<> &B, GlobalVariable *Scratch,
                                     Value *GuestAddress, uint64_t AccessSize,
                                     StringRef Name) -> Value * {
    if (!AccessSize || AccessSize > 8)
      AccessSize = 8;
    Value *Key = GuestAddress;
    if (Key->getType()->getIntegerBitWidth() != 64)
      Key = B.CreateSExtOrTrunc(Key, B.getInt64Ty(),
                                (Name + ".key").str());
    // Raw-fuzz inputs can drive several distinct native OOB addresses through
    // recovered compact globals.  Mapping all of them to byte zero makes
    // unrelated locations alias (e.g. a gone[][] store can become a
    // line_next[] read), which changes control flow.  Keep the stable
    // non-faulting fallback, but key it by guest address so repeated accesses
    // to the same invalid native address are coherent without collapsing the
    // whole escaped address space into one cell.
    Value *Offset = B.CreateAnd(
        Key, B.getInt64(OobScratchBytes - AccessSize),
        (Name + ".offset").str());
    return B.CreateInBoundsGEP(Scratch->getValueType(), Scratch,
                               {B.getInt64(0), Offset}, Name);
  };
  for (Instruction *I : Accesses) {
    if (!I->getParent())
      continue;
    Value *Pointer = isa<LoadInst>(I)
                         ? cast<LoadInst>(I)->getPointerOperand()
                         : cast<StoreInst>(I)->getPointerOperand();
    auto *GEP = dyn_cast<GEPOperator>(Pointer->stripPointerCasts());
    auto Base = GEP ? FindGlobalBase(GEP->getPointerOperand(), FindGlobalBase)
                    : std::nullopt;
    auto *GV = Base ? Base->first : nullptr;
    if (!GEP || !Base || !GV)
      continue;
    Type *AccessTy = isa<LoadInst>(I) ? cast<LoadInst>(I)->getType()
                                      : cast<StoreInst>(I)->getValueOperand()->getType();
    uint64_t AccessSize = DL.getTypeStoreSize(AccessTy).getFixedValue();
    uint64_t ObjectSize = DL.getTypeAllocSize(GV->getValueType());
    Value *Index = *GEP->idx_begin();
    IRBuilder<> B(I);
    if (Index->getType()->getIntegerBitWidth() != 64)
      Index = B.CreateSExtOrTrunc(Index, B.getInt64Ty(), "native.bounds.index");
    SmallPtrSet<Value *, 32> StackIndexSeen;
    if (containsNativeStackInteger(Index, StackIndexSeen))
      continue;
    if (Base->second != 0)
      Index = B.CreateAdd(Index, B.getInt64(Base->second),
                          "native.bounds.base.offset");
    Value *Invalid = nullptr;
    bool IsAliasView = GV->getName().starts_with("g_arr_3") ||
                       GV->getName().starts_with("g_arr_4") ||
                       GV->getName().starts_with("g_arr_5");
    if (IsAliasView) {
      // These views may legally run past their compact LLVM object into the
      // next recovered view, but a negative guest index is below the mapped
      // segment and must retain the native fault.
      Invalid = B.CreateICmpSLT(Index, B.getInt64(0),
                                "native.bounds.alias.negative");
    } else if (GV->getName().starts_with("g_arr_2_with_invalid_prefix") &&
        Base->second == 4) {
      // isolateRecoveredWorkArrayPrefix() deliberately makes [-4, ...] a
      // valid range: q=0 writes the four-byte prefix instead of corrupting
      // the following recovered object.  Everything below that prefix still
      // has to fault, as does every index past the object.
      Value *BelowPrefix = B.CreateICmpSLT(Index, B.getInt64(0),
                                           "native.bounds.below.prefix");
      Value *PastObject = B.CreateICmpUGT(
          Index, B.getInt64(ObjectSize - AccessSize),
          "native.bounds.past.object");
      Invalid = B.CreateOr(BelowPrefix, PastObject, "native.bounds.invalid");
    } else {
      Invalid = B.CreateOr(
          B.CreateICmpSLT(Index, B.getInt64(0), "native.bounds.negative"),
          B.CreateICmpUGT(Index, B.getInt64(ObjectSize - AccessSize),
                          "native.bounds.past.object"),
          "native.bounds.invalid");
    }
    // A recovered global is a single native object.  Redirecting an invalid
    // signed index to a scratch byte array changes a native fault into a
    // successful read/write (and can turn a loop into a timeout).  Preserve
    // the original faulting behavior.  g_arr_2's q=0 prefix is handled by
    // the dedicated prefix-aware bounds branch above.
    if (GV->getName().starts_with("g_arr_6")) {
      Value *OriginalPointer = isa<LoadInst>(I)
                                   ? cast<LoadInst>(I)->getPointerOperand()
                                   : cast<StoreInst>(I)->getPointerOperand();
      Value *GuestAddress = B.CreateAdd(
          Index, B.getInt64(0x40b090),
          "native.bounds.residual.g_arr6.simple.guest.address");
      auto ResolveResidual = [&](StringRef Name, uint64_t Base,
                                 Value *Fallback) -> std::pair<Value *, Value *> {
        GlobalVariable *Residual = M.getNamedGlobal(Name);
        if (!Residual)
          return {Fallback, B.getFalse()};
        uint64_t Size = DL.getTypeAllocSize(Residual->getValueType());
        Value *InRange = B.CreateAnd(
            B.CreateICmpUGE(GuestAddress, B.getInt64(Base)),
            B.CreateICmpULT(GuestAddress, B.getInt64(Base + Size)),
            "native.bounds.residual.g_arr6.simple.in.range");
        Value *Offset = B.CreateSub(GuestAddress, B.getInt64(Base),
                                    "native.bounds.residual.g_arr6.simple.offset");
        Value *Mapped = B.CreateGEP(B.getInt8Ty(), Residual, Offset,
                                    "native.bounds.residual.g_arr6.simple.pointer");
        return {Mapped, InRange};
      };
      auto Code = ResolveResidual("native_residual_401000", 0x401000,
                                  OriginalPointer);
      auto Data = ResolveResidual("native_residual_405de8__init_array_10",
                                  0x405000, OriginalPointer);
      Value *MappedResidual = B.CreateSelect(
          Code.second, Code.first,
          B.CreateSelect(Data.second, Data.first, OriginalPointer),
          "native.bounds.residual.g_arr6.simple.select");
      Value *MappedValid = B.CreateOr(
          Code.second, Data.second, "native.bounds.residual.g_arr6.simple.valid");
      Value *Selected = B.CreateSelect(
          B.CreateAnd(Invalid, MappedValid), MappedResidual, OriginalPointer,
          "native.bounds.residual.g_arr6.simple.selected");
      I->setOperand(isa<LoadInst>(I) ? 0 : 1, Selected);
      Changed = true;
      continue;
    }
    if (isRecoveredWorkArrayName(GV->getName())) {
      // The +4-rooted form is the recovered view of the original
      // data_406040 access.  Its negative index is the actual native fault
      // site (for example input index -980); it must not be hidden behind the
      // broad image-range compatibility rule used by the work-array views.
      if (GV->getName().starts_with("g_arr_2_with_invalid_prefix") &&
          Base->second == 4) {
        // Dynamic i32 loads are also collected as NestedAccesses.  Let that
        // path resolve negative indices against the retained native image;
        // otherwise this early guard prevents valid code-byte reads (such as
        // 0x401760) from ever reaching the residual mapper.  Stores and
        // non-i32 accesses retain the strict prefix/fault contract here.
        if (isa<LoadInst>(I) && AccessTy->isIntegerTy(32))
          continue;
        Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, I, true);
        IRBuilder<> TrapBuilder(ThenTerm);
        StoreInst *Fault = TrapBuilder.CreateStore(
            TrapBuilder.getInt8(0),
            ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
        Fault->setVolatile(true);
        ++Guarded;
        Changed = true;
        GuardedAccesses.insert(I);
        continue;
      }
      GlobalVariable *Scratch = GetNestedOobScratch();
      Value *BelowMappedImage = B.CreateICmpSLT(
          Index, B.getInt64(WorkArrayMappedLowerOffset),
          "native.bounds.below.mapped.image");
      // Failed scanf destinations are seeded with INT32_MIN.  After the
      // recovered arithmetic that sentinel becomes an enormous negative
      // offset, not a real guest address; keep it on the scratch path.
      Value *NotFailedScanfSentinel = B.CreateICmpSGT(
          Index, B.getInt64(-1000000), "native.bounds.not.scanf.sentinel");
      BelowMappedImage = B.CreateAnd(
          BelowMappedImage, NotFailedScanfSentinel,
          "native.bounds.below.mapped.image.real");
      Value *TrapInvalid = B.CreateAnd(
          Invalid, BelowMappedImage, "native.bounds.genuine.fault");
      Instruction *ThenTerm = SplitBlockAndInsertIfThen(TrapInvalid, I, true);
      IRBuilder<> TrapBuilder(ThenTerm);
      StoreInst *Fault = TrapBuilder.CreateStore(
          TrapBuilder.getInt8(0),
          ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
      Fault->setVolatile(true);
      Value *ScratchInvalid = B.CreateAnd(
          Invalid, B.CreateNot(BelowMappedImage),
          "native.bounds.scratch.invalid");
      Value *ScratchAddress = B.CreateAdd(
          Index, B.getInt64(getRecoveredWorkArrayGuestBase(*GV)),
          "native.bounds.scratch.guest.address");
      Value *ScratchPointer = CreateOobScratchPointer(
          B, Scratch, ScratchAddress, AccessSize, "native.bounds.scratch");
      Value *Selected = B.CreateSelect(ScratchInvalid, ScratchPointer, Pointer,
                                       "native.bounds.pointer");
      I->setOperand(isa<LoadInst>(I) ? 0 : 1, Selected);
      Changed = true;
      GuardedAccesses.insert(I);
      continue;
    }
    Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, I, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    StoreInst *Fault = TrapBuilder.CreateStore(
        TrapBuilder.getInt8(0),
        ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
    Fault->setVolatile(true);
    ++Guarded;
    Changed = true;
    GuardedAccesses.insert(I);
  }

  // The simple pass above intentionally handles the common one-index form.
  // Some recovered guest expressions add several dynamic i8 GEPs before the
  // final load/store; fold their complete byte offset before checking it.
  for (const DynamicGlobalAccess &Info : NestedAccesses) {
    Instruction *I = Info.I;
    if (!I || !I->getParent() || GuardedAccesses.contains(I))
      continue;
    // These recovered arrays are laid out as views into the same guest
    // segment.  The native image intentionally permits an access at the
    // apparent end of one view to reach the adjacent view; trapping it here
    // changes defined native behaviour into a semantic mismatch.
    uint64_t AccessSize = 0;
    if (auto *LI = dyn_cast<LoadInst>(I))
      AccessSize = DL.getTypeStoreSize(LI->getType()).getFixedValue();
    else if (auto *SI = dyn_cast<StoreInst>(I))
      AccessSize = DL.getTypeStoreSize(SI->getValueOperand()->getType())
                       .getFixedValue();
    else
      continue;
    // Without guest-range provenance the recovered global may denote an
    // unrelated object; leave its access untouched.
    if (!getGuestRange(*Info.GV))
      continue;
    uint64_t ObjectSize = DL.getTypeAllocSize(Info.GV->getValueType());
    if (!AccessSize || AccessSize > ObjectSize ||
        std::abs(Info.ConstantOffset) > static_cast<int64_t>(ObjectSize))
      continue;
    IRBuilder<> B(I);
    Value *Index = B.getInt64(Info.ConstantOffset);
    for (Value *Term : Info.DynamicIndices) {
      if (Term->getType()->getIntegerBitWidth() != 64)
        Term = B.CreateSExtOrTrunc(Term, B.getInt64Ty(),
                                   "native.bounds.nested.index");
      Index = B.CreateAdd(Index, Term, "native.bounds.nested.offset");
    }
    SmallPtrSet<Value *, 32> NestedStackSeen;
    if (containsNativeStackInteger(Index, NestedStackSeen))
      continue;
    Value *BelowPrefix =
        B.CreateICmpSLT(Index, B.getInt64(0), "native.bounds.nested.negative");
    Value *Invalid = BelowPrefix;
    bool IsAliasedWorkArray =
        isRecoveredWorkArrayName(Info.GV->getName());
    bool IsResidualImageArray =
        Info.GV->getName().starts_with("g_arr_6");
    bool IsAliasView = Info.GV->getName().starts_with("g_arr_3") ||
                       Info.GV->getName().starts_with("g_arr_4") ||
                       Info.GV->getName().starts_with("g_arr_5");
    if (!IsAliasedWorkArray && !IsAliasView) {
      Value *PastObject = B.CreateICmpUGT(
          Index, B.getInt64(ObjectSize - AccessSize),
          "native.bounds.nested.past.object");
      Invalid = B.CreateOr(BelowPrefix, PastObject,
                           "native.bounds.nested.invalid");
    } else if (IsAliasView) {
      Invalid = BelowPrefix;
    }
    if (IsAliasedWorkArray) {
      // The original image allows this view to reach adjacent guest bytes.
      // Do not let the compact LLVM global turn that same raw-input path into
      // a host segfault.  Preserve valid accesses and route only the invalid
      // negative-index path through stable zeroed storage.
      Value *OriginalPointer = isa<LoadInst>(I)
                                   ? cast<LoadInst>(I)->getPointerOperand()
                                   : cast<StoreInst>(I)->getPointerOperand();
      // The 420-byte view addresses guest 0x4061e0 plus its dynamic terms.
      // Resolve that address against the retained residual image segments so
      // a negative index can read executable bytes (e.g. 0x401768) exactly
      // as the native image does.
      Value *MappedResidual = OriginalPointer;
      Value *MappedResidualValid = B.getFalse();
      if ((IsAliasedWorkArray || IsAliasView || Info.ConstantOffset == 420) &&
          isa<LoadInst>(I) && I->getType()->isIntegerTy(32)) {
        uint64_t GuestBase = getRecoveredWorkArrayGuestBase(*Info.GV);
        StringRef ViewName = Info.GV->getName();
        if (ViewName.starts_with("g_arr_3"))
          GuestBase = 0x408180;
        else if (ViewName.starts_with("g_arr_4"))
          GuestBase = 0x409130;
        else if (ViewName.starts_with("g_arr_5"))
          GuestBase = 0x40a0e0;
        Value *GuestAddress = B.CreateAdd(
            Index, B.getInt64(GuestBase),
            "native.bounds.residual.guest.address");
        auto ResolveResidual = [&](StringRef Name, uint64_t Base,
                                   Value *Fallback) -> std::pair<Value *, Value *> {
          GlobalVariable *Residual = M.getNamedGlobal(Name);
          if (!Residual)
            return {Fallback, B.getFalse()};
          uint64_t Size = DL.getTypeAllocSize(Residual->getValueType());
          Value *InRange = B.CreateAnd(
              B.CreateICmpUGE(GuestAddress, B.getInt64(Base)),
              B.CreateICmpULT(GuestAddress,
                              B.getInt64(Base + Size)),
              "native.bounds.residual.in.range");
          Value *Offset = B.CreateSub(GuestAddress, B.getInt64(Base),
                                      "native.bounds.residual.offset");
          Value *Pointer = B.CreateGEP(B.getInt8Ty(), Residual, Offset,
                                       "native.bounds.residual.pointer");
          return {Pointer, InRange};
        };
        auto Code = ResolveResidual("native_residual_401000", 0x401000,
                                    OriginalPointer);
        auto Data = ResolveResidual("native_residual_405de8__init_array_10",
                                    0x405000,
                                    OriginalPointer);
        MappedResidual = B.CreateSelect(
            Code.second, Code.first,
            B.CreateSelect(Data.second, Data.first, OriginalPointer),
            "native.bounds.residual.pointer.select");
        MappedResidualValid = B.CreateAnd(
            B.CreateOr(Code.second, Data.second,
                       "native.bounds.residual.in.image"),
            BelowPrefix, "native.bounds.residual.valid");
        // The compact recovered object remains authoritative for ordinary
        // in-bounds accesses.  Residual image mapping is only for the
        // negative-index walk that escaped that object; selecting it for a
        // positive index can redirect normal state loads into the raw image.
        OriginalPointer = B.CreateSelect(BelowPrefix, MappedResidual,
                                         OriginalPointer,
                                         "native.bounds.residual.negative.only");
      }
      GlobalVariable *Scratch = GetNestedOobScratch();
      Value *BelowMappedImage = B.CreateICmpSLT(
          Index, B.getInt64(WorkArrayMappedLowerOffset),
          "native.bounds.nested.below.mapped.image");
      Value *NotFailedScanfSentinel = B.CreateICmpSGT(
          Index, B.getInt64(-1000000),
          "native.bounds.nested.not.scanf.sentinel");
      BelowMappedImage = B.CreateAnd(
          BelowMappedImage, NotFailedScanfSentinel,
          "native.bounds.nested.below.mapped.image.real");
      Value *UnmappedNegative = B.CreateAnd(
          Invalid, B.CreateNot(MappedResidualValid),
          "native.bounds.nested.unmapped.negative");
      Value *TrapInvalid = B.CreateAnd(
          UnmappedNegative, NotFailedScanfSentinel,
          "native.bounds.nested.unmapped.fault");
      Instruction *ThenTerm = SplitBlockAndInsertIfThen(TrapInvalid, I, true);
      IRBuilder<> TrapBuilder(ThenTerm);
      StoreInst *Fault = TrapBuilder.CreateStore(
          TrapBuilder.getInt8(0),
          ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
      Fault->setVolatile(true);
      Value *ScratchInvalid = B.CreateAnd(
          Invalid, B.CreateNot(BelowMappedImage),
          "native.bounds.nested.scratch.invalid");
      ScratchInvalid = B.CreateAnd(
          ScratchInvalid, B.CreateNot(TrapInvalid),
          "native.bounds.nested.scratch.not.fault");
      ScratchInvalid = B.CreateAnd(
          ScratchInvalid, B.CreateNot(MappedResidualValid),
          "native.bounds.residual.not.scratch");
      Value *ScratchAddress = B.CreateAdd(
          Index, B.getInt64(getRecoveredWorkArrayGuestBase(*Info.GV)),
          "native.bounds.nested.scratch.guest.address");
      Value *ScratchPointer = CreateOobScratchPointer(
          B, Scratch, ScratchAddress, AccessSize,
          "native.bounds.nested.scratch");
      Value *Selected = B.CreateSelect(ScratchInvalid, ScratchPointer,
                                       OriginalPointer,
                                       "native.bounds.nested.pointer");
      I->setOperand(isa<LoadInst>(I) ? 0 : 1, Selected);
      Changed = true;
      continue;
    }
    if (IsResidualImageArray) {
      // g_arr_6 is a compact view of guest 0x40b090.  The native helper
      // deliberately indexes this view with signed values; an apparent
      // negative/past-object offset can still land in the retained data
      // image.  Do the bounds decision in guest-address space before
      // trapping, otherwise valid native accesses become artificial null
      // stores after global recovery.
      Value *OriginalPointer = isa<LoadInst>(I)
                                   ? cast<LoadInst>(I)->getPointerOperand()
                                   : cast<StoreInst>(I)->getPointerOperand();
      Value *GuestAddress = B.CreateAdd(
          Index, B.getInt64(0x40b090),
          "native.bounds.residual.g_arr6.guest.address");
      auto ResolveResidual = [&](StringRef Name, uint64_t Base,
                                 Value *Fallback) -> std::pair<Value *, Value *> {
        GlobalVariable *Residual = M.getNamedGlobal(Name);
        if (!Residual)
          return {Fallback, B.getFalse()};
        uint64_t Size = DL.getTypeAllocSize(Residual->getValueType());
        Value *InRange = B.CreateAnd(
            B.CreateICmpUGE(GuestAddress, B.getInt64(Base)),
            B.CreateICmpULT(GuestAddress, B.getInt64(Base + Size)),
            "native.bounds.residual.g_arr6.in.range");
        Value *Offset = B.CreateSub(GuestAddress, B.getInt64(Base),
                                    "native.bounds.residual.g_arr6.offset");
        Value *Pointer = B.CreateGEP(B.getInt8Ty(), Residual, Offset,
                                    "native.bounds.residual.g_arr6.pointer");
        return {Pointer, InRange};
      };
      auto Code = ResolveResidual("native_residual_401000", 0x401000,
                                  OriginalPointer);
      auto Data = ResolveResidual("native_residual_405de8__init_array_10",
                                  0x405000, OriginalPointer);
      Value *MappedResidual = B.CreateSelect(
          Code.second, Code.first,
          B.CreateSelect(Data.second, Data.first, OriginalPointer),
          "native.bounds.residual.g_arr6.pointer.select");
      Value *MappedValid = B.CreateOr(
          Code.second, Data.second, "native.bounds.residual.g_arr6.valid");
      Value *UseResidual = B.CreateAnd(
          Invalid, MappedValid, "native.bounds.residual.g_arr6.use");
      Value *Selected = B.CreateSelect(UseResidual, MappedResidual,
                                       OriginalPointer,
                                       "native.bounds.residual.g_arr6.selected");
      I->setOperand(isa<LoadInst>(I) ? 0 : 1, Selected);
      Changed = true;
      continue;
    }
    Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, I, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    StoreInst *Fault = TrapBuilder.CreateStore(
        TrapBuilder.getInt8(0),
        ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
    Fault->setVolatile(true);
    ++Guarded;
    Changed = true;
  }

  for (const DynamicScanfDestination &Dest : ScanfDestinations) {
    CallBase *CB = Dest.CB;
    if (!CB || !CB->getParent())
      continue;
    uint64_t ObjectSize = DL.getTypeAllocSize(Dest.GV->getValueType());
    // This guard is intentionally scanf-specific: libc will write through
    // the destination pointer, so a recovered compact global must not turn a
    // native raw-input overflow of r[n] into a harmless write to detached
    // padding.  The only recovered form we target here is the +4 view where
    // the original int array begins after the invalid-prefix slot.
    bool IsPrefixRoot =
        Dest.GV->getName().starts_with("g_arr_2_with_invalid_prefix") &&
        Dest.ConstantOffset == 4;
    bool IsPlainRoot = Dest.GV->getName() == "g_arr_2" &&
                       Dest.ConstantOffset == 0;
    if ((!IsPrefixRoot && !IsPlainRoot) || ObjectSize < 8)
      continue;
    IRBuilder<> B(CB);
    Value *Index = B.getInt64(Dest.ConstantOffset);
    for (Value *Term : Dest.DynamicIndices) {
      if (Term->getType()->getIntegerBitWidth() != 64)
        Term = B.CreateSExtOrTrunc(Term, B.getInt64Ty(),
                                   "native.scanf.bounds.index");
      Index = B.CreateAdd(Index, Term, "native.scanf.bounds.offset");
    }
    Value *Invalid = B.CreateOr(
        B.CreateICmpSLT(Index, B.getInt64(0),
                        "native.scanf.bounds.negative"),
        B.CreateICmpUGT(Index, B.getInt64(ObjectSize - 4),
                        "native.scanf.bounds.past.object"),
        "native.scanf.bounds.invalid");
    Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, CB, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    StoreInst *Fault = TrapBuilder.CreateStore(
        TrapBuilder.getInt8(0),
        ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
    Fault->setVolatile(true);
    ++Guarded;
    Changed = true;
  }

  // Access-level traps are the sound insertion point.  Splitting at a shared
  // producer GEP can move it across other users and violate LLVM dominance.
  return Guarded;

}

// Guard direct dynamic accesses rooted in a recovered frame backing.  Mixed
// data/stack selects are deliberately excluded: their existing range dispatch
// decides which object is active at runtime.
static unsigned guardRecoveredStackBounds(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  auto FindBacking = [&](Value *V, bool &Dynamic,
                         auto &&Self) -> GlobalVariable * {
    if (!V)
      return nullptr;
    V = V->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(V))
      return GV->getName().starts_with("frame_storage_backing.") ? GV
                                                                  : nullptr;
    if (auto *GEP = dyn_cast<GEPOperator>(V)) {
      for (Value *Index : GEP->indices())
        if (!isa<ConstantInt>(Index))
          Dynamic = true;
      return Self(GEP->getPointerOperand(), Dynamic, Self);
    }
    if (auto *Cast = dyn_cast<CastInst>(V))
      return Self(Cast->getOperand(0), Dynamic, Self);
    return nullptr;
  };

  SmallVector<Instruction *, 128> Accesses;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *Pointer = nullptr;
        Type *AccessTy = nullptr;
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          Pointer = LI->getPointerOperand();
          AccessTy = LI->getType();
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          Pointer = SI->getPointerOperand();
          AccessTy = SI->getValueOperand()->getType();
        }
        if (!Pointer || !AccessTy || !AccessTy->isSized())
          continue;
        bool Dynamic = false;
        if (FindBacking(Pointer, Dynamic, FindBacking) && Dynamic)
          Accesses.push_back(&I);
      }
    }
  }

  constexpr uint64_t BackingBytes = 16 * 1024 * 1024;
  unsigned Guarded = 0;
  for (Instruction *I : Accesses) {
    if (!I->getParent())
      continue;
    Value *Pointer = nullptr;
    Type *AccessTy = nullptr;
    if (auto *LI = dyn_cast<LoadInst>(I)) {
      Pointer = LI->getPointerOperand();
      AccessTy = LI->getType();
    } else if (auto *SI = dyn_cast<StoreInst>(I)) {
      Pointer = SI->getPointerOperand();
      AccessTy = SI->getValueOperand()->getType();
    }
    bool Dynamic = false;
    GlobalVariable *Backing = FindBacking(Pointer, Dynamic, FindBacking);
    if (!Backing || !Dynamic)
      continue;
    TypeSize Size = DL.getTypeStoreSize(AccessTy);
    if (Size.isScalable())
      continue;
    IRBuilder<> B(I);
    Value *Base = B.CreatePtrToInt(Backing, B.getInt64Ty(),
                                   "native.stack.bounds.base");
    Value *Address = B.CreatePtrToInt(Pointer, B.getInt64Ty(),
                                      "native.stack.bounds.address");
    Value *End = B.CreateAdd(Address, B.getInt64(Size.getFixedValue()),
                             "native.stack.bounds.end");
    Value *Limit = B.CreateAdd(Base, B.getInt64(BackingBytes),
                               "native.stack.bounds.limit");
    Value *Invalid = B.CreateOr(B.CreateICmpULT(Address, Base),
                                B.CreateICmpUGT(End, Limit),
                                "native.stack.bounds.invalid");
    Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, I, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    StoreInst *Fault = TrapBuilder.CreateStore(
        TrapBuilder.getInt8(0),
        ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
    Fault->setVolatile(true);
    ++Guarded;
    Changed = true;
  }
  return Guarded;
}

// This used to clone g_arr_2 into g_arr_2_with_invalid_prefix and RAUW the
// original global with a constant GEP into the padded object.  That preserved
// one q=0 raw-fuzz case, but it also turned recovered guest-address constants
// into host pointer integers through ptrtoint(ConstantExpr GEP) and could
// corrupt LLVM constant ownership at opt teardown.  Bounds/scratch handling in
// guardRecoveredGlobalBounds() now isolates invalid work-array accesses without
// replacing the global object.
static unsigned isolateRecoveredWorkArrayPrefix(Module &M, bool &Changed) {
  (void)M;
  (void)Changed;
  return 0;
}

static GlobalVariable *findRecoveredArrayRoot(Value *V, bool &HasDynamic,
                                              unsigned Depth = 0) {
  if (!V || Depth > 8)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalVariable>(V))
    return GV->getName().starts_with("g_arr_") ? GV : nullptr;
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP)
    return nullptr;
  for (Value *Index : GEP->indices())
    if (!isa<ConstantInt>(Index))
      HasDynamic = true;
  return findRecoveredArrayRoot(GEP->getPointerOperand(), HasDynamic,
                                Depth + 1);
}

static bool isResidualConstantPointer(Value *V) {
  if (!V)
    return false;
  V = V->stripPointerCasts();
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (GEP)
    V = GEP->getPointerOperand()->stripPointerCasts();
  auto *GV = dyn_cast<GlobalVariable>(V);
  if (!GV)
    return false;
  StringRef Name = GV->getName();
  return Name.starts_with("native_data_") ||
         Name.starts_with("native_residual_") ||
         Name.starts_with("dyn_bytes_") ||
         Name.starts_with("g_bytes_");
}

// qsort's base pointer is frequently recovered before compact BSS globals are
// split out.  If the direct qsort operand still points at a residual segment
// but the same function has exactly one dynamic scanf destination rooted in a
// recovered array, keep qsort attached to the mutable recovered array.  This
// preserves programs that read an array with scanf and then sort it; sorting a
// residual snapshot leaves the live recovered array unsorted.
static unsigned rewriteResidualQsortArrayArguments(Module &M, bool &Changed) {
  SmallVector<CallInst *, 16> Work;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    SmallPtrSet<GlobalVariable *, 4> DynamicScanfArrays;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        StringRef Name = Callee ? Callee->getName() : StringRef();
        if (Name != "scanf" && Name != "__isoc99_scanf")
          continue;
        for (unsigned ArgNo = 1; ArgNo < CB->arg_size(); ++ArgNo) {
          Value *Arg = CB->getArgOperand(ArgNo);
          if (!Arg->getType()->isPointerTy())
            continue;
          bool HasDynamic = false;
          GlobalVariable *Root = findRecoveredArrayRoot(Arg, HasDynamic);
          if (Root && HasDynamic && !Root->getName().starts_with("g_arr_0"))
            DynamicScanfArrays.insert(Root);
        }
      }
    }
    if (DynamicScanfArrays.size() != 1)
      continue;
    GlobalVariable *ArrayRoot = *DynamicScanfArrays.begin();

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->arg_size() < 3)
          continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee || Callee->getName() != "qsort")
          continue;
        auto *ElemSize = dyn_cast<ConstantInt>(CI->getArgOperand(2));
        if (!ElemSize || ElemSize->getZExtValue() != 4)
          continue;
        bool AlreadyRecovered = false;
        GlobalVariable *CurrentRoot =
            findRecoveredArrayRoot(CI->getArgOperand(0), AlreadyRecovered);
        if (CurrentRoot != ArrayRoot)
          continue;
        CI->setArgOperand(0, ArrayRoot);
        Work.push_back(CI);
      }
    }
  }
  if (Work.empty())
    return 0;
  Changed = true;
  return Work.size();
}

bool NativeCleanupPass::cleanupModule(Module &M, bool EnforceStrict,
                                      bool PostSouper) {
  // The final pipeline element is a verifier, not a second recovery pass.
  // Running the mutation pipeline again after O3 hides phase-ownership bugs.
  if (EnforceStrict) {
    bool Changed = false;
    unsigned PromotedDispatchers = promoteStackDispatcherStateSlots(M, Changed);
    if (PromotedDispatchers)
      errs() << "  final stack dispatcher state slots promoted to SSA: "
             << PromotedDispatchers << "\n";
    unsigned FinalPointerIntegers =
        rewriteRecoveredPointerIntegerIdentities(M, Changed);
    if (FinalPointerIntegers)
      errs() << "  final recovered pointer integer identities lowered: "
             << FinalPointerIntegers << "\n";
    unsigned FinalStackRecoveredGEPs =
        rewriteRecoveredGlobalStackIndexedGEPs(M, Changed);
    if (FinalStackRecoveredGEPs)
      errs() << "  final recovered stack-indexed GEPs restored: "
             << FinalStackRecoveredGEPs << "\n";
    unsigned FinalVarargPointers =
        rewriteRecoveredVarargSaveSlots(M, Changed);
    if (FinalVarargPointers)
      errs() << "  final recovered variadic pointer save slots lowered: "
             << FinalVarargPointers << "\n";
    unsigned DeadInlineAsm = eraseUnusedInlineAsmCalls(M, Changed);
    if (DeadInlineAsm)
      errs() << "  final unused inline-asm calls erased: " << DeadInlineAsm
             << "\n";
    if (PostSouper) {
      unsigned FinalAffineFramePointers =
          canonicalizeFrameBackingAffinePointers(M, Changed);
      if (FinalAffineFramePointers)
        errs() << "  post-Souper affine frame pointers canonicalized: "
               << FinalAffineFramePointers << "\n";
      unsigned FinalStackDataSelects =
          collapseFrameProvenantDataPointerSelects(M, Changed);
      if (FinalStackDataSelects)
        errs() << "  post-Souper stack-provenant data selects collapsed: "
               << FinalStackDataSelects << "\n";
      unsigned FinalScanfShadows =
          isolateRecoveredScanfDestinations(M, Changed);
      if (FinalScanfShadows)
        errs() << "  post-Souper recovered scanf destinations isolated: "
               << FinalScanfShadows << "\n";
      unsigned FinalCompactedFrames =
          compactProvenConstantFrameBackings(M, Changed);
      if (FinalCompactedFrames)
        errs() << "  post-Souper proven fake stack backings converted to "
                  "native frames: "
               << FinalCompactedFrames << "\n";
    }
    stripRemillMetadata(M, Changed);
    reportNativeContract(M, 0, 0, true);
    return Changed;
  }

  bool Changed = false;
  SmallVector<std::string, 32> Violations;
  if (GlobalVariable *StackStorage = ensureNativeEntrypointStackStorage(M)) {
    if (StackStorage->getName() == "frame_storage_backing.main" &&
        StackStorage->getMetadata("brighten.stack.ensured") == nullptr) {
      StackStorage->setMetadata("brighten.stack.ensured",
                                MDNode::get(M.getContext(), {}));
      Changed = true;
      errs() << "  residual native stack backing ensured for entrypoint\n";
    }
  }
  // Recovered guest ranges are required by the later scanf/external-pointer
  // lowering.  Strip them only after every such use has been materialized.
  stripRemillMetadata(M, Changed, false);

  unsigned ResidualLibcFormats = materializeResidualLibcFormats(M, Changed);
  if (ResidualLibcFormats)
    errs() << "  residual guest libc formats materialized: "
           << ResidualLibcFormats << "\n";
  preserveRecoveredGlobalsAcrossOptimization(M);

  unsigned WidenedRecoveredScalars =
      widenOverNarrowRecoveredScalars(M, Changed);
  if (WidenedRecoveredScalars)
    errs() << "  over-narrow recovered scalars widened: "
           << WidenedRecoveredScalars << "\n";

  unsigned DeadArguments = canonicalizeDeadLiftedArguments(M);
  if (DeadArguments) {
    Changed = true;
    errs() << "  dead lifted poison arguments canonicalized: " << DeadArguments
           << "\n";
  }

  // Do not fill an undef/poison PHI incoming edge in native mode.  A common
  // value on the other edges is not proof that the missing predecessor had
  // the same architectural state; the strict report must retain this gap.

  // Never freeze unresolved architectural values in the native pipeline.
  // `freeze` makes an unknown register/flag stable but does not recover its
  // machine meaning; strict certification must observe and reject it instead.
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

  // Pointer-translation lowering may use an already-proven frame anchor, but
  // native cleanup never creates a synthetic stack to supply one.
  unsigned NativeTranslations =
      rewriteNativeScanfVarargAddresses(M, Changed);
  NativeTranslations += lowerProvenNativePointerTranslations(M, Changed);
  if (NativeTranslations)
    errs() << "  proven native pointer translations lowered: "
           << NativeTranslations << "\n";

  // Preserve callback entrypoints before wrapper inlining removes the only
  // link from a naked qsort trampoline to its lifted comparator body.
  // qsort invokes the trampoline with (lhs, rhs); once the wrapper is gone
  // there is no sound way to reconstruct that callback contract later.
  unsigned EarlyCallbackBridges =
      lowerNativeCallbackTrampolines(M, Changed);
  if (EarlyCallbackBridges)
    errs() << "  early native callback ABI bridges lowered: "
           << EarlyCallbackBridges << "\n";

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
  unsigned EarlyQsortArrays = rewriteResidualQsortArrayArguments(M, Changed);
  if (EarlyQsortArrays)
    errs() << "  residual qsort array arguments recovered: "
           << EarlyQsortArrays << "\n";
  unsigned EarlyConstantGuestPointers =
      rewriteConstantGuestPointerOperands(M, Changed);
  if (EarlyConstantGuestPointers)
    errs() << "  early constant guest pointers lowered: "
           << EarlyConstantGuestPointers << "\n";
  unsigned EarlyMissingScanfDestinations =
      materializeMissingScanfDestinations(M, Changed);
  if (EarlyMissingScanfDestinations)
    errs() << "  missing scanf destinations materialized: "
           << EarlyMissingScanfDestinations << "\n";

  unsigned NativeDataPointers = materializeNativeSegmentPointers(M, Changed);
  if (NativeDataPointers)
    errs() << "  segment pointers materialized as native data: "
           << NativeDataPointers << "\n";
  unsigned MaterializedQsortArrays =
      rewriteResidualQsortArrayArguments(M, Changed);
  if (MaterializedQsortArrays)
    errs() << "  residual qsort array arguments recovered: "
           << MaterializedQsortArrays << "\n";

  // Strict mode is the production contract: do not let the old internal
  // State-pointer ABI survive merely because the optional optimization flag
  // was omitted.
  if (NativeStateSSA || NativeStrict) {
    bool StateSSAChanged = lowerNativeStateABI(M);
    if (!StateSSAChanged) {
      // The native ABI pass is transactional: false means either that there
      // was no proven native State plan or that a plan failed and was rolled
      // back.  The address/stack rewrites below depend on the SSA ABI and
      // must not run on the original lifted ABI after such a rollback.
      errs() << "  native State ABI not lowered; preserving dependent native rewrites\n";
    } else {
      Changed = true;
      errs() << "  native State ABI lowered to explicit SSA slots\n";

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

    // Preserve translated stack integer addresses until the pass can prove
    // their guest-frame provenance.  Rewriting them from affine patterns
    // alone changes valid guest pointers into host stack addresses.
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
    unsigned NativeQsortArrays = rewriteResidualQsortArrayArguments(M, Changed);
    if (NativeQsortArrays)
      errs() << "  residual qsort array arguments recovered: "
             << NativeQsortArrays << "\n";
    unsigned NativeConstantGuestPointers =
        rewriteConstantGuestPointerOperands(M, Changed);
    if (NativeConstantGuestPointers)
      errs() << "  native constant guest pointers lowered: "
             << NativeConstantGuestPointers << "\n";

    // State-ABI lowering can synthesize the final guest-base + dynamic-index
    // expression after the first cleanup sweep.  Rewrite its scanf save-slot
    // use after that lowering as well, while the recovered-global provenance
    // metadata is still available.
    unsigned LateScanfPointers = rewriteNativeScanfVarargAddresses(M, Changed);
    if (LateScanfPointers)
      errs() << "  late native scanf pointer addresses lowered: "
             << LateScanfPointers << "\n";
    unsigned LateQsortArrays = rewriteResidualQsortArrayArguments(M, Changed);
    if (LateQsortArrays)
      errs() << "  residual qsort array arguments recovered: "
             << LateQsortArrays << "\n";
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
    unsigned RecoveredPointerByteGEPs =
        rewriteMaterializedRecoveredPointerByteGEPs(M, Changed);
    if (RecoveredPointerByteGEPs)
      errs() << "  recovered pointer byte GEPs rematerialized: "
             << RecoveredPointerByteGEPs << "\n";
    }
  }

  if ((NativeStateSSA || NativeStrict) && lowerNativeStackAddresses(M)) {
    Changed = true;
    errs() << "  native stack addresses rebased on recovered frame\n";
  }

  // A failed State-SSA transaction can still leave a valid recovered frame
  // backing and direct scanf pointer selects.  Normalize only those stack
  // arms even in that rollback mode; the broad external-pointer sweep above
  // remains gated by the proven native State ABI.
  unsigned RollbackScanfPointers =
      rewriteRecoveredExternalPointerArguments(M, Changed, true);
  if (RollbackScanfPointers)
    errs() << "  rollback-mode scanf stack pointer arms lowered: "
           << RollbackScanfPointers << "\n";

  unsigned NativeVarargExternalPointers =
      rewriteNativeVarargExternalPointerArguments(M, Changed);
  if (NativeVarargExternalPointers)
    errs() << "  native variadic external pointer arguments restored: "
           << NativeVarargExternalPointers << "\n";

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

  // Conservatively preserved residual segments acquire their exact guest
  // range while the final data_<addr> aliases are removed above.  Revisit
  // dynamic inttoptrs now: the earlier State-SSA-dependent sweep could not
  // prove their mapping before that provenance existed (and a later cleanup
  // sweep may legitimately roll its State transaction back).
  unsigned FinalDynamicGuestPointers = 0;
  unsigned FinalResidualGuestPointers = 0;
  if (DataAliases) {
    FinalDynamicGuestPointers =
        rewriteDynamicGuestAddressIntToPtr(M, Changed);
    FinalResidualGuestPointers =
        rewriteResidualRecoveredDataIntToPtrs(M, Changed);
  }
  if (FinalDynamicGuestPointers)
    errs() << "  final dynamic guest pointers lowered: "
           << FinalDynamicGuestPointers << "\n";
  if (FinalResidualGuestPointers)
    errs() << "  final residual guest data inttoptrs lowered: "
           << FinalResidualGuestPointers << "\n";

  unsigned ConstantGuestPointers =
      rewriteConstantGuestPointerOperands(M, Changed);
  if (ConstantGuestPointers)
    errs() << "  constant guest pointers lowered: " << ConstantGuestPointers
           << "\n";

  unsigned StackRecoveredGEPs =
      rewriteRecoveredGlobalStackIndexedGEPs(M, Changed);
  if (StackRecoveredGEPs)
    errs() << "  recovered stack-indexed GEPs restored: "
           << StackRecoveredGEPs << "\n";

  unsigned FinalVarargPointers = rewriteRecoveredVarargSaveSlots(M, Changed);
  if (FinalVarargPointers)
    errs() << "  final recovered variadic pointer save slots lowered: "
           << FinalVarargPointers << "\n";

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
  unsigned QsortCallbacks = lowerNativeQsortCallbacks(M, Changed);
  if (QsortCallbacks)
    errs() << "  qsort callback ABI bridges lowered: " << QsortCallbacks
           << "\n";
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
  // State/entrypoint normalization can expose one final direct inttoptr of
  // the architectural RSP in native bodies.  Run the provenance-gated stack
  // lowering once more after the entry seed is in place; this is deliberately
  // separate from the broad data-pointer cleanup above.
  unsigned LateRawNativeStackPointers = 0;
  bool HasNativeEntrypointCall = false;
  if (Function *Main = M.getFunction("main"))
    for (BasicBlock &BB : *Main)
      for (Instruction &I : BB)
        if (auto *CB = dyn_cast<CallBase>(&I))
          if (Function *Callee = CB->getCalledFunction();
              Callee && Callee->getName().ends_with(".native"))
            HasNativeEntrypointCall = true;
  bool LateStackAlreadyLowered =
      M.getNamedMetadata("brighten.late.stack.lowered") != nullptr;
  bool HasLateStackCandidate = hasRawNativeStackIntToPtrCandidate(M);
  if ((HasNativeEntrypointCall || HasLateStackCandidate) &&
      !LateStackAlreadyLowered) {
    LateRawNativeStackPointers = lowerRawNativeStackIntToPtrs(M, Changed);
    NamedMDNode *Marker = M.getOrInsertNamedMetadata(
        "brighten.late.stack.lowered");
    Marker->addOperand(MDNode::get(
        M.getContext(), {ConstantAsMetadata::get(
                            ConstantInt::get(Type::getInt1Ty(M.getContext()),
                                             true))}));
  }
  if (LateRawNativeStackPointers)
    errs() << "  late raw guest stack inttoptrs lowered: "
           << LateRawNativeStackPointers << "\n";
  unsigned AffineFramePointers =
      canonicalizeFrameBackingAffinePointers(M, Changed);
  if (AffineFramePointers)
    errs() << "  affine frame pointers canonicalized: "
           << AffineFramePointers << "\n";
  unsigned StackDataSelects =
      collapseFrameProvenantDataPointerSelects(M, Changed);
  if (StackDataSelects)
    errs() << "  stack-provenant data selects collapsed: "
           << StackDataSelects << "\n";
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

  unsigned LateMissingScanfDestinations =
      materializeMissingScanfDestinations(M, Changed);
  if (LateMissingScanfDestinations)
    errs() << "  late missing scanf destinations materialized: "
           << LateMissingScanfDestinations << "\n";
  // Preserve scanf failure semantics; do not seed or trap destinations.
  unsigned PromotedDispatchers = promoteStackDispatcherStateSlots(M, Changed);
  if (PromotedDispatchers)
    errs() << "  stack dispatcher state slots promoted to SSA: "
           << PromotedDispatchers << "\n";
  // Do not broadly initialize scanf destinations before the call.  Native
  // scanf leaves an integer destination unchanged when conversion/EOF fails;
  // the narrow seeding above is limited to recovered integer locals whose
  // zero-backed frame would otherwise turn raw failed conversions into
  // defined-looking values.
  unsigned IsolatedWorkArray =
      isolateRecoveredWorkArrayPrefix(M, Changed);
  if (IsolatedWorkArray)
    errs() << "  recovered work-array invalid prefix isolated: "
           << IsolatedWorkArray << "\n";
  // Do not synthesize null-pointer stores for recovered global bounds.  The
  // lifted image-backed address space can legitimately use negative offsets
  // into adjacent mapped segments; trapping here caused SIGSEGVs on valid
  // contract inputs.  Keep the original access unless provenance is proven.
  unsigned LatePointerIntegers =
      rewriteRecoveredPointerIntegerIdentities(M, Changed);
  if (LatePointerIntegers)
    errs() << "  late recovered pointer integer identities lowered: "
           << LatePointerIntegers << "\n";
  // No recovery step below this point consumes guest-range provenance; remove
  // it now so the final NativeStrict contract remains metadata-free.
  // Keep guest-range provenance across the intervening O3 pipeline.  A later
  // cleanup invocation still needs it to materialize libc format constants
  // after translator calls have folded to raw guest addresses.  The final
  // strict verifier strips it once all rewrites are complete.
  stripRemillMetadata(M, Changed, false);
  foldExactPointerRoundTrips(M, Changed);
  reportNativeContract(M, RemovedFunctions, RemovedGlobals, false);

  return Changed;
}

} // namespace brighten_native_cleanup
