#include "BrightenTypeReconstructionPass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"

using namespace llvm;

namespace brighten_type {
namespace {

static bool isIntegralPointer(Type *Ty, const DataLayout &DL) {
  auto *PT = dyn_cast<PointerType>(Ty);
  return PT && !DL.isNonIntegralPointerType(PT);
}

static bool exactPointerRoundTrips(Module &M) {
  const DataLayout &DL = M.getDataLayout();
  SmallVector<IntToPtrInst *, 64> ITPs;
  SmallVector<PtrToIntInst *, 64> PTIs;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F)) {
      if (auto *ITP = dyn_cast<IntToPtrInst>(&I))
        ITPs.push_back(ITP);
      else if (auto *PTI = dyn_cast<PtrToIntInst>(&I))
        PTIs.push_back(PTI);
    }
  }

  bool Changed = false;
  for (IntToPtrInst *ITP : ITPs) {
    if (!ITP->getParent() || !isIntegralPointer(ITP->getType(), DL))
      continue;
    auto *PTI = dyn_cast<PtrToIntInst>(ITP->getOperand(0));
    if (!PTI || !isIntegralPointer(PTI->getPointerOperandType(), DL) ||
        PTI->getPointerOperandType() != ITP->getType())
      continue;
    unsigned PtrBits = DL.getPointerTypeSizeInBits(ITP->getType());
    auto *ITy = dyn_cast<IntegerType>(PTI->getType());
    if (!ITy || ITy->getBitWidth() != PtrBits)
      continue;
    ITP->replaceAllUsesWith(PTI->getPointerOperand());
    ITP->eraseFromParent();
    if (PTI->use_empty())
      PTI->eraseFromParent();
    Changed = true;
  }

  // ptrtoint(inttoptr(iN x)) is exact only for an integral pointer address
  // space and when iN has exactly the pointer width.  Do not canonicalize any
  // arithmetic around the integer: those bits may be intentionally observed.
  for (PtrToIntInst *PTI : PTIs) {
    if (!PTI->getParent())
      continue;
    auto *ITP = dyn_cast<IntToPtrInst>(PTI->getPointerOperand());
    if (!ITP || !isIntegralPointer(ITP->getType(), DL))
      continue;
    auto *SrcTy = dyn_cast<IntegerType>(ITP->getOperand(0)->getType());
    auto *DstTy = dyn_cast<IntegerType>(PTI->getType());
    unsigned PtrBits = DL.getPointerTypeSizeInBits(ITP->getType());
    if (!SrcTy || !DstTy || SrcTy != DstTy || SrcTy->getBitWidth() != PtrBits)
      continue;
    PTI->replaceAllUsesWith(ITP->getOperand(0));
    PTI->eraseFromParent();
    if (ITP->use_empty())
      ITP->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

static void verifyOrDie(Module &M) {
  std::string Error;
  raw_string_ostream OS(Error);
  if (verifyModule(M, &OS))
    report_fatal_error("080 address provenance v2 produced invalid IR:\n" +
                       OS.str());
}

} // namespace

bool RecoverNativePointerIntegerRoundTrips(Module &M,
                                           ModuleAnalysisManager &) {
  bool Changed = exactPointerRoundTrips(M);
  verifyOrDie(M);
  return Changed;
}

bool CanonicalizeAddresses(Module &M, ModuleAnalysisManager &) {
  bool Changed = exactPointerRoundTrips(M);
  verifyOrDie(M);
  return Changed;
}

bool CollapseHeapProvenPointerResolvers(Module &M, ModuleAnalysisManager &) {
  // Resolver collapse is not a type-reconstruction responsibility.  060/070
  // must first turn the allocation/static-image choice into a native pointer;
  // 080 only removes exact representational round trips after that proof.
  verifyOrDie(M);
  return false;
}

} // namespace brighten_type
