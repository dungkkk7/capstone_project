#include "BrightenRepairPass.h"

#include <limits>
#include <optional>

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"

namespace brighten_repair {

using namespace llvm;

namespace {

std::optional<uint64_t> ApplyOffset(uint64_t Base, const APInt &Offset) {
  if (Offset.isNegative()) {
    APInt Magnitude = -Offset;
    uint64_t Delta = Magnitude.getZExtValue();
    if (Delta > Base) {
      return std::nullopt;
    }
    return Base - Delta;
  }
  uint64_t Delta = Offset.getZExtValue();
  if (Delta > std::numeric_limits<uint64_t>::max() - Base) {
    return std::nullopt;
  }
  return Base + Delta;
}

bool IsGuestNamedAddress(GlobalValue *GV) {
  StringRef Name = GV->getName();
  return Name.starts_with("data_") || Name.starts_with("seg_") ||
         Name.starts_with("sub_");
}

bool IsGuestMemoryObject(GlobalVariable &GV) {
  StringRef Name = GV.getName();
  return Name.starts_with("seg_") || Name.starts_with("data_");
}

std::optional<uint64_t> ResolveGuestPointerConstant(Value *Ptr, Module &M,
                                                    bool AllowExternal) {
  Value *DirectBase = Ptr->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalValue>(DirectBase)) {
    if (IsGuestNamedAddress(GV) || AllowExternal) {
      uint64_t GuestAddr = ResolveGuestAddress(GV, M);
      if (GuestAddr != 0) {
        return GuestAddr;
      }
    }
  }

  const DataLayout &DL = M.getDataLayout();
  unsigned PtrBits = DL.getPointerSizeInBits(0);
  if (PtrBits == 0) {
    PtrBits = 64;
  }

  APInt Offset(PtrBits, 0, true);
  Value *Base = Ptr->stripAndAccumulateConstantOffsets(DL, Offset, true);
  Base = Base->stripPointerCasts();

  auto *GV = dyn_cast<GlobalValue>(Base);
  if (!GV) {
    return std::nullopt;
  }
  if (!IsGuestNamedAddress(GV) && !AllowExternal) {
    return std::nullopt;
  }

  uint64_t GuestBase = ResolveGuestAddress(GV, M);
  if (GuestBase == 0) {
    return std::nullopt;
  }

  return ApplyOffset(GuestBase, Offset);
}

std::optional<APInt> EvalBinary(unsigned Opcode, const APInt &L, const APInt &R) {
  switch (Opcode) {
    case Instruction::Add:
      return L + R;
    case Instruction::Sub:
      return L - R;
    case Instruction::Mul:
      return L * R;
    case Instruction::And:
      return L & R;
    case Instruction::Or:
      return L | R;
    case Instruction::Xor:
      return L ^ R;
    case Instruction::Shl:
      return L.shl(R);
    case Instruction::LShr:
      return L.lshr(R);
    case Instruction::AShr:
      return L.ashr(R);
    case Instruction::UDiv:
      if (R.isZero()) return std::nullopt;
      return L.udiv(R);
    case Instruction::SDiv:
      if (R.isZero()) return std::nullopt;
      return L.sdiv(R);
    case Instruction::URem:
      if (R.isZero()) return std::nullopt;
      return L.urem(R);
    case Instruction::SRem:
      if (R.isZero()) return std::nullopt;
      return L.srem(R);
    default:
      return std::nullopt;
  }
}

Constant *FoldGuestAddressConstant(Constant *C, Module &M, bool &Changed,
                                   bool FoldPointerValues,
                                   bool AllowExternal) {
  if (FoldPointerValues && C->getType()->isPointerTy()) {
    if (auto GuestAddr = ResolveGuestPointerConstant(C, M, AllowExternal)) {
      Changed = true;
      auto *IntTy = Type::getInt64Ty(M.getContext());
      return ConstantExpr::getIntToPtr(ConstantInt::get(IntTy, *GuestAddr),
                                       C->getType());
    }
  }

  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    bool LocalChanged = false;
    SmallVector<Constant *, 16> Ops;
    for (unsigned i = 0; i < CS->getNumOperands(); ++i) {
      auto *Op = dyn_cast<Constant>(CS->getOperand(i));
      if (!Op) {
        return C;
      }
      Ops.push_back(FoldGuestAddressConstant(Op, M, LocalChanged,
                                             FoldPointerValues,
                                             AllowExternal));
    }
    if (LocalChanged) {
      Changed = true;
      return ConstantStruct::get(cast<StructType>(CS->getType()), Ops);
    }
    return C;
  }

  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    bool LocalChanged = false;
    SmallVector<Constant *, 16> Ops;
    for (unsigned i = 0; i < CA->getNumOperands(); ++i) {
      auto *Op = dyn_cast<Constant>(CA->getOperand(i));
      if (!Op) {
        return C;
      }
      Ops.push_back(FoldGuestAddressConstant(Op, M, LocalChanged,
                                             FoldPointerValues,
                                             AllowExternal));
    }
    if (LocalChanged) {
      Changed = true;
      return ConstantArray::get(cast<ArrayType>(CA->getType()), Ops);
    }
    return C;
  }

  if (auto *CV = dyn_cast<ConstantVector>(C)) {
    bool LocalChanged = false;
    SmallVector<Constant *, 16> Ops;
    for (unsigned i = 0; i < CV->getNumOperands(); ++i) {
      auto *Op = dyn_cast<Constant>(CV->getOperand(i));
      if (!Op) {
        return C;
      }
      Ops.push_back(FoldGuestAddressConstant(Op, M, LocalChanged,
                                             FoldPointerValues,
                                             AllowExternal));
    }
    if (LocalChanged) {
      Changed = true;
      return ConstantVector::get(Ops);
    }
    return C;
  }

  auto *CE = dyn_cast<ConstantExpr>(C);
  if (!CE) {
    return C;
  }

  if (CE->getOpcode() == Instruction::PtrToInt) {
    if (auto GuestAddr =
            ResolveGuestPointerConstant(CE->getOperand(0), M, AllowExternal)) {
      Changed = true;
      return ConstantInt::get(CE->getType(), *GuestAddr);
    }
    return C;
  }

  if (!CE->getType()->isIntegerTy() || CE->getNumOperands() != 2) {
    return C;
  }

  auto *LConst = dyn_cast<Constant>(CE->getOperand(0));
  auto *RConst = dyn_cast<Constant>(CE->getOperand(1));
  if (!LConst || !RConst) {
    return C;
  }

  bool LocalChanged = false;
  Constant *NewL = FoldGuestAddressConstant(LConst, M, LocalChanged,
                                            FoldPointerValues, AllowExternal);
  Constant *NewR = FoldGuestAddressConstant(RConst, M, LocalChanged,
                                            FoldPointerValues, AllowExternal);
  if (!LocalChanged) {
    return C;
  }

  auto *LI = dyn_cast<ConstantInt>(NewL);
  auto *RI = dyn_cast<ConstantInt>(NewR);
  if (!LI || !RI) {
    Changed = true;
    SmallVector<Constant *, 2> Ops{NewL, NewR};
    return CE->getWithOperands(Ops, CE->getType());
  }

  if (auto Res = EvalBinary(CE->getOpcode(), LI->getValue(), RI->getValue())) {
    Changed = true;
    return ConstantInt::get(CE->getType(), *Res);
  }

  return C;
}

}  // namespace

bool BrightenRepairPass::CanonicalizeGuestAddressConstants(Module &M) {
  bool Changed = false;

  for (GlobalVariable &GV : M.globals()) {
    if (!GV.hasInitializer()) {
      continue;
    }

    bool InitChanged = false;
    Constant *NewInit = FoldGuestAddressConstant(
        GV.getInitializer(), M, InitChanged,
        IsGuestMemoryObject(GV), true);
    if (InitChanged && NewInit != GV.getInitializer()) {
      GV.setInitializer(NewInit);
      Changed = true;
    }
  }

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (Use &U : I.operands()) {
          auto *C = dyn_cast<Constant>(U.get());
          if (!C) {
            continue;
          }

          bool OperandChanged = false;
          Constant *Replacement =
              FoldGuestAddressConstant(C, M, OperandChanged, false, true);
          if (OperandChanged && Replacement != C) {
            U.set(Replacement);
            Changed = true;
          }
        }
      }
    }
  }

  return Changed;
}

}  // namespace brighten_repair
