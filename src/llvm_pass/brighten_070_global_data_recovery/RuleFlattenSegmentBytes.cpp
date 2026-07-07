#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/IR/Constants.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_global {

using namespace llvm;

static bool FlattenConstant(Constant *C, const DataLayout &DL,
                            std::vector<uint8_t> &Bytes,
                            std::map<uint64_t, Constant *> &Relocs,
                            uint64_t CurrentOffset) {
  if (!C)
    return false;

  if (auto *CDA = dyn_cast<ConstantDataArray>(C)) {
    StringRef Raw = CDA->getRawDataValues();
    Bytes.insert(Bytes.end(), Raw.begin(), Raw.end());
    return true;
  }

  if (auto *CAZ = dyn_cast<ConstantAggregateZero>(C)) {
    uint64_t Size = DL.getTypeAllocSize(C->getType());
    Bytes.insert(Bytes.end(), Size, 0);
    return true;
  }

  if (auto *CI = dyn_cast<ConstantInt>(C)) {
    uint64_t Size = DL.getTypeStoreSize(CI->getType());
    APInt Val = CI->getValue();
    for (unsigned I = 0; I < Size; ++I) {
      Bytes.push_back(Val.extractBits(8, I * 8).getZExtValue());
    }
    return true;
  }

  if (auto *CFP = dyn_cast<ConstantFP>(C)) {
    APFloat APF = CFP->getValueAPF();
    APInt API = APF.bitcastToAPInt();
    uint64_t Size = DL.getTypeStoreSize(CFP->getType());
    for (unsigned I = 0; I < Size; ++I) {
      Bytes.push_back(API.extractBits(8, I * 8).getZExtValue());
    }
    return true;
  }

  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    for (unsigned I = 0; I < CA->getNumOperands(); ++I) {
      auto *Elem = cast<Constant>(CA->getOperand(I));
      uint64_t ElemSize = DL.getTypeAllocSize(Elem->getType());
      if (!FlattenConstant(Elem, DL, Bytes, Relocs, CurrentOffset + I * ElemSize))
        return false;
    }
    return true;
  }

  if (auto *CS = dyn_cast<ConstantStruct>(C)) {
    const StructLayout *Layout = DL.getStructLayout(CS->getType());
    uint64_t ExpectedOffset = 0;
    for (unsigned I = 0; I < CS->getNumOperands(); ++I) {
      uint64_t Off = Layout->getElementOffset(I);
      if (Off > ExpectedOffset) {
        Bytes.insert(Bytes.end(), Off - ExpectedOffset, 0); // Padding
      }
      auto *Elem = cast<Constant>(CS->getOperand(I));
      if (!FlattenConstant(Elem, DL, Bytes, Relocs, CurrentOffset + Off))
        return false;
      ExpectedOffset = Off + DL.getTypeAllocSize(Elem->getType());
    }
    uint64_t StructSize = Layout->getSizeInBytes();
    if (StructSize > ExpectedOffset) {
      Bytes.insert(Bytes.end(), StructSize - ExpectedOffset, 0);
    }
    return true;
  }

  // Pointer/relocation constant expressions (e.g. ptrtoint, getelementptr)
  if (auto *CE = dyn_cast<ConstantExpr>(C)) {
    uint64_t Size = DL.getTypeStoreSize(CE->getType());
    Relocs[CurrentOffset] = CE;
    Bytes.insert(Bytes.end(), Size, 0);
    return true;
  }

  if (auto *GV = dyn_cast<GlobalValue>(C)) {
    uint64_t Size = DL.getTypeStoreSize(GV->getType());
    Relocs[CurrentOffset] = GV;
    Bytes.insert(Bytes.end(), Size, 0);
    return true;
  }

  if (isa<UndefValue>(C)) {
    uint64_t Size = DL.getTypeAllocSize(C->getType());
    Bytes.insert(Bytes.end(), Size, 0);
    return true;
  }

  errs() << "unsupported initializer constant: ";
  C->print(errs());
  errs() << "\n";
  return false;
}

bool BrightenGlobalDataRecoveryPass::FlattenSegmentBytes(
    GlobalDataContext &Ctx) {
  bool Changed = false;
  for (auto &Seg : Ctx.Segments) {
    if (!Seg->GV)
      continue;
    Seg->FlatBytes.clear();
    Seg->Relocations.clear();
    if (Seg->GV->hasInitializer()) {
      if (!FlattenConstant(Seg->GV->getInitializer(), Ctx.DL, Seg->FlatBytes, Seg->Relocations, 0)) {
        Seg->SkipReason = "initializer-flatten-unsupported";
        Seg->FlatBytes.clear();
        Seg->Relocations.clear();
        continue;
      }
      if (Seg->FlatBytes.size() < Seg->Size) {
        Seg->FlatBytes.insert(Seg->FlatBytes.end(), Seg->Size - Seg->FlatBytes.size(), 0);
      }
    } else {
      Seg->FlatBytes.assign(Seg->Size, 0);
    }
  }
  return Changed;
}

} // namespace brighten_global
