#include "BrightenABIRecoveryPass.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/raw_ostream.h"

#include <functional>

namespace brighten_abi {

using namespace llvm;

static Value *BuildArgLoad(IRBuilder<> &B, Value *State, ABIArgInfo &Arg) {
  Value *Ptr = BuildStateRegisterPointer(B, State, Arg.Reg);
  if (!Ptr) {
    return nullptr;
  }
  Type *LoadTy = Arg.Ty->isPointerTy() ? B.getInt64Ty() : Arg.Ty;
  Value *V = B.CreateLoad(LoadTy, Ptr, (GetRegisterName(Arg.Reg) + ".mw").str());
  return CoerceValue(B, V, Arg.Ty, GetRegisterName(Arg.Reg));
}

static Value *BuildEntrypointRegisterArg(IRBuilder<> &B, Function &Main,
                                         Value *State, ABIReg Reg, Type *Ty) {
  if (Reg == ABIReg::RDI && Main.arg_size() > 0)
    return CoerceValue(B, Main.getArg(0), B.getInt64Ty(), "main.argc");
  if (Reg == ABIReg::RSI && Main.arg_size() > 1)
    return CoerceValue(B, B.CreatePtrToInt(Main.getArg(1), B.getInt64Ty()),
                       B.getInt64Ty(), "main.argv");
  if (Reg == ABIReg::RDX && Main.arg_size() > 2)
    return CoerceValue(B, B.CreatePtrToInt(Main.getArg(2), B.getInt64Ty()),
                       B.getInt64Ty(), "main.envp");

  ABIArgInfo Arg;
  Arg.Reg = Reg;
  Arg.Ty = Ty ? Ty : B.getInt64Ty();
  return BuildArgLoad(B, State, Arg);
}

static Value *MaterializeLocalState(ABIRecoveryContext &Ctx, Function &Main,
                                    GlobalVariable *State) {
  if (!State || Main.empty()) {
    return nullptr;
  }

  uint64_t StateBytes =
      Ctx.DL.getTypeAllocSize(State->getValueType()).getFixedValue();
  if (StateBytes == 0) {
    return nullptr;
  }

  IRBuilder<> B(&Main.getEntryBlock(), Main.getEntryBlock().begin());
  AllocaInst *Local =
      B.CreateAlloca(B.getInt8Ty(), B.getInt64(StateBytes), "native_state");
  Local->setAlignment(Align(16));
  B.CreateMemSet(Local, B.getInt8(0), B.getInt64(StateBytes), Align(1));

  std::function<Value *(Value *, Instruction *)> Materialize =
      [&](Value *V, Instruction *Before) -> Value * {
    if (V == State) {
      return Local;
    }
    auto *CE = dyn_cast<ConstantExpr>(V);
    if (!CE) {
      return V;
    }

    Instruction *Clone = CE->getAsInstruction();
    bool Changed = false;
    for (unsigned I = 0; I < Clone->getNumOperands(); ++I) {
      Value *OldOp = Clone->getOperand(I);
      Value *NewOp = Materialize(OldOp, Before);
      if (NewOp != OldOp) {
        Clone->setOperand(I, NewOp);
        Changed = true;
      }
    }
    if (!Changed) {
      Clone->deleteValue();
      return V;
    }
    Clone->insertBefore(Before);
    return Clone;
  };

  for (BasicBlock &BB : Main) {
    for (Instruction &I : BB) {
      for (unsigned Op = 0; Op < I.getNumOperands(); ++Op) {
        Value *OldOp = I.getOperand(Op);
        Value *NewOp = Materialize(OldOp, &I);
        if (NewOp != OldOp) {
          I.setOperand(Op, NewOp);
        }
      }
    }
  }
  return Local;
}

// Replace the McSema-generated main -> main_wrapper edge with a direct call
// to the recovered native function.  Keeping the wrapper alive as the only
// entry edge would preserve the State ABI even when its body is native.
static bool RewriteNativeMainEntrypoint(ABIRecoveryContext &Ctx,
                                        FunctionABISummary &S) {
  Function *Main = Ctx.M.getFunction("main");
  GlobalVariable *State = Ctx.M.getGlobalVariable("__mcsema_reg_state");
  if (!Main || !S.NativeFn || !State) {
    return false;
  }

  CallInst *WrapperCall = nullptr;
  for (BasicBlock &BB : *Main) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (CI && ResolveCalledFunction(CI->getCalledOperand()) ==
                    Ctx.M.getFunction("main_wrapper")) {
        WrapperCall = CI;
        break;
      }
    }
    if (WrapperCall)
      break;
  }
  if (!WrapperCall) {
    return false;
  }

  Value *LocalState = MaterializeLocalState(Ctx, *Main, State);
  if (!LocalState) {
    return false;
  }

  IRBuilder<> B(WrapperCall);
  SmallVector<Value *, 12> Args;
  if (S.HiddenState)
    Args.push_back(LocalState);
  if (S.HiddenPC)
    Args.push_back(B.getInt64(0));
  if (S.HiddenMemory)
    Args.push_back(ConstantPointerNull::get(B.getPtrTy()));
  for (const ABIArgInfo &Arg : S.Args) {
    Value *V =
        BuildEntrypointRegisterArg(B, *Main, LocalState, Arg.Reg, Arg.Ty);
    if (!V) {
      return false;
    }
    Value *Coerced =
        CoerceValue(B, V, Arg.Ty, GetRegisterName(Arg.Reg));
    // Never let an unsupported ABI conversion become a null call operand.
    // The verifier will reject such IR, while returning false leaves the
    // original wrapper intact for a later, conservative failure path.
    if (!Coerced) {
      return false;
    }
    Args.push_back(Coerced);
  }

  CallInst *NativeCall = B.CreateCall(
      S.NativeFn, Args,
      S.RetKind == ReturnKind::Void ? "" : "main.native");
  NativeCall->setCallingConv(S.NativeFn->getCallingConv());
  if (S.RetKind != ReturnKind::Void) {
    Value *RAX = BuildStateRegisterPointer(B, LocalState, ABIReg::RAX);
    Value *Ret = CoerceValue(B, NativeCall, B.getInt64Ty(), "main.ret.i64");
    if (RAX && Ret)
      B.CreateStore(Ret, RAX);
  }

  if (!WrapperCall->use_empty())
    WrapperCall->replaceAllUsesWith(ConstantPointerNull::get(B.getPtrTy()));
  WrapperCall->eraseFromParent();
  errs() << "[brighten-abi] entrypoint rewritten: main -> "
         << S.NativeFn->getName() << "\n";
  return true;
}

bool BrightenABIRecoveryPass::RewriteMainWrapper(ABIRecoveryContext &Ctx) {
  Function *MW = Ctx.M.getFunction("main_wrapper");
  if (!MW) {
    return false;
  }

  FunctionABISummary *MainS = nullptr;
  CallInst *MainCall = nullptr;
  for (BasicBlock &BB : *MW) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI) continue;
      Function *Target = ResolveCalledFunction(CI->getCalledOperand());
      if (!Target) continue;

      FunctionABISummary *Candidate = FindSummary(Ctx, Target);
      // RewriteKnownCallsites runs before this compatibility-specific pass.
      // Do not reinterpret the already-native call as a Remill call and add
      // the ABI arguments a second time.
      if (Candidate && Candidate->NativeFn && Target == Candidate->RemillFn) {
        MainS = Candidate;
        MainCall = CI;
        break;
      }
    }
    if (MainCall) break;
  }

  // The lifted entry function address is not stable across binaries.  After
  // RewriteKnownCallsites the wrapper normally calls the recovered native
  // function directly, so discover the summary from that call instead of
  // relying on the old single-binary `sub_1190_main` spelling.
  if (!MainS) {
    for (BasicBlock &BB : *MW) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI)
          continue;
        if (FunctionABISummary *Candidate =
                FindSummary(Ctx, ResolveCalledFunction(CI->getCalledOperand()))) {
          if (Candidate->NativeFn) {
            MainS = Candidate;
            break;
          }
        }
      }
      if (MainS)
        break;
    }
  }

  if (!MainS) {
    // Keep a name-based fallback for modules whose wrapper call could not be
    // rewritten, but accept any recovered *_main candidate.
    for (FunctionABISummary *Candidate : Ctx.Summaries) {
      if (Candidate->NativeFn &&
          StringRef(Candidate->OriginalName).contains("_main")) {
        MainS = Candidate;
        break;
      }
    }
  }

  bool EntrypointChanged =
      MainS && MainS->NativeFn && RewriteNativeMainEntrypoint(Ctx, *MainS);
  if (!MainCall || !MainS || !MainS->NativeFn)
    return EntrypointChanged;

  bool Changed = false;
  IRBuilder<> B(MainCall);
  SmallVector<Value *, 12> Args;
  if (MainS->HiddenState) {
    Args.push_back(MainCall->arg_size() > 0 ? MainCall->getArgOperand(0) :
                   Constant::getNullValue(B.getPtrTy()));
  }
  if (MainS->HiddenPC) {
    Args.push_back(MainCall->arg_size() > 1 ? MainCall->getArgOperand(1) : B.getInt64(0));
  }
  if (MainS->HiddenMemory) {
    Args.push_back(MainCall->arg_size() > 2 ? MainCall->getArgOperand(2) :
                   Constant::getNullValue(B.getPtrTy()));
  }
  for (ABIArgInfo &Arg : MainS->Args) {
    Value *StatePtr = MainCall->arg_size() > 0 ? MainCall->getArgOperand(0) : MW->getArg(0);
    Value *V = BuildArgLoad(B, StatePtr, Arg);
    if (!V) {
      return Changed;
    }
    Args.push_back(V);
  }

  CallInst *NewCall =
      B.CreateCall(MainS->NativeFn, Args,
                   MainS->RetKind == ReturnKind::Void ? "" : "main.ret");
  NewCall->setCallingConv(MainS->NativeFn->getCallingConv());

  if (MainS->RetKind != ReturnKind::Void) {
    Value *StatePtr = MainCall->arg_size() > 0 ? MainCall->getArgOperand(0) : MW->getArg(0);
    Value *Ptr = BuildStateRegisterPointer(B, StatePtr,
                                           ABIReg::RAX);
    Value *I64 = CoerceValue(B, NewCall, B.getInt64Ty(), "main.ret.i64");
    if (Ptr && I64) {
      B.CreateStore(I64, Ptr);
    }
  }

  if (!MainCall->use_empty()) {
    Value *MemVal = MainCall->arg_size() > 2 ? MainCall->getArgOperand(2) : MW->getArg(2);
    MainCall->replaceAllUsesWith(MemVal);
  }
  MainCall->eraseFromParent();
  Changed = true;
  errs() << "[brighten-abi] callsite rewritten: caller=main_wrapper target="
         << MainS->NativeFn->getName() << "\n";

  return Changed || EntrypointChanged;
}

} // namespace brighten_abi
