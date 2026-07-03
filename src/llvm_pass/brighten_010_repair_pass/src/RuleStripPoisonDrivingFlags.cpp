// Strip flag/metadata nguy hiem (nsw/nuw/exact/inbounds).
// - Clear instruction flags
// - Rebuild constexpr GEP bo inbounds
#include "BrightenRepairPass.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

namespace brighten_repair {

using namespace llvm;

static Constant *DropInBoundsFromConstantExpr(Constant *C, DenseMap<Constant *, Constant *> &Cache) {
  // Đệ quy qua constant graph để bỏ cờ inbounds trong constexpr GEP,
  // đồng thời rebuild operand nếu con đã thay đổi.
  auto It = Cache.find(C);
  if (It != Cache.end()) {
    return It->second;
  }

  auto RebuildOperands = [&](Constant *K, SmallVectorImpl<Constant *> &OutOps) -> bool {
    bool OpsChanged = false;
    OutOps.reserve(K->getNumOperands());
    for (Value *OpV : K->operands()) {
      auto *OpC = cast<Constant>(OpV);
      Constant *NewOp = DropInBoundsFromConstantExpr(OpC, Cache);
      OutOps.push_back(NewOp);
      OpsChanged |= (NewOp != OpC);
    }
    return OpsChanged;
  };

  if (auto *CE = dyn_cast<ConstantExpr>(C)) {
    SmallVector<Constant *, 8> NewOps;
    const bool OpsChanged = RebuildOperands(CE, NewOps);

    if (CE->getOpcode() == Instruction::GetElementPtr) {
      auto *GEP = cast<GEPOperator>(CE);
      Constant *Base = NewOps.empty() ? cast<Constant>(CE->getOperand(0)) : NewOps[0];
      SmallVector<Constant *, 8> Indices;
      for (size_t I = 1; I < NewOps.size(); ++I) {
        Indices.push_back(NewOps[I]);
      }

      if (GEP->isInBounds() || OpsChanged) {
        // Rebuild GEP constexpr với inbounds=false.
        Constant *NewCE = ConstantExpr::getGetElementPtr(GEP->getSourceElementType(), Base, Indices, false);
        Cache[C] = NewCE;
        return NewCE;
      }
    }

    if (OpsChanged) {
      Constant *NewCE = CE->getWithOperands(NewOps);
      Cache[C] = NewCE;
      return NewCE;
    }
  } else if (auto *CA = dyn_cast<ConstantArray>(C)) {
    SmallVector<Constant *, 8> NewOps;
    const bool OpsChanged = RebuildOperands(CA, NewOps);
    if (OpsChanged) {
      Constant *NewC = ConstantArray::get(cast<ArrayType>(CA->getType()), NewOps);
      Cache[C] = NewC;
      return NewC;
    }
  } else if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    SmallVector<Constant *, 8> NewOps;
    const bool OpsChanged = RebuildOperands(CS, NewOps);
    if (OpsChanged) {
      Constant *NewC = ConstantStruct::get(cast<StructType>(CS->getType()), NewOps);
      Cache[C] = NewC;
      return NewC;
    }
  } else if (auto *CV = dyn_cast<ConstantVector>(C)) {
    SmallVector<Constant *, 8> NewOps;
    const bool OpsChanged = RebuildOperands(CV, NewOps);
    if (OpsChanged) {
      Constant *NewC = ConstantVector::get(NewOps);
      Cache[C] = NewC;
      return NewC;
    }
  }

  Cache[C] = C;
  return C;
}

bool BrightenRepairPass::StripPoisonDrivingFlags(Module &M) {
  // Xoá các flag/metadata dễ làm optimizer suy luận quá mức trên lifted IR:
  // nsw/nuw/exact/inbounds.
  bool Changed = false;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *BO = dyn_cast<BinaryOperator>(&I)) {
          if (isa<OverflowingBinaryOperator>(BO)) {
            if (BO->hasNoSignedWrap()) {
              BO->setHasNoSignedWrap(false);
              Changed = true;
            }
            if (BO->hasNoUnsignedWrap()) {
              BO->setHasNoUnsignedWrap(false);
              Changed = true;
            }
          }
          if (isa<PossiblyExactOperator>(BO) && BO->isExact()) {
            BO->setIsExact(false);
            Changed = true;
          }
        }

        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
          if (GEP->isInBounds()) {
            GEP->setIsInBounds(false);
            Changed = true;
          }
        }
      }
    }
  }

  DenseMap<Constant *, Constant *> Cache;
  // Đồng bộ xử lý inbounds trong global initializers (constant expressions).
  for (GlobalVariable &GV : M.globals()) {
    if (!GV.hasInitializer()) {
      continue;
    }
    Constant *Init = GV.getInitializer();
    Constant *NewInit = DropInBoundsFromConstantExpr(Init, Cache);
    if (NewInit != Init) {
      GV.setInitializer(NewInit);
      Changed = true;
    }
  }

  return Changed;
}

}  // namespace brighten_repair
