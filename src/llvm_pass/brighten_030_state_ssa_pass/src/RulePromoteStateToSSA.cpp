#include "BrightenStateSSAPass.h"
#include "StateOffsetResolver.h"
#include "../../common/StateSliceSemantics.h"

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Metadata.h"
#include "llvm/Support/Alignment.h"
#include "llvm/Support/TypeSize.h"

#include <algorithm>
#include <cstdint>
#include <limits>
#include <optional>

namespace brighten_state_ssa {

using namespace llvm;
using brighten_state_semantics::StateSlice;
using brighten_state_semantics::WriteKind;
using brighten_state_semantics::classifyArchitecturalSlice;
using brighten_state_semantics::classifyFallbackSlice;

namespace {

enum class AccessKind {
  Load,
  Store,
};

struct StateAccess {
  Instruction *Inst = nullptr;
  Type *Ty = nullptr;
  StateSlice Slice;
  AccessKind Kind = AccessKind::Load;
};

struct StateCell {
  uint64_t BaseOffset = 0;
  unsigned CellBits = 0;
  bool Architectural = false;
  SmallVector<StateAccess, 8> Accesses;
};

static unsigned fixedStoreBits(Type *Ty, const DataLayout &DL) {
  if (!Ty || !Ty->isSized())
    return 0;
  TypeSize Bytes = DL.getTypeStoreSize(Ty);
  if (Bytes.isScalable() || Bytes.getFixedValue() > UINT_MAX / 8)
    return 0;
  return static_cast<unsigned>(Bytes.getFixedValue() * 8);
}

static Value *resizeInteger(IRBuilder<> &B, Value *V, unsigned Bits,
                            const Twine &Name) {
  auto *SrcTy = dyn_cast<IntegerType>(V->getType());
  if (!SrcTy || !Bits)
    return nullptr;
  IntegerType *DstTy = IntegerType::get(B.getContext(), Bits);
  if (SrcTy == DstTy)
    return V;
  if (SrcTy->getBitWidth() > Bits)
    return B.CreateTrunc(V, DstTy, Name);
  return B.CreateZExt(V, DstTy, Name);
}

static Value *toIntegerBits(IRBuilder<> &B, Value *V, unsigned Bits,
                            const DataLayout &DL, const Twine &Name) {
  if (!V || !Bits)
    return nullptr;
  Type *Ty = V->getType();
  if (Ty->isIntegerTy())
    return resizeInteger(B, V, Bits, Name);
  if (Ty->isPointerTy()) {
    unsigned PointerBits = DL.getPointerSizeInBits(
        cast<PointerType>(Ty)->getAddressSpace());
    Value *Integer = B.CreatePtrToInt(
        V, IntegerType::get(B.getContext(), PointerBits), Name + ".ptr");
    return resizeInteger(B, Integer, Bits, Name);
  }
  unsigned SourceBits = fixedStoreBits(Ty, DL);
  if (!SourceBits ||
      !(Ty->isFloatingPointTy() || isa<FixedVectorType>(Ty)))
    return nullptr;
  Value *Integer = B.CreateBitCast(
      V, IntegerType::get(B.getContext(), SourceBits), Name + ".bits");
  return resizeInteger(B, Integer, Bits, Name);
}

static Value *fromIntegerBits(IRBuilder<> &B, Value *V, Type *Ty,
                              const DataLayout &DL, const Twine &Name) {
  if (!V || !V->getType()->isIntegerTy() || !Ty)
    return nullptr;
  if (Ty->isIntegerTy())
    return resizeInteger(B, V, cast<IntegerType>(Ty)->getBitWidth(), Name);
  if (Ty->isPointerTy()) {
    unsigned PointerBits = DL.getPointerSizeInBits(
        cast<PointerType>(Ty)->getAddressSpace());
    Value *Integer = resizeInteger(B, V, PointerBits, Name + ".ptrbits");
    return Integer ? B.CreateIntToPtr(Integer, Ty, Name) : nullptr;
  }
  unsigned DestinationBits = fixedStoreBits(Ty, DL);
  if (!DestinationBits ||
      !(Ty->isFloatingPointTy() || isa<FixedVectorType>(Ty)))
    return nullptr;
  Value *Integer = resizeInteger(B, V, DestinationBits, Name + ".bits");
  return Integer ? B.CreateBitCast(Integer, Ty, Name) : nullptr;
}

static Value *statePointer(IRBuilder<> &B, Value *State, uint64_t Offset,
                           const Twine &Name) {
  return B.CreateConstGEP1_64(B.getInt8Ty(), State, Offset, Name);
}

static LoadInst *createUnalignedLoad(IRBuilder<> &B, Type *Ty, Value *Ptr,
                                     const Twine &Name) {
  LoadInst *Load = B.CreateLoad(Ty, Ptr, Name);
  Load->setAlignment(Align(1));
  return Load;
}

static StoreInst *createUnalignedStore(IRBuilder<> &B, Value *V, Value *Ptr) {
  StoreInst *Store = B.CreateStore(V, Ptr);
  Store->setAlignment(Align(1));
  return Store;
}

static bool intervalsOverlap(uint64_t AOffset, unsigned ABits,
                             uint64_t BOffset, unsigned BBits) {
  uint64_t ABytes = ABits / 8;
  uint64_t BBytes = BBits / 8;
  if (!ABytes || !BBytes || AOffset > UINT64_MAX - ABytes ||
      BOffset > UINT64_MAX - BBytes)
    return true;
  return AOffset < BOffset + BBytes && BOffset < AOffset + ABytes;
}

static Value *buildStoredCellValue(IRBuilder<> &B, Value *Stored,
                                   const StateSlice &Slice, IntegerType *CellTy,
                                   Value *CellPtr, const DataLayout &DL) {
  Value *Bits = toIntegerBits(B, Stored, Slice.AccessBits, DL,
                              "state.store.bits");
  if (!Bits)
    return nullptr;

  if (Slice.StoreKind == WriteKind::ZeroExtend) {
    if (Slice.BitOffset != 0 || Slice.AccessBits >= Slice.CellBits)
      return nullptr;
    return B.CreateZExt(Bits, CellTy, "state.gpr32.zero_extend");
  }

  if (Slice.StoreKind == WriteKind::Replace && Slice.BitOffset == 0)
    return resizeInteger(B, Bits, Slice.CellBits, "state.store.replace");

  if (Slice.StoreKind != WriteKind::Merge ||
      Slice.AccessBits > Slice.CellBits - Slice.BitOffset)
    return nullptr;

  Value *Wide = resizeInteger(B, Bits, Slice.CellBits, "state.store.wide");
  if (!Wide)
    return nullptr;
  if (Slice.BitOffset)
    Wide = B.CreateShl(
        Wide, ConstantInt::get(CellTy, Slice.BitOffset),
        "state.store.shifted");

  APInt Mask = APInt::getLowBitsSet(Slice.CellBits, Slice.AccessBits);
  if (Slice.BitOffset)
    Mask <<= Slice.BitOffset;
  Value *Old = B.CreateLoad(CellTy, CellPtr, "state.store.old");
  Value *Keep = B.CreateAnd(
      Old, ConstantInt::get(CellTy, ~Mask), "state.store.keep");
  return B.CreateOr(Keep, Wide, "state.store.merge");
}

} // namespace

bool BrightenStateSSAPass::PromoteStateToSSA(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  LLVMContext &Ctx = M.getContext();
  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");

  for (Function &F : M) {
    if (F.isDeclaration() || !IsLiftedFunction(F))
      continue;

    // State promotion is an exact memory-model rewrite.  EH/control-flow calls
    // and inline assembly need a separate memory-effect model; do not guess.
    bool UnsupportedBoundary = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (isa<InvokeInst>(I) || isa<CallBrInst>(I)) {
          UnsupportedBoundary = true;
          break;
        }
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          if (CI->isMustTailCall() || CI->isInlineAsm()) {
            UnsupportedBoundary = true;
            break;
          }
        }
      }
      if (UnsupportedBoundary)
        break;
    }
    if (UnsupportedBoundary ||
        FunctionHasUnsupportedStateBoundary(F, StateGV, DL))
      continue;

    DenseMap<uint64_t, StateCell> Cells;
    DenseSet<uint64_t> InvalidCells;
    std::optional<StateBaseKind> FunctionBase;
    bool MixedStateBases = false;
    bool UnsupportedStateAccess = false;

    auto recordAccess = [&](Instruction &I, Value *Ptr, Type *Ty,
                            AccessKind Kind, bool IsVolatile,
                            bool IsAtomic) {
      auto Resolved = ResolveStateOffset(Ptr, DL, F, StateGV);
      if (!Resolved || Resolved->Offset > std::numeric_limits<unsigned>::max())
        return;
      if (!FunctionBase)
        FunctionBase = Resolved->Base;
      else if (*FunctionBase != Resolved->Base)
        MixedStateBases = true;

      unsigned AccessBits = fixedStoreBits(Ty, DL);
      if (IsVolatile || IsAtomic || !AccessBits || AccessBits % 8) {
        UnsupportedStateAccess = true;
        return;
      }

      StateSlice Slice;
      if (auto Architectural =
              classifyArchitecturalSlice(Resolved->Offset, AccessBits)) {
        Slice = *Architectural;
      } else {
        Slice = classifyFallbackSlice(Resolved->Offset, AccessBits, AccessBits);
      }

      StateCell &Cell = Cells[Slice.BaseOffset];
      if (!Cell.CellBits) {
        Cell.BaseOffset = Slice.BaseOffset;
        Cell.CellBits = Slice.CellBits;
        Cell.Architectural = Slice.Architectural;
      } else if (Cell.Architectural != Slice.Architectural) {
        InvalidCells.insert(Slice.BaseOffset);
      } else if (Slice.Architectural && Cell.CellBits != Slice.CellBits) {
        InvalidCells.insert(Slice.BaseOffset);
      } else if (!Slice.Architectural) {
        Cell.CellBits = std::max(Cell.CellBits, Slice.AccessBits);
      }
      Cell.Accesses.push_back(StateAccess{&I, Ty, Slice, Kind});
    };

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          recordAccess(I, LI->getPointerOperand(), LI->getType(),
                       AccessKind::Load, LI->isVolatile(), LI->isAtomic());
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          recordAccess(I, SI->getPointerOperand(),
                       SI->getValueOperand()->getType(), AccessKind::Store,
                       SI->isVolatile(), SI->isAtomic());
        }
      }
    }

    if (MixedStateBases || UnsupportedStateAccess || !FunctionBase ||
        Cells.empty())
      continue;

    // Unknown byte ranges are promoted only when they form disjoint cells.
    // Known GPR/XMM aliases intentionally share one architectural cell.
    SmallVector<uint64_t, 32> Bases;
    for (const auto &Entry : Cells)
      Bases.push_back(Entry.first);
    for (unsigned I = 0; I < Bases.size(); ++I) {
      StateCell &A = Cells[Bases[I]];
      for (unsigned J = I + 1; J < Bases.size(); ++J) {
        StateCell &B = Cells[Bases[J]];
        if (intervalsOverlap(A.BaseOffset, A.CellBits,
                             B.BaseOffset, B.CellBits)) {
          InvalidCells.insert(A.BaseOffset);
          InvalidCells.insert(B.BaseOffset);
        }
      }
    }
    for (uint64_t Base : InvalidCells)
      Cells.erase(Base);
    if (Cells.empty())
      continue;

    for (auto &Entry : Cells) {
      StateCell &Cell = Entry.second;
      for (StateAccess &Access : Cell.Accesses) {
        if (!Access.Slice.Architectural) {
          Access.Slice.CellBits = Cell.CellBits;
          Access.Slice.StoreKind =
              Access.Slice.AccessBits == Cell.CellBits
                  ? WriteKind::Replace
                  : WriteKind::Merge;
        }
      }
    }

    Value *StatePtr = *FunctionBase == StateBaseKind::Arg0
                          ? static_cast<Value *>(F.getArg(0))
                          : static_cast<Value *>(StateGV);
    if (!StatePtr)
      continue;

    IRBuilder<> EntryBuilder(&*F.getEntryBlock().getFirstInsertionPt());
    DenseMap<uint64_t, AllocaInst *> CellAllocas;
    DenseMap<uint64_t, IntegerType *> CellTypes;
    for (auto &Entry : Cells) {
      StateCell &Cell = Entry.second;
      IntegerType *CellTy = IntegerType::get(Ctx, Cell.CellBits);
      AllocaInst *Alloca = EntryBuilder.CreateAlloca(
          CellTy, nullptr, "state_cell_" + std::to_string(Cell.BaseOffset));
      Alloca->setMetadata(
          "brighten.state.offset",
          MDNode::get(Ctx, ConstantAsMetadata::get(ConstantInt::get(
                               Type::getInt64Ty(Ctx), Cell.BaseOffset))));
      CellAllocas[Cell.BaseOffset] = Alloca;
      CellTypes[Cell.BaseOffset] = CellTy;
    }

    auto InsertIt = F.getEntryBlock().getFirstInsertionPt();
    while (InsertIt != F.getEntryBlock().end() && isa<AllocaInst>(*InsertIt))
      ++InsertIt;
    IRBuilder<> InitBuilder(&*InsertIt);
    for (auto &Entry : Cells) {
      uint64_t Base = Entry.first;
      IntegerType *CellTy = CellTypes[Base];
      Value *Ptr = statePointer(InitBuilder, StatePtr, Base,
                                "state.cell.init.ptr");
      Value *Initial = createUnalignedLoad(
          InitBuilder, CellTy, Ptr, "state.cell.init");
      InitBuilder.CreateStore(Initial, CellAllocas[Base]);
    }

    bool RewriteFailed = false;
    for (auto &Entry : Cells) {
      uint64_t Base = Entry.first;
      IntegerType *CellTy = CellTypes[Base];
      Value *CellPtr = CellAllocas[Base];
      for (StateAccess &Access : Entry.second.Accesses) {
        if (!Access.Inst->getParent())
          continue;
        if (Access.Kind == AccessKind::Load) {
          auto *LI = cast<LoadInst>(Access.Inst);
          IRBuilder<> B(LI);
          Value *Bits = B.CreateLoad(CellTy, CellPtr, "state.cell.load");
          if (Access.Slice.BitOffset)
            Bits = B.CreateLShr(
                Bits, ConstantInt::get(CellTy, Access.Slice.BitOffset),
                "state.slice.shift");
          Bits = resizeInteger(B, Bits, Access.Slice.AccessBits,
                               "state.slice.bits");
          Value *Replacement =
              fromIntegerBits(B, Bits, Access.Ty, DL, "state.slice.value");
          if (!Replacement) {
            RewriteFailed = true;
            break;
          }
          LI->replaceAllUsesWith(Replacement);
          LI->eraseFromParent();
        } else {
          auto *SI = cast<StoreInst>(Access.Inst);
          IRBuilder<> B(SI);
          Value *NewValue = buildStoredCellValue(
              B, SI->getValueOperand(), Access.Slice, CellTy, CellPtr, DL);
          if (!NewValue) {
            RewriteFailed = true;
            break;
          }
          B.CreateStore(NewValue, CellPtr);
          SI->eraseFromParent();
        }
      }
      if (RewriteFailed)
        break;
    }

    // Every access was validated before mutation, so failure here indicates an
    // unsupported LLVM type.  Abort rather than emit a partially rewritten
    // State model that would mix the old bytes with new SSA cells.
    if (RewriteFailed)
      report_fatal_error("brighten-state-ssa: unsupported State slice coercion");

    auto flushCells = [&](IRBuilder<> &B) {
      for (auto &Entry : Cells) {
        uint64_t Base = Entry.first;
        IntegerType *CellTy = CellTypes[Base];
        Value *Value = B.CreateLoad(CellTy, CellAllocas[Base],
                                    "state.cell.flush");
        Value *Ptr = statePointer(B, StatePtr, Base, "state.cell.flush.ptr");
        createUnalignedStore(B, Value, Ptr);
      }
    };
    auto reloadCells = [&](IRBuilder<> &B) {
      for (auto &Entry : Cells) {
        uint64_t Base = Entry.first;
        IntegerType *CellTy = CellTypes[Base];
        Value *Ptr = statePointer(B, StatePtr, Base, "state.cell.reload.ptr");
        Value *Value = createUnalignedLoad(
            B, CellTy, Ptr, "state.cell.reload");
        B.CreateStore(Value, CellAllocas[Base]);
      }
    };

    for (BasicBlock &BB : F) {
      for (auto It = BB.begin(); It != BB.end();) {
        Instruction &I = *It++;
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || !CallMayAccessState(CI, F, StateGV, DL))
          continue;
        IRBuilder<> Before(CI);
        flushCells(Before);
        IRBuilder<> After(CI->getNextNode());
        reloadCells(After);
      }
    }

    for (BasicBlock &BB : F) {
      if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator())) {
        IRBuilder<> B(RI);
        flushCells(B);
      }
    }

    Changed = true;
  }

  return Changed;
}

} // namespace brighten_state_ssa
