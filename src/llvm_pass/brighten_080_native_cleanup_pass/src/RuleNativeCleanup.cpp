#include "BrightenNativeCleanupPass.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Analysis/ConstantFolding.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/Transforms/Utils/Local.h"
#include <optional>

namespace brighten_native_cleanup {

using namespace llvm;

namespace {

static bool stripOptimizationBlockers(Function &F) {
  bool Changed = false;
  if (F.hasFnAttribute(Attribute::OptimizeNone)) {
    F.removeFnAttr(Attribute::OptimizeNone);
    Changed = true;
  }
  if (F.hasFnAttribute(Attribute::NoInline)) {
    F.removeFnAttr(Attribute::NoInline);
    Changed = true;
  }
  return Changed;
}

static std::optional<uint64_t> parseLiftedPC(StringRef Name) {
  if (!Name.starts_with("sub_") || Name.ends_with("_native")) {
    return std::nullopt;
  }

  StringRef Hex = Name.drop_front(4);
  size_t Underscore = Hex.find('_');
  if (Underscore != StringRef::npos) {
    Hex = Hex.substr(0, Underscore);
  }

  uint64_t PC = 0;
  if (!Hex.getAsInteger(16, PC)) {
    return PC;
  }
  return std::nullopt;
}

static std::optional<uint64_t> resolveDispatchTargetPC(Value *V,
                                                       const DataLayout &DL) {
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    return CI->getZExtValue();
  }

  auto *LI = dyn_cast<LoadInst>(V);
  if (!LI) {
    return std::nullopt;
  }

  auto *PtrC = dyn_cast<Constant>(LI->getPointerOperand());
  if (!PtrC) {
    return std::nullopt;
  }

  Constant *Folded = ConstantFoldLoadFromConstPtr(PtrC, LI->getType(), DL);
  if (auto *Target = dyn_cast_or_null<ConstantInt>(Folded)) {
    return Target->getZExtValue();
  }

  APInt Offset(64, 0, true);
  Value *Base = LI->getPointerOperand();
  while (true) {
    if (auto *GEP = dyn_cast<GEPOperator>(Base)) {
      if (!GEP->accumulateConstantOffset(DL, Offset)) {
        return std::nullopt;
      }
      Base = GEP->getPointerOperand();
      continue;
    }
    if (auto *BC = dyn_cast<BitCastOperator>(Base)) {
      Base = BC->getOperand(0);
      continue;
    }
    break;
  }

  auto *GV = dyn_cast<GlobalVariable>(Base->stripPointerCasts());
  if (!GV || !GV->hasInitializer() || Offset.isNegative()) {
    return std::nullopt;
  }

  Folded = ConstantFoldLoadFromConst(GV->getInitializer(), LI->getType(),
                                     Offset, DL);
  auto *Target = dyn_cast_or_null<ConstantInt>(Folded);
  if (!Target) {
    return std::nullopt;
  }

  return Target->getZExtValue();
}

static CallInst *findHelperCaseCall(Function *Helper, uint64_t TargetPC) {
  CallInst *MatchedCall = nullptr;
  for (BasicBlock &BB : *Helper) {
    for (Instruction &I : BB) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI || CI->getCalledFunction() == Helper) {
        continue;
      }

      Function *Target = CI->getCalledFunction();
      if (!Target) {
        continue;
      }

      std::optional<uint64_t> CalledPC = parseLiftedPC(Target->getName());
      if (!CalledPC || *CalledPC != TargetPC) {
        continue;
      }

      if (MatchedCall && MatchedCall != CI) {
        return nullptr;
      }
      MatchedCall = CI;
    }
  }

  if (MatchedCall) {
    return MatchedCall;
  }

  for (BasicBlock &BB : *Helper) {
    auto *SI = dyn_cast<SwitchInst>(BB.getTerminator());
    if (!SI) {
      continue;
    }

    for (const auto &Case : SI->cases()) {
      if (Case.getCaseValue()->getZExtValue() != TargetPC) {
        continue;
      }

      BasicBlock *CaseBB = Case.getCaseSuccessor();
      for (Instruction &I : *CaseBB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (CI && CI->getCalledFunction() != Helper) {
          return CI;
        }
      }
    }
  }

  return nullptr;
}

static Value *remapHelperOperand(Value *V, CallInst *Dispatch) {
  if (auto *Arg = dyn_cast<Argument>(V)) {
    if (Arg->getArgNo() < Dispatch->arg_size()) {
      return Dispatch->getArgOperand(Arg->getArgNo());
    }
    return nullptr;
  }
  if (isa<Constant>(V)) {
    return V;
  }
  return nullptr;
}

static bool rewriteStaticRemillDispatch(Module &M) {
  bool Changed = false;
  DenseMap<uint64_t, Function *> LiftedByPC;
  const DataLayout &DL = M.getDataLayout();

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    std::optional<uint64_t> PC = parseLiftedPC(F.getName());
    if (PC) {
      LiftedByPC[*PC] = &F;
    }
  }

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    SmallVector<CallInst *, 8> DispatchCalls;
    for (Instruction &I : instructions(F)) {
      auto *CI = dyn_cast<CallInst>(&I);
      if (!CI || CI->arg_size() < 3) {
        continue;
      }

      Function *Callee = CI->getCalledFunction();
      if (!Callee) {
        continue;
      }

      if (Callee->getName() == "__remill_function_call" ||
          Callee->getName() == "__remill_jump") {
        DispatchCalls.push_back(CI);
      }
    }

    for (CallInst *CI : DispatchCalls) {
      std::optional<uint64_t> TargetPC = resolveDispatchTargetPC(
          CI->getArgOperand(1), DL);
      if (!TargetPC) {
        continue;
      }

      Function *Helper = CI->getCalledFunction();
      if (Helper && !Helper->isDeclaration()) {
        if (CallInst *HelperCaseCall = findHelperCaseCall(Helper, *TargetPC)) {
          Function *Target = HelperCaseCall->getCalledFunction();
          if (Target && HelperCaseCall->getType() == CI->getType()) {
            SmallVector<Value *, 8> Args;
            bool CanRemap = true;
            for (Value *Arg : HelperCaseCall->args()) {
              Value *Mapped = remapHelperOperand(Arg, CI);
              if (!Mapped) {
                CanRemap = false;
                break;
              }
              Args.push_back(Mapped);
            }
            if (CanRemap) {
              IRBuilder<> B(CI);
              CallInst *Direct =
                  B.CreateCall(Target->getFunctionType(), Target, Args);
              Direct->setCallingConv(Target->getCallingConv());
              CI->replaceAllUsesWith(Direct);
              CI->eraseFromParent();
              Changed = true;
              continue;
            }
          }
        }
      }

      Function *Target = LiftedByPC.lookup(*TargetPC);
      if (!Target || Target->getFunctionType()->getNumParams() != 3) {
        continue;
      }

      IRBuilder<> B(CI);
      Value *PCArg =
          ConstantInt::get(Type::getInt64Ty(M.getContext()), *TargetPC);
      SmallVector<Value *, 3> Args = {CI->getArgOperand(0), PCArg,
                                      CI->getArgOperand(2)};
      CallInst *Direct = B.CreateCall(Target->getFunctionType(), Target, Args);
      Direct->setCallingConv(Target->getCallingConv());
      CI->replaceAllUsesWith(Direct);
      CI->eraseFromParent();
      Changed = true;
    }
  }

  return Changed;
}

static bool internalizeRecoveredLiftedFunctions(Module &M) {
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration() || F.getName().ends_with("_native") ||
        F.getName().starts_with("__remill_") ||
        F.getName().starts_with("__mcsema_")) {
      continue;
    }

    if (!M.getFunction((F.getName() + "_native").str())) {
      continue;
    }

    Changed |= stripOptimizationBlockers(F);
    if (!F.hasFnAttribute(Attribute::AlwaysInline) && !F.hasAddressTaken()) {
      F.addFnAttr(Attribute::AlwaysInline);
      Changed = true;
    }
    if (!F.hasAddressTaken() && F.getLinkage() != GlobalValue::InternalLinkage) {
      F.setLinkage(GlobalValue::InternalLinkage);
      Changed = true;
    }
  }

  return Changed;
}

static bool cleanupNativeWrappers(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (!F.isDeclaration() && F.getName().ends_with("_native")) {
      Changed |= stripOptimizationBlockers(F);
      if (!F.hasAddressTaken() &&
          F.getLinkage() != GlobalValue::InternalLinkage) {
        F.setLinkage(GlobalValue::InternalLinkage);
        Changed = true;
      }
    }
  }
  return Changed;
}

static bool isTrackedStateBase(Value *V) {
  V = V->stripPointerCasts();

  if (auto *GV = dyn_cast<GlobalVariable>(V)) {
    return GV->getName() == "__mcsema_reg_state";
  }

  if (auto *Arg = dyn_cast<Argument>(V)) {
    if (!Arg->getType()->isPointerTy()) {
      return false;
    }
    if (Arg->getName().contains_insensitive("state")) {
      return true;
    }
    return Arg->getArgNo() == 0 && Arg->getParent()->getName() != "main";
  }

  if (auto *AI = dyn_cast<AllocaInst>(V)) {
    return AI->getName().contains("state");
  }

  return false;
}

static Value *getTrackedStateBase(Value *V) {
  while (true) {
    if (auto *GEP = dyn_cast<GEPOperator>(V)) {
      V = GEP->getPointerOperand();
      continue;
    }
    if (auto *BC = dyn_cast<BitCastOperator>(V)) {
      V = BC->getOperand(0);
      continue;
    }
    if (auto *GA = dyn_cast<GlobalAlias>(V)) {
      V = GA->getAliasee();
      continue;
    }
    break;
  }

  V = V->stripPointerCasts();
  return isTrackedStateBase(V) ? V : nullptr;
}

static std::optional<int64_t> resolveTrackedStateOffset(Value *Ptr,
                                                        const DataLayout &DL) {
  int64_t TotalOffset = 0;
  Value *Base = Ptr;

  while (true) {
    if (auto *GEP = dyn_cast<GEPOperator>(Base)) {
      APInt APOffset(64, 0);
      if (!GEP->accumulateConstantOffset(DL, APOffset)) {
        return std::nullopt;
      }
      TotalOffset += APOffset.getSExtValue();
      Base = GEP->getPointerOperand();
      continue;
    }
    if (auto *BC = dyn_cast<BitCastOperator>(Base)) {
      Base = BC->getOperand(0);
      continue;
    }
    if (auto *GA = dyn_cast<GlobalAlias>(Base)) {
      Base = GA->getAliasee();
      continue;
    }
    break;
  }

  Base = Base->stripPointerCasts();
  if (!isTrackedStateBase(Base)) {
    return std::nullopt;
  }
  return TotalOffset;
}

static bool callUsesTrackedState(CallBase &CB) {
  for (Value *Arg : CB.args()) {
    if (getTrackedStateBase(Arg)) {
      return true;
    }
  }
  return false;
}

static bool cleanupRedundantStateTraffic(Function &F,
                                         const DataLayout &DL) {
  bool Changed = false;
  SmallVector<Instruction *, 32> DeadCandidates;

  for (BasicBlock &BB : F) {
    DenseMap<int64_t, Value *> KnownStateValues;
    SmallVector<Instruction *, 16> ToErase;

    for (Instruction &I : BB) {
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        if (LI->isVolatile() || LI->isAtomic()) {
          KnownStateValues.clear();
          continue;
        }

        std::optional<int64_t> Offset =
            resolveTrackedStateOffset(LI->getPointerOperand(), DL);
        if (!Offset) {
          continue;
        }

        auto It = KnownStateValues.find(*Offset);
        if (It != KnownStateValues.end() &&
            It->second->getType() == LI->getType()) {
          LI->replaceAllUsesWith(It->second);
          DeadCandidates.push_back(LI);
          if (auto *PtrI = dyn_cast<Instruction>(LI->getPointerOperand())) {
            DeadCandidates.push_back(PtrI);
          }
          ToErase.push_back(LI);
          Changed = true;
          continue;
        }

        KnownStateValues[*Offset] = LI;
        continue;
      }

      if (auto *SI = dyn_cast<StoreInst>(&I)) {
        if (SI->isVolatile() || SI->isAtomic()) {
          KnownStateValues.clear();
          continue;
        }

        std::optional<int64_t> Offset =
            resolveTrackedStateOffset(SI->getPointerOperand(), DL);
        if (!Offset) {
          KnownStateValues.clear();
          continue;
        }

        auto It = KnownStateValues.find(*Offset);
        if (It != KnownStateValues.end() &&
            It->second == SI->getValueOperand()) {
          if (auto *ValueI = dyn_cast<Instruction>(SI->getValueOperand())) {
            DeadCandidates.push_back(ValueI);
          }
          if (auto *PtrI = dyn_cast<Instruction>(SI->getPointerOperand())) {
            DeadCandidates.push_back(PtrI);
          }
          ToErase.push_back(SI);
          Changed = true;
          continue;
        }

        KnownStateValues[*Offset] = SI->getValueOperand();
        continue;
      }

      if (auto *CB = dyn_cast<CallBase>(&I)) {
        Function *Callee = CB->getCalledFunction();
        if (!Callee || !Callee->getName().ends_with("_native") ||
            callUsesTrackedState(*CB)) {
          KnownStateValues.clear();
        }
        continue;
      }

      if (I.mayReadOrWriteMemory()) {
        KnownStateValues.clear();
      }
    }

    for (Instruction *I : ToErase) {
      I->eraseFromParent();
    }
  }

  if (!Changed) {
    return false;
  }

  bool DeletedDead = true;
  while (DeletedDead) {
    DeletedDead = false;
    SmallVector<Instruction *, 32> DeadNow;
    for (Instruction &I : instructions(F)) {
      if (isInstructionTriviallyDead(&I)) {
        DeadNow.push_back(&I);
      }
    }
    for (Instruction *I : DeadNow) {
      RecursivelyDeleteTriviallyDeadInstructions(I);
      DeletedDead = true;
    }
  }

  for (Instruction *I : DeadCandidates) {
    if (I->getParent() && isInstructionTriviallyDead(I)) {
      RecursivelyDeleteTriviallyDeadInstructions(I);
    }
  }

  return true;
}

static bool cleanupRedundantStateTraffic(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    Changed |= cleanupRedundantStateTraffic(F, DL);
  }
  return Changed;
}

static bool cleanupRuntimeHelpers(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    if (!(F.getName().starts_with("__remill_") ||
          F.getName().starts_with("__mcsema_"))) {
      continue;
    }

    Changed |= stripOptimizationBlockers(F);
    if (!F.hasAddressTaken() &&
        F.getLinkage() != GlobalValue::InternalLinkage) {
      F.setLinkage(GlobalValue::InternalLinkage);
      Changed = true;
    }
  }
  return Changed;
}

static bool isHoistablePointerCandidate(Instruction *I) {
  if (I->mayHaveSideEffects() || I->mayReadOrWriteMemory()) {
    return false;
  }

  switch (I->getOpcode()) {
    case Instruction::GetElementPtr:
    case Instruction::BitCast:
    case Instruction::AddrSpaceCast:
    case Instruction::PtrToInt:
    case Instruction::IntToPtr:
    case Instruction::Add:
    case Instruction::Sub:
    case Instruction::Mul:
    case Instruction::Shl:
    case Instruction::LShr:
    case Instruction::AShr:
    case Instruction::And:
    case Instruction::Or:
    case Instruction::Xor:
    case Instruction::ZExt:
    case Instruction::SExt:
    case Instruction::Trunc:
      return true;
    default:
      return false;
  }
}

static bool isUsedByHeaderPHI(Instruction *I, Loop *L) {
  BasicBlock *Header = L->getHeader();
  for (User *U : I->users()) {
    auto *PHI = dyn_cast<PHINode>(U);
    if (PHI && PHI->getParent() == Header) {
      return true;
    }
  }
  return false;
}

static bool canHoistFromLoop(Instruction *I, Loop *L,
                             DenseSet<Instruction *> &Hoistable) {
  if (!isSafeToSpeculativelyExecute(I)) {
    return false;
  }

  for (Use &Op : I->operands()) {
    auto *OpI = dyn_cast<Instruction>(Op.get());
    if (OpI && L->contains(OpI) && !Hoistable.contains(OpI)) {
      return false;
    }
  }
  return true;
}

static bool hoistLoopPointerComputations(Function &F) {
  DominatorTree DT(F);
  LoopInfo LI(DT);
  bool Changed = false;

  SmallVector<Loop *, 8> Worklist;
  for (Loop *TopLoop : LI) {
    SmallVector<Loop *, 8> Stack;
    Stack.push_back(TopLoop);
    while (!Stack.empty()) {
      Loop *L = Stack.pop_back_val();
      Worklist.push_back(L);
      for (Loop *Sub : *L) {
        Stack.push_back(Sub);
      }
    }
  }
  std::reverse(Worklist.begin(), Worklist.end());

  for (Loop *L : Worklist) {
    BasicBlock *Preheader = L->getLoopPreheader();
    if (!Preheader) {
      continue;
    }

    DenseSet<Instruction *> Hoistable;
    bool Added = true;
    while (Added) {
      Added = false;
      for (BasicBlock *BB : L->blocks()) {
        for (Instruction &I : *BB) {
          if (Hoistable.contains(&I) || !isHoistablePointerCandidate(&I) ||
              isUsedByHeaderPHI(&I, L) || !canHoistFromLoop(&I, L, Hoistable)) {
            continue;
          }
          Hoistable.insert(&I);
          Added = true;
        }
      }
    }

    if (Hoistable.empty()) {
      continue;
    }

    SmallVector<Instruction *, 32> Ordered;
    for (BasicBlock *BB : L->blocks()) {
      for (Instruction &I : *BB) {
        if (Hoistable.contains(&I)) {
          Ordered.push_back(&I);
        }
      }
    }

    Instruction *InsertPt = Preheader->getTerminator();
    for (Instruction *I : Ordered) {
      I->moveBefore(InsertPt->getIterator());
      Changed = true;
    }
  }

  return Changed;
}

static bool dedupSameBlockPointerComputations(Function &F) {
  bool Changed = false;

  for (BasicBlock &BB : F) {
    SmallVector<Instruction *, 16> Available;
    SmallVector<Instruction *, 16> ToErase;

    for (Instruction &I : BB) {
      if (!isHoistablePointerCandidate(&I)) {
        continue;
      }

      bool Reused = false;
      for (Instruction *Prev : Available) {
        if (I.isIdenticalToWhenDefined(Prev)) {
          I.replaceAllUsesWith(Prev);
          ToErase.push_back(&I);
          Changed = true;
          Reused = true;
          break;
        }
      }

      if (!Reused) {
        Available.push_back(&I);
      }
    }

    for (Instruction *I : ToErase) {
      I->eraseFromParent();
    }
  }

  return Changed;
}

static bool cleanupLoopInvariantPointerComputations(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    Changed |= hoistLoopPointerComputations(F);
    Changed |= dedupSameBlockPointerComputations(F);
  }
  return Changed;
}

static bool isDeadPrivateVolatileSeed(GlobalVariable *GV) {
  if (!GV || !GV->hasInitializer() || !GV->hasLocalLinkage()) {
    return false;
  }
  if (!GV->getValueType()->isIntegerTy() || !GV->getInitializer()->isNullValue()) {
    return false;
  }
  for (User *U : GV->users()) {
    auto *LI = dyn_cast<LoadInst>(U);
    if (!LI || !LI->isVolatile() || !LI->use_empty()) {
      return false;
    }
  }
  return true;
}

static bool cleanupDeadPrivateVolatileLoads(Module &M) {
  bool Changed = false;
  SmallVector<Instruction *, 8> DeadLoads;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    for (Instruction &I : instructions(F)) {
      auto *LI = dyn_cast<LoadInst>(&I);
      if (!LI || !LI->isVolatile() || !LI->use_empty()) {
        continue;
      }

      auto *GV = dyn_cast<GlobalVariable>(LI->getPointerOperand()->stripPointerCasts());
      if (!isDeadPrivateVolatileSeed(GV)) {
        continue;
      }

      DeadLoads.push_back(LI);
    }
  }

  for (Instruction *I : DeadLoads) {
    I->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

static bool pruneUnusedArtifacts(Module &M) {
  bool Changed = false;
  SmallVector<Function *, 16> DeadDecls;
  SmallVector<GlobalVariable *, 16> DeadGlobals;
  SmallVector<GlobalAlias *, 16> DeadAliases;

  for (Function &F : M) {
    if (F.use_empty() &&
        (F.getName().starts_with("__remill_") ||
         F.getName().starts_with("__mcsema_"))) {
      DeadDecls.push_back(&F);
    }
  }

  for (GlobalVariable &GV : M.globals()) {
    if (!GV.use_empty()) {
      continue;
    }
    if (GV.getName().starts_with("__remill_") ||
        GV.getName().starts_with("__mcsema_") ||
        GV.hasLocalLinkage()) {
      DeadGlobals.push_back(&GV);
    }
  }

  for (GlobalAlias &GA : M.aliases()) {
    if (GA.use_empty()) {
      DeadAliases.push_back(&GA);
    }
  }

  for (GlobalAlias *GA : DeadAliases) {
    GA->eraseFromParent();
    Changed = true;
  }
  for (GlobalVariable *GV : DeadGlobals) {
    GV->eraseFromParent();
    Changed = true;
  }
  for (Function *F : DeadDecls) {
    F->eraseFromParent();
    Changed = true;
  }

  return Changed;
}

} // namespace

bool BrightenNativeCleanupPass::CleanupNativeArtifacts(Module &M) {
  bool Changed = false;
  Changed |= rewriteStaticRemillDispatch(M);
  Changed |= cleanupRedundantStateTraffic(M);
  Changed |= cleanupLoopInvariantPointerComputations(M);
  Changed |= cleanupDeadPrivateVolatileLoads(M);
  Changed |= internalizeRecoveredLiftedFunctions(M);
  Changed |= cleanupNativeWrappers(M);
  Changed |= cleanupRuntimeHelpers(M);
  Changed |= pruneUnusedArtifacts(M);
  return Changed;
}

} // namespace brighten_native_cleanup
