#include "BrightenABIRecoveryPass.h"

#include "llvm/IR/CFG.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/raw_ostream.h"

#include <map>
#include <set>

namespace brighten_abi {

using namespace llvm;

using RegSet = std::set<ABIReg>;

static Value *NativeArgForReg(FunctionABISummary &S, ABIReg Reg) {
  unsigned Index = 0;
  if (S.HiddenState) {
    ++Index;
  }
  if (S.HiddenPC) {
    ++Index;
  }
  if (S.HiddenMemory) {
    ++Index;
  }
  for (const ABIArgInfo &Arg : S.Args) {
    if (Arg.Reg == Reg) {
      return S.NativeFn->getArg(Index);
    }
    ++Index;
  }
  return nullptr;
}

static bool IsMcsemaStateBase(Value *V) {
  if (!V) {
    return false;
  }
  V = V->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalVariable>(V)) {
    return GV->getName() == "__mcsema_reg_state";
  }
  if (auto *Alias = dyn_cast<GlobalAlias>(V)) {
    if (Alias->getName() == "__mcsema_reg_state") {
      return true;
    }
    if (Constant *Aliasee = Alias->getAliasee()) {
      return IsMcsemaStateBase(Aliasee);
    }
  }
  return false;
}

static Value *NativeStatePointer(IRBuilder<> &B, Value *State,
                                 uint64_t Offset) {
  if (!State) {
    return nullptr;
  }
  return B.CreateConstGEP1_64(B.getInt8Ty(), State, Offset,
                              "native.state.ptr");
}

static bool IsNativeStateConsumer(Function *F) {
  if (!F || F->arg_size() == 0 || !F->getArg(0)->getType()->isPointerTy()) {
    return false;
  }
  if (F->getName().ends_with(".native")) {
    return true;
  }
  return LooksLikeRemillFunction(*F);
}

// State-SSA deliberately runs before ABI cloning.  The clone can therefore
// still contain a mixture of the lifted global state and its explicit state
// argument.  Inside a native body those are the same logical object; keeping
// both forms makes it impossible for later ABI lowering to prove that the
// state argument is the only state source.  Canonicalize register accesses and
// native-to-native calls to the clone's state argument.
static bool CanonicalizeStatePointers(Function &F) {
  if (F.arg_size() == 0 ||
      !F.getArg(0)->getType()->isPointerTy()) {
    return false;
  }

  Value *State = F.getArg(0);
  bool Changed = false;
  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      if (auto RA = IdentifyRegAccess(I)) {
        Value *OldPtr = nullptr;
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          OldPtr = LI->getPointerOperand();
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          OldPtr = SI->getPointerOperand();
        }
        if (OldPtr) {
          // A global McSema state base is not proven identical to the explicit
          // State argument; preserve it unless alias analysis establishes that
          // identity.
          if (IsMcsemaStateBase(OldPtr->stripPointerCasts()))
            continue;
          IRBuilder<> B(&I);
          if (Value *NewPtr = NativeStatePointer(B, State, RA->Offset)) {
            if (auto *LI = dyn_cast<LoadInst>(&I)) {
              LI->setOperand(0, NewPtr);
            } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
              SI->setOperand(1, NewPtr);
            }
            Changed = true;
          }
        }
      }

      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI) {
        continue;
      }
      Function *Callee = ResolveCalledFunction(CI->getCalledOperand());
      if (!IsNativeStateConsumer(Callee) || CI->arg_size() == 0) {
        continue;
      }
      Value *Arg0 = CI->getArgOperand(0);
      if (!IsMcsemaStateBase(Arg0)) {
        continue;
      }
      CI->setArgOperand(0, State);
      Changed = true;
    }
  }
  return Changed;
}

static bool CanonicalizeNativeState(FunctionABISummary &S) {
  if (!S.HiddenState) {
    return false;
  }
  return CanonicalizeStatePointers(*S.NativeFn);
}

static RegSet IntersectPredOuts(BasicBlock &BB,
                                const std::map<BasicBlock *, RegSet> &Out) {
  bool First = true;
  RegSet Result;
  for (BasicBlock *Pred : predecessors(&BB)) {
    auto It = Out.find(Pred);
    RegSet PredOut = It == Out.end() ? RegSet{} : It->second;
    if (First) {
      Result = std::move(PredOut);
      First = false;
      continue;
    }
    for (auto RI = Result.begin(); RI != Result.end();) {
      if (!PredOut.count(*RI)) {
        RI = Result.erase(RI);
      } else {
        ++RI;
      }
    }
  }
  return Result;
}

static bool ReplaceLiveInLoads(FunctionABISummary &S) {
  Function &F = *S.NativeFn;
  std::map<BasicBlock *, RegSet> In;
  std::map<BasicBlock *, RegSet> Out;
  bool Changed = false;

  bool DataflowChanged = true;
  while (DataflowChanged) {
    DataflowChanged = false;
    for (BasicBlock &BB : F) {
      RegSet NewIn;
      if (&BB != &F.getEntryBlock()) {
        NewIn = IntersectPredOuts(BB, Out);
      }
      if (In[&BB] != NewIn) {
        In[&BB] = NewIn;
        DataflowChanged = true;
      }
      RegSet Def = In[&BB];
      for (Instruction &I : BB) {
        auto RA = IdentifyRegAccess(I);
        if (!RA) {
          continue;
        }
        if (RA->IsStore && IsArgumentRegister(RA->Reg)) {
          Def.insert(RA->Reg);
        }
      }
      if (Out[&BB] != Def) {
        Out[&BB] = std::move(Def);
        DataflowChanged = true;
      }
    }
  }

  SmallVector<Instruction *, 32> ToErase;
  for (BasicBlock &BB : F) {
    RegSet Def = In[&BB];
    for (Instruction &I : BB) {
      auto RA = IdentifyRegAccess(I);
      if (!RA) {
        continue;
      }
      if (RA->IsLoad && S.LiveIns.count(RA->Reg) && !Def.count(RA->Reg)) {
        auto *LI = dyn_cast<LoadInst>(&I);
        if (!LI || LI->isVolatile()) {
          continue;
        }
        Value *Arg = NativeArgForReg(S, RA->Reg);
        if (!Arg) {
          continue;
        }
        IRBuilder<> B(LI);
        Value *Replacement =
            CoerceValue(B, Arg, LI->getType(), GetRegisterName(RA->Reg));
        if (!Replacement) {
          continue;
        }
        LI->replaceAllUsesWith(Replacement);
        ToErase.push_back(LI);
        Changed = true;
      }
      if (RA->IsStore && IsArgumentRegister(RA->Reg)) {
        Def.insert(RA->Reg);
      }
    }
  }

  for (Instruction *I : ToErase) {
    I->eraseFromParent();
  }
  return Changed;
}

static bool RewriteReturns(FunctionABISummary &S) {
  Function &F = *S.NativeFn;
  SmallVector<ReturnInst *, 8> Returns;
  for (BasicBlock &BB : F) {
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator())) {
      Returns.push_back(RI);
    }
  }

  bool Changed = false;
  for (ReturnInst *RI : Returns) {
    IRBuilder<> B(RI);
    if (S.RetKind == ReturnKind::Void) {
      B.CreateRetVoid();
      RI->eraseFromParent();
      Changed = true;
      continue;
    }

    Value *RetV = nullptr;
    if (S.RetKind == ReturnKind::IntRDXRAX) {
      Value *RAX = FindRegisterValueBeforeReturn(RI, ABIReg::RAX);
      Value *RDX = FindRegisterValueBeforeReturn(RI, ABIReg::RDX);
      if (!RAX || !RDX) {
        errs() << "[brighten-abi] skipped return rewrite: " << S.OriginalName
               << " reason=no-rdx-rax-value\n";
        continue;
      }
      RAX = CoerceValue(B, RAX, B.getInt64Ty(), "abi.ret.rax");
      RDX = CoerceValue(B, RDX, B.getInt64Ty(), "abi.ret.rdx");
      if (!RAX || !RDX) {
        errs() << "[brighten-abi] skipped return rewrite: " << S.OriginalName
               << " reason=rdx-rax-type-conflict\n";
        continue;
      }
      Type *I128Ty = Type::getIntNTy(B.getContext(), 128);
      Value *Low = B.CreateZExt(RAX, I128Ty, "abi.ret.low");
      Value *High = B.CreateZExt(RDX, I128Ty, "abi.ret.high");
      High = B.CreateShl(High, ConstantInt::get(I128Ty, 64),
                          "abi.ret.high.shifted");
      RetV = B.CreateOr(High, Low, "abi.ret.rdxrax");
    } else {
      RetV = FindRegisterValueBeforeReturn(RI, ABIReg::RAX);
      if (!RetV) {
        errs() << "[brighten-abi] skipped return rewrite: " << S.OriginalName
               << " reason=no-rax-value\n";
        continue;
      }
      RetV = CoerceValue(B, RetV, S.RetTy, "abi.ret");
    }
    if (!RetV) {
      errs() << "[brighten-abi] skipped return rewrite: " << S.OriginalName
             << " reason=ret-type-conflict\n";
      continue;
    }
    B.CreateRet(RetV);
    RI->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

bool BrightenABIRecoveryPass::RewriteNativeFunctionBodies(
    ABIRecoveryContext &Ctx) {
  bool Changed = false;
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (!S->Cloned || !S->NativeFn) {
      continue;
    }
    Changed |= CanonicalizeNativeState(*S);
    Changed |= ReplaceLiveInLoads(*S);
    Changed |= RewriteReturns(*S);
    S->NativeBodyRewritten = true;
  }

  // External bridges and unresolved lifted wrappers have the same canonical
  // state ABI but are not represented by a native-function summary.  Apply
  // the same normalization to them so the global state is not reintroduced at
  // wrapper boundaries.
  for (Function &F : Ctx.M) {
    if (F.isDeclaration() || F.getName().ends_with(".native") ||
        !LooksLikeRemillFunction(F)) {
      continue;
    }
    Changed |= CanonicalizeStatePointers(F);
  }
  return Changed;
}

} // namespace brighten_abi
