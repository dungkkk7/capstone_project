#include "BrightenDevirtPass.h"

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>

namespace brighten_devirt {

using namespace llvm;

static constexpr unsigned kMaxFiniteTargets = 32;

static bool CollectFinitePCs(Value *V, const DataLayout &DL,
                             SmallVectorImpl<uint64_t> &PCs,
                             DenseSet<Value *> &Visited,
                             unsigned Depth = 0) {
  if (!V || Depth > 8 || !Visited.insert(V).second) {
    return false;
  }

  if (auto PC = ExtractConstantPC(V, DL)) {
    PCs.push_back(*PC);
    return PCs.size() <= kMaxFiniteTargets;
  }

  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    return CollectFinitePCs(Sel->getTrueValue(), DL, PCs, Visited, Depth + 1) &&
           CollectFinitePCs(Sel->getFalseValue(), DL, PCs, Visited, Depth + 1);
  }

  if (auto *PN = dyn_cast<PHINode>(V)) {
    for (Value *Incoming : PN->incoming_values()) {
      if (!CollectFinitePCs(Incoming, DL, PCs, Visited, Depth + 1)) {
        return false;
      }
    }
    return true;
  }

  return false;
}

static void SortUnique(SmallVectorImpl<uint64_t> &PCs) {
  llvm::sort(PCs);
  PCs.erase(std::unique(PCs.begin(), PCs.end()), PCs.end());
}

static Value *CoerceArg(IRBuilder<> &B, Value *V, Type *Ty) {
  if (V->getType() == Ty) {
    return V;
  }
  if (V->getType()->isIntegerTy() && Ty->isIntegerTy()) {
    unsigned FromBits = V->getType()->getIntegerBitWidth();
    unsigned ToBits = Ty->getIntegerBitWidth();
    if (FromBits < ToBits) {
      return B.CreateZExt(V, Ty);
    }
    if (FromBits > ToBits) {
      return B.CreateTrunc(V, Ty);
    }
  }
  if (V->getType()->isPointerTy() && Ty->isPointerTy()) {
    return B.CreateBitCast(V, Ty);
  }
  return V;
}

static bool CanCallWithOldArgs(CallInst *Old, Function *Target) {
  FunctionType *FTy = Target->getFunctionType();
  if (FTy->getNumParams() > Old->arg_size()) {
    return false;
  }
  return Old->use_empty() || FTy->getReturnType() == Old->getType();
}

static CallInst *CreateCallWithOldArgs(IRBuilder<> &B, CallInst *Old,
                                       Function *Target, Value *ResolvedPC) {
  FunctionType *FTy = Target->getFunctionType();
  SmallVector<Value *, 4> Args;
  for (unsigned I = 0, E = FTy->getNumParams(); I < E; ++I) {
    Value *Arg = (I == 1 && ResolvedPC) ? ResolvedPC : Old->getArgOperand(I);
    Args.push_back(CoerceArg(B, Arg, FTy->getParamType(I)));
  }

  CallInst *NewCall = B.CreateCall(FTy, Target, Args);
  NewCall->setCallingConv(Target->getCallingConv());
  return NewCall;
}

bool LowerFiniteRemillPCSwitch(Module &M, CallInst *CI, Function *Dispatcher,
                               bool IsJump) {
  if (!Dispatcher || !CI || CI->arg_size() < 3) {
    return false;
  }

  Value *PCVal = CI->getArgOperand(1);
  if (!PCVal->getType()->isIntegerTy()) {
    return false;
  }

  const DataLayout &DL = M.getDataLayout();
  SmallVector<uint64_t, 8> PCs;
  DenseSet<Value *> Visited;
  if (!CollectFinitePCs(PCVal, DL, PCs, Visited)) {
    return false;
  }
  SortUnique(PCs);
  if (PCs.empty() || PCs.size() > kMaxFiniteTargets) {
    return false;
  }

  SmallVector<std::pair<uint64_t, Function *>, 8> Resolved;
  unsigned FallbackCases = 0;
  for (uint64_t PC : PCs) {
    Function *Target = FindLiftedSubroutineByPC(M, PC);
    if (!Target) {
      ++FallbackCases;
      continue;
    }
    if (!CanCallWithOldArgs(CI, Target)) {
      errs() << "[devirt] ERROR: finite "
             << (IsJump ? "jump" : "call")
             << " switch target type mismatch PC 0x" << Twine::utohexstr(PC)
             << " -> @" << Target->getName() << "\n";
      return false;
    }
    Resolved.push_back({PC, Target});
  }

  if (Resolved.empty() || !CanCallWithOldArgs(CI, Dispatcher)) {
    return false;
  }

  Function *Parent = CI->getFunction();
  BasicBlock *SwitchBB = CI->getParent();
  BasicBlock *ContBB =
      SwitchBB->splitBasicBlock(CI->getIterator(), "devirt.finite.cont");

  SwitchBB->getTerminator()->eraseFromParent();

  LLVMContext &Ctx = M.getContext();
  BasicBlock *DefaultBB =
      BasicBlock::Create(Ctx, "devirt.finite.default", Parent, ContBB);

  SmallVector<std::pair<uint64_t, CallInst *>, 8> IncomingCalls;
  CallInst *Fallback = nullptr;
  IRBuilder<> DefaultBuilder(DefaultBB);
  if (FallbackCases == 0) {
    DefaultBuilder.CreateUnreachable();
  } else {
    Fallback = CreateCallWithOldArgs(DefaultBuilder, CI, Dispatcher, nullptr);
    DefaultBuilder.CreateBr(ContBB);
  }

  IRBuilder<> SwitchBuilder(SwitchBB);
  auto *SW = SwitchBuilder.CreateSwitch(PCVal, DefaultBB, Resolved.size());

  for (auto [PC, Target] : Resolved) {
    BasicBlock *CaseBB =
        BasicBlock::Create(Ctx, "devirt.finite.case", Parent, ContBB);
    IRBuilder<> CaseBuilder(CaseBB);
    Value *ResolvedPC = ConstantInt::get(PCVal->getType(), PC);
    CallInst *TargetCall =
        CreateCallWithOldArgs(CaseBuilder, CI, Target, ResolvedPC);
    CaseBuilder.CreateBr(ContBB);
    SW->addCase(cast<ConstantInt>(ResolvedPC), CaseBB);
    IncomingCalls.push_back({PC, TargetCall});
  }

  if (!CI->use_empty()) {
    IRBuilder<> PhiBuilder(CI);
    PHINode *Phi = PhiBuilder.CreatePHI(
        CI->getType(), IncomingCalls.size() + (Fallback ? 1 : 0),
        CI->hasName() ? CI->getName() + ".finite" : "finite");
    if (Fallback) {
      Phi->addIncoming(Fallback, DefaultBB);
    }
    for (auto [PC, TargetCall] : IncomingCalls) {
      Phi->addIncoming(TargetCall, TargetCall->getParent());
    }
    CI->replaceAllUsesWith(Phi);
  }

  CI->eraseFromParent();

  errs() << "[devirt] lowered finite remill " << (IsJump ? "jump" : "call")
         << " switch: " << Resolved.size() << " direct case(s)";
  if (FallbackCases) {
    errs() << ", " << FallbackCases << " unresolved case(s) use dispatcher";
  }
  errs() << "\n";

  return true;
}

} // namespace brighten_devirt
