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
#include "llvm/IR/IRBuilder.h"

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
  Type *Int64Ty = Type::getInt64Ty(Ctx);

  // 1. Thao tác trên tất cả các hàm callback_sub_*
  // Thay thế tất cả các references tới callback_sub_N bằng inttoptr(N)
  SmallVector<Function *, 16> Callbacks;
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    StringRef Name = F.getName();
    if (Name.starts_with("callback_sub_")) {
      Callbacks.push_back(&F);
    }
  }

  for (Function *F : Callbacks) {
    auto PC = ParseCallbackPC(F->getName());
    if (!PC.has_value()) continue;

    Constant *IntVal = ConstantInt::get(Int64Ty, *PC);
    Constant *Replacement = ConstantExpr::getIntToPtr(IntVal, F->getType());
    F->replaceAllUsesWith(Replacement);
    Changed = true;
  }

  // 2. Scan và dọn dẹp các PtrToIntInst thô đang chứa inttoptr
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    for (BasicBlock &BB : F) {
      for (auto InstIt = BB.begin(); InstIt != BB.end(); ) {
        Instruction &I = *InstIt++;
        if (auto *PTI = dyn_cast<PtrToIntInst>(&I)) {
          Value *Op = PTI->getOperand(0);
          if (auto *CE = dyn_cast<ConstantExpr>(Op)) {
            if (CE->getOpcode() == Instruction::IntToPtr) {
              Value *IntVal = CE->getOperand(0);
              if (IntVal->getType() == PTI->getType()) {
                PTI->replaceAllUsesWith(IntVal);
                PTI->eraseFromParent();
                Changed = true;
              } else {
                IRBuilder<> B(PTI);
                Value *CastVal = B.CreateIntCast(IntVal, PTI->getType(), false);
                PTI->replaceAllUsesWith(CastVal);
                PTI->eraseFromParent();
                Changed = true;
              }
            }
          } else if (auto *GV = dyn_cast<GlobalValue>(Op->stripPointerCasts())) {
            // Trường hợp PtrToIntInst trực tiếp trên sub_ hoặc callback_sub_ chưa bị thay thế
            if (auto PC = ParseCallbackPC(GV->getName())) {
              Value *ConstVal = ConstantInt::get(PTI->getType(), *PC);
              PTI->replaceAllUsesWith(ConstVal);
              PTI->eraseFromParent();
              Changed = true;
            }
          }
        }
      }
    }
  }

  return Changed;
}

}  // namespace brighten_repair

