#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

// A malloc-family call writes the native pointer into RAX.  After the lifted
// state is converted to explicit ABI arguments, some McSema-produced bodies
// still read the incoming `state_in_2216` value instead of the allocator
// result.  Restore that ordinary SSA dataflow before pointer cleanup.
unsigned repairNativeAllocatorRAX(Module &M, bool &Changed) {
  unsigned Rewritten = 0;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    Argument *RAXArg = nullptr;
    for (Argument &Arg : F.args()) {
      if (Arg.getName() == "state_in_2216" ||
          Arg.getName() == "arg_RAX") {
        RAXArg = &Arg;
        break;
      }
    }
    if (!RAXArg || !RAXArg->getType()->isIntegerTy())
      continue;

    DominatorTree DT(F);
    SmallVector<CallInst *, 8> Allocators;
    SmallVector<CallInst *, 8> DeallocatorReturns;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee)
          continue;
        StringRef Name = Callee->getName();
        if (CI->getType()->isPointerTy() &&
            (Name == "malloc" || Name == "calloc" || Name == "realloc"))
          Allocators.push_back(CI);
        else if (CI->getType()->isIntegerTy() && Name == "free")
          DeallocatorReturns.push_back(CI);
      }
    }

    // Choose the nearest dominating allocator for each RAX use.  Replacing
    // all dominated uses once per allocator is order-dependent: with
    // calloc(); calloc(); use(RAX), the first pass consumes the use before the
    // second pass can associate it with the second allocation.  The native
    // value in RAX is a normal SSA definition, so the selected definition must
    // be the latest allocator that dominates that use.
    DenseMap<CallInst *, Value *> Results;
    SmallVector<Use *, 16> RAXUses;
    for (Use &U : RAXArg->uses())
      RAXUses.push_back(&U);
    for (Use *UPtr : RAXUses) {
      Use &U = *UPtr;
      auto *UserI = dyn_cast<Instruction>(U.getUser());
      if (!UserI)
        continue;

      CallInst *Best = nullptr;
      for (CallInst *Allocator : Allocators) {
        if (Allocator->getParent() == UserI->getParent() &&
            !Allocator->comesBefore(UserI))
          continue;
        if (!DT.dominates(Allocator, UserI))
          continue;
        if (!Best || DT.dominates(Best, Allocator)) {
          Best = Allocator;
          continue;
        }
        // DominatorTree normally orders two definitions that both dominate a
        // use.  Keep an explicit same-block fallback for LLVM versions where
        // the relation is not exposed through the instruction overload.
        if (Best->getParent() == Allocator->getParent() &&
            Best->comesBefore(Allocator))
          Best = Allocator;
      }
      if (!Best)
        continue;

      Value *&Result = Results[Best];
      if (!Result) {
        Instruction *InsertBefore = Best->getNextNode();
        IRBuilder<> B(Best->getParent());
        if (InsertBefore)
          B.SetInsertPoint(InsertBefore);
        else
          B.SetInsertPoint(Best->getParent());
        Result = B.CreatePtrToInt(Best, RAXArg->getType(),
                                  "native.allocator.rax");
      }
      U.set(Result);
      ++Rewritten;
      Changed = true;
    }

    // Before the external bridge can prove a native pointer argument, a
    // preserved lifted `free` may still return an integer carrier.  In the
    // original machine code that carrier is not a C return value; it is the
    // stale RAX value until a following allocator writes RAX.  Associate such
    // uses with the nearest allocator that occurs after the free and before
    // the use.  This handles free(); calloc(); use(RAX) without encoding a
    // function or slot from a particular binary.
    for (CallInst *FreeCall : DeallocatorReturns) {
      SmallVector<Use *, 8> FreeUses;
      for (Use &U : FreeCall->uses())
        FreeUses.push_back(&U);
      for (Use *UPtr : FreeUses) {
        Use &U = *UPtr;
        auto *UserI = dyn_cast<Instruction>(U.getUser());
        if (!UserI)
          continue;

        CallInst *Best = nullptr;
        for (CallInst *Allocator : Allocators) {
          if (FreeCall->getParent() == Allocator->getParent()) {
            if (!FreeCall->comesBefore(Allocator))
              continue;
          } else if (!DT.dominates(FreeCall, Allocator)) {
            continue;
          }
          if (Allocator->getParent() == UserI->getParent() &&
              !Allocator->comesBefore(UserI))
            continue;
          if (!DT.dominates(Allocator, UserI))
            continue;
          if (!Best || DT.dominates(Best, Allocator) ||
              (Best->getParent() == Allocator->getParent() &&
               Best->comesBefore(Allocator)))
            Best = Allocator;
        }
        if (!Best)
          continue;

        Value *&Result = Results[Best];
        if (!Result) {
          Instruction *InsertBefore = Best->getNextNode();
          IRBuilder<> B(Best->getParent());
          if (InsertBefore)
            B.SetInsertPoint(InsertBefore);
          else
            B.SetInsertPoint(Best->getParent());
          Result = B.CreatePtrToInt(Best, RAXArg->getType(),
                                    "native.allocator.rax");
        }
        U.set(Result);
        ++Rewritten;
        Changed = true;
      }
    }
  }
  return Rewritten;
}

// A preserved external wrapper can leave a direct libc declaration with the
// lifter's integer carrier ABI, e.g. `i64 @free(i64)` or
// `i64 @memset(i64, i64, i64)`.  Once the State ABI is gone those declarations
// are not merely ugly: LLVM is allowed to optimize them differently from the
// real C ABI.  Normalize the small, stable libc ABI surface here, after all
// pointer-carrier lowering has happened.
FunctionType *nativeExternalType(Module &M, StringRef Name) {
  if (Name.ends_with(".lifted_abi"))
    Name = Name.drop_back(StringRef(".lifted_abi").size());
  LLVMContext &Ctx = M.getContext();
  Type *I32 = Type::getInt32Ty(Ctx);
  Type *I64 = Type::getInt64Ty(Ctx);
  Type *F64 = Type::getDoubleTy(Ctx);
  Type *Ptr = PointerType::getUnqual(Ctx);
  auto Fixed = [&](Type *Ret, ArrayRef<Type *> Params,
                   bool VarArg = false) {
    return FunctionType::get(Ret, Params, VarArg);
  };

  if (Name == "free")
    return Fixed(Type::getVoidTy(Ctx), {Ptr});
  if (Name == "malloc")
    return Fixed(Ptr, {I64});
  if (Name == "calloc")
    return Fixed(Ptr, {I64, I64});
  if (Name == "realloc")
    return Fixed(Ptr, {Ptr, I64});
  if (Name == "memset")
    return Fixed(Ptr, {Ptr, I32, I64});
  if (Name == "memcpy" || Name == "memmove")
    return Fixed(Ptr, {Ptr, Ptr, I64});
  if (Name == "puts")
    return Fixed(I32, {Ptr});
  if (Name == "strlen")
    return Fixed(I64, {Ptr});
  if (Name == "strcmp")
    return Fixed(I32, {Ptr, Ptr});
  if (Name == "strstr")
    return Fixed(Ptr, {Ptr, Ptr});
  if (Name == "strncmp")
    return Fixed(I32, {Ptr, Ptr, I64});
  if (Name == "strcpy" || Name == "strcat")
    return Fixed(Ptr, {Ptr, Ptr});
  if (Name == "strncpy" || Name == "strncat")
    return Fixed(Ptr, {Ptr, Ptr, I64});
  if (Name == "strchr" || Name == "strrchr")
    return Fixed(Ptr, {Ptr, I32});
  if (Name == "memcmp")
    return Fixed(I32, {Ptr, Ptr, I64});
  if (Name == "setjmp" || Name == "_setjmp")
    return Fixed(I32, {Ptr});
  if (Name == "sigsetjmp" || Name == "__sigsetjmp")
    return Fixed(I32, {Ptr, I32});
  if (Name == "longjmp" || Name == "siglongjmp")
    return Fixed(Type::getVoidTy(Ctx), {Ptr, I32});
  if (Name == "getchar")
    return Fixed(I32, {});
  if (Name == "gets")
    return Fixed(Ptr, {Ptr});
  if (Name == "fgets")
    return Fixed(Ptr, {Ptr, I32, Ptr});
  if (Name == "strtok")
    return Fixed(Ptr, {Ptr, Ptr});
  if (Name == "qsort")
    return Fixed(Type::getVoidTy(Ctx), {Ptr, I64, I64, Ptr});
  if (Name == "sqrt" || Name == "round")
    return Fixed(F64, {F64});
  if (Name == "hypot" || Name == "atan2" || Name == "pow")
    return Fixed(F64, {F64, F64});
  if (Name == "printf" || Name == "scanf" || Name == "__isoc99_scanf")
    return Fixed(I32, {Ptr}, true);
  if (Name == "vprintf" || Name == "vscanf" ||
      Name == "__isoc99_vscanf")
    return Fixed(I32, {Ptr, Ptr});
  if (Name == "__cxa_finalize")
    return Fixed(Type::getVoidTy(Ctx), {Ptr});
  if (Name == "exit")
    return Fixed(Type::getVoidTy(Ctx), {I32});
  if (Name == "abort")
    return Fixed(Type::getVoidTy(Ctx), {});
  return nullptr;
}

Value *coerceNativeExternalValue(IRBuilder<> &B, Value *V, Type *Dst) {
  if (!V || !Dst)
    return nullptr;
  if (V->getType() == Dst)
    return V;
  Type *Src = V->getType();
  if (Src->isIntegerTy() && Dst->isPointerTy()) {
    // ABI normalization runs after the first stack-address lowering pass.
    // Do not re-materialize a proven RSP/RBP-derived value as inttoptr here:
    // external arguments such as sprintf/strlen destinations may still be
    // represented by an integer stack address at this late boundary.
    if (BasicBlock *BB = B.GetInsertBlock()) {
      if (Value *NativeStackPtr = lowerNativeStackInteger(
              B, V, *BB->getParent()))
        return NativeStackPtr;
      // External libc calls receive host pointers, while lifted code carries
      // recovered data addresses in integer registers.  Resolve those
      // addresses against the recovered guest ranges before falling back to
      // inttoptr; otherwise qsort/memcpy operate on the numeric guest address
      // and silently sort/copy the wrong object.
      if (Module *Mod = BB->getModule())
        if (Value *NativeDataPtr =
                materializeRecoveredDataPointer(*Mod, B, V))
          return NativeDataPtr;
    }
    return B.CreateIntToPtr(V, Dst, "native.external.inttoptr");
  }
  if (Src->isPointerTy() && Dst->isIntegerTy())
    return B.CreatePtrToInt(V, Dst, "native.external.ptrtoint");
  if (Src->isIntegerTy() && Dst->isIntegerTy()) {
    unsigned SW = Src->getIntegerBitWidth();
    unsigned DW = Dst->getIntegerBitWidth();
    if (SW > DW)
      return B.CreateTrunc(V, Dst, "native.external.trunc");
    return B.CreateZExt(V, Dst, "native.external.zext");
  }
  if (Src->isIntegerTy() && Dst->isFloatingPointTy()) {
    unsigned DstBits = Dst->getPrimitiveSizeInBits();
    if (!DstBits)
      return nullptr;
    Type *CarrierTy = IntegerType::get(B.getContext(), DstBits);
    Value *Carrier = V;
    unsigned SrcBits = Src->getIntegerBitWidth();
    if (SrcBits > DstBits)
      Carrier = B.CreateTrunc(V, CarrierTy, "native.external.fp.trunc");
    else if (SrcBits < DstBits)
      Carrier = B.CreateZExt(V, CarrierTy, "native.external.fp.zext");
    return B.CreateBitCast(Carrier, Dst, "native.external.fp");
  }
  if (Src->isFloatingPointTy() && Dst->isIntegerTy()) {
    unsigned SrcBits = Src->getPrimitiveSizeInBits();
    if (!SrcBits)
      return nullptr;
    Type *CarrierTy = IntegerType::get(B.getContext(), SrcBits);
    Value *Carrier = B.CreateBitCast(V, CarrierTy, "native.external.int.bits");
    unsigned DstBits = Dst->getIntegerBitWidth();
    if (SrcBits > DstBits)
      return B.CreateTrunc(Carrier, Dst, "native.external.int.trunc");
    if (SrcBits < DstBits)
      return B.CreateZExt(Carrier, Dst, "native.external.int.zext");
    return Carrier;
  }
  return nullptr;
}

unsigned normalizeNativeExternalABIs(Module &M, bool &Changed,
                                             SmallVectorImpl<std::string> *Findings) {
  SmallVector<CallInst *, 128> Calls;
  for (Function &F : M) {
    // The Remill dispatcher can survive until late cleanup when a guest uses
    // a runtime function pointer.  Its libc arms still need the real C ABI;
    // otherwise the dispatcher itself pins declarations such as
    // vscanf.lifted_abi even after all direct lifted wrappers are gone.
    if (F.isDeclaration() ||
        (isLiftedFunctionName(F.getName()) &&
         F.getName() != "__remill_function_call"))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee || !nativeExternalType(M, Callee->getName()))
          continue;
        Calls.push_back(CI);
      }
    }
  }

  unsigned Rewritten = 0;
  SmallVector<std::pair<Function *, Function *>, 16> LiftedDeclarations;
  for (CallInst *OldCall : Calls) {
    if (!OldCall->getParent())
      continue;
    Function *OldCallee = OldCall->getCalledFunction();
    if (!OldCallee)
      continue;
    StringRef ExternalName = OldCallee->getName();
    StringRef CanonicalName = ExternalName;
    if (CanonicalName.ends_with(".lifted_abi"))
      CanonicalName = CanonicalName.drop_back(StringRef(".lifted_abi").size());
    FunctionType *Expected = nativeExternalType(M, CanonicalName);
    if (!Expected || OldCallee->getFunctionType() == Expected)
      continue;

    // A void ABI has no return value.  Do not invent one for a lifted use:
    // using a deallocator's incidental RAX contents is undefined at the C
    // level and must be reported as an unsupported native contract.
    if (Expected->getReturnType()->isVoidTy() && !OldCall->use_empty()) {
      if (Findings)
        addFinding(*Findings, "external ABI result used", OldCallee->getName());
      continue;
    }

    Function *NativeCallee = M.getFunction(CanonicalName);
    if (NativeCallee == OldCallee) {
      if (!OldCallee->getName().ends_with(".lifted_abi")) {
        std::string OldName = OldCallee->getName().str();
        OldCallee->setName(OldName + ".lifted_abi");
      }
      NativeCallee = Function::Create(Expected, GlobalValue::ExternalLinkage,
                                      CanonicalName, &M);
      NativeCallee->setCallingConv(OldCall->getCallingConv());
    }
    if (!NativeCallee || NativeCallee->getFunctionType() != Expected)
      continue;
    if (OldCallee != NativeCallee &&
        OldCallee->getName().ends_with(".lifted_abi"))
      LiftedDeclarations.emplace_back(OldCallee, NativeCallee);

    IRBuilder<> B(OldCall);
    SmallVector<Value *, 16> Args;
    bool Valid = OldCall->arg_size() >= Expected->getNumParams();
    for (unsigned I = 0; Valid && I < Expected->getNumParams(); ++I) {
      Value *Arg = coerceNativeExternalValue(
          B, OldCall->getArgOperand(I), Expected->getParamType(I));
      if (!Arg)
        Valid = false;
      else
        Args.push_back(Arg);
    }
    if (!Valid)
      continue;
    if (Expected->isVarArg())
      for (unsigned I = Expected->getNumParams(); I < OldCall->arg_size(); ++I)
        Args.push_back(OldCall->getArgOperand(I));
    else if (OldCall->arg_size() != Expected->getNumParams())
      continue;

    CallInst *NewCall = B.CreateCall(NativeCallee, Args,
                                     Expected->getReturnType()->isVoidTy()
                                         ? ""
                                         : "native.external.ret");
    NewCall->setCallingConv(NativeCallee->getCallingConv());
    if (!OldCall->use_empty()) {
      Value *Replacement = coerceNativeExternalValue(
          B, NewCall, OldCall->getType());
      if (!Replacement)
        continue;
      OldCall->replaceAllUsesWith(Replacement);
    }
    OldCall->eraseFromParent();
    Changed = true;
    ++Rewritten;
  }

  // Relocation tables in a residual native data allocation may still name
  // the lifted declaration after every executable callsite was normalized.
  // Rebase only declarations whose complete use graph ends in globals; a
  // constant-expression call user would still require ABI conversion.
  auto HasOnlyGlobalConstantUsers = [](Value *Root) {
    SmallVector<Value *, 16> Work{Root};
    SmallPtrSet<Value *, 32> Seen;
    while (!Work.empty()) {
      Value *V = Work.pop_back_val();
      if (!Seen.insert(V).second)
        continue;
      for (User *U : V->users()) {
        if (isa<GlobalVariable>(U))
          continue;
        if (isa<Constant>(U)) {
          Work.push_back(cast<Value>(U));
          continue;
        }
        return false;
      }
    }
    return true;
  };
  LiftedDeclarations.clear();
  for (Function &F : M) {
    if (!F.getName().ends_with(".lifted_abi"))
      continue;
    StringRef Canonical =
        F.getName().drop_back(StringRef(".lifted_abi").size());
    if (!HasOnlyGlobalConstantUsers(&F))
      continue;
    FunctionType *Expected = nativeExternalType(M, Canonical);
    if (!Expected)
      continue;
    Function *Native = M.getFunction(Canonical);
    if (!Native) {
      Native = Function::Create(Expected, GlobalValue::ExternalLinkage,
                                Canonical, &M);
      Native->setCallingConv(CallingConv::C);
    }
    if (Native->getFunctionType() == Expected)
      LiftedDeclarations.emplace_back(&F, Native);
  }
  for (auto [Lifted, Native] : LiftedDeclarations) {
    if (!Lifted->getParent() || !HasOnlyGlobalConstantUsers(Lifted))
      continue;
    Lifted->replaceAllUsesWith(Native);
    if (Lifted->use_empty())
      Lifted->eraseFromParent();
    Changed = true;
  }
  return Rewritten;
}

// Lifting a variadic scanf call can lose trailing destination operands while
// leaving the format string intact.  Calling libc with fewer pointers than
// the format consumes reads arbitrary registers/stack slots and turns a
// recoverable raw-input path into an unrelated crash.  Materialize only the
// missing integer destinations; existing operands and their order are kept
// unchanged.
unsigned materializeMissingScanfDestinations(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  SmallVector<CallInst *, 64> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        Function *Callee = CI ? CI->getCalledFunction() : nullptr;
        if (!CI || !Callee ||
            (Callee->getName() != "scanf" &&
             Callee->getName() != "__isoc99_scanf") ||
            CI->arg_empty() || !Callee->getFunctionType()->isVarArg())
          continue;
        Candidates.push_back(CI);
      }
    }
  }

  auto CollectIntegerArgs = [](StringRef Format,
                               SmallVectorImpl<std::pair<unsigned, unsigned>> &Out) {
    unsigned Arg = 0;
    for (size_t I = 0; I < Format.size();) {
      if (Format[I++] != '%')
        continue;
      if (I >= Format.size())
        break;
      if (Format[I] == '%') {
        ++I;
        continue;
      }
      bool Suppressed = false;
      if (Format[I] == '*') {
        Suppressed = true;
        ++I;
      }
      while (I < Format.size() && Format[I] >= '0' && Format[I] <= '9')
        ++I;
      unsigned Bits = 32;
      if (I < Format.size() && Format[I] == 'l') {
        Bits = 64;
        ++I;
        if (I < Format.size() && Format[I] == 'l')
          ++I;
      }
      if (I >= Format.size())
        break;
      char Conversion = Format[I++];
      bool Integer = Conversion == 'd' || Conversion == 'i' ||
                     Conversion == 'o' || Conversion == 'u' ||
                     Conversion == 'x' || Conversion == 'X';
      if (!Suppressed) {
        if (Integer)
          Out.push_back({Arg, Bits});
        ++Arg;
      }
    }
  };

  std::function<Value *(Value *, SmallPtrSetImpl<Value *> &)>
      FindNativeStackAddress = [&](Value *V,
                                   SmallPtrSetImpl<Value *> &Seen) -> Value * {
    if (!V || !Seen.insert(V).second)
      return nullptr;
    if (auto *Sel = dyn_cast<SelectInst>(V)) {
      if (Value *Found = FindNativeStackAddress(Sel->getFalseValue(), Seen))
        return Found;
      return FindNativeStackAddress(Sel->getTrueValue(), Seen);
    }
    if (auto *Cast = dyn_cast<CastInst>(V))
      return FindNativeStackAddress(Cast->getOperand(0), Seen);
    auto *GEP = dyn_cast<GetElementPtrInst>(V);
    if (!GEP || GEP->getNumIndices() != 1)
      return nullptr;
    std::function<GlobalVariable *(Value *, SmallPtrSetImpl<Value *> &)>
        FindRootGlobal = [&](Value *Root,
                             SmallPtrSetImpl<Value *> &RootSeen)
        -> GlobalVariable * {
      if (!Root || !RootSeen.insert(Root).second)
        return nullptr;
      if (auto *GV = dyn_cast<GlobalVariable>(Root->stripPointerCasts()))
        return GV;
      if (auto *GEP = dyn_cast<GEPOperator>(Root))
        return FindRootGlobal(GEP->getPointerOperand(), RootSeen);
      if (auto *Cast = dyn_cast<CastInst>(Root))
        return FindRootGlobal(Cast->getOperand(0), RootSeen);
      return nullptr;
    };
    SmallPtrSet<Value *, 8> RootSeen;
    auto *BaseGV = FindRootGlobal(GEP->getPointerOperand(), RootSeen);
    if (!BaseGV || !BaseGV->getName().starts_with("frame_storage_backing."))
      return nullptr;
    Value *Index = GEP->idx_begin()->get();
    auto *Sub = dyn_cast<BinaryOperator>(Index);
    if (!Sub || Sub->getOpcode() != Instruction::Sub)
      return nullptr;
    SmallPtrSet<Value *, 16> AnchorSeen;
    if (!containsNativeStackAnchorInteger(Sub->getOperand(1), AnchorSeen))
      return nullptr;
    return Sub->getOperand(0);
  };

  std::function<Value *(Value *, SmallPtrSetImpl<Value *> &)>
      FindNativeStackFrameTop = [&](Value *V,
                                    SmallPtrSetImpl<Value *> &Seen) -> Value * {
    if (!V || !Seen.insert(V).second)
      return nullptr;
    if (auto *Sel = dyn_cast<SelectInst>(V)) {
      if (Value *Found = FindNativeStackFrameTop(Sel->getFalseValue(), Seen))
        return Found;
      return FindNativeStackFrameTop(Sel->getTrueValue(), Seen);
    }
    if (auto *Cast = dyn_cast<CastInst>(V))
      return FindNativeStackFrameTop(Cast->getOperand(0), Seen);
    auto *GEP = dyn_cast<GetElementPtrInst>(V);
    if (!GEP || GEP->getNumIndices() != 1)
      return nullptr;
    std::function<GlobalVariable *(Value *, SmallPtrSetImpl<Value *> &)>
        FindRootGlobal = [&](Value *Root,
                             SmallPtrSetImpl<Value *> &RootSeen)
        -> GlobalVariable * {
      if (!Root || !RootSeen.insert(Root).second)
        return nullptr;
      if (auto *GV = dyn_cast<GlobalVariable>(Root->stripPointerCasts()))
        return GV;
      if (auto *GEP = dyn_cast<GEPOperator>(Root))
        return FindRootGlobal(GEP->getPointerOperand(), RootSeen);
      if (auto *Cast = dyn_cast<CastInst>(Root))
        return FindRootGlobal(Cast->getOperand(0), RootSeen);
      return nullptr;
    };
    SmallPtrSet<Value *, 8> RootSeen;
    auto *BaseGV = FindRootGlobal(GEP->getPointerOperand(), RootSeen);
    if (!BaseGV || !BaseGV->getName().starts_with("frame_storage_backing."))
      return nullptr;
    return GEP->getPointerOperand();
  };

  auto MatchAddConstant = [](Value *V, Value *&Base,
                             int64_t &Offset) -> bool {
    if (auto *BO = dyn_cast<BinaryOperator>(V)) {
      if (BO->getOpcode() == Instruction::Add) {
        if (auto *CI = dyn_cast<ConstantInt>(BO->getOperand(1))) {
          Base = BO->getOperand(0);
          Offset = CI->getSExtValue();
          return true;
        }
        if (auto *CI = dyn_cast<ConstantInt>(BO->getOperand(0))) {
          Base = BO->getOperand(1);
          Offset = CI->getSExtValue();
          return true;
        }
      }
    }
    return false;
  };

  unsigned Rewritten = 0;
  for (CallInst *CI : Candidates) {
    if (!CI->getParent())
      continue;
    SmallVector<std::pair<unsigned, unsigned>, 8> IntegerArgs;
    std::optional<std::string> Format;
    SmallPtrSet<Value *, 32> SeenFormats;
    std::function<void(Value *)> FindBestFormat = [&](Value *V) {
      if (!V || !SeenFormats.insert(V).second)
        return;
      if (auto Candidate = readConstantFormatString(V, DL)) {
        SmallVector<std::pair<unsigned, unsigned>, 8> Parsed;
        CollectIntegerArgs(*Candidate, Parsed);
        if (!Format || Parsed.size() > IntegerArgs.size()) {
          Format = std::move(Candidate);
          IntegerArgs = std::move(Parsed);
        }
        // A resolved GEP already encodes the exact format-string start.  Do
        // not recurse into its base global and accidentally prefer a longer
        // neighbouring string at offset 0, e.g. "%d%d%d\0" over GEP+2 "%d%d".
        return;
      }
      if (auto *Inst = dyn_cast<Instruction>(V))
        for (Value *Op : Inst->operands())
          FindBestFormat(Op);
      else if (auto *CE = dyn_cast<ConstantExpr>(V))
        for (Value *Op : CE->operands())
          FindBestFormat(Op);
    };
    FindBestFormat(CI->getArgOperand(0));
    if (!Format)
      continue;
    unsigned Existing = CI->arg_size() - 1;
    if (IntegerArgs.size() <= Existing)
      continue;

    Function *F = CI->getFunction();
    IRBuilder<> EntryBuilder(&*F->getEntryBlock().getFirstInsertionPt());
    IRBuilder<> CallBuilder(CI);
    SmallVector<Value *, 16> Args;
    for (unsigned I = 0; I < CI->arg_size(); ++I)
      Args.push_back(CI->getArgOperand(I));

    Value *StackBase = nullptr;
    Value *StackFrameTop = nullptr;
    int64_t PrevOffset = 0;
    int64_t LastOffset = 0;
    bool HaveStackStride = false;
    if (Existing >= 2) {
      SmallPtrSet<Value *, 32> SeenPrev;
      SmallPtrSet<Value *, 32> SeenLast;
      Value *PrevAddr = FindNativeStackAddress(CI->getArgOperand(Existing - 1),
                                               SeenPrev);
      Value *LastAddr = FindNativeStackAddress(CI->getArgOperand(Existing),
                                               SeenLast);
      Value *PrevBase = nullptr;
      Value *LastBase = nullptr;
      SmallPtrSet<Value *, 32> SeenFrameTop;
      if (PrevAddr && LastAddr &&
          MatchAddConstant(PrevAddr, PrevBase, PrevOffset) &&
          MatchAddConstant(LastAddr, LastBase, LastOffset) &&
          PrevBase == LastBase) {
        StackBase = LastBase;
        StackFrameTop =
            FindNativeStackFrameTop(CI->getArgOperand(Existing), SeenFrameTop);
        HaveStackStride = StackFrameTop != nullptr;
      }
    }

    for (unsigned I = Existing; I < IntegerArgs.size(); ++I) {
      unsigned Bits = IntegerArgs[I].second;
      if (!Bits)
        continue;
      Type *IntTy = IntegerType::get(M.getContext(), Bits);
      Value *Dest = nullptr;
      if (HaveStackStride && StackBase) {
        int64_t Stride = LastOffset - PrevOffset;
        unsigned Bytes = std::max(1u, Bits / 8);
        if (std::llabs(Stride) == static_cast<long long>(Bytes)) {
          PrevOffset = LastOffset;
          LastOffset += Stride;
          Value *NextAddr = CallBuilder.CreateAdd(
              StackBase,
              ConstantInt::get(StackBase->getType(), LastOffset, true),
              "native.scanf.missing.stack.addr");
          Value *Address = NextAddr;
          if (!Address->getType()->isIntegerTy(64))
            Address = CallBuilder.CreateZExtOrTrunc(
                Address, CallBuilder.getInt64Ty(), "native.stack.address");
          Value *Anchor = CallBuilder.CreatePtrToInt(
              StackFrameTop, CallBuilder.getInt64Ty(),
              "native.scanf.missing.stack.anchor");
          Value *Delta = CallBuilder.CreateSub(
              Address, Anchor, "native.scanf.missing.stack.delta");
          Dest = CallBuilder.CreateGEP(CallBuilder.getInt8Ty(), StackFrameTop,
                                       Delta, "native.scanf.missing.stack.gep");
        } else {
          HaveStackStride = false;
        }
      }
      if (!Dest) {
        AllocaInst *Scratch = EntryBuilder.CreateAlloca(
            IntTy, nullptr, "native.scanf.missing.destination");
        Dest = Scratch;
      }
      Args.push_back(Dest);
    }
    if (Args.size() == CI->arg_size())
      continue;

    CallInst *Replacement = CallInst::Create(
        CI->getFunctionType(), CI->getCalledOperand(), Args, "",
        CI->getIterator());
    Replacement->setCallingConv(CI->getCallingConv());
    Replacement->setAttributes(CI->getAttributes());
    Replacement->copyMetadata(*CI);
    CI->replaceAllUsesWith(Replacement);
    CI->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

bool parseStateSlotName(StringRef Name, StringRef Prefix,
                               uint64_t &Offset) {
  if (!Name.starts_with(Prefix))
    return false;
  StringRef Suffix = Name.drop_front(Prefix.size());
  if (Suffix.empty() || Suffix.getAsInteger(10, Offset))
    return false;
  return true;
}

bool isStateOutputValue(Value *V, uint64_t Offset,
                               SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return false;
  uint64_t ValueOffset = 0;
  StringRef Name = V->getName();
  if (parseStateSlotName(Name, "state_out.", ValueOffset) &&
      ValueOffset == Offset)
    return true;
  if (parseStateSlotName(Name, "state_out_", ValueOffset) &&
      ValueOffset == Offset)
    return true;
  if (auto *I = dyn_cast<Instruction>(V)) {
    for (Value *Op : I->operands())
      if (isStateOutputValue(Op, Offset, Seen))
        return true;
  }
  return false;
}

std::optional<unsigned>
findStateOutputIndex(Value *Aggregate, uint64_t Offset,
                     SmallPtrSetImpl<Value *> &Seen) {
  if (!Aggregate || !Seen.insert(Aggregate).second)
    return std::nullopt;
  if (auto *IV = dyn_cast<InsertValueInst>(Aggregate)) {
    ArrayRef<unsigned> Indices = IV->getIndices();
    if (Indices.size() == 1) {
      SmallPtrSet<Value *, 16> ValueSeen;
      if (isStateOutputValue(IV->getInsertedValueOperand(), Offset,
                             ValueSeen))
        return Indices.front();
    }
    return findStateOutputIndex(IV->getAggregateOperand(), Offset, Seen);
  }
  if (auto *PN = dyn_cast<PHINode>(Aggregate)) {
    for (Value *Incoming : PN->incoming_values())
      if (auto Index = findStateOutputIndex(Incoming, Offset, Seen))
        return Index;
  }
  return std::nullopt;
}

// RBP is callee-saved in the native ABI and is also the anchor used by the
// recovered stack model.  A lifted return can accidentally populate the RBP
// output slot from a transient stack load instead of carrying the incoming
// RBP forward.  The output field is located from the State-SSA slot name,
// not from a function name or a fixed aggregate index.
unsigned preserveNativeRBPOutputs(Module &M, bool &Changed) {
  unsigned Rewritten = 0;
  for (Function &F : M) {
    Argument *RBP = nullptr;
    uint64_t RBPOffset = 0;
    for (Argument &Arg : F.args()) {
      uint64_t Offset = 0;
      if (parseStateSlotName(Arg.getName(), "state_in_", Offset) &&
          Arg.getType()->isIntegerTy(64) &&
          Arg.getName().contains("2328")) {
        RBP = &Arg;
        RBPOffset = Offset;
        break;
      }
    }
    auto *ResultTy = dyn_cast<StructType>(F.getReturnType());
    if (!RBP || !ResultTy)
      continue;
    SmallVector<ReturnInst *, 8> Returns;
    for (BasicBlock &BB : F)
      if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator()))
        Returns.push_back(RI);
    for (ReturnInst *RI : Returns) {
      if (RI->getReturnValue()->getType() != ResultTy)
        continue;
      SmallPtrSet<Value *, 32> AggregateSeen;
      auto OutputIndex = findStateOutputIndex(RI->getReturnValue(), RBPOffset,
                                              AggregateSeen);
      if (!OutputIndex || *OutputIndex >= ResultTy->getNumElements() ||
          !ResultTy->getElementType(*OutputIndex)->isIntegerTy(64))
        continue;
      IRBuilder<> B(RI);
      Value *Fixed = B.CreateInsertValue(RI->getReturnValue(), RBP,
                                         {*OutputIndex},
                                          "native.rbp.return");
      RI->setOperand(0, Fixed);
      ++Rewritten;
      Changed = true;
    }
  }
  return Rewritten;
}

unsigned inlineExternalLiftedWrappers(Module &M, bool &Changed) {
  SmallVector<Function *, 16> Wrappers;
  for (Function &F : M) {
    if (!F.isDeclaration() && F.getName().starts_with("ext_"))
      Wrappers.push_back(&F);
  }

  unsigned Inlined = 0;
  for (Function *Wrapper : Wrappers) {
    SmallVector<CallBase *, 16> Calls;
    for (User *U : Wrapper->users()) {
      if (auto *CB = dyn_cast<CallBase>(U))
        Calls.push_back(CB);
    }
    for (CallBase *CB : Calls) {
      InlineFunctionInfo IFI;
      InlineResult Result = InlineFunction(*CB, IFI);
      if (Result.isSuccess()) {
        ++Inlined;
        Changed = true;
      }
    }
  }
  return Inlined;
}

} // namespace brighten_native_cleanup
