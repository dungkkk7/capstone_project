#include "NativeStateSSA.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/PromoteMemToReg.h"
#include "llvm/Transforms/Utils/Cloning.h"

#include <algorithm>
#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <string>
#include <utility>
#include <vector>

using namespace llvm;

namespace brighten_native_cleanup {
namespace {

struct Slot {
  uint64_t Offset = 0;
  Type *Ty = nullptr;
};

struct Plan {
  Function *Old = nullptr;
  Function *New = nullptr;
  GlobalVariable *Proxy = nullptr;
  StructType *ResultTy = nullptr;
  unsigned HiddenArgs = 1;
  Type *OldReturnTy = nullptr;
  SmallVector<unsigned, 8> OldExplicitArgs;
  SmallVector<Slot, 32> Inputs;
  SmallVector<Slot, 32> Outputs;
  SmallVector<Slot, 32> Used;
  DenseMap<uint64_t, AllocaInst *> LocalSlots;
  DenseMap<uint64_t, Type *> SlotTypes;
  DenseMap<uint64_t, unsigned> ResultFields;
  bool HasStateUses = false;
};

static bool IsNative(Function &F) {
  return !F.isDeclaration() && F.getName().ends_with(".native") &&
         F.arg_size() > 0 && F.getArg(0)->getType()->isPointerTy();
}

static std::optional<uint64_t> StateOffset(Value *Ptr, Value *Base,
                                            const DataLayout &DL) {
  if (!Ptr || !Base)
    return std::nullopt;
  auto *GEP = dyn_cast<GEPOperator>(Ptr->stripPointerCasts());
  if (!GEP)
    return std::nullopt;
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *GEPBase = GEP->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (GEPBase != Base || Offset.isNegative())
    return std::nullopt;
  return Offset.getZExtValue();
}

static Type *MergeSlotType(Type *A, Type *B) {
  if (!A)
    return B;
  if (!B || A == B)
    return A;
  if (A->isIntegerTy() && B->isIntegerTy()) {
    unsigned Width = std::max(cast<IntegerType>(A)->getBitWidth(),
                              cast<IntegerType>(B)->getBitWidth());
    return IntegerType::get(A->getContext(), Width);
  }
  if (A->isPointerTy() && B->isPointerTy())
    return PointerType::getUnqual(A->getContext());
  return nullptr;
}

static void AddUsedSlot(Plan &P, uint64_t Offset, Type *Ty) {
  auto It = P.SlotTypes.find(Offset);
  if (It == P.SlotTypes.end()) {
    P.SlotTypes[Offset] = Ty;
    P.Used.push_back({Offset, Ty});
    return;
  }
  Type *Merged = MergeSlotType(It->second, Ty);
  if (!Merged)
    return;
  It->second = Merged;
  for (Slot &S : P.Used)
    if (S.Offset == Offset)
      S.Ty = Merged;
}

static void SortSlots(SmallVectorImpl<Slot> &Slots) {
  llvm::sort(Slots, [](const Slot &A, const Slot &B) {
    return A.Offset < B.Offset;
  });
  Slots.erase(std::unique(Slots.begin(), Slots.end(),
                          [](const Slot &A, const Slot &B) {
                            return A.Offset == B.Offset;
                          }),
              Slots.end());
}

static unsigned HiddenArgumentCount(Function &F) {
  if (F.arg_size() < 2)
    return 1;
  Argument *A1 = F.getArg(1);
  StringRef Name = A1->getName();
  if (Name == "memory" || Name == "pc")
    return 2;
  return 1;
}

static void CollectPlanUses(Plan &P, const DataLayout &DL) {
  Function &F = *P.Old;
  Value *State = F.getArg(0);
  P.HiddenArgs = HiddenArgumentCount(F);
  P.OldReturnTy = F.getReturnType();

  for (unsigned I = P.HiddenArgs; I < F.arg_size(); ++I)
    P.OldExplicitArgs.push_back(I);

  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      Value *Ptr = nullptr;
      Type *AccessTy = nullptr;
      bool IsLoad = false;
      bool IsStore = false;
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        Ptr = LI->getPointerOperand();
        AccessTy = LI->getType();
        IsLoad = true;
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        Ptr = SI->getPointerOperand();
        AccessTy = SI->getValueOperand()->getType();
        IsStore = true;
      }
      if (!Ptr)
        continue;
      auto Offset = StateOffset(Ptr, State, DL);
      if (!Offset)
        continue;
      P.HasStateUses = true;
      AddUsedSlot(P, *Offset, AccessTy);
      if (IsLoad)
        P.Inputs.push_back({*Offset, AccessTy});
      if (IsStore)
        P.Outputs.push_back({*Offset, AccessTy});
    }
  }
  SortSlots(P.Inputs);
  SortSlots(P.Outputs);
  SortSlots(P.Used);
  for (Slot &S : P.Inputs)
    S.Ty = P.SlotTypes.lookup(S.Offset);
  for (Slot &S : P.Outputs)
    S.Ty = P.SlotTypes.lookup(S.Offset);
  for (Slot &S : P.Used)
    S.Ty = P.SlotTypes.lookup(S.Offset);
}

static Plan *FindPlan(DenseMap<Function *, std::unique_ptr<Plan>> &Plans,
                      Function *F) {
  auto It = Plans.find(F);
  return It == Plans.end() ? nullptr : It->second.get();
}

static bool AddCallStateRequirements(DenseMap<Function *, std::unique_ptr<Plan>> &Plans) {
  bool Changed = false;
  for (auto &Entry : Plans) {
    Plan &Caller = *Entry.second;
    for (BasicBlock &BB : *Caller.Old) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        Plan *CalleePlan = FindPlan(Plans, Callee);
        if (!CalleePlan || CalleePlan == &Caller)
          continue;
        for (const Slot &S : CalleePlan->Used) {
          if (!Caller.SlotTypes.count(S.Offset)) {
            AddUsedSlot(Caller, S.Offset, S.Ty);
            Changed = true;
          }
        }
        for (const Slot &S : CalleePlan->Outputs) {
          auto Before = Caller.Outputs.size();
          Caller.Outputs.push_back(S);
          SortSlots(Caller.Outputs);
          Changed |= Caller.Outputs.size() != Before;
        }
      }
    }
  }
  return Changed;
}

static Value *Coerce(IRBuilder<> &B, Value *V, Type *Ty, const Twine &Name) {
  if (!V || !Ty)
    return nullptr;
  if (V->getType() == Ty)
    return V;
  if (V->getType()->isIntegerTy() && Ty->isIntegerTy()) {
    unsigned SW = cast<IntegerType>(V->getType())->getBitWidth();
    unsigned DW = cast<IntegerType>(Ty)->getBitWidth();
    if (SW > DW)
      return B.CreateTrunc(V, Ty, Name);
    return B.CreateZExt(V, Ty, Name);
  }
  if (V->getType()->isPointerTy() && Ty->isPointerTy())
    return B.CreateBitCast(V, Ty, Name);
  return nullptr;
}

static Value *BuildStateGEP(IRBuilder<> &B, Value *State, uint64_t Offset) {
  return B.CreateConstGEP1_64(B.getInt8Ty(), State, Offset,
                              "native.state.slot");
}

static FunctionType *BuildNewType(Plan &P, LLVMContext &Ctx) {
  SmallVector<Type *, 32> Args;
  // The guest RSP/RBP values are integer encodings of one shared native
  // stack anchor.  Carry that anchor explicitly through the native call
  // graph so address lowering can use GEPs instead of inttoptr.
  Args.push_back(PointerType::getUnqual(Ctx));
  for (const Slot &S : P.Used)
    Args.push_back(S.Ty);
  for (unsigned I : P.OldExplicitArgs)
    Args.push_back(P.Old->getArg(I)->getType());

  SmallVector<Type *, 32> Results;
  if (!P.OldReturnTy->isVoidTy())
    Results.push_back(P.OldReturnTy);
  for (const Slot &S : P.Outputs)
    Results.push_back(S.Ty);
  if (Results.empty())
    return FunctionType::get(Type::getVoidTy(Ctx), Args, false);
  if (Results.size() == 1)
    return FunctionType::get(Results.front(), Args, false);
  std::string ResultName = P.Old->getName().str();
  if (StringRef(ResultName).ends_with(".native"))
    ResultName.resize(ResultName.size() - 7);
  P.ResultTy = StructType::create(Ctx, Results, ResultName + ".state_result");
  return FunctionType::get(P.ResultTy, Args, false);
}

static void NameNewArgs(Plan &P) {
  unsigned I = 0;
  P.New->getArg(I++)->setName("native_stack");
  for (const Slot &S : P.Used)
    P.New->getArg(I++)->setName(("state_in_" + Twine(S.Offset)).str());
  for (unsigned OldIndex : P.OldExplicitArgs)
    P.New->getArg(I++)->setName(P.Old->getArg(OldIndex)->getName());
}

static bool ClonePlan(Plan &P, Module &M) {
  LLVMContext &Ctx = M.getContext();
  FunctionType *FT = BuildNewType(P, Ctx);
  P.New = Function::Create(FT, GlobalValue::InternalLinkage,
                           P.Old->getName() + ".state_ssa", M);
  P.New->setCallingConv(P.Old->getCallingConv());
  P.New->setDSOLocal(true);
  NameNewArgs(P);

  // A temporary module-local proxy lets CloneFunctionBodyInto remap the old
  // state argument without retaining it in the new function type.  All
  // accesses based on it are replaced by local SSA slots immediately after
  // cloning and the proxy is deleted at the end.
  P.Proxy = new GlobalVariable(M, Type::getInt8Ty(Ctx), false,
                               GlobalValue::InternalLinkage,
                               ConstantInt::get(Type::getInt8Ty(Ctx), 0),
                               "__native_state_proxy");

  ValueToValueMapTy VMap;
  VMap[P.Old->getArg(0)] = P.Proxy;
  if (P.HiddenArgs == 2) {
    Value *Hidden = P.Old->getArg(1);
    if (Hidden->getType()->isPointerTy())
      VMap[Hidden] = ConstantPointerNull::get(cast<PointerType>(Hidden->getType()));
    else if (Hidden->getType()->isIntegerTy())
      VMap[Hidden] = ConstantInt::get(Hidden->getType(), 0);
  }
  unsigned NewArg = 1 + P.Used.size();
  for (unsigned OldIndex : P.OldExplicitArgs)
    VMap[P.Old->getArg(OldIndex)] = P.New->getArg(NewArg++);

  SmallVector<ReturnInst *, 8> Returns;
  CloneFunctionBodyInto(*P.New, *P.Old, VMap, RF_None, Returns);
  if (P.New->empty())
    return false;

  BasicBlock &Entry = P.New->getEntryBlock();
  IRBuilder<> EB(&Entry, Entry.begin());
  for (const Slot &S : P.Used) {
    AllocaInst *A = EB.CreateAlloca(S.Ty, nullptr,
                                    ("native.slot." + Twine(S.Offset)).str());
    P.LocalSlots[S.Offset] = A;
  }
  NewArg = 1;
  for (const Slot &S : P.Used) {
    Value *V = P.New->getArg(NewArg++);
    EB.CreateStore(V, P.LocalSlots[S.Offset]);
  }

  SmallVector<Instruction *, 128> StateInstructions;
  for (BasicBlock &BB : *P.New) {
    for (Instruction &I : BB) {
      Value *Ptr = nullptr;
      if (auto *LI = dyn_cast<LoadInst>(&I))
        Ptr = LI->getPointerOperand();
      else if (auto *SI = dyn_cast<StoreInst>(&I))
        Ptr = SI->getPointerOperand();
      if (!Ptr)
        continue;
      auto Offset = StateOffset(Ptr, P.Proxy, M.getDataLayout());
      if (Offset)
        StateInstructions.push_back(&I);
    }
  }

  for (Instruction *I : StateInstructions) {
    auto Offset = [&]() -> std::optional<uint64_t> {
      if (auto *LI = dyn_cast<LoadInst>(I))
        return StateOffset(LI->getPointerOperand(), P.Proxy, M.getDataLayout());
      return StateOffset(cast<StoreInst>(I)->getPointerOperand(), P.Proxy,
                         M.getDataLayout());
    }();
    if (!Offset || !P.LocalSlots.count(*Offset))
      return false;
    AllocaInst *SlotPtr = P.LocalSlots[*Offset];
    if (auto *LI = dyn_cast<LoadInst>(I)) {
      Type *SlotTy = P.SlotTypes.lookup(*Offset);
      if (LI->getType() == SlotTy) {
        LI->setOperand(0, SlotPtr);
      } else {
        IRBuilder<> B(LI);
        Value *V = B.CreateLoad(SlotTy, SlotPtr, "native.slot.load");
        V = Coerce(B, V, LI->getType(), "native.slot.coerce");
        if (!V)
          return false;
        LI->replaceAllUsesWith(V);
        LI->eraseFromParent();
      }
    } else {
      auto *SI = cast<StoreInst>(I);
      Type *SlotTy = P.SlotTypes.lookup(*Offset);
      Value *V = SI->getValueOperand();
      if (V->getType() != SlotTy) {
        IRBuilder<> B(SI);
        V = Coerce(B, V, SlotTy, "native.slot.store");
        if (!V)
          return false;
        SI->setOperand(0, V);
      }
      SI->setOperand(1, SlotPtr);
    }
  }

  SmallVector<ReturnInst *, 16> NewReturns;
  for (BasicBlock &BB : *P.New)
    if (auto *RI = dyn_cast<ReturnInst>(BB.getTerminator()))
      NewReturns.push_back(RI);

  for (ReturnInst *RI : NewReturns) {
    IRBuilder<> B(RI);
    SmallVector<Value *, 32> Values;
    if (!P.OldReturnTy->isVoidTy())
      Values.push_back(RI->getReturnValue());
    for (const Slot &S : P.Outputs)
      Values.push_back(B.CreateLoad(S.Ty, P.LocalSlots[S.Offset],
                                    ("state_out." + Twine(S.Offset)).str()));
    if (Values.empty()) {
      if (!RI->getFunction()->getReturnType()->isVoidTy())
        return false;
      B.CreateRetVoid();
      RI->eraseFromParent();
      continue;
    }
    Value *Ret = Values.front();
    if (P.ResultTy) {
      Ret = Constant::getNullValue(P.ResultTy);
      for (unsigned I = 0; I < Values.size(); ++I)
        Ret = B.CreateInsertValue(Ret, Values[I], {I}, "state.result");
    }
    B.CreateRet(Ret);
    RI->eraseFromParent();
  }
  return true;
}

static Value *LoadStateSlot(IRBuilder<> &B, Plan &Caller, uint64_t Offset,
                            Type *Ty) {
  auto It = Caller.LocalSlots.find(Offset);
  if (It == Caller.LocalSlots.end())
    return nullptr;
  Value *V = B.CreateLoad(Caller.SlotTypes.lookup(Offset), It->second,
                          "state.call.in");
  return Coerce(B, V, Ty, "state.call.coerce");
}

static Value *ExtractOriginalResult(IRBuilder<> &B, Plan &Callee,
                                    CallInst *Call) {
  if (Callee.OldReturnTy->isVoidTy())
    return nullptr;
  if (!Callee.ResultTy)
    return Call;
  return B.CreateExtractValue(Call, {0}, "native.call.ret");
}

static bool RewriteNativeCalls(Plan &Caller,
                               DenseMap<Function *, std::unique_ptr<Plan>> &Plans) {
  SmallVector<CallInst *, 32> Calls;
  for (BasicBlock &BB : *Caller.New) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI)
        continue;
      if (Plan *Callee = FindPlan(Plans, CI->getCalledFunction()))
        Calls.push_back(CI);
    }
  }

  for (CallInst *OldCall : Calls) {
    Plan *Callee = FindPlan(Plans, OldCall->getCalledFunction());
    if (!Callee)
      continue;
    IRBuilder<> B(OldCall);
    SmallVector<Value *, 32> Args;
    Args.push_back(Caller.New->getArg(0));
    for (const Slot &S : Callee->Used) {
      Value *V = LoadStateSlot(B, Caller, S.Offset, S.Ty);
      if (!V)
        return false;
      Args.push_back(V);
    }
    unsigned ExplicitStart = Callee->HiddenArgs;
    if (OldCall->arg_size() < ExplicitStart)
      return false;
    for (unsigned I = ExplicitStart; I < OldCall->arg_size(); ++I)
      Args.push_back(OldCall->getArgOperand(I));

    CallInst *NewCall = B.CreateCall(Callee->New, Args, "native.call");
    NewCall->setCallingConv(Callee->New->getCallingConv());
    Value *OriginalRet = ExtractOriginalResult(B, *Callee, NewCall);
    unsigned Field = Callee->OldReturnTy->isVoidTy() ? 0 : 1;
    for (const Slot &S : Callee->Outputs) {
      Value *V = nullptr;
      if (Callee->ResultTy)
        V = B.CreateExtractValue(NewCall, {Field},
                                 ("state.call.out." + Twine(S.Offset)).str());
      else
        V = NewCall;
      ++Field;
      V = Coerce(B, V, Caller.SlotTypes.lookup(S.Offset),
                 "state.call.out.coerce");
      if (!V)
        return false;
      B.CreateStore(V, Caller.LocalSlots[S.Offset]);
    }
    if (!OldCall->getType()->isVoidTy()) {
      if (!OriginalRet)
        return false;
      OldCall->replaceAllUsesWith(OriginalRet);
    }
    OldCall->eraseFromParent();
  }
  return true;
}

static bool RewriteExternalNativeCalls(
    Module &M, DenseMap<Function *, std::unique_ptr<Plan>> &Plans) {
  SmallVector<CallInst *, 32> Calls;
  for (Function &F : M) {
    if (Plans.count(&F))
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (CI && Plans.count(CI->getCalledFunction()))
          Calls.push_back(CI);
      }
    }
  }

  for (CallInst *OldCall : Calls) {
    Plan *Callee = FindPlan(Plans, OldCall->getCalledFunction());
    if (!Callee || OldCall->arg_size() < Callee->HiddenArgs)
      return false;
    Value *State = OldCall->getArgOperand(0);
    IRBuilder<> B(OldCall);
    SmallVector<Value *, 32> Args;
    Value *NativeStack = nullptr;
    Function *Caller = OldCall->getFunction();
    for (Argument &A : Caller->args()) {
      if (A.getName() == "native_stack") {
        NativeStack = &A;
        break;
      }
    }
    if (!NativeStack && Caller->getName() == "main") {
      // Before the cleanup pass replaces the oversized allocation, the
      // entrypoint already contains the pointer that represents the initial
      // guest RSP.  Reuse that exact pointer as the native stack anchor.
      for (Instruction &I : Caller->getEntryBlock()) {
        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
          if (GEP->getName().starts_with("native_stack_top")) {
            NativeStack = GEP;
            break;
          }
        }
      }
    }
    if (!NativeStack)
      NativeStack = ConstantPointerNull::get(
          PointerType::getUnqual(M.getContext()));
    Args.push_back(NativeStack);
    for (const Slot &S : Callee->Used) {
      Value *Ptr = BuildStateGEP(B, State, S.Offset);
      Value *V = B.CreateLoad(S.Ty, Ptr, "entry.state.in");
      Args.push_back(V);
    }
    for (unsigned I = Callee->HiddenArgs; I < OldCall->arg_size(); ++I)
      Args.push_back(OldCall->getArgOperand(I));
    CallInst *NewCall = B.CreateCall(Callee->New, Args, "native.entry.call");
    NewCall->setCallingConv(Callee->New->getCallingConv());
    Value *OriginalRet = ExtractOriginalResult(B, *Callee, NewCall);
    unsigned Field = Callee->OldReturnTy->isVoidTy() ? 0 : 1;
    for (const Slot &S : Callee->Outputs) {
      Value *V = Callee->ResultTy
                     ? B.CreateExtractValue(NewCall, {Field++}, "entry.state.out")
                     : NewCall;
      B.CreateStore(V, BuildStateGEP(B, State, S.Offset));
    }
    if (!OldCall->getType()->isVoidTy())
      OldCall->replaceAllUsesWith(OriginalRet);
    OldCall->eraseFromParent();
  }
  return true;
}

static void PromoteNativeSlotAllocas(Plan &P) {
  SmallVector<AllocaInst *, 32> Allocas;
  for (auto &Entry : P.LocalSlots)
    if (Entry.second->getParent())
      Allocas.push_back(Entry.second);
  if (Allocas.empty())
    return;
  DominatorTree DT(*P.New);
  PromoteMemToReg(Allocas, DT, nullptr);
}

static bool CleanupProxy(Plan &P) {
  for (unsigned Iter = 0; Iter < 8; ++Iter) {
    SmallVector<Instruction *, 32> Dead;
    for (BasicBlock &BB : *P.New) {
      for (Instruction &I : BB) {
        bool UsesProxy = false;
        for (Value *Op : I.operands())
          UsesProxy |= Op == P.Proxy;
        if (UsesProxy) {
          if (I.isTerminator() || !I.use_empty())
            return false;
          Dead.push_back(&I);
        }
      }
    }
    if (Dead.empty()) {
      // Cloning can leave the proxy in constant expressions used by dead
      // instructions.  Drop those constant users before the final check.
      P.Proxy->removeDeadConstantUsers();
      return P.Proxy->use_empty();
    }
    for (Instruction *I : Dead)
      I->eraseFromParent();
  }
  return P.Proxy->use_empty();
}

static bool CanRemoveOldFunctions(
    Module &M, DenseMap<Function *, std::unique_ptr<Plan>> &Plans) {
  for (auto &Entry : Plans) {
    Function *Old = Entry.first;
    for (User *U : Old->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I || !Plans.count(I->getFunction()))
        return false;
    }
  }
  return true;
}

static AllocaInst *FindMainStateBuffer(Function &Main) {
  for (Instruction &I : Main.getEntryBlock()) {
    auto *AI = dyn_cast<AllocaInst>(&I);
    if (!AI || !AI->getName().starts_with("native_state"))
      continue;
    auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
    if (AT && AT->getElementType()->isIntegerTy(8))
      return AI;
  }
  return nullptr;
}

static bool lowerNativeMainStateBufferImpl(Module &M) {
  Function *Main = M.getFunction("main");
  if (!Main || Main->empty())
    return false;
  AllocaInst *State = FindMainStateBuffer(*Main);
  if (!State)
    return false;

  const DataLayout &DL = M.getDataLayout();
  DenseMap<uint64_t, Value *> Current;
  SmallVector<Instruction *, 64> Erase;
  bool ZeroInitialized = false;

  // The generated entrypoint is intentionally straight-line.  Promote only
  // when every state load has a dominating byte-range value; this keeps the
  // transformation conservative for a future CFG-shaped wrapper.
  for (BasicBlock &BB : *Main) {
    for (Instruction &I : BB) {
      if (auto *MS = dyn_cast<MemSetInst>(&I)) {
        Value *Dest = MS->getDest()->stripPointerCasts();
        auto *Fill = dyn_cast<ConstantInt>(MS->getValue());
        if (Dest == State && Fill && Fill->isZero()) {
          ZeroInitialized = true;
          Erase.push_back(&I);
        }
        continue;
      }

      if (auto *SI = dyn_cast<StoreInst>(&I)) {
        auto Offset = StateOffset(SI->getPointerOperand(), State, DL);
        if (!Offset)
          continue;
        Current[*Offset] = SI->getValueOperand();
        Erase.push_back(SI);
        continue;
      }

      auto *LI = dyn_cast<LoadInst>(&I);
      if (!LI)
        continue;
      auto Offset = StateOffset(LI->getPointerOperand(), State, DL);
      if (!Offset)
        continue;
      Value *V = Current.lookup(*Offset);
      if (!V && ZeroInitialized)
        V = Constant::getNullValue(LI->getType());
      if (!V || V->getType() != LI->getType())
        return false;
      LI->replaceAllUsesWith(V);
      Erase.push_back(LI);
    }
  }

  if (Erase.empty() || !ZeroInitialized)
    return false;
  for (Instruction *I : llvm::reverse(Erase))
    if (I->getParent())
      I->eraseFromParent();

  for (unsigned Iter = 0; Iter < 8 && !State->use_empty(); ++Iter) {
    SmallVector<Instruction *, 64> Dead;
    for (BasicBlock &BB : *Main)
      for (Instruction &I : BB)
        if (I.use_empty() && isa<GetElementPtrInst>(&I) &&
            StateOffset(&I, State, DL))
          Dead.push_back(&I);
    if (Dead.empty())
      break;
    for (Instruction *I : Dead)
      I->eraseFromParent();
  }

  if (!State->use_empty())
    return false;
  State->eraseFromParent();
  return true;
}

static bool lowerNativeMainStackBufferImpl(Module &M) {
  Function *Main = M.getFunction("main");
  if (!Main || Main->empty())
    return false;

  AllocaInst *OldStack = nullptr;
  for (Instruction &I : Main->getEntryBlock()) {
    auto *AI = dyn_cast<AllocaInst>(&I);
    if (!AI || !AI->getName().starts_with("native_stack"))
      continue;
    auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
    if (AT && AT->getElementType()->isIntegerTy(8) &&
        AT->getNumElements() >= 1024 * 1024) {
      OldStack = AI;
      break;
    }
  }
  if (!OldStack)
    return false;

  // The recovered code only uses the old allocation as a temporary frame
  // backing store.  Give it a bounded native stack area with a guard on both
  // sides; the guest RSP/RBP values remain ordinary integer data until the
  // address lowering pass turns accesses into native GEPs.
  constexpr uint64_t NativeStackBytes = 64 * 1024;
  constexpr uint64_t NativeStackTop = NativeStackBytes - 256;
  IRBuilder<> B(OldStack);
  AllocaInst *NewStack = B.CreateAlloca(
      B.getInt8Ty(), B.getInt64(NativeStackBytes), "native_stack_storage");
  NewStack->setAlignment(Align(16));

  SmallVector<Instruction *, 4> StackUsers;
  for (User *U : OldStack->users()) {
    auto *GEP = dyn_cast<GetElementPtrInst>(U);
    if (!GEP)
      return false;
    StackUsers.push_back(GEP);
  }
  for (Instruction *I : StackUsers) {
    auto *GEP = cast<GetElementPtrInst>(I);
    IRBuilder<> GB(GEP);
    Value *Top = GB.CreateConstGEP1_64(B.getInt8Ty(), NewStack,
                                       NativeStackTop, "native_stack_top");
    GEP->replaceAllUsesWith(Top);
    GEP->eraseFromParent();
  }
  if (!OldStack->use_empty())
    return false;
  OldStack->eraseFromParent();
  return true;
}

struct StackAffine {
  Value *Root = nullptr;
  int64_t Offset = 0;
};

static std::optional<StackAffine>
GetStackAffine(Value *V, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return std::nullopt;
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || (BO->getOpcode() != Instruction::Add &&
              BO->getOpcode() != Instruction::Sub)) {
    StringRef Name = V->getName();
    if (Name.contains("2312") || Name.contains("2328") ||
        Name.contains("new_rsp") || Name.contains("new_rbp"))
      return StackAffine{V, 0};
    return std::nullopt;
  }
  Value *Base = nullptr;
  int64_t Delta = 0;
  if (auto *C = dyn_cast<ConstantInt>(BO->getOperand(1))) {
    if (!C->getValue().isSignedIntN(64))
      return std::nullopt;
    Base = BO->getOperand(0);
    Delta = C->getSExtValue();
    if (BO->getOpcode() == Instruction::Sub)
      Delta = -Delta;
  } else if (BO->getOpcode() == Instruction::Add) {
    auto *C = dyn_cast<ConstantInt>(BO->getOperand(0));
    if (!C || !C->getValue().isSignedIntN(64))
      return std::nullopt;
    Base = BO->getOperand(1);
    Delta = C->getSExtValue();
  } else {
    return std::nullopt;
  }
  auto Parent = GetStackAffine(Base, Seen);
  if (!Parent)
    return std::nullopt;
  if ((Delta > 0 && Parent->Offset > INT64_MAX - Delta) ||
      (Delta < 0 && Parent->Offset < INT64_MIN - Delta))
    return std::nullopt;
  Parent->Offset += Delta;
  return Parent;
}

static bool lowerNativeStackAddressesImpl(Module &M) {
  unsigned Lowered = 0;
  for (Function &F : M) {
    DenseMap<Value *, Value *> BasePointers;
    Value *NativeStack = nullptr;
    for (Argument &A : F.args()) {
      if (A.getName() == "native_stack") {
        NativeStack = &A;
        break;
      }
    }
    auto GetBasePointer = [&](Value *BaseInteger, Instruction *InsertBefore) {
      auto It = BasePointers.find(BaseInteger);
      if (It != BasePointers.end())
        return It->second;
      if (NativeStack) {
        BasePointers[BaseInteger] = NativeStack;
        return NativeStack;
      }
      Instruction *Point = InsertBefore;
      if (auto *BaseInst = dyn_cast<Instruction>(BaseInteger)) {
        Point = BaseInst->getNextNode();
        if (isa<PHINode>(BaseInst))
          Point = &*BaseInst->getParent()->getFirstInsertionPt();
      } else if (isa<Argument>(BaseInteger)) {
        Point = &*F.getEntryBlock().getFirstInsertionPt();
      }
      IRBuilder<> B(Point);
      Value *Base = B.CreateIntToPtr(
          BaseInteger, PointerType::getUnqual(B.getContext()),
                                     "native.stack.base");
      BasePointers[BaseInteger] = Base;
      return Base;
    };
    SmallVector<IntToPtrInst *, 256> Candidates;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I))
          Candidates.push_back(ITP);

    for (IntToPtrInst *ITP : Candidates) {
      Value *Integer = ITP->getOperand(0);
      SmallPtrSet<Value *, 32> Seen;
      auto Affine = GetStackAffine(Integer, Seen);
      if (!Affine)
        continue;
      IRBuilder<> B(ITP);
      Value *Address = nullptr;
      if (NativeStack) {
        // The integer root is an absolute native address encoded in the
        // lifted register file.  Rebase it against the explicit native stack
        // anchor before applying the affine frame offset.  This preserves
        // values produced by PHIs/calls instead of treating every root as
        // the initial RSP.
        Value *AnchorInt = B.CreatePtrToInt(NativeStack, B.getInt64Ty(),
                                            "native.stack.anchor");
        Value *Delta = B.CreateSub(Affine->Root, AnchorInt,
                                   "native.stack.delta");
        if (Affine->Offset != 0)
          Delta = B.CreateAdd(Delta, B.getInt64(Affine->Offset),
                              "native.stack.offset");
        Address = B.CreateGEP(B.getInt8Ty(), NativeStack, Delta,
                              "native.stack.gep");
      } else {
        Value *Base = GetBasePointer(Affine->Root, ITP);
        Address = Base;
        if (Affine->Offset != 0)
          Address = B.CreateGEP(B.getInt8Ty(), Base,
                                B.getInt64(Affine->Offset),
                                "native.stack.gep");
      }
      ITP->replaceAllUsesWith(Address);
      ITP->eraseFromParent();
      ++Lowered;
    }
  }
  if (Lowered)
    errs() << "  native stack integer addresses lowered: " << Lowered
           << "\n";
  return Lowered != 0;
}

} // namespace

bool lowerNativeMainStateBuffer(Module &M) {
  return lowerNativeMainStateBufferImpl(M);
}

bool lowerNativeMainStackBuffer(Module &M) {
  return lowerNativeMainStackBufferImpl(M);
}

bool lowerNativeStackAddresses(Module &M) {
  return lowerNativeStackAddressesImpl(M);
}

bool cleanupNativeDeadInstructions(Module &M) {
  bool Changed = false;
  for (unsigned Iter = 0; Iter < 16; ++Iter) {
    SmallVector<Instruction *, 256> Dead;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (I.use_empty())
            Dead.push_back(&I);
    }
    if (Dead.empty())
      break;
    bool RoundChanged = false;
    for (Instruction *I : Dead)
      if (I->getParent() && I->use_empty())
        RoundChanged |= RecursivelyDeleteTriviallyDeadInstructions(I);
    Changed |= RoundChanged;
    if (!RoundChanged)
      break;
  }
  return Changed;
}

bool lowerNativeStateABI(Module &M) {
  DenseMap<Function *, std::unique_ptr<Plan>> Plans;
  for (Function &F : M) {
    if (!IsNative(F))
      continue;
    auto P = std::make_unique<Plan>();
    P->Old = &F;
    CollectPlanUses(*P, M.getDataLayout());
    if (!P->HasStateUses)
      continue;
    Plans[&F] = std::move(P);
  }
  if (Plans.empty())
    return false;

  // Propagate callee state requirements until every caller can carry all
  // values needed by a transformed direct call.
  for (unsigned Iter = 0; Iter < Plans.size() + 2; ++Iter)
    if (!AddCallStateRequirements(Plans))
      break;

  for (auto &Entry : Plans)
    if (!ClonePlan(*Entry.second, M)) {
      errs() << "brighten-native-state-ssa: clone failed for "
             << Entry.first->getName() << "\n";
      return false;
    }

  for (auto &Entry : Plans)
    if (!RewriteNativeCalls(*Entry.second, Plans)) {
      errs() << "brighten-native-state-ssa: internal call rewrite failed for "
             << Entry.first->getName() << "\n";
      return false;
    }
  if (!RewriteExternalNativeCalls(M, Plans)) {
    errs() << "brighten-native-state-ssa: external call rewrite failed\n";
    return false;
  }
  for (auto &Entry : Plans)
    PromoteNativeSlotAllocas(*Entry.second);
  for (auto &Entry : Plans)
    if (!CleanupProxy(*Entry.second)) {
      errs() << "brighten-native-state-ssa: proxy cleanup failed for "
             << Entry.first->getName() << " (uses="
             << Entry.second->Proxy->getNumUses() << ")\n";
      return false;
    }
  if (!CanRemoveOldFunctions(M, Plans)) {
    for (auto &Entry : Plans) {
      Function *F = Entry.first;
      if (F->use_empty())
        continue;
      errs() << "brighten-native-state-ssa: old function still has uses: "
             << F->getName() << "\n";
      for (User *U : F->users())
        errs() << "  user: " << *U << "\n";
    }
    return false;
  }

  for (auto &Entry : Plans) {
    Function *Old = Entry.first;
    Function *New = Entry.second->New;
    // Keep the name alive across eraseFromParent().  StringRef would point
    // into the Function's uniqued name storage, which is released on erase.
    std::string OldName = Old->getName().str();
    std::string CanonicalName = OldName;
    if (StringRef(CanonicalName).ends_with(".native"))
      CanonicalName.resize(CanonicalName.size() - 7);
    // Old lifted functions may still call one another.  All such users are
    // inside the dead old-function set and can be dropped as a group after
    // external callsites have been rewritten.
    Old->dropAllReferences();
    Old->eraseFromParent();
    New->setName(CanonicalName);
    Entry.second->Proxy->removeDeadConstantUsers();
    if (Entry.second->Proxy->use_empty())
      Entry.second->Proxy->eraseFromParent();
  }
  // Remove any now-unused proxy globals that survived per-plan cleanup.
  SmallVector<GlobalVariable *, 8> DeadProxies;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.getName().starts_with("__native_state_proxy")) {
      GV.removeDeadConstantUsers();
      if (GV.use_empty())
        DeadProxies.push_back(&GV);
    }
  }
  for (GlobalVariable *GV : DeadProxies)
    GV->eraseFromParent();
  return true;
}

} // namespace brighten_native_cleanup
