#ifndef BRIGHTEN_050_REGISTER_ACCESS_H
#define BRIGHTEN_050_REGISTER_ACCESS_H

#include "ABIModel.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Value.h"

#include <cstdint>
#include <optional>

namespace brighten_abi {

struct RegAccess {
  llvm::Instruction *Inst = nullptr;
  ABIReg Reg = ABIReg::Unknown;
  bool IsLoad = false;
  bool IsStore = false;
  llvm::Type *AccessType = nullptr;
  llvm::Value *Value = nullptr;
  uint64_t Offset = 0;
};

std::optional<uint64_t> IdentifyStateOffset(llvm::Value *Ptr);
std::optional<ABIReg> IdentifyStateRegisterPointer(llvm::Value *Ptr);
std::optional<RegAccess> IdentifyRegAccess(llvm::Instruction &I);

llvm::Value *BuildStateRegisterPointer(llvm::IRBuilder<> &B,
                                       llvm::Value *StateBase, ABIReg Reg);

} // namespace brighten_abi

#endif
