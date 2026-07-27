#include "BrightenABIRecoveryPass.h"

#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

#include <map>

namespace brighten_abi {

using namespace llvm;

namespace {

struct CallbackSource {
  Argument *Arg = nullptr;
  Constant *C = nullptr;
};

struct CallbackRewritePlan {
  Function *Adapter = nullptr;
  Function *Bridge = nullptr;
  FunctionABISummary *Target = nullptr;
  CallInst *BridgeCall = nullptr;
  CallInst *NativeCall = nullptr;
  std::map<ABIReg, CallbackSource> RegisterSources;
  CallbackSource PCSource;
  CallbackSource MemorySource;
};

static Value *StripAlias(Value *V) {
  if (!V)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *GA = dyn_cast<GlobalAlias>(V)) {
    if (Constant *Aliasee = GA->getAliasee())
      return Aliasee->stripPointerCasts();
  }
  return V;
}

static bool PointerHasBase(Value *Ptr, Value *Expected,
                           const DataLayout &DL) {
  if (!Ptr || !Expected)
    return false;
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Ptr->stripAndAccumulateConstantOffsets(DL, Offset, true);
  return StripAlias(Base) == StripAlias(Expected);
}

static bool IsPureCast(const Instruction &I) {
  return isa<CastInst>(I) || isa<FreezeInst>(I);
}

static bool IsDerivedThroughPureCasts(Value *V, Value *Root) {
  SmallPtrSet<Value *, 8> Seen;
  while (V && Seen.insert(V).second) {
    if (V == Root)
      return true;
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !IsPureCast(*I) || I->getNumOperands() != 1)
      return false;
    V = I->getOperand(0);
  }
  return false;
}

static std::optional<CallbackSource> FindCallbackSource(Value *V,
                                                        Function &Adapter) {
  SmallPtrSet<Value *, 8> Seen;
  while (V && Seen.insert(V).second) {
    if (auto *Arg = dyn_cast<Argument>(V)) {
      if (Arg->getParent() != &Adapter)
        return std::nullopt;
      return CallbackSource{Arg, nullptr};
    }
    if (auto *C = dyn_cast<Constant>(V))
      return CallbackSource{nullptr, C};
    auto *I = dyn_cast<Instruction>(V);
    if (!I || I->getFunction() != &Adapter || !IsPureCast(*I) ||
        I->getNumOperands() != 1)
      return std::nullopt;
    V = I->getOperand(0);
  }
  return std::nullopt;
}

static bool CanCoerce(Type *Src, Type *Dst) {
  if (!Src || !Dst)
    return false;
  if (Src == Dst)
    return true;
  if (Src->isPointerTy() && Dst->isPointerTy())
    return cast<PointerType>(Src)->getAddressSpace() ==
           cast<PointerType>(Dst)->getAddressSpace();
  if (Src->isPointerTy() && Dst->isIntegerTy())
    return true;
  if (Src->isIntegerTy() && (Dst->isPointerTy() || Dst->isIntegerTy()))
    return true;
  if (Src->isFloatingPointTy() && Dst->isFloatingPointTy())
    return true;
  if (!Src->isVectorTy() || !Dst->isVectorTy())
    return false;
  return Src->getPrimitiveSizeInBits() == Dst->getPrimitiveSizeInBits();
}

static Type *SourceType(const CallbackSource &Source) {
  if (Source.Arg)
    return Source.Arg->getType();
  return Source.C ? Source.C->getType() : nullptr;
}

static Value *MaterializeSource(const CallbackSource &Source) {
  if (Source.Arg)
    return Source.Arg;
  return Source.C;
}

static bool IsStatePointerScaffold(Instruction &I, Value *State,
                                   const DataLayout &DL) {
  if (!isa<GetElementPtrInst>(I) && !isa<BitCastInst>(I) &&
      !isa<AddrSpaceCastInst>(I))
    return false;
  return PointerHasBase(&I, State, DL);
}

static CallInst *FindUniqueNativeCall(Function &Bridge,
                                      FunctionABISummary &S) {
  CallInst *Found = nullptr;
  for (BasicBlock &BB : Bridge) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI || ResolveCalledFunction(CI->getCalledOperand()) != S.NativeFn)
        continue;
      if (Found)
        return nullptr;
      Found = CI;
    }
  }
  return Found;
}

static bool ValueIsWrapperArg(Value *V, Argument *Arg) {
  SmallPtrSet<Value *, 8> Seen;
  while (V && Seen.insert(V).second) {
    if (V == Arg)
      return true;
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !IsPureCast(*I) || I->getNumOperands() != 1)
      return false;
    V = I->getOperand(0);
  }
  return false;
}

static bool IsWrapperRegisterLoad(Value *V, Value *State, ABIReg Reg,
                                  const DataLayout &DL) {
  SmallPtrSet<Value *, 8> Seen;
  while (V && Seen.insert(V).second) {
    if (auto *LI = dyn_cast<LoadInst>(V)) {
      auto AccessReg = IdentifyStateRegisterPointer(LI->getPointerOperand());
      return AccessReg && *AccessReg == Reg &&
             PointerHasBase(LI->getPointerOperand(), State, DL);
    }
    auto *I = dyn_cast<Instruction>(V);
    if (!I || !IsPureCast(*I) || I->getNumOperands() != 1)
      return false;
    V = I->getOperand(0);
  }
  return false;
}

static bool ValidateBridge(Function &Bridge, FunctionABISummary &S,
                           CallInst &NativeCall, const DataLayout &DL) {
  if (Bridge.isDeclaration() || Bridge.size() != 1 || Bridge.arg_size() != 3 ||
      !Bridge.getReturnType()->isPointerTy() || S.HiddenState)
    return false;

  unsigned NativeIndex = 0;
  if (S.HiddenPC) {
    if (NativeIndex >= NativeCall.arg_size() ||
        !ValueIsWrapperArg(NativeCall.getArgOperand(NativeIndex++),
                           Bridge.getArg(1)))
      return false;
  }
  if (S.HiddenMemory) {
    if (NativeIndex >= NativeCall.arg_size() ||
        !ValueIsWrapperArg(NativeCall.getArgOperand(NativeIndex++),
                           Bridge.getArg(2)))
      return false;
  }
  for (const ABIArgInfo &Arg : S.Args) {
    if (NativeIndex >= NativeCall.arg_size() ||
        !IsWrapperRegisterLoad(NativeCall.getArgOperand(NativeIndex++),
                               Bridge.getArg(0), Arg.Reg, DL))
      return false;
  }
  if (NativeIndex != NativeCall.arg_size())
    return false;

  auto *RI = dyn_cast<ReturnInst>(Bridge.getEntryBlock().getTerminator());
  if (!RI || !RI->getReturnValue() ||
      !ValueIsWrapperArg(RI->getReturnValue(), Bridge.getArg(2)))
    return false;

  for (Instruction &I : Bridge.getEntryBlock()) {
    if (&I == &NativeCall || isa<ReturnInst>(I) || IsPureCast(I) ||
        isa<GetElementPtrInst>(I))
      continue;
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      bool FeedsNativeCall = llvm::any_of(NativeCall.args(), [&](Use &Arg) {
        return IsDerivedThroughPureCasts(Arg.get(), LI);
      });
      if (LI->isSimple() &&
          PointerHasBase(LI->getPointerOperand(), Bridge.getArg(0), DL) &&
          (LI->use_empty() || FeedsNativeCall))
        continue;
    }
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      auto Reg = IdentifyStateRegisterPointer(SI->getPointerOperand());
      if (SI->isSimple() && Reg && *Reg == ABIReg::RAX &&
          PointerHasBase(SI->getPointerOperand(), Bridge.getArg(0), DL) &&
          SI->getValueOperand() == &NativeCall)
        continue;
    }
    return false;
  }
  return true;
}

// Commit only adapters whose complete State protocol is a single direct
// bridge: callback arguments enter known registers and RAX solely supplies
// the callback return. Any extra call, memory effect, or register is rejected.
static std::optional<CallbackRewritePlan>
BuildCallbackPlan(Function &Adapter, Function &Bridge,
                  FunctionABISummary &S, CallInst &BridgeCall,
                  CallInst &NativeCall, const DataLayout &DL) {
  if (Adapter.isDeclaration() || Adapter.size() != 1 ||
      !Adapter.hasAddressTaken() || BridgeCall.getParent() != &Adapter.front() ||
      BridgeCall.arg_size() != 3 || S.HiddenState ||
      S.RetKind == ReturnKind::Void || Adapter.getReturnType()->isVoidTy() ||
      !CanCoerce(S.RetTy, Adapter.getReturnType()) ||
      !BridgeCall.use_empty() || !ValidateBridge(Bridge, S, NativeCall, DL))
    return std::nullopt;

  Value *State = BridgeCall.getArgOperand(0);
  auto PCSource = FindCallbackSource(BridgeCall.getArgOperand(1), Adapter);
  auto MemorySource = FindCallbackSource(BridgeCall.getArgOperand(2), Adapter);
  if ((S.HiddenPC && !PCSource) || (S.HiddenMemory && !MemorySource))
    return std::nullopt;

  CallbackRewritePlan Plan;
  Plan.Adapter = &Adapter;
  Plan.Bridge = &Bridge;
  Plan.Target = &S;
  Plan.BridgeCall = &BridgeCall;
  Plan.NativeCall = &NativeCall;
  if (PCSource)
    Plan.PCSource = *PCSource;
  if (MemorySource)
    Plan.MemorySource = *MemorySource;

  bool SeenBridge = false;
  LoadInst *ReturnLoad = nullptr;
  for (Instruction &I : Adapter.getEntryBlock()) {
    if (&I == &BridgeCall) {
      SeenBridge = true;
      continue;
    }
    if (isa<ReturnInst>(I) || IsPureCast(I) ||
        IsStatePointerScaffold(I, State, DL))
      continue;
    if (auto *SI = dyn_cast<StoreInst>(&I)) {
      if (SeenBridge || !PointerHasBase(SI->getPointerOperand(), State, DL))
        return std::nullopt;
      auto Reg = IdentifyStateRegisterPointer(SI->getPointerOperand());
      auto Source = FindCallbackSource(SI->getValueOperand(), Adapter);
      if (!SI->isSimple() || !Reg || !IsArgumentRegister(*Reg) || !Source ||
          Plan.RegisterSources.count(*Reg))
        return std::nullopt;
      Plan.RegisterSources[*Reg] = *Source;
      continue;
    }
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      auto Reg = IdentifyStateRegisterPointer(LI->getPointerOperand());
      if (!SeenBridge || ReturnLoad || !LI->isSimple() || !Reg ||
          *Reg != ABIReg::RAX ||
          !PointerHasBase(LI->getPointerOperand(), State, DL))
        return std::nullopt;
      ReturnLoad = LI;
      continue;
    }
    return std::nullopt;
  }
  auto *RI = dyn_cast<ReturnInst>(Adapter.getEntryBlock().getTerminator());
  if (!SeenBridge || !ReturnLoad || !RI || !RI->getReturnValue() ||
      !IsDerivedThroughPureCasts(RI->getReturnValue(), ReturnLoad))
    return std::nullopt;

  if (S.HiddenPC && !CanCoerce(SourceType(Plan.PCSource),
                               S.NativeFn->getArg(0)->getType()))
    return std::nullopt;

  unsigned NativeIndex = S.HiddenPC ? 1 : 0;
  if (S.HiddenMemory) {
    if (!CanCoerce(SourceType(Plan.MemorySource),
                   S.NativeFn->getArg(NativeIndex)->getType()))
      return std::nullopt;
    ++NativeIndex;
  }
  for (const ABIArgInfo &Arg : S.Args) {
    auto It = Plan.RegisterSources.find(Arg.Reg);
    if (It == Plan.RegisterSources.end() ||
        !CanCoerce(SourceType(It->second),
                   S.NativeFn->getArg(NativeIndex++)->getType()))
      return std::nullopt;
  }
  if (Plan.RegisterSources.size() != S.Args.size())
    return std::nullopt;
  return Plan;
}

static bool ApplyCallbackPlan(CallbackRewritePlan &Plan) {
  Function &Adapter = *Plan.Adapter;
  FunctionABISummary &S = *Plan.Target;
  while (!Adapter.empty())
    Adapter.begin()->eraseFromParent();
  BasicBlock *Entry = BasicBlock::Create(Adapter.getContext(), "entry", &Adapter);
  IRBuilder<> B(Entry);
  SmallVector<Value *, 12> Args;
  if (S.HiddenPC) {
    Value *V = CoerceValue(B, MaterializeSource(Plan.PCSource),
                           S.NativeFn->getArg(Args.size())->getType(),
                           "callback.pc");
    if (!V)
      return false;
    Args.push_back(V);
  }
  if (S.HiddenMemory) {
    Value *V = CoerceValue(B, MaterializeSource(Plan.MemorySource),
                           S.NativeFn->getArg(Args.size())->getType(),
                           "callback.memory");
    if (!V)
      return false;
    Args.push_back(V);
  }
  for (const ABIArgInfo &Arg : S.Args) {
    Value *V = MaterializeSource(Plan.RegisterSources.at(Arg.Reg));
    V = CoerceValue(B, V, S.NativeFn->getArg(Args.size())->getType(),
                    "callback.arg");
    if (!V)
      return false;
    Args.push_back(V);
  }
  CallInst *Call = B.CreateCall(S.NativeFn, Args, "callback.native.call");
  Call->setCallingConv(S.NativeFn->getCallingConv());
  Value *Ret = CoerceValue(B, Call, Adapter.getReturnType(), "callback.ret");
  if (!Ret)
    return false;
  B.CreateRet(Ret);
  errs() << "[brighten-abi] callback boundary lowered: " << Adapter.getName()
         << " -> " << S.NativeFn->getName() << "\n";
  return true;
}

static bool LowerCallbackBoundaries(ABIRecoveryContext &Ctx) {
  SmallVector<CallbackRewritePlan, 8> Plans;
  for (FunctionABISummary *S : Ctx.Summaries) {
    if (!S->NativeFn || S->HiddenState)
      continue;
    for (Function &Bridge : Ctx.M) {
      if (Bridge.isDeclaration() || !LooksLikeRemillFunction(Bridge))
        continue;
      CallInst *NativeCall = FindUniqueNativeCall(Bridge, *S);
      if (!NativeCall)
        continue;
      SmallVector<CallInst *, 8> Calls;
      for (User *U : Bridge.users()) {
        auto *CI = dyn_cast<CallInst>(U);
        if (CI && ResolveCalledFunction(CI->getCalledOperand()) == &Bridge)
          Calls.push_back(CI);
      }
      for (CallInst *CI : Calls) {
        Function *Adapter = CI->getFunction();
        if (!Adapter)
          continue;
        auto Plan = BuildCallbackPlan(*Adapter, Bridge, *S, *CI, *NativeCall,
                                      Ctx.DL);
        if (Plan)
          Plans.push_back(std::move(*Plan));
      }
    }
  }

  bool Changed = false;
  SmallPtrSet<Function *, 8> Rewritten;
  SmallPtrSet<Function *, 8> DeadBridgeCandidates;
  for (CallbackRewritePlan &Plan : Plans) {
    if (!Rewritten.insert(Plan.Adapter).second)
      continue;
    if (ApplyCallbackPlan(Plan)) {
      DeadBridgeCandidates.insert(Plan.Bridge);
      Changed = true;
    }
  }
  for (Function *Bridge : DeadBridgeCandidates) {
    if (Bridge->hasLocalLinkage() && Bridge->use_empty()) {
      errs() << "[brighten-abi] erased dead callback State bridge: "
             << Bridge->getName() << "\n";
      Bridge->eraseFromParent();
      Changed = true;
    }
  }
  return Changed;
}

} // namespace

bool BrightenABIRecoveryPass::LowerCallbackAndSharedStateABI(
    ABIRecoveryContext &Ctx) {
  return LowerCallbackBoundaries(Ctx);
}

} // namespace brighten_abi
