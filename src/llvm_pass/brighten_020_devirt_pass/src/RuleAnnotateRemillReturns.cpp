#include "BrightenDevirtPass.h"

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Metadata.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_devirt {

using namespace llvm;

static constexpr int64_t kOffRAX = 2216;

static bool IsRAXPointer(Value *Ptr, const DataLayout &DL) {
  if (!Ptr) {
    return false;
  }

  Value *Stripped = Ptr->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalValue>(Stripped)) {
    if (GV->getName().starts_with("RAX_")) {
      return true;
    }
  }

  auto *GEP = dyn_cast<GEPOperator>(Stripped);
  if (!GEP) {
    return false;
  }

  Value *Base = GEP->getPointerOperand()->stripPointerCasts();
  auto *BaseGV = dyn_cast<GlobalValue>(Base);
  if (!BaseGV || BaseGV->getName() != "__mcsema_reg_state") {
    return false;
  }

  APInt Offset(DL.getIndexTypeSizeInBits(GEP->getType()), 0, true);
  if (GEP->accumulateConstantOffset(DL, Offset) &&
      Offset.getSExtValue() == kOffRAX) {
    return true;
  }

  if (GEP->getNumOperands() >= 4) {
    if (auto *Idx = dyn_cast<ConstantInt>(GEP->getOperand(3))) {
      return Idx->getZExtValue() == 1;
    }
  }

  return false;
}

static Value *NormalizeCandidate(Value *V) {
  if (!V) {
    return nullptr;
  }

  if (auto *Cast = dyn_cast<CastInst>(V)) {
    switch (Cast->getOpcode()) {
    case Instruction::Trunc:
    case Instruction::ZExt:
    case Instruction::SExt:
    case Instruction::PtrToInt:
    case Instruction::IntToPtr:
    case Instruction::BitCast:
      return V;
    default:
      break;
    }
  }

  return V;
}

static bool CallMayClobberState(CallBase *CB) {
  if (Function *Callee = CB->getCalledFunction()) {
    if (Callee->onlyReadsMemory() || Callee->doesNotAccessMemory())
      return false;
  }
  return true;
}

static Value *FindRAXStoreInBlock(BasicBlock *BB, const DataLayout &DL,
                                  bool &Clobbered) {
  Clobbered = false;
  for (auto It = BB->rbegin(); It != BB->rend(); ++It) {
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (SI && IsRAXPointer(SI->getPointerOperand(), DL)) {
      return NormalizeCandidate(SI->getValueOperand());
    }
    // A lifted/native call can update RAX through the shared State even when
    // its LLVM return value is the memory token.  Never use a stale store from
    // before such a call as the recovered application return value.
    if (auto *CB = dyn_cast<CallBase>(&*It); CB && CallMayClobberState(CB)) {
      Clobbered = true;
      return nullptr;
    }
  }
  return nullptr;
}

static Value *FindExistingPhiForPredValues(BasicBlock *BB,
                                           ArrayRef<BasicBlock *> Preds,
                                           ArrayRef<Value *> Values) {
  for (PHINode &Phi : BB->phis()) {
    if (Phi.getNumIncomingValues() != Preds.size()) {
      continue;
    }

    bool Match = true;
    for (unsigned I = 0, E = Preds.size(); I < E; ++I) {
      if (Phi.getIncomingValueForBlock(Preds[I]) != Values[I]) {
        Match = false;
        break;
      }
    }
    if (Match) {
      return &Phi;
    }
  }
  return nullptr;
}

static Value *FindReachingRAXValue(BasicBlock *BB, const DataLayout &DL,
                                   DenseSet<BasicBlock *> &Visiting,
                                   unsigned Depth) {
  if (Depth > 32 || !Visiting.insert(BB).second)
    return nullptr;

  bool Clobbered = false;
  if (Value *V = FindRAXStoreInBlock(BB, DL, Clobbered)) {
    Visiting.erase(BB);
    return V;
  }
  if (Clobbered) {
    Visiting.erase(BB);
    return nullptr;
  }

  SmallVector<BasicBlock *, 8> Preds(predecessors(BB));
  if (Preds.empty()) {
    Visiting.erase(BB);
    return nullptr;
  }

  SmallVector<Value *, 8> Values;
  for (BasicBlock *Pred : Preds) {
    Value *V = FindReachingRAXValue(Pred, DL, Visiting, Depth + 1);
    if (!V) {
      Visiting.erase(BB);
      return nullptr;
    }
    Values.push_back(V);
  }
  Visiting.erase(BB);

  bool Same = true;
  for (unsigned I = 1, E = Values.size(); I < E; ++I)
    Same &= Values[I] == Values[0];
  if (Same)
    return Values[0];
  return FindExistingPhiForPredValues(BB, Preds, Values);
}

static Value *FindRAXValueBeforeRet(ReturnInst *RI, const DataLayout &DL) {
  DenseSet<BasicBlock *> Visiting;
  return FindReachingRAXValue(RI->getParent(), DL, Visiting, 0);
}

static MDNode *MakeCandidateMetadata(LLVMContext &Ctx, StringRef Prefix,
                                     Value *V) {
  std::string Ty;
  raw_string_ostream OS(Ty);
  OS << Prefix << ":";
  V->getType()->print(OS);
  if (V->hasName()) {
    OS << ":" << V->getName();
  }
  return MDNode::get(Ctx, {MDString::get(Ctx, OS.str())});
}

static bool HasReturnMarker(ReturnInst *RI) {
  Instruction *Prev = RI->getPrevNode();
  auto *CB = dyn_cast_or_null<CallBase>(Prev);
  if (!CB) {
    return false;
  }
  Function *Callee = CB->getCalledFunction();
  return Callee && Callee->getIntrinsicID() == Intrinsic::sideeffect &&
         CB->hasOperandBundles() &&
         CB->getOperandBundle("brighten_return_rax").has_value();
}

static bool InsertReturnMarker(Module &M, ReturnInst *RI, Value *RAX,
                               DominatorTree &DT) {
  if (HasReturnMarker(RI)) {
    return true;
  }

  // The operand bundle is a real use of RAX.  In particular, a value found
  // in one predecessor cannot be attached directly to a return in a join
  // block unless it dominates that return.  Skipping the annotation is
  // conservative; emitting invalid IR would poison every later pass.
  if (auto *Def = dyn_cast<Instruction>(RAX)) {
    if (!DT.dominates(Def, RI)) {
      errs() << "[brighten-devirt] skipping non-dominating return RAX in "
             << RI->getFunction()->getName() << "\n";
      return false;
    }
  }

  IRBuilder<> B(RI);
  FunctionCallee SideEffect =
      Intrinsic::getOrInsertDeclaration(&M, Intrinsic::sideeffect);
  OperandBundleDef Bundle("brighten_return_rax", RAX);
  B.CreateCall(SideEffect, {}, {Bundle});
  return true;
}

bool BrightenDevirtPass::AnnotateRemillReturns(Module &M) {
  LLVMContext &Ctx = M.getContext();
  const DataLayout &DL = M.getDataLayout();
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    DominatorTree DT(F);

    for (BasicBlock &BB : F) {
      auto *RI = dyn_cast<ReturnInst>(BB.getTerminator());
      if (!RI) {
        continue;
      }

      Value *RAX = FindRAXValueBeforeRet(RI, DL);
      if (!RAX) {
        continue;
      }

      if (!InsertReturnMarker(M, RI, RAX, DT)) {
        continue;
      }
      RI->setMetadata("brighten.return_rax.info",
                      MakeCandidateMetadata(Ctx, "rax", RAX));
      RI->setMetadata("brighten.return_candidate",
                      MakeCandidateMetadata(Ctx, "candidate", RAX));
      F.setMetadata("brighten.return_candidate",
                    MakeCandidateMetadata(Ctx, "candidate", RAX));
      Changed = true;
    }
  }

  return Changed;
}

} // namespace brighten_devirt
