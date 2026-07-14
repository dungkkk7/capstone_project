#include "BrightenExternCallBridgePass.h"

#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_extern {

using namespace llvm;

static constexpr uint64_t kOffRAX = 2216;

static Module *FindModule(Value *V) {
  if (!V) return nullptr;
  if (auto *I = dyn_cast<Instruction>(V)) return I->getModule();
  if (auto *GV = dyn_cast<GlobalValue>(V)) return GV->getParent();
  if (auto *GEP = dyn_cast<GEPOperator>(V)) return FindModule(GEP->getPointerOperand());
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    for (Value *Op : CE->operands()) {
      if (Module *M = FindModule(Op)) return M;
    }
  }
  return nullptr;
}

static std::optional<uint64_t> IdentifyStateOffset(Value *Ptr) {
  if (!Ptr)
    return std::nullopt;

  Value *Stripped = Ptr->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalValue>(Stripped)) {
    StringRef Name = GV->getName();
    if (Name == "RAX" || Name == "rax") return 2216;
    if (Name == "RDI" || Name == "rdi") return 2296;
    if (Name == "RSI" || Name == "rsi") return 2280;
    if (Name == "RDX" || Name == "rdx") return 2264;
    if (Name == "RCX" || Name == "rcx") return 2248;
    if (Name == "R8" || Name == "r8") return 2344;
    if (Name == "R9" || Name == "r9") return 2360;
    if (Name == "RSP" || Name == "rsp") return 2312;
    if (Name == "RBP" || Name == "rbp") return 2328;

    // Parse offset from whitelisted register variable names like RDI_2296_xxxx
    bool ValidPrefix = Name.starts_with("RAX_") || Name.starts_with("rax_") ||
                       Name.starts_with("RDI_") || Name.starts_with("rdi_") ||
                       Name.starts_with("RSI_") || Name.starts_with("rsi_") ||
                       Name.starts_with("RDX_") || Name.starts_with("rdx_") ||
                       Name.starts_with("RCX_") || Name.starts_with("rcx_") ||
                       Name.starts_with("R8_")  || Name.starts_with("r8_")  ||
                       Name.starts_with("R9_")  || Name.starts_with("r9_")  ||
                       Name.starts_with("RSP_") || Name.starts_with("rsp_") ||
                       Name.starts_with("RBP_") || Name.starts_with("rbp_") ||
                       Name.starts_with("XMM")  || Name.starts_with("xmm");
    if (ValidPrefix) {
      size_t Underscore1 = Name.find('_');
      if (Underscore1 != StringRef::npos) {
        size_t Underscore2 = Name.find('_', Underscore1 + 1);
        StringRef NumStr = (Underscore2 != StringRef::npos) 
          ? Name.substr(Underscore1 + 1, Underscore2 - Underscore1 - 1)
          : Name.substr(Underscore1 + 1);
        uint64_t Val;
        if (!NumStr.getAsInteger(10, Val)) {
          return Val;
        }
      }
    }
  }

  Module *M = FindModule(Stripped);
  if (!M)
    return std::nullopt;

  const DataLayout &DL = M->getDataLayout();
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Stripped->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (!Base || Offset.isNegative())
    return std::nullopt;

  Base = Base->stripPointerCasts();
  if (auto *Alias = dyn_cast<GlobalAlias>(Base)) {
    if (Constant *Aliasee = Alias->getAliasee())
      Base = Aliasee->stripPointerCasts();
  }
  auto *GV = dyn_cast<GlobalValue>(Base);
  if (!GV)
    return std::nullopt;
  if (GV->getName() == "__mcsema_reg_state")
    return Offset.getZExtValue();

  // Also parse offset if the base variable itself has offset encoded in its name
  StringRef BaseName = GV->getName();
  bool ValidBasePrefix = BaseName.starts_with("RAX_") || BaseName.starts_with("rax_") ||
                         BaseName.starts_with("RDI_") || BaseName.starts_with("rdi_") ||
                         BaseName.starts_with("RSI_") || BaseName.starts_with("rsi_") ||
                         BaseName.starts_with("RDX_") || BaseName.starts_with("rdx_") ||
                         BaseName.starts_with("RCX_") || BaseName.starts_with("rcx_") ||
                         BaseName.starts_with("R8_")  || BaseName.starts_with("r8_")  ||
                         BaseName.starts_with("R9_")  || BaseName.starts_with("r9_")  ||
                         BaseName.starts_with("RSP_") || BaseName.starts_with("rsp_") ||
                         BaseName.starts_with("RBP_") || BaseName.starts_with("rbp_") ||
                         BaseName.starts_with("XMM")  || BaseName.starts_with("xmm");
  if (ValidBasePrefix) {
    size_t Underscore1 = BaseName.find('_');
    if (Underscore1 != StringRef::npos) {
      size_t Underscore2 = BaseName.find('_', Underscore1 + 1);
      StringRef NumStr = (Underscore2 != StringRef::npos) 
        ? BaseName.substr(Underscore1 + 1, Underscore2 - Underscore1 - 1)
        : BaseName.substr(Underscore1 + 1);
      uint64_t Val;
      if (!NumStr.getAsInteger(10, Val)) {
        return Val + Offset.getZExtValue();
      }
    }
  }

  return std::nullopt;
}

// FIX #8: Recursive memory-token use validation
// Walk all users of the old call result and verify every use is a memory-token
// position (arg2 of Remill call, return, or PHI that eventually feeds only
// memory-token positions).
static bool IsMemoryTokenUse(Value *V, SmallPtrSetImpl<Value *> &Visited,
                              unsigned Depth) {
  if (!V || Depth > 16 || !Visited.insert(V).second)
    return true; // cycles are ok (conservative: memory token loops)

  for (User *U : V->users()) {
    if (auto *CI = dyn_cast<CallInst>(U)) {
      // Used as arg[2] (memory) of Remill call
      if (CI->arg_size() >= 3 && CI->getArgOperand(2) == V) continue;
      return false;
    }
    if (auto *Ret = dyn_cast<ReturnInst>(U)) continue;
    if (auto *Phi = dyn_cast<PHINode>(U)) {
      if (!IsMemoryTokenUse(Phi, Visited, Depth + 1))
        return false;
      continue;
    }
    if (auto *Sel = dyn_cast<SelectInst>(U)) {
      if (!IsMemoryTokenUse(Sel, Visited, Depth + 1))
        return false;
      continue;
    }
    return false;
  }
  return true;
}

static bool OldCallResultIsMemoryOnly(CallInst *CI) {
  if (CI->use_empty()) return true;
  SmallPtrSet<Value *, 16> Visited;
  return IsMemoryTokenUse(CI, Visited, 0);
}

static Function *GetOrDeclareLibcFunction(Module &M,
                                            const LibcSignatureDB &SigDB,
                                            const LibcSignature &Sig) {
  LLVMContext &Ctx = M.getContext();
  FunctionType *FTy = SigDB.buildFunctionType(Ctx, Sig);

  Function *Existing = M.getFunction(Sig.Name);
  if (Existing) {
    if (Existing->getFunctionType() == FTy) return Existing;
    if (Existing->isDeclaration() && Existing->use_empty()) {
      Existing->eraseFromParent();
    } else if (Existing->isDeclaration()) {
      std::string OldName = Existing->getName().str();
      Existing->setName(OldName + ".old");
      Function *NewF = Function::Create(FTy, GlobalValue::ExternalLinkage,
                                         OldName, &M);
      NewF->setCallingConv(Existing->getCallingConv());
      if (Sig.Special == LibcSpecialKind::NoReturn)
        NewF->addFnAttr(Attribute::NoReturn);
      Existing->replaceAllUsesWith(ConstantExpr::getBitCast(NewF, Existing->getType()));
      return NewF;
    } else {
      return nullptr;
    }
  }

  Function *F = Function::Create(FTy, GlobalValue::ExternalLinkage,
                                  Sig.Name, &M);
  if (Sig.Special == LibcSpecialKind::NoReturn)
    F->addFnAttr(Attribute::NoReturn);
  return F;
}

static void StoreReturnToRAX(IRBuilder<> &B, Value *StatePtr, Value *Ret) {
  if (!Ret || Ret->getType()->isVoidTy()) return;
  Value *Ret64 = nullptr;
  Type *Ty = Ret->getType();
  if (Ty->isPointerTy()) {
    Ret64 = B.CreatePtrToInt(Ret, B.getInt64Ty(), "ext.ret.pti");
  } else if (Ty->isIntegerTy()) {
    unsigned Bits = Ty->getIntegerBitWidth();
    if (Bits < 64) Ret64 = B.CreateZExt(Ret, B.getInt64Ty(), "ext.ret.zext");
    else if (Bits > 64) Ret64 = B.CreateTrunc(Ret, B.getInt64Ty(), "ext.ret.trunc");
    else Ret64 = Ret;
  } else {
    return;
  }
  Value *RAXPtr = B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, kOffRAX,
                                        "rax.ptr");
  B.CreateAlignedStore(Ret64, RAXPtr, Align(8));
}

static bool ReplaceImmediateRAXLoads(CallInst *NewCall) {
  if (NewCall->getType()->isVoidTy()) return false;
  bool Changed = false;
  BasicBlock *BB = NewCall->getParent();
  for (auto It = std::next(NewCall->getIterator()); It != BB->end(); ++It) {
    Instruction &I = *It;
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      auto Off = IdentifyStateOffset(LI->getPointerOperand());
      if (Off && *Off == kOffRAX) {
        IRBuilder<> B(LI);
        Value *V = NewCall;
        Type *Dst = LI->getType();
        if (V->getType() != Dst) {
          if (V->getType()->isPointerTy() && Dst->isIntegerTy())
            V = B.CreatePtrToInt(V, Dst, "ext.rax.pti");
          else if (V->getType()->isIntegerTy() && Dst->isPointerTy())
            V = B.CreateIntToPtr(V, Dst, "ext.rax.itp");
          else if (V->getType()->isIntegerTy() && Dst->isIntegerTy()) {
            unsigned SW = V->getType()->getIntegerBitWidth();
            unsigned DW = Dst->getIntegerBitWidth();
            if (SW > DW) V = B.CreateTrunc(V, Dst);
            else V = B.CreateZExt(V, Dst);
          } else break;
        }
        LI->replaceAllUsesWith(V);
        Changed = true;
      }
    }
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      auto Off = IdentifyStateOffset(SI->getPointerOperand());
      if (Off && *Off == kOffRAX) break;
    }
    if (isa<CallBase>(&I) && &I != NewCall) break;
  }
  return Changed;
}

// FIX #9: Check if caller is a native Phase 5 function (non-Remill signature)
static bool CallerIsNativeFunction(Function *F) {
  if (!F) return false;
  // Native functions have non-Remill signatures: not (ptr, i64, ptr) -> ptr
  if (F->arg_size() == 3 && F->getReturnType()->isPointerTy()) {
    auto It = F->arg_begin();
    if ((It++)->getType()->isPointerTy() &&
        (It++)->getType()->isIntegerTy(64) &&
        (It++)->getType()->isPointerTy())
      return false; // Remill signature
  }
  // Check for .native suffix
  if (F->getName().ends_with(".native")) return true;
  // Non-Remill signature => native
  return true;
}

bool BrightenExternCallBridgePass::RewriteExternalCallsites(
    ExternCallContext &Ctx) {
  bool Changed = false;

  for (auto &CS : Ctx.Callsites) {
    if (!CS->Target.Resolved || !CS->Target.Signature) continue;
    if (!CS->SkipReason.empty() || CS->Action == "preserve") continue;

    CallInst *OldCI = CS->OrigCall;
    if (!OldCI || !OldCI->getParent()) continue;

    bool AllValid = true;
    for (auto &Arg : CS->Args) {
      if (!Arg.IsValid) { AllValid = false; break; }
    }
    if (!AllValid) {
      CS->Action = "preserve";
      if (CS->SkipReason.empty()) CS->SkipReason = "arg-type-conflict";
      continue;
    }

    if (!OldCallResultIsMemoryOnly(OldCI)) {
      CS->Action = "preserve";
      CS->SkipReason = "memory-result-use-unsafe";
      continue;
    }

    const LibcSignature &Sig = *CS->Target.Signature;
    Function *ExtFn = GetOrDeclareLibcFunction(Ctx.M, Ctx.SigDB, Sig);
    if (!ExtFn) {
      CS->Action = "preserve";
      CS->SkipReason = "external-declaration-conflict";
      continue;
    }

    IRBuilder<> B(OldCI);
    SmallVector<Value *, 12> CallArgs;
    for (auto &Arg : CS->Args) CallArgs.push_back(Arg.Val);

    FunctionType *FTy = ExtFn->getFunctionType();
    for (unsigned I = 0; I < CallArgs.size() && I < FTy->getNumParams(); ++I) {
      Type *Expected = FTy->getParamType(I);
      if (CallArgs[I]->getType() != Expected) {
        Value *V = CallArgs[I];
        Type *Src = V->getType();
        if (Src->isIntegerTy() && Expected->isPointerTy())
          CallArgs[I] = B.CreateIntToPtr(V, Expected);
        else if (Src->isPointerTy() && Expected->isIntegerTy())
          CallArgs[I] = B.CreatePtrToInt(V, Expected);
        else if (Src->isIntegerTy() && Expected->isIntegerTy()) {
          unsigned SW = Src->getIntegerBitWidth();
          unsigned DW = Expected->getIntegerBitWidth();
          if (SW > DW) CallArgs[I] = B.CreateTrunc(V, Expected);
          else CallArgs[I] = B.CreateZExt(V, Expected);
        }
      }
    }

    bool IsVoid = Sig.Special == LibcSpecialKind::Deallocator ||
                  Sig.Special == LibcSpecialKind::NoReturn;
    CallInst *NewCall;
    if (FTy->isVarArg()) {
      NewCall = B.CreateCall(FTy, ExtFn, CallArgs,
                              IsVoid ? "" : CS->Target.SymbolName + ".ret");
    } else {
      NewCall = B.CreateCall(ExtFn, CallArgs,
                              IsVoid ? "" : CS->Target.SymbolName + ".ret");
    }
    NewCall->setCallingConv(ExtFn->getCallingConv());

    // FIX #9: For native callers (post-Phase5), prefer direct SSA use.
    // For Remill-style callers, store into RAX.
    bool IsNativeCaller = CallerIsNativeFunction(CS->Caller);
    if (!NewCall->getType()->isVoidTy() && OldCI->arg_size() >= 1) {
      Value *StatePtr = OldCI->getArgOperand(0);
      if (!IsNativeCaller) {
        StoreReturnToRAX(B, StatePtr, NewCall);
      }
      ReplaceImmediateRAXLoads(NewCall);
    }

    // FIX #7: Handle noreturn safely — remove successor edges, clear PHI incoming, and truncate block safely
    if (Sig.Special == LibcSpecialKind::NoReturn) {
      BasicBlock *BB = NewCall->getParent();
      Instruction *Term = BB->getTerminator();
      if (Term) {
        for (BasicBlock *Succ : successors(BB)) {
          Succ->removePredecessor(BB);
        }
        Term->eraseFromParent();
      }
      SmallVector<Instruction *, 16> ToErase;
      bool FoundNew = false;
      for (Instruction &I : *BB) {
        if (&I == NewCall) { FoundNew = true; continue; }
        if (FoundNew && &I != OldCI) {
          ToErase.push_back(&I);
        }
      }
      if (!OldCI->use_empty()) {
        Value *Mem = OldCI->arg_size() >= 3 ? OldCI->getArgOperand(2) : nullptr;
        if (Mem) OldCI->replaceAllUsesWith(Mem);
        else OldCI->replaceAllUsesWith(Constant::getNullValue(OldCI->getType()));
      }
      OldCI->eraseFromParent();
      for (auto It = ToErase.rbegin(); It != ToErase.rend(); ++It) {
        if (!(*It)->use_empty()) {
          (*It)->replaceAllUsesWith(Constant::getNullValue((*It)->getType()));
        }
        (*It)->eraseFromParent();
      }
      IRBuilder<> B2(BB);
      B2.CreateUnreachable();
    } else {
      // Normal case: replace old call uses with memory arg
      if (!OldCI->use_empty()) {
        Value *Mem = OldCI->arg_size() >= 3 ? OldCI->getArgOperand(2) : nullptr;
        if (Mem) OldCI->replaceAllUsesWith(Mem);
        else OldCI->replaceAllUsesWith(Constant::getNullValue(OldCI->getType()));
      }
      OldCI->eraseFromParent();
    }

    CS->OrigCall = nullptr;
    CS->Rewritten = true;

    bool AnyFallback = false;
    for (auto &Arg : CS->Args) {
      if (Arg.IsFallbackTranslated) AnyFallback = true;
      if (Arg.Provenance != PointerProvenance::Unknown &&
          Arg.Ty && Arg.Ty->isPointerTy()) {
        if (Arg.IsFallbackTranslated) ++Ctx.Report.PointerArgsFallback;
        else ++Ctx.Report.PointerArgsNative;
      }
    }
    CS->Action = AnyFallback ? "rewrite-compat" : "rewrite-native";
    if (AnyFallback) { CS->FallbackUsed = true; ++Ctx.Report.RewrittenCompat; }
    else ++Ctx.Report.RewrittenNative;

    Changed = true;
    if (Ctx.Debug) {
      errs() << "[brighten-extern] rewritten: caller="
             << CS->Caller->getName() << " target=" << CS->Target.SymbolName
             << " action=" << CS->Action << " args=" << CS->Args.size() << "\n";
    }
  }

  return Changed;
}

// FIX #9: RewriteExternalReturns — propagate native SSA return values
// to callers that read RAX after the external call across basic blocks.
bool BrightenExternCallBridgePass::RewriteExternalReturns(
    ExternCallContext &Ctx) {
  bool Changed = false;

  // For each rewritten callsite, scan subsequent basic blocks for RAX loads
  // that haven't been replaced yet and replace them with the return value.
  for (auto &CS : Ctx.Callsites) {
    if (!CS->Rewritten || !CS->Target.Signature) continue;
    const LibcSignature &Sig = *CS->Target.Signature;
    if (Sig.Special == LibcSpecialKind::Deallocator ||
        Sig.Special == LibcSpecialKind::NoReturn) continue;

    // Find the new call instruction in the caller
    Function *Caller = CS->Caller;
    if (!Caller) continue;

    // Walk through the function looking for the call we inserted
    for (BasicBlock &BB : *Caller) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI) continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee || Callee->getName() != CS->Target.SymbolName) continue;
        if (CI->getType()->isVoidTy()) continue;

        // Found the native call — now scan for RAX loads after it
        // that load from the same RAX store we made
        ReplaceImmediateRAXLoads(CI);
        Changed = true;
      }
    }
  }

  return Changed;
}

} // namespace brighten_extern
