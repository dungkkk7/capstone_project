#include "BrightenABIRecoveryPass.h"

#include "llvm/IR/IRBuilder.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_abi {

using namespace llvm;

static Value *StateArg(CallInst &CI) {
  return CI.arg_size() >= 1 ? CI.getArgOperand(0) : nullptr;
}

static Value *MemoryArg(CallInst &CI) {
  return CI.arg_size() >= 3 ? CI.getArgOperand(2) : nullptr;
}

static void AddHiddenArgs(FunctionABISummary &S, CallInst &Old,
                          SmallVectorImpl<Value *> &Args) {
  if (S.HiddenState) {
    Args.push_back(Old.getArgOperand(0));
  }
  if (S.HiddenPC) {
    Args.push_back(Old.getArgOperand(1));
  }
  if (S.HiddenMemory) {
    Args.push_back(Old.getArgOperand(2));
  }
}

static Value *BuildABIArg(IRBuilder<> &B, FunctionABISummary &S,
                          CallsiteABIInfo &Info, ABIArgInfo &Arg,
                          CallInst &Old) {
  Value *V = nullptr;
  auto It = Info.StoredArgs.find(Arg.Reg);
  if (It != Info.StoredArgs.end()) {
    V = It->second;
  } else {
    Value *Ptr = BuildStateRegisterPointer(B, StateArg(Old), Arg.Reg);
    if (!Ptr) {
      return nullptr;
    }
    Type *LoadTy = Arg.Ty->isPointerTy() ? B.getInt64Ty() : Arg.Ty;
    V = B.CreateLoad(LoadTy, Ptr, (GetRegisterName(Arg.Reg) + ".load").str());
  }
  return CoerceValue(B, V, Arg.Ty, GetRegisterName(Arg.Reg));
}

static void StoreReturnToState(IRBuilder<> &B, FunctionABISummary &S,
                               CallInst &Old, Value *Ret) {
  if (!Ret || S.RetKind == ReturnKind::Void) {
    return;
  }
  Value *State = StateArg(Old);
  if (!State) {
    return;
  }

  if (S.RetKind == ReturnKind::IntRDXRAX) {
    Type *I128Ty = Type::getIntNTy(B.getContext(), 128);
    Value *Packed = CoerceValue(B, Ret, I128Ty, "abi.ret.i128");
    if (!Packed) {
      return;
    }
    Value *RAX = B.CreateTrunc(Packed, B.getInt64Ty(), "abi.ret.rax");
    Value *High = B.CreateLShr(Packed, ConstantInt::get(I128Ty, 64),
                                "abi.ret.rdx.shifted");
    Value *RDX = B.CreateTrunc(High, B.getInt64Ty(), "abi.ret.rdx");
    Value *RAXPtr = BuildStateRegisterPointer(B, State, ABIReg::RAX);
    Value *RDXPtr = BuildStateRegisterPointer(B, State, ABIReg::RDX);
    if (RAXPtr && RDXPtr) {
      B.CreateStore(RAX, RAXPtr);
      B.CreateStore(RDX, RDXPtr);
    }
    return;
  }

  Value *Ptr = BuildStateRegisterPointer(B, State, ABIReg::RAX);
  if (!Ptr) {
    return;
  }
  Value *I64 = CoerceValue(B, Ret, B.getInt64Ty(), "abi.ret.i64");
  if (I64) {
    B.CreateStore(I64, Ptr);
  }
}

static bool RewriteImmediateRAXLoads(CallInst &NewCall) {
  if (NewCall.getType()->isVoidTy()) {
    return false;
  }
  bool Changed = false;
  BasicBlock *BB = NewCall.getParent();
  for (auto It = std::next(NewCall.getIterator()); It != BB->end(); ++It) {
    Instruction &I = *It;
    if (auto RA = IdentifyRegAccess(I)) {
      if (RA->Reg == ABIReg::RAX) {
        if (RA->IsStore) {
          break;
        }
        if (RA->IsLoad) {
          auto *LI = cast<LoadInst>(&I);
          IRBuilder<> B(LI);
          Value *ReturnValue = &NewCall;
          if (NewCall.getType()->isIntegerTy(128)) {
            ReturnValue = B.CreateTrunc(ReturnValue, B.getInt64Ty(),
                                        "abi.ret.rax");
          }
          Value *V = CoerceValue(B, ReturnValue, LI->getType(),
                                 "abi.ret.use");
          if (V) {
            LI->replaceAllUsesWith(V);
            Changed = true;
          }
        }
      }
    }
    if (isa<CallBase>(&I) && &I != &NewCall) {
      break;
    }
  }
  return Changed;
}

static bool RewriteImmediateRDXLoads(CallInst &NewCall) {
  if (!NewCall.getType()->isIntegerTy(128)) {
    return false;
  }
  bool Changed = false;
  BasicBlock *BB = NewCall.getParent();
  for (auto It = std::next(NewCall.getIterator()); It != BB->end(); ++It) {
    Instruction &I = *It;
    if (auto RA = IdentifyRegAccess(I)) {
      if (RA->Reg == ABIReg::RDX) {
        if (RA->IsStore) {
          break;
        }
        if (RA->IsLoad) {
          auto *LI = cast<LoadInst>(&I);
          IRBuilder<> B(LI);
          Type *I128Ty = Type::getIntNTy(B.getContext(), 128);
          Value *High = B.CreateLShr(
              &NewCall, ConstantInt::get(I128Ty, 64), "abi.ret.rdx.shifted");
          Value *RDX = B.CreateTrunc(High, B.getInt64Ty(), "abi.ret.rdx");
          Value *V = CoerceValue(B, RDX, LI->getType(), "abi.ret.rdx.use");
          if (V) {
            LI->replaceAllUsesWith(V);
            Changed = true;
          }
        }
      }
    }
    if (isa<CallBase>(&I) && &I != &NewCall) {
      break;
    }
  }
  return Changed;
}

static bool CanRewrite(CallInst &CI, FunctionABISummary &S,
                       CallsiteABIInfo &Info) {


  if (!S.NativeFn || !Info.RewritableMemoryResult) {
    return false;
  }
  Function *Caller = CI.getFunction();
  if (Caller && (Caller->getName() == "__remill_function_call" ||
                 Caller->getName() == "__remill_jump")) {
    return false;
  }
  if (CI.isMustTailCall() || CI.isNoTailCall()) {
    return false;
  }
  return true;
}

static bool IsMemoryTokenUse(Value *V, SmallPtrSetImpl<Value *> &Visited,
                             unsigned Depth) {
  if (!V || Depth > 16)
    return false;
  if (!Visited.insert(V).second)
    return true;

  for (User *U : V->users()) {
    if (auto *CB = dyn_cast<CallBase>(U)) {
      if (CB->arg_size() >= 3 && CB->getArgOperand(2) == V)
        continue;
      return false;
    }
    if (isa<ReturnInst>(U))
      continue;
    if (auto *PN = dyn_cast<PHINode>(U)) {
      if (!IsMemoryTokenUse(PN, Visited, Depth + 1))
        return false;
      continue;
    }
    if (auto *SI = dyn_cast<SelectInst>(U)) {
      if (!IsMemoryTokenUse(SI, Visited, Depth + 1))
        return false;
      continue;
    }
    return false;
  }
  return true;
}

static bool IsMemoryOnlyResult(CallInst &CI) {
  if (CI.use_empty())
    return true;
  SmallPtrSet<Value *, 16> Visited;
  return IsMemoryTokenUse(&CI, Visited, 0);
}

static bool RewriteOne(FunctionABISummary &S, CallsiteABIInfo &Info) {
  CallInst *Old = Info.Call;
  if (!Old || !Old->getParent()) {
    return false;
  }
  Function *Target = ResolveCalledFunction(Old->getCalledOperand());
  if (Target != S.RemillFn) {
    return false;
  }
  if (!CanRewrite(*Old, S, Info)) {
    return false;
  }

  IRBuilder<> B(Old);
  SmallVector<Value *, 12> Args;
  AddHiddenArgs(S, *Old, Args);
  for (ABIArgInfo &Arg : S.Args) {
    Value *V = BuildABIArg(B, S, Info, Arg, *Old);
    if (!V) {
      return false;
    }
    Args.push_back(V);
  }

  CallInst *NewCall = B.CreateCall(S.NativeFn, Args,
                                   (S.RetKind == ReturnKind::Void
                                        ? ""
                                        : S.OriginalName + ".ret"));
  NewCall->setCallingConv(S.NativeFn->getCallingConv());

  if (S.RetKind != ReturnKind::Void) {
    StoreReturnToState(B, S, *Old, NewCall);
    RewriteImmediateRAXLoads(*NewCall);
    if (S.RetKind == ReturnKind::IntRDXRAX) {
      RewriteImmediateRDXLoads(*NewCall);
    }
  }

  if (!Old->use_empty()) {
    Value *Mem = MemoryArg(*Old);
    if (!Mem) {
      return false;
    }
    Old->replaceAllUsesWith(Mem);
  }
  Old->eraseFromParent();
  Info.Rewritten = true;

  errs() << "[brighten-abi] callsite rewritten: caller="
         << NewCall->getFunction()->getName() << " target="
         << S.NativeFn->getName() << "\n";
  return true;
}

bool BrightenABIRecoveryPass::RewriteKnownCallsites(ABIRecoveryContext &Ctx) {
  bool Changed = false;

  // AnalyzeCallsiteABI runs before cloning.  Cloning creates additional
  // direct calls in the native bodies, so do not rely solely on the stale
  // per-summary callsite list.  Collect every current call to the original
  // Remill function before any rewrite mutates the module.
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (!S->Cloned || !S->NativeBodyRewritten) {
      continue;
    }

    SmallVector<CallInst *, 32> Calls;
    for (Function &Caller : Ctx.M) {
      if (Caller.isDeclaration())
        continue;
      for (BasicBlock &BB : Caller) {
        for (Instruction &I : BB) {
          auto *CI = dyn_cast<CallInst>(&I);
          if (!CI || ResolveCalledFunction(CI->getCalledOperand()) != S->RemillFn)
            continue;
          Calls.push_back(CI);
        }
      }
    }

    if (Ctx.Debug && !Calls.empty()) {
      errs() << "[brighten-abi] scan direct callsites: " << S->OriginalName
             << " count=" << Calls.size() << "\n";
    }

    for (CallInst *CI : Calls) {
      CallsiteABIInfo Info;
      Info.Call = CI;
      Info.Caller = CI->getFunction();
      Info.Target = S->RemillFn;
      // The lifted return is a memory token by contract.  Calls with no
      // users are also safe to rewrite.  Calls whose result is observed as a
      // register value remain for the explicit callsite analysis path.
      Info.RewritableMemoryResult = IsMemoryOnlyResult(*CI) ||
                                    S->ReturnsOriginalMemoryArg;
      bool Rewritten = RewriteOne(*S, Info);
      if (!Rewritten && Ctx.Debug && Info.RewritableMemoryResult) {
        errs() << "[brighten-abi] callsite preserved: caller="
               << CI->getFunction()->getName() << " target="
               << S->OriginalName << " memory-result="
               << (Info.RewritableMemoryResult ? "yes" : "no") << "\n";
      }
      Changed |= Rewritten;
    }
  }
  return Changed;
}

} // namespace brighten_abi
