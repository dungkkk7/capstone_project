#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

bool readConstantByte(Constant *C, const DataLayout &DL,
                             uint64_t Offset, uint8_t &Byte) {
  if (!C)
    return false;
  if (isa<ConstantAggregateZero>(C)) {
    Byte = 0;
    return true;
  }
  if (auto *CI = dyn_cast<ConstantInt>(C)) {
    TypeSize StoreSize = DL.getTypeStoreSize(CI->getType());
    if (StoreSize.isScalable() || Offset >= StoreSize.getFixedValue())
      return false;
    uint64_t StoreBytes = StoreSize.getFixedValue();
    APInt Bits = CI->getValue().zextOrTrunc(StoreBytes * 8);
    uint64_t ByteIndex =
        DL.isLittleEndian() ? Offset : StoreBytes - Offset - 1;
    Byte = static_cast<uint8_t>(Bits.lshr(ByteIndex * 8)
                                    .trunc(8)
                                    .getZExtValue());
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

std::optional<uint64_t> segmentPointerOffset(Value *V,
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

unsigned materializeNativeSegmentPointers(Module &M, bool &Changed) {
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

// A residual segment can remain live after global recovery when the program
// indexes it with a runtime guest address.  It is not dead and must not be
// erased, but retaining the lifter's identified `seg_*` aggregate type also
// retains the raw lifted memory model in otherwise native IR.  Convert only a
// completely readable initializer to an exactly sized native byte array.
// Opaque pointers make all existing GEP/load users type-compatible, while the
// byte-for-byte initializer, linkage, address space, alignment and metadata
// preserve the allocation's behavior.  Relocations, undef bytes and scalable
// layouts fail closed rather than being guessed.
unsigned canonicalizeLiveNativeResidualSegments(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  SmallVector<GlobalVariable *, 8> Candidates;
  for (GlobalVariable &GV : M.globals()) {
    if (!GV.getName().starts_with("native_residual_") ||
        !GV.hasInitializer())
      continue;
    auto *ST = dyn_cast<StructType>(GV.getValueType());
    if (!ST || !ST->hasName() || !ST->getName().starts_with("seg_"))
      continue;
    Candidates.push_back(&GV);
  }

  unsigned Rewritten = 0;
  for (GlobalVariable *Old : Candidates) {
    auto *ST = cast<StructType>(Old->getValueType());
    TypeSize AllocSize = DL.getTypeAllocSize(Old->getValueType());
    if (AllocSize.isScalable() || !AllocSize.getFixedValue() ||
        AllocSize.getFixedValue() > std::numeric_limits<uint32_t>::max())
      continue;

    uint64_t NumBytes = AllocSize.getFixedValue();
    SmallVector<uint8_t, 256> Bytes;
    Bytes.reserve(static_cast<size_t>(NumBytes));
    bool Complete = true;
    for (uint64_t Offset = 0; Offset < NumBytes; ++Offset) {
      uint8_t Byte = 0;
      if (!readConstantByte(Old->getInitializer(), DL, Offset, Byte)) {
        Complete = false;
        break;
      }
      Bytes.push_back(Byte);
    }
    Constant *Init = nullptr;
    if (Complete) {
      Init = ConstantDataArray::get(M.getContext(), Bytes);
    } else if (auto *CS = dyn_cast<ConstantStruct>(Old->getInitializer())) {
      // Pointer relocations cannot be represented as constant i8 bytes.  Keep
      // those typed relocation fields exactly, but move them into a literal
      // native aggregate so the lifter-specific identified segment type no
      // longer owns the allocation.  The element sequence and packedness make
      // this layout-identical; this is not a guessed pointer serialization.
      SmallVector<Type *, 32> ElementTypes;
      SmallVector<Constant *, 32> Elements;
      ElementTypes.reserve(CS->getNumOperands());
      Elements.reserve(CS->getNumOperands());
      for (Value *Operand : CS->operands()) {
        auto *Element = cast<Constant>(Operand);
        ElementTypes.push_back(Element->getType());
        Elements.push_back(Element);
      }
      auto *Literal = StructType::get(M.getContext(), ElementTypes,
                                      ST->isPacked());
      if (DL.getTypeAllocSize(Literal) == AllocSize)
        Init = ConstantStruct::get(Literal, Elements);
    }
    if (!Init)
      continue;

    std::string Name = Old->getName().str();
    Old->setName(Name + ".lifted_type");
    auto *Native = new GlobalVariable(
        M, Init->getType(), Old->isConstant(), Old->getLinkage(), Init, Name,
        Old, Old->getThreadLocalMode(), Old->getAddressSpace(),
        Old->isExternallyInitialized());
    Native->copyAttributesFrom(Old);
    Native->copyMetadata(Old, 0);
    Old->replaceAllUsesWith(Native);
    Old->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

unsigned rewriteExactNativeSegmentGEPs(Module &M, bool &Changed) {
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

} // namespace brighten_native_cleanup
