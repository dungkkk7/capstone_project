#include "BrightenGlobalDataPass.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include <cctype>
#include <string>

namespace brighten_global_data {

using namespace llvm;

namespace {

static StringRef getRODataBytes(GlobalVariable *GV, uint64_t Offset) {
  if (!GV || !GV->hasInitializer()) {
    return "";
  }

  Constant *Init = GV->getInitializer();
  if (auto *CDA = dyn_cast<ConstantDataArray>(Init)) {
    if (Offset < CDA->getNumElements()) {
      return CDA->getAsString().drop_front(Offset);
    }
    return "";
  }

  auto *CS = dyn_cast<ConstantStruct>(Init);
  if (!CS) {
    return "";
  }

  const DataLayout &DL = GV->getParent()->getDataLayout();
  const StructLayout *SL = DL.getStructLayout(CS->getType());
  for (unsigned I = 0; I < CS->getNumOperands(); ++I) {
    uint64_t ElemOff = SL->getElementOffset(I);
    uint64_t ElemSize = DL.getTypeAllocSize(CS->getOperand(I)->getType());
    if (Offset < ElemOff || Offset >= ElemOff + ElemSize) {
      continue;
    }
    auto *Nested = dyn_cast<ConstantDataArray>(CS->getOperand(I));
    if (!Nested) {
      return "";
    }
    uint64_t LocalOff = Offset - ElemOff;
    if (LocalOff >= Nested->getNumElements()) {
      return "";
    }
    return Nested->getAsString().drop_front(LocalOff);
  }

  return "";
}

static bool isDisplayableCString(StringRef Bytes) {
  if (Bytes.empty()) {
    return false;
  }

  unsigned Printable = 0;
  for (char C : Bytes) {
    if (C == '\0') {
      return Printable >= 2;
    }
    if (std::isprint(static_cast<unsigned char>(C)) || C == '\n' ||
        C == '\r' || C == '\t') {
      ++Printable;
      continue;
    }
    return false;
  }

  return false;
}

static bool isStringLikeGlobal(GlobalVariable *GV) {
  if (!GV || !GV->isConstant()) {
    return false;
  }

  StringRef Name = GV->getName();
  return Name.contains("rodata") || Name.contains("cstring") ||
         Name.contains(".str") || Name.contains("str");
}

static bool matchStringPointer(Value *V, const DataLayout &DL, GlobalVariable *&GV,
                               uint64_t &Offset) {
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP) {
    return false;
  }

  GV = dyn_cast<GlobalVariable>(GEP->getPointerOperand()->stripPointerCasts());
  if (!isStringLikeGlobal(GV)) {
    return false;
  }

  APInt APOffset(64, 0);
  if (!GEP->accumulateConstantOffset(DL, APOffset) || APOffset.isNegative()) {
    return false;
  }

  Offset = APOffset.getZExtValue();
  return true;
}

static Constant *buildRecoveredStringPtr(Module &M, GlobalVariable *SourceGV,
                                         uint64_t Offset, StringRef RawStr,
                                         Type *ExpectedTy) {
  size_t NullTerm = RawStr.find('\0');
  if (NullTerm != StringRef::npos) {
    RawStr = RawStr.substr(0, NullTerm);
  }

  LLVMContext &Ctx = M.getContext();
  Constant *StrInit = ConstantDataArray::getString(Ctx, RawStr, true);
  std::string Name =
      (Twine(".str.recovered.") + SourceGV->getName() + "." + Twine(Offset))
          .str();

  auto *NewGV = M.getGlobalVariable(Name);
  if (!NewGV) {
    NewGV = new GlobalVariable(M, StrInit->getType(), true,
                               GlobalValue::PrivateLinkage, StrInit, Name);
    NewGV->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
  }

  Constant *Zero = ConstantInt::get(Type::getInt64Ty(Ctx), 0);
  Constant *Idxs[] = {Zero, Zero};
  Constant *NewPtr = ConstantExpr::getInBoundsGetElementPtr(
      NewGV->getValueType(), NewGV, ArrayRef<Constant *>(Idxs));
  if (NewPtr->getType() != ExpectedTy) {
    NewPtr = ConstantExpr::getBitCast(NewPtr, ExpectedTy);
  }
  return NewPtr;
}

} // namespace

bool BrightenGlobalDataPass::RecoverGlobalData(Module &M) {
  bool Changed = false;
  for (GlobalVariable &GV : M.globals()) {
    if ((GV.getName().contains("rodata") || GV.getName().contains("cstring")) &&
        !GV.isConstant()) {
      GV.setConstant(true);
      Changed = true;
    }
  }
  return Changed;
}

bool BrightenGlobalDataPass::RecoverStringLiterals(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  SmallVector<GetElementPtrInst *, 16> MaybeDeadGEPs;

  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (Use &U : I.operands()) {
          GlobalVariable *GV = nullptr;
          uint64_t Offset = 0;
          if (!matchStringPointer(U.get(), DL, GV, Offset)) {
            continue;
          }

          StringRef RawStr = getRODataBytes(GV, Offset);
          if (!isDisplayableCString(RawStr)) {
            continue;
          }

          Constant *Recovered =
              buildRecoveredStringPtr(M, GV, Offset, RawStr, U.get()->getType());
          if (auto *GEP = dyn_cast<GetElementPtrInst>(U.get())) {
            MaybeDeadGEPs.push_back(GEP);
          }
          U.set(Recovered);
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

} // namespace brighten_global_data
