#include "BrightenDevirtPass.h"

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>

namespace brighten_devirt {

using namespace llvm;

static constexpr uint64_t kOffRAX = 2216;
static constexpr uint64_t kOffRDI = 2296;
static constexpr uint64_t kOffRSI = 2280;
static constexpr uint64_t kOffRDX = 2264;
static constexpr uint64_t kOffRCX = 2248;
static constexpr uint64_t kOffR8 = 2344;
static constexpr uint64_t kOffR9 = 2360;
static constexpr uint64_t kOffXMM0 = 16;
static constexpr uint64_t kOffXMM1 = 80;
static constexpr uint64_t kOffXMM2 = 144;

static bool IsGenericSafeExternalName(StringRef Name) {
  return Name == "puts" || Name == "putchar" || Name == "strlen" ||
         Name == "strcmp" || Name == "strncmp" || Name == "strcpy" ||
         Name == "strncpy" || Name == "strcat" || Name == "memcpy" ||
         Name == "memmove" || Name == "memset" || Name == "malloc" ||
         Name == "calloc" || Name == "realloc" || Name == "free" ||
         Name == "__cxa_finalize" || Name == "__gmon_start__" ||
         Name == "fopen" || Name == "fclose" || Name == "fread" ||
         Name == "fwrite" || Name == "fgets" || Name == "fputs" ||
         Name == "time" || Name == "localtime" || Name == "cos" ||
         Name == "sin";
}

static bool IsScanfFamilyName(StringRef Name) {
  return Name == "scanf" || Name == "__isoc99_scanf" ||
         Name == "__isoc23_scanf" || Name == "sscanf" ||
         Name == "__isoc99_sscanf" || Name == "fscanf" ||
         Name == "__isoc99_fscanf";
}

static bool RequiresSpecialExternalBridge(StringRef Name) {
  return Name == "setjmp" || Name == "_setjmp" ||
         Name == "__sigsetjmp" || Name == "sigsetjmp" ||
         Name == "longjmp" || Name == "_longjmp" ||
         Name == "siglongjmp" || Name == "qsort" ||
         Name == "bsearch" || Name == "atexit" ||
         Name == "signal" || Name == "pthread_create" ||
         Name == "fork" || Name == "system" ||
         Name.starts_with("exec");
}

static Value *LoadReg(IRBuilder<> &B, Value *StatePtr, uint64_t Offset,
                      const Twine &Name) {
  Value *Ptr = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, Offset,
                                    Name + ".ptr");
  return B.CreateAlignedLoad(B.getInt64Ty(), Ptr, Align(8), Name);
}

static Value *CoerceInt(IRBuilder<> &B, Value *Raw, Type *Ty) {
  unsigned Bits = Ty->getIntegerBitWidth();
  if (Bits < 64) {
    return B.CreateTrunc(Raw, Ty);
  }
  if (Bits > 64) {
    return B.CreateZExt(Raw, Ty);
  }
  return Raw;
}

static Value *CoercePointer(IRBuilder<> &B, Value *Raw, Type *Ty,
                            Function *TranslateFn, bool IsWrite) {
  Value *Translated = B.CreateCall(TranslateFn, {Raw, B.getInt1(IsWrite)},
                                   "translated_ptr");
  if (Translated->getType() == Ty) {
    return Translated;
  }
  if (Translated->getType()->isPointerTy() && Ty->isIntegerTy()) {
    return B.CreatePtrToInt(Translated, Ty);
  }
  if (Translated->getType()->isIntegerTy() && Ty->isPointerTy()) {
    return B.CreateIntToPtr(Translated, Ty);
  }
  return B.CreateBitCast(Translated, Ty);
}

static Value *CoerceArg(IRBuilder<> &B, Value *Raw, Type *Ty,
                        Function *TranslateFn, bool IsWritePointer,
                        bool IsPointer) {
  if (Ty->isPointerTy() || IsPointer) {
    return CoercePointer(B, Raw, Ty, TranslateFn, IsWritePointer);
  }
  if (Ty->isIntegerTy()) {
    return CoerceInt(B, Raw, Ty);
  }
  if (Ty->isFloatTy()) {
    return B.CreateBitCast(B.CreateTrunc(Raw, B.getInt32Ty()), Ty);
  }
  if (Ty->isDoubleTy()) {
    return B.CreateBitCast(Raw, Ty);
  }
  return Constant::getNullValue(Ty);
}

static bool IsFloatingType(Type *Ty) {
  return Ty && (Ty->isFloatTy() || Ty->isDoubleTy());
}

static bool IsWritePointerArg(StringRef Name, unsigned Index) {
  if ((Name == "memcpy" || Name == "memmove") && Index == 0) {
    return true;
  }
  if (Name == "memset" && Index == 0) {
    return true;
  }
  if (Name == "fread" && Index == 0) {
    return true;
  }
  if (Name == "fgets" && Index == 0) {
    return true;
  }
  if (Name == "time" && Index == 0) {
    return true;
  }
  return false;
}

// McSema commonly declares libc pointer parameters as i64.  For these
// symbols the ABI type alone is therefore insufficient: translate the guest
// integer before the call and coerce it back to the declaration's type.
static bool IsPointerArg(StringRef Name, unsigned Index) {
  if (Name == "free" || Name == "puts" || Name == "strlen" ||
      Name == "strcmp" || Name == "strncmp" || Name == "strcpy" ||
      Name == "strncpy" || Name == "strcat" || Name == "strncat" ||
      Name == "strstr" || Name == "strchr" || Name == "strrchr" ||
      Name == "memcpy" || Name == "memmove" || Name == "memcmp")
    return Index < 2;
  if (Name == "memset")
    return Index == 0;
  if (Name == "fclose" || Name == "fputs" || Name == "fopen")
    return Index < 2;
  if (Name == "fgets")
    return Index == 0 || Index == 2;
  if (Name == "fread" || Name == "fwrite")
    return Index == 0 || Index == 3;
  if (Name == "realloc")
    return Index == 0;
  if (Name == "strtol" || Name == "strtoll" || Name == "strtoul" ||
      Name == "strtoull" || Name == "strtod")
    return Index < 2;
  return false;
}

static bool HasUnsupportedArgOrReturnTypes(FunctionType *FTy) {
  Type *RetTy = FTy->getReturnType();
  if (!RetTy->isVoidTy() && !RetTy->isIntegerTy() &&
      !RetTy->isPointerTy() && !IsFloatingType(RetTy)) {
    return true;
  }

  for (Type *ParamTy : FTy->params()) {
    if (!ParamTy->isIntegerTy() && !ParamTy->isPointerTy() &&
        !IsFloatingType(ParamTy)) {
      return true;
    }
  }

  return false;
}

static void StoreRAX(IRBuilder<> &B, Value *StatePtr, Value *Ret) {
  if (!Ret || Ret->getType()->isVoidTy()) {
    return;
  }

  Value *Ret64 = nullptr;
  Type *Ty = Ret->getType();
  if (Ty->isPointerTy()) {
    Ret64 = B.CreatePtrToInt(Ret, B.getInt64Ty());
  } else if (Ty->isIntegerTy()) {
    unsigned Bits = Ty->getIntegerBitWidth();
    if (Bits < 64) {
      Ret64 = B.CreateZExt(Ret, B.getInt64Ty());
    } else if (Bits > 64) {
      Ret64 = B.CreateTrunc(Ret, B.getInt64Ty());
    } else {
      Ret64 = Ret;
    }
  } else {
    errs() << "[devirt] WARNING: external fp return not stored in RAX\n";
    return;
  }

  Value *RAXPtr =
      B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, kOffRAX, "rax.ptr");
  B.CreateAlignedStore(Ret64, RAXPtr, Align(8));
}

static void StoreFPReturnInXMM0(IRBuilder<> &B, Value *StatePtr, Value *Ret) {
  if (!Ret || !IsFloatingType(Ret->getType()))
    return;
  Value *Bits = nullptr;
  if (Ret->getType()->isDoubleTy()) {
    Bits = B.CreateBitCast(Ret, B.getInt64Ty(), "xmm0.ret.bits");
  } else {
    Value *Low = B.CreateBitCast(Ret, B.getInt32Ty(), "xmm0.ret.low");
    Bits = B.CreateZExt(Low, B.getInt64Ty(), "xmm0.ret.bits");
  }
  Value *XMM0Ptr = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr,
                                         kOffXMM0, "xmm0.ptr");
  B.CreateAlignedStore(Bits, XMM0Ptr, Align(8));
}

static bool IsRemillCall(CallBase *CB, Function *RemillCall) {
  return RemillCall && ResolveCalledFunction(CB->getCalledOperand()) == RemillCall;
}

bool BrightenDevirtPass::LowerExternalCalls(Module &M) {
  Function *RemillCall = M.getFunction("__remill_function_call");
  if (!RemillCall) {
    return false;
  }

  const DataLayout &DL = M.getDataLayout();
  SmallVector<CallInst *, 32> Worklist;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (CI && IsRemillCall(CI, RemillCall)) {
          Worklist.push_back(CI);
        } else if (auto *II = dyn_cast<InvokeInst>(&I);
                   II && IsRemillCall(II, RemillCall)) {
          errs() << "[devirt] WARNING: external invoke not lowered\n";
        }
      }
    }
  }

  bool Changed = false;
  static const uint64_t ArgRegs[] = {kOffRDI, kOffRSI, kOffRDX,
                                     kOffRCX, kOffR8,  kOffR9};

  for (CallInst *CI : Worklist) {
    if (CI->arg_size() < 3) {
      continue;
    }

    Function *ExtFn = ResolveExternalFunction(M, CI->getArgOperand(1), DL);
    if (!ExtFn) {
      continue;
    }
    if (RequiresSpecialExternalBridge(ExtFn->getName())) {
      errs() << "[devirt] WARNING: special external not lowered generically: @"
             << ExtFn->getName() << "\n";
      continue;
    }

    FunctionType *ExtTy = ExtFn->getFunctionType();
    if (IsScanfFamilyName(ExtFn->getName())) {
      errs() << "[devirt] WARNING: scanf-family external not lowered without "
                "format-aware guest pointer translation: @"
             << ExtFn->getName() << "\n";
      continue;
    }
    if (ExtTy->isVarArg()) {
      errs() << "[devirt] WARNING: generic vararg external not lowered: @"
             << ExtFn->getName() << "\n";
      continue;
    }
    if (!IsGenericSafeExternalName(ExtFn->getName())) {
      continue;
    }
    if (ExtTy->getNumParams() > 6) {
      errs() << "[devirt] WARNING: external call not lowered, stack args: @"
             << ExtFn->getName() << "\n";
      continue;
    }
    if (HasUnsupportedArgOrReturnTypes(ExtTy)) {
      errs() << "[devirt] WARNING: external call not lowered, unsupported "
                "arg/return type: @"
             << ExtFn->getName() << "\n";
      continue;
    }

    Value *StatePtr = CI->getArgOperand(0);
    Value *Mem = CI->getArgOperand(2);
    Function *TranslateFn = GetTranslateGuestPointerIfDefined(M);
    if (!TranslateFn) {
      errs() << "[devirt] WARNING: __translate_guest_pointer has no body; "
                "external call not lowered: @"
             << ExtFn->getName() << "\n";
      continue;
    }

    IRBuilder<> B(CI);
    SmallVector<Value *, 12> Args;
    unsigned GPIdx = 0;
    unsigned XMMIdx = 0;
    for (unsigned I = 0, E = ExtTy->getNumParams(); I < E; ++I) {
      Type *ParamTy = ExtTy->getParamType(I);
      bool FP = IsFloatingType(ParamTy);
      unsigned RegIndex = FP ? XMMIdx++ : GPIdx++;
      if ((!FP && RegIndex >= 6) || (FP && RegIndex >= 3)) {
        Args.clear();
        break;
      }
      static const uint64_t XMMArgs[] = {kOffXMM0, kOffXMM1, kOffXMM2};
      uint64_t Offset = FP ? XMMArgs[RegIndex] : ArgRegs[RegIndex];
      Value *Raw = LoadReg(B, StatePtr, Offset, Twine("arg") + Twine(I));
      Args.push_back(CoerceArg(B, Raw, ParamTy, TranslateFn,
                               IsWritePointerArg(ExtFn->getName(), I),
                               IsPointerArg(ExtFn->getName(), I)));
    }

    if (Args.size() != ExtTy->getNumParams())
      continue;

    CallInst *NewCall = B.CreateCall(ExtTy, ExtFn, Args);
    if (!ExtTy->getReturnType()->isVoidTy()) {
      NewCall->setName(ExtFn->getName() + ".direct");
    }
    NewCall->setCallingConv(ExtFn->getCallingConv());
    if (ExtFn->hasFnAttribute(Attribute::NoReturn)) {
      NewCall->addFnAttr(Attribute::NoReturn);
    }
    if (ExtFn->hasFnAttribute(Attribute::ReturnsTwice)) {
      NewCall->addFnAttr(Attribute::ReturnsTwice);
    }

    if (IsFloatingType(ExtTy->getReturnType()))
      StoreFPReturnInXMM0(B, StatePtr, NewCall);
    else
      StoreRAX(B, StatePtr, NewCall);
    if (!CI->use_empty()) {
      CI->replaceAllUsesWith(Mem);
    }
    CI->eraseFromParent();
    Changed = true;

    errs() << "[devirt] lowered external call: @" << ExtFn->getName() << "\n";
  }

  return Changed;
}

} // namespace brighten_devirt
