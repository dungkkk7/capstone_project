#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Operator.h"
#include <optional>
#include <cstdlib>

using namespace llvm;

namespace {

struct StackAccess {
  Instruction *Inst;
  bool IsStore;
};

struct SlotInfo {
  int64_t Offset;
  Type *Ty;
  Align Alignment;
  SmallVector<StackAccess, 8> Accesses;
  SmallVector<StoreInst *, 4> Stores;
  SmallVector<LoadInst *, 4> Loads;
  AllocaInst *Alloca = nullptr;
};

bool TraceEnabled() {
  return getenv("REMILL_STACK_SSA_TRACE") != nullptr;
}

bool ShouldSkipFunction(Function &F) {
  const char *skip_env = getenv("REMILL_STACK_SSA_SKIP");
  if (!skip_env || *skip_env == '\0') {
    return false;
  }
  SmallVector<StringRef, 8> skip_list;
  StringRef(skip_env).split(skip_list, ',', -1, false);
  for (auto &skip_name : skip_list) {
    StringRef trimmed = skip_name.trim(" \t\n\v\f\r");
    if (!trimmed.empty() && F.getName().contains(trimmed)) {
      return true;
    }
  }
  return false;
}

bool EnvEnabled(const char *name, bool default_val) {
  const char *env_val = getenv(name);
  if (!env_val || *env_val == '\0') {
    return default_val;
  }
  StringRef val(env_val);
  if (val.equals_insensitive("0") || val.equals_insensitive("false") || val.equals_insensitive("off") || val.equals_insensitive("no")) {
    return false;
  }
  if (val.equals_insensitive("1") || val.equals_insensitive("true") || val.equals_insensitive("on") || val.equals_insensitive("yes")) {
    return true;
  }
  return default_val;
}

bool AllowBoundaryCrossing() {
  return EnvEnabled("REMILL_STACK_SSA_ALLOW_BOUNDARY", true);
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

bool IsRspOffset(Value *val, const DataLayout &DL) {
  if (!val) return false;
  int64_t Offset = resolveStateOffset(val, DL);
  return Offset == 2312;
}

bool IsRspLoad(Value *val, const DataLayout &DL) {
  if (auto *load = dyn_cast_or_null<LoadInst>(val)) {
    if (load->isVolatile() || load->isAtomic()) {
      return false;
    }
    if (!load->getType()->isIntegerTy()) {
      return false;
    }
    return IsRspOffset(load->getPointerOperand(), DL);
  }
  return false;
}

bool LooksLikeRspArgument(Argument &arg) {
  if (arg.hasName()) {
    return arg.getName().contains_insensitive("rsp");
  }
  return false;
}

void CollectFrameBases(Function &F, const DataLayout &DL, SmallPtrSetImpl<Value*> &Bases) {
  if (F.empty()) {
    return;
  }
  for (auto &I : F.getEntryBlock()) {
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (IsRspOffset(SI->getPointerOperand(), DL)) {
        break;
      }
    }
    if (IsRspLoad(&I, DL)) {
      Bases.insert(&I);
    }
  }
}

bool IsBoundaryCall(CallBase &CB) {
  if (isa<DbgInfoIntrinsic>(&CB)) {
    return false;
  }
  Function *Callee = CB.getCalledFunction();
  if (!Callee) {
    return true;
  }
  if (Callee->isIntrinsic()) {
    return false;
  }
  StringRef Name = Callee->getName();
  if (Name.starts_with("sub_") ||
      Name.starts_with("ext_") ||
      Name.starts_with("__remill_") ||
      Name.starts_with("__mcsema_")) {
    return true;
  }
  return !Callee->isDeclaration();
}

bool ConstI64(Value *Val, int64_t &Res) {
  if (auto *CI = dyn_cast_or_null<ConstantInt>(Val)) {
    Res = CI->getSExtValue();
    return true;
  }
  return false;
}

std::optional<int64_t> EvalRspOffset(Value *Val, SmallPtrSetImpl<Value*> &Visited, SmallPtrSetImpl<Value*> const &Bases) {
  if (!Val) {
    return std::nullopt;
  }
  if (!Visited.insert(Val).second) {
    return std::nullopt;
  }
  Value *Stripped = Val->stripPointerCasts();
  if (Bases.contains(Stripped)) {
    return 0;
  }
  if (auto *BO = dyn_cast<BinaryOperator>(Stripped)) {
    if (BO->getOpcode() == Instruction::Add) {
      int64_t ConstVal = 0;
      if (ConstI64(BO->getOperand(1), ConstVal)) {
        if (auto Offset = EvalRspOffset(BO->getOperand(0), Visited, Bases)) {
          return *Offset + ConstVal;
        }
      } else if (ConstI64(BO->getOperand(0), ConstVal)) {
        if (auto Offset = EvalRspOffset(BO->getOperand(1), Visited, Bases)) {
          return ConstVal + *Offset;
        }
      }
    } else if (BO->getOpcode() == Instruction::Sub) {
      int64_t ConstVal = 0;
      if (ConstI64(BO->getOperand(1), ConstVal)) {
        if (auto Offset = EvalRspOffset(BO->getOperand(0), Visited, Bases)) {
          return *Offset - ConstVal;
        }
      }
    }
  }
  return std::nullopt;
}

std::optional<int64_t> ResolveStackPtr(Value *Val, DataLayout const &DL, SmallPtrSetImpl<Value*> const &Bases) {
  if (!Val) return std::nullopt;
  if (!Val->getType()->isPointerTy()) return std::nullopt;

  if (auto *I2P = dyn_cast<IntToPtrInst>(Val)) {
    SmallPtrSet<Value*, 8> Visited;
    return EvalRspOffset(I2P->getOperand(0), Visited, Bases);
  }
  if (auto *CE = dyn_cast<ConstantExpr>(Val)) {
    if (CE->getOpcode() == Instruction::PtrToInt) {
      SmallPtrSet<Value*, 8> Visited;
      return EvalRspOffset(CE->getOperand(0), Visited, Bases);
    }
  }
  if (auto *GEP = dyn_cast<GEPOperator>(Val)) {
    if (auto PtrOffset = ResolveStackPtr(GEP->getPointerOperand(), DL, Bases)) {
      unsigned IndexSize = DL.getIndexTypeSizeInBits(GEP->getType());
      APInt Offset(IndexSize, 0);
      if (GEP->accumulateConstantOffset(DL, Offset, [](Value &, APInt &) { return false; })) {
        return Offset.getSExtValue() + *PtrOffset;
      }
    }
    return std::nullopt;
  }
  if (auto *BC = dyn_cast<BitCastInst>(Val)) {
    return ResolveStackPtr(BC->getOperand(0), DL, Bases);
  }
  if (auto *ASC = dyn_cast<AddrSpaceCastInst>(Val)) {
    return ResolveStackPtr(ASC->getOperand(0), DL, Bases);
  }
  return std::nullopt;
}

void CollectArgumentFrameBases(Function &F, DataLayout const &DL, SmallPtrSetImpl<Value*> &Bases) {
  for (auto &Arg : F.args()) {
    if (!Arg.getType()->isIntegerTy()) {
      continue;
    }
    SmallPtrSet<Value*, 1> ArgSet;
    ArgSet.insert(&Arg);

    bool HasResolved = false;
    bool HasPositive = false;
    bool HasZero = false;

    for (auto &I : instructions(F)) {
      Value *Ptr = nullptr;
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        if (LI->isVolatile() || LI->isAtomic()) continue;
        Ptr = LI->getPointerOperand();
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        if (SI->isVolatile() || SI->isAtomic()) continue;
        Ptr = SI->getPointerOperand();
      }
      if (Ptr) {
        if (auto Offset = ResolveStackPtr(Ptr, DL, ArgSet)) {
          HasResolved = true;
          if (*Offset > 0) {
            HasPositive = true;
          } else if (*Offset == 0) {
            HasZero = true;
          }
        }
      }
    }

    if (!HasResolved || HasPositive) {
      continue;
    }

    if (HasZero) {
      if (LooksLikeRspArgument(Arg)) {
        Bases.insert(&Arg);
      }
    } else {
      Bases.insert(&Arg);
    }
  }
}

bool IsScalarSlotType(Type *Ty, DataLayout const &DL) {
  if (!Ty) return false;
  if (Ty->isIntegerTy() || Ty->isPointerTy() || Ty->isFloatingPointTy()) {
    TypeSize TS = DL.getTypeStoreSize(Ty);
    if (TS.isScalable()) return false;
    uint64_t Size = TS.getFixedValue();
    return Size > 0 && Size <= 8;
  }
  return false;
}

uint64_t SlotSize(Type *Ty, DataLayout const &DL) {
  return DL.getTypeStoreSize(Ty).getFixedValue();
}

bool IsAllowedStackPtrUse(Instruction &I, Value *val) {
  if (auto *LI = dyn_cast<LoadInst>(&I)) {
    return LI->getPointerOperand() == val;
  }
  if (auto *SI = dyn_cast<StoreInst>(&I)) {
    return SI->getPointerOperand() == val;
  }
  if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
    return GEP->getPointerOperand() == val;
  }
  if (auto *BC = dyn_cast<BitCastInst>(&I)) {
    return BC->getOperand(0) == val;
  }
  if (auto *ASC = dyn_cast<AddrSpaceCastInst>(&I)) {
    return ASC->getOperand(0) == val;
  }
  return false;
}

bool HasEscapingStackPtr(Function &F, DataLayout const &DL, SmallPtrSetImpl<Value*> const &Bases, DenseSet<int64_t> &EscapedSlots) {
  bool Escaped = false;
  for (auto &I : instructions(F)) {
    for (auto &U : I.operands()) {
      Value *V = U.get();
      if (V && V->getType()->isPointerTy()) {
        if (auto Offset = ResolveStackPtr(V, DL, Bases)) {
          if (!IsAllowedStackPtrUse(I, V)) {
            EscapedSlots.insert(*Offset);
            Escaped = true;
          }
        }
      }
    }
  }
  return Escaped;
}

void CollectSlots(Function &F, DataLayout const &DL, DenseMap<int64_t, SlotInfo> &Slots, SmallPtrSetImpl<Value*> const &Bases, DenseSet<int64_t> &EscapedSlots) {
  for (auto &I : instructions(F)) {
    Value *Ptr = nullptr;
    Type *Ty = nullptr;
    Align Align;
    bool IsStore = false;

    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      if (LI->isVolatile() || LI->isAtomic()) continue;
      Ptr = LI->getPointerOperand();
      Ty = LI->getType();
      Align = LI->getAlign();
      IsStore = false;
    } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (SI->isVolatile() || SI->isAtomic()) continue;
      Ptr = SI->getPointerOperand();
      Ty = SI->getValueOperand()->getType();
      Align = SI->getAlign();
      IsStore = true;
    }

    if (!Ptr) continue;

    if (auto Offset = ResolveStackPtr(Ptr, DL, Bases)) {
      if (*Offset == 0) continue;

      if (EscapedSlots.contains(*Offset)) continue;

      if (IsScalarSlotType(Ty, DL)) {
        if (IsStore && *Offset > 0) {
          EscapedSlots.insert(*Offset);
          continue;
        }

        auto &Slot = Slots[*Offset];
        if (Slot.Ty != nullptr) {
          if (Slot.Ty == Ty) {
            Slot.Alignment = std::max(Slot.Alignment, Align);
          } else {
            EscapedSlots.insert(*Offset);
            continue;
          }
        } else {
          Slot.Offset = *Offset;
          Slot.Ty = Ty;
          Slot.Alignment = Align;
        }

        Slot.Accesses.push_back({&I, IsStore});
        if (IsStore) {
          Slot.Stores.push_back(cast<StoreInst>(&I));
        } else {
          Slot.Loads.push_back(cast<LoadInst>(&I));
        }
      } else {
        EscapedSlots.insert(*Offset);
      }
    }
  }

  SmallVector<int64_t, 16> SlotOffsets;
  for (auto &Entry : Slots) {
    SlotOffsets.push_back(Entry.first);
  }

  for (size_t i = 0; i < SlotOffsets.size(); ++i) {
    int64_t Offset1 = SlotOffsets[i];
    auto it1 = Slots.find(Offset1);
    if (it1 == Slots.end()) continue;
    uint64_t Size1 = SlotSize(it1->second.Ty, DL);

    for (size_t j = 0; j < SlotOffsets.size(); ++j) {
      int64_t Offset2 = SlotOffsets[j];
      if (Offset1 < Offset2) {
        auto it2 = Slots.find(Offset2);
        if (it2 == Slots.end()) continue;
        if (Offset1 + Size1 > Offset2) {
          EscapedSlots.insert(Offset1);
          EscapedSlots.insert(Offset2);
        }
      }
    }
  }
}

bool IsBoundaryInstruction(Instruction &I) {
  if (auto *CB = dyn_cast<CallBase>(&I)) {
    return IsBoundaryCall(*CB);
  }
  return false;
}

int LocalStateUntil(BasicBlock *BB, Instruction *Until, SmallPtrSetImpl<Instruction*> const &Stores) {
  int State = 0; // 0: None, 1: Store, 2: Boundary
  for (auto &I : *BB) {
    if (&I == Until) {
      break;
    }
    if (IsBoundaryInstruction(I)) {
      State = 2;
    } else if (Stores.contains(&I)) {
      State = 1;
    }
  }
  return State;
}

bool BlockEndCovered(BasicBlock *BB, SmallPtrSetImpl<Instruction*> const &Stores, DenseMap<BasicBlock*, bool> &Visited, SmallPtrSetImpl<BasicBlock*> &ActivePath) {
  if (!BB) return false;
  auto it = Visited.find(BB);
  if (it != Visited.end()) {
    return it->second;
  }
  ActivePath.insert(BB);
  int State = LocalStateUntil(BB, nullptr, Stores);
  bool Covered = false;
  if (State == 1) {
    Covered = true;
  } else if (State == 2) {
    Covered = false;
  } else {
    if (pred_empty(BB)) {
      Covered = false;
    } else {
      Covered = true;
      for (auto *Pred : predecessors(BB)) {
        if (!BlockEndCovered(Pred, Stores, Visited, ActivePath)) {
          Covered = false;
          break;
        }
      }
    }
  }
  ActivePath.erase(BB);
  Visited[BB] = Covered;
  return Covered;
}

bool LoadCoveredByStores(LoadInst *LI, SmallPtrSetImpl<Instruction*> const &Stores) {
  BasicBlock *BB = LI->getParent();
  int State = LocalStateUntil(BB, LI, Stores);
  if (State == 1) {
    return true;
  }
  if (State == 2) {
    return false;
  }
  if (pred_empty(BB)) {
    return false;
  }
  for (auto *Pred : predecessors(BB)) {
    SmallPtrSet<BasicBlock*, 16> ActivePath;
    DenseMap<BasicBlock*, bool> Visited;
    if (!BlockEndCovered(Pred, Stores, Visited, ActivePath)) {
      return false;
    }
  }
  return true;
}

bool LoadsDominatedByStores(SlotInfo &Slot) {
  if (Slot.Offset < 0) {
    return true;
  }
  if (Slot.Stores.empty()) {
    return false;
  }
  SmallPtrSet<Instruction*, 8> StoresSet;
  for (auto *SI : Slot.Stores) {
    StoresSet.insert(SI);
  }
  for (auto *LI : Slot.Loads) {
    if (!LoadCoveredByStores(LI, StoresSet)) {
      return false;
    }
  }
  return true;
}

bool FunctionHasBoundaryCall(Function &F) {
  for (auto &I : instructions(F)) {
    if (IsBoundaryInstruction(I)) {
      return true;
    }
  }
  return false;
}

std::optional<int64_t> ComputeFrameLowWatermark(Function &F, const DataLayout &DL, SmallPtrSetImpl<Value*> const &Bases) {
  std::optional<int64_t> Watermark;

  for (auto &I : instructions(F)) {
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (IsRspOffset(SI->getPointerOperand(), DL)) {
        SmallPtrSet<Value*, 8> Visited;
        if (auto Offset = EvalRspOffset(SI->getValueOperand(), Visited, Bases)) {
          if (*Offset < 0) {
            if (!Watermark || *Offset < *Watermark) {
              Watermark = *Offset;
            }
          }
        }
      }
    }
  }

  for (auto &I : instructions(F)) {
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (auto *Callee = CB->getCalledFunction()) {
        if (!Callee->isDeclaration() && !Callee->isIntrinsic()) {
          for (auto &Arg : Callee->args()) {
            if (LooksLikeRspArgument(Arg)) {
              unsigned ArgNo = Arg.getArgNo();
              if (ArgNo < CB->arg_size()) {
                SmallPtrSet<Value*, 8> Visited;
                if (auto Offset = EvalRspOffset(CB->getArgOperand(ArgNo), Visited, Bases)) {
                  if (*Offset < 0) {
                    if (!Watermark || *Offset < *Watermark) {
                      Watermark = *Offset;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  return Watermark;
}

bool IsReservedFrameOffset(int64_t Offset, std::optional<int64_t> LowWatermark) {
  if (LowWatermark) {
    return Offset < 0 && *LowWatermark <= Offset;
  }
  return false;
}

DenseMap<BasicBlock*, bool> ComputeBoundaryReachability(Function &F) {
  DenseMap<BasicBlock*, bool> Reachable;
  for (auto &BB : F) {
    bool HasBoundary = false;
    for (auto &I : BB) {
      if (IsBoundaryInstruction(I)) {
        HasBoundary = true;
        break;
      }
    }
    Reachable[&BB] = HasBoundary;
  }

  bool Changed = true;
  while (Changed) {
    Changed = false;
    for (auto &BB : F) {
      if (!Reachable[&BB]) {
        for (auto *Succ : successors(&BB)) {
          if (Reachable[Succ]) {
            Reachable[&BB] = true;
            Changed = true;
            break;
          }
        }
      }
    }
  }
  return Reachable;
}

bool BoundaryReachableAfter(Instruction *I, DenseMap<BasicBlock*, bool> const &BoundaryReachability) {
  if (!I) return true;
  BasicBlock *BB = I->getParent();
  if (!BB) return true;

  auto it = std::next(I->getIterator());
  for (auto ie = BB->end(); it != ie; ++it) {
    if (IsBoundaryInstruction(*it)) {
      return true;
    }
  }

  if (succ_empty(BB)) {
    return false;
  }

  for (auto *Succ : successors(BB)) {
    if (BoundaryReachability.lookup(Succ)) {
      return true;
    }
  }
  return false;
}

bool SlotCanReachBoundaryAfterAccess(SlotInfo &Slot, DenseMap<BasicBlock*, bool> const &BoundaryReachability) {
  for (auto &Access : Slot.Accesses) {
    if (BoundaryReachableAfter(Access.Inst, BoundaryReachability)) {
      return true;
    }
  }
  return false;
}

bool PromoteFunction(Function &F, DataLayout const &DL) {
  if (F.isDeclaration() || F.empty()) {
    return false;
  }
  if (ShouldSkipFunction(F)) {
    return false;
  }

  SmallPtrSet<Value*, 4> Bases;
  CollectFrameBases(F, DL, Bases);
  if (Bases.empty()) {
    CollectArgumentFrameBases(F, DL, Bases);
  }
  if (Bases.empty()) {
    return false;
  }

  bool HasBoundary = FunctionHasBoundaryCall(F);
  auto LowWatermark = ComputeFrameLowWatermark(F, DL, Bases);

  if (HasBoundary && !AllowBoundaryCrossing() && !LowWatermark.has_value()) {
    return false;
  }

  DenseMap<BasicBlock*, bool> Reachability;
  if (HasBoundary && AllowBoundaryCrossing()) {
    Reachability = ComputeBoundaryReachability(F);
  }

  DenseSet<int64_t> EscapedSlots;
  HasEscapingStackPtr(F, DL, Bases, EscapedSlots);

  DenseMap<int64_t, SlotInfo> Slots;
  CollectSlots(F, DL, Slots, Bases, EscapedSlots);

  if (Slots.empty()) {
    return false;
  }

  SmallVector<int64_t, 16> EraseSlots;
  for (auto &Entry : Slots) {
    int64_t Offset = Entry.first;
    SlotInfo &Slot = Entry.second;
    bool Escape = false;
    if (HasBoundary) {
      if (!AllowBoundaryCrossing()) {
        Escape = !IsReservedFrameOffset(Offset, LowWatermark);
      } else {
        Escape = SlotCanReachBoundaryAfterAccess(Slot, Reachability);
      }
    }
    if (EscapedSlots.contains(Offset) || Escape || Slot.Ty == nullptr) {
      EraseSlots.push_back(Offset);
    }
  }

  for (int64_t Offset : EraseSlots) {
    Slots.erase(Offset);
  }

  if (Slots.empty()) {
    return false;
  }

  BasicBlock &EntryBB = F.getEntryBlock();
  Instruction *EntryIP = &*EntryBB.getFirstInsertionPt();
  IRBuilder<> AllocaBuilder(EntryIP);

  Value *BaseVal = *Bases.begin();
  Instruction *BaseInst = dyn_cast<Instruction>(BaseVal);
  Instruction *InitIP = nullptr;
  if (BaseInst) {
    InitIP = BaseInst->getNextNode();
  } else {
    InitIP = &*EntryBB.getFirstInsertionPt();
  }
  IRBuilder<> InitBuilder(InitIP);

  SmallVector<AllocaInst*, 16> SlotAllocas;
  SmallVector<Instruction*, 64> ErasedInstructions;

  for (auto &Entry : Slots) {
    int64_t Offset = Entry.first;
    SlotInfo &Slot = Entry.second;

    AllocaInst *Alloca = AllocaBuilder.CreateAlloca(
        Slot.Ty, nullptr, "stack_" + Twine(Offset) + ".slot");
    Slot.Alloca = Alloca;

    if (!LoadsDominatedByStores(Slot)) {
      Value *Addr = BaseVal;
      if (Offset != 0) {
        Addr = InitBuilder.CreateAdd(
            BaseVal,
            ConstantInt::get(BaseVal->getType(), Offset, true),
            "stack_" + Twine(Offset) + ".addr");
      }
      Value *Ptr = InitBuilder.CreateIntToPtr(
          Addr, InitBuilder.getPtrTy(), "stack_" + Twine(Offset) + ".ptr");
      LoadInst *InitVal = InitBuilder.CreateLoad(
          Slot.Ty, Ptr, "stack_" + Twine(Offset) + ".init");
      InitVal->setAlignment(Slot.Alignment);
      StoreInst *SI = InitBuilder.CreateStore(InitVal, Alloca);
      SI->setAlignment(Slot.Alignment);
    }
    SlotAllocas.push_back(Alloca);
  }

  for (auto &Entry : Slots) {
    int64_t Offset = Entry.first;
    SlotInfo &Slot = Entry.second;

    for (auto &Access : Slot.Accesses) {
      Instruction *I = Access.Inst;
      if (!I->getParent()) continue;

      IRBuilder<> AccessBuilder(I);
      if (!Access.IsStore) {
        auto *LI = cast<LoadInst>(I);
        LoadInst *NewLoad = AccessBuilder.CreateLoad(
            Slot.Ty, Slot.Alloca, "stack_" + Twine(Offset) + ".ssa");
        NewLoad->setAlignment(LI->getAlign());
        LI->replaceAllUsesWith(NewLoad);
        ErasedInstructions.push_back(LI);
      } else {
        auto *SI = cast<StoreInst>(I);
        StoreInst *NewStore = AccessBuilder.CreateStore(
            SI->getValueOperand(), Slot.Alloca);
        NewStore->setAlignment(SI->getAlign());
        ErasedInstructions.push_back(SI);
      }
    }
  }

  for (auto *I : ErasedInstructions) {
    I->eraseFromParent();
  }

  DominatorTree DT(F);
  AssumptionCache AC(F);
  PromoteMemToReg(SlotAllocas, DT, &AC);

  if (TraceEnabled()) {
    errs() << "brighten-stack-ssa-pass function=" << F.getName()
           << " slots=" << Slots.size()
           << " erased=" << ErasedInstructions.size() << "\n";
  }

  return true;
}

struct BrightenStackSSAPass : public PassInfoMixin<BrightenStackSSAPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    bool Changed = false;
    for (auto &F : M) {
      Changed |= PromoteFunction(F, M.getDataLayout());
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
    LLVM_PLUGIN_API_VERSION,
    "BrightenStackSSAPass",
    LLVM_VERSION_STRING,
    [](PassBuilder &PB) {
      PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "brighten-stack-ssa-pass") {
            MPM.addPass(BrightenStackSSAPass());
            return true;
          }
          return false;
        }
      );
    }
  };
}
