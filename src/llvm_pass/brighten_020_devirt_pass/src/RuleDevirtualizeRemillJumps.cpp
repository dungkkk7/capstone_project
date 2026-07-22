#include "BrightenDevirtPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Twine.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

static bool IsRemillJump(CallBase *CB, Function *RemillJump) {
  return RemillJump && ResolveCalledFunction(CB->getCalledOperand()) == RemillJump;
}

// Prove the byte index used by a recovered immutable table load preserves the
// table element alignment.  This intentionally accepts only arithmetic whose
// low zero bits are evident syntactically; an arbitrary runtime byte index is
// not a finite element selection.
static bool IsKnownMultipleOf(Value *V, uint64_t Multiple,
                              unsigned Depth = 0) {
  if (!V || !Multiple || Depth > 8)
    return false;
  if (Multiple == 1)
    return true;
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return CI->getValue().urem(Multiple) == 0;
  if (auto *Cast = dyn_cast<CastInst>(V)) {
    if (isa<SExtInst, ZExtInst, TruncInst>(Cast))
      return IsKnownMultipleOf(Cast->getOperand(0), Multiple, Depth + 1);
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO)
    return false;
  if (BO->getOpcode() == Instruction::Shl) {
    auto *Shift = dyn_cast<ConstantInt>(BO->getOperand(1));
    if (!Shift || !isPowerOf2_64(Multiple))
      return false;
    return Shift->getZExtValue() >= Log2_64(Multiple) ||
           IsKnownMultipleOf(BO->getOperand(0), Multiple, Depth + 1);
  }
  if (BO->getOpcode() == Instruction::Mul) {
    if (auto *K = dyn_cast<ConstantInt>(BO->getOperand(0)))
      if (K->getValue().urem(Multiple) == 0)
        return true;
    if (auto *K = dyn_cast<ConstantInt>(BO->getOperand(1)))
      if (K->getValue().urem(Multiple) == 0)
        return true;
  }
  if (BO->getOpcode() == Instruction::Add ||
      BO->getOpcode() == Instruction::Sub)
    return IsKnownMultipleOf(BO->getOperand(0), Multiple, Depth + 1) &&
           IsKnownMultipleOf(BO->getOperand(1), Multiple, Depth + 1);
  return false;
}

static bool CollectImmutableTablePCs(Value *V, const DataLayout &DL,
                                     SmallVectorImpl<uint64_t> &PCs) {
  auto *LI = dyn_cast<LoadInst>(V);
  if (!LI || LI->isVolatile() || !LI->getType()->isIntegerTy())
    return false;
  auto *GEP = dyn_cast<GEPOperator>(LI->getPointerOperand());
  if (!GEP)
    return false;
  auto *GV = dyn_cast<GlobalVariable>(
      GEP->getPointerOperand()->stripPointerCasts());
  auto *AT = GV && GV->hasInitializer()
                 ? dyn_cast<ArrayType>(GV->getInitializer()->getType())
                 : nullptr;
  if (!GV || !GV->isConstant() || !AT ||
      AT->getElementType() != LI->getType() || AT->getNumElements() == 0 ||
      AT->getNumElements() > 32)
    return false;

  uint64_t ElementBytes = DL.getTypeStoreSize(LI->getType()).getFixedValue();
  if (!ElementBytes)
    return false;
  bool ProvenElementAddress = false;
  if (GEP->getSourceElementType()->isIntegerTy(8) &&
      GEP->getNumIndices() == 1) {
    ProvenElementAddress =
        IsKnownMultipleOf(*GEP->idx_begin(), ElementBytes);
  } else if (GEP->getSourceElementType() == AT &&
             GEP->getNumIndices() == 2) {
    auto It = GEP->idx_begin();
    auto *Zero = dyn_cast<ConstantInt>(*It++);
    ProvenElementAddress = Zero && Zero->isZero();
  }
  if (!ProvenElementAddress)
    return false;

  for (uint64_t I = 0; I < AT->getNumElements(); ++I) {
    Constant *Element = GV->getInitializer()->getAggregateElement(I);
    auto PC = ExtractConstantPC(Element, DL);
    if (!PC)
      return false;
    PCs.push_back(*PC);
  }
  llvm::sort(PCs);
  PCs.erase(std::unique(PCs.begin(), PCs.end()), PCs.end());
  return !PCs.empty();
}

static Value *SwitchSourcePC(Value *Condition, Value *PC) {
  if (Condition == PC)
    return PC;
  auto *Cast = dyn_cast<CastInst>(Condition);
  if (Cast && Cast->getOperand(0) == PC && isa<TruncInst>(Cast))
    return PC;
  return nullptr;
}

// A recovered jump-table access is defined only for an in-object element.
// If a chain of switch defaults has already intercepted every value stored in
// the immutable table, the final Remill jump is solely the invalid/OOB path.
// Cut that default edge to unreachable so the legacy dispatcher SCC can die.
static bool EliminateExhaustedImmutableTableJump(CallInst *CI,
                                                 Value *PC,
                                                 const DataLayout &DL) {
  if (!CI || !CI->use_empty())
    return false;
  SmallVector<uint64_t, 32> PCs;
  if (!CollectImmutableTablePCs(PC, DL, PCs))
    return false;

  SmallVector<SwitchInst *, 8> DefaultChain;
  BasicBlock *Current = CI->getParent();
  for (unsigned Depth = 0; Depth < 8; ++Depth) {
    BasicBlock *Pred = Current->getUniquePredecessor();
    auto *SW = Pred ? dyn_cast<SwitchInst>(Pred->getTerminator()) : nullptr;
    if (!SW || SW->getDefaultDest() != Current ||
        !SwitchSourcePC(SW->getCondition(), PC))
      break;
    DefaultChain.push_back(SW);
    Current = Pred;
  }
  if (DefaultChain.empty())
    return false;

  for (uint64_t PCValue : PCs) {
    bool Covered = false;
    for (SwitchInst *SW : DefaultChain) {
      auto *CondTy = cast<IntegerType>(SW->getCondition()->getType());
      ConstantInt *Key = ConstantInt::get(CondTy, PCValue);
      if (SW->findCaseValue(Key) != SW->case_default()) {
        Covered = true;
        break;
      }
    }
    if (!Covered)
      return false;
  }

  SwitchInst *Closest = DefaultChain.front();
  Function *F = CI->getFunction();
  BasicBlock *Invalid = BasicBlock::Create(
      F->getContext(), "devirt.invalid.table.target", F,
      Closest->getDefaultDest());
  IRBuilder<>(Invalid).CreateUnreachable();
  Closest->setDefaultDest(Invalid);
  CI->eraseFromParent();
  errs() << "[devirt] eliminated exhausted immutable-table remill jump with "
         << PCs.size() << " proven target value(s)\n";
  return true;
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

static CallInst *CreateLiftedDirectJump(IRBuilder<> &B, CallInst *Old,
                                        Function *Target, Value *ResolvedPC) {
  FunctionType *FTy = Target->getFunctionType();
  if (FTy->getNumParams() > Old->arg_size()) {
    errs() << "[devirt] ERROR: rewrite type mismatch for @" << Target->getName()
           << "\n";
    return nullptr;
  }
  if (!Old->use_empty() && FTy->getReturnType() != Old->getType()) {
    errs() << "[devirt] ERROR: rewrite return type mismatch for @"
           << Target->getName() << "\n";
    return nullptr;
  }

  SmallVector<Value *, 4> Args;
  for (unsigned I = 0, E = FTy->getNumParams(); I < E && I < Old->arg_size();
       ++I) {
    Value *Arg = (I == 1 && ResolvedPC) ? ResolvedPC : Old->getArgOperand(I);
    Args.push_back(CoerceArg(B, Arg, FTy->getParamType(I)));
  }

  CallInst *NewCall = B.CreateCall(FTy, Target, Args);
  NewCall->setCallingConv(Target->getCallingConv());
  NewCall->setTailCallKind(Old->getTailCallKind());
  return NewCall;
}

bool BrightenDevirtPass::DevirtualizeRemillJumps(Module &M) {
  Function *RemillJump = M.getFunction("__remill_jump");
  if (!RemillJump) {
    return false;
  }

  const DataLayout &DL = M.getDataLayout();
  SmallVector<CallInst *, 64> Worklist;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CI = dyn_cast<CallInst>(&I)) {
          if (IsRemillJump(CI, RemillJump)) {
            Worklist.push_back(CI);
          }
        } else if (auto *II = dyn_cast<InvokeInst>(&I)) {
          if (IsRemillJump(II, RemillJump)) {
            errs() << "[devirt] WARNING: remill invoke jump not lowered\n";
          }
        }
      }
    }
  }

  bool Changed = false;
  for (CallInst *CI : Worklist) {
    if (CI->arg_size() < 3) {
      continue;
    }

    Value *PCVal = CI->getArgOperand(1);
    auto PC = ExtractConstantPC(PCVal, DL);
    if (!PC) {
      if (EliminateExhaustedImmutableTableJump(CI, PCVal, DL)) {
        Changed = true;
        continue;
      }
      if (LowerFiniteRemillPCSwitch(M, CI, RemillJump, true)) {
        Changed = true;
        continue;
      }
      errs() << "[devirt] INFO: dynamic remill jump preserved\n";
      continue;
    }

    Function *Target = FindLiftedSubroutineByPC(M, *PC);
    if (!Target) {
      errs() << "[devirt] WARNING: unresolved constant __remill_jump PC = 0x"
             << Twine::utohexstr(*PC) << "\n";
      continue;
    }

    IRBuilder<> B(CI);
    Value *ResolvedPC =
        ConstantInt::get(CI->getArgOperand(1)->getType(), *PC);
    CallInst *NewCall = CreateLiftedDirectJump(B, CI, Target, ResolvedPC);
    if (!NewCall) {
      continue;
    }
    if (!CI->use_empty()) {
      CI->replaceAllUsesWith(NewCall);
    }
    CI->eraseFromParent();
    Changed = true;

    errs() << "[devirt] lowered remill jump PC 0x" << Twine::utohexstr(*PC)
           << " -> @" << Target->getName() << "\n";
  }

  return Changed;
}

} // namespace brighten_devirt
