// Define missing Remill control helpers so lifted modules link standalone.
//
// __remill_function_call: Quan trọng nhất — cần xử lý cả:
//   1) Constant PC (ptrtoint(@ext_fn)) → đã được ImplementExternCallBridge xử lý
//   2) Dynamic PC (load từ stack) → indirect call tới lifted sub_<pc>
//
// Thay vì noop đơn giản, ta tạo một dispatcher switch() trên tất cả
// lifted subroutines (sub_<hex>) và external stubs (ext_<hex>_*) để handle
// dynamic indirect calls đúng cách.
//
// __remill_jump cũng phải dispatch theo PC; noop làm rơi control-flow động.
// Các helpers còn lại (__remill_function_return, ...) vẫn là noop.

#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <set>
#include <string>
#include <vector>

#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

namespace brighten_repair {

using namespace llvm;

namespace {

static bool IsSimpleNoop(StringRef Name) {
  // Các helpers này không cần dispatch — chỉ return memory.
  return Name == "__remill_function_return" ||
         Name == "__remill_missing_block" ||
         Name == "__remill_async_hyper_call";
}

static bool HasMemoryThreadingSignature(const Function &F) {
  auto *FTy = F.getFunctionType();
  if (FTy->getNumParams() != 3 || !FTy->getReturnType()->isPointerTy()) {
    return false;
  }
  return FTy->getParamType(0)->isPointerTy() &&
         FTy->getParamType(1)->isIntegerTy() &&
         FTy->getParamType(2)->isPointerTy();
}

// Tạo thân hàm simple noop: return memory arg.
static bool DefineReturnMemory(Function &F) {
  if (!F.isDeclaration() || !HasMemoryThreadingSignature(F)) {
    return false;
  }
  BasicBlock *Entry = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(Entry);
  auto ArgIt = F.arg_begin();
  (void)*ArgIt++;  // state
  (void)*ArgIt++;  // pc
  Value *Memory = &*ArgIt;
  B.CreateRet(Memory);
  return true;
}

// Parse tên sub_<hex> hoặc ext_<hex>_* để lấy PC.
static std::optional<uint64_t> ParseDispatchPC(StringRef Name) {
  if (Name.starts_with("sub_")) {
    Name = Name.drop_front(4);
  } else if (Name.starts_with("ext_")) {
    Name = Name.drop_front(4);
  } else {
    return std::nullopt;
  }
  if (Name.empty()) {
    return std::nullopt;
  }
  // Strip hậu tố nếu có (ví dụ sub_a5a0_main → lấy a5a0)
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

// Tạo helper PC-dispatch với body là switch dispatch trên tất cả sub_<pc>.
// Nếu PC match một lifted subroutine → gọi trực tiếp.
// Default → return memory (noop fallback).
static bool DefineRemillPCDispatcher(Function &Helper, Module &M) {
  if (!Helper.isDeclaration() ||
      !HasMemoryThreadingSignature(Helper)) {
    return false;
  }

  LLVMContext &Ctx = M.getContext();
  FunctionType *FTy = Helper.getFunctionType();

  // Thu thập lifted subroutines và external stubs cùng signature.
  std::vector<std::pair<uint64_t, Function *>> Targets;
  std::set<uint64_t> SeenPCs;
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    auto PC = ParseDispatchPC(F.getName());
    if (!PC.has_value()) continue;
    // Chỉ chấp nhận functions với cùng signature (ptr, i64, ptr) -> ptr
    if (F.getFunctionType() != FTy) continue;
    if (!SeenPCs.insert(*PC).second) continue;
    Targets.push_back({*PC, &F});
  }

  // Tạo body
  BasicBlock *EntryBB = BasicBlock::Create(Ctx, "entry", &Helper);
  BasicBlock *DefaultBB = BasicBlock::Create(Ctx, "noop", &Helper);

  // Args
  auto ArgIt = Helper.arg_begin();
  Value *StateArg = &*ArgIt++;
  Value *PCArg = &*ArgIt++;
  Value *MemArg = &*ArgIt++;

  // Default block: noop return
  {
    IRBuilder<> B(DefaultBB);
    B.CreateRet(MemArg);
  }

  // Switch block
  {
    IRBuilder<> B(EntryBB);
    auto *Switch = B.CreateSwitch(PCArg, DefaultBB,
                                  static_cast<unsigned>(Targets.size()));
    for (auto &[PC, Target] : Targets) {
      auto *CaseVal = ConstantInt::get(
          cast<IntegerType>(PCArg->getType()), PC);
      BasicBlock *CaseBB =
          BasicBlock::Create(Ctx, "case_" + Target->getName(), &Helper);
      Switch->addCase(CaseVal, CaseBB);

      IRBuilder<> CB(CaseBB);
      auto *Call = CB.CreateCall(FTy, Target, {StateArg, PCArg, MemArg});
      CB.CreateRet(Call);
    }
  }

  return true;
}

}  // namespace

bool BrightenRepairPass::DefineRemillControlHelpers(Module &M) {
  bool Changed = false;

  for (Function &F : M) {
    StringRef Name = F.getName();

    if (Name == "__remill_function_call" || Name == "__remill_jump") {
      // Tạo dispatcher switch để handle static/dynamic PC.
      Changed |= DefineRemillPCDispatcher(F, M);
    } else if (IsSimpleNoop(Name)) {
      Changed |= DefineReturnMemory(F);
    }
  }

  return Changed;
}

}  // namespace brighten_repair
