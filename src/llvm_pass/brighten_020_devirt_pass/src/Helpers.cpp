#include "BrightenDevirtPass.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

#include <cctype>
#include <cstring>
#include <limits>
#include <string>

namespace brighten_devirt {

using namespace llvm;

static std::optional<uint64_t> ParseHexPrefix(StringRef Text) {
  if (Text.empty()) {
    return std::nullopt;
  }

  size_t End = 0;
  while (End < Text.size() &&
         std::isxdigit(static_cast<unsigned char>(Text[End]))) {
    ++End;
  }
  if (End == 0) {
    return std::nullopt;
  }

  uint64_t Value = 0;
  if (Text.substr(0, End).getAsInteger(16, Value)) {
    return std::nullopt;
  }
  return Value;
}

std::optional<uint64_t> ParseAddressName(StringRef Name) {
  if (Name.empty()) {
    return std::nullopt;
  }

  uint64_t Raw = 0;
  if (!Name.getAsInteger(16, Raw)) {
    return Raw;
  }

  if (Name.starts_with("auto_sub_")) {
    return ParseHexPrefix(Name.drop_front(strlen("auto_sub_")));
  }
  if (Name.starts_with("callback_sub_")) {
    return ParseHexPrefix(Name.drop_front(strlen("callback_sub_")));
  }
  if (Name.starts_with("sub_")) {
    return ParseHexPrefix(Name.drop_front(strlen("sub_")));
  }
  if (Name.starts_with("ext_")) {
    return ParseHexPrefix(Name.drop_front(strlen("ext_")));
  }
  if (Name.starts_with("data_")) {
    return ParseHexPrefix(Name.drop_front(strlen("data_")));
  }
  if (Name.starts_with("seg_")) {
    return ParseHexPrefix(Name.drop_front(strlen("seg_")));
  }

  return std::nullopt;
}

Function *ResolveCalledFunction(Value *Callee) {
  if (!Callee) {
    return nullptr;
  }

  Value *V = Callee->stripPointerCasts();
  if (auto *Alias = dyn_cast<GlobalAlias>(V)) {
    if (Constant *Aliasee = Alias->getAliasee()) {
      V = Aliasee->stripPointerCasts();
    }
  }
  return dyn_cast<Function>(V);
}

static Value *StripAlias(Value *V) {
  if (!V) {
    return nullptr;
  }
  V = V->stripPointerCasts();
  if (auto *Alias = dyn_cast<GlobalAlias>(V)) {
    if (Constant *Aliasee = Alias->getAliasee()) {
      return Aliasee->stripPointerCasts();
    }
  }
  return V;
}

static Constant *ConstantAtOffset(Constant *C, Type *LoadTy, uint64_t Offset,
                                  const DataLayout &DL) {
  if (!C) {
    return nullptr;
  }

  if (Offset == 0) {
    if (C->getType() == LoadTy) {
      return C;
    }
    // Recovered pointer tables are typed as [N x ptr], while the lifted
    // code often reads one entry through an i64 load before handing it to a
    // Remill dispatcher.  Preserve the relocation as a pointer constant so
    // later devirtualization can recover the actual Function instead of
    // treating the entry as an opaque integer.
    if (C->getType()->isPointerTy() && LoadTy->isIntegerTy()) {
      return ConstantExpr::getPtrToInt(C, LoadTy);
    }
    if (C->getType()->isIntegerTy() && LoadTy->isPointerTy()) {
      return ConstantExpr::getIntToPtr(C, LoadTy);
    }
  }

  if (isa<ConstantAggregateZero>(C)) {
    uint64_t Size = DL.getTypeAllocSize(C->getType());
    uint64_t LoadSize = DL.getTypeStoreSize(LoadTy);
    if (Offset <= Size && LoadSize <= Size - Offset) {
      return Constant::getNullValue(LoadTy);
    }
    return nullptr;
  }

  if (auto *CDS = dyn_cast<ConstantDataSequential>(C)) {
    Type *ElemTy = CDS->getElementType();
    uint64_t ElemSize = DL.getTypeStoreSize(ElemTy);
    if (ElemSize == 0) {
      return nullptr;
    }

    if (ElemTy->isIntegerTy(8) && LoadTy->isIntegerTy()) {
      uint64_t LoadBytes = DL.getTypeStoreSize(LoadTy);
      if (Offset + LoadBytes > CDS->getNumElements()) {
        return nullptr;
      }

      unsigned Bits = cast<IntegerType>(LoadTy)->getBitWidth();
      APInt Value(Bits, 0);
      for (uint64_t I = 0; I < LoadBytes; ++I) {
        uint64_t Byte = CDS->getElementAsInteger(Offset + I) & 0xff;
        unsigned Shift =
            DL.isLittleEndian() ? static_cast<unsigned>(I * 8)
                                : static_cast<unsigned>((LoadBytes - 1 - I) * 8);
        Value |= APInt(Bits, Byte) << Shift;
      }
      return ConstantInt::get(LoadTy, Value);
    }

    if (Offset % ElemSize != 0) {
      return nullptr;
    }
    uint64_t Index = Offset / ElemSize;
    if (Index >= CDS->getNumElements()) {
      return nullptr;
    }
    Constant *Elem = CDS->getElementAsConstant(Index);
    return ConstantAtOffset(Elem, LoadTy, 0, DL);
  }

  if (auto *ArrTy = dyn_cast<ArrayType>(C->getType())) {
    uint64_t ElemSize = DL.getTypeAllocSize(ArrTy->getElementType());
    if (ElemSize == 0) {
      return nullptr;
    }
    uint64_t Index = Offset / ElemSize;
    if (Index >= ArrTy->getNumElements()) {
      return nullptr;
    }
    auto *Agg = dyn_cast<ConstantAggregate>(C);
    if (!Agg) {
      return nullptr;
    }
    return ConstantAtOffset(Agg->getOperand(Index), LoadTy, Offset % ElemSize,
                            DL);
  }

  if (auto *StructTy = dyn_cast<StructType>(C->getType())) {
    auto *Agg = dyn_cast<ConstantAggregate>(C);
    if (!Agg) {
      return nullptr;
    }
    const StructLayout *Layout = DL.getStructLayout(StructTy);
    unsigned Index = Layout->getElementContainingOffset(Offset);
    if (Index >= StructTy->getNumElements()) {
      return nullptr;
    }
    uint64_t ElemOff = Layout->getElementOffset(Index);
    return ConstantAtOffset(Agg->getOperand(Index), LoadTy, Offset - ElemOff,
                            DL);
  }

  return nullptr;
}

static std::optional<uint64_t> ExtractConstantLoadPC(LoadInst *LI,
                                                     const DataLayout &DL) {
  if (!LI || LI->isVolatile()) {
    return std::nullopt;
  }

  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base =
      LI->getPointerOperand()->stripAndAccumulateConstantOffsets(DL, Offset,
                                                                 true);
  if (!Base || Offset.isNegative()) {
    return std::nullopt;
  }

  Base = StripAlias(Base);
  auto *GV = dyn_cast<GlobalVariable>(Base);
  // Lifted guest segments are commonly mutable LLVM globals whose addresses
  // are hidden behind aliases.  Writes reach them through the guest-pointer
  // translator, so a scan of the global's direct LLVM users cannot prove the
  // initializer is still current.  Folding such a load (often an initial
  // zero in a GOT slot) silently turns a dynamic jump into the fallback path.
  if (!GV || !GV->hasInitializer() || !GV->isConstant()) {
    return std::nullopt;
  }

  Constant *Loaded =
      ConstantAtOffset(GV->getInitializer(), LI->getType(),
                       Offset.getZExtValue(), DL);
  if (!Loaded) {
    return std::nullopt;
  }

  return ExtractConstantPC(Loaded, DL);
}

static Function *ResolveFunctionFromConstantLoad(Value *V,
                                                 const DataLayout &DL) {
  auto *LI = dyn_cast<LoadInst>(V);
  if (!LI || LI->isVolatile()) {
    return nullptr;
  }

  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = LI->getPointerOperand()->stripAndAccumulateConstantOffsets(
      DL, Offset, true);
  if (!Base || Offset.isNegative()) {
    return nullptr;
  }
  Base = StripAlias(Base);
  auto *GV = dyn_cast<GlobalVariable>(Base);
  if (!GV || !GV->hasInitializer() || !GV->isConstant()) {
    return nullptr;
  }

  PointerType *PtrTy = PointerType::getUnqual(GV->getContext());
  Constant *Loaded = ConstantAtOffset(GV->getInitializer(), PtrTy,
                                      Offset.getZExtValue(), DL);
  if (!Loaded) {
    return nullptr;
  }
  Value *Stripped = Loaded->stripPointerCasts();
  return dyn_cast<Function>(Stripped);
}

std::optional<uint64_t> ExtractConstantPC(Value *V, const DataLayout &DL) {
  if (!V) {
    return std::nullopt;
  }

  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    return CI->getZExtValue();
  }

  if (auto *LI = dyn_cast<LoadInst>(V)) {
    return ExtractConstantLoadPC(LI, DL);
  }

  if (auto *PtrToInt = dyn_cast<PtrToIntOperator>(V)) {
    return ExtractConstantPC(PtrToInt->getPointerOperand(), DL);
  }

  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    auto BasePC = ExtractConstantPC(GEP->getPointerOperand(), DL);
    if (!BasePC) {
      return std::nullopt;
    }

    APInt Offset(DL.getIndexTypeSizeInBits(GEP->getType()), 0, true);
    if (!GEP->accumulateConstantOffset(DL, Offset)) {
      return std::nullopt;
    }

    int64_t SignedOffset = Offset.getSExtValue();
    if (SignedOffset < 0 &&
        *BasePC < static_cast<uint64_t>(-SignedOffset)) {
      return std::nullopt;
    }
    if (SignedOffset > 0 &&
        *BasePC > std::numeric_limits<uint64_t>::max() -
                      static_cast<uint64_t>(SignedOffset)) {
      return std::nullopt;
    }
    return static_cast<uint64_t>(*BasePC + SignedOffset);
  }

  if (auto *Op = dyn_cast<Operator>(V)) {
    if (Op->getOpcode() == Instruction::BitCast ||
        Op->getOpcode() == Instruction::AddrSpaceCast) {
      return ExtractConstantPC(Op->getOperand(0), DL);
    }
  }

  Value *Stripped = StripAlias(V);
  if (Stripped != V) {
    return ExtractConstantPC(Stripped, DL);
  }

  if (auto *GV = dyn_cast<GlobalValue>(V)) {
    return ParseAddressName(GV->getName());
  }

  return std::nullopt;
}

static unsigned LiftedRank(StringRef Name) {
  if (Name.starts_with("sub_")) {
    return 0;
  }
  if (Name.starts_with("auto_sub_")) {
    return 1;
  }
  if (Name.starts_with("callback_sub_")) {
    return 2;
  }
  uint64_t Ignored = 0;
  if (!Name.getAsInteger(16, Ignored)) {
    return 3;
  }
  return 4;
}

Function *FindLiftedSubroutineByPC(Module &M, uint64_t PC) {
  Function *Best = nullptr;
  unsigned BestRank = std::numeric_limits<unsigned>::max();

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    auto Parsed = ParseAddressName(F.getName());
    if (!Parsed || *Parsed != PC) {
      continue;
    }

    unsigned Rank = LiftedRank(F.getName());
    if (Rank < BestRank) {
      Best = &F;
      BestRank = Rank;
    }
  }

  return Best;
}

static std::optional<StringRef> ExternalNameFromExtStub(StringRef Name) {
  if (!Name.starts_with("ext_")) {
    return std::nullopt;
  }

  StringRef Rest = Name.drop_front(strlen("ext_"));
  size_t Sep = Rest.find('_');
  if (Sep == StringRef::npos || Sep + 1 >= Rest.size()) {
    return std::nullopt;
  }

  return Rest.drop_front(Sep + 1);
}

static Function *FindExternalByName(Module &M, StringRef Name) {
  if (Function *F = M.getFunction(Name)) {
    return F;
  }
  return nullptr;
}

static bool IsKnownExternalTarget(StringRef Name) {
  return Name == "__gmon_start__" || Name == "__cxa_finalize" ||
         Name == "__libc_start_main" || Name == "free" ||
         Name == "printf" || Name == "memset" || Name == "calloc" ||
         Name == "realloc" || Name == "__isoc99_scanf";
}

Function *FindExternalFunctionByPC(Module &M, uint64_t PC) {
  for (Function &F : M) {
    auto Parsed = ParseAddressName(F.getName());
    if (!Parsed || *Parsed != PC) {
      continue;
    }

    if (auto ExtName = ExternalNameFromExtStub(F.getName())) {
      if (Function *Ext = FindExternalByName(M, *ExtName)) {
        return Ext;
      }
    }

    if (F.isDeclaration()) {
      return &F;
    }
  }

  for (GlobalAlias &Alias : M.aliases()) {
    auto Parsed = ParseAddressName(Alias.getName());
    if (!Parsed || *Parsed != PC) {
      continue;
    }

    if (auto ExtName = ExternalNameFromExtStub(Alias.getName())) {
      if (Function *Ext = FindExternalByName(M, *ExtName)) {
        return Ext;
      }
    }

    if (Function *F = dyn_cast<Function>(Alias.getAliasee()->stripPointerCasts())) {
      if (F->isDeclaration()) {
        return F;
      }
    }
  }

  return nullptr;
}

Function *ResolveExternalFunction(Module &M, Value *PCVal, const DataLayout &DL) {
  if (!PCVal) {
    return nullptr;
  }

  // This is the post-global-recovery form of a dispatcher target:
  //   %pc = load i64, ptr getelementptr (... @g_ptrtable, ...)
  // The table is accepted only after proving that no instruction can mutate
  // it, so resolving it does not invent a target from arbitrary data.
  if (Function *F = ResolveFunctionFromConstantLoad(PCVal, DL)) {
    if (auto ExtName = ExternalNameFromExtStub(F->getName())) {
      if (Function *Ext = FindExternalByName(M, *ExtName)) {
        return Ext;
      }
    }
    if (F->isDeclaration() || IsKnownExternalTarget(F->getName())) {
      return F;
    }
  }

  Value *Ptr = nullptr;
  if (auto *PtrToInt = dyn_cast<PtrToIntOperator>(PCVal)) {
    Ptr = PtrToInt->getPointerOperand();
  } else if (auto *CE = dyn_cast<ConstantExpr>(PCVal);
             CE && CE->getOpcode() == Instruction::PtrToInt) {
    Ptr = CE->getOperand(0);
  }

  if (Ptr) {
    Ptr = StripAlias(Ptr);
    if (auto *F = dyn_cast<Function>(Ptr)) {
      if (auto ExtName = ExternalNameFromExtStub(F->getName())) {
        if (Function *Ext = FindExternalByName(M, *ExtName)) {
          return Ext;
        }
      }
      if (F->isDeclaration()) {
        return F;
      }
    }
  }

  auto PC = ExtractConstantPC(PCVal, DL);
  if (!PC) {
    return nullptr;
  }

  return FindExternalFunctionByPC(M, *PC);
}

Function *GetTranslateGuestPointerIfDefined(Module &M) {
  Function *F = M.getFunction("__translate_guest_pointer");
  if (!F || F->isDeclaration()) {
    return nullptr;
  }
  return F;
}

} // namespace brighten_devirt
