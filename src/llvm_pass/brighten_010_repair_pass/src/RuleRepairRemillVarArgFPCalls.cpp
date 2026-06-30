// Fix vararg FP calls (printf-like) trong wrapper ext_.
// - Parse format de suy ra arg types
// - Chuyen alias/raw stack layout thanh double/int/ptr dung
#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

namespace brighten_repair {

using namespace llvm;

namespace {

enum class ArgKind { Int, Ptr, Double };

struct LibCallKind {
  StringRef Name;
  unsigned FormatGPRIndex;
  unsigned FirstVarArgGPRIndex;
};

struct ResolvedPtr {
  GlobalVariable *GV = nullptr;
  uint64_t Offset = 0;
};

static bool HasPrefixName(const Value *V, StringRef Prefix) {
  const auto *GV = dyn_cast<GlobalValue>(V);
  return GV && GV->getName().starts_with(Prefix);
}

static GlobalAlias *FindAlias(Module &M, StringRef Prefix, Type *Ty) {
  for (GlobalAlias &GA : M.aliases()) {
    if (GA.getName().starts_with(Prefix) && GA.getValueType() == Ty) {
      return &GA;
    }
  }
  return nullptr;
}

static std::optional<ResolvedPtr> ResolveConstantPointer(Constant *C, const DataLayout &DL) {
  if (!C) {
    return std::nullopt;
  }
  if (auto *GV = dyn_cast<GlobalVariable>(C)) {
    return ResolvedPtr{GV, 0};
  }
  if (auto *GA = dyn_cast<GlobalAlias>(C)) {
    return ResolveConstantPointer(GA->getAliasee(), DL);
  }
  if (auto *CE = dyn_cast<ConstantExpr>(C)) {
    unsigned Opcode = CE->getOpcode();
    if (Opcode == Instruction::BitCast || Opcode == Instruction::AddrSpaceCast) {
      return ResolveConstantPointer(CE->getOperand(0), DL);
    }
    if (Opcode == Instruction::GetElementPtr) {
      APInt Offset(DL.getPointerSizeInBits(0), 0);
      auto *GEP = cast<GEPOperator>(CE);
      if (!GEP->accumulateConstantOffset(DL, Offset) || Offset.isNegative()) {
        return std::nullopt;
      }
      auto Base = ResolveConstantPointer(cast<Constant>(GEP->getPointerOperand()), DL);
      if (!Base.has_value()) {
        return std::nullopt;
      }
      Base->Offset += Offset.getZExtValue();
      return Base;
    }
  }
  return std::nullopt;
}

static std::optional<uint8_t> ReadByte(Constant *C, uint64_t Offset, const DataLayout &DL) {
  if (!C) {
    return std::nullopt;
  }

  if (isa<ConstantAggregateZero>(C) || isa<UndefValue>(C)) {
    return Offset < DL.getTypeAllocSize(C->getType()) ? std::optional<uint8_t>(0) : std::nullopt;
  }

  if (auto *CDS = dyn_cast<ConstantDataSequential>(C)) {
    Type *ElemTy = CDS->getElementType();
    uint64_t ElemBytes = DL.getTypeAllocSize(ElemTy);
    if (ElemBytes == 0) {
      return std::nullopt;
    }
    uint64_t Index = Offset / ElemBytes;
    uint64_t Inner = Offset % ElemBytes;
    if (Index >= CDS->getNumElements()) {
      return std::nullopt;
    }
    if (ElemTy->isIntegerTy(8)) {
      return static_cast<uint8_t>(CDS->getElementAsInteger(Index));
    }
    if (auto *CI = dyn_cast<ConstantInt>(CDS->getElementAsConstant(Index))) {
      return static_cast<uint8_t>(CI->getValue().lshr(Inner * 8).getZExtValue() & 0xff);
    }
    return std::nullopt;
  }

  if (auto *CI = dyn_cast<ConstantInt>(C)) {
    uint64_t Bytes = DL.getTypeStoreSize(CI->getType());
    if (Offset >= Bytes) {
      return std::nullopt;
    }
    return static_cast<uint8_t>(CI->getValue().lshr(Offset * 8).getZExtValue() & 0xff);
  }

  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    auto *STy = cast<StructType>(CS->getType());
    const StructLayout *Layout = DL.getStructLayout(STy);
    for (unsigned I = 0, E = STy->getNumElements(); I != E; ++I) {
      uint64_t Begin = Layout->getElementOffset(I);
      uint64_t End = Begin + DL.getTypeAllocSize(STy->getElementType(I));
      if (Offset >= Begin && Offset < End) {
        return ReadByte(CS->getAggregateElement(I), Offset - Begin, DL);
      }
    }
    return std::nullopt;
  }

  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    Type *ElemTy = CA->getType()->getElementType();
    uint64_t ElemBytes = DL.getTypeAllocSize(ElemTy);
    if (ElemBytes == 0) {
      return std::nullopt;
    }
    uint64_t Index = Offset / ElemBytes;
    uint64_t Inner = Offset % ElemBytes;
    if (Index >= CA->getNumOperands()) {
      return std::nullopt;
    }
    return ReadByte(cast<Constant>(CA->getOperand(Index)), Inner, DL);
  }

  return std::nullopt;
}

static std::optional<std::string> ReadCString(Constant *Ptr, const DataLayout &DL) {
  auto Resolved = ResolveConstantPointer(Ptr, DL);
  if (!Resolved.has_value() || !Resolved->GV->hasInitializer()) {
    return std::nullopt;
  }

  std::string Out;
  Constant *Init = Resolved->GV->getInitializer();
  for (unsigned I = 0; I < 4096; ++I) {
    auto Byte = ReadByte(Init, Resolved->Offset + I, DL);
    if (!Byte.has_value()) {
      return std::nullopt;
    }
    if (*Byte == 0) {
      return Out;
    }
    Out.push_back(static_cast<char>(*Byte));
  }
  return std::nullopt;
}

static std::optional<LibCallKind> ClassifyWrapper(Function *F) {
  if (!F || !F->getName().starts_with("ext_")) {
    return std::nullopt;
  }

  StringRef Name = F->getName();
  if (Name.ends_with("_printf")) {
    return LibCallKind{"printf", 0, 1};
  }
  if (Name.ends_with("_fprintf")) {
    return LibCallKind{"fprintf", 1, 2};
  }
  if (Name.ends_with("_sprintf")) {
    return LibCallKind{"sprintf", 1, 2};
  }
  if (Name.ends_with("_snprintf")) {
    return LibCallKind{"snprintf", 2, 3};
  }
  return std::nullopt;
}

static bool ParseFormat(StringRef Fmt, std::vector<ArgKind> &Args, bool &HasFP) {
  HasFP = false;

  for (size_t I = 0; I < Fmt.size(); ++I) {
    if (Fmt[I] != '%') {
      continue;
    }
    ++I;
    if (I >= Fmt.size()) {
      return false;
    }
    if (Fmt[I] == '%') {
      continue;
    }

    while (I < Fmt.size() && StringRef("-+ #0'").contains(Fmt[I])) {
      ++I;
    }

    if (I < Fmt.size() && Fmt[I] == '*') {
      Args.push_back(ArgKind::Int);
      ++I;
    } else {
      while (I < Fmt.size() && std::isdigit(static_cast<unsigned char>(Fmt[I]))) {
        ++I;
      }
    }

    if (I < Fmt.size() && Fmt[I] == '.') {
      ++I;
      if (I < Fmt.size() && Fmt[I] == '*') {
        Args.push_back(ArgKind::Int);
        ++I;
      } else {
        while (I < Fmt.size() && std::isdigit(static_cast<unsigned char>(Fmt[I]))) {
          ++I;
        }
      }
    }

    if (I >= Fmt.size()) {
      return false;
    }
    if (Fmt.substr(I).starts_with("hh")) {
      I += 2;
    } else if (Fmt.substr(I).starts_with("ll")) {
      I += 2;
    } else if (StringRef("hljztLq").contains(Fmt[I])) {
      ++I;
    }
    if (I >= Fmt.size()) {
      return false;
    }

    switch (Fmt[I]) {
      case 'a':
      case 'A':
      case 'e':
      case 'E':
      case 'f':
      case 'F':
      case 'g':
      case 'G':
        Args.push_back(ArgKind::Double);
        HasFP = true;
        break;
      case 's':
      case 'p':
      case 'n':
        Args.push_back(ArgKind::Ptr);
        break;
      case 'd':
      case 'i':
      case 'u':
      case 'o':
      case 'x':
      case 'X':
      case 'c':
        Args.push_back(ArgKind::Int);
        break;
      default:
        return false;
    }
  }

  return true;
}

static Constant *FindLastStoredConstantToReg(CallInst *CI, StringRef RegPrefix) {
  for (auto It = CI->getIterator(); It != CI->getParent()->begin();) {
    --It;
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (!SI) {
      continue;
    }
    if (!HasPrefixName(SI->getPointerOperand()->stripPointerCasts(), RegPrefix)) {
      continue;
    }
    return dyn_cast<Constant>(SI->getValueOperand()->stripPointerCasts());
  }
  return nullptr;
}

static Value *LoadReg(IRBuilder<> &B, Module &M, StringRef Prefix, Type *Ty) {
  if (GlobalAlias *GA = FindAlias(M, Prefix, Ty)) {
    return B.CreateLoad(Ty, GA);
  }

  Type *I64Ty = B.getInt64Ty();
  if (Ty->isPointerTy()) {
    if (auto *I64Alias = FindAlias(M, Prefix, I64Ty)) {
      return B.CreateIntToPtr(B.CreateLoad(I64Ty, I64Alias), Ty);
    }
  }
  if (Ty->isIntegerTy(64)) {
    if (auto *PtrAlias = FindAlias(M, Prefix, B.getPtrTy())) {
      return B.CreatePtrToInt(B.CreateLoad(B.getPtrTy(), PtrAlias), I64Ty);
    }
  }

  return UndefValue::get(Ty);
}

static Value *LoadStackArg(IRBuilder<> &B, Module &M, unsigned StackIndex) {
  auto *RspPtr = FindAlias(M, "RSP_", B.getPtrTy());
  auto *I64Ty = B.getInt64Ty();
  if (!RspPtr) {
    return UndefValue::get(I64Ty);
  }
  Value *Base = B.CreateLoad(B.getPtrTy(), RspPtr);
  Value *Slot = B.CreateConstGEP1_32(I64Ty, Base, static_cast<int>(StackIndex + 1));
  return B.CreateLoad(I64Ty, Slot);
}

static Value *ReadGPRArg(IRBuilder<> &B, Module &M, unsigned GPRIndex, ArgKind Kind,
                         unsigned &StackIndex) {
  static constexpr StringRef Prefixes[] = {"RDI_", "RSI_", "RDX_", "RCX_", "R8_", "R9_"};
  if (GPRIndex < 6) {
    Type *ArgTy = Kind == ArgKind::Ptr ? static_cast<Type *>(B.getPtrTy())
                                       : static_cast<Type *>(B.getInt64Ty());
    return LoadReg(B, M, Prefixes[GPRIndex], ArgTy);
  }

  Value *Raw = LoadStackArg(B, M, StackIndex++);
  return Kind == ArgKind::Ptr ? B.CreateIntToPtr(Raw, B.getPtrTy()) : Raw;
}

static Value *ReadXMMArg(IRBuilder<> &B, Module &M, unsigned XMMIndex) {
  SmallString<16> Prefix;
  Prefix += "XMM";
  Prefix += Twine(XMMIndex).str();
  Prefix += "_";
  return LoadReg(B, M, Prefix, B.getDoubleTy());
}

static FunctionCallee GetLibCallee(Module &M, const LibCallKind &Kind) {
  LLVMContext &Ctx = M.getContext();
  Type *I32Ty = Type::getInt32Ty(Ctx);
  Type *I64Ty = Type::getInt64Ty(Ctx);
  Type *PtrTy = PointerType::get(Ctx, 0);

  if (Function *Existing = M.getFunction(Kind.Name)) {
    return Existing;
  }
  if (Kind.Name == "printf") {
    return M.getOrInsertFunction("printf", FunctionType::get(I32Ty, {PtrTy}, true));
  }
  if (Kind.Name == "fprintf") {
    return M.getOrInsertFunction("fprintf", FunctionType::get(I32Ty, {PtrTy, PtrTy}, true));
  }
  if (Kind.Name == "sprintf") {
    return M.getOrInsertFunction("sprintf", FunctionType::get(I32Ty, {PtrTy, PtrTy}, true));
  }
  if (Kind.Name == "snprintf") {
    return M.getOrInsertFunction("snprintf", FunctionType::get(I32Ty, {PtrTy, I64Ty, PtrTy}, true));
  }
  return nullptr;
}

static void StoreReturnToRAX(IRBuilder<> &B, Module &M, Value *Ret) {
  auto *RAX = FindAlias(M, "RAX_", B.getInt64Ty());
  if (!RAX) {
    return;
  }
  if (Ret->getType()->isIntegerTy(64)) {
    B.CreateStore(Ret, RAX);
  } else if (Ret->getType()->isIntegerTy()) {
    B.CreateStore(B.CreateZExtOrTrunc(Ret, B.getInt64Ty()), RAX);
  } else if (Ret->getType()->isPointerTy()) {
    B.CreateStore(B.CreatePtrToInt(Ret, B.getInt64Ty()), RAX);
  }
}

static void AdvanceSyntheticRSP(IRBuilder<> &B, Module &M) {
  auto *RSP = FindAlias(M, "RSP_", B.getInt64Ty());
  if (!RSP) {
    return;
  }
  Value *Old = B.CreateLoad(B.getInt64Ty(), RSP);
  B.CreateStore(B.CreateAdd(Old, B.getInt64(8)), RSP);
}

static bool RewriteCall(CallInst *CI, const LibCallKind &Kind, Constant *FormatPtr,
                        ArrayRef<ArgKind> VarArgs) {
  Module &M = *CI->getModule();
  IRBuilder<> B(CI);
  FunctionCallee Callee = GetLibCallee(M, Kind);
  if (!Callee) {
    return false;
  }

  std::vector<Value *> Args;
  if (Kind.Name == "printf") {
    Args.push_back(FormatPtr);
  } else if (Kind.Name == "fprintf" || Kind.Name == "sprintf") {
    Args.push_back(LoadReg(B, M, "RDI_", B.getPtrTy()));
    Args.push_back(FormatPtr);
  } else if (Kind.Name == "snprintf") {
    Args.push_back(LoadReg(B, M, "RDI_", B.getPtrTy()));
    Args.push_back(LoadReg(B, M, "RSI_", B.getInt64Ty()));
    Args.push_back(FormatPtr);
  } else {
    return false;
  }

  unsigned GPRIndex = Kind.FirstVarArgGPRIndex;
  unsigned StackIndex = 0;
  unsigned XMMIndex = 0;
  for (ArgKind AK : VarArgs) {
    if (AK == ArgKind::Double) {
      Args.push_back(ReadXMMArg(B, M, XMMIndex++));
    } else {
      Args.push_back(ReadGPRArg(B, M, GPRIndex++, AK, StackIndex));
    }
  }

  CallInst *NewCall = B.CreateCall(Callee, Args);
  StoreReturnToRAX(B, M, NewCall);
  AdvanceSyntheticRSP(B, M);
  CI->replaceAllUsesWith(CI->getArgOperand(2));
  CI->eraseFromParent();
  return true;
}

}  // namespace

bool BrightenRepairPass::RepairRemillVarArgFPCalls(Module &M) {
  const DataLayout &DL = M.getDataLayout();
  std::vector<CallInst *> Worklist;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (CI && !CI->isInlineAsm() && ClassifyWrapper(CI->getCalledFunction()).has_value()) {
          Worklist.push_back(CI);
        }
      }
    }
  }

  bool Changed = false;
  static constexpr StringRef GPRPrefixes[] = {"RDI_", "RSI_", "RDX_", "RCX_", "R8_", "R9_"};
  for (CallInst *CI : Worklist) {
    auto Kind = ClassifyWrapper(CI->getCalledFunction());
    if (!Kind.has_value() || Kind->FormatGPRIndex >= std::size(GPRPrefixes)) {
      continue;
    }

    Constant *FormatPtr = FindLastStoredConstantToReg(CI, GPRPrefixes[Kind->FormatGPRIndex]);
    auto Format = ReadCString(FormatPtr, DL);
    if (!Format.has_value()) {
      continue;
    }

    std::vector<ArgKind> Args;
    bool HasFP = false;
    if (!ParseFormat(*Format, Args, HasFP) || !HasFP) {
      continue;
    }

    Changed |= RewriteCall(CI, *Kind, FormatPtr, Args);
  }

  return Changed;
}

}  // namespace brighten_repair
