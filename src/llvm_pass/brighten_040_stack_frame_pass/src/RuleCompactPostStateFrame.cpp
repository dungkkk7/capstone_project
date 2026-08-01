#include "BrightenStackFramePass.h"

#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"

#include <algorithm>
#include <cstdlib>
#include <cstdint>
#include <limits>
#include <set>
#include <string>

namespace brighten_stack_frame {
namespace {

using namespace llvm;

struct PostStateFrameAccess {
  Instruction *Inst = nullptr;
  unsigned PointerOperand = 0;
  int64_t Begin = 0;
  int64_t End = 0;
  Type *AccessType = nullptr;
  bool Read = false;
  // Write means a definite local store which can initialize a later read.
  bool Write = false;
};

// The creation marker identifies a synthetic object, but does not imply that
// it is fresh for every owner invocation.  015 additionally certifies the
// entry-owner fact with its exact versioned function metadata schema.
static bool hasExactSingleInvocationCapability(GlobalVariable &Backing,
                                               Function &Owner) {
  auto getInt = [](Metadata *MD, unsigned Bits, uint64_t Expected) {
    auto *CI = mdconst::dyn_extract<ConstantInt>(MD);
    return CI && CI->getBitWidth() == Bits && CI->getZExtValue() == Expected;
  };
  auto isExactBinding = [&](MDNode *Record, Value *Expected) {
    if (!Record || Record->getNumOperands() != 2 ||
        !getInt(Record->getOperand(1).get(), 32, 1))
      return false;
    auto *Value = dyn_cast<ValueAsMetadata>(Record->getOperand(0));
    return Value && Value->getValue() == Expected;
  };
  if (!isExactBinding(Backing.getMetadata("brighten.stack.synthetic.created"),
                      &Owner))
    return false;
  MDNode *Capability = Owner.getMetadata("brighten.entry_single_invocation");
  if (!Capability || Capability->getNumOperands() != 2)
    return false;
  auto *Version = dyn_cast<MDString>(Capability->getOperand(0));
  auto *Kind = dyn_cast<MDString>(Capability->getOperand(1));
  if (!Version || !Kind || Version->getString() != "v1" ||
      Kind->getString() != "attach_direct_unique" || Owner.hasAddressTaken())
    return false;
  // 015 refuses recursive owners before emitting the capability.  Keep this
  // local check as a defense against malformed hand-authored metadata.
  for (Instruction &I : instructions(Owner))
    if (auto *CB = dyn_cast<CallBase>(&I))
      if (CB->getCalledFunction() == &Owner)
        return false;
  return true;
}

static bool addOffset(int64_t Base, int64_t Delta, int64_t &Result) {
  if ((Delta > 0 && Base > std::numeric_limits<int64_t>::max() - Delta) ||
      (Delta < 0 && Base < std::numeric_limits<int64_t>::min() - Delta))
    return false;
  Result = Base + Delta;
  return true;
}

// This walk is intentionally more restrictive than a generic pointer
// canonicalizer.  Its only purpose is to prove that a post-State byte backing
// is a local frame.  It does not fold mapper selects, calls, or non-constant
// pointer arithmetic.
class PostStateFrameProof {
public:
  explicit PostStateFrameProof(GlobalVariable &Backing)
      : Backing(Backing), DL(Backing.getParent()->getDataLayout()) {}

  bool prove(SmallVectorImpl<PostStateFrameAccess> &Result,
             Function *&ResultOwner) {
    auto *AT = dyn_cast<ArrayType>(Backing.getValueType());
    if (!AT || !AT->getElementType()->isIntegerTy(8) ||
        !Backing.hasInternalLinkage() || !Backing.hasInitializer() ||
        !Backing.getInitializer()->isNullValue())
      return false;
    ObjectSize = AT->getNumElements();
    if (!ObjectSize ||
        ObjectSize > uint64_t(std::numeric_limits<int64_t>::max()))
      return false;
    if (!walkPointer(&Backing, 0))
      return false;
    if (!Owner || Accesses.empty())
      return false;
    Result.append(Accesses.begin(), Accesses.end());
    ResultOwner = Owner;
    return true;
  }

  ArrayRef<Instruction *> derivedInstructions() const { return Derived; }

private:
  bool claimOwner(Instruction *I) {
    if (!I || !I->getFunction() || (Owner && Owner != I->getFunction()))
      return false;
    Owner = I->getFunction();
    return true;
  }

  bool addAccess(Instruction *I, unsigned PointerOperand, uint64_t Size,
                 Type *AccessType, bool Read, bool Write, int64_t Offset) {
    if (!Size || Size > uint64_t(std::numeric_limits<int64_t>::max()))
      return false;
    int64_t End = 0;
    if (Offset < 0 ||
        !addOffset(Offset, int64_t(Size), End) ||
        uint64_t(End) > ObjectSize || !claimOwner(I))
      return false;
    Accesses.push_back(
        {I, PointerOperand, Offset, End, AccessType, Read, Write});
    return true;
  }

  bool addTypedAccess(Instruction *I, unsigned PointerOperand, Type *Ty,
                      bool Read, bool Write, int64_t Offset) {
    TypeSize Size = DL.getTypeStoreSize(Ty);
    if (Size.isScalable())
      return false;
    return addAccess(I, PointerOperand, Size.getFixedValue(), Ty, Read, Write,
                     Offset);
  }

  // Only intrinsics whose LLVM semantics are exactly memory accesses are
  // modeled here.  A declaration with nocapture alone remains insufficient:
  // it may observe pointer identity or have effects not represented by this
  // pass.  The call operand is recorded in the same plan as load/store so a
  // commit never leaves one path pointing at the global backing.
  bool addKnownCallAccess(CallBase *CB, Value *V, int64_t Offset) {
    auto *MS = dyn_cast<MemSetInst>(CB);
    if (!MS || MS->getRawDest() != V || MS->isVolatile() ||
        !CB->doesNotCapture(0))
      return false;
    auto *Length = dyn_cast<ConstantInt>(MS->getLength());
    if (!Length || !Length->getValue().isSignedIntN(64) ||
        Length->isZero())
      return false;
    return addAccess(MS, 0, Length->getZExtValue(), nullptr, false, true,
                     Offset);
  }

  bool walkPointer(Value *V, int64_t Offset) {
    if (!PointerSeen.insert({V, Offset}).second)
      return true;
    for (User *U : V->users()) {
      if (auto *GEP = dyn_cast<GEPOperator>(U)) {
        if (GEP->getPointerOperand() != V || !GEP->isInBounds())
          return false;
        unsigned Bits = DL.getIndexSizeInBits(GEP->getPointerAddressSpace());
        APInt Delta(Bits, 0, true);
        int64_t Next = 0;
        if (!GEP->accumulateConstantOffset(DL, Delta) ||
            !Delta.isSignedIntN(64) ||
            !addOffset(Offset, Delta.getSExtValue(), Next))
          return false;
        if (auto *I = dyn_cast<Instruction>(U))
          Derived.push_back(I);
        if (!walkPointer(cast<Value>(U), Next))
          return false;
        continue;
      }
      if (auto *BC = dyn_cast<BitCastOperator>(U)) {
        if (BC->getOperand(0) != V)
          return false;
        if (auto *I = dyn_cast<Instruction>(U))
          Derived.push_back(I);
        if (!walkPointer(cast<Value>(U), Offset))
          return false;
        continue;
      }
      // A ptrtoint/inttoptr round trip is not a local-frame proof in LLVM:
      // integer wrapping, pointer provenance, and nsw/nuw poison depend on
      // the concrete pointer representation.  Pointer canonicalization owns
      // that recovery; this pass must leave it untouched.
      if (isa<PtrToIntInst>(U))
        return false;
      if (auto *LI = dyn_cast<LoadInst>(U)) {
        if (LI->getPointerOperand() != V || LI->isVolatile() || LI->isAtomic() ||
            !addTypedAccess(LI, 0, LI->getType(), true, false, Offset))
          return false;
        continue;
      }
      if (auto *SI = dyn_cast<StoreInst>(U)) {
        if (SI->getPointerOperand() != V || SI->getValueOperand() == V ||
            SI->isVolatile() || SI->isAtomic() ||
            !addTypedAccess(SI, 1, SI->getValueOperand()->getType(), false,
                            true, Offset))
          return false;
        continue;
      }
      if (auto *CB = dyn_cast<CallBase>(U)) {
        if (!addKnownCallAccess(CB, V, Offset))
          return false;
        continue;
      }
      return false;
    }
    return true;
  }

  GlobalVariable &Backing;
  const DataLayout &DL;
  uint64_t ObjectSize = 0;
  Function *Owner = nullptr;
  SmallVector<PostStateFrameAccess, 16> Accesses;
  SmallVector<Instruction *, 32> Derived;
  std::set<std::pair<Value *, int64_t>> PointerSeen;
};

static bool hasIncompatibleOverlap(ArrayRef<PostStateFrameAccess> Accesses) {
  for (unsigned I = 0; I < Accesses.size(); ++I) {
    for (unsigned J = I + 1; J < Accesses.size(); ++J) {
      const PostStateFrameAccess &A = Accesses[I];
      const PostStateFrameAccess &B = Accesses[J];
      if (A.End <= B.Begin || B.End <= A.Begin)
        continue;
      // An exact same typed cell has ordinary LLVM aliasing semantics.  Any
      // partial or differently typed overlap could encode a packed alias and
      // is intentionally left for object recovery, not frame localization.
      if (A.Begin != B.Begin || A.End != B.End ||
          (A.AccessType && B.AccessType && A.AccessType != B.AccessType))
        return true;
    }
  }
  return false;
}

// RBP remains architectural state while this traffic is live.  Do not split a
// saved-RBP frame slot away from it.  The state object is recognized by its
// structural byte offset, never by its symbol name.
static bool hasSavedRBPStateTraffic(Function &Owner, GlobalVariable &Backing,
                                    const DataLayout &DL) {
  for (Instruction &I : instructions(Owner)) {
    Value *Ptr = nullptr;
    if (auto *LI = dyn_cast<LoadInst>(&I))
      Ptr = LI->getPointerOperand();
    else if (auto *SI = dyn_cast<StoreInst>(&I))
      Ptr = SI->getPointerOperand();
    if (!Ptr)
      continue;
    auto *PT = dyn_cast<PointerType>(Ptr->getType());
    if (!PT)
      continue;
    APInt Offset(DL.getIndexTypeSizeInBits(PT), 0);
    Value *Base = Ptr->stripAndAccumulateConstantOffsets(
        DL, Offset, /*AllowNonInbounds=*/true);
    if (Base != &Backing && isa<GlobalVariable>(Base) &&
        Offset.isSignedIntN(64) && Offset.getSExtValue() == 2328)
      return true;
  }
  return false;
}

// Commit is permitted only after every backing use is in the planned closure.
// This duplicates the essential use-graph condition at the commit boundary so
// a failed erase cannot leave rewritten accesses pointing at a local object.
static bool hasOnlyPlannedUses(
    Value *V, const SmallPtrSetImpl<Instruction *> &Derived,
    const SmallPtrSetImpl<Instruction *> &Accesses,
    SmallPtrSetImpl<Value *> &Seen) {
  if (!Seen.insert(V).second)
    return true;
  for (User *U : V->users()) {
    if (auto *I = dyn_cast<Instruction>(U)) {
      if (Accesses.contains(I))
        continue;
      if (!Derived.contains(I) || !hasOnlyPlannedUses(I, Derived, Accesses, Seen))
        return false;
      continue;
    }
    auto *C = dyn_cast<Constant>(U);
    if (!C || (!isa<GEPOperator>(C) && !isa<BitCastOperator>(C)) ||
        !hasOnlyPlannedUses(C, Derived, Accesses, Seen))
      return false;
  }
  return true;
}

static bool canEraseAfterPlannedRewrite(
    GlobalVariable &Backing, ArrayRef<Instruction *> Derived,
    ArrayRef<PostStateFrameAccess> Accesses) {
  SmallPtrSet<Instruction *, 32> DerivedSet;
  SmallPtrSet<Instruction *, 32> AccessSet;
  for (Instruction *I : Derived) {
    if (!I || I->mayHaveSideEffects())
      return false;
    DerivedSet.insert(I);
  }
  for (const PostStateFrameAccess &Access : Accesses) {
    if (!Access.Inst || Access.PointerOperand >= Access.Inst->getNumOperands())
      return false;
    AccessSet.insert(Access.Inst);
  }
  SmallPtrSet<Value *, 32> Seen;
  return hasOnlyPlannedUses(&Backing, DerivedSet, AccessSet, Seen);
}

// A global zeroinitializer describes process-lifetime state.  It is not proof
// that an alloca begins zeroed on every invocation: replacing it with an entry
// memset would change repeated-call, recursive, and reentrant behavior.  This
// pass has no documented producer for such a per-invocation lifetime contract,
// so every byte of a read must be covered by a definite dominating write.
static bool readsAreInitialized(ArrayRef<PostStateFrameAccess> Accesses,
                                Function &Owner) {
  DominatorTree DT(Owner);
  for (const PostStateFrameAccess &Read : Accesses) {
    if (!Read.Read)
      continue;
    SmallVector<std::pair<int64_t, int64_t>, 8> Covered;
    for (const PostStateFrameAccess &Write : Accesses) {
      if (!Write.Write || !DT.dominates(Write.Inst, Read.Inst))
        continue;
      int64_t Begin = std::max(Read.Begin, Write.Begin);
      int64_t End = std::min(Read.End, Write.End);
      if (Begin < End)
        Covered.push_back({Begin, End});
    }
    llvm::sort(Covered);
    int64_t Cursor = Read.Begin;
    for (auto [Begin, End] : Covered) {
      if (Begin > Cursor)
        break;
      Cursor = std::max(Cursor, End);
      if (Cursor >= Read.End)
        break;
    }
    if (Cursor < Read.End)
      return false;
  }
  return true;
}

// This is deliberately not a general frame/object recovery walker.  080 owns
// integer-address canonicalization.  040 only consumes the resulting direct
// constant GEP/bitcast path, so ptrtoint affine expressions, PHIs and selects
// remain a refusal rather than becoming a provenance guess here.
static std::optional<int64_t>
getCanonicalBackingOffset(Value *V, GlobalVariable &Backing,
                          const DataLayout &DL) {
  if (V == &Backing)
    return int64_t(0);
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP || !GEP->isInBounds()) {
    if (auto *BC = dyn_cast<BitCastOperator>(V))
      return getCanonicalBackingOffset(BC->getOperand(0), Backing, DL);
    return std::nullopt;
  }
  std::optional<int64_t> Base =
      getCanonicalBackingOffset(GEP->getPointerOperand(), Backing, DL);
  if (!Base)
    return std::nullopt;
  APInt Delta(DL.getIndexSizeInBits(GEP->getPointerAddressSpace()), 0, true);
  int64_t Result = 0;
  if (!GEP->accumulateConstantOffset(DL, Delta) || !Delta.isSignedIntN(64) ||
      !addOffset(*Base, Delta.getSExtValue(), Result))
    return std::nullopt;
  return Result;
}

static Function *getSyntheticBackingOwner(GlobalVariable &Backing) {
  MDNode *Record = Backing.getMetadata("brighten.stack.synthetic.created");
  if (!Record || Record->getNumOperands() != 2)
    return nullptr;
  auto *OwnerMD = dyn_cast<ValueAsMetadata>(Record->getOperand(0));
  auto *Version = mdconst::dyn_extract<ConstantInt>(Record->getOperand(1));
  if (!OwnerMD || !Version || !Version->getType()->isIntegerTy(32) ||
      !Version->isOne())
    return nullptr;
  return dyn_cast<Function>(OwnerMD->getValue());
}

// Unlike whole-frame localization, a single closed pointer cell does not need
// a fresh-object-per-entry capability.  Its old global value is unobservable
// when every load is dominated by a same-invocation store, and the cell's
// address cannot escape the owner.  Keep this proof separate so relaxing the
// slot lifetime never weakens the whole-frame contract.
static bool hasPointerSlotLifetimeOwner(GlobalVariable &Backing,
                                        Function &Owner) {
  if (getSyntheticBackingOwner(Backing) != &Owner || Owner.hasAddressTaken())
    return false;
  for (Instruction &I : instructions(Owner))
    if (auto *CB = dyn_cast<CallBase>(&I))
      if (CB->getCalledFunction() == &Owner)
        return false;
  return true;
}

static bool isKnownPointerConsumer(const CallBase &CB, const Value *V) {
  const Function *Callee = CB.getCalledFunction();
  if (!Callee)
    return false;
  StringRef Name = Callee->getName();
  if (Name == "free" || Name == "strlen")
    return CB.arg_size() >= 1 && CB.getArgOperand(0) == V;
  if (Name == "memcpy" || Name.starts_with("llvm.memcpy"))
    return CB.arg_size() >= 2 &&
           (CB.getArgOperand(0) == V || CB.getArgOperand(1) == V);
  return false;
}

static bool isNullEquality(const ICmpInst &Cmp, const Value *V) {
  if (!Cmp.isEquality())
    return false;
  Value *Other = Cmp.getOperand(0) == V ? Cmp.getOperand(1) :
                 Cmp.getOperand(1) == V ? Cmp.getOperand(0) : nullptr;
  return Other && isa<ConstantInt>(Other) && cast<ConstantInt>(Other)->isZero();
}

static bool isPointerNullEquality(const ICmpInst &Cmp, const Value *V) {
  if (!Cmp.isEquality())
    return false;
  const Value *Other = Cmp.getOperand(0) == V ? Cmp.getOperand(1) :
                       Cmp.getOperand(1) == V ? Cmp.getOperand(0) : nullptr;
  return Other && isa<ConstantPointerNull>(Other);
}

static bool isNullResolverSelect(const SelectInst &SI, const Value *V) {
  if (SI.getType()->isPointerTy() &&
      (SI.getTrueValue() == V || SI.getFalseValue() == V)) {
    const Value *Other = SI.getTrueValue() == V ? SI.getFalseValue() :
                         SI.getTrueValue();
    if (isa<ConstantPointerNull>(Other))
      if (auto *Cmp = dyn_cast<ICmpInst>(SI.getCondition())) {
        // Lifted resolvers normally test the integer load for null and use
        // its inttoptr as the fallback pointer.  Both forms are equivalent
        // only for equality against zero; ordered address predicates remain
        // refused by the load-use closure.
        return isNullEquality(*Cmp, V) ||
               isNullEquality(*Cmp, cast<IntToPtrInst>(V)->getOperand(0));
      }
  }
  return false;
}

static bool pointerUsesAreClosed(IntToPtrInst &I2P) {
  for (User *U : I2P.users()) {
    if (isa<GetElementPtrInst>(U))
      continue;
    if (auto *Cmp = dyn_cast<ICmpInst>(U)) {
      if (isNullEquality(*Cmp, &I2P))
        continue;
    }
    if (auto *SI = dyn_cast<SelectInst>(U)) {
      if (isNullResolverSelect(*SI, &I2P))
        continue;
    }
    if (auto *CB = dyn_cast<CallBase>(U)) {
      if (isKnownPointerConsumer(*CB, &I2P))
        continue;
    }
    return false;
  }
  return true;
}

// The sidecar is not a general integer-pointer recovery.  It recognizes only
// the canonical range resolver shape: `bits +/- C`, unsigned range test, GEP
// arm, and a pointer select chain terminating at known pointer consumers.
// In particular, tags, hashes, ordered comparisons and arithmetic on a
// pointer value stay outside 040.
static bool isResolverRangeCondition(const Value *V, const Value *Root) {
  auto *Cmp = dyn_cast<ICmpInst>(V);
  if (!Cmp || !Cmp->isUnsigned())
    return false;
  const Value *Other = nullptr;
  const Value *Expr = nullptr;
  if (isa<ConstantInt>(Cmp->getOperand(1))) {
    Expr = Cmp->getOperand(0);
    Other = Cmp->getOperand(1);
  } else if (isa<ConstantInt>(Cmp->getOperand(0))) {
    Expr = Cmp->getOperand(1);
    Other = Cmp->getOperand(0);
  }
  if (!Other)
    return false;
  auto *BO = dyn_cast<BinaryOperator>(Expr);
  if (!BO || BO->hasNoSignedWrap() || BO->hasNoUnsignedWrap() ||
      (BO->getOpcode() != Instruction::Add && BO->getOpcode() != Instruction::Sub))
    return false;
  return (BO->getOperand(0) == Root && isa<ConstantInt>(BO->getOperand(1))) ||
         (BO->getOpcode() == Instruction::Add && BO->getOperand(1) == Root &&
          isa<ConstantInt>(BO->getOperand(0)));
}

static bool isResolverPointerClosure(Value *V, const Value *Root,
                                     SmallPtrSetImpl<Value *> &Seen) {
  if (!Seen.insert(V).second)
    return true;
  for (User *U : V->users()) {
    if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
      if (GEP->getPointerOperand() != V || !isResolverPointerClosure(GEP, Root, Seen))
        return false;
      continue;
    }
    if (auto *Sel = dyn_cast<SelectInst>(U)) {
      if (!Sel->getType()->isPointerTy() ||
          (Sel->getTrueValue() != V && Sel->getFalseValue() != V))
        return false;
      // Preserve the ordinary null/fallback resolver exactly.  It is not a
      // range arm, but is already constrained to equality with null and a
      // direct inttoptr fallback by isNullResolverSelect.
      bool IsNullFallback =
          isa<IntToPtrInst>(V) && isNullResolverSelect(*Sel, V);
      if ((!IsNullFallback &&
           !isResolverRangeCondition(Sel->getCondition(), Root)) ||
          !isResolverPointerClosure(Sel, Root, Seen))
        return false;
      continue;
    }
    if (auto *Cmp = dyn_cast<ICmpInst>(U)) {
      if (isPointerNullEquality(*Cmp, V))
        continue;
    }
    if (auto *CB = dyn_cast<CallBase>(U)) {
      if (isKnownPointerConsumer(*CB, V))
        continue;
    }
    return false;
  }
  return true;
}

static bool isResolverIntegerClosure(Value *V, const Value *Root,
                                     SmallPtrSetImpl<Value *> &SeenIntegers,
                                     SmallPtrSetImpl<Value *> &SeenPointers,
                                     bool &NeedsSidecar) {
  if (!SeenIntegers.insert(V).second)
    return true;
  for (User *U : V->users()) {
    if (auto *I2P = dyn_cast<IntToPtrInst>(U)) {
      if (!I2P->getType()->isPointerTy() ||
          cast<PointerType>(I2P->getType())->getAddressSpace() != 0 ||
          !isResolverPointerClosure(I2P, Root, SeenPointers))
        return false;
      continue;
    }
    if (auto *Cmp = dyn_cast<ICmpInst>(U)) {
      if (isNullEquality(*Cmp, V) || isResolverRangeCondition(Cmp, Root))
        continue;
      return false;
    }
    if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
      bool IsIndex = false;
      for (Value *Index : GEP->indices())
        IsIndex |= Index == V;
      if (!IsIndex || !isResolverPointerClosure(GEP, Root, SeenPointers))
        return false;
      NeedsSidecar = true;
      continue;
    }
    auto *BO = dyn_cast<BinaryOperator>(U);
    if (!BO || BO->hasNoSignedWrap() || BO->hasNoUnsignedWrap() ||
        (BO->getOpcode() != Instruction::Add && BO->getOpcode() != Instruction::Sub) ||
        !((BO->getOperand(0) == V && isa<ConstantInt>(BO->getOperand(1))) ||
          (BO->getOpcode() == Instruction::Add && BO->getOperand(1) == V &&
           isa<ConstantInt>(BO->getOperand(0))) ||
          (BO->getOpcode() == Instruction::Sub && BO->getOperand(0) == V &&
           isa<ConstantInt>(BO->getOperand(1)))) ||
        !isResolverIntegerClosure(BO, Root, SeenIntegers, SeenPointers,
                                  NeedsSidecar))
      return false;
    NeedsSidecar = true;
  }
  return true;
}

struct PointerSlotPlan {
  int64_t Offset = 0;
  Function *Owner = nullptr;
  SmallVector<StoreInst *, 4> Stores;
  SmallVector<LoadInst *, 4> Loads;
  Value *UnderlyingObject = nullptr;
  Align Alignment = Align(1);
  SmallPtrSet<LoadInst *, 4> SidecarLoads;
};

// This is intentionally a separate, narrow class from pointer-slot recovery.
// The corpus' next common closed cell is an ordinary i32 local.  Do not infer
// a C type, combine adjacent cells, or use byte storage as a catch-all: an
// exact i32 cell is the alias boundary established by the complete-use scan.
struct ScalarSlotPlan {
  int64_t Offset = 0;
  Type *Ty = nullptr;
  Function *Owner = nullptr;
  SmallVector<StoreInst *, 8> Stores;
  SmallVector<LoadInst *, 8> Loads;
  Align Alignment = Align(1);
  bool NeedsZeroInitialization = false;
};

static bool accessOverlapsSlot(int64_t AccessOffset, uint64_t AccessSize,
                               int64_t SlotOffset, uint64_t SlotSize) {
  int64_t End = 0;
  int64_t SlotEnd = 0;
  return AccessSize <= uint64_t(std::numeric_limits<int64_t>::max()) &&
         SlotSize <= uint64_t(std::numeric_limits<int64_t>::max()) &&
         addOffset(AccessOffset, int64_t(AccessSize), End) &&
         addOffset(SlotOffset, int64_t(SlotSize), SlotEnd) &&
         AccessOffset < SlotEnd && SlotOffset < End;
}

static bool preflightPointerSlot(PointerSlotPlan &Plan,
                                 GlobalVariable &Backing,
                                 const DataLayout &DL) {
  if (!Plan.Owner || !hasPointerSlotLifetimeOwner(Backing, *Plan.Owner))
    return false;
  // The complete slot access set must be exact i64 accesses in the bound
  // owner.  This makes moving just this cell to an alloca alias-neutral with
  // respect to the remaining byte backing.
  for (Function &F : *Backing.getParent()) {
    for (Instruction &I : instructions(F)) {
      Value *Ptr = nullptr;
      Type *Ty = nullptr;
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        Ptr = LI->getPointerOperand();
        Ty = LI->getType();
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        Ptr = SI->getPointerOperand();
        Ty = SI->getValueOperand()->getType();
      } else {
        // Taking the cell address is an escape unless it is the direct,
        // already-accounted-for operand of a load/store.  This includes
        // callbacks, returns, lifetime ambiguity, and stores of the address.
        for (Value *Operand : I.operands()) {
          if (!Operand->getType()->isPointerTy())
            continue;
          if (getCanonicalBackingOffset(Operand, Backing, DL) == Plan.Offset)
            return false;
        }
        continue;
      }
      std::optional<int64_t> Offset = getCanonicalBackingOffset(Ptr, Backing, DL);
      if (!Offset)
        continue;
      TypeSize Size = DL.getTypeStoreSize(Ty);
      if (Size.isScalable() ||
          !accessOverlapsSlot(*Offset, Size.getFixedValue(), Plan.Offset, 8))
        continue;
      if (&F != Plan.Owner || !Ty->isIntegerTy(64) || *Offset != Plan.Offset ||
          Size.getFixedValue() != 8 ||
          (isa<LoadInst>(&I) && (cast<LoadInst>(&I)->isVolatile() ||
                                 cast<LoadInst>(&I)->isAtomic())) ||
          (isa<StoreInst>(&I) && (cast<StoreInst>(&I)->isVolatile() ||
                                  cast<StoreInst>(&I)->isAtomic())))
        return false;
    }
  }
  if (Plan.Stores.empty() || Plan.Loads.empty())
    return false;
  for (StoreInst *SI : Plan.Stores) {
    auto *PTI = dyn_cast<PtrToIntInst>(SI->getValueOperand());
    if (!PTI || !PTI->getType()->isIntegerTy(64) ||
        PTI->getType()->getIntegerBitWidth() != DL.getPointerSizeInBits(0) ||
        cast<PointerType>(PTI->getPointerOperand()->getType())->getAddressSpace() != 0 ||
        !PTI->hasOneUse())
      return false;
    Value *Object = getUnderlyingObject(PTI->getPointerOperand());
    if (!Object || (Plan.UnderlyingObject && Plan.UnderlyingObject != Object))
      return false;
    Plan.UnderlyingObject = Object;
  }
  for (LoadInst *LI : Plan.Loads) {
    SmallPtrSet<Value *, 16> SeenIntegers;
    SmallPtrSet<Value *, 16> SeenPointers;
    bool NeedsSidecar = false;
    if (!isResolverIntegerClosure(LI, LI, SeenIntegers, SeenPointers,
                                  NeedsSidecar))
      return false;
    if (NeedsSidecar)
      Plan.SidecarLoads.insert(LI);
  }
  // A zero-initialized global can be observably read before its first store on
  // a later invocation.  Entry alloca conversion is safe only when a slot
  // store dominates every load in this invocation.
  DominatorTree DT(*Plan.Owner);
  for (LoadInst *LI : Plan.Loads) {
    bool Initialized = false;
    for (StoreInst *SI : Plan.Stores)
      Initialized |= DT.dominates(SI, LI);
    if (!Initialized)
      return false;
  }
  return true;
}

static bool recoverProvenPointerSlots(Module &M) {
  const DataLayout &DL = M.getDataLayout();
  SmallVector<PointerSlotPlan, 8> Plans;
  for (GlobalVariable &Backing : M.globals()) {
    Function *Owner = getSyntheticBackingOwner(Backing);
    if (!Owner || !Backing.hasInternalLinkage())
      continue;
    for (Instruction &I : instructions(*Owner)) {
      auto *SI = dyn_cast<StoreInst>(&I);
      if (!SI || SI->isVolatile() || SI->isAtomic() ||
          !SI->getValueOperand()->getType()->isIntegerTy(64))
        continue;
      std::optional<int64_t> Offset =
          getCanonicalBackingOffset(SI->getPointerOperand(), Backing, DL);
      if (!Offset || *Offset < 0 || (*Offset & 7))
        continue;
      auto *PTI = dyn_cast<PtrToIntInst>(SI->getValueOperand());
      if (!PTI || !PTI->getPointerOperand()->getType()->isPointerTy())
        continue;
      PointerSlotPlan Plan;
      Plan.Offset = *Offset;
      Plan.Owner = Owner;
      Plan.Alignment = SI->getAlign();
      for (Instruction &J : instructions(*Owner)) {
        if (auto *CandidateStore = dyn_cast<StoreInst>(&J)) {
          if (getCanonicalBackingOffset(CandidateStore->getPointerOperand(),
                                        Backing, DL) == Offset)
            Plan.Stores.push_back(CandidateStore);
        } else if (auto *CandidateLoad = dyn_cast<LoadInst>(&J)) {
          if (getCanonicalBackingOffset(CandidateLoad->getPointerOperand(),
                                        Backing, DL) == Offset) {
            Plan.Loads.push_back(CandidateLoad);
            Plan.Alignment = std::max(Plan.Alignment, CandidateLoad->getAlign());
          }
        }
      }
      if (preflightPointerSlot(Plan, Backing, DL))
        Plans.push_back(std::move(Plan));
    }
  }

  bool Changed = false;
  for (unsigned PlanIndex = 0; PlanIndex < Plans.size(); ++PlanIndex) {
    PointerSlotPlan &Plan = Plans[PlanIndex];
    // A second plan for the same slot is harmless only if it is the exact same
    // preflight closure.  Commit it once.
    bool Duplicate = false;
    for (unsigned EarlierIndex = 0; EarlierIndex < PlanIndex; ++EarlierIndex)
      if (Plans[EarlierIndex].Owner == Plan.Owner &&
          Plans[EarlierIndex].Offset == Plan.Offset)
        Duplicate = true;
    if (Duplicate)
      continue;
    IRBuilder<> Entry(&*Plan.Owner->getEntryBlock().getFirstInsertionPt());
    Type *PointerTy = PointerType::getUnqual(M.getContext());
    AllocaInst *Slot = Entry.CreateAlloca(PointerTy,
                                          nullptr, "native.pointer.slot");
    Slot->setAlignment(Plan.Alignment);
    for (StoreInst *SI : Plan.Stores) {
      auto *PTI = cast<PtrToIntInst>(SI->getValueOperand());
      IRBuilder<> B(SI);
      StoreInst *Replacement = B.CreateStore(PTI->getPointerOperand(), Slot);
      Replacement->setAlignment(SI->getAlign());
      Replacement->copyMetadata(*SI);
      SI->eraseFromParent();
      PTI->eraseFromParent();
    }
    for (LoadInst *LI : Plan.Loads) {
      IRBuilder<> B(LI);
      LoadInst *PointerLoad = B.CreateLoad(PointerTy, Slot,
                                           "native.pointer.slot.load");
      PointerLoad->setAlignment(LI->getAlign());
      PointerLoad->copyMetadata(*LI);
      Value *IntegerReplacement = PointerLoad;
      PtrToIntInst *Sidecar = nullptr;
      if (Plan.SidecarLoads.contains(LI)) {
        Sidecar = cast<PtrToIntInst>(B.CreatePtrToInt(
            PointerLoad, LI->getType(), "native.pointer.slot.bits"));
        IntegerReplacement = Sidecar;
      }
      SmallVector<User *, 4> Users(LI->users());
      for (User *U : Users) {
        if (auto *I2P = dyn_cast<IntToPtrInst>(U)) {
          I2P->replaceAllUsesWith(PointerLoad);
          I2P->eraseFromParent();
        } else if (auto *Cmp = dyn_cast<ICmpInst>(U); Cmp && isNullEquality(*Cmp, LI)) {
          Value *Other = Cmp->getOperand(0) == LI ? Cmp->getOperand(1) :
                         Cmp->getOperand(0);
          ICmpInst *Replacement = cast<ICmpInst>(
              B.CreateICmp(Cmp->getPredicate(), PointerLoad,
                           ConstantPointerNull::get(cast<PointerType>(PointerTy))));
          (void)Other;
          Replacement->copyMetadata(*Cmp);
          Cmp->replaceAllUsesWith(Replacement);
          Cmp->eraseFromParent();
        } else {
          // Preflight proved this is only a range-resolver address use.
          U->replaceUsesOfWith(LI, IntegerReplacement);
        }
      }
      LI->eraseFromParent();
    }
    Changed = true;
  }
  return Changed;
}

static bool hasScalarSlotLifetimeOwner(GlobalVariable &Backing,
                                       Function &Owner) {
  // A store dominating every load makes sequential calls independent.  The
  // remaining ownership conditions prevent a recursive or externally invoked
  // activation from observing a different storage duration.
  return hasPointerSlotLifetimeOwner(Backing, Owner);
}

static bool preflightScalarSlot(ScalarSlotPlan &Plan,
                                GlobalVariable &Backing,
                                const DataLayout &DL) {
  if (!Plan.Owner || !Plan.Ty || !Plan.Ty->isIntegerTy() ||
      !(Plan.Ty->isIntegerTy(8) || Plan.Ty->isIntegerTy(16) ||
        Plan.Ty->isIntegerTy(32) || Plan.Ty->isIntegerTy(64)) ||
      !hasScalarSlotLifetimeOwner(Backing, *Plan.Owner) ||
      hasSavedRBPStateTraffic(*Plan.Owner, Backing, DL))
    return false;

  TypeSize PlanSize = DL.getTypeStoreSize(Plan.Ty);
  if (PlanSize.isScalable())
    return false;

  // Prove the complete cell boundary, not merely the accesses found while
  // collecting the candidate.  Any derived address used by a call, return,
  // pointer store, lifetime marker, or a different-width access refuses the
  // entire slot transaction.
  for (Function &F : *Backing.getParent()) {
    for (Instruction &I : instructions(F)) {
      Value *Ptr = nullptr;
      Type *Ty = nullptr;
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        Ptr = LI->getPointerOperand();
        Ty = LI->getType();
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        Ptr = SI->getPointerOperand();
        Ty = SI->getValueOperand()->getType();
      } else {
        for (Value *Operand : I.operands()) {
          if (!Operand->getType()->isPointerTy())
            continue;
          if (getCanonicalBackingOffset(Operand, Backing, DL) == Plan.Offset)
            return false;
        }
        continue;
      }
      std::optional<int64_t> Offset =
          getCanonicalBackingOffset(Ptr, Backing, DL);
      if (!Offset)
        continue;
      TypeSize Size = DL.getTypeStoreSize(Ty);
      if (Size.isScalable() ||
          !accessOverlapsSlot(*Offset, Size.getFixedValue(), Plan.Offset,
                              PlanSize.getFixedValue()))
        continue;
      if (&F != Plan.Owner || *Offset != Plan.Offset ||
          Size.getFixedValue() != PlanSize.getFixedValue() || Ty != Plan.Ty ||
          (isa<LoadInst>(&I) && (cast<LoadInst>(&I)->isVolatile() ||
                                 cast<LoadInst>(&I)->isAtomic())) ||
          (isa<StoreInst>(&I) && (cast<StoreInst>(&I)->isVolatile() ||
                                  cast<StoreInst>(&I)->isAtomic())))
        return false;
    }
  }
  if (Plan.Stores.empty() || Plan.Loads.empty())
    return false;

  DominatorTree DT(*Plan.Owner);
  for (LoadInst *LI : Plan.Loads) {
    bool Initialized = false;
    for (StoreInst *SI : Plan.Stores)
      Initialized |= DT.dominates(SI, LI);
    if (!Initialized)
      Plan.NeedsZeroInitialization = true;
  }
  // A zeroed entry alloca replaces global read-before-write only when the
  // producer's exact single-invocation capability proves the global cannot
  // carry a value from an earlier activation.
  return !Plan.NeedsZeroInitialization ||
         hasExactSingleInvocationCapability(Backing, *Plan.Owner);
}

static void deleteDeadCanonicalPointer(Value *V) {
  auto *I = dyn_cast<Instruction>(V);
  if (I && I->getParent() && isInstructionTriviallyDead(I))
    RecursivelyDeleteTriviallyDeadInstructions(I);
}

static bool recoverProvenScalarSlots(Module &M) {
  const DataLayout &DL = M.getDataLayout();
  SmallVector<ScalarSlotPlan, 32> Plans;
  for (GlobalVariable &Backing : M.globals()) {
    Function *Owner = getSyntheticBackingOwner(Backing);
    if (!Owner || !Backing.hasInternalLinkage())
      continue;
    for (Instruction &I : instructions(*Owner)) {
      auto *SI = dyn_cast<StoreInst>(&I);
      if (!SI || SI->isVolatile() || SI->isAtomic() ||
          !SI->getValueOperand()->getType()->isIntegerTy())
        continue;
      Type *Ty = SI->getValueOperand()->getType();
      if (!(Ty->isIntegerTy(8) || Ty->isIntegerTy(16) ||
            Ty->isIntegerTy(32) || Ty->isIntegerTy(64)))
        continue;
      TypeSize SlotSize = DL.getTypeStoreSize(Ty);
      if (SlotSize.isScalable())
        continue;
      std::optional<int64_t> Offset =
          getCanonicalBackingOffset(SI->getPointerOperand(), Backing, DL);
      if (!Offset || *Offset < 0 ||
          uint64_t(*Offset) % SlotSize.getFixedValue())
        continue;
      ScalarSlotPlan Plan;
      Plan.Offset = *Offset;
      Plan.Ty = Ty;
      Plan.Owner = Owner;
      Plan.Alignment = SI->getAlign();
      for (Instruction &J : instructions(*Owner)) {
        if (auto *CandidateStore = dyn_cast<StoreInst>(&J)) {
          if (CandidateStore->getValueOperand()->getType() == Ty &&
              getCanonicalBackingOffset(CandidateStore->getPointerOperand(),
                                        Backing, DL) == *Offset)
            Plan.Stores.push_back(CandidateStore);
        } else if (auto *CandidateLoad = dyn_cast<LoadInst>(&J)) {
          if (CandidateLoad->getType() == Ty &&
              getCanonicalBackingOffset(CandidateLoad->getPointerOperand(),
                                        Backing, DL) == *Offset) {
            Plan.Loads.push_back(CandidateLoad);
            Plan.Alignment = std::max(Plan.Alignment,
                                      CandidateLoad->getAlign());
          }
        }
      }
      if (preflightScalarSlot(Plan, Backing, DL))
        Plans.push_back(std::move(Plan));
    }
  }

  bool Changed = false;
  for (unsigned Index = 0; Index < Plans.size(); ++Index) {
    ScalarSlotPlan &Plan = Plans[Index];
    bool Duplicate = false;
    for (unsigned Earlier = 0; Earlier < Index; ++Earlier)
      if (Plans[Earlier].Owner == Plan.Owner &&
          Plans[Earlier].Offset == Plan.Offset)
        Duplicate = true;
    if (Duplicate)
      continue;

    IRBuilder<> Entry(&*Plan.Owner->getEntryBlock().getFirstInsertionPt());
    AllocaInst *Slot = Entry.CreateAlloca(Plan.Ty, nullptr,
                                          "native.scalar.slot");
    Slot->setAlignment(Plan.Alignment);
    if (Plan.NeedsZeroInitialization)
      Entry.CreateStore(Constant::getNullValue(Plan.Ty), Slot)
          ->setAlignment(Plan.Alignment);

    SmallVector<Value *, 16> OldPointers;
    for (StoreInst *SI : Plan.Stores) {
      OldPointers.push_back(SI->getPointerOperand());
      SI->setOperand(1, Slot);
    }
    for (LoadInst *LI : Plan.Loads) {
      OldPointers.push_back(LI->getPointerOperand());
      LI->setOperand(0, Slot);
    }
    for (Value *Ptr : OldPointers)
      deleteDeadCanonicalPointer(Ptr);
    Changed = true;
  }
  for (GlobalVariable &Backing : M.globals())
    Backing.removeDeadConstantUsers();
  SmallVector<GlobalVariable *, 8> EmptyBackings;
  for (GlobalVariable &Backing : M.globals())
    if (Backing.use_empty() &&
        Backing.getMetadata("brighten.stack.synthetic.created"))
      EmptyBackings.push_back(&Backing);
  for (GlobalVariable *Backing : EmptyBackings)
    Backing->eraseFromParent();
  return Changed;
}

// Analysis-only audit for the stricter activation-relative subset.  It never
// creates an alloca or rewrites an operand: the records are evidence for a
// future owner, not permission for this pass to materialize a frame.
struct ActivationFrameAudit {
  GlobalVariable &Backing;
  Function &Owner;
  const DataLayout &DL;
  DominatorTree DT;
  SmallVector<PostStateFrameAccess, 16> Accesses;
  SmallPtrSet<Value *, 32> Walked;
  StringRef Blocker = "none";
  Value *Root = nullptr;

  ActivationFrameAudit(GlobalVariable &Backing, Function &Owner)
      : Backing(Backing), Owner(Owner), DL(Backing.getParent()->getDataLayout()),
        DT(Owner) {}

  bool fail(StringRef Why) {
    if (Blocker == "none")
      Blocker = Why;
    return false;
  }

  bool isExactZeroAuditRoot(const GetElementPtrInst &GEP) {
    if (GEP.getPointerOperand() != &Backing ||
        GEP.getPointerAddressSpace() != Backing.getAddressSpace() ||
        DL.isNonIntegralAddressSpace(GEP.getPointerAddressSpace()))
      return false;
    // LLVM 21 exposes inrange on GEPOperator but not GetElementPtrInst.  The
    // printed instruction is the only stable representation available here;
    // reject rather than silently treating an inrange root as a plain one.
    std::string Printed;
    raw_string_ostream OS(Printed);
    GEP.print(OS);
    OS.flush();
    if (StringRef(Printed).contains("inrange"))
      return false;
    APInt Delta(DL.getIndexSizeInBits(GEP.getPointerAddressSpace()), 0, true);
    return GEP.accumulateConstantOffset(DL, Delta) && Delta.isZero();
  }

  bool offsetsFromRoot(Value *V, SmallVectorImpl<int64_t> &Offsets,
                       SmallPtrSetImpl<Value *> &Seen) {
    if (!Seen.insert(V).second)
      return fail("cyclic_pointer");
    if (V == Root) {
      Offsets.push_back(0);
      return true;
    }
    if (auto *GEP = dyn_cast<GEPOperator>(V)) {
      if (!GEP->isInBounds())
        return fail("noncanonical_gep");
      SmallVector<int64_t, 8> Base;
      if (!offsetsFromRoot(GEP->getPointerOperand(), Base, Seen))
        return false;
      APInt Delta(DL.getIndexSizeInBits(GEP->getPointerAddressSpace()), 0,
                  true);
      if (!GEP->accumulateConstantOffset(DL, Delta) ||
          !Delta.isSignedIntN(64))
        return fail("dynamic_offset");
      for (int64_t B : Base) {
        int64_t Next = 0;
        if (!addOffset(B, Delta.getSExtValue(), Next))
          return fail("offset_overflow");
        Offsets.push_back(Next);
      }
    } else if (auto *BC = dyn_cast<BitCastOperator>(V)) {
      if (!offsetsFromRoot(BC->getOperand(0), Offsets, Seen))
        return false;
    } else if (auto *PN = dyn_cast<PHINode>(V)) {
      for (Value *Incoming : PN->incoming_values()) {
        SmallPtrSet<Value *, 16> BranchSeen;
        for (Value *SeenValue : Seen)
          BranchSeen.insert(SeenValue);
        if (!offsetsFromRoot(Incoming, Offsets, BranchSeen))
          return false;
      }
    } else if (auto *SI = dyn_cast<SelectInst>(V)) {
      SmallPtrSet<Value *, 16> TrueSeen;
      SmallPtrSet<Value *, 16> FalseSeen;
      for (Value *SeenValue : Seen) {
        TrueSeen.insert(SeenValue);
        FalseSeen.insert(SeenValue);
      }
      if (!offsetsFromRoot(SI->getTrueValue(), Offsets, TrueSeen) ||
          !offsetsFromRoot(SI->getFalseValue(), Offsets, FalseSeen))
        return false;
    } else {
      return fail("nonroot_pointer");
    }
    llvm::sort(Offsets);
    Offsets.erase(std::unique(Offsets.begin(), Offsets.end()), Offsets.end());
    return Offsets.size() <= 32 || fail("nonfinite_offsets");
  }

  bool addAccess(Instruction &I, unsigned PointerOperand, Value *Ptr,
                 Type *Ty, bool Read, bool Write) {
    if (!I.getFunction() || I.getFunction() != &Owner || !DT.dominates(Root, &I))
      return fail("owner_or_dominance");
    TypeSize Size = DL.getTypeStoreSize(Ty);
    if (Size.isScalable() || Size.getFixedValue() == 0 ||
        Size.getFixedValue() > uint64_t(std::numeric_limits<int64_t>::max()))
      return fail("unsupported_access_size");
    SmallVector<int64_t, 8> Offsets;
    SmallPtrSet<Value *, 16> Seen;
    if (!offsetsFromRoot(Ptr, Offsets, Seen))
      return false;
    for (int64_t Offset : Offsets) {
      int64_t End = 0;
      if (!addOffset(Offset, int64_t(Size.getFixedValue()), End))
        return fail("offset_overflow");
      Accesses.push_back({&I, PointerOperand, Offset, End, Ty, Read, Write});
    }
    return true;
  }

  bool walk(Value *V) {
    if (!Walked.insert(V).second)
      return true;
    for (User *U : V->users()) {
      if (auto *GEP = dyn_cast<GEPOperator>(U)) {
        if (GEP->getPointerOperand() != V || !GEP->isInBounds())
          return fail("noncanonical_gep");
        APInt Delta(DL.getIndexSizeInBits(GEP->getPointerAddressSpace()), 0,
                    true);
        if (!GEP->accumulateConstantOffset(DL, Delta) ||
            !Delta.isSignedIntN(64))
          return fail("dynamic_offset");
        if (!walk(cast<Value>(GEP)))
          return false;
        continue;
      }
      if (auto *BC = dyn_cast<BitCastOperator>(U)) {
        if (BC->getOperand(0) != V || !walk(cast<Value>(BC)))
          return fail("noncanonical_bitcast");
        continue;
      }
      if (auto *PN = dyn_cast<PHINode>(U)) {
        if (!PN->getType()->isPointerTy() || !walk(PN))
          return fail("cross_component_join");
        continue;
      }
      if (auto *SI = dyn_cast<SelectInst>(U)) {
        if (!SI->getType()->isPointerTy() || !walk(SI))
          return fail("cross_component_join");
        continue;
      }
      if (isa<PtrToIntInst>(U) || isa<IntToPtrInst>(U))
        return fail("pointer_integer_observation");
      if (auto *LI = dyn_cast<LoadInst>(U)) {
        if (LI->getPointerOperand() != V || LI->isVolatile() || LI->isAtomic())
          return fail("volatile_or_atomic");
        if (!addAccess(*LI, 0, V, LI->getType(), true, false))
          return false;
        continue;
      }
      if (auto *ST = dyn_cast<StoreInst>(U)) {
        if (ST->getPointerOperand() != V || ST->getValueOperand() == V ||
            ST->isVolatile() || ST->isAtomic())
          return fail("volatile_or_atomic");
        if (!addAccess(*ST, 1, V, ST->getValueOperand()->getType(), false,
                       true))
          return false;
        continue;
      }
      if (auto *MS = dyn_cast<MemSetInst>(U)) {
        auto *Length = dyn_cast<ConstantInt>(MS->getLength());
        if (MS->getRawDest() != V || MS->isVolatile() || !Length ||
            !Length->getValue().isSignedIntN(64) || Length->isZero())
          return fail("unbounded_call");
        if (!addAccess(*MS, 0, V, ArrayType::get(Type::getInt8Ty(Backing.getContext()),
                                                  Length->getZExtValue()),
                       false, true))
          return false;
        continue;
      }
      if (isa<CallBase>(U))
        return fail("call_escape");
      return fail("unsupported_use");
    }
    return true;
  }

  bool run() {
    if (!hasPointerSlotLifetimeOwner(Backing, Owner))
      return fail("lifetime_or_recursion");
    SmallVector<Value *, 4> Roots;
    for (User *U : Backing.users()) {
      auto *I = dyn_cast<Instruction>(U);
      auto *GEP = dyn_cast_or_null<GetElementPtrInst>(I);
      if (!GEP || GEP->getFunction() != &Owner ||
          GEP->getParent() != &Owner.getEntryBlock() ||
          !isExactZeroAuditRoot(*GEP))
        return fail("root_shape");
      Roots.push_back(GEP);
    }
    if (Roots.size() != 1)
      return fail("root_count");
    Root = Roots.front();
    if (!Root->getType()->isPointerTy())
      return fail("root_shape");
    if (!walk(Root) || Accesses.empty())
      return false;
    return true;
  }
};

static void emitActivationFrameAudit(Module &M) {
  for (GlobalVariable &Backing : M.globals()) {
    Function *Owner = getSyntheticBackingOwner(Backing);
    if (!Owner)
      continue;
    ActivationFrameAudit Audit(Backing, *Owner);
    bool Candidate = Audit.run();
    int64_t Lo = 0;
    int64_t Hi = 0;
    Align MaxAlignment = Backing.getAlign().valueOrOne();
    if (!Audit.Accesses.empty()) {
      Lo = Audit.Accesses.front().Begin;
      Hi = Audit.Accesses.front().End;
      for (const PostStateFrameAccess &Access : Audit.Accesses) {
        Lo = std::min(Lo, Access.Begin);
        Hi = std::max(Hi, Access.End);
        if (auto *LI = dyn_cast<LoadInst>(Access.Inst))
          MaxAlignment = std::max(MaxAlignment, LI->getAlign());
        else if (auto *SI = dyn_cast<StoreInst>(Access.Inst))
          MaxAlignment = std::max(MaxAlignment, SI->getAlign());
      }
    }
    StringRef Init = "unknown";
    if (Candidate)
      Init = readsAreInitialized(Audit.Accesses, *Owner)
                 ? "dominating_write"
                 : hasExactSingleInvocationCapability(Backing, *Owner)
                       ? "single_invocation_zero"
                       : "unknown";
    if (Candidate && Init == "unknown") {
      Candidate = false;
      Audit.Blocker = "unknown_init";
    }
    errs() << "activation-frame-audit function=" << Owner->getName()
           << " component=synthetic root=" << (Audit.Root ? "ssa" : "none")
           << " lo=" << Lo << " hi=" << Hi << " span=" << (Hi - Lo)
           << " accesses=" << Audit.Accesses.size()
           << " align=" << MaxAlignment.value() << " init=" << Init
           << " blocker=" << (Candidate ? "none" : Audit.Blocker)
           << " candidate=" << (Candidate ? "true" : "false") << "\n";
  }
}

} // namespace

bool BrightenPostStateFramePass::CompactProvenPostStateFrameBackings(Module &M) {
  if (const char *Audit = std::getenv("BRIGHTEN_ACTIVATION_FRAME_AUDIT");
      Audit && StringRef(Audit) == "1") {
    emitActivationFrameAudit(M);
    return false;
  }
  bool Changed = recoverProvenPointerSlots(M);
  SmallVector<GlobalVariable *, 8> Candidates;
  for (GlobalVariable &GV : M.globals())
    if (GV.getMetadata("brighten.stack.synthetic.created"))
      Candidates.push_back(&GV);

  for (GlobalVariable *Backing : Candidates) {
    // Interprocedural inlining is deliberately not performed before proof.
    // A failed proof must leave an unresolved backing unchanged; otherwise a
    // refusal could still mutate CFG/call boundaries.  A future
    // interprocedural owner must clone/preflight and commit atomically.
    PostStateFrameProof Proof(*Backing);
    SmallVector<PostStateFrameAccess, 16> Accesses;
    Function *Owner = nullptr;
    if (!Proof.prove(Accesses, Owner) || !Owner ||
        !hasExactSingleInvocationCapability(*Backing, *Owner) ||
        hasIncompatibleOverlap(Accesses) ||
        hasSavedRBPStateTraffic(*Owner, *Backing, M.getDataLayout()) ||
        !canEraseAfterPlannedRewrite(*Backing, Proof.derivedInstructions(),
                                     Accesses))
      continue;

    int64_t Min = Accesses.front().Begin;
    int64_t Max = Accesses.front().End;
    Align Alignment = Backing->getAlign().valueOrOne();
    for (const PostStateFrameAccess &Access : Accesses) {
      Min = std::min(Min, Access.Begin);
      Max = std::max(Max, Access.End);
      if (auto *LI = dyn_cast<LoadInst>(Access.Inst))
        Alignment = std::max(Alignment, LI->getAlign());
      else if (auto *SI = dyn_cast<StoreInst>(Access.Inst))
        Alignment = std::max(Alignment, SI->getAlign());
    }
    if (Max <= Min || uint64_t(Max - Min) > 1024 * 1024 ||
        uint64_t(Min) % Alignment.value() != 0)
      continue;

    int64_t FrameSize = std::max<int64_t>(Max - Min + 16384, 65536);
    auto *FrameTy = ArrayType::get(Type::getInt8Ty(M.getContext()), FrameSize);
    IRBuilder<> Entry(&*Owner->getEntryBlock().getFirstInsertionPt());
    AllocaInst *Frame = Entry.CreateAlloca(FrameTy, nullptr, "native_frame");
    Frame->setAlignment(Alignment);
    // Preserve the source global's zero value only when a read can observe it
    // before a definite write.  Otherwise an alloca is left uninitialized.
    if (!readsAreInitialized(Accesses, *Owner))
      Entry.CreateMemSet(Frame, Entry.getInt8(0), uint64_t(Max - Min),
                         Alignment);
    for (const PostStateFrameAccess &Access : Accesses) {
      IRBuilder<> B(Access.Inst);
      Value *Slot = B.CreateGEP(
          FrameTy, Frame, {B.getInt64(0), B.getInt64(Access.Begin - Min)},
          "native.frame.slot");
      Access.Inst->setOperand(Access.PointerOperand, Slot);
    }
    for (Instruction *I : llvm::reverse(Proof.derivedInstructions()))
      if (I->getParent() && isInstructionTriviallyDead(I))
        RecursivelyDeleteTriviallyDeadInstructions(I);
    Backing->removeDeadConstantUsers();
    // canEraseAfterPlannedRewrite establishes this before the first operand
    // rewrite.  Do not turn a violated invariant into a partial transaction.
    assert(Backing->use_empty() && "post-state frame preflight inconsistency");
    Backing->eraseFromParent();
    Changed = true;
  }
  // Prefer whole-object compaction when its stronger proof succeeds.  Scalar
  // localization is the fallback for a backing with unrelated or otherwise
  // non-localizable bytes, so it must not preempt the existing full-frame
  // transaction.
  Changed |= recoverProvenScalarSlots(M);
  return Changed;
}

} // namespace brighten_stack_frame
