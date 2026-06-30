#include "BrightenStackFramePass.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include <cctype>
#include <utility>

namespace brighten_stack_frame {

using namespace llvm;

static StringRef getRODataBytes(GlobalVariable *GV, uint64_t Offset) {
  if (!GV->hasInitializer()) return "";
  Constant *Init = GV->getInitializer();

  if (auto *CDA = dyn_cast<ConstantDataArray>(Init)) {
    if (Offset < CDA->getNumElements()) {
      return CDA->getAsString().drop_front(Offset);
    }
  }

  if (auto *CS = dyn_cast<ConstantStruct>(Init)) {
    const DataLayout &DL = GV->getParent()->getDataLayout();
    const StructLayout *SL = DL.getStructLayout(CS->getType());
    for (unsigned i = 0; i < CS->getNumOperands(); ++i) {
      uint64_t ElemOff = SL->getElementOffset(i);
      uint64_t ElemSize = DL.getTypeAllocSize(CS->getOperand(i)->getType());
      if (Offset >= ElemOff && Offset < ElemOff + ElemSize) {
        if (auto *CDA = dyn_cast<ConstantDataArray>(CS->getOperand(i))) {
          uint64_t LocalOff = Offset - ElemOff;
          if (LocalOff < CDA->getNumElements()) {
            return CDA->getAsString().drop_front(LocalOff);
          }
        }
      }
    }
  }

  return "";
}

static bool isDisplayableString(StringRef Str) {
  if (Str.empty()) return false;
  unsigned Printables = 0;
  for (char C : Str) {
    if (C == '\0') return Printables > 1;
    if (std::isprint(static_cast<unsigned char>(C)) || C == '\n' || C == '\r' || C == '\t') {
      Printables++;
    } else {
      return false; // Non-printable character found before null-terminator.
    }
  }
  return false;
}

static bool isStringLikeGlobal(GlobalVariable *GV) {
  if (!GV || !GV->isConstant()) {
    return false;
  }
  StringRef Name = GV->getName();
  return Name.contains("rodata") || Name.contains("cstring") ||
         Name.contains("str") || Name.contains("data");
}

static bool matchStringGEP(Value *V, const DataLayout &DL, GlobalVariable *&GV,
                           uint64_t &OffVal) {
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP) {
    return false;
  }

  Value *PtrOp = GEP->getPointerOperand()->stripPointerCasts();
  GV = dyn_cast<GlobalVariable>(PtrOp);
  if (!isStringLikeGlobal(GV)) {
    return false;
  }

  APInt Offset(64, 0);
  if (!GEP->accumulateConstantOffset(DL, Offset) || Offset.isNegative()) {
    return false;
  }
  OffVal = Offset.getZExtValue();
  return true;
}

static Constant *getRecoveredStringPointer(Module &M, StringRef RawStr,
                                           Type *ExpectedTy) {
  LLVMContext &Ctx = M.getContext();
  size_t NullTerm = RawStr.find('\0');
  if (NullTerm != StringRef::npos) {
    RawStr = RawStr.substr(0, NullTerm);
  }

  Constant *StrConst = ConstantDataArray::getString(Ctx, RawStr, true);
  auto *NewGV = new GlobalVariable(M, StrConst->getType(), true,
                                   GlobalValue::PrivateLinkage, StrConst,
                                   ".str.recovered");
  NewGV->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);

  Constant *Zero = ConstantInt::get(Type::getInt64Ty(Ctx), 0);
  Constant *Idxs[] = {Zero, Zero};
  Constant *NewPtr = ConstantExpr::getInBoundsGetElementPtr(
      NewGV->getValueType(), NewGV, ArrayRef<Constant *>(Idxs));
  if (NewPtr->getType() != ExpectedTy) {
    NewPtr = ConstantExpr::getBitCast(NewPtr, ExpectedTy);
  }
  return NewPtr;
}

bool BrightenStackFramePass::RecoverStrings(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();

  SmallVector<GetElementPtrInst *, 16> MaybeDeadGEPs;

  for (Function &F : M) {
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (Use &U : I.operands()) {
          GlobalVariable *GV = nullptr;
          uint64_t OffVal = 0;
          if (!matchStringGEP(U.get(), DL, GV, OffVal)) {
            continue;
          }

          StringRef RawStr = getRODataBytes(GV, OffVal);
          if (!isDisplayableString(RawStr)) {
            continue;
          }

          Constant *NewPtr = getRecoveredStringPointer(M, RawStr, U.get()->getType());
          if (auto *GEP = dyn_cast<GetElementPtrInst>(U.get())) {
            MaybeDeadGEPs.push_back(GEP);
          }
          U.set(NewPtr);
          Changed = true;
        }
      }
    }
  }

  for (GetElementPtrInst *GEP : MaybeDeadGEPs) {
    if (GEP->use_empty()) {
      GEP->eraseFromParent();
    }
  }

  return Changed;
}

} // namespace brighten_stack_frame
