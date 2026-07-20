#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_type {

using namespace llvm;

static void ResolveIndexExpression(Value *Idx, int64_t CurrentStride, int64_t &ConstantOffsetAccumulator, int64_t &FinalStride, Value *&FinalIdx) {
  if (auto *BO = dyn_cast<BinaryOperator>(Idx)) {
    if (BO->getOpcode() == Instruction::Add) {
      Value *LHS = BO->getOperand(0);
      Value *RHS = BO->getOperand(1);
      if (auto *CI = dyn_cast<ConstantInt>(RHS)) {
        ConstantOffsetAccumulator += CI->getSExtValue() * CurrentStride;
        ResolveIndexExpression(LHS, CurrentStride, ConstantOffsetAccumulator, FinalStride, FinalIdx);
        return;
      } else if (auto *CI = dyn_cast<ConstantInt>(LHS)) {
        ConstantOffsetAccumulator += CI->getSExtValue() * CurrentStride;
        ResolveIndexExpression(RHS, CurrentStride, ConstantOffsetAccumulator, FinalStride, FinalIdx);
        return;
      }
    } else if (BO->getOpcode() == Instruction::Sub) {
      Value *LHS = BO->getOperand(0);
      Value *RHS = BO->getOperand(1);
      if (auto *CI = dyn_cast<ConstantInt>(RHS)) {
        ConstantOffsetAccumulator -= CI->getSExtValue() * CurrentStride;
        ResolveIndexExpression(LHS, CurrentStride, ConstantOffsetAccumulator, FinalStride, FinalIdx);
        return;
      }
    } else if (BO->getOpcode() == Instruction::Mul) {
      Value *LHS = BO->getOperand(0);
      Value *RHS = BO->getOperand(1);
      if (auto *CI = dyn_cast<ConstantInt>(RHS)) {
        ResolveIndexExpression(LHS, CurrentStride * CI->getSExtValue(), ConstantOffsetAccumulator, FinalStride, FinalIdx);
        return;
      } else if (auto *CI = dyn_cast<ConstantInt>(LHS)) {
        ResolveIndexExpression(RHS, CurrentStride * CI->getSExtValue(), ConstantOffsetAccumulator, FinalStride, FinalIdx);
        return;
      }
    } else if (BO->getOpcode() == Instruction::Shl) {
      Value *LHS = BO->getOperand(0);
      Value *RHS = BO->getOperand(1);
      if (auto *CI = dyn_cast<ConstantInt>(RHS)) {
        ResolveIndexExpression(LHS, CurrentStride * (1LL << CI->getZExtValue()), ConstantOffsetAccumulator, FinalStride, FinalIdx);
        return;
      }
    }
  }

  FinalIdx = Idx;
  FinalStride = CurrentStride;
}

static void TracePointerUses(Value *Val, int64_t Offset, Value *IndexExpr, int64_t Stride,
                             TypeReconstructionContext &Ctx, ObjectCandidate &Cand,
                             std::set<Value *> &Visited, int Depth) {
  if (Depth > Ctx.MaxDepth) {
    Cand.Escaped = true;
    Cand.RejectionReasons.push_back("depth-limit-exceeded");
    return;
  }

  if (Visited.count(Val))
    return;
  Visited.insert(Val);

  for (User *U : Val->users()) {
    Instruction *Inst = dyn_cast<Instruction>(U);
    if (!Inst)
      continue;

    if (auto *LI = dyn_cast<LoadInst>(Inst)) {
      if (LI->getPointerOperand() == Val) {
        AccessFact Fact;
        Fact.BaseObject = Cand.BaseVal;
        Fact.ConstantOffset = Offset;
        Fact.DynamicIndexExpr = IndexExpr;
        Fact.Stride = Stride;
        Fact.AccessSize = Ctx.DL.getTypeStoreSize(LI->getType()).getFixedValue();
        Fact.ObservedType = LI->getType();
        Fact.IsWrite = false;
        Fact.Alignment = LI->getAlign();
        Fact.IsVolatile = LI->isVolatile();
        Fact.IsAtomic = LI->isAtomic();
        Fact.Ordering = LI->getOrdering();
        Fact.SyncScope = LI->getSyncScopeID();
        Fact.SourceInst = LI;
        Fact.Kind = EvidenceKind::LoadStoreType;

        if (LI->getType()->isPointerTy()) Fact.IsPointerClue = true;
        else if (LI->getType()->isFloatingPointTy()) Fact.IsFloatClue = true;
        else if (LI->getType()->isIntegerTy()) Fact.IsIntegerClue = true;
        else if (LI->getType()->isAggregateType()) Fact.IsAggregateClue = true;

        Cand.Accesses.push_back(Fact);
      } else {
        Cand.Escaped = true;
        Cand.RejectionReasons.push_back("pointer-used-as-metadata-in-load");
      }
      continue;
    }

    if (auto *SI = dyn_cast<StoreInst>(Inst)) {
      if (SI->getPointerOperand() == Val) {
        AccessFact Fact;
        Fact.BaseObject = Cand.BaseVal;
        Fact.ConstantOffset = Offset;
        Fact.DynamicIndexExpr = IndexExpr;
        Fact.Stride = Stride;
        Fact.AccessSize = Ctx.DL.getTypeStoreSize(SI->getValueOperand()->getType()).getFixedValue();
        Fact.ObservedType = SI->getValueOperand()->getType();
        Fact.IsWrite = true;
        Fact.Alignment = SI->getAlign();
        Fact.IsVolatile = SI->isVolatile();
        Fact.IsAtomic = SI->isAtomic();
        Fact.Ordering = SI->getOrdering();
        Fact.SyncScope = SI->getSyncScopeID();
        Fact.SourceInst = SI;
        Fact.Kind = EvidenceKind::LoadStoreType;

        Type *ValTy = SI->getValueOperand()->getType();
        if (ValTy->isPointerTy()) Fact.IsPointerClue = true;
        else if (ValTy->isFloatingPointTy()) Fact.IsFloatClue = true;
        else if (ValTy->isIntegerTy()) Fact.IsIntegerClue = true;
        else if (ValTy->isAggregateType()) Fact.IsAggregateClue = true;

        Cand.Accesses.push_back(Fact);
      } else {
        Cand.Escaped = true;
        Cand.RejectionReasons.push_back("pointer-stored-to-memory");
      }
      continue;
    }

    if (auto *GEP = dyn_cast<GetElementPtrInst>(Inst)) {
      if (GEP->getPointerOperand() != Val) {
        Cand.Escaped = true;
        Cand.RejectionReasons.push_back("pointer-used-as-gep-index");
        continue;
      }

      int64_t ConstantOffset = 0;
      Value *DynamicIdx = nullptr;
      int64_t DynamicStride = 0;
      bool GEPAnalysisSuccess = true;

      auto GeptIt = gep_type_begin(GEP);
      for (unsigned i = 1, e = GEP->getNumOperands(); i != e; ++i, ++GeptIt) {
        Value *Idx = GEP->getOperand(i);
        if (auto *CI = dyn_cast<ConstantInt>(Idx)) {
          if (CI->isZero())
            continue;
          if (StructType *STy = GeptIt.getStructTypeOrNull()) {
            ConstantOffset += Ctx.DL.getStructLayout(STy)->getElementOffset(CI->getZExtValue());
          } else {
            uint64_t ElementSize = Ctx.DL.getTypeAllocSize(GeptIt.getIndexedType()).getFixedValue();
            ConstantOffset += CI->getSExtValue() * ElementSize;
          }
        } else {
          if (DynamicIdx) {
            GEPAnalysisSuccess = false;
            break;
          }
          if (GeptIt.getStructTypeOrNull()) {
            GEPAnalysisSuccess = false;
            break;
          }
          
          int64_t CurrentStride = Ctx.DL.getTypeAllocSize(GeptIt.getIndexedType()).getFixedValue();
          int64_t AccOffset = 0;
          ResolveIndexExpression(Idx, CurrentStride, AccOffset, DynamicStride, DynamicIdx);
          ConstantOffset += AccOffset;
        }
      }

      if (!GEPAnalysisSuccess) {
        Cand.Escaped = true;
        Cand.RejectionReasons.push_back("complex-gep-dynamic-indices");
        continue;
      }

      if (DynamicIdx) {
        if (IndexExpr) {
          Cand.Escaped = true;
          Cand.RejectionReasons.push_back("nested-dynamic-indices");
          continue;
        }
        TracePointerUses(GEP, Offset + ConstantOffset, DynamicIdx, DynamicStride, Ctx, Cand, Visited, Depth + 1);
      } else {
        TracePointerUses(GEP, Offset + ConstantOffset, IndexExpr, Stride, Ctx, Cand, Visited, Depth + 1);
      }
      continue;
    }

    if (isa<BitCastInst>(Inst) || isa<AddrSpaceCastInst>(Inst)) {
      TracePointerUses(Inst, Offset, IndexExpr, Stride, Ctx, Cand, Visited, Depth + 1);
      continue;
    }

    if (auto *PTI = dyn_cast<PtrToIntInst>(Inst)) {
      for (User *PtiU : PTI->users()) {
        Instruction *PtiInst = dyn_cast<Instruction>(PtiU);
        if (!PtiInst)
          continue;

        if (PtiInst->getOpcode() == Instruction::Add) {
          Value *LHS = PtiInst->getOperand(0);
          Value *RHS = PtiInst->getOperand(1);
          Value *ConstOp = (LHS == PTI) ? RHS : LHS;
          if (auto *CI = dyn_cast<ConstantInt>(ConstOp)) {
            TracePointerUses(PtiInst, Offset + CI->getSExtValue(), IndexExpr, Stride, Ctx, Cand, Visited, Depth + 1);
            continue;
          }
        } else if (PtiInst->getOpcode() == Instruction::Sub) {
          if (PtiInst->getOperand(0) == PTI) {
            if (auto *CI = dyn_cast<ConstantInt>(PtiInst->getOperand(1))) {
              TracePointerUses(PtiInst, Offset - CI->getSExtValue(), IndexExpr, Stride, Ctx, Cand, Visited, Depth + 1);
              continue;
            }
          }
        }
        Cand.Escaped = true;
        Cand.RejectionReasons.push_back("ptrtoint-arithmetic-escape");
      }
      continue;
    }

    if (isa<IntToPtrInst>(Inst)) {
      TracePointerUses(Inst, Offset, IndexExpr, Stride, Ctx, Cand, Visited, Depth + 1);
      continue;
    }

    if (auto *CB = dyn_cast<CallBase>(Inst)) {
      Function *Callee = CB->getCalledFunction();
      if (Callee) {
        StringRef Name = Callee->getName();
        if (Name.starts_with("llvm.lifetime.start") || Name.starts_with("llvm.lifetime.end") ||
            Name.starts_with("llvm.dbg")) {
          continue;
        }

        if (auto *MemIntrin = dyn_cast<MemIntrinsic>(CB)) {
          bool IsDest = (MemIntrin->getRawDest() == Val);
          uint64_t Size = 0;
          if (auto *ConstSize = dyn_cast<ConstantInt>(MemIntrin->getLength())) {
            Size = ConstSize->getZExtValue();
          }

          AccessFact Fact;
          Fact.BaseObject = Cand.BaseVal;
          Fact.ConstantOffset = Offset;
          Fact.DynamicIndexExpr = IndexExpr;
          Fact.Stride = Stride;
          Fact.AccessSize = Size;
          Fact.ObservedType = ArrayType::get(Type::getInt8Ty(Ctx.M.getContext()), Size ? Size : 1);
          Fact.IsWrite = IsDest;
          Fact.Alignment = MemIntrin->getDestAlign().value_or(Align(1));
          Fact.IsVolatile = MemIntrin->isVolatile();
          Fact.SourceInst = MemIntrin;
          Fact.Kind = EvidenceKind::InitializerBytes;
          Fact.IsAggregateClue = true;
          Cand.Accesses.push_back(Fact);
          continue;
        }
      }

      Cand.Escaped = true;
      Cand.RejectionReasons.push_back("passed-to-call-" + (Callee ? Callee->getName().str() : "indirect"));
      continue;
    }

    if (isa<ICmpInst>(Inst)) {
      continue;
    }

    if (isa<PHINode>(Inst) || isa<SelectInst>(Inst)) {
      Cand.Escaped = true;
      Cand.RejectionReasons.push_back("phi-or-select-escape");
      continue;
    }

    Cand.Escaped = true;
    Cand.RejectionReasons.push_back("unknown-instruction-use-" + std::string(Inst->getOpcodeName()));
  }
}

void AnalyzePointerOffsets(TypeReconstructionContext &Ctx) {
  for (auto &Cand : Ctx.Candidates) {
    std::set<Value *> Visited;
    TracePointerUses(Cand->BaseVal, 0, nullptr, 0, Ctx, *Cand, Visited, 0);
  }
}

} // namespace brighten_type
