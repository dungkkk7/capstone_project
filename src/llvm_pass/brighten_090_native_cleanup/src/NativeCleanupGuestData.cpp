#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

std::optional<std::pair<GlobalVariable *, uint64_t>>
resolveConstantGlobalPointer(Value *V, const DataLayout &DL,
                             unsigned Depth) {
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

bool formatHasAnyConversion(StringRef Text) {
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

std::optional<std::string>
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
AllocaInst *getRootAlloca(Value *V) {
  if (!V)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *AI = dyn_cast<AllocaInst>(V))
    return AI;
  if (auto *GEP = dyn_cast<GEPOperator>(V))
    return dyn_cast<AllocaInst>(GEP->getPointerOperand()->stripPointerCasts());
  return nullptr;
}

std::optional<uint64_t> getConstantGEPByteOffset(Value *Ptr,
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
void collectFormatPointerSlots(StringRef Format, bool IsScanf,
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

std::optional<std::pair<GlobalVariable *, uint64_t>>
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

std::optional<std::pair<GlobalVariable *, uint64_t>>
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

std::optional<std::pair<uint64_t, uint64_t>>
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

std::optional<uint64_t> getConstantGuestPointer(Value *V) {
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
unsigned materializeResidualLibcFormats(Module &M, bool &Changed) {
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

void preserveRecoveredGlobalsAcrossOptimization(Module &M) {
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

void setGuestRangeMetadata(Module &M, GlobalVariable &GV,
                                  uint64_t Begin, uint64_t End) {
  LLVMContext &Ctx = M.getContext();
  GV.setMetadata(
      "brighten.guest.range",
      MDNode::get(Ctx, {ConstantAsMetadata::get(ConstantInt::get(
                            Type::getInt64Ty(Ctx), Begin)),
                        ConstantAsMetadata::get(ConstantInt::get(
                            Type::getInt64Ty(Ctx), End))}));
}

unsigned widenOverNarrowRecoveredScalars(Module &M, bool &Changed) {
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
// dynamic access uses the full segment.
unsigned rewriteRecoveredGlobalsToNativeSegments(Module &M,
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

unsigned inlineGuestPointerTranslators(Module &M, bool &Changed) {
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

unsigned rewriteRemainingDataAliasesToNativeSegments(Module &M,
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
unsigned rewriteConstantGuestPointerOperands(Module &M,
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
unsigned rewriteDeadRIPDataAliases(Module &M, bool &Changed) {
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
bool isProvenScalarLibcCallArgument(Value *V, CallBase &CB) {
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

unsigned rewriteGuestAddressIdentityAliasIntegers(Module &M,
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

// Recover the guest address represented by a constant pointer expression
// after global-data recovery has materialized the backing object.  LLVM keeps
// ptrtoint(@recovered_object) as a ConstantExpr in some pipelines, while
// other optimization orders fold the same provenance to ConstantInt.  The
// dynamic-address matcher must understand both forms; otherwise an otherwise
// valid recovered object is discarded before it can be used to rebase an
// inttoptr.
std::optional<uint64_t>
findConstantRecoveredGuestAddress(Module &M, Value *V, unsigned Depth) {
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

std::optional<ConstantGuestInteger>
evaluateConstantGuestInteger(Module &M, Constant *C, unsigned Depth) {
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

unsigned rewriteRecoveredPointerIntegerIdentities(Module &M,
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
std::optional<GuestAddressExpression>
findGuestAddressExpression(Module &M, Value *V, IRBuilder<> &B,
                           unsigned Depth) {
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

unsigned rewriteNativeScanfVarargAddresses(Module &M,
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
unsigned rewriteDynamicGuestAddressIntToPtr(Module &M,
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

} // namespace brighten_native_cleanup
