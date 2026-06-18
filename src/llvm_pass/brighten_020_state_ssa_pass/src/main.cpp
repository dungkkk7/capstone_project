#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Operator.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include <string>
#include <cstdlib>
#include <optional>
#include <algorithm>

using namespace llvm;

namespace brighten_state_ssa {
namespace {

enum class SlotKind : int32_t {
  Register = 0,
  Flag = 1
};

struct SlotKey {
  std::string KeyName; // e.g., "RAX_0"
  std::string RegName; // e.g., "RAX"
  int64_t Offset;
  SlotKind Kind;

  bool operator==(const SlotKey &Other) const {
    return KeyName == Other.KeyName;
  }
};

} // namespace
} // namespace brighten_state_ssa

namespace llvm {
template <> struct DenseMapInfo<brighten_state_ssa::SlotKey> {
  static inline brighten_state_ssa::SlotKey getEmptyKey() {
    return brighten_state_ssa::SlotKey{"", "", 0, brighten_state_ssa::SlotKind::Register};
  }
  static inline brighten_state_ssa::SlotKey getTombstoneKey() {
    return brighten_state_ssa::SlotKey{"<tombstone>", "", 0, brighten_state_ssa::SlotKind::Register};
  }
  static unsigned getHashValue(const brighten_state_ssa::SlotKey &Val) {
    return DenseMapInfo<StringRef>::getHashValue(Val.KeyName);
  }
  static bool isEqual(const brighten_state_ssa::SlotKey &LHS, const brighten_state_ssa::SlotKey &RHS) {
    return LHS.KeyName == RHS.KeyName;
  }
};
} // namespace llvm

namespace brighten_state_ssa {
namespace {

struct SlotInfo {
  SlotKey Key;
  Type *StorageType = nullptr;
  Value *Pointer = nullptr;
  AllocaInst *Alloca = nullptr;
  Align Alignment = Align(8);
  bool IsStore = false;
};

bool TraceEnabled() {
  const char *Env = std::getenv("REMILL_STATE_SSA_TRACE");
  return Env && std::string(Env) != "0";
}

bool IsGprName(StringRef Name) {
  return Name == "RAX" || Name == "RBX" || Name == "RCX" || Name == "RDX" ||
         Name == "RSI" || Name == "RDI" || Name == "RBP" || Name == "RSP" ||
         Name == "R8"  || Name == "R9"  || Name == "R10" || Name == "R11" ||
         Name == "R12" || Name == "R13" || Name == "R14" || Name == "R15" ||
         Name == "RIP";
}

bool IsV1PromotableReg(StringRef Name) {
  return IsGprName(Name) && Name != "RIP" && Name != "RSP";
}

bool IsFlagName(StringRef Name) {
  return Name == "CF" || Name == "PF" || Name == "AF" || Name == "ZF" ||
         Name == "SF" || Name == "OF" || Name == "DF";
}

int64_t resolveStateOffset(Value *ptr, const DataLayout &DL) {
  int64_t total_offset = 0;
  Value *base = ptr;

  int limit = 100;
  while (limit-- > 0) {
    if (auto *GA = dyn_cast<GlobalAlias>(base)) {
      base = GA->getAliasee();
      continue;
    }
    if (auto *GEP = dyn_cast<GEPOperator>(base)) {
      APInt ap_offset(64, 0);
      if (GEP->accumulateConstantOffset(DL, ap_offset)) {
        total_offset += ap_offset.getSExtValue();
        base = GEP->getPointerOperand();
        continue;
      }
      return -1;
    }
    if (auto *BC = dyn_cast<BitCastOperator>(base)) {
      base = BC->getOperand(0);
      continue;
    }
    break;
  }

  if (auto *arg = dyn_cast<Argument>(base)) {
    if (arg->getArgNo() == 0 && total_offset >= 0) {
      return total_offset;
    }
  }

  if (auto *GV = dyn_cast<GlobalValue>(base)) {
    if (GV->hasName()) {
      StringRef Name = GV->getName();
      if (Name == "__mcsema_reg_state" || Name.contains("reg_state")) {
        if (total_offset >= 0) {
          return total_offset;
        }
      }
      size_t FirstUnderscore = Name.find('_');
      if (FirstUnderscore != StringRef::npos) {
        size_t SecondUnderscore = Name.find('_', FirstUnderscore + 1);
        StringRef OffsetPart;
        if (SecondUnderscore != StringRef::npos) {
          OffsetPart = Name.slice(FirstUnderscore + 1, SecondUnderscore);
        } else {
          OffsetPart = Name.substr(FirstUnderscore + 1);
        }
        if (!OffsetPart.empty()) {
          int64_t OffsetVal = 0;
          if (!OffsetPart.getAsInteger(10, OffsetVal)) {
            if (OffsetVal >= 0 && total_offset >= 0) {
              return OffsetVal + total_offset;
            }
          }
        }
      }
    }
  }

  return -1;
}

std::optional<SlotKey> ClassifyStateAlias(Value *V, const DataLayout &DL) {
  if (!V) return std::nullopt;
  int64_t Offset = resolveStateOffset(V, DL);
  if (Offset < 0) return std::nullopt;

  if (Offset >= 2216 && Offset < 2488) {
    int64_t k = (Offset - 2216) / 16;
    std::string RegName;
    switch (k) {
      case 0: RegName = "RAX"; break;
      case 1: RegName = "RBX"; break;
      case 2: RegName = "RCX"; break;
      case 3: RegName = "RDX"; break;
      case 4: RegName = "RSI"; break;
      case 5: RegName = "RDI"; break;
      case 6: RegName = "RSP"; break;
      case 7: RegName = "RBP"; break;
      case 8: RegName = "R8"; break;
      case 9: RegName = "R9"; break;
      case 10: RegName = "R10"; break;
      case 11: RegName = "R11"; break;
      case 12: RegName = "R12"; break;
      case 13: RegName = "R13"; break;
      case 14: RegName = "R14"; break;
      case 15: RegName = "R15"; break;
      case 16: RegName = "RIP"; break;
      default: return std::nullopt;
    }
    
    if (RegName == "RIP") {
      return std::nullopt;
    }

    SlotKey Key;
    Key.RegName = RegName;
    Key.Offset = Offset;
    Key.Kind = SlotKind::Register;
    Key.KeyName = RegName + "_" + std::to_string(Offset);
    return Key;
  }

  if (Offset == 2065 || Offset == 2067 || Offset == 2069 || Offset == 2071 ||
      Offset == 2073 || Offset == 2077 || Offset == 2079) {
    std::string FlagName;
    switch (Offset) {
      case 2065: FlagName = "CF"; break;
      case 2067: FlagName = "PF"; break;
      case 2069: FlagName = "AF"; break;
      case 2071: FlagName = "ZF"; break;
      case 2073: FlagName = "SF"; break;
      case 2077: FlagName = "OF"; break;
      case 2079: FlagName = "DF"; break;
      default: return std::nullopt;
    }

    SlotKey Key;
    Key.RegName = FlagName;
    Key.Offset = Offset;
    Key.Kind = SlotKind::Flag;
    Key.KeyName = FlagName + "_" + std::to_string(Offset);
    return Key;
  }

  return std::nullopt;
}

void CollectGprBaseOffsets(Function &F, const DataLayout &DL, StringMap<int64_t> &GprBaseOffsets) {
  for (Instruction &I : instructions(F)) {
    Value *Ptr = nullptr;
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      if (!LI->isVolatile() && !LI->isAtomic())
        Ptr = LI->getPointerOperand();
    } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (!SI->isVolatile() && !SI->isAtomic())
        Ptr = SI->getPointerOperand();
    }
    if (Ptr) {
      if (auto OptKey = ClassifyStateAlias(Ptr, DL)) {
        if (OptKey->Kind == SlotKind::Register) {
          auto It = GprBaseOffsets.find(OptKey->RegName);
          if (It != GprBaseOffsets.end()) {
            if (OptKey->Offset < It->second) {
              It->second = OptKey->Offset;
            }
          } else {
            GprBaseOffsets.insert({OptKey->RegName, OptKey->Offset});
          }
        }
      }
    }
  }
}

void CollectGprBasePtrs(Function &F, const DataLayout &DL, const StringMap<int64_t> &GprBaseOffsets, StringMap<Value*> &GprBasePtrs) {
  for (Instruction &I : instructions(F)) {
    Value *Ptr = nullptr;
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      if (!LI->isVolatile() && !LI->isAtomic())
        Ptr = LI->getPointerOperand();
    } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (!SI->isVolatile() && !SI->isAtomic())
        Ptr = SI->getPointerOperand();
    }
    if (Ptr) {
      if (auto OptKey = ClassifyStateAlias(Ptr, DL)) {
        if (OptKey->Kind == SlotKind::Register) {
          auto It = GprBaseOffsets.find(OptKey->RegName);
          if (It != GprBaseOffsets.end() && OptKey->Offset == It->second) {
            GprBasePtrs.insert({OptKey->RegName, Ptr});
          }
        }
      }
    }
  }
}

SlotKey CanonicalSlotKey(const SlotKey &Key, const StringMap<int64_t> &GprBaseOffsets) {
  if (Key.Kind == SlotKind::Register) {
    auto It = GprBaseOffsets.find(Key.RegName);
    if (It != GprBaseOffsets.end()) {
      int64_t BaseOffset = It->second;
      SlotKey NewKey = Key;
      NewKey.Offset = Key.Offset - BaseOffset;
      NewKey.KeyName = Key.RegName + "_" + std::to_string(NewKey.Offset);
      return NewKey;
    }
  }
  return Key;
}

bool AccessFitsSlot(const SlotKey &AccessKey, const SlotKey &SlotKey, Type *AccessType) {
  if (AccessKey.Kind == SlotKind::Flag) {
    return AccessKey.Offset == SlotKey.Offset;
  }
  int64_t Diff = AccessKey.Offset - SlotKey.Offset;
  if (Diff < 0 || Diff >= 8) {
    return false;
  }
  if (AccessType->isPointerTy()) {
    return Diff == 0;
  }
  if (auto *ITy = dyn_cast<IntegerType>(AccessType)) {
    uint32_t Width = ITy->getBitWidth();
    if (Width > 64) {
      return false;
    }
    return (Width + 8 * Diff) <= 64;
  }
  return false;
}

bool IsSupportedAccessType(Type *Ty, SlotKind Kind) {
  if (Ty->isPointerTy()) {
    return Kind == SlotKind::Register;
  }
  if (auto *ITy = dyn_cast<IntegerType>(Ty)) {
    uint32_t Width = ITy->getBitWidth();
    if (Kind == SlotKind::Flag) {
      return Width <= 8;
    }
    return Width == 1 || Width == 8 || Width == 16 || Width == 32 || Width == 64;
  }
  return false;
}

Type *StorageTypeFor(LLVMContext &Ctx, SlotKind Kind) {
  if (Kind == SlotKind::Flag) {
    return Type::getInt8Ty(Ctx);
  }
  return Type::getInt64Ty(Ctx);
}

Value *CastToStorage(IRBuilder<> &Builder, SlotInfo &Slot, Value *V, Instruction *InsertBefore = nullptr) {
  Type *StorageTy = Slot.StorageType;
  Type *VTy = V->getType();
  if (VTy == StorageTy) {
    return V;
  }
  if (VTy->isPointerTy() && StorageTy->isIntegerTy()) {
    return Builder.CreatePtrToInt(V, StorageTy, V->getName() + ".ptrint");
  }
  if (VTy->isIntegerTy() && StorageTy->isPointerTy()) {
    return Builder.CreateIntToPtr(V, StorageTy, V->getName() + ".intptr");
  }
  if (auto *VInt = dyn_cast<IntegerType>(VTy)) {
    if (auto *StorageInt = dyn_cast<IntegerType>(StorageTy)) {
      uint32_t VWidth = VInt->getBitWidth();
      uint32_t StorageWidth = StorageInt->getBitWidth();
      if (VWidth > StorageWidth) {
        return Builder.CreateTrunc(V, StorageTy, V->getName() + ".trunc");
      } else if (VWidth < StorageWidth) {
        return Builder.CreateZExt(V, StorageTy, V->getName() + ".zext");
      }
    }
  }
  return V;
}

Value *ValueForLoad(IRBuilder<> &Builder, SlotInfo &Slot, const SlotKey &AccessKey, Type *LoadTy, Instruction *I) {
  Value *Val = Builder.CreateLoad(Slot.StorageType, Slot.Alloca, Slot.Key.KeyName + ".ssa");
  bool DirectLoad = true;
  Value *LoadedVal = Val;

  if (Slot.Key.Kind == SlotKind::Register) {
    int64_t Diff = AccessKey.Offset - Slot.Key.Offset;
    if (Diff < 0) {
      return nullptr;
    }
    if (Diff > 0) {
      int64_t ShiftBits = 8 * Diff;
      Value *ShiftConst = ConstantInt::get(Slot.StorageType, ShiftBits, false);
      Val = Builder.CreateLShr(Val, ShiftConst, Slot.Key.KeyName + ".shift");
      DirectLoad = false;
      LoadedVal = Val;
    }
  }

  if (DirectLoad && Slot.StorageType == LoadTy) {
    return LoadedVal;
  }

  if (LoadTy->isPointerTy() && Slot.StorageType->isIntegerTy()) {
    if (DirectLoad) {
      return Builder.CreateIntToPtr(Val, LoadTy, Slot.Key.KeyName + ".ptr");
    }
    return nullptr;
  }

  if (auto *ValInt = dyn_cast<IntegerType>(Val->getType())) {
    if (auto *LoadInt = dyn_cast<IntegerType>(LoadTy)) {
      uint32_t ValWidth = ValInt->getBitWidth();
      uint32_t LoadWidth = LoadInt->getBitWidth();
      if (ValWidth != LoadWidth) {
        if (LoadWidth > ValWidth) {
          return Builder.CreateZExt(Val, LoadTy, Slot.Key.KeyName + ".wide");
        } else {
          return Builder.CreateTrunc(Val, LoadTy, Slot.Key.KeyName + ".narrow");
        }
      }
    }
  }
  return LoadedVal;
}

Value *MaskedIntegerUpdate(IRBuilder<> &Builder, SlotInfo &Slot, const SlotKey &AccessKey, Value *ValToStore) {
  auto *SlotInt = dyn_cast<IntegerType>(Slot.StorageType);
  auto *ValInt = dyn_cast<IntegerType>(ValToStore->getType());
  if (SlotInt && ValInt && Slot.Key.Kind == SlotKind::Register) {
    uint32_t ValWidth = ValInt->getBitWidth();
    uint32_t SlotWidth = SlotInt->getBitWidth();
    int64_t Diff = AccessKey.Offset - Slot.Key.Offset;
    if (Diff >= 0 && (8 * Diff + ValWidth) <= SlotWidth) {
      int32_t ShiftBits = 8 * Diff;
      if (ValWidth < SlotWidth || ShiftBits != 0) {
        Value *OldVal = Builder.CreateLoad(Slot.StorageType, Slot.Alloca, Slot.Key.KeyName + ".old");
        APInt Mask(SlotWidth, 0);
        Mask.setLowBits(ValWidth);
        Mask = Mask.shl(ShiftBits);
        Mask.flipAllBits();

        Value *KeepMaskConst = ConstantInt::get(Slot.StorageType, Mask);
        Value *KeptVal = Builder.CreateAnd(OldVal, KeepMaskConst, Slot.Key.KeyName + ".keep");

        Value *ZExtVal = Builder.CreateZExt(ValToStore, Slot.StorageType, ValToStore->getName() + ".zextlo");
        if (ShiftBits != 0) {
          Value *ShiftConst = ConstantInt::get(Slot.StorageType, ShiftBits, false);
          ZExtVal = Builder.CreateShl(ZExtVal, ShiftConst, Slot.Key.KeyName + ".place", false, false);
        }
        return Builder.CreateOr(KeptVal, ZExtVal, Slot.Key.KeyName + ".merge", false);
      } else {
        Instruction *InsertPt = nullptr;
        auto InsertBlock = Builder.GetInsertBlock();
        if (InsertBlock && Builder.GetInsertPoint() != InsertBlock->end()) {
          InsertPt = &*Builder.GetInsertPoint();
        }
        return CastToStorage(Builder, Slot, ValToStore, InsertPt);
      }
    }
  }
  return nullptr;
}

bool StoreToSlot(IRBuilder<> &Builder, SlotInfo &Slot, const SlotKey &AccessKey, Value *ValToStore) {
  Value *StoreVal = nullptr;
  if (Slot.Key.Kind != SlotKind::Register) {
    StoreVal = CastToStorage(Builder, Slot, ValToStore);
  } else {
    auto *ValTy = ValToStore->getType();
    if (!ValTy->isIntegerTy() || !Slot.StorageType->isIntegerTy()) {
      StoreVal = CastToStorage(Builder, Slot, ValToStore);
    } else {
      StoreVal = MaskedIntegerUpdate(Builder, Slot, AccessKey, ValToStore);
      if (!StoreVal) {
        return false;
      }
    }
  }

  if (StoreVal) {
    auto *StoreInst = Builder.CreateStore(StoreVal, Slot.Alloca);
    StoreInst->setAlignment(Slot.Alignment);
    Slot.IsStore = true;
    return true;
  }
  return false;
}

int64_t GetGprBaseOffset(StringRef RegName) {
  if (RegName == "RAX") return 2216;
  if (RegName == "RBX") return 2232;
  if (RegName == "RCX") return 2248;
  if (RegName == "RDX") return 2264;
  if (RegName == "RSI") return 2280;
  if (RegName == "RDI") return 2296;
  if (RegName == "RSP") return 2312;
  if (RegName == "RBP") return 2328;
  if (RegName == "R8")  return 2344;
  if (RegName == "R9")  return 2360;
  if (RegName == "R10") return 2376;
  if (RegName == "R11") return 2392;
  if (RegName == "R12") return 2408;
  if (RegName == "R13") return 2424;
  if (RegName == "R14") return 2440;
  if (RegName == "R15") return 2456;
  if (RegName == "RIP") return 2472;
  return 0;
}

int64_t GetAbsoluteOffset(const SlotInfo &Slot) {
  int64_t BaseOffset = 0;
  if (Slot.Key.Kind == SlotKind::Register) {
    BaseOffset = GetGprBaseOffset(Slot.Key.RegName);
  }
  return BaseOffset + Slot.Key.Offset;
}

Value *GetSlotPointer(IRBuilder<> &Builder, Value *StatePtr, const SlotInfo &Slot) {
  int64_t AbsoluteOffset = GetAbsoluteOffset(Slot);
  return Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StatePtr, AbsoluteOffset);
}

void FlushSlot(IRBuilder<> &Builder, Value *StatePtr, SlotInfo &Slot) {
  Value *Val = Builder.CreateLoad(Slot.StorageType, Slot.Alloca, Slot.Key.KeyName + ".flush");
  Value *Ptr = GetSlotPointer(Builder, StatePtr, Slot);
  auto *Store = Builder.CreateStore(Val, Ptr);
  Store->setAlignment(Slot.Alignment);
}

void ReloadSlot(IRBuilder<> &Builder, Value *StatePtr, SlotInfo &Slot) {
  Value *Ptr = GetSlotPointer(Builder, StatePtr, Slot);
  Value *Val = Builder.CreateLoad(Slot.StorageType, Ptr, Slot.Key.KeyName + ".reload");
  auto *Store = Builder.CreateStore(Val, Slot.Alloca);
  Store->setAlignment(Slot.Alignment);
}

bool IsBoundaryCall(CallBase &CB) {
  if (isa<DbgInfoIntrinsic>(&CB)) {
    return false;
  }
  Value *CalledVal = CB.getCalledOperand()->stripPointerCasts();
  Function *CalledF = dyn_cast<Function>(CalledVal);
  if (!CalledF) {
    return true; // Indirect calls are boundaries
  }
  if (CalledF->isIntrinsic()) {
    return false;
  }
  StringRef Name = CalledF->getName();
  if (Name.starts_with("ext_") || Name.starts_with("sub_") ||
      Name.starts_with("__remill_") || Name.starts_with("__mcsema_") ||
      Name.starts_with("callback_")) {
    return true;
  }
  return CalledF->isDeclaration();
}

bool CalleeTakesState(CallBase &CB) {
  Value *CalledVal = CB.getCalledOperand()->stripPointerCasts();
  Function *CalledF = dyn_cast<Function>(CalledVal);
  if (!CalledF) {
    return true; // Indirect calls are assumed to take State*
  }
  StringRef Name = CalledF->getName();
  if (Name.starts_with("sub_") || Name.starts_with("__mcsema_") || 
      Name.starts_with("__remill_") || Name.starts_with("ext_") ||
      Name.starts_with("callback_")) {
    return true;
  }
  return false;
}

bool IsCallerClobbered(StringRef Name) {
  return Name == "RAX" || Name == "RCX" || Name == "RDX" || Name == "RSI" ||
         Name == "RDI" || Name == "R8"  || Name == "R9"  || Name == "R10" ||
         Name == "R11" || IsFlagName(Name);
}

bool NeedsCallFlush(const SlotInfo &Slot) {
  if (Slot.IsStore) {
    return true;
  }
  StringRef Name = Slot.Key.RegName;
  return Name == "RAX" || Name == "RDI" || Name == "RSI" || Name == "RDX" ||
         Name == "RCX" || Name == "R8"  || Name == "R9"  || Name == "RSP";
}

bool NeedsCallReload(const SlotInfo &Slot) {
  return IsCallerClobbered(Slot.Key.RegName);
}

bool NeedsReturnFlush(const SlotInfo &Slot) {
  if (Slot.IsStore) {
    return true;
  }
  StringRef Name = Slot.Key.RegName;
  return Name == "RAX" || Name == "RSP" || Name == "RIP";
}

void CollectSlots(Function &F, const DataLayout &DL, DenseMap<SlotKey, SlotInfo> &Slots) {
  StringMap<int64_t> GprBaseOffsets;
  CollectGprBaseOffsets(F, DL, GprBaseOffsets);

  StringMap<Value*> GprBasePtrs;
  CollectGprBasePtrs(F, DL, GprBaseOffsets, GprBasePtrs);

  for (Instruction &I : instructions(F)) {
    Value *Ptr = nullptr;
    Value *AccessVal = nullptr;
    bool IsStore = false;
    Align AccessAlign = Align(1);

    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      if (!LI->isVolatile() && !LI->isAtomic()) {
        Ptr = LI->getPointerOperand();
        AccessVal = LI;
        IsStore = false;
        AccessAlign = LI->getAlign();
      }
    } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (!SI->isVolatile() && !SI->isAtomic()) {
        Ptr = SI->getPointerOperand();
        AccessVal = SI->getValueOperand();
        IsStore = true;
        AccessAlign = SI->getAlign();
      }
    }

    if (Ptr) {
      if (auto OptKey = ClassifyStateAlias(Ptr, DL)) {
        if (IsSupportedAccessType(AccessVal->getType(), OptKey->Kind)) {
          SlotKey Key = CanonicalSlotKey(*OptKey, GprBaseOffsets);
          if (AccessFitsSlot(Key, Key, AccessVal->getType())) {
            Value *BasePtr = nullptr;
            if (Key.Kind == SlotKind::Register) {
              auto It = GprBasePtrs.find(Key.RegName);
              if (It != GprBasePtrs.end()) {
                BasePtr = It->second;
              }
            } else {
              BasePtr = Ptr;
            }

            if (BasePtr) {
              auto It = Slots.find(Key);
              if (It != Slots.end()) {
                It->second.Alignment = std::max(It->second.Alignment, AccessAlign);
                It->second.IsStore |= IsStore;
              } else {
                SlotInfo Slot;
                Slot.Key = Key;
                Slot.StorageType = StorageTypeFor(F.getContext(), Key.Kind);
                Slot.Pointer = BasePtr;
                Slot.Alignment = (Key.Kind == SlotKind::Register) ? Align(8) : Align(1);
                Slot.IsStore = IsStore;
                Slots.insert({Key, Slot});
              }
            }
          }
        }
      }
    }
  }
}

bool PromoteFunction(Function &F) {
  if (F.isDeclaration() || F.empty()) {
    return false;
  }

  const DataLayout &DL = F.getParent()->getDataLayout();

  DenseMap<SlotKey, SlotInfo> Slots;
  CollectSlots(F, DL, Slots);

  if (Slots.empty()) {
    return false;
  }

  StringMap<int64_t> GprBaseOffsets;
  CollectGprBaseOffsets(F, DL, GprBaseOffsets);

  BasicBlock &Entry = F.getEntryBlock();
  IRBuilder<> Builder(&Entry, Entry.getFirstInsertionPt());

  SmallVector<AllocaInst*, 16> Allocas;
  SmallPtrSet<Instruction*, 32> CreatedInsts;

  bool IsNative = F.getName().ends_with("_native");
  const std::vector<unsigned> x86_64_param_offsets = { 2296, 2280, 2264, 2248, 2344, 2360 }; // RDI, RSI, RDX, RCX, R8, R9

  AllocaInst *StateAlloca = nullptr;
  if (IsNative) {
    for (Instruction &I : F.getEntryBlock()) {
      if (auto *AI = dyn_cast<AllocaInst>(&I)) {
        if (AI->getName() == "state" || AI->getName() == "state_raw") {
          StateAlloca = AI;
          break;
        }
      }
    }
  }

  if (IsNative && StateAlloca) {
    Builder.SetInsertPoint(StateAlloca->getNextNode());
  }

  for (auto &Entry : Slots) {
    SlotInfo &Slot = Entry.second;
    std::string VRegName = Slot.Key.KeyName + ".vreg";
    Slot.Alloca = Builder.CreateAlloca(Slot.StorageType, nullptr, VRegName);

    Value *InitVal = nullptr;
    if (IsNative) {
      for (unsigned i = 0; i < x86_64_param_offsets.size() && i < F.arg_size(); ++i) {
        if (Slot.Key.Offset == x86_64_param_offsets[i]) {
          InitVal = F.getArg(i);
          break;
        }
      }
    }

    if (InitVal) {
      Value *CastVal = CastToStorage(Builder, Slot, InitVal);
      auto *EntryStore = Builder.CreateStore(CastVal, Slot.Alloca);
      EntryStore->setAlignment(Slot.Alignment);
      CreatedInsts.insert(EntryStore);
    } else {
      Value *SrcPtr = nullptr;
      int64_t AbsoluteOffset = GetAbsoluteOffset(Slot);
      if (IsNative && StateAlloca) {
        SrcPtr = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StateAlloca, AbsoluteOffset);
      } else {
        Value *StatePtr = F.getArg(0);
        SrcPtr = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StatePtr, AbsoluteOffset);
      }

      std::string EntryName = Slot.Key.KeyName + ".entry";
      auto *EntryLoad = Builder.CreateLoad(Slot.StorageType, SrcPtr, EntryName);
      auto *EntryStore = Builder.CreateStore(EntryLoad, Slot.Alloca);
      EntryStore->setAlignment(Slot.Alignment);

      CreatedInsts.insert(EntryLoad);
      CreatedInsts.insert(EntryStore);
    }

    Allocas.push_back(Slot.Alloca);
  }

  SmallVector<Instruction*, 128> InstsToErase;
  SmallVector<CallInst*, 16> BoundaryCalls;
  SmallVector<ReturnInst*, 16> Returns;

  for (BasicBlock &BB : F) {
    for (Instruction &I : make_early_inc_range(BB)) {
      if (CreatedInsts.contains(&I)) {
        continue;
      }
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        if (auto *CI = dyn_cast<CallInst>(CB)) {
          if (IsBoundaryCall(*CB)) {
            BoundaryCalls.push_back(CI);
          }
        }
      } else if (auto *RI = dyn_cast<ReturnInst>(&I)) {
        Returns.push_back(RI);
      } else if (auto *LI = dyn_cast<LoadInst>(&I)) {
        if (auto OptKey = ClassifyStateAlias(LI->getPointerOperand(), DL)) {
          SlotKey Key = CanonicalSlotKey(*OptKey, GprBaseOffsets);
          auto It = Slots.find(Key);
          if (It != Slots.end() && AccessFitsSlot(Key, Key, LI->getType())) {
            if (F.getName() == "sub_36d0_main_native") {
              errs() << "[DEBUG_SSA] Found Load: " << *LI << " (Key=" << Key.KeyName << ")\n";
            }
            IRBuilder<> LBuilder(LI);
            if (Value *Val = ValueForLoad(LBuilder, It->second, Key, LI->getType(), LI)) {
              if (F.getName() == "sub_36d0_main_native") {
                errs() << "[DEBUG_SSA] Replaced load with: " << *Val << "\n";
              }
              LI->replaceAllUsesWith(Val);
              InstsToErase.push_back(LI);
            } else {
              if (F.getName() == "sub_36d0_main_native") {
                errs() << "[DEBUG_SSA] ValueForLoad failed!\n";
              }
            }
          }
        }
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        if (auto OptKey = ClassifyStateAlias(SI->getPointerOperand(), DL)) {
          SlotKey Key = CanonicalSlotKey(*OptKey, GprBaseOffsets);
          auto It = Slots.find(Key);
          if (It != Slots.end() && AccessFitsSlot(Key, Key, SI->getValueOperand()->getType())) {
            if (F.getName() == "sub_36d0_main_native") {
              errs() << "[DEBUG_SSA] Found Store: " << *SI << " (Key=" << Key.KeyName << ")\n";
            }
            IRBuilder<> SBuilder(SI);
            if (StoreToSlot(SBuilder, It->second, Key, SI->getValueOperand())) {
              if (F.getName() == "sub_36d0_main_native") {
                errs() << "[DEBUG_SSA] StoreToSlot succeeded!\n";
              }
              InstsToErase.push_back(SI);
            } else {
              if (F.getName() == "sub_36d0_main_native") {
                errs() << "[DEBUG_SSA] StoreToSlot failed!\n";
              }
            }
          }
        }
      }
    }
  }

  for (Instruction *I : InstsToErase) {
    I->eraseFromParent();
  }

  for (CallInst *CI : BoundaryCalls) {
    if (CI->getParent() && CalleeTakesState(*CI) && CI->arg_size() > 0) {
      Value *CallStatePtr = CI->getArgOperand(0);
      if (CallStatePtr->getType()->isPointerTy()) {
        IRBuilder<> PreBuilder(CI);
        for (auto &Entry : Slots) {
          if (NeedsCallFlush(Entry.second)) {
            FlushSlot(PreBuilder, CallStatePtr, Entry.second);
          }
        }
        Instruction *Next = CI->getNextNode();
        if (Next) {
          IRBuilder<> PostBuilder(Next);
          for (auto &Entry : Slots) {
            if (NeedsCallReload(Entry.second)) {
              ReloadSlot(PostBuilder, CallStatePtr, Entry.second);
            }
          }
        }
      }
    }
  }

  if (!IsNative) {
    for (ReturnInst *RI : Returns) {
      if (RI->getParent()) {
        IRBuilder<> RetBuilder(RI);
        for (auto &Entry : Slots) {
          if (NeedsReturnFlush(Entry.second)) {
            FlushSlot(RetBuilder, F.getArg(0), Entry.second);
          }
        }
      }
    }
  }

  DominatorTree DT(F);
  AssumptionCache AC(F);
  PromoteMemToReg(Allocas, DT, &AC);

  if (TraceEnabled()) {
    errs() << "brighten-state-ssa-pass function=" << F.getName()
           << " slots=" << Slots.size()
           << " erased=" << InstsToErase.size()
           << " boundaries=" << BoundaryCalls.size() + Returns.size() << "\n";
  }

  return true;
}

Value *lowerConstantExpr(ConstantExpr *CE, Instruction *InsertBefore) {
  Instruction *NewInst = CE->getAsInstruction();
  if (!NewInst) return CE;
  NewInst->insertBefore(InsertBefore->getIterator());
  
  for (unsigned i = 0; i < NewInst->getNumOperands(); ++i) {
    if (auto *SubCE = dyn_cast<ConstantExpr>(NewInst->getOperand(i))) {
      NewInst->setOperand(i, lowerConstantExpr(SubCE, NewInst));
    }
  }
  return NewInst;
}

void LowerConstantExprsInFunction(Function &F) {
  SmallVector<Instruction *, 128> Insts;
  for (Instruction &I : instructions(F)) {
    Insts.push_back(&I);
  }
  for (Instruction *I : Insts) {
    if (auto *PN = dyn_cast<PHINode>(I)) {
      for (unsigned i = 0; i < PN->getNumIncomingValues(); ++i) {
        if (auto *CE = dyn_cast<ConstantExpr>(PN->getIncomingValue(i))) {
          BasicBlock *Pred = PN->getIncomingBlock(i);
          Instruction *Term = Pred->getTerminator();
          PN->setIncomingValue(i, lowerConstantExpr(CE, Term));
        }
      }
    } else {
      for (unsigned i = 0; i < I->getNumOperands(); ++i) {
        if (auto *CE = dyn_cast<ConstantExpr>(I->getOperand(i))) {
          I->setOperand(i, lowerConstantExpr(CE, I));
        }
      }
    }
  }
}

Value *TracePointerOriginHelper(Value *V, int64_t &Offset, const DataLayout &DL, SmallPtrSetImpl<PHINode *> &VisitingPHIs) {
  if (!V) return nullptr;
  if (auto *P2I = dyn_cast<PtrToIntInst>(V)) {
    return P2I->getPointerOperand();
  }
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt) {
      return CE->getOperand(0);
    }
  }
  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (BO->getOpcode() == Instruction::Add) {
      if (auto *CI = dyn_cast<ConstantInt>(BO->getOperand(1))) {
        Offset += CI->getSExtValue();
        return TracePointerOriginHelper(BO->getOperand(0), Offset, DL, VisitingPHIs);
      }
      if (auto *CI = dyn_cast<ConstantInt>(BO->getOperand(0))) {
        Offset += CI->getSExtValue();
        return TracePointerOriginHelper(BO->getOperand(1), Offset, DL, VisitingPHIs);
      }
    }
    if (BO->getOpcode() == Instruction::Sub) {
      if (auto *CI = dyn_cast<ConstantInt>(BO->getOperand(1))) {
        Offset -= CI->getSExtValue();
        return TracePointerOriginHelper(BO->getOperand(0), Offset, DL, VisitingPHIs);
      }
    }
  }
  if (auto *PN = dyn_cast<PHINode>(V)) {
    if (VisitingPHIs.insert(PN).second) {
      Value *CommonBase = nullptr;
      int64_t CommonOffset = 0;
      bool First = true;
      bool Valid = true;
      for (unsigned i = 0; i < PN->getNumIncomingValues(); ++i) {
        int64_t Off = 0;
        Value *Base = TracePointerOriginHelper(PN->getIncomingValue(i), Off, DL, VisitingPHIs);
        if (!Base) {
          Valid = false;
          break;
        }
        if (First) {
          CommonBase = Base;
          CommonOffset = Off;
          First = false;
        } else if (CommonBase != Base || CommonOffset != Off) {
          Valid = false;
          break;
        }
      }
      VisitingPHIs.erase(PN);
      if (Valid) {
        Offset += CommonOffset;
        return CommonBase;
      }
    }
  }
  return nullptr;
}

Value *TracePointerOrigin(Value *V, int64_t &Offset, const DataLayout &DL) {
  SmallPtrSet<PHINode *, 8> VisitingPHIs;
  return TracePointerOriginHelper(V, Offset, DL, VisitingPHIs);
}

bool SimplifyPointerArithmetic(Function &F) {
  bool Changed = false;
  SmallVector<Instruction *, 64> ToErase;
  const DataLayout &DL = F.getParent()->getDataLayout();
  
  for (Instruction &I : instructions(F)) {
    if (auto *I2P = dyn_cast<IntToPtrInst>(&I)) {
      Value *Src = I2P->getOperand(0);
      int64_t Offset = 0;
      if (Value *Base = TracePointerOrigin(Src, Offset, DL)) {
        IRBuilder<> B(I2P);
        Value *GEP = B.CreateGEP(Type::getInt8Ty(F.getContext()), Base, B.getInt64(Offset));
        Value *Cast = B.CreatePointerCast(GEP, I2P->getType());
        I2P->replaceAllUsesWith(Cast);
        ToErase.push_back(I2P);
        Changed = true;
        continue;
      }
    }
    
    // Pattern 4: ptrtoint (inttoptr Val) -> Val
    if (auto *P2I = dyn_cast<PtrToIntInst>(&I)) {
      Value *Src = P2I->getPointerOperand();
      if (auto *I2P = dyn_cast<IntToPtrInst>(Src)) {
        Value *Val = I2P->getOperand(0);
        IRBuilder<> B(P2I);
        Value *Cast = B.CreateIntCast(Val, P2I->getType(), false);
        P2I->replaceAllUsesWith(Cast);
        ToErase.push_back(P2I);
        Changed = true;
        continue;
      }
    }
  }
  
  for (Instruction *I : ToErase) {
    if (I->getParent()) {
      I->eraseFromParent();
    }
  }
  
  return Changed;
}

bool SimplifyPointerArithmeticLoop(Function &F) {
  bool Changed = false;
  while (SimplifyPointerArithmetic(F)) {
    Changed = true;
  }
  return Changed;
}

bool StripRemillCalls(Function &F) {
  bool Changed = false;
  SmallVector<CallInst *, 16> ToErase;
  for (Instruction &I : instructions(F)) {
    if (auto *CI = dyn_cast<CallInst>(&I)) {
      Value *CalledVal = CI->getCalledOperand()->stripPointerCasts();
      if (Function *Callee = dyn_cast<Function>(CalledVal)) {
        StringRef Name = Callee->getName();
        if (Name == "__remill_function_call" || Name == "__remill_jump") {
          if (CI->arg_size() >= 3) {
            CI->replaceAllUsesWith(CI->getArgOperand(2));
          }
          ToErase.push_back(CI);
          Changed = true;
        }
      }
    }
  }
  for (CallInst *CI : ToErase) {
    if (CI->getParent()) {
      CI->eraseFromParent();
    }
  }
  return Changed;
}

void CleanNames(Function &F) {
  for (BasicBlock &BB : F) {
    if (BB.hasName()) {
      StringRef Name = BB.getName();
      if (Name.starts_with("_Z") || Name.contains("_ZN") || Name.contains("_GLOBAL__N")) {
        BB.setName("");
      }
    }
    for (Instruction &I : BB) {
      if (I.hasName()) {
        StringRef Name = I.getName();
        if (Name.starts_with("_Z") || Name.contains("_ZN") || Name.contains("_GLOBAL__N")) {
          I.setName("");
        }
      }
    }
  }
}

} // namespace

struct BrightenStateSSAPass : public PassInfoMixin<BrightenStateSSAPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    bool Changed = false;
    for (Function &F : M) {
      if (F.isDeclaration() || F.empty()) {
        continue;
      }
      Changed |= PromoteFunction(F);
      LowerConstantExprsInFunction(F);
      Changed |= SimplifyPointerArithmeticLoop(F);
      Changed |= StripRemillCalls(F);
      CleanNames(F);
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace brighten_state_ssa

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
    LLVM_PLUGIN_API_VERSION,
    "BrightenStateSSAPass",
    LLVM_VERSION_STRING,
    [](PassBuilder &PB) {
      PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "brighten-state-ssa-pass") {
            MPM.addPass(brighten_state_ssa::BrightenStateSSAPass());
            return true;
          }
          return false;
        }
      );
    }
  };
}
