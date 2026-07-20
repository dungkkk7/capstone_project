#include "ABIModel.h"

#include "llvm/IR/DerivedTypes.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <cctype>

namespace brighten_abi {

using namespace llvm;

static constexpr ABIRegisterInfo kSysVRegisters[] = {
    {ABIReg::RAX, "RAX", 2216, 64, false, false, true, false},
    {ABIReg::RCX, "RCX", 2248, 64, true, false, false, false},
    {ABIReg::RDX, "RDX", 2264, 64, true, false, true, false},
    {ABIReg::RSI, "RSI", 2280, 64, true, false, false, false},
    {ABIReg::RDI, "RDI", 2296, 64, true, false, false, false},
    {ABIReg::RSP, "RSP", 2312, 64, false, false, false, true},
    {ABIReg::RBP, "RBP", 2328, 64, false, false, false, true},
    {ABIReg::R8, "R8", 2344, 64, true, false, false, false},
    {ABIReg::R9, "R9", 2360, 64, true, false, false, false},
    {ABIReg::RIP, "RIP", 2472, 64, false, false, false, true},
    {ABIReg::XMM0, "XMM0", 16, 128, false, true, true, false},
    {ABIReg::XMM1, "XMM1", 80, 128, false, true, true, false},
    {ABIReg::XMM2, "XMM2", 144, 128, false, true, false, false},
    {ABIReg::XMM3, "XMM3", 208, 128, false, true, false, false},
    {ABIReg::XMM4, "XMM4", 272, 128, false, true, false, false},
    {ABIReg::XMM5, "XMM5", 336, 128, false, true, false, false},
    {ABIReg::XMM6, "XMM6", 400, 128, false, true, false, false},
    {ABIReg::XMM7, "XMM7", 464, 128, false, true, false, false},
    {ABIReg::CF, "CF", 2065, 8, false, false, false, true},
    {ABIReg::PF, "PF", 2067, 8, false, false, false, true},
    {ABIReg::AF, "AF", 2069, 8, false, false, false, true},
    {ABIReg::ZF, "ZF", 2071, 8, false, false, false, true},
    {ABIReg::SF, "SF", 2073, 8, false, false, false, true},
    {ABIReg::OF, "OF", 2077, 8, false, false, false, true},
};

ArrayRef<ABIRegisterInfo> GetSysVRegisterTable() { return kSysVRegisters; }

const ABIRegisterInfo *GetRegisterInfo(ABIReg Reg) {
  for (const ABIRegisterInfo &Info : kSysVRegisters) {
    if (Info.Reg == Reg) {
      return &Info;
    }
  }
  return nullptr;
}

std::optional<ABIReg> RegisterForOffset(uint64_t Offset) {
  for (const ABIRegisterInfo &Info : kSysVRegisters) {
    if (Info.Offset == Offset) {
      return Info.Reg;
    }
  }
  return std::nullopt;
}

static std::string Upper(StringRef S) {
  std::string Out = S.str();
  std::transform(Out.begin(), Out.end(), Out.begin(), [](unsigned char C) {
    return static_cast<char>(std::toupper(C));
  });
  return Out;
}

std::optional<ABIReg> RegisterForName(StringRef Name) {
  if (Name.empty()) {
    return std::nullopt;
  }

  std::string U = Upper(Name);
  for (const ABIRegisterInfo &Info : kSysVRegisters) {
    StringRef RegName(Info.Name);
    std::string Underscore = (RegName.str() + "_");
    std::string Dot = (RegName.str() + ".");
    if (U == RegName || StringRef(U).starts_with(Underscore) ||
        StringRef(U).starts_with(Dot)) {
      return Info.Reg;
    }
  }
  return std::nullopt;
}

bool IsIntegerArgumentRegister(ABIReg Reg) {
  if (const ABIRegisterInfo *Info = GetRegisterInfo(Reg)) {
    return Info->IntegerArgument;
  }
  return false;
}

bool IsVectorArgumentRegister(ABIReg Reg) {
  if (const ABIRegisterInfo *Info = GetRegisterInfo(Reg)) {
    return Info->VectorArgument;
  }
  return false;
}

bool IsArgumentRegister(ABIReg Reg) {
  return IsIntegerArgumentRegister(Reg) || IsVectorArgumentRegister(Reg);
}

bool IsReturnRegister(ABIReg Reg) {
  if (const ABIRegisterInfo *Info = GetRegisterInfo(Reg)) {
    return Info->ReturnRegister;
  }
  return false;
}

bool IsIgnoredAsArgument(ABIReg Reg) {
  if (const ABIRegisterInfo *Info = GetRegisterInfo(Reg)) {
    return Info->IgnoredAsArgument;
  }
  return true;
}

bool IsFlagRegister(ABIReg Reg) {
  return Reg == ABIReg::CF || Reg == ABIReg::PF || Reg == ABIReg::AF ||
         Reg == ABIReg::ZF || Reg == ABIReg::SF || Reg == ABIReg::OF;
}

bool IsStackOrControlRegister(ABIReg Reg) {
  return Reg == ABIReg::RSP || Reg == ABIReg::RBP || Reg == ABIReg::RIP;
}

SmallVector<ABIReg, 8> GetSysVArgumentOrder() {
  return {ABIReg::RDI, ABIReg::RSI, ABIReg::RDX, ABIReg::RCX,
          ABIReg::R8,  ABIReg::R9,  ABIReg::XMM0, ABIReg::XMM1,
          ABIReg::XMM2, ABIReg::XMM3, ABIReg::XMM4, ABIReg::XMM5,
          ABIReg::XMM6, ABIReg::XMM7};
}

StringRef GetRegisterName(ABIReg Reg) {
  if (const ABIRegisterInfo *Info = GetRegisterInfo(Reg)) {
    return Info->Name;
  }
  return "Unknown";
}

std::string GetReturnKindName(ReturnKind Kind) {
  switch (Kind) {
  case ReturnKind::Void:
    return "void";
  case ReturnKind::IntRAX:
    return "RAX";
  case ReturnKind::PtrRAX:
    return "RAX.ptr";
  case ReturnKind::IntRDXRAX:
    return "RDX:RAX";
  case ReturnKind::FloatXMM0:
    return "XMM0.float";
  case ReturnKind::DoubleXMM0:
    return "XMM0.double";
  case ReturnKind::VectorXMM0:
    return "XMM0.vector";
  case ReturnKind::Unknown:
    return "unknown";
  }
  return "unknown";
}

std::string TypeToString(Type *Ty) {
  std::string S;
  raw_string_ostream OS(S);
  if (Ty) {
    Ty->print(OS);
  } else {
    OS << "<null>";
  }
  return OS.str();
}

Type *DefaultArgumentType(LLVMContext &Ctx, ABIReg Reg) {
  if (IsVectorArgumentRegister(Reg)) {
    return FixedVectorType::get(Type::getDoubleTy(Ctx), 2);
  }
  return Type::getInt64Ty(Ctx);
}

Type *DefaultReturnType(LLVMContext &Ctx, ReturnKind Kind) {
  switch (Kind) {
  case ReturnKind::Void:
    return Type::getVoidTy(Ctx);
  case ReturnKind::PtrRAX:
    return PointerType::getUnqual(Ctx);
  case ReturnKind::FloatXMM0:
    return Type::getFloatTy(Ctx);
  case ReturnKind::DoubleXMM0:
    return Type::getDoubleTy(Ctx);
  case ReturnKind::VectorXMM0:
    return FixedVectorType::get(Type::getDoubleTy(Ctx), 2);
  case ReturnKind::IntRDXRAX:
    return IntegerType::get(Ctx, 128);
  case ReturnKind::IntRAX:
  case ReturnKind::Unknown:
    return Type::getInt64Ty(Ctx);
  }
  return Type::getVoidTy(Ctx);
}

} // namespace brighten_abi
