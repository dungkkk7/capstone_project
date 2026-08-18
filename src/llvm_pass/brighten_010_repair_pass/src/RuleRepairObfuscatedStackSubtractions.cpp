#include "BrightenRepairPass.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_repair {

using namespace llvm;

static uint64_t ParseGuestAddress(StringRef Name) {
  if (Name.starts_with("data_")) {
    StringRef Hex = Name.drop_front(5);
    uint64_t Val = 0;
    if (!Hex.getAsInteger(16, Val)) {
      return Val;
    }
  } else if (Name.starts_with("sub_")) {
    StringRef Hex = Name.drop_front(4);
    size_t Underscore = Hex.find('_');
    if (Underscore != StringRef::npos) {
      Hex = Hex.substr(0, Underscore);
    }
    uint64_t Val = 0;
    if (!Hex.getAsInteger(16, Val)) {
      return Val;
    }
  }
  return 0;
}

static GlobalValue *MatchPtrToIntGlobal(Value *V) {
  Value *Ptr = nullptr;
  if (auto *Cast = dyn_cast<PtrToIntInst>(V)) {
    Ptr = Cast->getOperand(0);
  } else if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt) {
      Ptr = CE->getOperand(0);
    }
  }
  if (!Ptr) return nullptr;

  Ptr = Ptr->stripPointerCasts();
  return dyn_cast<GlobalValue>(Ptr);
}

static bool IsRSPSlot(Value *Ptr) {
  Ptr = Ptr->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalVariable>(Ptr)) {
    StringRef Name = GV->getName();
    if (Name.starts_with("RSP_2312") || Name == "__mcsema_reg_state") {
      return true;
    }
  }
  if (auto *GEP = dyn_cast<GEPOperator>(Ptr)) {
    Value *Base = GEP->getPointerOperand()->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(Base)) {
      if (GV->getName() == "__mcsema_reg_state") {
        if (GEP->getNumIndices() >= 3) {
          if (auto *CI = dyn_cast<ConstantInt>(GEP->getOperand(3))) {
            if (CI->getZExtValue() == 13) {
              return true;
            }
          }
        }
      }
    }
  }
  return false;
}

static bool IsStoredToRSP(Value *V, int Depth) {
  if (Depth > 5) return false;
  for (User *U : V->users()) {
    if (auto *SI = dyn_cast<StoreInst>(U)) {
      if (IsRSPSlot(SI->getPointerOperand())) {
        return true;
      }
    }
    if (auto *BI = dyn_cast<BinaryOperator>(U)) {
      if (IsStoredToRSP(BI, Depth + 1)) {
        return true;
      }
    }
    if (auto *Cast = dyn_cast<CastInst>(U)) {
      if (IsStoredToRSP(Cast, Depth + 1)) {
        return true;
      }
    }
  }
  return false;
}

bool BrightenRepairPass::RepairObfuscatedStackSubtractions(Module &M) {
  bool Changed = false;

  for (Function &F : M) {
    if (F.isDeclaration()) continue;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO) continue;

        unsigned Opcode = BO->getOpcode();
        if (Opcode != Instruction::Sub && Opcode != Instruction::Add) continue;

        // Trace if the computed value is eventually stored back to RSP
        if (!IsStoredToRSP(BO, 0)) continue;

        if (Opcode == Instruction::Sub) {
          Value *RHS = BO->getOperand(1);
          if (GlobalValue *GV = MatchPtrToIntGlobal(RHS)) {
            uint64_t Addr = ParseGuestAddress(GV->getName());
            if (Addr > 0) {
              BO->setOperand(1, ConstantInt::get(BO->getType(), Addr));
              Changed = true;
            }
          }
        } else if (Opcode == Instruction::Add) {
          Value *LHS = BO->getOperand(0);
          Value *RHS = BO->getOperand(1);
          if (GlobalValue *GV = MatchPtrToIntGlobal(LHS)) {
            uint64_t Addr = ParseGuestAddress(GV->getName());
            if (Addr > 0) {
              BO->setOperand(0, ConstantInt::get(BO->getType(), Addr));
              Changed = true;
            }
          } else if (GlobalValue *GV = MatchPtrToIntGlobal(RHS)) {
            uint64_t Addr = ParseGuestAddress(GV->getName());
            if (Addr > 0) {
              BO->setOperand(1, ConstantInt::get(BO->getType(), Addr));
              Changed = true;
            }
          }
        }
      }
    }
  }

  return Changed;
}

} // namespace brighten_repair
