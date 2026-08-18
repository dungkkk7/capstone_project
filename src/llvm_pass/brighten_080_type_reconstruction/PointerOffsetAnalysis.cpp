#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"

#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/TypeSize.h"

#include <cstdint>
#include <limits>
#include <optional>
#include <set>
#include <tuple>

namespace brighten_type {

using namespace llvm;

namespace {

struct TraceState {
  Value *V = nullptr;
  int64_t Offset = 0;
  Value *Index = nullptr;
  int64_t Stride = 0;

  bool operator<(const TraceState &Other) const {
    return std::tie(V, Offset, Index, Stride) <
           std::tie(Other.V, Other.Offset, Other.Index, Other.Stride);
  }
};

static bool checkedAdd(int64_t A, int64_t B, int64_t &Out) {
  __int128 Sum = static_cast<__int128>(A) + static_cast<__int128>(B);
  if (Sum < std::numeric_limits<int64_t>::min() ||
      Sum > std::numeric_limits<int64_t>::max())
    return false;
  Out = static_cast<int64_t>(Sum);
  return true;
}

static bool checkedMul(int64_t A, int64_t B, int64_t &Out) {
  __int128 Product = static_cast<__int128>(A) * static_cast<__int128>(B);
  if (Product < std::numeric_limits<int64_t>::min() ||
      Product > std::numeric_limits<int64_t>::max())
    return false;
  Out = static_cast<int64_t>(Product);
  return true;
}

static std::optional<uint64_t> fixedAllocSize(Type *Ty, const DataLayout &DL) {
  if (!Ty || !Ty->isSized())
    return std::nullopt;
  TypeSize Size = DL.getTypeAllocSize(Ty);
  if (Size.isScalable())
    return std::nullopt;
  return Size.getFixedValue();
}

static std::optional<uint64_t> fixedStoreSize(Type *Ty, const DataLayout &DL) {
  if (!Ty || !Ty->isSized())
    return std::nullopt;
  TypeSize Size = DL.getTypeStoreSize(Ty);
  if (Size.isScalable())
    return std::nullopt;
  return Size.getFixedValue();
}

static void reject(ObjectCandidate &Cand, StringRef Reason) {
  std::string Text = Reason.str();
  if (!is_contained(Cand.RejectionReasons, Text))
    Cand.RejectionReasons.push_back(std::move(Text));
  Cand.Escaped = true;
}

// Normalize one affine expression to BaseIndex * Stride + Constant.  A bare
// SSA value is a valid symbolic index.  Once arithmetic is present, every
// operation must be affine with a compile-time constant.  In particular,
// `shl %idx, %idx`, division, remainder, bitwise masking and select/phi are not
// reclassified as arrays merely because they have an integer type.
static bool resolveAffineIndex(Value *Idx, int64_t CurrentStride,
                               int64_t &ConstantOffset,
                               int64_t &FinalStride, Value *&FinalIndex,
                               unsigned Depth = 0) {
  if (!Idx || Depth > 16)
    return false;

  if (auto *Cast = dyn_cast<CastInst>(Idx)) {
    if (Cast->getOpcode() == Instruction::ZExt ||
        Cast->getOpcode() == Instruction::SExt)
      return resolveAffineIndex(Cast->getOperand(0), CurrentStride,
                                ConstantOffset, FinalStride, FinalIndex,
                                Depth + 1);
    return false;
  }

  auto *BO = dyn_cast<BinaryOperator>(Idx);
  if (!BO) {
    if (FinalIndex && FinalIndex != Idx)
      return false;
    FinalIndex = Idx;
    FinalStride = CurrentStride;
    return CurrentStride > 0;
  }

  Value *LHS = BO->getOperand(0);
  Value *RHS = BO->getOperand(1);
  ConstantInt *LC = dyn_cast<ConstantInt>(LHS);
  ConstantInt *RC = dyn_cast<ConstantInt>(RHS);

  int64_t Updated = 0;
  switch (BO->getOpcode()) {
  case Instruction::Add:
    if (RC && checkedMul(RC->getSExtValue(), CurrentStride, Updated) &&
        checkedAdd(ConstantOffset, Updated, ConstantOffset))
      return resolveAffineIndex(LHS, CurrentStride, ConstantOffset,
                                FinalStride, FinalIndex, Depth + 1);
    if (LC && checkedMul(LC->getSExtValue(), CurrentStride, Updated) &&
        checkedAdd(ConstantOffset, Updated, ConstantOffset))
      return resolveAffineIndex(RHS, CurrentStride, ConstantOffset,
                                FinalStride, FinalIndex, Depth + 1);
    return false;
  case Instruction::Sub:
    if (!RC ||
        !checkedMul(RC->getSExtValue(), CurrentStride, Updated) ||
        Updated == std::numeric_limits<int64_t>::min() ||
        !checkedAdd(ConstantOffset, -Updated, ConstantOffset))
      return false;
    return resolveAffineIndex(LHS, CurrentStride, ConstantOffset,
                              FinalStride, FinalIndex, Depth + 1);
  case Instruction::Mul:
    if (RC && checkedMul(CurrentStride, RC->getSExtValue(), Updated))
      return resolveAffineIndex(LHS, Updated, ConstantOffset, FinalStride,
                                FinalIndex, Depth + 1);
    if (LC && checkedMul(CurrentStride, LC->getSExtValue(), Updated))
      return resolveAffineIndex(RHS, Updated, ConstantOffset, FinalStride,
                                FinalIndex, Depth + 1);
    return false;
  case Instruction::Shl:
    if (!RC || RC->getValue().uge(63))
      return false;
    if (!checkedMul(CurrentStride,
                    static_cast<int64_t>(uint64_t{1}
                                         << RC->getZExtValue()),
                    Updated))
      return false;
    return resolveAffineIndex(LHS, Updated, ConstantOffset, FinalStride,
                              FinalIndex, Depth + 1);
  default:
    return false;
  }
}

static void addLoadStoreFact(ObjectCandidate &Cand, TypeReconstructionContext &Ctx,
                             Instruction *Inst, Type *Ty, bool IsWrite,
                             int64_t Offset, Value *IndexExpr, int64_t Stride,
                             Align Alignment, bool IsVolatile, bool IsAtomic,
                             AtomicOrdering Ordering,
                             SyncScope::ID SyncScope) {
  auto Size = fixedStoreSize(Ty, Ctx.DL);
  if (!Size) {
    reject(Cand, "scalable-or-unsized-access");
    return;
  }

  AccessFact Fact;
  Fact.BaseObject = Cand.BaseVal;
  Fact.ConstantOffset = Offset;
  Fact.DynamicIndexExpr = IndexExpr;
  Fact.Stride = Stride;
  Fact.AccessSize = *Size;
  Fact.ObservedType = Ty;
  Fact.IsWrite = IsWrite;
  Fact.Alignment = Alignment;
  Fact.IsVolatile = IsVolatile;
  Fact.IsAtomic = IsAtomic;
  Fact.Ordering = Ordering;
  Fact.SyncScope = SyncScope;
  Fact.SourceInst = Inst;
  Fact.Kind = IndexExpr ? EvidenceKind::AffineArray
                        : EvidenceKind::LoadStoreType;
  Fact.IsPointerClue = Ty->isPointerTy();
  Fact.IsFloatClue = Ty->isFloatingPointTy();
  Fact.IsIntegerClue = Ty->isIntegerTy();
  Fact.IsAggregateClue = Ty->isAggregateType() || isa<FixedVectorType>(Ty);
  Cand.Accesses.push_back(std::move(Fact));
}

static bool analyzeGEP(const GEPOperator &GEP, const DataLayout &DL,
                       int64_t &ConstantOffset, Value *&DynamicIndex,
                       int64_t &DynamicStride) {
  auto GTI = gep_type_begin(GEP);
  for (unsigned I = 1, E = GEP.getNumOperands(); I != E; ++I, ++GTI) {
    Value *Index = GEP.getOperand(I);
    if (auto *CI = dyn_cast<ConstantInt>(Index)) {
      if (StructType *ST = GTI.getStructTypeOrNull()) {
        uint64_t Field = CI->getZExtValue();
        if (Field >= ST->getNumElements())
          return false;
        uint64_t FieldOffset = DL.getStructLayout(ST)->getElementOffset(Field);
        if (FieldOffset > static_cast<uint64_t>(INT64_MAX) ||
            !checkedAdd(ConstantOffset, static_cast<int64_t>(FieldOffset),
                        ConstantOffset))
          return false;
      } else {
        auto ElementSize = fixedAllocSize(GTI.getIndexedType(), DL);
        int64_t Delta = 0;
        if (!ElementSize || *ElementSize > static_cast<uint64_t>(INT64_MAX) ||
            !checkedMul(CI->getSExtValue(), static_cast<int64_t>(*ElementSize),
                        Delta) ||
            !checkedAdd(ConstantOffset, Delta, ConstantOffset))
          return false;
      }
      continue;
    }

    if (DynamicIndex || GTI.getStructTypeOrNull())
      return false;
    auto ElementSize = fixedAllocSize(GTI.getIndexedType(), DL);
    if (!ElementSize || *ElementSize == 0 ||
        *ElementSize > static_cast<uint64_t>(INT64_MAX))
      return false;
    int64_t Accumulated = 0;
    if (!resolveAffineIndex(Index, static_cast<int64_t>(*ElementSize),
                            Accumulated, DynamicStride, DynamicIndex) ||
        !checkedAdd(ConstantOffset, Accumulated, ConstantOffset))
      return false;
  }
  return true;
}

static void tracePointerUses(Value *Val, int64_t Offset, Value *IndexExpr,
                             int64_t Stride, TypeReconstructionContext &Ctx,
                             ObjectCandidate &Cand,
                             std::set<TraceState> &Visited, unsigned Depth) {
  if (Depth > Ctx.MaxDepth) {
    reject(Cand, "pointer-trace-depth-limit");
    return;
  }
  if (!Visited.insert({Val, Offset, IndexExpr, Stride}).second)
    return;

  for (Use &Use : Val->uses()) {
    User *U = Use.getUser();
    Instruction *Inst = dyn_cast<Instruction>(U);

    if (auto *LI = dyn_cast<LoadInst>(U)) {
      if (LI->getPointerOperand() != Val) {
        reject(Cand, "pointer-used-as-nonaddress-load-operand");
        continue;
      }
      addLoadStoreFact(Cand, Ctx, LI, LI->getType(), false, Offset,
                       IndexExpr, Stride, LI->getAlign(), LI->isVolatile(),
                       LI->isAtomic(), LI->getOrdering(), LI->getSyncScopeID());
      continue;
    }

    if (auto *SI = dyn_cast<StoreInst>(U)) {
      if (SI->getPointerOperand() == Val) {
        addLoadStoreFact(Cand, Ctx, SI, SI->getValueOperand()->getType(), true,
                         Offset, IndexExpr, Stride, SI->getAlign(),
                         SI->isVolatile(), SI->isAtomic(), SI->getOrdering(),
                         SI->getSyncScopeID());
      } else {
        reject(Cand, "object-pointer-stored-to-memory");
      }
      continue;
    }

    if (auto *RMW = dyn_cast<AtomicRMWInst>(U)) {
      if (RMW->getPointerOperand() != Val) {
        reject(Cand, "pointer-used-as-atomic-value");
        continue;
      }
      addLoadStoreFact(Cand, Ctx, RMW, RMW->getValOperand()->getType(), false,
                       Offset, IndexExpr, Stride, RMW->getAlign(), false, true,
                       RMW->getOrdering(), RMW->getSyncScopeID());
      addLoadStoreFact(Cand, Ctx, RMW, RMW->getValOperand()->getType(), true,
                       Offset, IndexExpr, Stride, RMW->getAlign(), false, true,
                       RMW->getOrdering(), RMW->getSyncScopeID());
      continue;
    }

    if (auto *CX = dyn_cast<AtomicCmpXchgInst>(U)) {
      if (CX->getPointerOperand() != Val) {
        reject(Cand, "pointer-used-as-cmpxchg-value");
        continue;
      }
      Type *Ty = CX->getCompareOperand()->getType();
      addLoadStoreFact(Cand, Ctx, CX, Ty, false, Offset, IndexExpr, Stride,
                       CX->getAlign(), false, true, CX->getSuccessOrdering(),
                       CX->getSyncScopeID());
      addLoadStoreFact(Cand, Ctx, CX, Ty, true, Offset, IndexExpr, Stride,
                       CX->getAlign(), false, true, CX->getSuccessOrdering(),
                       CX->getSyncScopeID());
      continue;
    }

    if (auto *GEP = dyn_cast<GEPOperator>(U)) {
      if (GEP->getPointerOperand() != Val) {
        reject(Cand, "object-pointer-used-as-gep-index");
        continue;
      }
      int64_t AdditionalOffset = 0;
      Value *AdditionalIndex = nullptr;
      int64_t AdditionalStride = 0;
      if (!analyzeGEP(*GEP, Ctx.DL, AdditionalOffset, AdditionalIndex,
                      AdditionalStride)) {
        reject(Cand, "non-affine-gep");
        continue;
      }
      int64_t NewOffset = 0;
      if (!checkedAdd(Offset, AdditionalOffset, NewOffset)) {
        reject(Cand, "pointer-offset-overflow");
        continue;
      }
      if (AdditionalIndex && IndexExpr) {
        reject(Cand, "multiple-dynamic-index-dimensions");
        continue;
      }
      tracePointerUses(cast<Value>(U), NewOffset,
                       AdditionalIndex ? AdditionalIndex : IndexExpr,
                       AdditionalIndex ? AdditionalStride : Stride, Ctx, Cand,
                       Visited, Depth + 1);
      continue;
    }

    if (auto *Op = dyn_cast<Operator>(U)) {
      unsigned Opcode = Op->getOpcode();
      if (Opcode == Instruction::BitCast ||
          Opcode == Instruction::AddrSpaceCast ||
          Opcode == Instruction::IntToPtr) {
        tracePointerUses(cast<Value>(U), Offset, IndexExpr, Stride, Ctx, Cand,
                         Visited, Depth + 1);
        continue;
      }
    }

    if (auto *PTI = dyn_cast<Operator>(U);
        PTI && PTI->getOpcode() == Instruction::PtrToInt) {
      Value *PTIValue = cast<Value>(U);
      for (Use &IntegerUse : PTIValue->uses()) {
        User *IU = IntegerUse.getUser();
        auto *BO = dyn_cast<BinaryOperator>(IU);
        if (!BO) {
          reject(Cand, "pointer-integer-bits-observed");
          continue;
        }
        int64_t Delta = 0;
        if (BO->getOpcode() == Instruction::Add) {
          Value *Other = BO->getOperand(0) == PTIValue ? BO->getOperand(1)
                                                       : BO->getOperand(0);
          auto *CI = dyn_cast<ConstantInt>(Other);
          if (!CI) {
            reject(Cand, "nonconstant-pointer-integer-add");
            continue;
          }
          Delta = CI->getSExtValue();
        } else if (BO->getOpcode() == Instruction::Sub &&
                   BO->getOperand(0) == PTIValue) {
          auto *CI = dyn_cast<ConstantInt>(BO->getOperand(1));
          if (!CI) {
            reject(Cand, "nonconstant-pointer-integer-sub");
            continue;
          }
          int64_t Constant = CI->getSExtValue();
          if (Constant == std::numeric_limits<int64_t>::min()) {
            reject(Cand, "pointer-integer-subtraction-overflow");
            continue;
          }
          Delta = -Constant;
        } else {
          reject(Cand, "unsupported-pointer-integer-arithmetic");
          continue;
        }
        int64_t NewOffset = 0;
        if (!checkedAdd(Offset, Delta, NewOffset)) {
          reject(Cand, "pointer-integer-offset-overflow");
          continue;
        }
        tracePointerUses(BO, NewOffset, IndexExpr, Stride, Ctx, Cand, Visited,
                         Depth + 1);
      }
      continue;
    }

    if (auto *FI = dyn_cast<FreezeInst>(U)) {
      tracePointerUses(FI, Offset, IndexExpr, Stride, Ctx, Cand, Visited,
                       Depth + 1);
      continue;
    }

    if (auto *CB = dyn_cast<CallBase>(U)) {
      Function *Callee = CB->getCalledFunction();
      if (Callee && (Callee->getName().starts_with("llvm.lifetime.") ||
                     Callee->getName().starts_with("llvm.dbg.") ||
                     Callee->getName().starts_with("llvm.assume")))
        continue;

      if (auto *MI = dyn_cast<MemIntrinsic>(CB)) {
        bool IsDest = MI->getRawDest() == Val;
        bool IsSource = false;
        MaybeAlign Alignment = MI->getDestAlign();
        if (auto *MT = dyn_cast<MemTransferInst>(MI)) {
          IsSource = MT->getRawSource() == Val;
          if (IsSource)
            Alignment = MT->getSourceAlign();
        }
        if (!IsDest && !IsSource) {
          reject(Cand, "object-pointer-used-as-memory-length");
          continue;
        }

        uint64_t Length = 0;
        if (auto *CI = dyn_cast<ConstantInt>(MI->getLength()))
          Length = CI->getZExtValue();
        AccessFact Fact;
        Fact.BaseObject = Cand.BaseVal;
        Fact.ConstantOffset = Offset;
        Fact.DynamicIndexExpr = IndexExpr;
        Fact.Stride = Stride;
        Fact.AccessSize = Length;
        Fact.ObservedType = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()),
                                           Length ? Length : 1);
        Fact.IsWrite = IsDest;
        Fact.Alignment = Alignment.value_or(Align(1));
        Fact.IsVolatile = MI->isVolatile();
        Fact.SourceInst = MI;
        Fact.Kind = EvidenceKind::InitializerBytes;
        Fact.IsAggregateClue = true;
        Fact.IsWeak = true;
        Cand.Accesses.push_back(std::move(Fact));
        continue;
      }

      reject(Cand, "object-pointer-passed-to-unknown-call");
      continue;
    }

    if (isa<ICmpInst>(U))
      continue; // Retyping preserves the storage object's address identity.

    if (isa<PHINode>(U) || isa<SelectInst>(U)) {
      reject(Cand, "pointer-merge-requires-path-sensitive-provenance");
      continue;
    }

    reject(Cand, Inst ? (Twine("unsupported-pointer-use-") +
                         Inst->getOpcodeName()).str()
                      : "unsupported-constant-pointer-use");
  }
}

} // namespace

void AnalyzePointerOffsets(TypeReconstructionContext &Ctx) {
  for (auto &Cand : Ctx.Candidates) {
    std::set<TraceState> Visited;
    tracePointerUses(Cand->BaseVal, 0, nullptr, 0, Ctx, *Cand, Visited, 0);
  }
}

} // namespace brighten_type
