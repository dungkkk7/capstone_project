#ifndef BRIGHTEN_050_ABI_MODEL_H
#define BRIGHTEN_050_ABI_MODEL_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Type.h"

#include <cstdint>
#include <optional>
#include <string>

namespace brighten_abi {

enum class ABIReg {
  RAX,
  RDX,
  RCX,
  RSI,
  RDI,
  R8,
  R9,
  RSP,
  RBP,
  RIP,
  XMM0,
  XMM1,
  XMM2,
  XMM3,
  XMM4,
  XMM5,
  XMM6,
  XMM7,
  CF,
  PF,
  AF,
  ZF,
  SF,
  OF,
  Unknown
};

enum class ReturnKind {
  Void,
  IntRAX,
  PtrRAX,
  IntRDXRAX,
  FloatXMM0,
  DoubleXMM0,
  VectorXMM0,
  Unknown
};

struct ABIRegisterInfo {
  ABIReg Reg;
  const char *Name;
  uint64_t Offset;
  unsigned WidthBits;
  bool IntegerArgument;
  bool VectorArgument;
  bool ReturnRegister;
  bool IgnoredAsArgument;
};

llvm::ArrayRef<ABIRegisterInfo> GetSysVRegisterTable();
const ABIRegisterInfo *GetRegisterInfo(ABIReg Reg);
std::optional<ABIReg> RegisterForOffset(uint64_t Offset);
std::optional<ABIReg> RegisterForName(llvm::StringRef Name);

bool IsIntegerArgumentRegister(ABIReg Reg);
bool IsVectorArgumentRegister(ABIReg Reg);
bool IsArgumentRegister(ABIReg Reg);
bool IsReturnRegister(ABIReg Reg);
bool IsIgnoredAsArgument(ABIReg Reg);
bool IsFlagRegister(ABIReg Reg);
bool IsStackOrControlRegister(ABIReg Reg);

llvm::SmallVector<ABIReg, 8> GetSysVArgumentOrder();

llvm::StringRef GetRegisterName(ABIReg Reg);
std::string GetReturnKindName(ReturnKind Kind);
std::string TypeToString(llvm::Type *Ty);

llvm::Type *DefaultArgumentType(llvm::LLVMContext &Ctx, ABIReg Reg);
llvm::Type *DefaultReturnType(llvm::LLVMContext &Ctx, ReturnKind Kind);

} // namespace brighten_abi

#endif
