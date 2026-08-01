#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Transforms/Utils/Local.h"

#include <limits>

namespace brighten_global {
namespace {

using namespace llvm;

struct RangeArm {
  GlobalVariable *GV;
  uint64_t Begin;
  uint64_t End;
};

static bool getGuestRange(GlobalVariable *GV, uint64_t &Begin, uint64_t &End) {
  if (!GV)
    return false;
  MDNode *MD = GV->getMetadata("brighten.guest.range");
  if (!MD || MD->getNumOperands() != 2)
    return false;
  auto *B = dyn_cast<ConstantAsMetadata>(MD->getOperand(0));
  auto *E = dyn_cast<ConstantAsMetadata>(MD->getOperand(1));
  auto *BC = B ? dyn_cast<ConstantInt>(B->getValue()) : nullptr;
  auto *EC = E ? dyn_cast<ConstantInt>(E->getValue()) : nullptr;
  // Resolver addresses are explicitly i64 below.  Do not truncate or assert
  // on malformed metadata: coordinates of another width are not evidence for
  // this resolver and must leave its select/fallback untouched.
  if (!BC || !EC || !BC->getType()->isIntegerTy(64) ||
      !EC->getType()->isIntegerTy(64))
    return false;
  Begin = BC->getZExtValue();
  End = EC->getZExtValue();
  return Begin < End;
}

static bool isRangeCompare(Value *V, ICmpInst::Predicate Predicate,
                           Value *Address, uint64_t Bound) {
  auto *Cmp = dyn_cast<ICmpInst>(V);
  auto *C = Cmp ? dyn_cast<ConstantInt>(Cmp->getOperand(1)) : nullptr;
  return Cmp && C && Cmp->getPredicate() == Predicate &&
         Cmp->getOperand(0) == Address && C->getZExtValue() == Bound;
}

static bool isExactRangeCondition(Value *V, Value *Address, uint64_t Begin,
                                  uint64_t End) {
  auto *And = dyn_cast<BinaryOperator>(V);
  if (And && And->getOpcode() == Instruction::And)
    return (isRangeCompare(And->getOperand(0), ICmpInst::ICMP_UGE, Address,
                         Begin) &&
          isRangeCompare(And->getOperand(1), ICmpInst::ICMP_ULT, Address,
                         End)) ||
         (isRangeCompare(And->getOperand(1), ICmpInst::ICMP_UGE, Address,
                         Begin) &&
          isRangeCompare(And->getOperand(0), ICmpInst::ICMP_ULT, Address,
                         End));

  // The lifter's compact form is `icmp ult (add nsw address, -begin), size`.
  // It is recognized only to establish existing resolver provenance; dynamic
  // instances remain unchanged by this pass.
  auto *Cmp = dyn_cast<ICmpInst>(V);
  auto *Span = Cmp ? dyn_cast<ConstantInt>(Cmp->getOperand(1)) : nullptr;
  auto *Delta = Cmp ? dyn_cast<BinaryOperator>(Cmp->getOperand(0)) : nullptr;
  if (!Cmp || Cmp->getPredicate() != ICmpInst::ICMP_ULT || !Span || !Delta ||
      Span->getZExtValue() != End - Begin)
    return false;
  if (Delta->getOpcode() == Instruction::Sub &&
      Delta->getOperand(0) == Address)
    if (auto *C = dyn_cast<ConstantInt>(Delta->getOperand(1)))
      return C->getZExtValue() == Begin;
  if (Delta->getOpcode() == Instruction::Add) {
    Value *Other = Delta->getOperand(0) == Address ? Delta->getOperand(1)
                                                    : Delta->getOperand(0);
    if (auto *C = dyn_cast<ConstantInt>(Other))
      return C->getValue() == APInt(C->getBitWidth(), 0) -
                                  APInt(C->getBitWidth(), Begin);
  }
  return false;
}

// Verify the selected pointer is exactly i8-GEP(global, address - begin).
// Matching the arithmetic, rather than a generated SSA name, prevents this
// pass from turning an unrelated range guard into a guest resolver.
static bool isExactMappedPointer(Value *V, Value *Address, GlobalVariable *GV,
                                 uint64_t Begin, const DataLayout &DL) {
  auto *GEP = dyn_cast<GetElementPtrInst>(V);
  if (!GEP || !GEP->getSourceElementType()->isIntegerTy(8) ||
      GEP->getNumIndices() != 1 || GEP->getOperand(1) != Address)
    return false;
  auto *PT = dyn_cast<PointerType>(GEP->getPointerOperand()->getType());
  if (!PT || Begin > static_cast<uint64_t>(std::numeric_limits<int64_t>::max()))
    return false;
  APInt Offset(DL.getIndexTypeSizeInBits(PT), 0);
  Value *Base = GEP->getPointerOperand()->stripAndAccumulateConstantOffsets(
      DL, Offset, /*AllowNonInbounds=*/true);
  return Base && Base->stripPointerCasts() == GV && Offset.isSignedIntN(64) &&
         Offset.getSExtValue() == -static_cast<int64_t>(Begin);
}

static bool parseResolver(Value *Pointer, Value *&Address,
                          SmallVectorImpl<RangeArm> &Arms,
                          SmallPtrSetImpl<Value *> &Seen,
                          const DataLayout &DL) {
  if (!Pointer || !Seen.insert(Pointer).second)
    return false;
  if (auto *ITP = dyn_cast<IntToPtrInst>(Pointer)) {
    if (!ITP->getOperand(0)->getType()->isIntegerTy(64))
      return false;
    if (!Address)
      Address = ITP->getOperand(0);
    return Address == ITP->getOperand(0);
  }
  auto *Sel = dyn_cast<SelectInst>(Pointer);
  if (!Sel || !Sel->getType()->isPointerTy())
    return false;
  // The raw inttoptr at the tail is the authority for the one address SSA
  // value shared by every arm.  Parse it first, then prepend this arm so the
  // original outer-select precedence is retained.
  if (!parseResolver(Sel->getFalseValue(), Address, Arms, Seen, DL))
    return false;
  auto *Mapped = dyn_cast<GetElementPtrInst>(Sel->getTrueValue());
  if (!Mapped)
    return false;
  auto *PT = dyn_cast<PointerType>(Mapped->getPointerOperand()->getType());
  if (!PT)
    return false;
  APInt Offset(DL.getIndexTypeSizeInBits(PT), 0);
  Value *Base = Mapped->getPointerOperand()->stripAndAccumulateConstantOffsets(
      DL, Offset, /*AllowNonInbounds=*/true);
  auto *GV = dyn_cast_or_null<GlobalVariable>(
      Base ? Base->stripPointerCasts() : nullptr);
  uint64_t Begin = 0, End = 0;
  if (!getGuestRange(GV, Begin, End) || !Address)
    return false;
  if (!isExactRangeCondition(Sel->getCondition(), Address, Begin, End) ||
      !isExactMappedPointer(Mapped, Address, GV, Begin, DL))
    return false;
  Arms.insert(Arms.begin(), {GV, Begin, End});
  return true;
}

static bool uniqueConstantArm(Value *Address, ArrayRef<RangeArm> Arms,
                              RangeArm &Result) {
  auto *C = dyn_cast<ConstantInt>(Address);
  if (!C)
    return false;
  uint64_t A = C->getZExtValue();
  unsigned Count = 0;
  for (const RangeArm &Arm : Arms)
    if (A >= Arm.Begin && A < Arm.End) {
      Result = Arm;
      ++Count;
    }
  return Count == 1;
}

} // namespace

bool CanonicalizeGuestPointerResolvers(Module &M) {
  SmallVector<SelectInst *, 128> Candidates;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (auto *Sel = dyn_cast<SelectInst>(&I); Sel && Sel->getType()->isPointerTy())
            Candidates.push_back(Sel);

  bool Changed = false;
  SmallPtrSet<SelectInst *, 32> ProtectedNestedSelects;
  // Visit outer roots first.  Dynamic roots are intentionally left byte-for-
  // byte intact; this ordering only avoids considering their inner selects as
  // independent constant candidates.
  for (auto It = Candidates.rbegin(); It != Candidates.rend(); ++It) {
    SelectInst *Root = *It;
    if (!Root->getParent() || Root->use_empty() ||
        ProtectedNestedSelects.contains(Root))
      continue;
    Value *Address = nullptr;
    SmallVector<RangeArm, 8> Arms;
    SmallPtrSet<Value *, 16> Seen;
    if (!parseResolver(Root, Address, Arms, Seen, M.getDataLayout()) ||
        Arms.empty())
      continue;

    IRBuilder<> B(Root);
    RangeArm Unique{};
    if (uniqueConstantArm(Address, Arms, Unique)) {
      Value *Ptr = B.CreateGEP(B.getInt8Ty(), Unique.GV,
                               B.getInt64(cast<ConstantInt>(Address)->getZExtValue() -
                                          Unique.Begin),
                               "native.data.unique.gep");
      Root->replaceAllUsesWith(Ptr);
    } else {
      // A rejected outer resolver owns its nested selects.  Reconsidering an
      // inner arm alone could partially collapse an overlapping resolver and
      // change its precedence/representation despite the root being refused.
      for (Value *Node : Seen)
        if (auto *Nested = dyn_cast<SelectInst>(Node); Nested != Root)
          ProtectedNestedSelects.insert(Nested);
      continue;
    }
    RecursivelyDeleteTriviallyDeadInstructions(Root);
    Changed = true;
  }
  return Changed;
}

} // namespace brighten_global
