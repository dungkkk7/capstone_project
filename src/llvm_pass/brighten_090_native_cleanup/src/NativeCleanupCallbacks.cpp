#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

Function *resolveCallbackFunction(Value *V,
                                         SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *F = dyn_cast<Function>(V))
    return F;
  if (auto *GV = dyn_cast<GlobalVariable>(V)) {
    if (GV->hasInitializer())
      return resolveCallbackFunction(GV->getInitializer(), Seen);
  }
  if (auto *C = dyn_cast<Constant>(V)) {
    for (Value *Op : C->operands())
      if (Function *F = resolveCallbackFunction(Op, Seen))
        return F;
  }
  return nullptr;
}

Value *coerceCallbackArgument(IRBuilder<> &B, Value *V, Type *Ty,
                                     const Twine &Name) {
  if (!V || !Ty)
    return nullptr;
  if (V->getType() == Ty)
    return V;
  if (V->getType()->isPointerTy() && Ty->isIntegerTy())
    return B.CreatePtrToInt(V, Ty, Name);
  if (V->getType()->isIntegerTy() && Ty->isPointerTy())
    return B.CreateIntToPtr(V, Ty, Name);
  if (V->getType()->isIntegerTy() && Ty->isIntegerTy()) {
    unsigned SW = V->getType()->getIntegerBitWidth();
    unsigned DW = Ty->getIntegerBitWidth();
    if (SW > DW)
      return B.CreateTrunc(V, Ty, Name);
    return B.CreateZExt(V, Ty, Name);
  }
  return nullptr;
}

// McSema represents a C callback as a naked guest trampoline plus a helper
// with the lifted (State, pc, memory) ABI.  Once the target body has already
// been recovered to a native SSA call, make the callback itself native too:
// qsort-style callbacks receive only their real arguments, while the
// recovered body gets a bounded native stack anchor and the two stack-register
// values it needs.  This removes the trampoline/helper pair without inventing
// a guest State object.
unsigned lowerNativeCallbackTrampolines(Module &M, bool &Changed) {
  SmallVector<Function *, 16> Trampolines;
  for (Function &F : M) {
    if (F.isDeclaration() || F.getName() == "main" ||
        !F.hasFnAttribute(Attribute::Naked))
      continue;
    bool HasInlineAsm = false;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CB = dyn_cast<CallBase>(&I))
          HasInlineAsm |= isa<InlineAsm>(CB->getCalledOperand());
    if (HasInlineAsm)
      Trampolines.push_back(&F);
  }

  unsigned Lowered = 0;
  for (Function *Trampoline : Trampolines) {
    Function *Wrapper = nullptr;
    for (BasicBlock &BB : *Trampoline) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || !isa<InlineAsm>(CB->getCalledOperand()))
          continue;
        for (Use &Arg : CB->args()) {
          SmallPtrSet<Value *, 16> Seen;
          Function *Candidate = resolveCallbackFunction(Arg.get(), Seen);
          if (Candidate && Candidate != Trampoline &&
              Candidate->getName().ends_with("_wrapper")) {
            Wrapper = Candidate;
            break;
          }
        }
        if (Wrapper)
          break;
      }
      if (Wrapper)
        break;
    }
    if (!Wrapper)
      continue;

    CallBase *NativeCall = nullptr;
    for (BasicBlock &BB : *Wrapper) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (Callee && !Callee->isIntrinsic() && Callee != Wrapper) {
          NativeCall = CB;
          break;
        }
      }
      if (NativeCall)
        break;
    }
    if (!NativeCall)
      continue;
    Function *NativeTarget = NativeCall->getCalledFunction();
    if (!NativeTarget)
      continue;

    LLVMContext &Ctx = M.getContext();
    Type *PtrTy = PointerType::getUnqual(Ctx);
    FunctionType *AdapterTy =
        FunctionType::get(Type::getInt32Ty(Ctx), {PtrTy, PtrTy}, false);
    std::string AdapterName =
        (Trampoline->getName() + ".native_callback").str();
    Function *Adapter = Function::Create(
        AdapterTy, GlobalValue::InternalLinkage,
        AdapterName, M);
    Adapter->setCallingConv(Trampoline->getCallingConv());
    Adapter->setDSOLocal(true);
    Adapter->getArg(0)->setName("lhs");
    Adapter->getArg(1)->setName("rhs");
    BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", Adapter);
    IRBuilder<> B(Entry);
    AllocaInst *Stack =
        B.CreateAlloca(B.getInt8Ty(), B.getInt64(64 * 1024),
                       "callback_stack");
    Stack->setAlignment(Align(16));
    Value *StackTop = B.CreateConstGEP1_64(B.getInt8Ty(), Stack,
                                           64 * 1024 - 256,
                                           "callback_stack_top");
    Value *StackInt = B.CreatePtrToInt(StackTop, B.getInt64Ty(),
                                       "callback_stack_int");

    SmallVector<Value *, 32> Args;
    bool UnsupportedArg = false;
    for (unsigned I = 0; I < NativeCall->arg_size(); ++I) {
      Type *Ty = NativeCall->getCalledFunction()->getFunctionType()
                     ->getParamType(I);
      Value *V = nullptr;
      if (I == 0 || NativeTarget->getArg(I)->getName() == "native_stack") {
        V = StackTop;
      } else {
        StringRef ArgName = NativeTarget->getArg(I)->getName();
        if (ArgName == "arg_RDI")
          V = Adapter->getArg(0);
        else if (ArgName == "arg_RSI")
          V = Adapter->getArg(1);
        else if (ArgName == "state_in_2312" ||
                 ArgName == "state_in_2328")
          V = StackInt;
        else {
          UnsupportedArg = true;
          break;
        }
      }
      V = coerceCallbackArgument(B, V, Ty, "callback.arg");
      if (!V)
        break;
      Args.push_back(V);
    }
    if (UnsupportedArg || Args.size() != NativeCall->arg_size()) {
      Adapter->eraseFromParent();
      continue;
    }

    CallInst *Call = B.CreateCall(NativeTarget, Args, "callback.native.call");
    Call->setCallingConv(NativeTarget->getCallingConv());
    Value *Ret = Call;
    if (auto *ST = dyn_cast<StructType>(Call->getType())) {
      if (ST->getNumElements() == 0) {
        B.CreateRet(ConstantInt::get(Type::getInt32Ty(Ctx), 0));
        continue;
      }
      Ret = B.CreateExtractValue(Call, {0}, "callback.ret");
    }
    if (Ret->getType()->isPointerTy())
      Ret = B.CreatePtrToInt(Ret, B.getInt64Ty(), "callback.ret.bits");
    if (Ret->getType()->isIntegerTy()) {
      unsigned Width = Ret->getType()->getIntegerBitWidth();
      if (Width > 32)
        Ret = B.CreateTrunc(Ret, B.getInt32Ty(), "callback.ret.i32");
      else if (Width < 32)
        Ret = B.CreateZExt(Ret, B.getInt32Ty(), "callback.ret.i32");
    }
    if (!Ret->getType()->isIntegerTy(32)) {
      Adapter->eraseFromParent();
      continue;
    }
    B.CreateRet(Ret);

    Trampoline->replaceAllUsesWith(Adapter);
    if (Trampoline->use_empty() && Trampoline->getParent())
      Trampoline->eraseFromParent();
    Changed = true;
    ++Lowered;
  }
  return Lowered;
}

// A callback can lose its naked trampoline wrapper during earlier native
// lowering.  In that case a qsort call may still carry the old zero-argument
// guest function pointer.  qsort invokes its comparator with (lhs, rhs), so
// passing that pointer is an ABI mismatch even when the callback body itself
// is otherwise valid.  Re-introduce the small host/guest boundary only when
// the call is provably qsort-like and the callback has the lifted void()
// shape.  The register offsets are the stable McSema x86-64 State layout used
// by the existing state materialization code.
unsigned lowerNativeQsortCallbacks(Module &M, bool &Changed) {
  GlobalVariable *State = M.getNamedGlobal("__mcsema_reg_state");
  if (!State)
    return 0;

  SmallVector<CallBase *, 16> Calls;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB || CB->arg_size() < 4)
          continue;
        Function *Callee = CB->getCalledFunction();
        if (!Callee || Callee->getName() != "qsort")
          continue;
        SmallPtrSet<Value *, 16> Seen;
        Function *Callback = resolveCallbackFunction(CB->getArgOperand(3), Seen);
        if (!Callback || Callback->isDeclaration() ||
            !Callback->getReturnType()->isVoidTy() || Callback->arg_size() != 0)
          continue;
        if (!Callback->getName().starts_with("callback_"))
          continue;
        Calls.push_back(CB);
      }
  }

  unsigned Lowered = 0;
  LLVMContext &Ctx = M.getContext();
  Type *PtrTy = PointerType::getUnqual(Ctx);
  Type *I64Ty = Type::getInt64Ty(Ctx);
  FunctionType *AdapterTy =
      FunctionType::get(Type::getInt32Ty(Ctx), {PtrTy, PtrTy}, false);
  for (CallBase *CB : Calls) {
    SmallPtrSet<Value *, 16> Seen;
    Function *Callback = resolveCallbackFunction(CB->getArgOperand(3), Seen);
    // An earlier qsort call in this worklist may already have redirected all
    // uses of the same guest callback to its native adapter.  Resolve again
    // and re-check the complete lifted shape before constructing a zero-arg
    // call: calling InlineFunction on a call whose newly resolved callee now
    // has the native (lhs, rhs) ABI corrupts the inliner's use bookkeeping.
    if (!Callback || Callback->isDeclaration() ||
        !Callback->getReturnType()->isVoidTy() ||
        Callback->arg_size() != 0 ||
        !Callback->getName().starts_with("callback_"))
      continue;
    std::string Name = (Callback->getName() + ".qsort_callback").str();
    if (M.getFunction(Name))
      continue;
    Function *Adapter = Function::Create(AdapterTy, GlobalValue::InternalLinkage,
                                          Name, M);
    Adapter->setCallingConv(CB->getCallingConv());
    Adapter->setDSOLocal(true);
    Adapter->getArg(0)->setName("lhs");
    Adapter->getArg(1)->setName("rhs");
    BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", Adapter);
    IRBuilder<> B(Entry);
    auto StateSlot = [&](uint64_t Offset) {
      return B.CreateGEP(B.getInt8Ty(), State, B.getInt64(Offset),
                         "qsort.state.slot");
    };
    B.CreateStore(B.CreatePtrToInt(Adapter->getArg(0), I64Ty), StateSlot(2296));
    B.CreateStore(B.CreatePtrToInt(Adapter->getArg(1), I64Ty), StateSlot(2280));
    CallInst *GuestCallbackCall = B.CreateCall(Callback, {});
    GuestCallbackCall->setCallingConv(Callback->getCallingConv());
    Value *Ret = B.CreateLoad(Type::getInt32Ty(Ctx), StateSlot(2216),
                              "qsort.callback.ret");
    B.CreateRet(Ret);

    // The zero-argument callback is a lifted State wrapper, not a second host
    // ABI entry.  Inline it into the proven (lhs, rhs) adapter before
    // publishing the adapter.  This keeps the callback's register-file
    // accesses in one native activation; the subsequent private-State
    // localization can then promote them instead of retaining a shared global
    // solely to communicate across this synthetic call boundary.
    bool HadNoInline = Callback->hasFnAttribute(Attribute::NoInline);
    bool HadOptimizeNone = Callback->hasFnAttribute(Attribute::OptimizeNone);
    Callback->removeFnAttr(Attribute::NoInline);
    Callback->removeFnAttr(Attribute::OptimizeNone);
    InlineFunctionInfo IFI;
    bool CallbackInlined =
        InlineFunction(*GuestCallbackCall, IFI).isSuccess();
    if (!CallbackInlined) {
      if (HadNoInline)
        Callback->addFnAttr(Attribute::NoInline);
      if (HadOptimizeNone)
        Callback->addFnAttr(Attribute::OptimizeNone);
    }

    IRBuilder<> At(CB);
    Value *AdapterBits = At.CreatePtrToInt(Adapter, CB->getArgOperand(3)->getType(),
                                           "qsort.callback.bits");
    CB->setArgOperand(3, AdapterBits);
    if (CallbackInlined) {
      // All remaining address uses denote the same callback boundary (for
      // example a guest-PC carrier that survived data recovery).  Redirect
      // them to the native adapter after its only body call has disappeared.
      Callback->replaceAllUsesWith(Adapter);
      if (Callback->hasLocalLinkage() && Callback->use_empty())
        Callback->eraseFromParent();
    }
    Changed = true;
    ++Lowered;
  }
  return Lowered;
}

} // namespace brighten_native_cleanup
