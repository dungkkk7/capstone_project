#include "BrightenTypeReconstructionPass.h"
#include "TypeReconstructionContext.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_type {

using namespace llvm;

static bool IsByteArrayType(Type *Ty) {
  if (!Ty)
    return false;
  if (auto *ArrTy = dyn_cast<ArrayType>(Ty)) {
    return ArrTy->getElementType()->isIntegerTy(8);
  }
  return false;
}

bool DiscoverCandidates(TypeReconstructionContext &Ctx) {
  unsigned AllocaCount = 0;
  unsigned GlobalCount = 0;

  for (Function &F : Ctx.M) {
    if (F.isDeclaration())
      continue;

    unsigned LocalIndex = 0;
    for (auto &I : instructions(F)) {
      if (auto *AI = dyn_cast<AllocaInst>(&I)) {
        if (!AI->getAllocatedType()->isSized())
          continue;

        // Only reconstruct raw i8 byte arrays!
        if (!IsByteArrayType(AI->getAllocatedType()))
          continue;
        
        uint64_t AllocSize = Ctx.DL.getTypeAllocSize(AI->getAllocatedType()).getFixedValue();
        if (AllocSize == 0)
          continue;

        auto Cand = std::make_unique<ObjectCandidate>();
        Cand->BaseVal = AI;
        Cand->ObjectSize = AllocSize;
        Cand->ABIAlignment = AI->getAlign();
        Cand->AddressSpace = AI->getType()->getAddressSpace();
        Cand->Kind = ObjectKind::Stack;
        Cand->Escaped = false;
        
        std::string Name = AI->getName().str();
        if (Name.empty()) {
          Name = "alloca_" + F.getName().str() + "_" + std::to_string(LocalIndex++);
        }
        Cand->Name = Name;

        Ctx.Candidates.push_back(std::move(Cand));
        AllocaCount++;
      }
    }
  }

  for (GlobalVariable &GV : Ctx.M.globals()) {
    if (!GV.getValueType()->isSized())
      continue;

    // Only reconstruct raw i8 byte arrays!
    if (!IsByteArrayType(GV.getValueType()))
      continue;

    uint64_t AllocSize = Ctx.DL.getTypeAllocSize(GV.getValueType()).getFixedValue();
    if (AllocSize == 0)
      continue;

    auto Cand = std::make_unique<ObjectCandidate>();
    Cand->BaseVal = &GV;
    Cand->ObjectSize = AllocSize;
    Cand->ABIAlignment = GV.getAlign().value_or(Ctx.DL.getABITypeAlign(GV.getValueType()));
    Cand->AddressSpace = GV.getType()->getAddressSpace();
    Cand->Kind = ObjectKind::Global;
    Cand->Escaped = false;
    Cand->Linkage = GV.getLinkage();
    
    std::string Name = GV.getName().str();
    if (Name.empty()) {
      Name = "unnamed_global_" + std::to_string(GlobalCount);
    }
    Cand->Name = Name;

    Ctx.Candidates.push_back(std::move(Cand));
    GlobalCount++;
  }

  Ctx.Report.ObjectsAnalyzed = AllocaCount + GlobalCount;
  return AllocaCount + GlobalCount > 0;
}

} // namespace brighten_type
