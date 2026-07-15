#include "NativeStateSSA.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <algorithm>
#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

using namespace llvm;

namespace brighten_native_cleanup {
namespace {

struct Slot {
  uint64_t Offset = 0;
  Type *Ty = nullptr;
};

enum class HiddenTokenKind {
  State,
  Memory,
  PC,
};

struct Plan {
  Function *Old = nullptr;
  Function *New = nullptr;
  GlobalVariable *Proxy = nullptr;
  StructType *ResultTy = nullptr;
  unsigned HiddenArgs = 1;
  SmallVector<HiddenTokenKind, 2> HiddenTokens;
  Type *OldReturnTy = nullptr;
  SmallVector<unsigned, 8> OldExplicitArgs;
  SmallVector<Slot, 32> Inputs;
  SmallVector<Slot, 32> Outputs;
  SmallVector<Slot, 32> Used;
  DenseMap<uint64_t, AllocaInst *> LocalSlots;
  DenseMap<uint64_t, Type *> SlotTypes;
  DenseMap<uint64_t, unsigned> ResultFields;
  std::optional<uint64_t> ReturnSlot;
  bool HasStateUses = false;
  bool HasNativeStackArg = false;
  bool HasHiddenStateArg = false;
};

// McSema exposes overlapping aliases for both 64-bit halves of each XMM
// register.  For example, offsets 80/84 are the low lane and 88/92 are the
// high lane of XMM1.  Each pair must share one native slot, otherwise a
// 32-bit store to the upper half is invisible to a subsequent 64-bit load.
static std::optional<uint64_t> CanonicalStateSlotOffset(uint64_t Offset) {
  static constexpr uint64_t XMMBases[] = {
      16, 80, 144, 208, 272, 336, 400, 464};
  for (uint64_t Base : XMMBases) {
    if (Offset == Base + 4)
      return Base;
    if (Offset == Base + 8 || Offset == Base + 12)
      return Base;
  }
  return Offset;
}

static bool IsXMMUpperLaneOffset(uint64_t Offset) {
  static constexpr uint64_t XMMBases[] = {
      16, 80, 144, 208, 272, 336, 400, 464};
  for (uint64_t Base : XMMBases)
    if (Offset == Base + 8 || Offset == Base + 12)
      return true;
  return false;
}

static bool IsXMMStateSlotOffset(uint64_t Offset) {
  static constexpr uint64_t XMMBases[] = {
      16, 80, 144, 208, 272, 336, 400, 464};
  for (uint64_t Base : XMMBases)
    if (Offset == Base || Offset == Base + 8)
      return true;
  return false;
}

static Value *LocalSlotPointer(IRBuilder<> &B, Plan &P, uint64_t Offset) {
  auto Canonical = CanonicalStateSlotOffset(Offset);
  if (!Canonical)
    return nullptr;
  auto It = P.LocalSlots.find(*Canonical);
  if (It == P.LocalSlots.end())
    return nullptr;
  if (*Canonical == Offset)
    return It->second;
  return B.CreateConstGEP1_64(B.getInt8Ty(), It->second,
                              Offset - *Canonical, "native.state.subslot");
}

static bool IsNative(Function &F) {
  if (F.isDeclaration())
    return false;
  if (F.getName().ends_with(".native"))
    return true;
  return F.getName() == "__remill_function_call" && !F.arg_empty() &&
         F.getArg(0)->getType()->isPointerTy();
}

static std::optional<uint64_t>
StateOffsetImpl(Value *Ptr, Value *Base, const DataLayout &DL,
                SmallPtrSetImpl<Value *> &Seen) {
  if (!Ptr || !Base)
    return std::nullopt;
  Value *Stripped = Ptr->stripPointerCasts();
  if (!Seen.insert(Stripped).second)
    return std::nullopt;

  if (auto *PN = dyn_cast<PHINode>(Stripped)) {
    std::optional<uint64_t> Common;
    for (Value *Incoming : PN->incoming_values()) {
      SmallPtrSet<Value *, 32> BranchSeen;
      for (Value *SeenValue : Seen)
        BranchSeen.insert(SeenValue);
      auto Offset = StateOffsetImpl(Incoming, Base, DL, BranchSeen);
      if (!Offset)
        return std::nullopt;
      if (!Common)
        Common = Offset;
      else if (*Common != *Offset)
        return std::nullopt;
    }
    return Common;
  }

  if (auto *Sel = dyn_cast<SelectInst>(Stripped)) {
    SmallPtrSet<Value *, 32> TrueSeen;
    SmallPtrSet<Value *, 32> FalseSeen;
    for (Value *SeenValue : Seen) {
      TrueSeen.insert(SeenValue);
      FalseSeen.insert(SeenValue);
    }
    auto TrueOffset =
        StateOffsetImpl(Sel->getTrueValue(), Base, DL, TrueSeen);
    auto FalseOffset =
        StateOffsetImpl(Sel->getFalseValue(), Base, DL, FalseSeen);
    if (TrueOffset && FalseOffset && *TrueOffset == *FalseOffset)
      return TrueOffset;
    return std::nullopt;
  }

  auto *GEP = dyn_cast<GEPOperator>(Stripped);
  if (!GEP)
    return std::nullopt;
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *GEPBase = GEP->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (GEPBase != Base || Offset.isNegative())
    return std::nullopt;
  return Offset.getZExtValue();
}

static std::optional<uint64_t> StateOffset(Value *Ptr, Value *Base,
                                            const DataLayout &DL) {
  SmallPtrSet<Value *, 32> Seen;
  return StateOffsetImpl(Ptr, Base, DL, Seen);
}

// McSema emits register aliases rooted at the TLS State global even after a
// native clone has acquired the explicit State argument.  Treat those aliases
// as another spelling of the function's State ABI, so the same SSA lowering
// handles both forms and no hidden register-file global survives the clone.
static std::optional<uint64_t>
GlobalStateOffset(Value *Ptr, const DataLayout &DL,
                  SmallPtrSetImpl<Value *> &Seen) {
  if (!Ptr || !Seen.insert(Ptr).second)
    return std::nullopt;

  Value *Stripped = Ptr->stripPointerCasts();
  if (auto *GA = dyn_cast<GlobalAlias>(Stripped))
    return GlobalStateOffset(GA->getAliasee(), DL, Seen);

  if (auto *GV = dyn_cast<GlobalValue>(Stripped)) {
    if (GV->getName().contains("__mcsema_reg_state"))
      return 0;
    return std::nullopt;
  }

  auto *GEP = dyn_cast<GEPOperator>(Stripped);
  if (!GEP)
    return std::nullopt;

  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = GEP->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (Offset.isNegative())
    return std::nullopt;
  auto Parent = GlobalStateOffset(Base, DL, Seen);
  if (!Parent)
    return std::nullopt;
  uint64_t Delta = Offset.getZExtValue();
  if (*Parent > UINT64_MAX - Delta)
    return std::nullopt;
  return *Parent + Delta;
}

static bool RedirectGlobalStateAccesses(Function &F, const DataLayout &DL) {
  if (F.arg_empty() || !F.getArg(0)->getType()->isPointerTy() ||
      F.getArg(0)->getName() != "state")
    return false;

  Value *State = F.getArg(0);
  SmallVector<std::pair<Instruction *, uint64_t>, 64> Accesses;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      Value *Ptr = nullptr;
      if (auto *LI = dyn_cast<LoadInst>(&I))
        Ptr = LI->getPointerOperand();
      else if (auto *SI = dyn_cast<StoreInst>(&I))
        Ptr = SI->getPointerOperand();
      if (!Ptr)
        continue;
      SmallPtrSet<Value *, 8> Seen;
      if (auto Offset = GlobalStateOffset(Ptr, DL, Seen))
        Accesses.push_back({&I, *Offset});
    }
  }

  for (auto [I, Offset] : Accesses) {
    IRBuilder<> B(I);
    Value *StatePtr = B.CreateConstGEP1_64(
        Type::getInt8Ty(F.getContext()), State, Offset,
        "native.state.global.slot");
    if (auto *LI = dyn_cast<LoadInst>(I))
      LI->setOperand(0, StatePtr);
    else
      cast<StoreInst>(I)->setOperand(1, StatePtr);
  }
  return !Accesses.empty();
}

static unsigned ScalarBits(Type *Ty) {
  if (!Ty)
    return 0;
  if (auto *IT = dyn_cast<IntegerType>(Ty))
    return IT->getBitWidth();
  if (Ty->isFloatingPointTy())
    return Ty->getPrimitiveSizeInBits();
  if (auto *VT = dyn_cast<FixedVectorType>(Ty)) {
    unsigned ElementBits = ScalarBits(VT->getElementType());
    if (!ElementBits)
      return 0;
    return ElementBits * VT->getNumElements();
  }
  return 0;
}

static bool IsBitPatternType(Type *Ty) {
  return Ty && (Ty->isIntegerTy() || Ty->isFloatingPointTy() ||
                isa<FixedVectorType>(Ty));
}

static Type *MergeSlotType(Type *A, Type *B) {
  if (!A)
    return B;
  if (!B || A == B)
    return A;
  if (A->isIntegerTy() && B->isIntegerTy()) {
    unsigned Width = std::max(cast<IntegerType>(A)->getBitWidth(),
                              cast<IntegerType>(B)->getBitWidth());
    return IntegerType::get(A->getContext(), Width);
  }
  // x86-64 State register slots are sometimes loaded through a pointer view
  // (notably RSP during a lifted epilogue) and elsewhere through i64.  The
  // canonical SSA representation must remain the integer register bits.
  if (A->isPointerTy() && B->isIntegerTy(64))
    return B;
  if (B->isPointerTy() && A->isIntegerTy(64))
    return A;
  // A register-sized state slot is often accessed through both its integer
  // representation and its floating-point representation (for example an
  // XMM lane saved as double and later consumed as i64).  Keep the slot in a
  // canonical integer form and bitcast at the individual access sites so we
  // preserve the bits without rejecting an otherwise valid native clone.
  unsigned ABits = ScalarBits(A);
  unsigned BBits = ScalarBits(B);
  if (ABits && BBits && IsBitPatternType(A) && IsBitPatternType(B))
    return IntegerType::get(A->getContext(), std::max(ABits, BBits));
  if (A->isPointerTy() && B->isPointerTy())
    return PointerType::getUnqual(A->getContext());
  return nullptr;
}

static void AddUsedSlot(Plan &P, uint64_t Offset, Type *Ty) {
  auto It = P.SlotTypes.find(Offset);
  if (It == P.SlotTypes.end()) {
    P.SlotTypes[Offset] = Ty;
    P.Used.push_back({Offset, Ty});
    return;
  }
  Type *Merged = MergeSlotType(It->second, Ty);
  if (!Merged)
    return;
  It->second = Merged;
  for (Slot &S : P.Used)
    if (S.Offset == Offset)
      S.Ty = Merged;
}

static void SortSlots(SmallVectorImpl<Slot> &Slots) {
  llvm::sort(Slots, [](const Slot &A, const Slot &B) {
    return A.Offset < B.Offset;
  });
  Slots.erase(std::unique(Slots.begin(), Slots.end(),
                          [](const Slot &A, const Slot &B) {
                            return A.Offset == B.Offset;
                          }),
              Slots.end());
}

static void RefreshPlanSlotTypes(Plan &P) {
  auto Refresh = [&](SmallVectorImpl<Slot> &Slots) {
    for (Slot &S : Slots) {
      if (Type *Ty = P.SlotTypes.lookup(S.Offset))
        S.Ty = Ty;
    }
  };
  Refresh(P.Inputs);
  Refresh(P.Outputs);
  Refresh(P.Used);
}

static void CollectHiddenTokens(Plan &P) {
  P.HiddenTokens.clear();
  for (Argument &Arg : P.Old->args()) {
    StringRef Name = Arg.getName();
    if (Name == "state")
      P.HiddenTokens.push_back(HiddenTokenKind::State);
    else if (Name == "memory")
      P.HiddenTokens.push_back(HiddenTokenKind::Memory);
    else if (Name == "pc")
      P.HiddenTokens.push_back(HiddenTokenKind::PC);
    else
      break;
  }
  P.HiddenArgs = P.HiddenTokens.size();
  P.HasHiddenStateArg = llvm::is_contained(
      P.HiddenTokens, HiddenTokenKind::State);
}

static void CollectPlanUses(Plan &P, const DataLayout &DL) {
  Function &F = *P.Old;
  CollectHiddenTokens(P);
  Value *State = nullptr;
  for (unsigned I = 0; I < P.HiddenTokens.size(); ++I)
    if (P.HiddenTokens[I] == HiddenTokenKind::State) {
      State = F.getArg(I);
      break;
    }
  P.OldReturnTy = F.getReturnType();

  // Pass 030 may already have promoted RSP/RBP into annotated allocas.  Those
  // accesses no longer look like State GEPs below, but their derived integer
  // addresses still require the explicit native frame base.  Preserve that
  // cross-pass fact instead of silently dropping the frame argument.
  for (Instruction &I : F.getEntryBlock()) {
    auto *AI = dyn_cast<AllocaInst>(&I);
    MDNode *MD = AI ? AI->getMetadata("brighten.state.offset") : nullptr;
    if (!MD || MD->getNumOperands() != 1)
      continue;
    auto *CAM = dyn_cast<ConstantAsMetadata>(MD->getOperand(0));
    auto *CI = CAM ? dyn_cast<ConstantInt>(CAM->getValue()) : nullptr;
    if (!CI)
      continue;
    uint64_t Offset = CI->getZExtValue();
    P.HasNativeStackArg |= Offset == 2312 || Offset == 2328;
  }

  for (unsigned I = P.HiddenArgs; I < F.arg_size(); ++I)
    P.OldExplicitArgs.push_back(I);

  SmallVector<MemSetInst *, 8> StateMemSets;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto *MS = dyn_cast<MemSetInst>(&I)) {
        Value *Ptr = MS->getDest();
        auto Offset = StateOffset(Ptr, State, DL);
        if (!Offset) {
          SmallPtrSet<Value *, 8> Seen;
          Offset = GlobalStateOffset(Ptr, DL, Seen);
        }
        if (Offset)
          StateMemSets.push_back(MS);
        continue;
      }
      Value *Ptr = nullptr;
      Type *AccessTy = nullptr;
      bool IsLoad = false;
      bool IsStore = false;
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        Ptr = LI->getPointerOperand();
        AccessTy = LI->getType();
        IsLoad = true;
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        Ptr = SI->getPointerOperand();
        AccessTy = SI->getValueOperand()->getType();
        IsStore = true;
      }
      if (!Ptr)
        continue;
      auto Offset = StateOffset(Ptr, State, DL);
      if (!Offset) {
        SmallPtrSet<Value *, 8> Seen;
        Offset = GlobalStateOffset(Ptr, DL, Seen);
      }
      if (!Offset)
        continue;
      uint64_t SlotOffset = *CanonicalStateSlotOffset(*Offset);
      Type *SlotAccessTy = AccessTy;
      // The canonical low XMM lane is carried as an i64 so both the
      // base+0 and base+4 aliases update the same bit pattern.
      if (SlotOffset != *Offset)
        SlotAccessTy = IsXMMUpperLaneOffset(*Offset)
                           ? Type::getIntNTy(F.getContext(), 128)
                           : Type::getInt64Ty(F.getContext());
      P.HasStateUses = true;
      AddUsedSlot(P, SlotOffset, SlotAccessTy);
      if (IsLoad)
        P.Inputs.push_back({SlotOffset, SlotAccessTy});
      if (IsStore) {
        // A partial store to an overlapping register slot is a
        // read-modify-write operation.  The store rewriter preserves the
        // untouched bits, so the old slot value must cross the native-call
        // boundary even when the lifted IR has no explicit LoadInst.
        unsigned AccessBits = ScalarBits(AccessTy);
        unsigned SlotBits = ScalarBits(SlotAccessTy);
        if (SlotOffset != *Offset ||
            (AccessBits && SlotBits && AccessBits < SlotBits))
          P.Inputs.push_back({SlotOffset, SlotAccessTy});
        P.Outputs.push_back({SlotOffset, SlotAccessTy});
      }
    }
  }
  // A whole-slot zero memset is equivalent to a scalar zero store, but only
  // after another typed access has established the exact native slot.  Do not
  // invent a type for partial, dynamic, non-zero, or volatile byte writes.
  for (MemSetInst *MS : StateMemSets) {
    auto *Fill = dyn_cast<ConstantInt>(MS->getValue());
    auto *Length = dyn_cast<ConstantInt>(MS->getLength());
    if (MS->isVolatile() || !Fill || !Fill->isZero() || !Length ||
        Length->isZero())
      continue;
    auto Offset = StateOffset(MS->getDest(), State, DL);
    if (!Offset) {
      SmallPtrSet<Value *, 8> Seen;
      Offset = GlobalStateOffset(MS->getDest(), DL, Seen);
    }
    if (!Offset)
      continue;
    auto Canonical = CanonicalStateSlotOffset(*Offset);
    Type *SlotTy = Canonical ? P.SlotTypes.lookup(*Canonical) : nullptr;
    uint64_t Bytes = Length->getZExtValue();
    if (!Canonical || *Canonical != *Offset || !SlotTy ||
        Bytes > UINT64_MAX / 8 || ScalarBits(SlotTy) != Bytes * 8)
      continue;
    P.HasStateUses = true;
    AddUsedSlot(P, *Canonical, SlotTy);
    P.Outputs.push_back({*Canonical, SlotTy});
  }
  SortSlots(P.Inputs);
  SortSlots(P.Outputs);
  SortSlots(P.Used);
  // The Remill dispatcher returns the Memory* threading token, not the guest
  // RAX value.  Its RAX store must remain an explicit State output instead of
  // being paired with (and replaced by) that pointer return.
  if (!P.OldReturnTy->isVoidTy() &&
      P.Old->getName() != "__remill_function_call") {
    uint64_t ABIResultSlot =
        (P.OldReturnTy->isFloatingPointTy() || P.OldReturnTy->isVectorTy())
            ? 16
            : 2216;
    auto It = llvm::find_if(P.Outputs, [&](const Slot &S) {
      return S.Offset == ABIResultSlot;
    });
    if (It != P.Outputs.end()) {
      P.ReturnSlot = ABIResultSlot;
      P.Outputs.erase(It);
    }
  }
  // Preserve ABI result/caller-saved registers and condition codes.  The latter are live
  // across small lifted comparison helpers: dropping them leaves the caller's
  // SSA flags stale and changes the following branch.  RSP is also a required
  // call-frame result: lifted callers push a return address before the call
  // and the callee's RET advances RSP by eight.  Dropping that output leaves
  // the caller permanently at the pre-RET address. RBP must cross the native
  // call boundary as well: post-call guest-frame accesses remain RBP-relative,
  // and substituting a transient/restored RSP makes distinct locals alias.
  // The return builder below preserves the proven incoming RBP value.
  llvm::erase_if(P.Outputs, [](const Slot &S) {
    const bool IsConditionCode = S.Offset >= 2064 && S.Offset < 2080;
    const bool IsCallerSavedGPR = S.Offset == 2216 || S.Offset == 2248 ||
                                  S.Offset == 2264 || S.Offset == 2280 ||
                                  S.Offset == 2296 || S.Offset == 2344 ||
                                  S.Offset == 2360;
    const bool IsCallFrameRegister = S.Offset == 2312 || S.Offset == 2328;
    return !IsConditionCode && !IsCallerSavedGPR && !IsCallFrameRegister &&
           !IsXMMStateSlotOffset(S.Offset);
  });
  for (Slot &S : P.Inputs)
    S.Ty = P.SlotTypes.lookup(S.Offset);
  for (Slot &S : P.Outputs)
    S.Ty = P.SlotTypes.lookup(S.Offset);
  for (Slot &S : P.Used)
    S.Ty = P.SlotTypes.lookup(S.Offset);
  for (const Slot &S : P.Used)
    P.HasNativeStackArg |= S.Offset == 2312 || S.Offset == 2328;
}

static Plan *FindPlan(DenseMap<Function *, std::unique_ptr<Plan>> &Plans,
                      Function *F) {
  auto It = Plans.find(F);
  if (It != Plans.end())
    return It->second.get();
  if (!F || !F->getParent() || F->getName().ends_with(".native"))
    return nullptr;
  std::string NativeName = (F->getName() + ".native").str();
  if (Function *Native = F->getParent()->getFunction(NativeName)) {
    It = Plans.find(Native);
    if (It != Plans.end())
      return It->second.get();
  }
  return nullptr;
}

static std::optional<uint64_t> ExplicitGPRStateOffset(StringRef Name) {
  if (!Name.starts_with("arg_"))
    return std::nullopt;
  StringRef Reg = Name.drop_front(4);
  if (Reg == "RAX") return 2216;
  if (Reg == "RCX") return 2248;
  if (Reg == "RDX") return 2264;
  if (Reg == "RSI") return 2280;
  if (Reg == "RDI") return 2296;
  if (Reg == "RSP") return 2312;
  if (Reg == "RBP") return 2328;
  if (Reg == "R8") return 2344;
  if (Reg == "R9") return 2360;
  return std::nullopt;
}

static std::optional<uint64_t>
ExplicitRegisterStateOffset(StringRef Name);

static bool AddCallStateRequirements(DenseMap<Function *, std::unique_ptr<Plan>> &Plans) {
  bool Changed = false;
  for (auto &Entry : Plans) {
    Plan &Caller = *Entry.second;
    for (BasicBlock &BB : *Caller.Old) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        Plan *CalleePlan = FindPlan(Plans, Callee);
        if (!CalleePlan || CalleePlan == &Caller)
          continue;
        if (CalleePlan->HasNativeStackArg && !Caller.HasNativeStackArg) {
          Caller.HasNativeStackArg = true;
          Changed = true;
        }
        for (const Slot &S : CalleePlan->Inputs) {
          if (!Caller.SlotTypes.count(S.Offset)) {
            AddUsedSlot(Caller, S.Offset, S.Ty);
            Changed = true;
          }
          auto Before = Caller.Inputs.size();
          Caller.Inputs.push_back(S);
          SortSlots(Caller.Inputs);
          Changed |= Caller.Inputs.size() != Before;
        }
        if (CalleePlan->Old != Callee) {
          for (unsigned ArgNo : CalleePlan->OldExplicitArgs) {
            Argument *Arg = CalleePlan->Old->getArg(ArgNo);
            auto Offset = ExplicitRegisterStateOffset(Arg->getName());
            if (!Offset)
              continue;
            if (!Caller.SlotTypes.count(*Offset)) {
              AddUsedSlot(Caller, *Offset, Arg->getType());
              Changed = true;
            }
            auto Before = Caller.Inputs.size();
            Caller.Inputs.push_back({*Offset, Arg->getType()});
            SortSlots(Caller.Inputs);
            Changed |= Caller.Inputs.size() != Before;
          }
        }
      }
    }
  }
  return Changed;
}

static Value *ToIntegerBits(IRBuilder<> &B, Value *V, unsigned Bits,
                            const Twine &Name) {
  if (!V || !Bits || !IsBitPatternType(V->getType()))
    return nullptr;
  Type *IntTy = IntegerType::get(B.getContext(), Bits);
  Type *SrcTy = V->getType();
  unsigned SrcBits = ScalarBits(SrcTy);

  Value *Integer = V;
  if (!SrcTy->isIntegerTy()) {
    Type *SrcIntTy = IntegerType::get(B.getContext(), SrcBits);
    Integer = B.CreateBitCast(V, SrcIntTy, Name + ".bits");
  }
  if (Integer->getType() == IntTy)
    return Integer;
  unsigned SrcWidth = cast<IntegerType>(Integer->getType())->getBitWidth();
  if (SrcWidth > Bits)
    return B.CreateTrunc(Integer, IntTy, Name);
  return B.CreateZExt(Integer, IntTy, Name);
}

static Value *Coerce(IRBuilder<> &B, Value *V, Type *Ty, const Twine &Name) {
  if (!V || !Ty)
    return nullptr;
  if (V->getType() == Ty)
    return V;
  unsigned SrcBits = ScalarBits(V->getType());
  unsigned DstBits = ScalarBits(Ty);
  if (SrcBits && SrcBits == DstBits && IsBitPatternType(V->getType()) &&
      IsBitPatternType(Ty) &&
      !(V->getType()->isIntegerTy() && Ty->isIntegerTy()) &&
      !(V->getType()->isFloatingPointTy() && Ty->isFloatingPointTy()))
    return B.CreateBitCast(V, Ty, Name);
  if (V->getType()->isIntegerTy() && Ty->isIntegerTy()) {
    unsigned SW = cast<IntegerType>(V->getType())->getBitWidth();
    unsigned DW = cast<IntegerType>(Ty)->getBitWidth();
    if (SW > DW)
      return B.CreateTrunc(V, Ty, Name);
    return B.CreateZExt(V, Ty, Name);
  }
  if (V->getType()->isFloatingPointTy() && Ty->isFloatingPointTy()) {
    if (SrcBits > DstBits)
      return B.CreateFPTrunc(V, Ty, Name);
    return B.CreateFPExt(V, Ty, Name);
  }
  // State slots use an integer bit representation when the same byte range
  // is accessed through different scalar/vector types.  Resize the integer
  // bit pattern before converting it back to the requested access type.
  if (SrcBits && DstBits && IsBitPatternType(V->getType()) &&
      IsBitPatternType(Ty) &&
      (V->getType()->isIntegerTy() || Ty->isIntegerTy())) {
    Value *Bits = ToIntegerBits(B, V, DstBits, Name + ".bits");
    if (!Bits)
      return nullptr;
    if (Ty->isIntegerTy())
      return Bits;
    return B.CreateBitCast(Bits, Ty, Name);
  }
  if (V->getType()->isVectorTy() && Ty->isVectorTy() &&
      SrcBits == DstBits)
    return B.CreateBitCast(V, Ty, Name);
  if (V->getType()->isPointerTy() && Ty->isPointerTy())
    return B.CreateBitCast(V, Ty, Name);
  if (V->getType()->isIntegerTy() && Ty->isPointerTy())
    return B.CreateIntToPtr(V, Ty, Name);
  if (V->getType()->isPointerTy() && Ty->isIntegerTy())
    return B.CreatePtrToInt(V, Ty, Name);
  return nullptr;
}

static Value *BuildStateGEP(IRBuilder<> &B, Value *State, uint64_t Offset) {
  return B.CreateConstGEP1_64(B.getInt8Ty(), State, Offset,
                              "native.state.slot");
}

static FunctionType *BuildNewType(Plan &P, LLVMContext &Ctx) {
  SmallVector<Type *, 32> Args;
  // The guest RSP/RBP values are integer encodings of one shared native
  // stack anchor.  Carry that anchor explicitly through the native call
  // graph so address lowering can use GEPs instead of inttoptr.
  if (P.HasNativeStackArg)
    Args.push_back(PointerType::getUnqual(Ctx));
  for (const Slot &S : P.Inputs)
    Args.push_back(S.Ty);
  for (unsigned I : P.OldExplicitArgs)
    Args.push_back(P.Old->getArg(I)->getType());

  SmallVector<Type *, 32> Results;
  if (!P.OldReturnTy->isVoidTy())
    Results.push_back(P.OldReturnTy);
  for (const Slot &S : P.Outputs)
    Results.push_back(S.Ty);
  if (Results.empty())
    return FunctionType::get(Type::getVoidTy(Ctx), Args, false);
  if (Results.size() == 1)
    return FunctionType::get(Results.front(), Args, false);
  std::string ResultName = P.Old->getName().str();
  if (StringRef(ResultName).ends_with(".native"))
    ResultName.resize(ResultName.size() - 7);
  P.ResultTy = StructType::create(Ctx, Results, ResultName + ".native_result");
  return FunctionType::get(P.ResultTy, Args, false);
}

// ABI recovery can leave a recovered register as both an explicit argument
// (for example `arg_XMM1`) and a State slot.  The explicit argument is only
// the entry value; after a native call the live value is the slot updated by
// the callee's result.  Read the slot at each use so loops observe the
// caller-visible register output instead of the stale entry argument.
static std::optional<uint64_t>
ExplicitRegisterStateOffset(StringRef Name) {
  if (auto GPR = ExplicitGPRStateOffset(Name))
    return GPR;
  if (!Name.starts_with("arg_"))
    return std::nullopt;
  StringRef Reg = Name.drop_front(4);
  if (Reg == "XMM0")
    return 16;
  if (Reg == "XMM1")
    return 80;
  if (Reg == "XMM2")
    return 144;
  return std::nullopt;
}

static Value *LoadExplicitRegisterSlot(IRBuilder<> &B, Plan &P,
                                       uint64_t Offset, Type *ExpectedTy) {
  auto It = P.LocalSlots.find(Offset);
  if (It == P.LocalSlots.end())
    return nullptr;
  Type *SlotTy = P.SlotTypes.lookup(Offset);
  Value *V = B.CreateLoad(SlotTy, It->second, "native.arg.state");
  if (V->getType() == ExpectedTy)
    return V;
  return Coerce(B, V, ExpectedTy, "native.arg.state.coerce");
}

static bool RewriteExplicitRegisterArguments(Plan &P) {
  SmallVector<Argument *, 16> Candidates;
  unsigned FirstExplicit = (P.HasNativeStackArg ? 1 : 0) + P.Inputs.size();
  for (unsigned I = FirstExplicit; I < P.New->arg_size(); ++I) {
    Argument *Arg = P.New->getArg(I);
    if (ExplicitRegisterStateOffset(Arg->getName()))
      Candidates.push_back(Arg);
  }

  for (Argument *Arg : Candidates) {
    auto Offset = ExplicitRegisterStateOffset(Arg->getName());
    if (!Offset || !P.LocalSlots.count(*Offset))
      continue;
    SmallVector<Use *, 32> Uses;
    for (Use &U : Arg->uses())
      Uses.push_back(&U);

    // The recovered explicit ABI argument is the authoritative entry value.
    // A duplicated State input is only the caller's pre-call snapshot and can
    // legitimately differ (main's argv registers and call-preparation moves
    // are common examples).  Seed the shared slot from the explicit argument;
    // subsequent native-call outputs will continue updating that same slot.
    BasicBlock &Entry = P.New->getEntryBlock();
    Instruction *InsertBefore = Entry.getTerminator();
    for (Instruction &I : Entry) {
      if (isa<AllocaInst>(&I))
        continue;
      // ClonePlan seeds every collected State input immediately after the
      // synthetic slot allocas.  Explicit ABI values must be written after
      // those snapshot stores or the stale State input simply overwrites the
      // authoritative call argument.
      if (auto *SI = dyn_cast<StoreInst>(&I)) {
        auto *Input = dyn_cast<Argument>(SI->getValueOperand());
        if (Input && Input->getName().starts_with("state_in_"))
          continue;
      }
      InsertBefore = &I;
      break;
    }
    IRBuilder<> InitB(InsertBefore);
    Type *SlotTy = P.SlotTypes.lookup(*Offset);
    Value *Initial = Coerce(InitB, Arg, SlotTy,
                            "native.arg.state.init.coerce");
    if (!Initial)
      return false;
    InitB.CreateStore(Initial, P.LocalSlots[*Offset]);

    for (Use *U : Uses) {
      auto *UserInst = dyn_cast<Instruction>(U->getUser());
      if (!UserInst)
        continue;
      IRBuilder<> B(UserInst);
      if (auto *PN = dyn_cast<PHINode>(UserInst)) {
        unsigned Incoming =
            PN->getIncomingValueNumForOperand(U->getOperandNo());
        B.SetInsertPoint(PN->getIncomingBlock(Incoming)->getTerminator());
      }
      Value *V = LoadExplicitRegisterSlot(B, P, *Offset, Arg->getType());
      if (!V)
        return false;
      U->set(V);
    }
  }
  return true;
}

static void NameNewArgs(Plan &P) {
  unsigned I = 0;
  if (P.HasNativeStackArg)
    P.New->getArg(I++)->setName("native_stack");
  for (const Slot &S : P.Inputs)
    P.New->getArg(I++)->setName(("state_in_" + Twine(S.Offset)).str());
  for (unsigned OldIndex : P.OldExplicitArgs)
    P.New->getArg(I++)->setName(P.Old->getArg(OldIndex)->getName());
}

static bool ClonePlan(Plan &P, Module &M) {
  auto Fail = [&](const Twine &Reason) {
    errs() << "brighten-native-state-ssa: clone detail for "
            << P.Old->getName() << ": " << Reason << "\n";
    return false;
  };
  LLVMContext &Ctx = M.getContext();
  FunctionType *FT = BuildNewType(P, Ctx);
  P.New = Function::Create(FT, GlobalValue::InternalLinkage,
                           P.Old->getName() + ".state_ssa", M);
  P.New->setCallingConv(P.Old->getCallingConv());
  P.New->setDSOLocal(true);
  NameNewArgs(P);

  // A temporary module-local proxy lets CloneFunctionBodyInto remap the old
  // state argument without retaining it in the new function type.  All
  // accesses based on it are replaced by local SSA slots immediately after
  // cloning and the proxy is deleted at the end.
  P.Proxy = new GlobalVariable(M, Type::getInt8Ty(Ctx), false,
                               GlobalValue::InternalLinkage,
                               ConstantInt::get(Type::getInt8Ty(Ctx), 0),
                               "__native_state_proxy");

  ValueToValueMapTy VMap;
  for (unsigned I = 0; I < P.HiddenTokens.size(); ++I) {
    Value *Hidden = P.Old->getArg(I);
    if (P.HiddenTokens[I] == HiddenTokenKind::State) {
      VMap[Hidden] = P.Proxy;
      continue;
    }
    if (Hidden->getType()->isPointerTy())
      VMap[Hidden] =
          ConstantPointerNull::get(cast<PointerType>(Hidden->getType()));
    else if (Hidden->getType()->isIntegerTy())
      VMap[Hidden] = ConstantInt::get(Hidden->getType(), 0);
    else
      return Fail("unsupported hidden Memory/PC token type");
  }
  unsigned NewArg = (P.HasNativeStackArg ? 1 : 0) + P.Inputs.size();
  for (unsigned OldIndex : P.OldExplicitArgs)
    VMap[P.Old->getArg(OldIndex)] = P.New->getArg(NewArg++);

  SmallVector<ReturnInst *, 8> Returns;
  CloneFunctionBodyInto(*P.New, *P.Old, VMap, RF_None, Returns);
  if (P.New->empty())
    return Fail("cloned body is empty");

  BasicBlock &Entry = P.New->getEntryBlock();
  IRBuilder<> EB(&Entry, Entry.begin());
  for (const Slot &S : P.Used) {
    AllocaInst *A = EB.CreateAlloca(S.Ty, nullptr,
                                    ("native.slot." + Twine(S.Offset)).str());
    P.LocalSlots[S.Offset] = A;
  }
  NewArg = P.HasNativeStackArg ? 1 : 0;
  for (const Slot &S : P.Inputs) {
    Value *V = P.New->getArg(NewArg++);
    EB.CreateStore(V, P.LocalSlots[S.Offset]);
  }

  if (!RewriteExplicitRegisterArguments(P))
    return Fail("cannot rewrite explicit register arguments to State slots");

  SmallVector<Instruction *, 128> StateInstructions;
  SmallVector<MemSetInst *, 8> StateMemSets;
  SmallVector<std::pair<Instruction *, uint64_t>, 128> StatePointerValues;
  for (BasicBlock &BB : *P.New) {
    for (Instruction &I : BB) {
      // A pointer-typed load from State is the register value (for example
      // the pointer view of RSP), not an SSA address of the State slot.
      if (I.getType()->isPointerTy() && !isa<LoadInst>(&I)) {
        if (auto Offset = StateOffset(&I, P.Proxy, M.getDataLayout()))
          StatePointerValues.push_back({&I, *Offset});
      }
      Value *Ptr = nullptr;
      if (auto *MS = dyn_cast<MemSetInst>(&I)) {
        Ptr = MS->getDest();
      } else if (auto *LI = dyn_cast<LoadInst>(&I))
        Ptr = LI->getPointerOperand();
      else if (auto *SI = dyn_cast<StoreInst>(&I))
        Ptr = SI->getPointerOperand();
      if (!Ptr)
        continue;
      auto Offset = StateOffset(Ptr, P.Proxy, M.getDataLayout());
      if (!Offset) {
        SmallPtrSet<Value *, 8> Seen;
        Offset = GlobalStateOffset(Ptr, M.getDataLayout(), Seen);
      }
      if (Offset) {
        if (auto *MS = dyn_cast<MemSetInst>(&I))
          StateMemSets.push_back(MS);
        else
          StateInstructions.push_back(&I);
      }
    }
  }

  for (MemSetInst *MS : StateMemSets) {
    auto *Fill = dyn_cast<ConstantInt>(MS->getValue());
    auto *Length = dyn_cast<ConstantInt>(MS->getLength());
    auto Offset = StateOffset(MS->getDest(), P.Proxy, M.getDataLayout());
    if (!Offset) {
      SmallPtrSet<Value *, 8> Seen;
      Offset = GlobalStateOffset(MS->getDest(), M.getDataLayout(), Seen);
    }
    auto Canonical = Offset ? CanonicalStateSlotOffset(*Offset) : std::nullopt;
    Type *SlotTy = Canonical ? P.SlotTypes.lookup(*Canonical) : nullptr;
    uint64_t Bytes = Length ? Length->getZExtValue() : 0;
    // CollectPlanUses intentionally admits only this exact proof.  Refuse the
    // clone if the IR changed or an unsupported State memset reached us.
    if (MS->isVolatile() || !Fill || !Fill->isZero() || !Length || !Bytes ||
        !Offset || !Canonical || *Canonical != *Offset || !SlotTy ||
        Bytes > UINT64_MAX / 8 || ScalarBits(SlotTy) != Bytes * 8 ||
        !P.LocalSlots.count(*Canonical))
      return Fail("unsupported State memset");
    IRBuilder<> B(MS);
    B.CreateStore(Constant::getNullValue(SlotTy), P.LocalSlots[*Canonical]);
    MS->eraseFromParent();
  }

  for (Instruction *I : StateInstructions) {
    auto Offset = [&]() -> std::optional<uint64_t> {
      Value *Ptr = isa<LoadInst>(I)
                       ? cast<LoadInst>(I)->getPointerOperand()
                       : cast<StoreInst>(I)->getPointerOperand();
      auto Found = StateOffset(Ptr, P.Proxy, M.getDataLayout());
      if (Found)
        return Found;
      SmallPtrSet<Value *, 8> Seen;
      return GlobalStateOffset(Ptr, M.getDataLayout(), Seen);
    }();
    auto Canonical = Offset ? CanonicalStateSlotOffset(*Offset) : std::nullopt;
    if (!Canonical || !P.LocalSlots.count(*Canonical))
      return Fail("state access has no collected slot");
    IRBuilder<> AccessBuilder(I);
    Value *SlotPtr = LocalSlotPointer(AccessBuilder, P, *Offset);
    Value *BaseSlotPtr = LocalSlotPointer(AccessBuilder, P, *Canonical);
    if (!SlotPtr || !BaseSlotPtr)
      return Fail("state access has no native slot pointer");
    unsigned SubslotShift = static_cast<unsigned>((*Offset - *Canonical) * 8);
    if (auto *LI = dyn_cast<LoadInst>(I)) {
      Type *SlotTy = P.SlotTypes.lookup(*Canonical);
      if (LI->getType() == SlotTy && SubslotShift == 0) {
        LI->setOperand(0, BaseSlotPtr);
      } else {
        IRBuilder<> B(LI);
        Value *V = B.CreateLoad(SlotTy, BaseSlotPtr, "native.slot.load");
        if (SubslotShift)
          V = B.CreateLShr(V, B.getIntN(ScalarBits(SlotTy), SubslotShift),
                           "native.slot.subslot.load");
        V = Coerce(B, V, LI->getType(), "native.slot.coerce");
        if (!V)
          return Fail("cannot coerce state load at offset " +
                      Twine(*Offset) + " from " +
                      Twine(LI->getType()->getTypeID()) + " to " +
                      Twine(SlotTy->getTypeID()));
        LI->replaceAllUsesWith(V);
        LI->eraseFromParent();
      }
    } else {
      auto *SI = cast<StoreInst>(I);
      Type *SlotTy = P.SlotTypes.lookup(*Canonical);
      Value *V = SI->getValueOperand();
      unsigned SrcBits = ScalarBits(V->getType());
      unsigned SlotBits = ScalarBits(SlotTy);
      if (V->getType() != SlotTy && SlotTy->isIntegerTy() &&
          SrcBits && SlotBits && SrcBits < SlotBits &&
          IsBitPatternType(V->getType())) {
        // A narrow store updates only the low bytes of a wider overlapping
        // state slot.  Preserve the untouched high bytes instead of turning
        // it into a zero-extending whole-slot store.
        IRBuilder<> B(SI);
        Value *Low = ToIntegerBits(B, V, SrcBits, "native.slot.store");
        if (!Low)
          return Fail("cannot represent narrow state store at offset " +
                      Twine(*Offset));
        Value *Wide = B.CreateZExt(Low, SlotTy, "native.slot.store.wide");
        if (SubslotShift)
          Wide = B.CreateShl(Wide, B.getIntN(SlotBits, SubslotShift),
                             "native.slot.subslot.store");
        APInt LowMask(SlotBits, 0);
        LowMask.setLowBits(SrcBits);
        if (SubslotShift)
          LowMask <<= SubslotShift;
        Value *Old = B.CreateLoad(SlotTy, BaseSlotPtr, "native.slot.prior");
        Value *Keep = B.CreateAnd(
            Old, ConstantInt::get(SlotTy, ~LowMask), "native.slot.keep");
        V = B.CreateOr(Keep, Wide, "native.slot.merged");
        SI->setOperand(0, V);
      } else if (V->getType() != SlotTy) {
        IRBuilder<> B(SI);
        V = Coerce(B, V, SlotTy, "native.slot.store");
        if (!V)
          return Fail("cannot coerce state store at offset " +
                      Twine(*Offset) + " from " +
                      Twine(V->getType()->getTypeID()) + " to " +
                      Twine(SlotTy->getTypeID()));
        SI->setOperand(0, V);
      }
      SI->setOperand(1, BaseSlotPtr);
    }
  }

  // State slot addresses can flow through PHIs/selects before reaching a
  // load/store.  Replacing only the terminal memory instruction leaves the
  // proxy GEP alive through those pointer SSA values.  Once the slot address
  // is proven, use the local slot alloca as the native address for every such
  // pointer value and remove the now-dead proxy graph.
  for (auto [I, Offset] : StatePointerValues) {
    if (!I->getParent())
      continue;
    IRBuilder<> B(I);
    Value *Replacement = LocalSlotPointer(B, P, Offset);
    if (!Replacement || I == Replacement)
      continue;
    I->replaceAllUsesWith(Replacement);
    if (I->use_empty() && !I->isTerminator())
      I->eraseFromParent();
  }

  SmallVector<ReturnInst *, 16> NewReturns;
  for (BasicBlock &BB : *P.New)
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator()))
      NewReturns.push_back(RI);

  for (ReturnInst *RI : NewReturns) {
    IRBuilder<> B(RI);
    SmallVector<Value *, 32> Values;
    if (!P.OldReturnTy->isVoidTy())
      Values.push_back(RI->getReturnValue());
    for (const Slot &S : P.Outputs) {
      Value *Output = nullptr;
      if (S.Offset == 2328) {
        // RBP is callee-saved and is also the anchor used by the recovered
        // stack model.  A lifted epilogue can restore it with a load from
        // the caller's machine stack.  Native State-SSA calls do not have a
        // real machine call frame, so that load would read an uninitialized
        // byte range in the synthetic stack buffer.  The caller's RBP is
        // already an explicit SSA input; carry that proven value across the
        // call boundary instead of manufacturing a frame pointer.
        for (Argument &Arg : P.New->args()) {
          if (Arg.getName() == "state_in_2328") {
            Output = &Arg;
            break;
          }
        }
      }
      if (!Output)
        Output = B.CreateLoad(S.Ty, P.LocalSlots[S.Offset],
                              ("state_out." + Twine(S.Offset)).str());
      if (Output->getType() != S.Ty)
        Output = Coerce(B, Output, S.Ty,
                        "native.rbp.return.coerce");
      if (!Output)
        return Fail("cannot preserve native RBP output");
      Values.push_back(Output);
    }
    if (Values.empty()) {
      if (!RI->getFunction()->getReturnType()->isVoidTy())
        return Fail("void source return does not match cloned return type");
      B.CreateRetVoid();
      RI->eraseFromParent();
      continue;
    }
    Value *Ret = Values.front();
    if (P.ResultTy) {
      Ret = Constant::getNullValue(P.ResultTy);
      for (unsigned I = 0; I < Values.size(); ++I)
        Ret = B.CreateInsertValue(Ret, Values[I], {I}, "state.result");
    }
    B.CreateRet(Ret);
    RI->eraseFromParent();
  }
  return true;
}

static Value *LoadStateSlot(IRBuilder<> &B, Plan &Caller, uint64_t Offset,
                            Type *Ty) {
  auto It = Caller.LocalSlots.find(Offset);
  if (It == Caller.LocalSlots.end())
    return nullptr;
  Value *V = B.CreateLoad(Caller.SlotTypes.lookup(Offset), It->second,
                          "state.call.in");
  return Coerce(B, V, Ty, "state.call.coerce");
}

static Value *ExtractOriginalResult(IRBuilder<> &B, Plan &Callee,
                                    CallInst *Call) {
  if (Callee.OldReturnTy->isVoidTy())
    return nullptr;
  if (!Callee.ResultTy)
    return Call;
  return B.CreateExtractValue(Call, {0}, "native.call.ret");
}

// A caller can observe an XMM register as one 128-bit vector slot while a
// callee exposes its two scalar 64-bit lanes independently.  Do not coerce a
// scalar return to i128 in that case: zero-extending it overwrites the other
// live lane.  Merge the returned lane into the caller's wide slot instead.
static std::optional<uint64_t> WideXMMBaseSlot(const Plan &P,
                                               uint64_t Offset) {
  static constexpr uint64_t XMMBases[] = {
      16, 80, 144, 208, 272, 336, 400, 464};
  for (uint64_t Base : XMMBases) {
    if (Offset != Base && Offset != Base + 8)
      continue;
    auto It = P.LocalSlots.find(Base);
    if (It == P.LocalSlots.end())
      continue;
    if (ScalarBits(P.SlotTypes.lookup(Base)) == 128)
      return Base;
  }
  return std::nullopt;
}

static bool StoreCallStateOutput(IRBuilder<> &B, Plan &Caller,
                                 uint64_t Offset, Value *ValueToStore,
                                 const Twine &Name) {
  if (auto WideBase = WideXMMBaseSlot(Caller, Offset)) {
    Type *WideTy = Caller.SlotTypes.lookup(*WideBase);
    if (ScalarBits(ValueToStore->getType()) == 128) {
      Value *Whole = Coerce(B, ValueToStore, WideTy, Name + ".whole");
      if (!Whole)
        return false;
      B.CreateStore(Whole, Caller.LocalSlots[*WideBase]);
      return true;
    }
    Value *Lane = ToIntegerBits(B, ValueToStore, 64, Name + ".bits");
    if (!Lane)
      return false;
    Value *Old = B.CreateLoad(WideTy, Caller.LocalSlots[*WideBase],
                              Name + ".prior");
    Value *LaneWide = B.CreateZExt(Lane, WideTy, Name + ".wide");
    APInt LaneMask(128, 0);
    LaneMask.setLowBits(64);
    if (Offset == *WideBase + 8) {
      LaneWide = B.CreateShl(LaneWide, B.getIntN(128, 64),
                              Name + ".high");
      LaneMask <<= 64;
    }
    Value *Keep = B.CreateAnd(Old, ConstantInt::get(WideTy, ~LaneMask),
                              Name + ".keep");
    Value *Merged = B.CreateOr(Keep, LaneWide, Name + ".merged");
    B.CreateStore(Merged, Caller.LocalSlots[*WideBase]);
    return true;
  }

  auto It = Caller.LocalSlots.find(Offset);
  if (It == Caller.LocalSlots.end())
    return false;
  Value *Coerced = Coerce(B, ValueToStore, Caller.SlotTypes.lookup(Offset),
                          Name + ".coerce");
  if (!Coerced)
    return false;
  B.CreateStore(Coerced, It->second);
  return true;
}

static bool RewriteNativeCalls(Plan &Caller,
                               DenseMap<Function *, std::unique_ptr<Plan>> &Plans) {
  auto Fail = [&](CallInst *Call, const Twine &Reason) {
    errs() << "brighten-native-state-ssa: internal rewrite detail caller="
           << Caller.Old->getName() << " callee=";
    if (Call && Call->getCalledFunction())
      errs() << Call->getCalledFunction()->getName();
    else
      errs() << "<indirect>";
    errs() << " reason=" << Reason << "\n";
    return false;
  };
  SmallVector<CallInst *, 32> Calls;
  for (BasicBlock &BB : *Caller.New) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI)
        continue;
      if (Plan *Callee = FindPlan(Plans, CI->getCalledFunction()))
        Calls.push_back(CI);
    }
  }

  for (CallInst *OldCall : Calls) {
    Plan *Callee = FindPlan(Plans, OldCall->getCalledFunction());
    if (!Callee)
      continue;
    bool IsLiftedDispatcherArm =
        Callee->Old != OldCall->getCalledFunction();
    IRBuilder<> B(OldCall);
    SmallVector<Value *, 32> Args;
    if (Callee->HasNativeStackArg) {
      Value *CallerStack = nullptr;
      for (Argument &A : Caller.New->args())
        if (A.getName() == "native_stack") {
          CallerStack = &A;
          break;
        }
      if (!CallerStack)
        return Fail(OldCall, "callee requires native_stack but caller lacks it");
      Args.push_back(CallerStack);
    }
    for (const Slot &S : Callee->Inputs) {
      Value *V = LoadStateSlot(B, Caller, S.Offset, S.Ty);
      if (!V)
        return Fail(OldCall, "missing State input slot " + Twine(S.Offset));
      Args.push_back(V);
    }
    if (IsLiftedDispatcherArm) {
      for (unsigned ArgNo : Callee->OldExplicitArgs) {
        Argument *Arg = Callee->Old->getArg(ArgNo);
        auto Offset = ExplicitRegisterStateOffset(Arg->getName());
        if (!Offset)
          return Fail(OldCall, "dispatcher explicit arg is not a State register");
        Value *V = LoadStateSlot(B, Caller, *Offset, Arg->getType());
        if (!V)
          return Fail(OldCall, "missing dispatcher GPR slot " + Twine(*Offset));
        Args.push_back(V);
      }
    } else {
      unsigned ExplicitStart = Callee->HiddenArgs;
      if (OldCall->arg_size() < ExplicitStart)
        return Fail(OldCall, "call has fewer arguments than hidden State args");
      for (unsigned I = ExplicitStart; I < OldCall->arg_size(); ++I)
        Args.push_back(OldCall->getArgOperand(I));
    }

    CallInst *NewCall = B.CreateCall(
        Callee->New, Args,
        Callee->New->getReturnType()->isVoidTy() ? "" : "native.call");
    NewCall->setCallingConv(Callee->New->getCallingConv());
    Value *OriginalRet = ExtractOriginalResult(B, *Callee, NewCall);
    if (Callee->ReturnSlot && OriginalRet) {
      if (!StoreCallStateOutput(B, Caller, *Callee->ReturnSlot, OriginalRet,
                                "state.call.return"))
        return Fail(OldCall, "cannot materialize native return State slot");
    }
    unsigned Field = Callee->OldReturnTy->isVoidTy() ? 0 : 1;
    for (const Slot &S : Callee->Outputs) {
      Value *V = nullptr;
      if (Callee->ResultTy)
        V = B.CreateExtractValue(NewCall, {Field},
                                 ("state.call.out." + Twine(S.Offset)).str());
      else
        V = NewCall;
      ++Field;
      if (!StoreCallStateOutput(B, Caller, S.Offset, V,
                                "state.call.out"))
        return Fail(OldCall, "cannot coerce native output slot " + Twine(S.Offset));
    }
    if (!OldCall->getType()->isVoidTy()) {
      Value *ReplacementRet = OriginalRet;
      if (IsLiftedDispatcherArm && OldCall->arg_size() != 0 &&
          OldCall->getArgOperand(OldCall->arg_size() - 1)->getType() ==
              OldCall->getType())
        ReplacementRet = OldCall->getArgOperand(OldCall->arg_size() - 1);
      if (!ReplacementRet)
        return Fail(OldCall, "call result has no replacement value");
      OldCall->replaceAllUsesWith(ReplacementRet);
    }
    OldCall->eraseFromParent();
  }
  return true;
}

static bool RewriteExternalNativeCalls(
    Module &M, DenseMap<Function *, std::unique_ptr<Plan>> &Plans) {
  SmallVector<CallInst *, 32> Calls;
  for (Function &F : M) {
    if (Plans.count(&F))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (CI && Plans.count(CI->getCalledFunction()))
          Calls.push_back(CI);
      }
    }
  }

  auto FindNativeStack = [&](Function &Caller) -> Value * {
    for (Argument &A : Caller.args())
      if (A.getName() == "native_stack")
        return &A;
    if (Caller.empty())
      return nullptr;
    for (Instruction &I : Caller.getEntryBlock()) {
      if (auto *GEP = dyn_cast<GetElementPtrInst>(&I))
        if (GEP->getName().starts_with("native_stack_top"))
          return GEP;
    }
    // Entrypoint normalization can constant-fold the named top GEP into a
    // ptrtoint stored in the canonical State RSP/RBP slots.  Reuse that exact
    // pointer as the frame owner.  Creating another local backing here gives
    // the explicit frame_base and the absolute RSP bits different coordinate
    // systems after a post-O3 State-SSA retry.
    auto IsFrameBackingPointer =
        [&](Value *V, auto &&Self, SmallPtrSetImpl<Value *> &Seen) -> bool {
      if (!V || !Seen.insert(V).second)
        return false;
      Value *Stripped = V->stripPointerCasts();
      if (auto *GV = dyn_cast<GlobalValue>(Stripped))
        return GV->getName().starts_with("frame_storage_backing.");
      if (auto *GA = dyn_cast<GlobalAlias>(Stripped))
        return Self(GA->getAliasee(), Self, Seen);
      if (auto *GEP = dyn_cast<GEPOperator>(Stripped))
        return Self(GEP->getPointerOperand(), Self, Seen);
      return false;
    };
    for (Instruction &I : Caller.getEntryBlock()) {
      auto *SI = dyn_cast<StoreInst>(&I);
      if (!SI || !SI->isVolatile())
        continue;
      auto *PTI = SI ? dyn_cast<PtrToIntOperator>(SI->getValueOperand())
                     : nullptr;
      if (!PTI)
        continue;
      SmallPtrSet<Value *, 8> Seen;
      if (IsFrameBackingPointer(PTI->getPointerOperand(),
                                IsFrameBackingPointer, Seen))
        return PTI->getPointerOperand();
    }
    return nullptr;
  };

  // An entry wrapper has a State buffer but no incoming native_stack argument.
  // That buffer is zero-initialized, so treating its RSP slot as a fallback
  // stack pointer produces inttoptr(0) and the first recovered push writes to
  // address -8.  Give the wrapper an explicit bounded backing and seed RSP
  // from its top before crossing into recovered code.
  auto GetOrCreateEntryStack = [&](Function &Caller) -> Value * {
    if (Value *Stack = FindNativeStack(Caller))
      return Stack;
    if (Caller.empty())
      return nullptr;
    constexpr uint64_t NativeStackBytes = 2 * 1024 * 1024;
    constexpr uint64_t NativeStackGuard = 256;
    IRBuilder<> EntryB(&*Caller.getEntryBlock().getFirstInsertionPt());
    auto *StorageTy = ArrayType::get(EntryB.getInt8Ty(), NativeStackBytes);
    AllocaInst *Storage = EntryB.CreateAlloca(
        StorageTy, nullptr, "native_stack_storage");
    Storage->setAlignment(Align(16));
    return EntryB.CreateConstGEP1_64(
        EntryB.getInt8Ty(), Storage, NativeStackBytes - NativeStackGuard,
        "native_stack_top");
  };

  auto ResolveBoundaryState = [&](CallInst *Call) -> Value * {
    if (!Call)
      return nullptr;
    Plan *Callee = FindPlan(Plans, Call->getCalledFunction());
    if (Callee && Callee->HasHiddenStateArg) {
      for (unsigned I = 0; I < Callee->HiddenTokens.size(); ++I) {
        if (Callee->HiddenTokens[I] != HiddenTokenKind::State ||
            I >= Call->arg_size())
          continue;
        Value *State = Call->getArgOperand(I);
        if (State->getType()->isPointerTy() &&
            !isa<ConstantPointerNull>(State))
          return State;
      }
    }
    // ABI recovery can erase the redundant State parameter from an entry
    // wrapper before this interprocedural lowering runs, leaving `null` in
    // the old hidden argument position.  The module's canonical McSema State
    // global is still the authoritative boundary object.  Never form
    // GEP(null, state_offset): after O3 that becomes an absolute access such
    // as address 0x908 and crashes before main executes.
    for (GlobalVariable &GV : M.globals())
      if (GV.getName().contains("__mcsema_reg_state"))
        return &GV;
    return nullptr;
  };

  // Validate every boundary before mutating any caller.  Passing null as a
  // substitute for an unresolved stack anchor changes every recovered stack
  // address and was the source of silently wrong, strict-accepted programs.
  for (CallInst *OldCall : Calls) {
    Plan *Callee = FindPlan(Plans, OldCall->getCalledFunction());
    bool MissingStack = Callee && Callee->HasNativeStackArg &&
                        !FindNativeStack(*OldCall->getFunction()) &&
                        OldCall->getFunction()->empty();
    bool MissingState = !ResolveBoundaryState(OldCall);
    if (!Callee || OldCall->arg_size() < Callee->HiddenArgs || MissingStack ||
        MissingState) {
      errs() << "brighten-native-state-ssa: invalid external boundary caller="
             << OldCall->getFunction()->getName() << " callee="
             << OldCall->getCalledFunction()->getName() << " args="
             << OldCall->arg_size() << " hidden="
             << (Callee ? Callee->HiddenArgs : 0) << " missing-stack="
             << MissingStack << " missing-state=" << MissingState << "\n";
      return false;
    }
  }

  for (CallInst *OldCall : Calls) {
    Plan *Callee = FindPlan(Plans, OldCall->getCalledFunction());
    if (!Callee || OldCall->arg_size() < Callee->HiddenArgs) {
      errs() << "brighten-native-state-ssa: boundary plan disappeared caller="
             << OldCall->getFunction()->getName() << "\n";
      return false;
    }
    Value *State = ResolveBoundaryState(OldCall);
    if (!State) {
      errs() << "brighten-native-state-ssa: unresolved boundary State caller="
             << OldCall->getFunction()->getName() << "\n";
      return false;
    }
    IRBuilder<> B(OldCall);
    // McSema's memcpy thunk dispatches through the register state and its
    // lifted explicit destination argument is frequently undef.  Once the
    // state SSA form is available, call libc directly with the three live
    // SysV arguments instead of preserving that undef carrier.
    if (OldCall->getCalledFunction()->getName() == "ext_405058_memcpy") {
      Function *Memcpy = M.getFunction("memcpy");
      if (!Memcpy) {
        errs() << "brighten-native-state-ssa: memcpy declaration missing\n";
        return false;
      }
      Value *Dst = B.CreateLoad(B.getInt64Ty(), BuildStateGEP(B, State, 2296),
                                "memcpy.dst");
      Value *Src = B.CreateLoad(B.getInt64Ty(), BuildStateGEP(B, State, 2280),
                                "memcpy.src");
      Value *Len = B.CreateLoad(B.getInt64Ty(), BuildStateGEP(B, State, 2264),
                                "memcpy.len");
      CallInst *Direct = B.CreateCall(Memcpy, {Dst, Src, Len}, "memcpy.direct");
      Direct->setCallingConv(Memcpy->getCallingConv());
      Value *Ret = B.CreateIntToPtr(Direct, B.getPtrTy(), "memcpy.ret");
      if (!OldCall->getType()->isVoidTy())
        OldCall->replaceAllUsesWith(Ret);
      OldCall->eraseFromParent();
      continue;
    }
    SmallVector<Value *, 32> Args;
    Function *Caller = OldCall->getFunction();
    if (Callee->HasNativeStackArg) {
      Value *NativeStack = FindNativeStack(*Caller);
      if (!NativeStack) {
        NativeStack = GetOrCreateEntryStack(*Caller);
        if (!NativeStack) {
          errs() << "brighten-native-state-ssa: unable to create entry stack "
                 << "caller=" << Caller->getName() << "\n";
          return false;
        }
        Value *RSPPtr = BuildStateGEP(B, State, 2312);
        Value *RSP = B.CreatePtrToInt(NativeStack, B.getInt64Ty(),
                                      "native.boundary.rsp");
        B.CreateStore(RSP, RSPPtr);
      }
      Args.push_back(NativeStack);
    }
    for (const Slot &S : Callee->Inputs) {
      Value *Ptr = BuildStateGEP(B, State, S.Offset);
      Value *V = B.CreateLoad(S.Ty, Ptr, "entry.state.in");
      Args.push_back(V);
    }
    for (unsigned I = Callee->HiddenArgs; I < OldCall->arg_size(); ++I)
      Args.push_back(OldCall->getArgOperand(I));
    CallInst *NewCall = B.CreateCall(
        Callee->New, Args,
        Callee->New->getReturnType()->isVoidTy() ? "" :
                                                   "native.entry.call");
    NewCall->setCallingConv(Callee->New->getCallingConv());
    Value *OriginalRet = ExtractOriginalResult(B, *Callee, NewCall);
    if (Callee->ReturnSlot && OriginalRet) {
      Type *SlotTy = Callee->SlotTypes.lookup(*Callee->ReturnSlot);
      Value *Returned = Coerce(B, OriginalRet, SlotTy,
                               "entry.state.return.coerce");
      if (!Returned) {
        errs() << "brighten-native-state-ssa: boundary return coercion failed "
               << "caller=" << Caller->getName() << " callee="
               << OldCall->getCalledFunction()->getName() << " from="
               << *OriginalRet->getType() << " to=" << *SlotTy << "\n";
        return false;
      }
      B.CreateStore(Returned,
                    BuildStateGEP(B, State, *Callee->ReturnSlot));
    }
    unsigned Field = Callee->OldReturnTy->isVoidTy() ? 0 : 1;
    for (const Slot &S : Callee->Outputs) {
      Value *V = Callee->ResultTy
                     ? B.CreateExtractValue(NewCall, {Field++}, "entry.state.out")
                     : NewCall;
      B.CreateStore(V, BuildStateGEP(B, State, S.Offset));
    }
    if (!OldCall->getType()->isVoidTy())
      OldCall->replaceAllUsesWith(OriginalRet);
    OldCall->eraseFromParent();
  }
  return true;
}

static void PromoteNativeSlotAllocas(Plan &P) {
  SmallVector<AllocaInst *, 32> Allocas;
  for (auto &Entry : P.LocalSlots)
    if (Entry.second->getParent())
      Allocas.push_back(Entry.second);
  if (Allocas.empty())
    return;
  DominatorTree DT(*P.New);
  PromoteMemToReg(Allocas, DT, nullptr);
}

static bool CleanupProxy(Plan &P) {
  for (unsigned Iter = 0; Iter < 8; ++Iter) {
    SmallVector<Instruction *, 32> Dead;
    for (BasicBlock &BB : *P.New) {
      for (Instruction &I : BB) {
        bool UsesProxy = false;
        for (Value *Op : I.operands())
          UsesProxy |= Op == P.Proxy;
        if (UsesProxy) {
          if (I.isTerminator() || !I.use_empty())
            return false;
          Dead.push_back(&I);
        }
      }
    }
    if (Dead.empty()) {
      // Cloning can leave the proxy in constant expressions used by dead
      // instructions.  Drop those constant users before the final check.
      P.Proxy->removeDeadConstantUsers();
      return P.Proxy->use_empty();
    }
    for (Instruction *I : Dead)
      I->eraseFromParent();
  }
  return P.Proxy->use_empty();
}

static bool CanRemoveOldFunctions(
    Module &M, DenseMap<Function *, std::unique_ptr<Plan>> &Plans) {
  for (auto &Entry : Plans) {
    Function *Old = Entry.first;
    for (User *U : Old->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || !Plans.count(I->getFunction()))
        return false;
    }
  }
  return true;
}

static AllocaInst *FindMainStateBuffer(Function &Main) {
  for (Instruction &I : Main.getEntryBlock()) {
    auto *AI = dyn_cast<AllocaInst>(&I);
    if (!AI || !AI->getName().starts_with("native_state"))
      continue;
    auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
    if (AT && AT->getElementType()->isIntegerTy(8))
      return AI;
  }
  return nullptr;
}

static bool lowerNativeMainStateBufferImpl(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  for (StringRef FunctionName : {StringRef("main"),
                                 StringRef("native_entry_impl")}) {
    Function *Main = M.getFunction(FunctionName);
    if (!Main || Main->empty())
      continue;
    AllocaInst *State = FindMainStateBuffer(*Main);
    if (!State)
      continue;

    // If the raw State buffer still crosses a call boundary, State-SSA did
    // not rewrite that entry call. Do not erase its memset or register-slot
    // stores: doing so leaves the callee with an uninitialized State object,
    // which O3 may turn into undef-pointer UB after inlining.
    CallBase *StateCall = nullptr;
    SmallVector<Value *, 16> StatePointers{State};
    SmallPtrSet<Value *, 16> SeenStatePointers;
    while (!StatePointers.empty() && !StateCall) {
      Value *Pointer = StatePointers.pop_back_val();
      if (!SeenStatePointers.insert(Pointer).second)
        continue;
      for (User *U : Pointer->users()) {
        if (auto *CB = dyn_cast<CallBase>(U)) {
          if (isa<IntrinsicInst>(CB))
            continue;
          for (Value *Arg : CB->args()) {
            if (Arg == Pointer) {
              StateCall = CB;
              break;
            }
          }
          if (StateCall)
            break;
          continue;
        }
        if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
          StatePointers.push_back(GEP);
          continue;
        }
        if (isa<BitCastInst>(U) || isa<AddrSpaceCastInst>(U))
          StatePointers.push_back(cast<Value>(U));
      }
    }
    bool StateEscapesThroughCall = StateCall != nullptr;
    if (StateEscapesThroughCall) {
      // A raw native entry call still consumes the byte-addressed State ABI.
      // State-SSA cannot remove this buffer while it crosses the call, but a
      // zero-initialized RSP/RBP makes the callee's first push target address
      // -8. Seed the shared native frame backing at this boundary exactly as
      // the explicit State-SSA entry path does.
      bool HasRSP = false;
      bool HasRBP = false;
      for (Instruction &I : *StateCall->getParent()) {
        if (&I == StateCall)
          break;
        auto *SI = dyn_cast<StoreInst>(&I);
        if (!SI)
          continue;
        auto Offset = StateOffset(SI->getPointerOperand(), State, DL);
        bool IsZeroInitialization =
            isa<Constant>(SI->getValueOperand()) &&
            cast<Constant>(SI->getValueOperand())->isNullValue();
        HasRSP |= Offset && *Offset == 2312 && !IsZeroInitialization;
        HasRBP |= Offset && *Offset == 2328 && !IsZeroInitialization;
      }
      if (!HasRSP || !HasRBP) {
        constexpr uint64_t NativeStackBytes = 2 * 1024 * 1024;
        constexpr uint64_t NativeStackTop = NativeStackBytes - 256;
        IRBuilder<> B(StateCall);
        auto *StorageTy = ArrayType::get(B.getInt8Ty(), NativeStackBytes);
        AllocaInst *Storage = nullptr;
        for (Instruction &I : StateCall->getFunction()->getEntryBlock()) {
          auto *AI = dyn_cast<AllocaInst>(&I);
          if (AI && AI->getName().starts_with("native_stack_storage")) {
            Storage = AI;
            break;
          }
        }
        if (!Storage) {
          IRBuilder<> EntryB(
              &*StateCall->getFunction()->getEntryBlock().getFirstInsertionPt());
          Storage = EntryB.CreateAlloca(StorageTy, nullptr,
                                         "native_stack_storage");
          Storage->setAlignment(Align(16));
        }
        Value *Top = B.CreateConstGEP1_64(B.getInt8Ty(), Storage,
                                           NativeStackTop,
                                           "native_stack_top");
        Value *TopInt = B.CreatePtrToInt(Top, B.getInt64Ty(),
                                         "native.boundary.rsp");
        if (!HasRSP) {
          Value *Slot = B.CreateGEP(B.getInt8Ty(), State, B.getInt64(2312));
          B.CreateStore(TopInt, Slot);
        }
        if (!HasRBP) {
          Value *Slot = B.CreateGEP(B.getInt8Ty(), State, B.getInt64(2328));
          B.CreateStore(TopInt, Slot);
        }
        Changed = true;
      }
      continue;
    }

    DenseMap<uint64_t, Value *> Current;
    SmallVector<Instruction *, 64> Erase;
    bool ZeroInitialized = false;

  // The generated entrypoint is intentionally straight-line.  Promote only
  // when every state load has a dominating byte-range value; this keeps the
  // transformation conservative for a future CFG-shaped wrapper.
  for (BasicBlock &BB : *Main) {
    for (Instruction &I : BB) {
      if (auto *MS = dyn_cast<MemSetInst>(&I)) {
        Value *Dest = MS->getDest()->stripPointerCasts();
        auto *Fill = dyn_cast<ConstantInt>(MS->getValue());
        if (Dest == State && Fill && Fill->isZero()) {
          ZeroInitialized = true;
          Erase.push_back(&I);
        }
        continue;
      }

      if (auto *SI = dyn_cast<StoreInst>(&I)) {
        auto Offset = StateOffset(SI->getPointerOperand(), State, DL);
        if (!Offset)
          continue;
        Current[*Offset] = SI->getValueOperand();
        Erase.push_back(SI);
        continue;
      }

      auto *LI = dyn_cast<LoadInst>(&I);
      if (!LI)
        continue;
      auto Offset = StateOffset(LI->getPointerOperand(), State, DL);
      if (!Offset)
        continue;
      Value *V = Current.lookup(*Offset);
      if (!V && ZeroInitialized)
        V = Constant::getNullValue(LI->getType());
      if (!V || V->getType() != LI->getType())
        return Changed;
      LI->replaceAllUsesWith(V);
      Erase.push_back(LI);
    }
  }

    if (Erase.empty() || !ZeroInitialized) {
      continue;
    }
    for (Instruction *I : llvm::reverse(Erase))
      if (I->getParent())
        I->eraseFromParent();

    for (unsigned Iter = 0; Iter < 8 && !State->use_empty(); ++Iter) {
      SmallVector<Instruction *, 64> Dead;
      for (BasicBlock &BB : *Main)
        for (Instruction &I : BB)
          if (I.use_empty() && isa<GetElementPtrInst>(&I) &&
              StateOffset(&I, State, DL))
            Dead.push_back(&I);
      if (Dead.empty())
        break;
      for (Instruction *I : Dead)
        I->eraseFromParent();
    }

    if (!State->use_empty()) {
      continue;
    }
    State->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

static bool lowerNativeMainStackBufferImpl(Module &M) {
  bool Changed = false;
  for (StringRef FunctionName : {StringRef("main"),
                                 StringRef("native_entry_impl")}) {
    Function *Main = M.getFunction(FunctionName);
    if (!Main || Main->empty())
      continue;

    AllocaInst *OldStack = nullptr;
    for (Instruction &I : Main->getEntryBlock()) {
      auto *AI = dyn_cast<AllocaInst>(&I);
      if (!AI || !AI->getName().starts_with("native_stack"))
        continue;
      auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
      if (AT && AT->getElementType()->isIntegerTy(8) &&
          AT->getNumElements() >= 1024 * 1024) {
        OldStack = AI;
        break;
      }
    }
    if (!OldStack)
      continue;

  // The recovered code only uses the old allocation as a temporary frame
  // backing store.  Keep that backing separate from the host call stack: a
  // guest RSP underflow must not be able to overwrite the return address of
  // native_entry_impl.  The guest RSP/RBP values remain ordinary integer data
  // until the address lowering pass turns accesses into native GEPs.
  // Newer recovered binaries can use large but still finite stack frames
  // (for example, a vararg scratch area around -120 KiB from RBP).  Keep the
  // stack bounded and native while leaving enough room for those proven
  // frame offsets.
  // Some lifted binaries address locals more than 512 KiB below the
  // recovered stack top. Keep this compatibility backing off the host stack:
  // a guest underflow must not overwrite native return addresses.
  constexpr uint64_t NativeStackBytes = 16 * 1024 * 1024;
  constexpr uint64_t NativeStackGuard = 64 * 1024;
  constexpr uint64_t NativeStackTop = NativeStackBytes - NativeStackGuard;
  IRBuilder<> B(OldStack);
  auto *StorageTy = ArrayType::get(B.getInt8Ty(), NativeStackBytes);
  std::string StorageName = "frame_storage_backing.";
  StorageName += FunctionName.str();
  GlobalVariable *Storage = M.getNamedGlobal(StorageName);
  if (!Storage) {
    Storage = new GlobalVariable(
        M, StorageTy, false, GlobalValue::InternalLinkage,
        ConstantAggregateZero::get(StorageTy), StorageName);
    Storage->setAlignment(Align(16));
  }
  SmallVector<Value *, 2> StorageIndices = {B.getInt32(0), B.getInt32(0)};
  // Do not let IRBuilder fold this to a ConstantExpr: later stack-address
  // recovery needs a named, entry-dominating SSA anchor for this backing.
  Value *NewStack = GetElementPtrInst::CreateInBounds(
      StorageTy, Storage, StorageIndices, "native_stack_storage",
      OldStack->getIterator());

  SmallVector<Instruction *, 4> StackUsers;
  for (User *U : OldStack->users()) {
    auto *GEP = dyn_cast<GetElementPtrInst>(U);
    if (!GEP)
      return false;
    StackUsers.push_back(GEP);
  }
  for (Instruction *I : StackUsers) {
    auto *GEP = cast<GetElementPtrInst>(I);
    IRBuilder<> GB(GEP);
    Value *Top = GB.CreateConstGEP1_64(B.getInt8Ty(), NewStack,
                                       NativeStackTop, "native_stack_top");
    GEP->replaceAllUsesWith(Top);
    GEP->eraseFromParent();
  }

  // Some lifted address expressions are materialized after the direct stack
  // users above and still use the allocation base with a signed negative
  // offset.  The guest RSP is represented by native_stack_top, so rebase
  // those expressions on the top anchor before they escape to libc/scanf.
  SmallVector<GetElementPtrInst *, 32> NegativeFrameGEPs;
  for (User *U : NewStack->users()) {
    auto *GEP = dyn_cast<GetElementPtrInst>(U);
    if (!GEP || GEP->getNumIndices() == 0)
      continue;
    auto It = GEP->idx_end();
    --It;
    auto *CI = dyn_cast<ConstantInt>(*It);
    if (CI && CI->getValue().isNegative())
      NegativeFrameGEPs.push_back(GEP);
  }
  for (GetElementPtrInst *GEP : NegativeFrameGEPs) {
    auto It = GEP->idx_end();
    --It;
    int64_t Offset = cast<ConstantInt>(*It)->getSExtValue();
    IRBuilder<> GB(GEP);
    Value *Top = GB.CreateConstGEP1_64(B.getInt8Ty(), NewStack,
                                       NativeStackTop, "native_stack_top");
    Value *Rebased = GB.CreateGEP(B.getInt8Ty(), Top,
                                  GB.getInt64(Offset), "native_stack_rebased");
    GEP->replaceAllUsesWith(Rebased);
    GEP->eraseFromParent();
    Changed = true;
  }
  if (!OldStack->use_empty())
    continue;
  OldStack->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

struct StackAffine {
  Value *Root = nullptr;
  int64_t Offset = 0;
  Value *Dynamic = nullptr;
  bool NegateDynamic = false;
};

static std::optional<StackAffine>
GetStackAffine(Value *V, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return std::nullopt;
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || (BO->getOpcode() != Instruction::Add &&
              BO->getOpcode() != Instruction::Sub)) {
    StringRef Name = V->getName();
    if (Name.contains("2312") || Name.contains("2328") ||
        Name.contains("new_rsp") || Name.contains("new_rbp"))
      return StackAffine{V, 0};
    return std::nullopt;
  }
  Value *Base = nullptr;
  int64_t Delta = 0;
  if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1))) {
    if (!C->getValue().isSignedIntN(64))
      return std::nullopt;
    Base = BO->getOperand(0);
    Delta = C->getSExtValue();
    if (BO->getOpcode() == Instruction::Sub)
      Delta = -Delta;
  } else if (BO->getOpcode() == Instruction::Add) {
    auto *C = dyn_cast<ConstantInt>(BO->getOperand(0));
    if (C && C->getValue().isSignedIntN(64)) {
      Base = BO->getOperand(1);
      Delta = C->getSExtValue();
    } else {
      // A lifted array/struct access commonly computes
      //   stack_register + dynamic_index + constant.
      // Preserve the dynamic integer term and lower the complete expression
      // relative to the explicit native stack anchor below.
      auto Left = GetStackAffine(BO->getOperand(0), Seen);
      auto Right = GetStackAffine(BO->getOperand(1), Seen);
      if (Left && !Right && BO->getOperand(1)->getType()->isIntegerTy() &&
          !Left->Dynamic) {
        Left->Dynamic = BO->getOperand(1);
        return Left;
      }
      if (Right && !Left && BO->getOperand(0)->getType()->isIntegerTy() &&
          !Right->Dynamic) {
        Right->Dynamic = BO->getOperand(0);
        return Right;
      }
      return std::nullopt;
    }
  } else {
    auto Parent = GetStackAffine(BO->getOperand(0), Seen);
    if (!Parent || Parent->Dynamic ||
        !BO->getOperand(1)->getType()->isIntegerTy())
      return std::nullopt;
    Parent->Dynamic = BO->getOperand(1);
    Parent->NegateDynamic = true;
    return Parent;
  }
  auto Parent = GetStackAffine(Base, Seen);
  if (!Parent)
    return std::nullopt;
  if ((Delta > 0 && Parent->Offset > INT64_MAX - Delta) ||
      (Delta < 0 && Parent->Offset < INT64_MIN - Delta))
    return std::nullopt;
  Parent->Offset += Delta;
  return Parent;
}

// Some lifted address expressions are affine in the stack register but carry
// more than one runtime term, for example `rsp - 13 + index * 3 + length`.
// The compact StackAffine form intentionally handles the common one-term
// case; this fallback recognizes the stack root through the full expression
// and rebases the original integer expression directly against native_stack.
static Value *FindKnownStackRoot(Value *V,
                                 SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return nullptr;
  StringRef Name = V->getName();
  if (Name.contains("2312") || Name.contains("2328") ||
      Name.contains("new_rsp") || Name.contains("new_rbp"))
    return V;

  auto *I = dyn_cast<Instruction>(V);
  if (!I)
    return nullptr;
  for (Value *Op : I->operands()) {
    if (!Op->getType()->isIntegerTy())
      continue;
    if (Value *Root = FindKnownStackRoot(Op, Seen))
      return Root;
  }
  return nullptr;
}

static bool lowerNativeStackAddressesImpl(Module &M) {
  unsigned Lowered = 0;
  constexpr int64_t NativeStackBytes = 16 * 1024 * 1024;
  constexpr int64_t NativeStackGuard = 64 * 1024;
  constexpr int64_t NativeStackTop = NativeStackBytes - NativeStackGuard;
  for (Function &F : M) {
    DenseMap<Value *, Value *> BasePointers;
    Value *NativeStack = nullptr;
    Value *IncomingRSP = nullptr;
    for (Argument &A : F.args()) {
      if (A.getName() == "native_stack" || A.getName() == "frame_base") {
        NativeStack = &A;
      } else if (A.getName() == "state_in_2312") {
        IncomingRSP = &A;
      }
    }
    // Entry wrappers own the recovered stack locally rather than receiving a
    // native_stack argument.  Treat their explicit top/storage pointer as the
    // same native anchor; otherwise an absolute RSP is lowered as
    // `frame_top + ptrtoint(frame_top)`, which is an invalid host address.
    if (!NativeStack && !F.empty()) {
      for (Instruction &I : F.getEntryBlock()) {
        if (!I.getType()->isPointerTy())
          continue;
        StringRef Name = I.getName();
        if (Name.starts_with("native_stack_top") ||
            Name.starts_with("native_stack_storage")) {
          NativeStack = &I;
          break;
        }
      }
    }
    // A global backing can be constant-folded into a ConstantExpr, leaving no
    // entry instruction to discover above.  Prefer the backing named for this
    // entry wrapper before considering a module-wide unique fallback.
    if (!NativeStack) {
      std::string BackingName = "frame_storage_backing.";
      BackingName += F.getName().str();
      NativeStack = M.getNamedGlobal(BackingName);
    }
    if (!NativeStack) {
      GlobalVariable *OnlyBacking = nullptr;
      for (GlobalVariable &GV : M.globals()) {
        if (!GV.getName().starts_with("frame_storage_backing."))
          continue;
        if (OnlyBacking) {
          OnlyBacking = nullptr;
          break;
        }
        OnlyBacking = &GV;
      }
      NativeStack = OnlyBacking;
    }

    // A nested recovered function enters below the module entry stack top.
    // Earlier cleanup can leave constant GEPs that were formed as if every
    // function entered at that top, e.g. `backing + (top - 216)`.  Rebase
    // those fixed local slots on the function's incoming RSP.  Otherwise a
    // callee stores its dispatcher at top-216 but immediately loads it from
    // incoming_rsp-216, which is a different address after the caller frame
    // and CALL push have changed RSP.
    if (NativeStack && IncomingRSP) {
      const DataLayout &DL = M.getDataLayout();
      // Fixed backing slots emitted by the earlier native cleanup are
      // expressed relative to the function's allocated-frame RSP, not its
      // entry RSP.  Recover that prologue value before rebasing constants.
      // For a conventional `push rbp; sub rsp, N` frame this is the most
      // negative constant adjustment derived directly from state_in_2312.
      // Rebasing `top + 16` on entry RSP would write 72 bytes too high for a
      // 72-byte frame; rebasing it on `entry_rsp - 72` restores the original
      // `[rbp - 0x30]` address.
      int64_t DeepestAdjustment = 0;
      for (Instruction &I : F.getEntryBlock()) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO)
          continue;
        Value *Other = nullptr;
        int64_t Adjustment = 0;
        if (BO->getOpcode() == Instruction::Add) {
          if (BO->getOperand(0) == IncomingRSP)
            Other = BO->getOperand(1);
          else if (BO->getOperand(1) == IncomingRSP)
            Other = BO->getOperand(0);
          auto *K = dyn_cast_or_null<ConstantInt>(Other);
          if (!K || !K->getValue().isSignedIntN(64))
            continue;
          Adjustment = K->getSExtValue();
        } else if (BO->getOpcode() == Instruction::Sub &&
                   BO->getOperand(0) == IncomingRSP) {
          auto *K = dyn_cast<ConstantInt>(BO->getOperand(1));
          if (!K || !K->getValue().isSignedIntN(64))
            continue;
          int64_t Magnitude = K->getSExtValue();
          if (Magnitude == INT64_MIN)
            continue;
          Adjustment = -Magnitude;
        } else {
          continue;
        }
        if (Adjustment < DeepestAdjustment) {
          DeepestAdjustment = Adjustment;
        }
      }
      auto GetFixedSlotRSP = [&](Instruction *Before) -> Value * {
        if (DeepestAdjustment == 0)
          return IncomingRSP;
        IRBuilder<> B(Before);
        return B.CreateAdd(IncomingRSP, B.getInt64(DeepestAdjustment),
                           "native.stack.frame.rsp");
      };
      auto GetBackingOffset = [&](Value *V)
          -> std::optional<int64_t> {
        APInt Total(64, 0, true);
        Value *Cursor = V;
        bool SawGEP = false;
        while (auto *GEP = dyn_cast<GEPOperator>(Cursor)) {
          APInt Offset(64, 0, true);
          if (!GEP->accumulateConstantOffset(DL, Offset))
            return std::nullopt;
          Total += Offset;
          Cursor = GEP->getPointerOperand()->stripPointerCasts();
          SawGEP = true;
        }
        auto *Backing = dyn_cast<GlobalVariable>(Cursor);
        if (!SawGEP || !Backing ||
            !Backing->getName().starts_with("frame_storage_backing.") ||
            !Total.isSignedIntN(64))
          return std::nullopt;
        int64_t Offset = Total.getSExtValue();
        if (Offset < 0 || Offset >= NativeStackBytes)
          return std::nullopt;
        return Offset;
      };
      auto BuildNestedAddress = [&](Instruction *Before, Value *StackInteger,
                                    int64_t BackingOffset) -> Value * {
        IRBuilder<> B(Before);
        Value *Anchor = B.CreatePtrToInt(NativeStack, B.getInt64Ty(),
                                         "native.stack.anchor");
        Value *Depth = B.CreateSub(StackInteger, Anchor,
                                   "native.stack.incoming.depth");
        Value *Offset = B.CreateAdd(
            Depth, B.getInt64(BackingOffset - NativeStackTop),
            "native.stack.local.offset");
        return B.CreateGEP(B.getInt8Ty(), NativeStack, Offset,
                           "native.stack.local");
      };
      auto GetRebasedLocalOffset = [&](Value *V)
          -> std::optional<int64_t> {
        auto *GEP = dyn_cast<GEPOperator>(V);
        if (!GEP || GEP->getNumIndices() != 1)
          return std::nullopt;
        auto *Add = dyn_cast<BinaryOperator>(*GEP->idx_begin());
        if (!Add || Add->getOpcode() != Instruction::Add)
          return std::nullopt;
        ConstantInt *K = dyn_cast<ConstantInt>(Add->getOperand(1));
        Value *Depth = Add->getOperand(0);
        if (!K) {
          K = dyn_cast<ConstantInt>(Add->getOperand(0));
          Depth = Add->getOperand(1);
        }
        auto *Sub = dyn_cast<BinaryOperator>(Depth);
        if (!K || !Sub || Sub->getOpcode() != Instruction::Sub)
          return std::nullopt;
        auto *PTI = dyn_cast<PtrToIntOperator>(Sub->getOperand(1));
        if (!PTI || PTI->getPointerOperand() != GEP->getPointerOperand() ||
            !K->getValue().isSignedIntN(64))
          return std::nullopt;
        return K->getSExtValue();
      };

      auto IsReadOnlyAddress = [&](Value *V, auto &&Self,
                                   SmallPtrSetImpl<Value *> &Seen) -> bool {
        if (!V || !Seen.insert(V).second || V->use_empty())
          return false;
        for (User *U : V->users()) {
          if (auto *LI = dyn_cast<LoadInst>(U)) {
            if (LI->getPointerOperand() != V)
              return false;
            continue;
          }
          if (isa<GetElementPtrInst, BitCastInst, AddrSpaceCastInst>(U)) {
            if (!Self(cast<Value>(U), Self, Seen))
              return false;
            continue;
          }
          return false;
        }
        return true;
      };

      // A translated access can already encode a later stack value as
      //   gep (backing + top + K), (current_rsp - reference_rsp).
      // For nested functions the fixed base must represent reference_rsp,
      // not the module entry top.  Algebraically this is current_rsp + K.
      SmallVector<GetElementPtrInst *, 32> DeltaGEPs;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          auto *GEP = dyn_cast<GetElementPtrInst>(&I);
          if (!GEP || GEP->getNumIndices() != 1)
            continue;
          auto BackingOffset = GetBackingOffset(GEP->getPointerOperand());
          auto LocalOffset = GetRebasedLocalOffset(GEP->getPointerOperand());
          if (!BackingOffset && !LocalOffset)
            continue;
          Value *Index = *GEP->idx_begin();
          auto *Delta = dyn_cast<BinaryOperator>(Index);
          if (!Delta || Delta->getOpcode() != Instruction::Sub)
            continue;
          DeltaGEPs.push_back(GEP);
        }
      }
      for (GetElementPtrInst *GEP : DeltaGEPs) {
        auto BackingOffset = GetBackingOffset(GEP->getPointerOperand());
        auto LocalOffset = GetRebasedLocalOffset(GEP->getPointerOperand());
        auto *Delta = dyn_cast<BinaryOperator>(*GEP->idx_begin());
        if ((!BackingOffset && !LocalOffset) || !Delta || !GEP->getParent())
          continue;
        int64_t Offset = LocalOffset ? *LocalOffset
                                     : *BackingOffset - NativeStackTop;
        Value *Address = BuildNestedAddress(
            GEP, Delta->getOperand(0), NativeStackTop + Offset);
        GEP->replaceAllUsesWith(Address);
        GEP->eraseFromParent();
        ++Lowered;
      }

      SmallVector<GetElementPtrInst *, 64> FixedGEPs;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (auto *GEP = dyn_cast<GetElementPtrInst>(&I))
            if (GetBackingOffset(GEP))
              FixedGEPs.push_back(GEP);

      // Register/home slots are commonly written through one folded GEP and
      // read later through a separately folded GEP at the same backing
      // offset.  Value-use inspection alone would call that later load an
      // incoming stack argument.  Record written offsets function-wide so
      // the coordinate decision follows the memory location, not whichever
      // SSA spelling happens to reach this particular access.
      std::set<int64_t> WrittenFixedOffsets;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          auto *SI = dyn_cast<StoreInst>(&I);
          if (!SI)
            continue;
          if (auto Offset = GetBackingOffset(SI->getPointerOperand()))
            WrittenFixedOffsets.insert(*Offset);
        }
      }

      for (GetElementPtrInst *GEP : FixedGEPs) {
        auto Offset = GetBackingOffset(GEP);
        if (!Offset || !GEP->getParent())
          continue;
        // A positive offset above the entry stack top is the SysV incoming
        // stack-argument area when it is only read by the recovered callee.
        // It must stay relative to entry RSP.  Treating every top+K address as
        // a post-prologue local moved p00187's seventh/eighth integer args by
        // the full 568-byte frame allocation.  A written fixed slot retains
        // the existing allocated-frame interpretation used by recovered
        // callee locals.
        SmallPtrSet<Value *, 16> ReadSeen;
        bool IsIncomingStackArgument =
            *Offset > NativeStackTop &&
            !WrittenFixedOffsets.count(*Offset) &&
            IsReadOnlyAddress(GEP, IsReadOnlyAddress, ReadSeen);
        Value *SlotRSP = *Offset >= NativeStackTop &&
                                 !IsIncomingStackArgument
                             ? GetFixedSlotRSP(GEP)
                             : IncomingRSP;
        Value *Address = BuildNestedAddress(GEP, SlotRSP, *Offset);
        GEP->replaceAllUsesWith(Address);
        GEP->eraseFromParent();
        ++Lowered;
      }

      // O3 commonly folds a fixed GEP into a ConstantExpr operand, so the
      // post-O3 cleanup retry must repair those operands as well.
      SmallVector<std::tuple<Instruction *, unsigned, int64_t>, 64>
          FixedConstantOperands;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo) {
            Value *Op = I.getOperand(OpNo);
            if (!Op->getType()->isPointerTy() || isa<Instruction>(Op))
              continue;
            // Pointer-producing/address-carrier instructions are only pieces
            // of a larger address expression.  Rebasing their constant
            // operand in isolation changes the algebra seen by their users.
            // Direct memory/call operands are terminal addresses and remain
            // eligible for this post-O3 fixed-operand retry.
            if (isa<GetElementPtrInst, PtrToIntInst, BitCastInst,
                    AddrSpaceCastInst>(&I))
              continue;
            if (auto Offset = GetBackingOffset(Op))
              FixedConstantOperands.emplace_back(&I, OpNo, *Offset);
          }
        }
      }
      for (auto [I, OpNo, Offset] : FixedConstantOperands) {
        if (!I->getParent())
          continue;
        bool IsIncomingStackArgument =
            Offset > NativeStackTop && !WrittenFixedOffsets.count(Offset) &&
            isa<LoadInst>(I);
        Value *SlotRSP = Offset >= NativeStackTop &&
                                 !IsIncomingStackArgument
                             ? GetFixedSlotRSP(I)
                             : IncomingRSP;
        I->setOperand(OpNo, BuildNestedAddress(I, SlotRSP, Offset));
        ++Lowered;
      }
    }

    auto GetBasePointer = [&](Value *BaseInteger, Instruction *InsertBefore) {
      auto It = BasePointers.find(BaseInteger);
      if (It != BasePointers.end())
        return It->second;
      if (NativeStack) {
        BasePointers[BaseInteger] = NativeStack;
        return NativeStack;
      }
      Instruction *Point = InsertBefore;
      if (auto *BaseInst = dyn_cast<Instruction>(BaseInteger)) {
        Point = BaseInst->getNextNode();
        if (isa<PHINode>(BaseInst))
          Point = &*BaseInst->getParent()->getFirstInsertionPt();
      } else if (isa<Argument>(BaseInteger)) {
        Point = &*F.getEntryBlock().getFirstInsertionPt();
      }
      IRBuilder<> B(Point);
      Value *Base = B.CreateIntToPtr(
          BaseInteger, PointerType::getUnqual(B.getContext()),
                                     "native.stack.base");
      BasePointers[BaseInteger] = Base;
      return Base;
    };
    SmallVector<IntToPtrInst *, 256> Candidates;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I))
          Candidates.push_back(ITP);

    for (IntToPtrInst *ITP : Candidates) {
      Value *Integer = ITP->getOperand(0);
      SmallPtrSet<Value *, 32> Seen;
      auto Affine = GetStackAffine(Integer, Seen);
      if (!Affine && NativeStack) {
        SmallPtrSet<Value *, 32> RootSeen;
        if (FindKnownStackRoot(Integer, RootSeen)) {
          IRBuilder<> B(ITP);
          Value *AnchorInt = B.CreatePtrToInt(NativeStack, B.getInt64Ty(),
                                              "native.stack.anchor");
          Value *Delta = B.CreateSub(Integer, AnchorInt,
                                     "native.stack.expression.offset");
          Value *Address = B.CreateGEP(B.getInt8Ty(), NativeStack, Delta,
                                       "native.stack.gep");
          ITP->replaceAllUsesWith(Address);
          ITP->eraseFromParent();
          ++Lowered;
        }
        continue;
      }
      if (!Affine)
        continue;
      IRBuilder<> B(ITP);
      Value *Address = nullptr;
      if (NativeStack) {
        // The integer root is an absolute native address encoded in the
        // lifted register file.  Rebase it against the explicit native stack
        // anchor before applying the affine frame offset.  This preserves
        // values produced by PHIs/calls instead of treating every root as
        // the initial RSP.
        Value *AnchorInt = B.CreatePtrToInt(NativeStack, B.getInt64Ty(),
                                            "native.stack.anchor");
        Value *Delta = B.CreateSub(Affine->Root, AnchorInt,
                                   "native.stack.delta");
        if (Affine->Offset != 0)
          Delta = B.CreateAdd(Delta, B.getInt64(Affine->Offset),
                              "native.stack.offset");
        if (Affine->Dynamic) {
          if (Affine->NegateDynamic)
            Delta = B.CreateSub(Delta, Affine->Dynamic,
                                "native.stack.dynamic.offset");
          else
            Delta = B.CreateAdd(Delta, Affine->Dynamic,
                                "native.stack.dynamic.offset");
        }
        Address = B.CreateGEP(B.getInt8Ty(), NativeStack, Delta,
                              "native.stack.gep");
      } else {
        Value *Base = GetBasePointer(Affine->Root, ITP);
        Address = Base;
        if (Affine->Offset != 0)
          Address = B.CreateGEP(B.getInt8Ty(), Base,
                                B.getInt64(Affine->Offset),
                                "native.stack.gep");
      }
      ITP->replaceAllUsesWith(Address);
      ITP->eraseFromParent();
      ++Lowered;
    }
  }
  if (Lowered)
    errs() << "  native stack integer addresses lowered: " << Lowered
           << "\n";

  // After every recovered stack dereference has become a GEP from the
  // explicit frame pointer, RSP/RBP no longer need to contain host pointer
  // bits.  Represent them as signed byte offsets from frame_base.  At the
  // entry boundary the top of the frame is offset zero; arithmetic and PHIs
  // then propagate offsets naturally across recovered calls.
  auto ContainsLoadedInteger = [](Value *V, auto &&Self,
                                  SmallPtrSetImpl<Value *> &Seen) -> bool {
    if (!V || !Seen.insert(V).second)
      return false;
    if (isa<LoadInst>(V))
      return true;
    auto *I = dyn_cast<Instruction>(V);
    if (!I || isa<PHINode>(I))
      return false;
    for (Value *Op : I->operands())
      if (Op->getType()->isIntegerTy() && Self(Op, Self, Seen))
        return true;
    return false;
  };
  bool CanRelativize = true;
  for (Function &F : M) {
    bool HasFrameBase = false;
    for (Argument &A : F.args())
      HasFrameBase |= A.getName() == "native_stack";
    if (!HasFrameBase)
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP)
          continue;
        SmallPtrSet<Value *, 16> Seen;
        if (ContainsLoadedInteger(ITP->getOperand(0), ContainsLoadedInteger,
                                  Seen)) {
          CanRelativize = false;
          break;
        }
      }
      if (!CanRelativize)
        break;
    }
    if (!CanRelativize)
      break;
  }

  // Relativizing the entry stack pointer is valid only after every consumer
  // has been rewritten to `gep frame_base, signed_offset`.  In particular,
  // recovered entry wrappers can still contain an absolute-delta expression
  // such as
  //
  //   gep @frame_storage, (rsp - ptrtoint(@frame_storage))
  //
  // after all IntToPtr instructions have disappeared.  Replacing
  // ptrtoint(frame_top) with zero in that mixed representation folds the GEP
  // to a small absolute address.  Inspect GEP indices and external call
  // operands recursively; the earlier IntToPtr-only proof cannot see these
  // carriers.
  auto IsFrameBackingPointer =
      [&](Value *V, auto &&Self, SmallPtrSetImpl<Value *> &Seen) -> bool {
    if (!V || !Seen.insert(V).second)
      return false;
    Value *Stripped = V->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalValue>(Stripped))
      return GV->getName().starts_with("frame_storage_backing.");
    if (auto *GA = dyn_cast<GlobalAlias>(Stripped))
      return Self(GA->getAliasee(), Self, Seen);
    if (auto *GEP = dyn_cast<GEPOperator>(Stripped))
      return Self(GEP->getPointerOperand(), Self, Seen);
    return false;
  };
  auto ContainsFrameBackingPtrToInt =
      [&](Value *V, auto &&Self, SmallPtrSetImpl<Value *> &Seen) -> bool {
    if (!V || !Seen.insert(V).second)
      return false;
    if (auto *PTI = dyn_cast<PtrToIntOperator>(V)) {
      SmallPtrSet<Value *, 8> PointerSeen;
      if (IsFrameBackingPointer(PTI->getPointerOperand(),
                                IsFrameBackingPointer, PointerSeen))
        return true;
    }
    auto *U = dyn_cast<User>(V);
    if (!U)
      return false;
    for (Value *Op : U->operands())
      if (Self(Op, Self, Seen))
        return true;
    return false;
  };
  if (CanRelativize) {
    for (Function &F : M) {
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          SmallVector<Value *, 16> Consumers;
          if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
            for (Value *Index : GEP->indices())
              Consumers.push_back(Index);
          } else if (auto *ITP = dyn_cast<IntToPtrInst>(&I)) {
            Consumers.push_back(ITP->getOperand(0));
          } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
            // Entrypoint normalization seeds State RSP/RBP with a constant
            // ptrtoint(frame_top).  Leaving that absolute seed intact while
            // marking callees as relative-stack shifts every nested frame.
            Consumers.push_back(SI->getValueOperand());
          } else if (auto *CB = dyn_cast<CallBase>(&I)) {
            for (Value *Arg : CB->args())
              Consumers.push_back(Arg);
          }
          for (Value *Consumer : Consumers) {
            SmallPtrSet<Value *, 32> Seen;
            if (ContainsFrameBackingPtrToInt(
                    Consumer, ContainsFrameBackingPtrToInt, Seen)) {
              CanRelativize = false;
              break;
            }
          }
          if (!CanRelativize)
            break;
        }
        if (!CanRelativize)
          break;
      }
      if (!CanRelativize)
        break;
    }
  }

  SmallVector<PtrToIntInst *, 64> StackPointerIntegers;
  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *PTI = dyn_cast<PtrToIntInst>(&I);
        if (!PTI)
          continue;
        Value *Pointer = PTI->getPointerOperand();
        StringRef PointerName = Pointer->getName();
        bool IsFramePointer =
            (isa<Argument>(Pointer) && PointerName == "native_stack") ||
            PointerName.starts_with("native_stack_top") ||
            PointerName.starts_with("callback_stack_top");
        if (CanRelativize && IsFramePointer)
          StackPointerIntegers.push_back(PTI);
      }
    }
  }
  for (PtrToIntInst *PTI : StackPointerIntegers) {
    PTI->replaceAllUsesWith(ConstantInt::get(PTI->getType(), 0));
    PTI->eraseFromParent();
    ++Lowered;
  }

  for (Function &F : M) {
    for (Argument &A : F.args())
      if (A.getName() == "native_stack") {
        if (CanRelativize)
          F.addFnAttr("brighten.relative-stack");
        A.setName("frame_base");
      }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        StringRef Name = I.getName();
        if (Name.starts_with("native_stack_storage"))
          I.setName("frame_storage");
        else if (Name.starts_with("native_stack_top"))
          I.setName("frame_top");
        else if (Name.starts_with("native.stack."))
          I.setName("frame." + Name.drop_front(13));
      }
    }
  }
  return Lowered != 0;
}

} // namespace

bool lowerNativeMainStateBuffer(Module &M) {
  return lowerNativeMainStateBufferImpl(M);
}

bool lowerNativeMainStackBuffer(Module &M) {
  return lowerNativeMainStackBufferImpl(M);
}

bool lowerNativeStackAddresses(Module &M) {
  return lowerNativeStackAddressesImpl(M);
}

bool cleanupNativeDeadInstructions(Module &M) {
  bool Changed = false;
  for (unsigned Iter = 0; Iter < 16; ++Iter) {
    SmallVector<Instruction *, 256> Dead;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (I.use_empty())
            Dead.push_back(&I);
    }
    if (Dead.empty())
      break;
    bool RoundChanged = false;
    for (Instruction *I : Dead)
      if (I->getParent() && I->use_empty())
        RoundChanged |= RecursivelyDeleteTriviallyDeadInstructions(I);
    Changed |= RoundChanged;
    if (!RoundChanged)
      break;
  }
  return Changed;
}

bool lowerNativeStateABI(Module &M) {
  DenseMap<Function *, std::unique_ptr<Plan>> Plans;
  for (Function &F : M) {
    if (!IsNative(F))
      continue;
    RedirectGlobalStateAccesses(F, M.getDataLayout());
    auto P = std::make_unique<Plan>();
    P->Old = &F;
    CollectPlanUses(*P, M.getDataLayout());
    if (!P->HasStateUses)
      continue;
    Plans[&F] = std::move(P);
  }
  if (Plans.empty())
    return false;

  // Propagate callee state requirements until every caller can carry all
  // values needed by a transformed direct call.
  for (unsigned Iter = 0; Iter < Plans.size() + 2; ++Iter)
    if (!AddCallStateRequirements(Plans))
      break;
  for (auto &Entry : Plans)
    RefreshPlanSlotTypes(*Entry.second);

  // Cloning is the first mutating step.  If one function cannot be lowered,
  // remove every partial clone before returning so the cleanup pass never
  // continues with a half-transformed module.  This is especially important
  // for mixed integer/floating-point register slots in larger binaries.
  auto RollbackClones = [&]() {
    for (auto &Entry : Plans) {
      Plan &P = *Entry.second;
      if (P.New && P.New->getParent())
        P.New->dropAllReferences();
    }
    for (auto &Entry : Plans) {
      Plan &P = *Entry.second;
      if (P.New && P.New->getParent())
        P.New->eraseFromParent();
    }
    for (auto &Entry : Plans) {
      Plan &P = *Entry.second;
      if (!P.Proxy)
        continue;
      P.Proxy->removeDeadConstantUsers();
      if (P.Proxy->use_empty() && P.Proxy->getParent())
        P.Proxy->eraseFromParent();
    }
  };

  for (auto &Entry : Plans) {
    if (!ClonePlan(*Entry.second, M)) {
      errs() << "brighten-native-state-ssa: clone failed for "
             << Entry.first->getName() << "\n";
      RollbackClones();
      return false;
    }
  }

  for (auto &Entry : Plans)
    if (!RewriteNativeCalls(*Entry.second, Plans)) {
      errs() << "brighten-native-state-ssa: internal call rewrite failed for "
             << Entry.first->getName() << "\n";
      RollbackClones();
      return false;
    }
  if (!RewriteExternalNativeCalls(M, Plans)) {
    errs() << "brighten-native-state-ssa: external call rewrite failed\n";
    RollbackClones();
    return false;
  }
  for (auto &Entry : Plans)
    PromoteNativeSlotAllocas(*Entry.second);
  for (auto &Entry : Plans)
    if (!CleanupProxy(*Entry.second)) {
      // Calls have already been rewritten to the new SSA clones.  Erasing
      // those clones here is not a rollback: it leaves the rewritten call
      // operands dangling and corrupts the module.  A live proxy is valid
      // backing storage, so retain it and let the later fixed-point cleanup
      // remove it once its remaining users become dead.
      errs() << "brighten-native-state-ssa: proxy retained for "
             << Entry.first->getName() << " (uses="
             << Entry.second->Proxy->getNumUses() << ")\n";
    }
  if (!CanRemoveOldFunctions(M, Plans)) {
    for (auto &Entry : Plans) {
      Function *F = Entry.first;
      if (F->use_empty())
        continue;
      errs() << "brighten-native-state-ssa: old function still has uses: "
             << F->getName() << "\n";
      for (User *U : F->users())
        errs() << "  user: " << *U << "\n";
    }
    RollbackClones();
    return false;
  }

  for (auto &Entry : Plans) {
    Function *Old = Entry.first;
    Function *New = Entry.second->New;
    // Keep the name alive across eraseFromParent().  StringRef would point
    // into the Function's uniqued name storage, which is released on erase.
    std::string OldName = Old->getName().str();
    std::string CanonicalName = OldName;
    if (CanonicalName == "__remill_function_call")
      CanonicalName = "__brighten_native_indirect_call";
    else if (StringRef(CanonicalName).ends_with(".native"))
      CanonicalName.resize(CanonicalName.size() - 7);
    // Old lifted functions may still call one another.  All such users are
    // inside the dead old-function set and can be dropped as a group after
    // external callsites have been rewritten.
    Old->dropAllReferences();
    Old->eraseFromParent();
    New->setName(CanonicalName);
    Entry.second->Proxy->removeDeadConstantUsers();
    if (Entry.second->Proxy->use_empty())
      Entry.second->Proxy->eraseFromParent();
  }
  // Remove any now-unused proxy globals that survived per-plan cleanup.
  SmallVector<GlobalVariable *, 8> DeadProxies;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.getName().starts_with("__native_state_proxy")) {
      GV.removeDeadConstantUsers();
      if (GV.use_empty())
        DeadProxies.push_back(&GV);
    }
  }
  for (GlobalVariable *GV : DeadProxies)
    GV->eraseFromParent();
  return true;
}

} // namespace brighten_native_cleanup
