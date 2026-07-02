#include "BrightenDevirtPass.h"

#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/CFG.h"
#include "llvm/IR/Constants.h"
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

static Value *FindRAXStoreInBlock(BasicBlock *BB, const DataLayout &DL) {
  for (auto It = BB->rbegin(); It != BB->rend(); ++It) {
    auto *SI = dyn_cast<StoreInst>(&*It);
    if (!SI) {
      continue;
    }
    if (IsRAXPointer(SI->getPointerOperand(), DL)) {
      return NormalizeCandidate(SI->getValueOperand());
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

static Value *FindRAXValueBeforeRet(ReturnInst *RI, const DataLayout &DL) {
  BasicBlock *RetBB = RI->getParent();
  if (Value *V = FindRAXStoreInBlock(RetBB, DL)) {
    return V;
  }

  SmallVector<BasicBlock *, 8> Preds(predecessors(RetBB));
  if (Preds.empty()) {
    return nullptr;
  }

  if (Preds.size() > 1) {
    SmallVector<Value *, 8> Values;
    for (BasicBlock *Pred : Preds) {
      Value *V = FindRAXStoreInBlock(Pred, DL);
      if (!V) {
        return nullptr;
      }
      Values.push_back(V);
    }

    bool Same = true;
    for (unsigned I = 1, E = Values.size(); I < E; ++I) {
      if (Values[I] != Values[0]) {
        Same = false;
        break;
      }
    }
    if (Same) {
      return Values[0];
    }

    return FindExistingPhiForPredValues(RetBB, Preds, Values);
  }

  SmallVector<BasicBlock *, 8> Worklist;
  DenseSet<BasicBlock *> Seen;
  Worklist.push_back(Preds.front());

  unsigned Depth = 0;
  while (!Worklist.empty() && Depth++ < 4) {
    SmallVector<BasicBlock *, 8> Next;
    for (BasicBlock *BB : Worklist) {
      if (!Seen.insert(BB).second) {
        continue;
      }
      if (Value *V = FindRAXStoreInBlock(BB, DL)) {
        return V;
      }
      for (BasicBlock *Pred : predecessors(BB)) {
        Next.push_back(Pred);
      }
    }
    Worklist = std::move(Next);
  }

  return nullptr;
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

static void InsertReturnMarker(Module &M, ReturnInst *RI, Value *RAX) {
  if (HasReturnMarker(RI)) {
    return;
  }

  IRBuilder<> B(RI);
  FunctionCallee SideEffect =
      Intrinsic::getOrInsertDeclaration(&M, Intrinsic::sideeffect);
  OperandBundleDef Bundle("brighten_return_rax", RAX);
  B.CreateCall(SideEffect, {}, {Bundle});
}

bool BrightenDevirtPass::AnnotateRemillReturns(Module &M) {
  LLVMContext &Ctx = M.getContext();
  const DataLayout &DL = M.getDataLayout();
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    for (BasicBlock &BB : F) {
      auto *RI = dyn_cast<ReturnInst>(BB.getTerminator());
      if (!RI) {
        continue;
      }

      Value *RAX = FindRAXValueBeforeRet(RI, DL);
      if (!RAX) {
        continue;
      }

      InsertReturnMarker(M, RI, RAX);
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
