// Helpers chung cho cac rule refine.
// - Tao helper fallback (noop call)
// - Tim lifted subroutine theo PC
// - Pattern matching/parse format/size inference
#include "BrightenRepairPass.h"

#include <cctype>
#include <cstdint>
#include <limits>
#include <optional>
#include <string>

#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_repair {

using namespace llvm;

Function *GetOrCreateNoopCallHelper(Module &M, FunctionType *FTy) {
  // Reuse nếu helper đã tồn tại để tránh tạo trùng symbol.
  if (auto *F = M.getFunction("__lifter_refine_noop_call")) {
    return F;
  }

  // Tạo helper fallback: nhận (state, pc, memory) và trả về memory nguyên trạng.
  auto *F = Function::Create(FTy, GlobalValue::InternalLinkage, "__lifter_refine_noop_call", M);
  auto *BB = BasicBlock::Create(M.getContext(), "entry", F);
  IRBuilder<> B(BB);

  auto *It = F->arg_begin();
  (void) *(It++);  // state
  (void) *(It++);  // pc
  Value *Mem = &*It;
  B.CreateRet(Mem);

  return F;
}

Function *FindLiftedSubroutineByPC(Module &M, uint64_t PC) {
  // Quy ước hàm lifted: sub_<hex_pc>.
  std::string Name = (Twine("sub_") + Twine::utohexstr(PC)).str();
  auto *F = M.getFunction(Name);
  if (F && !F->isDeclaration()) {
    return F;
  }
  return nullptr;
}

bool IsConstInt(Value *V, int64_t SignedVal) {
  // So sánh theo giá trị signed để dùng được cho các pattern i32 signed.
  auto *CI = dyn_cast<ConstantInt>(V);
  if (!CI) {
    return false;
  }
  return CI->getSExtValue() == SignedVal;
}

bool MatchAddIntMin32(Value *V, Value *&X) {
  // Match mẫu: X + INT32_MIN hoặc INT32_MIN + X.
  auto *Add = dyn_cast<BinaryOperator>(V);
  if (!Add || Add->getOpcode() != Instruction::Add) {
    return false;
  }
  if (!Add->getType()->isIntegerTy(32)) {
    return false;
  }

  Value *L = Add->getOperand(0);
  Value *R = Add->getOperand(1);
  if (IsConstInt(R, std::numeric_limits<int32_t>::min())) {
    X = L;
    return true;
  }
  if (IsConstInt(L, std::numeric_limits<int32_t>::min())) {
    X = R;
    return true;
  }
  return false;
}

bool IsScanfLikeCall(const CallInst *CI) {
  // Nhận diện các biến thể scanf phổ biến theo libc version.
  auto *Callee = CI->getCalledFunction();
  if (!Callee) {
    return false;
  }
  StringRef N = Callee->getName();
  return N == "scanf" || N == "__isoc99_scanf" || N == "__isoc23_scanf";
}

bool ParseSimplePercentS(StringRef Fmt, bool &HasWidth, uint64_t &Width) {
  // Chỉ parse format rất hẹp: "%s" hoặc "%<digits>s".
  // Nếu format phức tạp hơn thì trả false để rule bỏ qua (an toàn).
  HasWidth = false;
  Width = 0;
  if (!Fmt.starts_with("%")) {
    return false;
  }
  Fmt = Fmt.drop_front();
  if (Fmt.empty()) {
    return false;
  }

  uint64_t Parsed = 0;
  bool SawDigit = false;
  while (!Fmt.empty() && std::isdigit(static_cast<unsigned char>(Fmt.front()))) {
    SawDigit = true;
    Parsed = Parsed * 10 + static_cast<uint64_t>(Fmt.front() - '0');
    Fmt = Fmt.drop_front();
  }

  if (Fmt != "s") {
    return false;
  }

  HasWidth = SawDigit;
  Width = Parsed;
  return true;
}

std::optional<uint64_t> InferBaseObjectBytes(Value *Base, const DataLayout &DL) {
  // Trường hợp stack object (alloca).
  if (auto *AI = dyn_cast<AllocaInst>(Base)) {
    uint64_t ElemBytes = DL.getTypeAllocSize(AI->getAllocatedType());
    uint64_t Count = 1;
    if (AI->isArrayAllocation()) {
      auto *C = dyn_cast<ConstantInt>(AI->getArraySize());
      if (!C) {
        return std::nullopt;
      }
      Count = C->getZExtValue();
    }
    if (ElemBytes != 0 && Count > (std::numeric_limits<uint64_t>::max() / ElemBytes)) {
      return std::nullopt;
    }
    return ElemBytes * Count;
  }

  // Trường hợp global có initializer.
  if (auto *GV = dyn_cast<GlobalVariable>(Base)) {
    if (!GV->hasInitializer()) {
      return std::nullopt;
    }
    return DL.getTypeAllocSize(GV->getValueType());
  }

  auto *CB = dyn_cast<CallBase>(Base);
  if (!CB) {
    return std::nullopt;
  }
  auto *Callee = CB->getCalledFunction();
  if (!Callee) {
    return std::nullopt;
  }

  // Suy luận kích thước từ các allocator libc quen thuộc.
  StringRef Name = Callee->getName();
  if (Name == "malloc") {
    auto *C = dyn_cast<ConstantInt>(CB->getArgOperand(0));
    if (!C) {
      return std::nullopt;
    }
    return C->getZExtValue();
  }
  if (Name == "calloc") {
    auto *N = dyn_cast<ConstantInt>(CB->getArgOperand(0));
    auto *S = dyn_cast<ConstantInt>(CB->getArgOperand(1));
    if (!N || !S) {
      return std::nullopt;
    }
    uint64_t NV = N->getZExtValue();
    uint64_t SV = S->getZExtValue();
    if (SV != 0 && NV > (std::numeric_limits<uint64_t>::max() / SV)) {
      return std::nullopt;
    }
    return NV * SV;
  }
  if (Name == "realloc") {
    auto *C = dyn_cast<ConstantInt>(CB->getArgOperand(1));
    if (!C) {
      return std::nullopt;
    }
    return C->getZExtValue();
  }

  return std::nullopt;
}

std::optional<uint64_t> InferWritableBytesAtPointer(Value *Ptr, const DataLayout &DL) {
  // Tách pointer thành (base object + constant byte offset).
  APInt ByteOffset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Ptr->stripAndAccumulateConstantOffsets(DL, ByteOffset, true);
  if (ByteOffset.isNegative()) {
    return std::nullopt;
  }
  auto TotalOpt = InferBaseObjectBytes(Base, DL);
  if (!TotalOpt.has_value()) {
    return std::nullopt;
  }

  // Trả về số byte còn ghi được từ Ptr tới cuối object.
  uint64_t Total = *TotalOpt;
  uint64_t Offset = ByteOffset.getZExtValue();
  if (Offset >= Total) {
    return std::nullopt;
  }
  return Total - Offset;
}

uint64_t ResolveGuestAddress(GlobalValue *GV, Module &M) {
  StringRef Name = GV->getName();
  if (Name.starts_with("data_")) {
    StringRef Hex = Name.drop_front(5);
    uint64_t Val = 0;
    if (!Hex.getAsInteger(16, Val)) {
      return Val;
    }
  } else if (Name.starts_with("sub_")) {
    StringRef Hex = Name.drop_front(4);
    size_t Underscore = Hex.find('_');
    if (Underscore != StringRef::npos) {
      Hex = Hex.substr(0, Underscore);
    }
    uint64_t Val = 0;
    if (!Hex.getAsInteger(16, Val)) {
      return Val;
    }
  }

  // Scan functions, global variables and aliases for ext_<hex>_<name>
  std::string Suffix = (Twine("_") + Name).str();

  for (Function &F : M) {
    StringRef FName = F.getName();
    if (FName.starts_with("ext_") && FName.ends_with(Suffix)) {
      StringRef Hex = FName.drop_front(4).drop_back(Suffix.size());
      uint64_t Val = 0;
      if (!Hex.getAsInteger(16, Val)) return Val;
    }
  }
  for (GlobalVariable &GVar : M.globals()) {
    StringRef GName = GVar.getName();
    if (GName.starts_with("ext_") && GName.ends_with(Suffix)) {
      StringRef Hex = GName.drop_front(4).drop_back(Suffix.size());
      uint64_t Val = 0;
      if (!Hex.getAsInteger(16, Val)) return Val;
    }
  }
  for (GlobalAlias &GA : M.aliases()) {
    StringRef AName = GA.getName();
    if (AName.starts_with("ext_") && AName.ends_with(Suffix)) {
      StringRef Hex = AName.drop_front(4).drop_back(Suffix.size());
      uint64_t Val = 0;
      if (!Hex.getAsInteger(16, Val)) return Val;
    }
  }

  return 0;
}

}  // namespace brighten_repair


