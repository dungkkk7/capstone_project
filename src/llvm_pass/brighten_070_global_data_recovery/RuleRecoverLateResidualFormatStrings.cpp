#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

#include <map>
#include <limits>
#include <optional>
#include <string>
#include <vector>

namespace brighten_global {

using namespace llvm;

namespace {

struct GuestRange {
  uint64_t Begin;
  uint64_t End;
};

struct FormatRole {
  unsigned Index;
};

struct IntervalKey {
  GlobalVariable *Source;
  uint64_t Offset;
  uint64_t Size;

  bool operator<(const IntervalKey &Other) const {
    return std::tie(Source, Offset, Size) <
           std::tie(Other.Source, Other.Offset, Other.Size);
  }
};

struct Plan {
  CallBase *Call;
  unsigned FormatIndex;
  IntervalKey Key;
  GuestRange Range;
  std::vector<uint8_t> Bytes;
};

static std::optional<FormatRole> getFormatRole(const CallBase &CB) {
  const Function *Callee = CB.getCalledFunction();
  if (!Callee)
    return std::nullopt;
  StringRef Name = Callee->getName();
  if (Name.starts_with("__isoc99_"))
    Name = Name.drop_front(strlen("__isoc99_"));

  unsigned Index = 0;
  if (Name == "printf" || Name == "vprintf" || Name == "scanf" ||
      Name == "vscanf")
    Index = 0;
  else if (Name == "fprintf" || Name == "vfprintf" ||
           Name == "sprintf" || Name == "vsprintf" ||
           Name == "fscanf" || Name == "vfscanf" ||
           Name == "sscanf" || Name == "vsscanf")
    Index = 1;
  else if (Name == "snprintf" || Name == "vsnprintf")
    Index = 2;
  else
    return std::nullopt;

  if (CB.arg_size() <= Index)
    return std::nullopt;
  return FormatRole{Index};
}

static std::optional<GuestRange> getExactGuestRange(const GlobalVariable &GV,
                                                     const DataLayout &DL) {
  MDNode *MD = GV.getMetadata("brighten.guest.range");
  if (!MD || MD->getNumOperands() != 2)
    return std::nullopt;
  auto *Begin = mdconst::dyn_extract<ConstantInt>(MD->getOperand(0));
  auto *End = mdconst::dyn_extract<ConstantInt>(MD->getOperand(1));
  if (!Begin || !End || !Begin->getType()->isIntegerTy(64) ||
      !End->getType()->isIntegerTy(64))
    return std::nullopt;
  uint64_t B = Begin->getZExtValue();
  uint64_t E = End->getZExtValue();
  uint64_t Size = DL.getTypeAllocSize(GV.getValueType()).getFixedValue();
  if (Size == 0 || B > std::numeric_limits<uint64_t>::max() - Size ||
      E != B + Size)
    return std::nullopt;
  return GuestRange{B, E};
}

static bool getConstantGEPOffset(const GEPOperator &GEP, const DataLayout &DL,
                                 uint64_t &Offset) {
  APInt AP(DL.getIndexTypeSizeInBits(GEP.getPointerOperandType()), 0);
  if (!GEP.accumulateConstantOffset(DL, AP) || AP.isNegative())
    return false;
  Offset = AP.getZExtValue();
  return true;
}

// Read only storage that is explicitly represented as i8. Adjacent i8 array
// fields are allowed: lift-time aggregate padding often separates the final
// NUL from a format's printable bytes. Any scalar/pointer field is refused.
static bool readOneByte(Constant *Init, Type *Ty, const DataLayout &DL,
                        uint64_t Base, uint64_t Address, uint8_t &Out) {
  uint64_t Size = DL.getTypeAllocSize(Ty).getFixedValue();
  if (Address < Base || Address >= Base + Size)
    return false;
  if (auto *AT = dyn_cast<ArrayType>(Ty)) {
    if (!AT->getElementType()->isIntegerTy(8))
      return false;
    uint64_t Local = Address - Base;
    if (Local >= AT->getNumElements())
      return false;
    if (isa<ConstantAggregateZero>(Init)) {
      Out = 0;
      return true;
    }
    auto *CDA = dyn_cast<ConstantDataArray>(Init);
    if (!CDA)
      return false;
    Out = static_cast<uint8_t>(CDA->getElementAsInteger(Local));
    return true;
  }
  auto *ST = dyn_cast<StructType>(Ty);
  auto *CS = dyn_cast<ConstantStruct>(Init);
  if (!ST || !CS)
    return false;
  const StructLayout *Layout = DL.getStructLayout(ST);
  for (unsigned I = 0; I < ST->getNumElements(); ++I) {
    uint64_t FieldBase = Base + Layout->getElementOffset(I);
    uint64_t FieldSize = DL.getTypeAllocSize(ST->getElementType(I)).getFixedValue();
    if (Address >= FieldBase && Address < FieldBase + FieldSize)
      return readOneByte(cast<Constant>(CS->getOperand(I)),
                         ST->getElementType(I), DL, FieldBase, Address, Out);
  }
  return false;
}

static bool isPrintableFormatByte(uint8_t C) {
  return (C >= 0x20 && C <= 0x7e) || C == '\n' || C == '\r' || C == '\t';
}

static bool readExactNulString(Constant *Init, Type *Ty, const DataLayout &DL,
                               uint64_t Offset, uint64_t Limit,
                               std::vector<uint8_t> &Bytes) {
  if (Offset >= Limit)
    return false;
  Bytes.clear();
  for (uint64_t Address = Offset; Address < Limit; ++Address) {
    uint8_t Byte = 0;
    if (!readOneByte(Init, Ty, DL, 0, Address, Byte))
      return false;
    Bytes.push_back(Byte);
    if (Byte == 0) {
      if (Bytes.size() == 1)
        return false;
      return true;
    }
    if (!isPrintableFormatByte(Byte))
      return false;
  }
  Bytes.clear();
  return false;
}

static bool resolveConstantFormatAddress(Value *V, const DataLayout &DL,
                                         GlobalVariable *&Source,
                                         Constant *&Address,
                                         uint64_t &Offset) {
  auto *CE = dyn_cast<ConstantExpr>(V);
  if (!CE || CE->getOpcode() != Instruction::GetElementPtr)
    return false;
  auto *GEP = dyn_cast<GEPOperator>(CE);
  if (!GEP || !getConstantGEPOffset(*GEP, DL, Offset))
    return false;
  Source = dyn_cast<GlobalVariable>(GEP->getPointerOperand()->stripPointerCasts());
  if (!Source)
    return false;
  Address = CE;
  return true;
}

static bool expressionOnlyFeedsEquivalentFormatCalls(
    Constant *Address, const IntervalKey &Key, const DataLayout &DL) {
  if (!Address)
    return false;
  for (User *U : Address->users()) {
    auto *CB = dyn_cast<CallBase>(U);
    if (!CB)
      return false;
    auto Role = getFormatRole(*CB);
    if (!Role || CB->getArgOperand(Role->Index) != Address)
      return false;
    GlobalVariable *OtherSource = nullptr;
    Constant *OtherAddress = nullptr;
    uint64_t OtherOffset = 0;
    if (!resolveConstantFormatAddress(CB->getArgOperand(Role->Index), DL,
                                      OtherSource, OtherAddress, OtherOffset) ||
        OtherSource != Key.Source || OtherOffset != Key.Offset)
      return false;
  }
  return true;
}

} // namespace

bool RecoverLateResidualFormatStrings(Module &M) {
  const DataLayout &DL = M.getDataLayout();
  std::map<IntervalKey, std::vector<Plan>> Plans;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        auto Role = getFormatRole(*CB);
        if (!Role)
          continue;

        GlobalVariable *Source = nullptr;
        Constant *Address = nullptr;
        uint64_t Offset = 0;
        if (!resolveConstantFormatAddress(CB->getArgOperand(Role->Index), DL,
                                          Source, Address, Offset) ||
            !Source->hasLocalLinkage() || !Source->isConstant() ||
            !Source->hasInitializer())
          continue;
        auto Range = getExactGuestRange(*Source, DL);
        if (!Range || Offset >= Range->End - Range->Begin)
          continue;

        std::vector<uint8_t> Bytes;
        if (!readExactNulString(Source->getInitializer(), Source->getValueType(),
                                DL, Offset, Range->End - Range->Begin, Bytes))
          continue;
        uint64_t GuestBegin = Range->Begin + Offset;
        if (GuestBegin > Range->End || Bytes.size() > Range->End - GuestBegin)
          continue;
        IntervalKey Key{Source, Offset, static_cast<uint64_t>(Bytes.size())};
        if (!expressionOnlyFeedsEquivalentFormatCalls(Address, Key, DL))
          continue;
        Plans[Key].push_back(Plan{CB, Role->Index, Key,
                                  GuestRange{GuestBegin, GuestBegin + Bytes.size()},
                                  std::move(Bytes)});
      }
    }
  }

  bool Changed = false;
  unsigned NextId = 0;
  for (auto &[Key, Group] : Plans) {
    if (Group.empty())
      continue;
    const Plan &First = Group.front();
    bool Consistent = true;
    for (const Plan &P : Group)
      if (P.Bytes != First.Bytes || P.Range.Begin != First.Range.Begin ||
          P.Range.End != First.Range.End)
        Consistent = false;
    if (!Consistent)
      continue;

    LLVMContext &Ctx = M.getContext();
    ArrayType *Ty = ArrayType::get(Type::getInt8Ty(Ctx), First.Bytes.size());
    Constant *Init = ConstantDataArray::get(Ctx, First.Bytes);
    auto *StringGV = new GlobalVariable(
        M, Ty, /*isConstant=*/true, GlobalValue::PrivateLinkage, Init,
        ".late.residual.str." + std::to_string(NextId++));
    StringGV->setAlignment(Align(1));
    for (const Plan &P : Group)
      P.Call->setArgOperand(P.FormatIndex, StringGV);
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_global
