#include "RegisterAccess.h"

#include "llvm/ADT/APInt.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"

namespace brighten_abi {

using namespace llvm;

static Module *FindModule(Value *V) {
  if (!V) {
    return nullptr;
  }
  if (auto *I = dyn_cast<Instruction>(V)) {
    return I->getModule();
  }
  if (auto *Arg = dyn_cast<Argument>(V)) {
    return Arg->getParent()->getParent();
  }
  if (auto *GV = dyn_cast<GlobalValue>(V)) {
    return GV->getParent();
  }
  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    return FindModule(GEP->getPointerOperand());
  }
  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    for (Value *Op : CE->operands()) {
      if (Module *M = FindModule(Op)) {
        return M;
      }
    }
  }
  if (auto *C = dyn_cast<Constant>(V)) {
    for (Value *Op : C->operands()) {
      if (Module *M = FindModule(Op)) {
        return M;
      }
    }
  }
  return nullptr;
}

static Value *StripAlias(Value *V) {
  if (!V) {
    return nullptr;
  }
  V = V->stripPointerCasts();
  if (auto *Alias = dyn_cast<GlobalAlias>(V)) {
    if (Constant *Aliasee = Alias->getAliasee()) {
      return Aliasee->stripPointerCasts();
    }
  }
  return V;
}

static bool IsLiftedStateArgument(Argument *Arg) {
  if (!Arg || Arg->getArgNo() != 0) {
    return false;
  }
  Function *F = Arg->getParent();
  if (!F || F->isDeclaration()) {
    return false;
  }
  if (F->getName().ends_with(".native")) {
    return Arg->getType()->isPointerTy();
  }
  if (F->arg_size() != 3 || !F->getReturnType()->isPointerTy()) {
    return false;
  }
  auto It = F->arg_begin();
  Type *StateTy = (It++)->getType();
  Type *PCTy = (It++)->getType();
  Type *MemoryTy = (It++)->getType();
  return StateTy->isPointerTy() && PCTy->isIntegerTy(64) &&
         MemoryTy->isPointerTy();
}

static std::optional<ABIReg> RegisterFromGlobalName(Value *V) {
  if (auto *GV = dyn_cast_or_null<GlobalValue>(V)) {
    return RegisterForName(GV->getName());
  }
  return std::nullopt;
}

std::optional<uint64_t> IdentifyStateOffset(Value *Ptr) {
  if (!Ptr) {
    return std::nullopt;
  }

  Value *Stripped = Ptr->stripPointerCasts();
  if (auto Reg = RegisterFromGlobalName(Stripped)) {
    if (const ABIRegisterInfo *Info = GetRegisterInfo(*Reg)) {
      return Info->Offset;
    }
  }

  if (auto *Alias = dyn_cast<GlobalAlias>(Stripped)) {
    if (auto Reg = RegisterForName(Alias->getName())) {
      if (const ABIRegisterInfo *Info = GetRegisterInfo(*Reg)) {
        return Info->Offset;
      }
    }
    if (Constant *Aliasee = Alias->getAliasee()) {
      return IdentifyStateOffset(Aliasee);
    }
  }

  Module *M = FindModule(Stripped);
  if (!M) {
    return std::nullopt;
  }

  const DataLayout &DL = M->getDataLayout();
  APInt Offset(DL.getPointerSizeInBits(0), 0, true);
  Value *Base = Stripped->stripAndAccumulateConstantOffsets(DL, Offset, true);
  if (!Base || Offset.isNegative()) {
    return std::nullopt;
  }

  Base = StripAlias(Base);
  auto *GV = dyn_cast<GlobalValue>(Base);
  if (GV && GV->getName() == "__mcsema_reg_state") {
    return Offset.getZExtValue();
  }

  // After state SSA and ABI preparation, the same guest state is often
  // addressed through the function's first lifted argument (%state) rather
  // than the global.  Treat that argument as a state base only for the
  // canonical McSema three-argument function shape; arbitrary user pointers
  // must not be misclassified as register state.
  if (auto *Arg = dyn_cast<Argument>(Base)) {
    if (IsLiftedStateArgument(Arg)) {
      return Offset.getZExtValue();
    }
  }
  return std::nullopt;
}

std::optional<ABIReg> IdentifyStateRegisterPointer(Value *Ptr) {
  if (!Ptr) {
    return std::nullopt;
  }

  if (auto Reg = RegisterFromGlobalName(Ptr->stripPointerCasts())) {
    return Reg;
  }

  auto Offset = IdentifyStateOffset(Ptr);
  if (!Offset) {
    return std::nullopt;
  }
  return RegisterForOffset(*Offset);
}

std::optional<RegAccess> IdentifyRegAccess(Instruction &I) {
  if (auto *LI = dyn_cast<LoadInst>(&I)) {
    auto Reg = IdentifyStateRegisterPointer(LI->getPointerOperand());
    auto Offset = IdentifyStateOffset(LI->getPointerOperand());
    if (!Reg || !Offset) {
      return std::nullopt;
    }
    RegAccess RA;
    RA.Inst = &I;
    RA.Reg = *Reg;
    RA.IsLoad = true;
    RA.AccessType = LI->getType();
    RA.Value = LI;
    RA.Offset = *Offset;
    return RA;
  }

  if (auto *SI = dyn_cast<StoreInst>(&I)) {
    auto Reg = IdentifyStateRegisterPointer(SI->getPointerOperand());
    auto Offset = IdentifyStateOffset(SI->getPointerOperand());
    if (!Reg || !Offset) {
      return std::nullopt;
    }
    RegAccess RA;
    RA.Inst = &I;
    RA.Reg = *Reg;
    RA.IsStore = true;
    RA.AccessType = SI->getValueOperand()->getType();
    RA.Value = SI->getValueOperand();
    RA.Offset = *Offset;
    return RA;
  }

  return std::nullopt;
}

Value *BuildStateRegisterPointer(IRBuilder<> &B, Value *StateBase, ABIReg Reg) {
  const ABIRegisterInfo *Info = GetRegisterInfo(Reg);
  if (!Info || !StateBase) {
    return nullptr;
  }
  return B.CreateConstGEP1_64(B.getInt8Ty(), StateBase, Info->Offset,
                              (GetRegisterName(Reg) + ".ptr").str());
}

} // namespace brighten_abi
