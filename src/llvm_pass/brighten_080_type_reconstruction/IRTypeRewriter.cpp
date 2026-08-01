#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <optional>

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

static std::optional<uint8_t> ExtractByteFromConstant(Constant *C,
                                                     uint64_t Offset,
                                                     const DataLayout &DL) {
  if (isa<ConstantAggregateZero>(C))
    return uint8_t(0);
  if (auto *CDS = dyn_cast<ConstantDataSequential>(C)) {
    if (Offset < CDS->getNumElements() * CDS->getElementByteSize()) {
      uint64_t ElemIdx = Offset / CDS->getElementByteSize();
      uint64_t ByteIdx = Offset % CDS->getElementByteSize();
      uint64_t Val = CDS->getElementAsInteger(ElemIdx);
      return static_cast<uint8_t>((Val >> (ByteIdx * 8)) & 0xFF);
    }
    return std::nullopt;
  }
  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    Type *ElemTy = CA->getType()->getElementType();
    uint64_t ElemSize = DL.getTypeAllocSize(ElemTy).getFixedValue();
    uint64_t ElemIdx = Offset / ElemSize;
    if (ElemIdx < CA->getNumOperands()) {
      return ExtractByteFromConstant(cast<Constant>(CA->getOperand(ElemIdx)),
                                     Offset % ElemSize, DL);
    }
    return std::nullopt;
  }
  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    const StructLayout *SL = DL.getStructLayout(CS->getType());
    for (unsigned i = 0; i < CS->getNumOperands(); ++i) {
      uint64_t FieldOffset = SL->getElementOffset(i);
      uint64_t FieldSize = DL.getTypeAllocSize(CS->getOperand(i)->getType()).getFixedValue();
      if (Offset >= FieldOffset && Offset < FieldOffset + FieldSize) {
        return ExtractByteFromConstant(cast<Constant>(CS->getOperand(i)),
                                       Offset - FieldOffset, DL);
      }
    }
    return std::nullopt;
  }
  if (auto *CI = dyn_cast<ConstantInt>(C)) {
    const APInt &Val = CI->getValue();
    uint64_t StoreBytes = DL.getTypeStoreSize(CI->getType()).getFixedValue();
    if (Offset >= StoreBytes)
      return std::nullopt;
    uint64_t MemoryByte = DL.isLittleEndian() ? Offset
                                               : StoreBytes - 1 - Offset;
    unsigned Bit = static_cast<unsigned>(MemoryByte * 8);
    if (Bit < Val.getBitWidth())
      return static_cast<uint8_t>(Val.lshr(Bit)
                                      .trunc(std::min(8u, Val.getBitWidth() - Bit))
                                      .getZExtValue());
    return std::nullopt;
  }
  if (auto *CFP = dyn_cast<ConstantFP>(C)) {
    APInt Bits = CFP->getValueAPF().bitcastToAPInt();
    uint64_t StoreBytes = DL.getTypeStoreSize(CFP->getType()).getFixedValue();
    if (Offset >= StoreBytes)
      return std::nullopt;
    uint64_t MemoryByte = DL.isLittleEndian() ? Offset
                                               : StoreBytes - 1 - Offset;
    unsigned Bit = static_cast<unsigned>(MemoryByte * 8);
    if (Bit < Bits.getBitWidth())
      return static_cast<uint8_t>(Bits.lshr(Bit)
                                      .trunc(std::min(8u, Bits.getBitWidth() - Bit))
                                      .getZExtValue());
    return std::nullopt;
  }
  return std::nullopt;
}

Constant *ExtractPointerFromConstant(Constant *C, uint64_t Offset, const DataLayout &DL) {
  if (C->getType()->isPointerTy() && Offset == 0) {
    return C;
  }
  if (auto *CE = dyn_cast<ConstantExpr>(C)) {
    if (CE->getOpcode() == Instruction::IntToPtr) {
      return CE;
    }
  }
  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    Type *ElemTy = CA->getType()->getElementType();
    uint64_t ElemSize = DL.getTypeAllocSize(ElemTy).getFixedValue();
    uint64_t ElemIdx = Offset / ElemSize;
    if (ElemIdx < CA->getNumOperands()) {
      return ExtractPointerFromConstant(cast<Constant>(CA->getOperand(ElemIdx)), Offset % ElemSize, DL);
    }
  }
  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    const StructLayout *SL = DL.getStructLayout(CS->getType());
    for (unsigned i = 0; i < CS->getNumOperands(); ++i) {
      uint64_t FieldOffset = SL->getElementOffset(i);
      uint64_t FieldSize = DL.getTypeAllocSize(CS->getOperand(i)->getType()).getFixedValue();
      if (Offset >= FieldOffset && Offset < FieldOffset + FieldSize) {
        return ExtractPointerFromConstant(cast<Constant>(CS->getOperand(i)), Offset - FieldOffset, DL);
      }
    }
  }
  return nullptr;
}

Constant *RebuildConstant(Constant *OldInit, Type *NewTy, uint64_t Offset, const DataLayout &DL, LLVMContext &Ctx) {
  if (Offset == 0 && OldInit->getType() == NewTy) {
    return OldInit;
  }

  if (isa<ConstantAggregateZero>(OldInit)) {
    return Constant::getNullValue(NewTy);
  }

  auto ReadBytes = [&](uint64_t Off, uint64_t Size, std::vector<uint8_t> &Out) {
    for (uint64_t i = 0; i < Size; ++i) {
      std::optional<uint8_t> Byte =
          ExtractByteFromConstant(OldInit, Off + i, DL);
      if (!Byte)
        return false;
      Out.push_back(*Byte);
    }
    return true;
  };

  auto AssembleBits = [&](ArrayRef<uint8_t> Bytes,
                          unsigned BitWidth) -> APInt {
    APInt Bits(BitWidth, 0);
    for (size_t I = 0; I < Bytes.size(); ++I) {
      size_t MemoryByte = DL.isLittleEndian() ? I : Bytes.size() - 1 - I;
      unsigned Shift = static_cast<unsigned>(MemoryByte * 8);
      if (Shift >= BitWidth)
        continue;
      Bits |= APInt(BitWidth, Bytes[I]).shl(Shift);
    }
    return Bits;
  };

  if (NewTy->isIntegerTy()) {
    unsigned Width = NewTy->getIntegerBitWidth();
    std::vector<uint8_t> Bytes;
    if (!ReadBytes(Offset, (Width + 7) / 8, Bytes))
      return nullptr;
    return ConstantInt::get(NewTy, AssembleBits(Bytes, Width));
  }

  if (NewTy->isFloatingPointTy()) {
    std::vector<uint8_t> Bytes;
    unsigned Size = DL.getTypeStoreSize(NewTy).getFixedValue();
    if (!ReadBytes(Offset, Size, Bytes))
      return nullptr;
    unsigned Width = NewTy->getPrimitiveSizeInBits().getFixedValue();
    APFloat Value(NewTy->getFltSemantics(), AssembleBits(Bytes, Width));
    return ConstantFP::get(Ctx, Value);
  }

  if (NewTy->isPointerTy()) {
    Constant *Reloc = ExtractPointerFromConstant(OldInit, Offset, DL);
    if (Reloc) {
      return ConstantExpr::getPointerCast(Reloc, NewTy);
    }
    // A raw all-zero pointer representation is proven null on the supported
    // integral-pointer targets.  Non-zero bytes without a symbolic relocation
    // are unresolved: replacing them with null silently changes program data
    // (and can hide a still-lifted guest address).  Reject the reconstruction
    // plan and preserve the original byte object instead.
    std::vector<uint8_t> Bytes;
    if (!ReadBytes(Offset, DL.getTypeStoreSize(NewTy).getFixedValue(), Bytes))
      return nullptr;
    if (!DL.isNonIntegralPointerType(NewTy) &&
        std::all_of(Bytes.begin(), Bytes.end(),
                    [](uint8_t Byte) { return Byte == 0; }))
      return Constant::getNullValue(NewTy);
    return nullptr;
  }

  if (auto *ArrTy = dyn_cast<ArrayType>(NewTy)) {
    Type *ElemTy = ArrTy->getElementType();
    uint64_t ElemSize = DL.getTypeAllocSize(ElemTy).getFixedValue();
    uint64_t NumElems = ArrTy->getNumElements();

    if (ElemTy->isIntegerTy(8)) {
      std::vector<uint8_t> Bytes;
      if (!ReadBytes(Offset, NumElems, Bytes))
        return nullptr;
      return ConstantDataArray::get(Ctx, Bytes);
    } else {
      std::vector<Constant *> Elems;
      for (uint64_t i = 0; i < NumElems; ++i) {
        Constant *Elem =
            RebuildConstant(OldInit, ElemTy, Offset + i * ElemSize, DL, Ctx);
        if (!Elem)
          return nullptr;
        Elems.push_back(Elem);
      }
      return ConstantArray::get(ArrTy, Elems);
    }
  }

  if (auto *STy = dyn_cast<StructType>(NewTy)) {
    const StructLayout *SL = DL.getStructLayout(STy);
    std::vector<Constant *> Elems;
    for (unsigned i = 0; i < STy->getNumElements(); ++i) {
      Type *ElemTy = STy->getElementType(i);
      uint64_t ElemOffset = SL->getElementOffset(i);
      Constant *Elem =
          RebuildConstant(OldInit, ElemTy, Offset + ElemOffset, DL, Ctx);
      if (!Elem)
        return nullptr;
      Elems.push_back(Elem);
    }
    return ConstantStruct::get(STy, Elems);
  }

  return nullptr;
}

static void GetGEPIndices(Type *Ty, uint64_t Offset, const DataLayout &DL, LLVMContext &Context,
                          std::vector<Value *> &Indices) {
  if (Offset == 0 && !Ty->isAggregateType())
    return;

  if (auto *STy = dyn_cast<StructType>(Ty)) {
    const StructLayout *SL = DL.getStructLayout(STy);
    unsigned F = SL->getElementContainingOffset(Offset);
    Indices.push_back(ConstantInt::get(Type::getInt32Ty(Context), F));
    GetGEPIndices(STy->getElementType(F), Offset - SL->getElementOffset(F), DL, Context, Indices);
  } else if (auto *ArrTy = dyn_cast<ArrayType>(Ty)) {
    Type *ElemTy = ArrTy->getElementType();
    uint64_t ElemSize = DL.getTypeAllocSize(ElemTy).getFixedValue();
    uint64_t Index = Offset / ElemSize;
    Indices.push_back(ConstantInt::get(Type::getInt64Ty(Context), Index));
    GetGEPIndices(ElemTy, Offset % ElemSize, DL, Context, Indices);
  } else {
    return;
  }
}

static bool GetOffsetTrace(Value *Val, Value *BaseVal, int64_t &Offset, Value *&IndexExpr, int64_t &Stride,
                           const DataLayout &DL, std::set<Value *> &Visited) {
  if (Val == BaseVal)
    return true;

  if (Visited.count(Val))
    return false;
  Visited.insert(Val);

  if (auto *GEP = dyn_cast<GetElementPtrInst>(Val)) {
    if (GetOffsetTrace(GEP->getPointerOperand(), BaseVal, Offset, IndexExpr, Stride, DL, Visited)) {
      int64_t ConstantOffset = 0;
      auto GeptIt = gep_type_begin(GEP);
      for (unsigned i = 1, e = GEP->getNumOperands(); i != e; ++i, ++GeptIt) {
        Value *Idx = GEP->getOperand(i);
        if (auto *CI = dyn_cast<ConstantInt>(Idx)) {
          if (StructType *STy = GeptIt.getStructTypeOrNull()) {
            ConstantOffset += DL.getStructLayout(STy)->getElementOffset(CI->getZExtValue());
          } else {
            uint64_t ElementSize = DL.getTypeAllocSize(GeptIt.getIndexedType()).getFixedValue();
            ConstantOffset += CI->getSExtValue() * ElementSize;
          }
        } else {
          int64_t CurrentStride = DL.getTypeAllocSize(GeptIt.getIndexedType()).getFixedValue();
          int64_t AccOffset = 0;
          ResolveIndexExpression(Idx, CurrentStride, AccOffset, Stride, IndexExpr);
          ConstantOffset += AccOffset;
        }
      }
      Offset += ConstantOffset;
      return true;
    }
  }

  if (auto *Cast = dyn_cast<CastInst>(Val)) {
    return GetOffsetTrace(Cast->getOperand(0), BaseVal, Offset, IndexExpr, Stride, DL, Visited);
  }

  return false;
}

void RewritePointerUses(Value *OldVal, Value *NewBase, InferredTypePlan &Plan, TypeReconstructionContext &Ctx) {
  std::vector<Instruction *> DeadInsts;
  std::vector<User *> Users(OldVal->user_begin(), OldVal->user_end());

  for (User *U : Users) {
    Instruction *Inst = dyn_cast<Instruction>(U);
    if (!Inst)
      continue;

    int64_t Offset = 0;
    Value *IndexExpr = nullptr;
    int64_t Stride = 0;
    std::set<Value *> Visited;

    if (!GetOffsetTrace(Inst, Plan.Candidate->BaseVal, Offset, IndexExpr, Stride, Ctx.DL, Visited)) {
      Inst->replaceUsesOfWith(OldVal, NewBase);
      continue;
    }

    std::vector<Value *> Indices;
    Indices.push_back(ConstantInt::get(Type::getInt32Ty(Ctx.M.getContext()), 0));

    if (Plan.IsArray && IndexExpr) {
      Indices.push_back(IndexExpr);
      if (auto *ArrTy = dyn_cast<ArrayType>(Plan.ProposedRootType)) {
        GetGEPIndices(ArrTy->getElementType(), Offset, Ctx.DL, Ctx.M.getContext(), Indices);
      }
    } else {
      GetGEPIndices(Plan.ProposedRootType, Offset, Ctx.DL, Ctx.M.getContext(), Indices);
      if (IndexExpr) {
        Indices.push_back(IndexExpr);
      }
    }

    Instruction *InsertPt = Inst;
    if (isa<PHINode>(Inst)) {
      continue;
    }

    IRBuilder<> Builder(InsertPt);
    Value *NewGEP = Builder.CreateGEP(Plan.ProposedRootType, NewBase, Indices, "brighten.gep");
    Ctx.Report.GEPsRewritten++;

    if (auto *LI = dyn_cast<LoadInst>(Inst)) {
      LI->setOperand(LI->getPointerOperandIndex(), NewGEP);
    } else if (auto *SI = dyn_cast<StoreInst>(Inst)) {
      SI->setOperand(SI->getPointerOperandIndex(), NewGEP);
    } else {
      Inst->replaceAllUsesWith(NewGEP);
      DeadInsts.push_back(Inst);
    }
  }

  for (auto *Dead : DeadInsts) {
    if (Dead->use_empty()) {
      Dead->eraseFromParent();
    }
  }
}

} // namespace brighten_type
