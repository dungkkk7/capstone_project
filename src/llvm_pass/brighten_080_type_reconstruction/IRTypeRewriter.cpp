#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GetElementPtrTypeIterator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TypeSize.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <optional>

namespace brighten_type {

using namespace llvm;

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

static bool AppendGEPPath(Type *Ty, uint64_t Offset, const DataLayout &DL,
                          LLVMContext &Context,
                          SmallVectorImpl<Value *> &Indices) {
  if (!Ty || !Ty->isSized())
    return false;
  TypeSize Size = DL.getTypeAllocSize(Ty);
  if (Size.isScalable() || Offset >= Size.getFixedValue())
    return Offset == 0 && !Ty->isAggregateType();

  if (auto *STy = dyn_cast<StructType>(Ty)) {
    const StructLayout *SL = DL.getStructLayout(STy);
    unsigned Field = SL->getElementContainingOffset(Offset);
    Indices.push_back(ConstantInt::get(Type::getInt32Ty(Context), Field));
    return AppendGEPPath(STy->getElementType(Field),
                         Offset - SL->getElementOffset(Field), DL, Context,
                         Indices);
  }
  if (auto *ArrTy = dyn_cast<ArrayType>(Ty)) {
    Type *ElemTy = ArrTy->getElementType();
    TypeSize ElemSizeTS = DL.getTypeAllocSize(ElemTy);
    if (ElemSizeTS.isScalable() || ElemSizeTS.getFixedValue() == 0)
      return false;
    uint64_t ElemSize = ElemSizeTS.getFixedValue();
    uint64_t Index = Offset / ElemSize;
    if (Index >= ArrTy->getNumElements())
      return false;
    Indices.push_back(ConstantInt::get(Type::getInt64Ty(Context), Index));
    return AppendGEPPath(ElemTy, Offset % ElemSize, DL, Context, Indices);
  }
  return Offset == 0;
}

static Value *BuildPointerForFact(IRBuilder<> &Builder, Value *NewBase,
                                  InferredTypePlan &Plan,
                                  const AccessFact &Fact,
                                  TypeReconstructionContext &Ctx) {
  if (!Fact.ConstantOffset.has_value() || *Fact.ConstantOffset < 0)
    return nullptr;
  uint64_t Offset = static_cast<uint64_t>(*Fact.ConstantOffset);
  SmallVector<Value *, 8> Indices;
  Indices.push_back(
      ConstantInt::get(Type::getInt32Ty(Ctx.M.getContext()), 0));

  Type *PathType = Plan.ProposedRootType;
  if (Fact.DynamicIndexExpr) {
    auto *Array = dyn_cast<ArrayType>(Plan.ProposedRootType);
    if (!Plan.IsArray || !Array)
      return nullptr;
    Indices.push_back(Fact.DynamicIndexExpr);
    PathType = Array->getElementType();
  }
  if (Offset != 0 || PathType->isAggregateType()) {
    if (!AppendGEPPath(PathType, Offset, Ctx.DL, Ctx.M.getContext(),
                       Indices))
      return nullptr;
  }
  return Builder.CreateGEP(Plan.ProposedRootType, NewBase, Indices,
                           "brighten.gep");
}

static bool RewriteAccessPointer(Instruction &Inst, const AccessFact &Fact,
                                 Value *Pointer) {
  if (auto *LI = dyn_cast<LoadInst>(&Inst)) {
    LI->setOperand(LI->getPointerOperandIndex(), Pointer);
    return true;
  }
  if (auto *SI = dyn_cast<StoreInst>(&Inst)) {
    SI->setOperand(SI->getPointerOperandIndex(), Pointer);
    return true;
  }
  if (auto *RMW = dyn_cast<AtomicRMWInst>(&Inst)) {
    RMW->setOperand(RMW->getPointerOperandIndex(), Pointer);
    return true;
  }
  if (auto *CX = dyn_cast<AtomicCmpXchgInst>(&Inst)) {
    CX->setOperand(CX->getPointerOperandIndex(), Pointer);
    return true;
  }
  if (auto *MI = dyn_cast<MemIntrinsic>(&Inst)) {
    if (Fact.IsWrite) {
      MI->setDest(Pointer);
      return true;
    }
    if (auto *MT = dyn_cast<MemTransferInst>(MI)) {
      MT->setSource(Pointer);
      return true;
    }
  }
  return false;
}

static void CollectDerivedPointerInstructions(Value *Root,
                                              SmallVectorImpl<Instruction *> &Out) {
  SmallVector<Value *, 32> Worklist{Root};
  SmallPtrSet<Value *, 32> Seen;
  while (!Worklist.empty()) {
    Value *Current = Worklist.pop_back_val();
    if (!Seen.insert(Current).second)
      continue;
    for (User *U : Current->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        continue;
      if (isa<GetElementPtrInst>(I) || isa<CastInst>(I) ||
          isa<FreezeInst>(I) || isa<BinaryOperator>(I)) {
        Out.push_back(I);
        Worklist.push_back(I);
      }
    }
  }
}

void RewritePointerUses(Value *OldVal, Value *NewBase, InferredTypePlan &Plan,
                        TypeReconstructionContext &Ctx) {
  SmallVector<Instruction *, 32> Derived;
  CollectDerivedPointerInstructions(OldVal, Derived);

  SmallPtrSet<Instruction *, 32> Rewritten;
  for (const AccessFact &Fact : Plan.Candidate->Accesses) {
    Instruction *Inst = Fact.SourceInst;
    if (!Inst || !Inst->getParent() || !Rewritten.insert(Inst).second)
      continue;
    IRBuilder<> Builder(Inst);
    Value *Pointer = BuildPointerForFact(Builder, NewBase, Plan, Fact, Ctx);
    if (!Pointer || !RewriteAccessPointer(*Inst, Fact, Pointer))
      report_fatal_error(
          "brighten type reconstruction lost a prevalidated access");
    Ctx.Report.GEPsRewritten++;
  }

  // Opaque pointers make this replacement representation-preserving for
  // lifetime markers, comparisons and other non-typing uses.  Typed memory
  // accesses have already received exact subobject GEPs above.
  if (OldVal != NewBase && !OldVal->use_empty())
    OldVal->replaceAllUsesWith(NewBase);

  for (Instruction *I : reverse(Derived))
    if (I->getParent() && isInstructionTriviallyDead(I))
      RecursivelyDeleteTriviallyDeadInstructions(I);
}

} // namespace brighten_type
