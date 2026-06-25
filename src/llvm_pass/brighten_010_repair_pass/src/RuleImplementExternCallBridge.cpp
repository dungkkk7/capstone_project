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
#include <map>

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
          if (Fn.isDeclaration() && ResolveGuestAddress(&Fn, *M) == Addr) {
            ExtFn = &Fn;
            break;
          }
        }
      }
      
      if (!ExtFn || !ExtFn->isDeclaration())
        return nullptr;
      if (ExtFn == &F)
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
      if (Fn.isDeclaration() && ResolveGuestAddress(&Fn, *M) == Addr) {
        return &Fn;
      }
    }
  }
  return nullptr;
  return nullptr;
}

static Function *GetOrCreateTranslateGuestPointer(Module &M) {
  if (auto *F = M.getFunction("__translate_guest_pointer")) {
    return F;
  }

  LLVMContext &Ctx = M.getContext();
  Type *Int64Ty = Type::getInt64Ty(Ctx);
  Type *Int1Ty = Type::getInt1Ty(Ctx);
  Type *PtrTy = PointerType::get(Ctx, 0);

  FunctionType *FTy = FunctionType::get(PtrTy, {Int64Ty, Int1Ty}, false);
  Function *F = Function::Create(FTy, GlobalValue::InternalLinkage, "__translate_guest_pointer", M);

  BasicBlock *EntryBB = BasicBlock::Create(Ctx, "entry", F);
  IRBuilder<> B(EntryBB);
  Value *GuestAddr = F->getArg(0);
  Value *IsKnownPointer = F->getArg(1);
  AllocaInst *DummyStack = B.CreateAlloca(B.getInt32Ty(), nullptr, "dummy_stack");

  const DataLayout &DL = M.getDataLayout();

  std::map<GlobalValue *, uint64_t> BaseAddresses;

  for (GlobalVariable &GV : M.globals()) {
    if (GV.isDeclaration()) continue;
    uint64_t Addr = ResolveGuestAddress(&GV, M);
    if (Addr > 0) {
      BaseAddresses[&GV] = Addr;
    }
  }

  for (GlobalAlias &GA : M.aliases()) {
    uint64_t Addr = ResolveGuestAddress(&GA, M);
    if (Addr > 0) {
      APInt ByteOffset(DL.getPointerSizeInBits(0), 0, true);
      Value *Base = GA.getAliasee()->stripAndAccumulateConstantOffsets(DL, ByteOffset, true);
      if (auto *GV = dyn_cast<GlobalValue>(Base)) {
        BaseAddresses[GV] = Addr - ByteOffset.getZExtValue();
      }
    }
  }

  for (Function &Fn : M) {
    if (Fn.isDeclaration()) continue;
    uint64_t Addr = ResolveGuestAddress(&Fn, M);
    if (Addr > 0) {
      BaseAddresses[&Fn] = Addr;
    }
  }

  struct GuestRange {
    uint64_t Start;
    uint64_t End;
    GlobalValue *GV;
  };
  std::vector<GuestRange> Ranges;

  for (auto &Pair : BaseAddresses) {
    GlobalValue *GV = Pair.first;
    uint64_t Addr = Pair.second;
    uint64_t Size = 1;
    if (auto *GVar = dyn_cast<GlobalVariable>(GV)) {
      Size = DL.getTypeAllocSize(GVar->getValueType());
    }

    GuestRange Range = {Addr, Addr + Size, GV};
    Ranges.push_back(Range);
  }

  BasicBlock *CurrentBB = EntryBB;
  for (const auto &Range : Ranges) {
    BasicBlock *MatchBB = BasicBlock::Create(Ctx, "match", F);
    BasicBlock *NextBB = BasicBlock::Create(Ctx, "next", F);

    B.SetInsertPoint(CurrentBB);
    Value *Cond1 = B.CreateICmpUGE(GuestAddr, B.getInt64(Range.Start));
    Value *Cond2 = B.CreateICmpULT(GuestAddr, B.getInt64(Range.End));
    Value *Cond = B.CreateAnd(Cond1, Cond2);
    B.CreateCondBr(Cond, MatchBB, NextBB);

    B.SetInsertPoint(MatchBB);
    Value *Offset = B.CreateSub(GuestAddr, B.getInt64(Range.Start));
    Value *BasePtr = B.CreateBitCast(Range.GV, PtrTy);
    Value *ResPtr = B.CreateGEP(Type::getInt8Ty(Ctx), BasePtr, Offset);
    B.CreateRet(ResPtr);

    CurrentBB = NextBB;
  }

  B.SetInsertPoint(CurrentBB);

  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");
  Value *FinalAddr = GuestAddr;

  if (StateGV) {
    Value *GuestAddr32 = B.CreateAnd(GuestAddr, B.getInt64(0xffffffffULL));
    
    // Check if GuestAddr32 >= 0x1000
    Value *InNonTrivialRange = B.CreateICmpUGE(GuestAddr32, B.getInt64(0x1000ULL));

    Value *UpperBits = B.CreateAnd(GuestAddr, B.getInt64(0xffffffff00000000ULL));
    Value *IsZeroUpper = B.CreateICmpEQ(UpperBits, B.getInt64(0));
    Value *IsSignExtended = B.CreateICmpEQ(UpperBits, B.getInt64(0xffffffff00000000ULL));
    Value *IsTruncatedPtr = B.CreateOr(IsZeroUpper, IsSignExtended);

    Value *StatePtrVal = B.CreatePtrToInt(StateGV, B.getInt64Ty());
    Value *StateLower = B.CreateAnd(StatePtrVal, B.getInt64(0xffffffffULL));
    Value *StackPtrVal = B.CreatePtrToInt(DummyStack, B.getInt64Ty());
    Value *StackLower = B.CreateAnd(StackPtrVal, B.getInt64(0xffffffffULL));

    // AbsDiffGlobal
    Value *DiffGlobal = B.CreateSub(GuestAddr32, StateLower);
    Value *IsNegGlobal = B.CreateICmpSLT(DiffGlobal, B.getInt64(0));
    Value *NegDiffGlobal = B.CreateNeg(DiffGlobal);
    Value *AbsDiffGlobal = B.CreateSelect(IsNegGlobal, NegDiffGlobal, DiffGlobal);

    // AbsDiffStack
    Value *DiffStack = B.CreateSub(GuestAddr32, StackLower);
    Value *IsNegStack = B.CreateICmpSLT(DiffStack, B.getInt64(0));
    Value *NegDiffStack = B.CreateNeg(DiffStack);
    Value *AbsDiffStack = B.CreateSelect(IsNegStack, NegDiffStack, DiffStack);

    // Check if distance to Global < 32MB or distance to Stack < 32MB
    Value *CloseToGlobal = B.CreateICmpULT(AbsDiffGlobal, B.getInt64(0x2000000ULL));
    Value *CloseToStack = B.CreateICmpULT(AbsDiffStack, B.getInt64(0x2000000ULL));
    Value *CloseToEither = B.CreateOr(CloseToGlobal, CloseToStack);

    Value *IsTruncatedHostPtr = B.CreateAnd(IsTruncatedPtr, B.CreateAnd(InNonTrivialRange, CloseToEither));
    Value *IsKnownPtrAndNonZero = B.CreateAnd(IsKnownPointer, B.CreateAnd(IsTruncatedPtr, B.CreateICmpNE(GuestAddr, B.getInt64(0))));
    Value *ShouldReconstruct = B.CreateOr(IsKnownPtrAndNonZero, IsTruncatedHostPtr);

    BasicBlock *ReconstructBB = BasicBlock::Create(Ctx, "reconstruct", F);
    BasicBlock *FinalBB = BasicBlock::Create(Ctx, "final", F);

    B.CreateCondBr(ShouldReconstruct, ReconstructBB, FinalBB);

    B.SetInsertPoint(ReconstructBB);
    Value *UseGlobalUpper = B.CreateICmpULT(AbsDiffGlobal, AbsDiffStack);
    Value *SelectedLower = B.CreateSelect(UseGlobalUpper, StateLower, StackLower);
    Value *SelectedPtrVal = B.CreateSelect(UseGlobalUpper, StatePtrVal, StackPtrVal);

    Value *Diff32 = B.CreateTrunc(B.CreateSub(GuestAddr32, SelectedLower), B.getInt32Ty());
    Value *Offset64 = B.CreateSExt(Diff32, B.getInt64Ty());
    Value *ReconstructedAddr = B.CreateAdd(SelectedPtrVal, Offset64);
    B.CreateBr(FinalBB);

    B.SetInsertPoint(FinalBB);
    PHINode *PHIRec = B.CreatePHI(B.getInt64Ty(), 2);
    PHIRec->addIncoming(GuestAddr, CurrentBB);
    PHIRec->addIncoming(ReconstructedAddr, ReconstructBB);
    FinalAddr = PHIRec;
  }

  Value *FallbackPtr = B.CreateIntToPtr(FinalAddr, PtrTy);
  B.CreateRet(FallbackPtr);

  return F;
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


  if (Name == "_setjmp" || Name == "setjmp" || Name == "sigsetjmp" || Name == "__sigsetjmp") {

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
      if (Offset == 2312/*RSP*/) {
        Val = B.CreateAdd(Val, B.getInt64(8));
      }
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

    // Call _setjmp
    Value *Env = LoadReg(B, StatePtr, 2296/*RDI*/, "env_val");
    Function *TranslateFn = GetOrCreateTranslateGuestPointer(*M);
    Value *EnvPtr = B.CreateCall(TranslateFn, {Env, B.getTrue()});
    
    FunctionCallee SetjmpFn = M->getOrInsertFunction(Name, B.getInt64Ty(), B.getPtrTy());
    Ret = B.CreateCall(SetjmpFn, {EnvPtr});

    // Check return value
    Value *IsZero = B.CreateICmpEQ(Ret, B.getInt64(0));
    
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

    // Load, translate và store 6 GP registers
    StoreTranslatedReg(kOffRDI, 0, "rdi");
    StoreTranslatedReg(kOffRSI, 1, "rsi");
    StoreTranslatedReg(kOffRDX, 2, "rdx");
    StoreTranslatedReg(kOffRCX, 3, "rcx");
    StoreTranslatedReg(kOffR8,  4, "r8");
    StoreTranslatedReg(kOffR9,  5, "r9");

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
      if (Name == "_setjmp" || Name == "setjmp" || Name == "sigsetjmp" || Name == "__sigsetjmp") {
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
    }
  }

  return Changed;
}

bool BrightenRepairPass::RepairExternalFunctionPointerDereferences(Module &M) {
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
              uint64_t Addr = ResolveGuestAddress(GV, M);
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
    uint64_t BaseAddr = ResolveGuestAddress(GV, M);

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

bool BrightenRepairPass::RepairIntToPtrDereferences(Module &M) {
  bool Changed = false;
  LLVMContext &Ctx = M.getContext();

  SmallVector<IntToPtrInst *, 64> IntToPtrs;

  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    if (F.getName() == "__translate_guest_pointer") continue;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *I2P = dyn_cast<IntToPtrInst>(&I)) {
          IntToPtrs.push_back(I2P);
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

}  // namespace brighten_repair
