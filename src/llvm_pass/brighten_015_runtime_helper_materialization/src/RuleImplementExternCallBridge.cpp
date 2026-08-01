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

#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include <vector>
#include <map>

#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Transforms/Utils/Cloning.h"

namespace brighten_runtime {

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
// XMM slots are 16-byte values in State.  The low 64 bits are at these
// offsets; this is the part used by the SysV scalar FP ABI.
static constexpr uint64_t kOffXMM0 = 16;
static constexpr uint64_t kOffXMM1 = 80;
static constexpr uint64_t kOffXMM2 = 144;
static constexpr uint64_t kOffXMM3 = 208;
static constexpr uint64_t kOffXMM4 = 272;
static constexpr uint64_t kOffXMM5 = 336;
static constexpr uint64_t kOffXMM6 = 400;
static constexpr uint64_t kOffXMM7 = 464;

static bool IsSetjmpName(StringRef Name) {
  return Name == "_setjmp" || Name == "setjmp" ||
         Name == "sigsetjmp" || Name == "__sigsetjmp";
}

static bool IsLongjmpName(StringRef Name) {
  return Name == "longjmp" || Name == "_longjmp" ||
         Name == "siglongjmp";
}

// McSema's imported declaration can retain the lifted i64 register type even
// for libc functions whose SysV ABI result is a pointer.  This intentionally
// names only the documented strchr contract; a generic i64 result has no
// provenance proof and must remain an integer.
static bool HasLiftedIntegerPointerReturnABI(const Function &F) {
  return F.getName() == "strchr" && F.getReturnType()->isIntegerTy(64) &&
         F.arg_size() == 2;
}

static bool IsSupportedDirectABIType(Type *Ty) {
  return Ty->isVoidTy() || Ty->isIntegerTy() || Ty->isPointerTy() ||
         Ty->isFloatTy() || Ty->isDoubleTy();
}

static bool IsSupportedDirectABI(Function *ExtFn) {
  FunctionType *FTy = ExtFn->getFunctionType();
  if (!IsSupportedDirectABIType(FTy->getReturnType()))
    return false;
  unsigned GPCount = 0;
  unsigned FPCount = 0;
  for (Type *Ty : FTy->params()) {
    if (!IsSupportedDirectABIType(Ty) || Ty->isVoidTy())
      return false;
    if (Ty->isFloatTy() || Ty->isDoubleTy())
      ++FPCount;
    else
      ++GPCount;
  }
  return GPCount <= 6 && FPCount <= 8;
}

// Load một thanh ghi i64 từ State tại byte offset đã biết.
static Value *LoadReg(IRBuilder<> &B, Value *StatePtr, uint64_t Offset,
                      const char *Name) {
  auto *GEP = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, Offset, Name);
  return B.CreateAlignedLoad(B.getInt64Ty(), GEP, Align(8), Name);
}

static uint64_t XMMOffset(unsigned Index) {
  static constexpr uint64_t Offsets[] = {
      kOffXMM0, kOffXMM1, kOffXMM2, kOffXMM3,
      kOffXMM4, kOffXMM5, kOffXMM6, kOffXMM7};
  return Index < 8 ? Offsets[Index] : kOffXMM0;
}

static Value *LoadFPArg(IRBuilder<> &B, Value *StatePtr, unsigned Index,
                        Type *ParamTy) {
  Value *Raw = LoadReg(B, StatePtr, XMMOffset(Index), "xmm_arg_bits");
  if (ParamTy->isDoubleTy())
    return B.CreateBitCast(Raw, ParamTy, "xmm_arg_double");
  if (ParamTy->isFloatTy()) {
    Value *Low32 = B.CreateTrunc(Raw, B.getInt32Ty(), "xmm_arg_float_bits");
    return B.CreateBitCast(Low32, ParamTy, "xmm_arg_float");
  }
  return nullptr;
}

static void StoreXMM0(IRBuilder<> &B, Value *StatePtr, Value *Val) {
  Value *Bits = nullptr;
  if (Val->getType()->isDoubleTy()) {
    Bits = B.CreateBitCast(Val, B.getInt64Ty(), "xmm0_ret_bits");
  } else if (Val->getType()->isFloatTy()) {
    Value *Low32 = B.CreateBitCast(Val, B.getInt32Ty(), "xmm0_ret_float_bits");
    Bits = B.CreateZExt(Low32, B.getInt64Ty(), "xmm0_ret_bits");
  }
  if (!Bits)
    return;
  auto *GEP = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, kOffXMM0,
                                   "xmm0_ret_ptr");
  B.CreateAlignedStore(Bits, GEP, Align(8));
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
  CallInst *TheCall = nullptr;
  for (Instruction &I : BB) {
    if (auto *CI = dyn_cast<CallInst>(&I)) {
      auto *Callee = CI->getCalledFunction();
      if (Callee != RemillCall)
        return nullptr;
      if (CI->arg_size() != 3)
        return nullptr;
      
      Value *Arg1 = CI->getArgOperand(1);
      Function *ExtFn = nullptr;
      if (auto *PtrToInt = dyn_cast<PtrToIntOperator>(Arg1)) {
        ExtFn = dyn_cast<Function>(PtrToInt->getPointerOperand());
      } else if (auto *ConstInt = dyn_cast<ConstantInt>(Arg1)) {
        uint64_t Addr = ConstInt->getZExtValue();
        Module *M = F.getParent();
        for (Function &Fn : *M) {
          if (Fn.isDeclaration() && ResolveGuestAddress(&Fn) == Addr) {
            ExtFn = &Fn;
            break;
          }
        }
      }
      
      if (!ExtFn || !ExtFn->isDeclaration())
        return nullptr;
      if (ExtFn == &F)
        return nullptr;
      if (!ExtFn->getFunctionType()->isVarArg() && !IsSupportedDirectABI(ExtFn))
        return nullptr;
      TheCall = CI;
    }
  }

  if (!TheCall)
    return nullptr;

  Value *Arg1 = TheCall->getArgOperand(1);
  if (auto *PtrToInt = dyn_cast<PtrToIntOperator>(Arg1)) {
    return cast<Function>(PtrToInt->getPointerOperand());
  } else if (auto *ConstInt = dyn_cast<ConstantInt>(Arg1)) {
    uint64_t Addr = ConstInt->getZExtValue();
    Module *M = F.getParent();
    for (Function &Fn : *M) {
      if (Fn.isDeclaration() && ResolveGuestAddress(&Fn) == Addr) {
        return &Fn;
      }
    }
  }
  return nullptr;
  return nullptr;
}



static bool IsExternalParamPointer(StringRef FuncName, unsigned ParamIdx) {
  if (FuncName == "malloc" || FuncName == "calloc") {
    return false;
  }
  if (FuncName == "realloc") {
    return ParamIdx == 0;
  }
  if (FuncName == "free" || FuncName == "fclose" || FuncName == "strlen" || 
      FuncName == "puts" || FuncName == "getchar" || FuncName == "putchar" || 
      FuncName == "localtime") {
    return ParamIdx == 0;
  }
  if (FuncName == "memcpy" || FuncName == "memmove" || FuncName == "strcpy" || 
      FuncName == "strncpy" || FuncName == "strcmp" || FuncName == "strncmp" || 
      FuncName == "strcat" || FuncName == "strncat" || FuncName == "strstr" || 
      FuncName == "strspn" || FuncName == "strcspn" || FuncName == "strpbrk" || 
      FuncName == "strtok" || FuncName == "strtol" || FuncName == "strtoll" || 
      FuncName == "strtoul" || FuncName == "strtoull" || FuncName == "strtod" || 
      FuncName == "fopen" || FuncName == "fputs" || FuncName == "fprintf" || 
      FuncName == "sprintf" || FuncName == "fscanf" || FuncName == "sscanf") {
    return ParamIdx == 0 || ParamIdx == 1;
  }
  if (FuncName == "memset") {
    return ParamIdx == 0;
  }
  if (FuncName == "fread" || FuncName == "fwrite") {
    return ParamIdx == 0 || ParamIdx == 3;
  }
  if (FuncName == "fgets") {
    return ParamIdx == 0 || ParamIdx == 2;
  }
  if (FuncName == "fputc") {
    return ParamIdx == 1;
  }
  if (FuncName == "printf" || FuncName == "scanf") {
    return ParamIdx == 0;
  }
  if (FuncName == "snprintf") {
    return ParamIdx == 0 || ParamIdx == 2;
  }
  if (FuncName == "qsort") {
    return ParamIdx == 0 || ParamIdx == 3;
  }
  if (FuncName == "bsearch") {
    return ParamIdx == 0 || ParamIdx == 1 || ParamIdx == 4;
  }
  if (FuncName == "time") {
    return ParamIdx == 0;
  }
  if (FuncName == "strftime") {
    return ParamIdx == 0 || ParamIdx == 2 || ParamIdx == 3;
  }
  return false;
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
  StringRef Name = ExtFn->getName();
  FunctionType *ExtFTy = ExtFn->getFunctionType();
  unsigned NumParams = ExtFTy->getNumParams();

  // Offset array theo thứ tự truyền argument x86_64 SysV
  static const uint64_t kArgRegs[] = {kOffRDI, kOffRSI, kOffRDX,
                                       kOffRCX, kOffR8,  kOffR9};

  Value *Ret = nullptr;


  if (IsLongjmpName(Name)) {
    ExtFn->addFnAttr(Attribute::NoReturn);
    ExtFn->removeFnAttr(Attribute::ReturnsTwice);
  }

  if (IsSetjmpName(Name)) {
    ExtFn->addFnAttr(Attribute::ReturnsTwice);
    ExtFn->removeFnAttr(Attribute::NoReturn);

    // 1. Allocate space on the host stack to save guest GPRs (17 * 8 = 136 bytes)
    auto *SavedGPRs = B.CreateAlloca(ArrayType::get(B.getInt64Ty(), 17), nullptr, "saved_gprs");

    // Helper to save a guest register
    auto SaveRegToBuf = [&](uint64_t Offset, unsigned idx) {
      Value *Val = LoadReg(B, StatePtr, Offset, "reg_val");
      Value *Slot = B.CreateConstGEP2_64(ArrayType::get(B.getInt64Ty(), 17), SavedGPRs, 0, idx);
      B.CreateStore(Val, Slot);
    };

    // Helper to restore a guest register
    auto RestoreRegFromBuf = [&](uint64_t Offset, unsigned idx) {
      Value *Slot = B.CreateConstGEP2_64(ArrayType::get(B.getInt64Ty(), 17), SavedGPRs, 0, idx);
      Value *Val = B.CreateLoad(B.getInt64Ty(), Slot);
      auto *GEP = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, Offset);
      B.CreateAlignedStore(Val, GEP, Align(8));
    };

    // Save all GPRs
    static const uint64_t kGPRs[] = {
      2216/*RAX*/, 2248/*RCX*/, 2264/*RDX*/, 2232/*RBX*/, 2312/*RSP*/, 2328/*RBP*/,
      2296/*RDI*/, 2280/*RSI*/, 2344/*R8*/,  2360/*R9*/,  2376/*R10*/, 2392/*R11*/,
      2408/*R12*/, 2424/*R13*/, 2440/*R14*/, 2456/*R15*/, 2472/*RIP*/
    };
    
    for (unsigned idx = 0; idx < 17; ++idx) {
      SaveRegToBuf(kGPRs[idx], idx);
    }

    // Call setjmp-family with the original McSema declaration type.
    // LLVM must see this as returns_twice; otherwise later SSA/cleanup passes
    // can legally miscompile the non-local return edge.
    Value *Env = LoadReg(B, StatePtr, 2296/*RDI*/, "env_val");
    Function *TranslateFn = GetOrCreateTranslateGuestPointer(*M);
    Value *EnvPtr = B.CreateCall(TranslateFn, {Env, B.getTrue()});

    auto CoerceArg = [&](Value *RawI64, Type *ParamTy,
                         bool ForcePointer) -> Value * {
      if (ParamTy->isPointerTy()) {
        if (ForcePointer) {
          return B.CreateBitCast(EnvPtr, ParamTy);
        }
        Value *Translated = B.CreateCall(TranslateFn, {RawI64, B.getTrue()});
        return B.CreateBitCast(Translated, ParamTy);
      }
      if (ParamTy->isIntegerTy()) {
        Value *V = RawI64;
        if (ForcePointer) {
          V = B.CreatePtrToInt(EnvPtr, B.getInt64Ty());
        }
        unsigned Bits = ParamTy->getIntegerBitWidth();
        if (Bits < 64) {
          return B.CreateTrunc(V, ParamTy);
        }
        if (Bits > 64) {
          return B.CreateZExt(V, ParamTy);
        }
        return V;
      }
      return ZeroValue(ParamTy);
    };

    SmallVector<Value *, 4> SetjmpArgs;
    for (unsigned i = 0; i < NumParams; ++i) {
      Type *ParamTy = ExtFTy->getParamType(i);
      if (i == 0) {
        SetjmpArgs.push_back(CoerceArg(Env, ParamTy, true));
      } else if (i < 6) {
        Value *RawI64 = LoadReg(B, StatePtr, kArgRegs[i], "setjmp_arg_reg");
        SetjmpArgs.push_back(CoerceArg(RawI64, ParamTy, false));
      } else {
        SetjmpArgs.push_back(ZeroValue(ParamTy));
      }
    }

    auto *SetjmpCall = B.CreateCall(ExtFTy, ExtFn, SetjmpArgs);
    SetjmpCall->setCallingConv(ExtFn->getCallingConv());
    SetjmpCall->addFnAttr(Attribute::ReturnsTwice);
    Ret = SetjmpCall;

    // Check return value
    Value *RetI64 = Ret;
    if (Ret->getType()->isIntegerTy() && !Ret->getType()->isIntegerTy(64)) {
      RetI64 = B.CreateZExt(Ret, B.getInt64Ty());
    } else if (Ret->getType()->isPointerTy()) {
      RetI64 = B.CreatePtrToInt(Ret, B.getInt64Ty());
    }
    Value *IsZero = B.CreateICmpEQ(RetI64, B.getInt64(0));
    
    BasicBlock *NormalBB = BasicBlock::Create(Ctx, "setjmp.normal", &Stub);
    BasicBlock *RestoreBB = BasicBlock::Create(Ctx, "setjmp.restore", &Stub);
    BasicBlock *MergeBB = BasicBlock::Create(Ctx, "setjmp.merge", &Stub);
    
    B.CreateCondBr(IsZero, NormalBB, RestoreBB);
    
    B.SetInsertPoint(NormalBB);
    B.CreateBr(MergeBB);
    
    B.SetInsertPoint(RestoreBB);
    for (unsigned idx = 0; idx < 17; ++idx) {
      RestoreRegFromBuf(kGPRs[idx], idx);
    }
    B.CreateBr(MergeBB);
    
    B.SetInsertPoint(MergeBB);
    StoreRAX(B, StatePtr, Ret);
  } else if (ExtFTy->isVarArg()) {
    StringRef Name = ExtFn->getName();
    bool IsScanfFamily = Name == "scanf" || Name == "__isoc99_scanf" ||
                         Name == "fscanf" || Name == "__isoc99_fscanf" ||
                         Name == "sscanf" || Name == "__isoc99_sscanf";
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

    // Helper load, translate and store register
    auto StoreTranslatedReg = [&](uint64_t Offset, unsigned idx, const char *name) {
      Value *Val = LoadReg(B, StatePtr, Offset, name);
      B.CreateStore(Val, GetSlot(idx));
    };

    // scanf-family varargs are write pointers.  The lifted call carries them
    // as guest integer addresses in the register save area; passing those
    // integers unchanged to vscanf/vfscanf makes libc dereference a guest
    // address (and commonly segfault).  Translate the variadic GP slots while
    // the original guest-address map is still available.  The later native
    // cleanup/global-data passes fold constant translations to native GEPs.
    auto StoreTranslatedScanfVarargReg = [&](unsigned idx, const char *name) {
      Value *Val = LoadReg(B, StatePtr, kArgRegs[idx], name);
      Function *TranslateFn = GetOrCreateTranslateGuestPointer(*M);
      Value *Translated = B.CreateCall(
          TranslateFn, {Val, B.getTrue()}, "scanf_vararg_ptr");
      Value *AsInt = B.CreatePtrToInt(Translated, B.getInt64Ty());
      B.CreateStore(AsInt, GetSlot(idx));
    };

    // Load, translate và store 6 GP registers
    StoreTranslatedReg(kOffRDI, 0, "rdi");
    StoreTranslatedReg(kOffRSI, 1, "rsi");
    StoreTranslatedReg(kOffRDX, 2, "rdx");
    StoreTranslatedReg(kOffRCX, 3, "rcx");
    StoreTranslatedReg(kOffR8,  4, "r8");
    StoreTranslatedReg(kOffR9,  5, "r9");

    if (IsScanfFamily) {
      unsigned FirstVararg = ActualNumParams < 6 ? ActualNumParams : 6;
      for (unsigned I = FirstVararg; I < 6; ++I) {
        StoreTranslatedScanfVarargReg(I, "scanf_vararg");
      }
    }

    // Load và store 8 FP/Vector registers (chỉ lấy low 8 bytes của XMM0-XMM7)
    StructType *StateType = nullptr;
    for (StructType *STy : M->getIdentifiedStructTypes()) {
      if (STy->getName().starts_with("struct.State")) {
        StateType = STy;
        break;
      }
    }
    for (unsigned k = 0; k < 8; ++k) {
      Value *GEP = B.CreateConstInBoundsGEP2_32(StateType, StatePtr, 0, 1, "xmm_ptr");
      Value *XMMGEP = B.CreateConstInBoundsGEP2_32(StateType->getElementType(1), GEP, 0, k, "xmm_k_ptr");
      Value *XMMVal = B.CreateAlignedLoad(B.getInt64Ty(), XMMGEP, Align(8));
      B.CreateStore(XMMVal, GetSlot(6 + k * 2));
    }

    // 2. Lấy guest RSP để tính overflow_arg_area
    Value *GuestRSP = LoadReg(B, StatePtr, 2312, "guest_rsp");
    Value *OverflowArgArea = B.CreateIntToPtr(B.CreateAdd(GuestRSP, B.getInt64(8)), B.getPtrTy());

    // 3. Cấp phát và khởi tạo struct va_list
    auto *VAList = B.CreateAlloca(VaListType, nullptr, "valist");
    
    unsigned GPCount = 0;
    unsigned FPCount = 0;
    for (unsigned i = 0; i < ActualNumParams; ++i) {
      if (i < ExtFTy->getNumParams()) {
        Type *ParamTy = ExtFTy->getParamType(i);
        if (ParamTy->isFloatingPointTy()) {
          FPCount++;
        } else {
          GPCount++;
        }
      } else {
        GPCount++;
      }
    }
    unsigned GPOffsetVal = GPCount * 8;
    unsigned FPOffsetVal = 48 + FPCount * 16;
    B.CreateStore(B.getInt32(GPOffsetVal), B.CreateStructGEP(VaListType, VAList, 0));
    B.CreateStore(B.getInt32(FPOffsetVal), B.CreateStructGEP(VaListType, VAList, 1));
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
      bool IsPointer = ParamTy->isPointerTy() || IsExternalParamPointer(ExtFn->getName(), i);
      if (IsPointer) {
        Function *TranslateFn = GetOrCreateTranslateGuestPointer(*M);
        Value *Translated = B.CreateCall(TranslateFn, {RawI64, B.getTrue()});
        if (ParamTy->isPointerTy()) {
          Arg = B.CreateBitCast(Translated, ParamTy);
        } else {
          Arg = B.CreatePtrToInt(Translated, ParamTy);
        }
      } else if (ParamTy->isIntegerTy(64)) {
        Arg = RawI64;
      } else if (ParamTy->isIntegerTy(32)) {
        Arg = B.CreateTrunc(RawI64, B.getInt32Ty());
      } else if (ParamTy->isIntegerTy()) {
        Arg = B.CreateTrunc(RawI64, ParamTy);
      } else {
        Arg = ZeroValue(ParamTy);
      }
      VArgs.push_back(Arg);
    }
    VArgs.push_back(VAList);

    Ret = B.CreateCall(VFunc, VArgs);
  } else {
    // Với non-vararg: phân loại argument theo SysV ABI.  Integer/pointer
    // arguments dùng dãy GPR; float/double dùng dãy XMM độc lập.
    SmallVector<Value *, 8> Args;
    unsigned GPIndex = 0;
    unsigned FPIndex = 0;
    for (unsigned i = 0; i < NumParams; ++i) {
      Type *ParamTy = ExtFTy->getParamType(i);
      Value *Arg = nullptr;
      if (ParamTy->isFloatingPointTy()) {
        if (FPIndex < 8)
          Arg = LoadFPArg(B, StatePtr, FPIndex, ParamTy);
        ++FPIndex;
      } else {
        uint64_t RegOff = GPIndex < 6 ? kArgRegs[GPIndex] : 0;
        ++GPIndex;
        if (RegOff != 0) {
          Value *RawI64 = LoadReg(B, StatePtr, RegOff, "arg_reg");
          bool IsPointer = ParamTy->isPointerTy() ||
                           IsExternalParamPointer(ExtFn->getName(), i);
          if (IsPointer) {
            Function *TranslateFn = GetOrCreateTranslateGuestPointer(*M);
            Value *Translated = B.CreateCall(TranslateFn, {RawI64, B.getTrue()});
            if (ParamTy->isPointerTy()) {
              Arg = B.CreateBitCast(Translated, ParamTy);
            } else {
              Arg = B.CreatePtrToInt(Translated, ParamTy);
            }
          } else if (ParamTy->isIntegerTy(64)) {
            Arg = RawI64;
          } else if (ParamTy->isIntegerTy(32)) {
            Arg = B.CreateTrunc(RawI64, B.getInt32Ty());
          } else if (ParamTy->isIntegerTy()) {
            Arg = B.CreateTrunc(RawI64, ParamTy);
          }
        }
      }
      if (!Arg) {
        // Không được bịa giá trị cho ABI chưa hỗ trợ.  Giữ stub nguyên
        // trạng thái bằng cách bỏ qua rewrite ở caller là tốt hơn, nhưng
        // ở đây các stub đã được xác định là scalar SysV signatures.
        Arg = ZeroValue(ParamTy);
      }
      Args.push_back(Arg);
    }
    auto *DirectCall = B.CreateCall(ExtFTy, ExtFn, Args);
    DirectCall->setCallingConv(ExtFn->getCallingConv());
    if (IsLongjmpName(Name)) {
      DirectCall->addFnAttr(Attribute::NoReturn);
    }
    Ret = DirectCall;
  }

  // Scalar FP returns live in XMM0; integer/pointer returns live in RAX.
  if (!ExtFTy->getReturnType()->isVoidTy() && Ret != nullptr) {
    if (ExtFTy->getReturnType()->isFloatingPointTy())
      StoreXMM0(B, StatePtr, Ret);
    else if (Ret->getType()->isPointerTy()) {
      // Lifted code performs subsequent pointer arithmetic in guest-address
      // space. A direct libc call returns a host pointer, so preserve the
      // original representation for known image objects before storing RAX.
      // Unknown/dynamic provenance remains a host integer fallback.
      Function *ToGuest = GetOrCreateGuestAddressFromPointer(*M);
      Value *GuestAddress = B.CreateCall(ToGuest, {Ret}, "guest_return_addr");
      StoreRAX(B, StatePtr, GuestAddress);
    } else if (HasLiftedIntegerPointerReturnABI(*ExtFn)) {
      // The direct call returned an ABI pointer in an i64 lifted declaration.
      // Re-establish guest representation only for this exact libc contract.
      Value *HostPointer = B.CreateIntToPtr(Ret, B.getPtrTy(),
                                             "strchr_host_return");
      Function *ToGuest = GetOrCreateGuestAddressFromPointer(*M);
      Value *GuestAddress = B.CreateCall(ToGuest, {HostPointer},
                                         "strchr_guest_return_addr");
      StoreRAX(B, StatePtr, GuestAddress);
    } else
      StoreRAX(B, StatePtr, Ret);
  }

  // Simulating the pop of the return address from guest stack (add guest RSP by 8)
  Value *GuestRSP = LoadReg(B, StatePtr, 2312, "guest_rsp");
  Value *NewRSP = B.CreateAdd(GuestRSP, B.getInt64(8), "new_rsp");
  auto *RSPGEP = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, 2312, "rsp_ptr");
  B.CreateAlignedStore(NewRSP, RSPGEP, Align(8));

  // Return memory arg
  Type *RetTy = Stub.getReturnType();
  if (RetTy->isPointerTy()) {
    B.CreateRet(MemArg);
  } else {
    B.CreateRetVoid();
  }
}

static bool InlineDirectCallsTo(Function &F) {
  SmallVector<CallBase *, 8> Calls;
  for (User *U : F.users()) {
    auto *CB = dyn_cast<CallBase>(U);
    if (!CB || CB->getCalledFunction() != &F) {
      continue;
    }
    Calls.push_back(CB);
  }

  bool Changed = false;
  for (CallBase *CB : Calls) {
    if (Function *Caller = CB->getFunction()) {
      Caller->addFnAttr(Attribute::ReturnsTwice);
    }
    InlineFunctionInfo IFI;
    InlineResult Res = InlineFunction(*CB, IFI);
    if (Res.isSuccess()) {
      Changed = true;
    } else {
      llvm::errs() << "BrightenRepair: failed to inline setjmp stub "
                   << F.getName() << ": " << Res.getFailureReason() << "\n";
    }
  }
  return Changed;
}

bool BrightenRuntimeHelperPass::ImplementExternCallBridge(Module &M) {
  // Tìm @__remill_function_call
  Function *RemillCall = M.getFunction("__remill_function_call");
  if (!RemillCall) {
    llvm::errs() << "RemillCall is null!\n";
    return false;
  }

  // Tìm @__mcsema_reg_state
  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");
  if (!StateGV) {
    llvm::errs() << "StateGV is null!\n";
    return false;
  }

  bool Changed = false;
  SmallVector<std::pair<Function *, Function *>, 8> Worklist;
  SmallVector<Function *, 4> SetjmpStubs;

  for (Function &F : M) {
    if (Function *ExtFn = MatchExternCallStub(F, RemillCall)) {
      Worklist.push_back({&F, ExtFn});
      StringRef Name = ExtFn->getName();
      if (IsSetjmpName(Name)) {
        SetjmpStubs.push_back(&F);
      }
    }
  }

  for (auto &[Stub, ExtFn] : Worklist) {
    RewriteStubToDirectCall(*Stub, ExtFn, StateGV);
    Changed = true;
  }

  if (!SetjmpStubs.empty()) {
    for (Function *Stub : SetjmpStubs) {
      Stub->removeFnAttr(Attribute::NoInline);
      Stub->addFnAttr(Attribute::AlwaysInline);
      Stub->addFnAttr(Attribute::ReturnsTwice);
      Changed |= InlineDirectCallsTo(*Stub);
    }
  }

  return Changed;
}

bool BrightenRuntimeHelperPass::RepairExternalFunctionPointerDereferences(Module &M) {
  bool Changed = false;
  LLVMContext &Ctx = M.getContext();
  Type *PtrTy = PointerType::get(Ctx, 0);

  // We will collect all GetElementPtrInsts to rewrite.
  SmallVector<GetElementPtrInst *, 32> GEPs;

  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
          Value *PtrOp = GEP->getPointerOperand()->stripPointerCasts();
          if (auto *GV = dyn_cast<GlobalValue>(PtrOp)) {
            if (GV->isDeclaration()) {
              uint64_t Addr = ResolveGuestAddress(GV);
              if (Addr > 0) {
                GEPs.push_back(GEP);
              }
            }
          }
        }
      }
    }
  }

  if (GEPs.empty()) {
    return false;
  }

  Function *TranslateFn = GetOrCreateTranslateGuestPointer(M);

  for (GetElementPtrInst *GEP : GEPs) {
    IRBuilder<> B(GEP);
    Value *PtrOp = GEP->getPointerOperand()->stripPointerCasts();
    auto *GV = cast<GlobalValue>(PtrOp);
    uint64_t BaseAddr = ResolveGuestAddress(GV);

    // 1. Calculate offset at runtime by applying the GEP to a null pointer of the same type.
    Value *BaseNull = ConstantPointerNull::get(cast<PointerType>(GEP->getPointerOperand()->getType()));
    
    // Collect indices
    SmallVector<Value *, 4> Idxs;
    for (auto It = GEP->idx_begin(); It != GEP->idx_end(); ++It) {
      Idxs.push_back(*It);
    }
    
    Value *OffsetGEP = B.CreateGEP(GEP->getSourceElementType(), BaseNull, Idxs, "gep_offset_ptr");
    Value *OffsetInt = B.CreatePtrToInt(OffsetGEP, B.getInt64Ty(), "gep_offset_bytes");

    // 2. Calculate the guest address: BaseAddr + OffsetInt
    Value *GuestAddr = B.CreateAdd(B.getInt64(BaseAddr), OffsetInt, "guest_addr");

    // 3. Translate guest address to host pointer
    Value *Translated = B.CreateCall(TranslateFn, {GuestAddr, B.getFalse()}, "translated_ptr");

    // 4. Bitcast the translated pointer to GEP's return type
    Value *Replacement = B.CreateBitCast(Translated, GEP->getType(), "replacement_ptr");

    // Replace and queue for deletion
    GEP->replaceAllUsesWith(Replacement);
    GEP->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

bool BrightenRuntimeHelperPass::RepairIntToPtrDereferences(Module &M) {
  bool Changed = false;
  LLVMContext &Ctx = M.getContext();

  SmallVector<IntToPtrInst *, 64> IntToPtrs;

  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    if (F.getName() == "__translate_guest_pointer") continue;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *I2P = dyn_cast<IntToPtrInst>(&I)) {
          Value *Src = I2P->getOperand(0);
          if (auto *CI = dyn_cast<ConstantInt>(Src)) {
            // Chỉ translate nếu hằng số địa chỉ guest nằm trong dải memory guest hợp lý
            if (CI->getZExtValue() < 0x800000000000ULL) {
              IntToPtrs.push_back(I2P);
            }
          } else {
            // Đối với các chỉ thị động, chúng ta vẫn chèn translate
            IntToPtrs.push_back(I2P);
          }
        }
      }
    }
  }

  if (IntToPtrs.empty()) {
    return false;
  }

  Function *TranslateFn = GetOrCreateTranslateGuestPointer(M);

  for (IntToPtrInst *I2P : IntToPtrs) {
    IRBuilder<> B(I2P);
    Value *Src = I2P->getOperand(0);

    // Call __translate_guest_pointer(Src)
    Value *Translated = B.CreateCall(TranslateFn, {Src, B.getFalse()}, "translated_ptr");
    
    // Cast to target pointer type
    Value *Replacement = B.CreateBitCast(Translated, I2P->getType());

    I2P->replaceAllUsesWith(Replacement);
    I2P->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

}  // namespace brighten_runtime
