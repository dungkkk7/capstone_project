// RuleFixCallbackFunctionPointerStores.cpp
//
// McSema emits indirect calls via function pointers using "callback thunks":
//   @callback_sub_1320 = private naked asm that jumps to the lifted sub
//   store i64 ptrtoint(@callback_sub_1320), ptr %stack_slot
//   ...
//   %pc = load i64, ptr %stack_slot
//   call @__remill_function_call(state, %pc, mem)   ← indirect call
//
// After optimization, callback thunks (private naked asm) get stripped/DCE'd,
// causing `ptrtoint(@callback_sub_1320)` to fold to ptrtoint(null) = 0.
// This breaks all indirect calls through function pointers.
//
// Fix: Before optimization, replace:
//   ptrtoint(@callback_sub_<hex>) → ConstantInt(hex)
//
// This preserves the ELF virtual address as a literal integer, matching
// the dispatcher switch table in __remill_function_call.

#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <string>

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"

namespace brighten_repair {

using namespace llvm;

namespace {

// Parse PC dari nama @callback_sub_<hex> atau @sub_<hex>.
static std::optional<uint64_t> ParseCallbackPC(StringRef Name) {
  StringRef Prefix;
  if (Name.starts_with("callback_sub_")) {
    Prefix = "callback_sub_";
  } else if (Name.starts_with("sub_")) {
    Prefix = "sub_";
  } else {
    return std::nullopt;
  }

  Name = Name.drop_front(Prefix.size());
  if (Name.empty()) {
    return std::nullopt;
  }

  size_t End = 0;
  while (End < Name.size() &&
         std::isxdigit(static_cast<unsigned char>(Name[End]))) {
    ++End;
  }
  if (End == 0) {
    return std::nullopt;
  }

  uint64_t PC = 0;
  if (Name.take_front(End).getAsInteger(16, PC)) {
    return std::nullopt;
  }
  return PC;
}

// Nếu V là ptrtoint(@callback_sub_<hex> to i64), trả về PC (hex value).
// Cũng xử lý ConstantExpr::PtrToInt wrapping.
static std::optional<uint64_t> ExtractCallbackPC(Value *V) {
  // Trực tiếp: ptrtoint(@callback_sub_N to i64) là ConstantExpr
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt) {
      Value *Inner = CE->getOperand(0)->stripPointerCasts();
      if (auto *GV = dyn_cast<GlobalValue>(Inner)) {
        return ParseCallbackPC(GV->getName());
      }
    }
  }
  // Direct global reference
  if (auto *GV = dyn_cast<GlobalValue>(V)) {
    return ParseCallbackPC(GV->getName());
  }
  return std::nullopt;
}

}  // namespace

bool BrightenRepairPass::FixCallbackFunctionPointerStores(Module &M) {
  bool Changed = false;
  LLVMContext &Ctx = M.getContext();

  // Scan tất cả instructions để tìm uses của ptrtoint(@callback_sub_*)
  SmallVector<std::pair<Use *, uint64_t>, 32> Replacements;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (Use &U : I.operands()) {
          auto PC = ExtractCallbackPC(U.get());
          if (PC.has_value()) {
            Replacements.push_back({&U, *PC});
          }
        }
      }
    }
  }

  // Cũng scan constant initializers của global variables.
  // (Ví dụ: @5 có thể chứa ptrtoint(@callback_sub_*))
  // Global init không dễ patch trực tiếp — bỏ qua cho safety.

  // Apply replacements
  for (auto &[U, PC] : Replacements) {
    // Xác định integer type của use
    Type *UsedTy = U->get()->getType();
    Type *IntTy = nullptr;
    if (UsedTy->isIntegerTy()) {
      IntTy = UsedTy;
    } else if (auto *CE = dyn_cast<ConstantExpr>(U->get())) {
      // ptrtoint result type
      if (CE->getOpcode() == Instruction::PtrToInt) {
        IntTy = CE->getType();
      }
    }
    if (!IntTy) {
      continue;
    }
    auto *NewVal = ConstantInt::get(cast<IntegerType>(IntTy), PC);
    U->set(NewVal);
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair
