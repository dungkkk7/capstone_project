// RuleImplementExternCallBridge.cpp
//
// Phát hiện các external-call stub được McSema sinh ra theo dạng:
//   define internal ptr @N(ptr %state, i64 %pc, ptr %mem) {
//     %r = call ptr @__remill_function_call(ptr state, i64 ptrtoint(@ext_fn), ptr %mem)
//     ret ptr %r
//   }
//
// Và viết lại thành direct call theo x86_64 SysV ABI:
//   - Đọc RDI/RSI/RDX/RCX/R8/R9/XMM0..7 từ @__mcsema_reg_state
//   - Gọi @ext_fn trực tiếp với các args này
//   - Ghi giá trị trả về (i64) vào RAX trong State
//   - Trả về %mem nguyên trạng
//
// Approach này đúng vì McSema luôn marshal args vào register slots
// trước khi gọi external stub.

#include "BrightenRepairPass.h"

#include <vector>

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"

namespace brighten_repair {

using namespace llvm;

// x86_64 SysV byte offsets trong struct State của McSema/Remill.
// Kiểm chứng từ IR: @RAX_2216, @RDI_2296, @RSI_2280, @RDX_2264,
//                   @RCX_2248, @R8_2344, @R9_2360.
static constexpr uint64_t kOffRAX = 2216;
static constexpr uint64_t kOffRDI = 2296;
static constexpr uint64_t kOffRSI = 2280;
static constexpr uint64_t kOffRDX = 2264;
static constexpr uint64_t kOffRCX = 2248;
static constexpr uint64_t kOffR8  = 2344;
static constexpr uint64_t kOffR9  = 2360;

// Load một thanh ghi i64 từ State tại byte offset đã biết.
static Value *LoadReg(IRBuilder<> &B, Value *StatePtr, uint64_t Offset,
                      const char *Name) {
  auto *GEP = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, Offset, Name);
  return B.CreateAlignedLoad(B.getInt64Ty(), GEP, Align(8), Name);
}

// Store một giá trị i64 vào thanh ghi RAX trong State.
static void StoreRAX(IRBuilder<> &B, Value *StatePtr, Value *Val) {
  auto *GEP = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, kOffRAX, "rax_ptr");
  // Truncate hoặc zext về i64 nếu cần.
  Value *V64 = Val;
  if (Val->getType()->isPointerTy()) {
    V64 = B.CreatePtrToInt(Val, B.getInt64Ty());
  } else if (Val->getType()->isIntegerTy() && !Val->getType()->isIntegerTy(64)) {
    V64 = B.CreateZExt(Val, B.getInt64Ty());
  } else if (Val->getType()->isFloatingPointTy()) {
    // float/double → bitcast to int, then zext; just zero for now
    V64 = B.getInt64(0);
  }
  B.CreateAlignedStore(V64, GEP, Align(8));
}

// Kiểm tra một Function có phải external-call stub không:
//   - internal linkage, 3 args (ptr, i64, ptr)
//   - body chỉ có 1 BB
//   - BB chứa đúng 1 call tới __remill_function_call với ptrtoint(@extFn)
//   - và 1 ret
// Nếu đúng, trả về @extFn, ngược lại nullptr.
static Function *MatchExternCallStub(Function &F, Function *RemillCall) {
  if (!RemillCall)
    return nullptr;
  if (F.isDeclaration())
    return nullptr;
  if (!F.hasLocalLinkage())
    return nullptr;
  if (F.arg_size() != 3)
    return nullptr;
  if (F.size() != 1)
    return nullptr;

  BasicBlock &BB = F.getEntryBlock();
  // Đếm instructions: phải là 2 (call + ret) hoặc có thể có 1-2 insts trước ret.
  CallInst *TheCall = nullptr;
  for (Instruction &I : BB) {
    if (auto *CI = dyn_cast<CallInst>(&I)) {
      auto *Callee = CI->getCalledFunction();
      if (Callee != RemillCall)
        return nullptr; // Gọi function khác → không phải stub đơn giản
      if (CI->arg_size() != 3)
        return nullptr;
      // Kiểm tra arg[1] là ptrtoint(@extFn to i64)
      auto *PtrToInt = dyn_cast<PtrToIntOperator>(CI->getArgOperand(1));
      if (!PtrToInt)
        return nullptr;
      auto *ExtFn = dyn_cast<Function>(PtrToInt->getPointerOperand());
      if (!ExtFn || !ExtFn->isDeclaration())
        return nullptr;
      // Tránh đệ quy (stub gọi chính nó)
      if (ExtFn == &F)
        return nullptr;
      TheCall = CI;
    }
  }

  if (!TheCall)
    return nullptr;

  // Lấy ExtFn từ call
  auto *PtrToInt = cast<PtrToIntOperator>(TheCall->getArgOperand(1));
  return cast<Function>(PtrToInt->getPointerOperand());
}

// Build body mới cho stub: đọc args từ State, call ExtFn, write RAX, ret mem.
static void RewriteStubToDirectCall(Function &Stub, Function *ExtFn,
                                    GlobalVariable *StateGV) {
  // Xóa tất cả basic blocks hiện tại
  while (!Stub.empty())
    Stub.begin()->eraseFromParent();

  LLVMContext &Ctx = Stub.getContext();
  Module *M = Stub.getParent();
  IRBuilder<> B(BasicBlock::Create(Ctx, "entry", &Stub));

  // Lấy danh sách args của Stub: (state_ptr, pc_i64, mem_ptr)
  auto ArgIt = Stub.arg_begin();
  // arg0 = state ptr (unused, chúng ta dùng StateGV trực tiếp)
  (void) ArgIt++;
  // arg1 = pc (unused)
  (void) ArgIt++;
  // arg2 = memory ptr
  Value *MemArg = &*ArgIt;

  Value *StatePtr = StateGV;
  FunctionType *ExtFTy = ExtFn->getFunctionType();
  unsigned NumParams = ExtFTy->getNumParams();

  // Offset array theo thứ tự truyền argument x86_64 SysV
  static const uint64_t kArgRegs[] = {kOffRDI, kOffRSI, kOffRDX,
                                       kOffRCX, kOffR8,  kOffR9};

  Value *Ret = nullptr;

  if (ExtFTy->isVarArg()) {
    StringRef Name = ExtFn->getName();
    unsigned ActualNumParams = NumParams;
    if (Name == "printf" || Name == "scanf" || Name == "__isoc99_scanf") {
      ActualNumParams = 1;
    } else if (Name == "fprintf" || Name == "sprintf" || Name == "sscanf" || Name == "__isoc99_sscanf" || Name == "fscanf" || Name == "__isoc99_fscanf") {
      ActualNumParams = 2;
    } else if (Name == "snprintf") {
      ActualNumParams = 3;
    }

    // Xây dựng struct va_list cho vararg call (printf, scanf, ...)
    // va_list struct:
    // struct {
    //   i32 gp_offset;
    //   i32 fp_offset;
    //   ptr overflow_arg_area;
    //   ptr reg_save_area;
    // }
    StructType *VaListType = StructType::getTypeByName(Ctx, "struct.__va_list_tag");
    if (!VaListType) {
      VaListType = StructType::create(
          Ctx,
          {B.getInt32Ty(), B.getInt32Ty(), B.getPtrTy(), B.getPtrTy()},
          "struct.__va_list_tag"
      );
    }

    // 1. Cấp phát reg_save_area trên stack: 6 * 8 (GP) + 8 * 16 (FP) = 176 bytes = 22 * i64
    auto *RegSaveArea = B.CreateAlloca(ArrayType::get(B.getInt64Ty(), 22), nullptr, "reg_save_area");

    // Helper store register
    auto GetSlot = [&](unsigned idx) {
      return B.CreateConstGEP2_64(ArrayType::get(B.getInt64Ty(), 22), RegSaveArea, 0, idx);
    };

    // Load và store 6 GP registers
    B.CreateStore(LoadReg(B, StatePtr, kOffRDI, "rdi"), GetSlot(0));
    B.CreateStore(LoadReg(B, StatePtr, kOffRSI, "rsi"), GetSlot(1));
    B.CreateStore(LoadReg(B, StatePtr, kOffRDX, "rdx"), GetSlot(2));
    B.CreateStore(LoadReg(B, StatePtr, kOffRCX, "rcx"), GetSlot(3));
    B.CreateStore(LoadReg(B, StatePtr, kOffR8,  "r8"),  GetSlot(4));
    B.CreateStore(LoadReg(B, StatePtr, kOffR9,  "r9"),  GetSlot(5));

    // Load và store 8 FP/Vector registers (chỉ lấy low 8 bytes của XMM0-XMM7)
    // Offset của XMMk trong State là 16 + k * 64
    for (unsigned k = 0; k < 8; ++k) {
      uint64_t XMMOff = 16 + k * 64;
      auto *GEP = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, XMMOff);
      Value *XMMVal = B.CreateAlignedLoad(B.getInt64Ty(), GEP, Align(8));
      B.CreateStore(XMMVal, GetSlot(6 + k * 2));
    }

    // 2. Lấy guest RSP để tính overflow_arg_area
    Value *GuestRSP = LoadReg(B, StatePtr, 2312, "guest_rsp");
    Value *OverflowArgArea = B.CreateIntToPtr(B.CreateAdd(GuestRSP, B.getInt64(8)), B.getPtrTy());

    // 3. Cấp phát và khởi tạo struct va_list
    auto *VAList = B.CreateAlloca(VaListType, nullptr, "valist");
    
    B.CreateStore(B.getInt32(ActualNumParams * 8), B.CreateStructGEP(VaListType, VAList, 0));
    B.CreateStore(B.getInt32(48),            B.CreateStructGEP(VaListType, VAList, 1));
    B.CreateStore(OverflowArgArea,           B.CreateStructGEP(VaListType, VAList, 2));
    B.CreateStore(B.CreateBitCast(RegSaveArea, B.getPtrTy()), B.CreateStructGEP(VaListType, VAList, 3));

    // 4. Tạo signature và định nghĩa cho hàm v-counterpart tương ứng
    std::string VName;
    if (Name == "printf") VName = "vprintf";
    else if (Name == "fprintf") VName = "vfprintf";
    else if (Name == "sprintf") VName = "vsprintf";
    else if (Name == "snprintf") VName = "vsnprintf";
    else if (Name == "scanf" || Name == "__isoc99_scanf") VName = "vscanf";
    else if (Name == "sscanf" || Name == "__isoc99_sscanf") VName = "vsscanf";
    else if (Name == "fscanf" || Name == "__isoc99_fscanf") VName = "vfscanf";
    else {
      VName = "v" + Name.str();
    }

    std::vector<Type *> VParams;
    for (unsigned i = 0; i < ActualNumParams; ++i) {
      if (i == 1 && Name == "snprintf") {
        VParams.push_back(B.getInt64Ty());
      } else {
        VParams.push_back(B.getPtrTy());
      }
    }
    VParams.push_back(B.getPtrTy()); // va_list type is ptr
    FunctionType *VFuncTy = FunctionType::get(ExtFTy->getReturnType(), VParams, false);
    FunctionCallee VFunc = M->getOrInsertFunction(VName, VFuncTy);

    // 5. Build arguments cho v-call
    SmallVector<Value *, 8> VArgs;
    for (unsigned i = 0; i < ActualNumParams; ++i) {
      Type *ParamTy = VParams[i];
      Value *RawI64 = LoadReg(B, StatePtr, kArgRegs[i], "fixed_arg_reg");
      Value *Arg = nullptr;
      if (ParamTy->isPointerTy()) {
        Arg = B.CreateIntToPtr(RawI64, ParamTy);
      } else if (ParamTy->isIntegerTy(64)) {
        Arg = RawI64;
      } else if (ParamTy->isIntegerTy(32)) {
        Arg = B.CreateTrunc(RawI64, B.getInt32Ty());
      } else if (ParamTy->isIntegerTy()) {
        Arg = B.CreateTrunc(RawI64, ParamTy);
      } else {
        Arg = UndefValue::get(ParamTy);
      }
      VArgs.push_back(Arg);
    }
    VArgs.push_back(VAList);

    Ret = B.CreateCall(VFunc, VArgs);
  } else {
    // Với non-vararg: load RDI, RSI, RDX, RCX, R8, R9
    SmallVector<Value *, 8> Args;
    for (unsigned i = 0; i < NumParams; ++i) {
      Type *ParamTy = ExtFTy->getParamType(i);
      uint64_t RegOff = (i < 6) ? kArgRegs[i] : 0;

      if (RegOff == 0) {
        Args.push_back(UndefValue::get(ParamTy));
        continue;
      }

      Value *RawI64 = LoadReg(B, StatePtr, RegOff, "arg_reg");
      Value *Arg = nullptr;
      if (ParamTy->isPointerTy()) {
        Arg = B.CreateIntToPtr(RawI64, ParamTy);
      } else if (ParamTy->isIntegerTy(64)) {
        Arg = RawI64;
      } else if (ParamTy->isIntegerTy(32)) {
        Arg = B.CreateTrunc(RawI64, B.getInt32Ty());
      } else if (ParamTy->isIntegerTy()) {
        Arg = B.CreateTrunc(RawI64, ParamTy);
      } else {
        Arg = UndefValue::get(ParamTy);
      }
      Args.push_back(Arg);
    }
    Ret = B.CreateCall(ExtFTy, ExtFn, Args);
  }

  // Store return value vào RAX nếu cần
  if (!ExtFTy->getReturnType()->isVoidTy() && Ret != nullptr) {
    StoreRAX(B, StatePtr, Ret);
  }

  // Return memory arg
  Type *RetTy = Stub.getReturnType();
  if (RetTy->isPointerTy()) {
    B.CreateRet(MemArg);
  } else {
    B.CreateRetVoid();
  }
}

bool BrightenRepairPass::ImplementExternCallBridge(Module &M) {
  // Tìm @__remill_function_call
  Function *RemillCall = M.getFunction("__remill_function_call");
  if (!RemillCall)
    return false;

  // Tìm @__mcsema_reg_state
  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");
  if (!StateGV)
    return false;

  bool Changed = false;
  SmallVector<std::pair<Function *, Function *>, 8> Worklist;

  for (Function &F : M) {
    if (Function *ExtFn = MatchExternCallStub(F, RemillCall)) {
      Worklist.push_back({&F, ExtFn});
    }
  }

  for (auto &[Stub, ExtFn] : Worklist) {
    RewriteStubToDirectCall(*Stub, ExtFn, StateGV);
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_repair
