#include "BrightenTypeReconstructionPass.h"

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/CFG.h"
#include "llvm/Analysis/CaptureTracking.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/SimplifyQuery.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/ValueHandle.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Transforms/Utils/Local.h"

#include <algorithm>
#include <cstdint>
#include <limits>
#include <memory>
#include <optional>

namespace brighten_type {

using namespace llvm;

namespace {

struct NativeBase {
  Value *Pointer = nullptr;
};

struct AllocaCell {
  AllocaInst *Base = nullptr;
  uint64_t Offset = 0;
  uint64_t Size = 0;
};

static bool Overlaps(uint64_t AOffset, uint64_t ASize, uint64_t BOffset,
                     uint64_t BSize) {
  if (ASize == 0 || BSize == 0)
    return false;
  return AOffset < BOffset + BSize && BOffset < AOffset + ASize;
}

static std::optional<uint64_t> GetFixedStoreSize(Type *Ty,
                                                 const DataLayout &DL) {
  if (!Ty || !Ty->isSized())
    return std::nullopt;
  TypeSize Size = DL.getTypeStoreSize(Ty);
  if (Size.isScalable())
    return std::nullopt;
  return Size.getFixedValue();
}

static std::optional<uint64_t> GetAllocaSize(AllocaInst &AI,
                                             const DataLayout &DL) {
  auto *Count = dyn_cast<ConstantInt>(AI.getArraySize());
  if (!Count || Count->getValue().getActiveBits() > 64)
    return std::nullopt;
  TypeSize ElementSize = DL.getTypeAllocSize(AI.getAllocatedType());
  if (ElementSize.isScalable())
    return std::nullopt;
  uint64_t Bytes = ElementSize.getFixedValue();
  uint64_t Elements = Count->getZExtValue();
  if (Elements != 0 && Bytes > std::numeric_limits<uint64_t>::max() / Elements)
    return std::nullopt;
  return Bytes * Elements;
}

static std::optional<AllocaCell> GetAllocaCell(Value *Pointer, uint64_t Size,
                                               const DataLayout &DL) {
  auto *PointerTy = dyn_cast<PointerType>(Pointer->getType());
  if (!PointerTy)
    return std::nullopt;

  unsigned Width = DL.getIndexTypeSizeInBits(PointerTy);
  APInt Offset(Width, 0);
  Value *Base = Pointer->stripAndAccumulateConstantOffsets(
      DL, Offset, /*AllowNonInbounds=*/true);
  auto *AI = dyn_cast<AllocaInst>(Base);
  if (!AI || Offset.isNegative() || Offset.getActiveBits() > 64)
    return std::nullopt;

  std::optional<uint64_t> AllocationSize = GetAllocaSize(*AI, DL);
  uint64_t ByteOffset = Offset.getZExtValue();
  if (!AllocationSize || ByteOffset > *AllocationSize ||
      Size > *AllocationSize - ByteOffset)
    return std::nullopt;
  return AllocaCell{AI, ByteOffset, Size};
}

static bool HasSameBase(Value *Pointer, AllocaInst *Base,
                        const DataLayout &DL) {
  auto *PointerTy = dyn_cast<PointerType>(Pointer->getType());
  if (!PointerTy)
    return false;
  APInt Offset(DL.getIndexTypeSizeInBits(PointerTy), 0);
  Value *Stripped = Pointer->stripAndAccumulateConstantOffsets(
      DL, Offset, /*AllowNonInbounds=*/true);
  if (Stripped == Base)
    return true;
  return getUnderlyingObject(Pointer) == Base;
}

static bool IsProvenAllocationRoot(Value *Pointer) {
  Pointer = Pointer->stripPointerCasts();
  if (isa<AllocaInst>(Pointer) || isa<GlobalValue>(Pointer))
    return true;

  auto *CB = dyn_cast<CallBase>(Pointer);
  if (!CB || !CB->hasRetAttr(Attribute::NoAlias) ||
      !CB->hasFnAttr(Attribute::AllocSize))
    return false;

  AllocFnKind Kind = CB->getAttributes().getFnAttrs().getAllocKind();
  if (Kind == AllocFnKind::Unknown)
    if (Function *Callee = CB->getCalledFunction())
      Kind = Callee->getAttributes().getFnAttrs().getAllocKind();
  uint64_t KindBits = static_cast<uint64_t>(Kind);
  return (KindBits & static_cast<uint64_t>(AllocFnKind::Alloc)) != 0 &&
         (KindBits & static_cast<uint64_t>(AllocFnKind::Realloc)) == 0;
}

static std::optional<uint64_t> GetAllocationSize(Value *Pointer,
                                                 const DataLayout &DL) {
  Pointer = Pointer->stripPointerCasts();
  if (auto *AI = dyn_cast<AllocaInst>(Pointer))
    return GetAllocaSize(*AI, DL);
  if (auto *GV = dyn_cast<GlobalVariable>(Pointer)) {
    TypeSize Size = DL.getTypeAllocSize(GV->getValueType());
    if (!Size.isScalable())
      return Size.getFixedValue();
    return std::nullopt;
  }

  auto *CB = dyn_cast<CallBase>(Pointer);
  if (!CB)
    return std::nullopt;
  uint64_t AttributeBytes =
      std::max(CB->getRetDereferenceableBytes(),
               CB->getRetDereferenceableOrNullBytes());
  if (AttributeBytes != 0)
    return AttributeBytes;

  Attribute AllocSize = CB->getFnAttr(Attribute::AllocSize);
  if (!AllocSize.isValid())
    return std::nullopt;
  auto [FirstArg, SecondArg] = AllocSize.getAllocSizeArgs();
  if (FirstArg >= CB->arg_size())
    return std::nullopt;
  auto *First = dyn_cast<ConstantInt>(CB->getArgOperand(FirstArg));
  if (!First || First->getValue().getActiveBits() > 64)
    return std::nullopt;
  uint64_t Bytes = First->getZExtValue();
  if (SecondArg) {
    if (*SecondArg >= CB->arg_size())
      return std::nullopt;
    auto *Second = dyn_cast<ConstantInt>(CB->getArgOperand(*SecondArg));
    if (!Second || Second->getValue().getActiveBits() > 64)
      return std::nullopt;
    uint64_t Factor = Second->getZExtValue();
    if (Factor != 0 && Bytes > std::numeric_limits<uint64_t>::max() / Factor)
      return std::nullopt;
    Bytes *= Factor;
  }
  return Bytes;
}

class FunctionPointerRecovery {
public:
  FunctionPointerRecovery(Function &F, const DataLayout &DL, DominatorTree &DT,
                          LoopInfo &LI, ScalarEvolution &SE,
                          AssumptionCache &AC)
      : F(F), DL(DL), DT(DT), LI(LI), SE(SE), AC(AC) {}

  bool run() {
    SmallVector<IntToPtrInst *, 16> Candidates;
    for (Instruction &I : instructions(F))
      if (auto *ITP = dyn_cast<IntToPtrInst>(&I))
        Candidates.push_back(ITP);

    bool Changed = false;
    for (IntToPtrInst *ITP : Candidates)
      Changed |= rewrite(*ITP);
    return Changed;
  }

private:
  Function &F;
  const DataLayout &DL;
  DominatorTree &DT;
  LoopInfo &LI;
  ScalarEvolution &SE;
  AssumptionCache &AC;

  std::optional<NativeBase>
  analyzeBaseInteger(Value *V, SmallPtrSetImpl<Value *> &Active) {
    if (!V->getType()->isIntegerTy() || !Active.insert(V).second)
      return std::nullopt;

    std::optional<NativeBase> Result;
    if (auto *PTI = dyn_cast<PtrToIntInst>(V)) {
      auto *PointerTy =
          cast<PointerType>(PTI->getPointerOperand()->getType());
      unsigned Width = DL.getIndexTypeSizeInBits(PointerTy);
      if (PTI->getType()->getIntegerBitWidth() == Width &&
          !DL.isNonIntegralPointerType(PointerTy) &&
          IsProvenAllocationRoot(PTI->getPointerOperand()))
        Result = NativeBase{PTI->getPointerOperand()};
    } else if (auto *LIInst = dyn_cast<LoadInst>(V)) {
      Result = analyzeSerializedBase(*LIInst, Active);
    }

    Active.erase(V);
    return Result;
  }

  std::optional<NativeBase>
  analyzeSerializedBase(LoadInst &Load,
                        SmallPtrSetImpl<Value *> &Active) {
    if (Load.isVolatile() || Load.isAtomic() ||
        !Load.getType()->isIntegerTy())
      return std::nullopt;
    std::optional<uint64_t> Size = GetFixedStoreSize(Load.getType(), DL);
    if (!Size)
      return std::nullopt;
    std::optional<AllocaCell> Cell =
        GetAllocaCell(Load.getPointerOperand(), *Size, DL);
    if (!Cell || PointerMayBeCaptured(Cell->Base, /*ReturnCaptures=*/true))
      return std::nullopt;

    StoreInst *Source = nullptr;
    std::optional<NativeBase> Provenance;
    for (Instruction &I : instructions(F)) {
      auto *Store = dyn_cast<StoreInst>(&I);
      if (!Store || Store->isVolatile() || Store->isAtomic() ||
          Store->getValueOperand()->getType() != Load.getType())
        continue;
      std::optional<AllocaCell> StoreCell =
          GetAllocaCell(Store->getPointerOperand(), *Size, DL);
      if (!StoreCell || StoreCell->Base != Cell->Base ||
          StoreCell->Offset != Cell->Offset || !DT.dominates(Store, &Load))
        continue;

      std::optional<NativeBase> Candidate =
          analyzeBaseInteger(Store->getValueOperand(), Active);
      if (!Candidate)
        continue;
      if (Source)
        return std::nullopt;
      Source = Store;
      Provenance = Candidate;
    }
    if (!Source || !Provenance)
      return std::nullopt;
    if (hasInterveningClobber(*Cell, *Source, Load))
      return std::nullopt;
    return Provenance;
  }

  bool mayClobberCell(Instruction &I, const AllocaCell &Target) {
    if (auto *Store = dyn_cast<StoreInst>(&I)) {
      std::optional<uint64_t> Size =
          GetFixedStoreSize(Store->getValueOperand()->getType(), DL);
      if (!HasSameBase(Store->getPointerOperand(), Target.Base, DL))
        return false;
      if (!Size)
        return true;
      std::optional<AllocaCell> Cell =
          GetAllocaCell(Store->getPointerOperand(), *Size, DL);
      return !Cell || Overlaps(Cell->Offset, Cell->Size, Target.Offset,
                               Target.Size);
    }
    if (auto *RMW = dyn_cast<AtomicRMWInst>(&I)) {
      std::optional<uint64_t> Size = GetFixedStoreSize(RMW->getValOperand()->getType(), DL);
      if (!HasSameBase(RMW->getPointerOperand(), Target.Base, DL))
        return false;
      std::optional<AllocaCell> Cell = Size ? GetAllocaCell(
                                                RMW->getPointerOperand(), *Size, DL)
                                           : std::nullopt;
      return !Cell || Overlaps(Cell->Offset, Cell->Size, Target.Offset,
                               Target.Size);
    }
    if (auto *CX = dyn_cast<AtomicCmpXchgInst>(&I)) {
      std::optional<uint64_t> Size =
          GetFixedStoreSize(CX->getCompareOperand()->getType(), DL);
      if (!HasSameBase(CX->getPointerOperand(), Target.Base, DL))
        return false;
      std::optional<AllocaCell> Cell = Size ? GetAllocaCell(
                                                CX->getPointerOperand(), *Size, DL)
                                           : std::nullopt;
      return !Cell || Overlaps(Cell->Offset, Cell->Size, Target.Offset,
                               Target.Size);
    }
    if (auto *MI = dyn_cast<MemIntrinsic>(&I)) {
      if (!HasSameBase(MI->getRawDest(), Target.Base, DL))
        return false;
      auto *Length = dyn_cast<ConstantInt>(MI->getLength());
      if (!Length || Length->getValue().getActiveBits() > 64)
        return true;
      std::optional<AllocaCell> Cell = GetAllocaCell(
          MI->getRawDest(), Length->getZExtValue(), DL);
      return !Cell || Overlaps(Cell->Offset, Cell->Size, Target.Offset,
                               Target.Size);
    }
    if (auto *CB = dyn_cast<CallBase>(&I)) {
      if (!CB->mayWriteToMemory())
        return false;
      for (Value *Arg : CB->args())
        if (Arg->getType()->isPointerTy() &&
            HasSameBase(Arg, Target.Base, DL))
          return true;
      return false;
    }
    return I.mayWriteToMemory();
  }

  bool hasInterveningClobber(const AllocaCell &Cell, StoreInst &Source,
                             LoadInst &Load) {
    for (Instruction &I : instructions(F)) {
      if (&I == &Source || !I.mayWriteToMemory() ||
          !mayClobberCell(I, Cell))
        continue;
      if (isPotentiallyReachable(&Source, &I, nullptr, &DT, &LI) &&
          isPotentiallyReachable(&I, &Load, nullptr, &DT, &LI))
        return true;
    }
    return false;
  }

  bool containsPointerInteger(Value *V, SmallPtrSetImpl<Value *> &Visited) {
    if (!Visited.insert(V).second)
      return false;
    if (isa<PtrToIntInst>(V) || isa<IntToPtrInst>(V))
      return true;
    if (auto *I = dyn_cast<Instruction>(V))
      for (Value *Operand : I->operands())
        if (containsPointerInteger(Operand, Visited))
          return true;
    return false;
  }

  bool isAffineOffset(Value *V) {
    SmallPtrSet<Value *, 16> Visited;
    if (containsPointerInteger(V, Visited))
      return false;

    SmallPtrSet<Value *, 16> AffineVisited;
    SmallVector<Value *, 16> Worklist(1, V);
    while (!Worklist.empty()) {
      Value *Current = Worklist.pop_back_val();
      if (!AffineVisited.insert(Current).second || isa<ConstantInt>(Current) ||
          isa<Argument>(Current) || isa<PHINode>(Current) ||
          isa<LoadInst>(Current))
        continue;
      auto *I = dyn_cast<Instruction>(Current);
      if (!I)
        return false;
      switch (I->getOpcode()) {
      case Instruction::Add:
      case Instruction::Sub:
        Worklist.push_back(I->getOperand(0));
        Worklist.push_back(I->getOperand(1));
        break;
      case Instruction::Mul:
        if (!isa<ConstantInt>(I->getOperand(0)) &&
            !isa<ConstantInt>(I->getOperand(1)))
          return false;
        Worklist.push_back(isa<ConstantInt>(I->getOperand(0))
                               ? I->getOperand(1)
                               : I->getOperand(0));
        break;
      case Instruction::Shl:
        if (!isa<ConstantInt>(I->getOperand(1)))
          return false;
        Worklist.push_back(I->getOperand(0));
        break;
      case Instruction::SExt:
      case Instruction::ZExt:
        Worklist.push_back(I->getOperand(0));
        break;
      default:
        return false;
      }
    }
    return true;
  }

  bool getAccessShape(IntToPtrInst &ITP, Type *&ElementType,
                      uint64_t &MaxAccessSize, bool &HasUnknownAccess) {
    ElementType = nullptr;
    MaxAccessSize = 0;
    HasUnknownAccess = false;
    bool SawAccessType = false;
    bool AccessTypesAgree = true;
    for (User *U : ITP.users()) {
      Type *AccessType = nullptr;
      if (auto *Load = dyn_cast<LoadInst>(U)) {
        // This recovery replaces an integer-derived pointer with a GEP.  That
        // is only a representation change for ordinary memory operations.
        // Do not make assumptions about volatile/atomic ordering or about a
        // pointer value that is observed rather than dereferenced.
        if (Load->getPointerOperand() != &ITP || Load->isVolatile() ||
            Load->isAtomic())
          return false;
        AccessType = Load->getType();
      } else if (auto *Store = dyn_cast<StoreInst>(U)) {
        if (Store->getPointerOperand() != &ITP || Store->isVolatile() ||
            Store->isAtomic())
          return false;
        AccessType = Store->getValueOperand()->getType();
      } else {
        // Atomic RMW/CmpXchg, calls, comparisons, casts, and all other uses
        // either have ordering/capture semantics or observe pointer identity.
        return false;
      }

      std::optional<uint64_t> Size = GetFixedStoreSize(AccessType, DL);
      if (!Size)
        return false;
      MaxAccessSize = std::max(MaxAccessSize, *Size);
      if (!SawAccessType) {
        ElementType = AccessType;
        SawAccessType = true;
      } else if (ElementType != AccessType) {
        AccessTypesAgree = false;
      }
    }
    if (!AccessTypesAgree)
      ElementType = nullptr;
    return true;
  }

  // A direct ptrtoint round trip is safe to erase only if the integer bits are
  // exclusively consumed by address construction for this inttoptr.  An
  // integer comparison, store, call, tag operation, or a second derivation
  // makes the address value observable independently of pointer provenance.
  bool hasOnlyAddressConstructionUses(Value *V, const IntToPtrInst &Target,
                                      SmallPtrSetImpl<Value *> &Visited) {
    if (!Visited.insert(V).second)
      return true;
    for (User *U : V->users()) {
      if (U == &Target)
        continue;
      auto *I = dyn_cast<Instruction>(U);
      if (!I || !I->getType()->isIntegerTy())
        return false;
      switch (I->getOpcode()) {
      case Instruction::Add:
      case Instruction::Sub:
      case Instruction::Mul:
      case Instruction::Shl:
      case Instruction::SExt:
      case Instruction::ZExt:
        if (!hasOnlyAddressConstructionUses(I, Target, Visited))
          return false;
        break;
      default:
        return false;
      }
    }
    return true;
  }

  // Serialized pointer slots are validated separately by analyzeSerializedBase.
  // This guard intentionally applies only when the direct incoming expression
  // still contains the ptrtoint producing the recovered base.
  bool hasObservableDirectPointerInteger(Value *Integer,
                                         Value *BasePointer,
                                         const IntToPtrInst &Target,
                                         SmallPtrSetImpl<Value *> &Visited) {
    if (!Visited.insert(Integer).second)
      return false;
    if (auto *PTI = dyn_cast<PtrToIntInst>(Integer)) {
      if (PTI->getPointerOperand()->stripPointerCasts() !=
          BasePointer->stripPointerCasts())
        return true;
      SmallPtrSet<Value *, 16> UseVisited;
      return !hasOnlyAddressConstructionUses(PTI, Target, UseVisited);
    }
    auto *I = dyn_cast<Instruction>(Integer);
    if (!I)
      return false;
    for (Value *Operand : I->operands())
      if (Operand->getType()->isIntegerTy() &&
          hasObservableDirectPointerInteger(Operand, BasePointer, Target,
                                            Visited))
        return true;
    return false;
  }

  // CaptureTracking treats ptrtoint as an escaping use, which is precisely the
  // bridge this pass is proving.  Follow the root's direct pointer uses
  // instead: permit only the bridge, ordinary dereferences, and null checks.
  // Any other pointer propagation can expose identity or capture the root.
  bool hasCaptureOrIdentityObservation(Value *V,
                                       SmallPtrSetImpl<Value *> &Visited) {
    if (!Visited.insert(V).second)
      return false;
    for (User *U : V->users()) {
      if (isa<PtrToIntInst>(U))
        continue;
      if (auto *Cast = dyn_cast<CastInst>(U)) {
        if (Cast->getType()->isPointerTy() &&
            !hasCaptureOrIdentityObservation(Cast, Visited))
          continue;
        return true;
      }
      if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
        if (!hasCaptureOrIdentityObservation(GEP, Visited))
          continue;
        return true;
      }
      if (auto *Load = dyn_cast<LoadInst>(U)) {
        if (Load->getPointerOperand() == V)
          continue;
        return true;
      }
      if (auto *Store = dyn_cast<StoreInst>(U)) {
        if (Store->getPointerOperand() == V)
          continue;
        return true;
      }
      if (auto *Cmp = dyn_cast<ICmpInst>(U)) {
        Value *Other = Cmp->getOperand(0) == V ? Cmp->getOperand(1)
                                                : Cmp->getOperand(0);
        if (isa<ConstantPointerNull>(Other))
          continue;
        return true;
      }
      return true;
    }
    return false;
  }

  bool proveInObject(Value *Base, Value *Offset, uint64_t AccessSize,
                     bool HasUnknownAccess, IntToPtrInst &ITP) {
    if (!Offset)
      return true;
    if (HasUnknownAccess || AccessSize == 0)
      return false;
    std::optional<uint64_t> ObjectSize = GetAllocationSize(Base, DL);
    if (!ObjectSize)
      return false;

    const SCEV *OffsetExpr = SE.getSCEV(Offset);
    ConstantRange Range = SE.getSignedRange(OffsetExpr);
    if (Range.isFullSet())
      return false;
    APInt Min = Range.getSignedMin();
    APInt Max = Range.getSignedMax();
    if (Min.isNegative() || Max.isNegative() || Max.getActiveBits() > 64)
      return false;
    uint64_t MaxOffset = Max.getZExtValue();
    if (MaxOffset > *ObjectSize || AccessSize > *ObjectSize - MaxOffset)
      return false;

    SimplifyQuery SQ(DL, &DT, &AC, &ITP);
    return MaxOffset == 0 || isKnownNonZero(Base, SQ);
  }

  bool rewrite(IntToPtrInst &ITP) {
    auto *ResultPointerTy = cast<PointerType>(ITP.getType());
    if (DL.isNonIntegralPointerType(ResultPointerTy) ||
        !ITP.getOperand(0)->getType()->isIntegerTy(
            DL.getIndexTypeSizeInBits(ResultPointerTy)))
      return false;

    Value *Integer = ITP.getOperand(0);
    Value *Offset = nullptr;
    std::optional<NativeBase> Base;
    SmallPtrSet<Value *, 16> Active;
    Base = analyzeBaseInteger(Integer, Active);

    if (!Base) {
      auto *BO = dyn_cast<BinaryOperator>(Integer);
      if (!BO || (BO->getOpcode() != Instruction::Add &&
                  BO->getOpcode() != Instruction::Sub))
        return false;

      Active.clear();
      Base = analyzeBaseInteger(BO->getOperand(0), Active);
      if (Base && isAffineOffset(BO->getOperand(1))) {
        if (BO->getOpcode() == Instruction::Sub)
          return false;
        Offset = BO->getOperand(1);
      } else if (BO->getOpcode() == Instruction::Add) {
        Active.clear();
        Base = analyzeBaseInteger(BO->getOperand(1), Active);
        if (Base && isAffineOffset(BO->getOperand(0)))
          Offset = BO->getOperand(0);
        else
          Base.reset();
      } else {
        Base.reset();
      }
    }
    if (!Base)
      return false;
    auto *BasePointerTy = dyn_cast<PointerType>(Base->Pointer->getType());
    if (!BasePointerTy || BasePointerTy->getAddressSpace() !=
                              ResultPointerTy->getAddressSpace())
      return false;

    // The provenance proof is intentionally stronger than dereferenceability:
    // an escaping root can participate in alias/callback behaviour that a
    // typed GEP must not silently re-model.  Null checks are allowed because
    // they do not observe a non-null pointer's identity.
    SmallPtrSet<Value *, 16> PointerVisited;
    if (hasCaptureOrIdentityObservation(Base->Pointer, PointerVisited))
      return false;
    SmallPtrSet<Value *, 16> IntegerVisited;
    if (hasObservableDirectPointerInteger(Integer, Base->Pointer, ITP,
                                          IntegerVisited))
      return false;

    Type *ElementType = nullptr;
    uint64_t AccessSize = 0;
    bool HasUnknownAccess = false;
    if (!getAccessShape(ITP, ElementType, AccessSize, HasUnknownAccess) ||
        !proveInObject(Base->Pointer, Offset, AccessSize, HasUnknownAccess,
                       ITP))
      return false;

    IRBuilder<> Builder(&ITP);
    Value *Recovered = Base->Pointer;
    if (Offset) {
      Type *GEPType = Type::getInt8Ty(F.getContext());
      Value *Index = Offset;
      if (ElementType) {
        uint64_t ElementSize = *GetFixedStoreSize(ElementType, DL);
        APInt Multiple = SE.getConstantMultiple(SE.getSCEV(Offset));
        if (ElementSize != 0 &&
            Multiple.urem(APInt(Multiple.getBitWidth(), ElementSize)).isZero()) {
          GEPType = ElementType;
          if (ElementSize != 1)
            Index = Builder.CreateExactSDiv(
                Offset, ConstantInt::get(Offset->getType(), ElementSize),
                "brighten.native.index");
        }
      }
      Recovered = Builder.CreateGEP(GEPType, Base->Pointer, Index,
                                    "brighten.native.gep");
    }

    ITP.replaceAllUsesWith(Recovered);
    ITP.eraseFromParent();
    return true;
  }
};

// This is deliberately narrower than the generic guest resolver pass.  It
// does not infer objects from numeric addresses.  Instead, it recognizes an
// already-validated static-image resolver and proves that its fallback is a
// fresh allocation object, whose provenance cannot be any GlobalVariable arm.
class HeapProvenResolverCollapse {
public:
  HeapProvenResolverCollapse(Function &F, const DataLayout &DL,
                             DominatorTree &DT, AssumptionCache &AC)
      : F(F), DL(DL), DT(DT), AC(AC) {}

  bool run() {
    SmallVector<SelectInst *, 32> Candidates;
    for (Instruction &I : instructions(F))
      if (auto *Sel = dyn_cast<SelectInst>(&I); Sel && Sel->getType()->isPointerTy())
        Candidates.push_back(Sel);

    SmallVector<Plan, 16> Plans;
    SmallPtrSet<Value *, 32> ResolverNodes;
    for (auto It = Candidates.rbegin(); It != Candidates.rend(); ++It) {
      Plan P;
      SmallPtrSet<Value *, 32> Seen;
      if (!parseResolver(**It, P, Seen) || P.Arms.empty() ||
          !nonOverlapping(P.Arms))
        continue;
      collectResolverNodes(P.Root, P.Address, ResolverNodes);
      Plans.push_back(std::move(P));
    }

    struct ReadyPlan {
      Plan *Resolver;
      Value *Heap;
    };
    SmallVector<ReadyPlan, 16> Ready;
    for (Plan &P : Plans) {
      if (!P.Root->getParent() || P.Root->use_empty() ||
          !addressHasNoTagOrComparisonObservation(P.Address, ResolverNodes))
        continue;
      Value *Heap = nullptr;
      // A nullable allocation is safe only when the exact range predicates
      // prove that integer zero cannot select a static arm.  The fallback is
      // then the original pointer value, so replacing the resolver with the
      // allocation preserves its null result as well.
      if (!matchHeapFallback(P, Heap) ||
          (!isKnownNonNull(Heap, P.Root) && !P.NullFallsThrough) ||
          rootHasForbiddenUse(Heap, P))
        continue;
      Ready.push_back({&P, Heap});
    }

    bool Changed = false;
    for (const ReadyPlan &Prepared : Ready) {
      Plan &P = *Prepared.Resolver;
      Value *Heap = Prepared.Heap;
      if (!P.Root->getParent())
        continue;

      IRBuilder<> B(P.Root);
      Value *Replacement = Heap;
      if (P.Address != P.BaseInteger) {
        // Keep the original integer computation live in the new GEP index.
        // This preserves poison from flagged add/sub and modulo index bits;
        // importantly, this is not an inbounds GEP.
        Value *Index = B.CreateSub(P.Address, P.BaseInteger,
                                   "brighten.heap.index");
        Replacement = B.CreateGEP(B.getInt8Ty(), Heap, Index,
                                  "brighten.heap.gep");
      }
      P.Root->replaceAllUsesWith(Replacement);
      RecursivelyDeleteTriviallyDeadInstructions(P.Root);
      Changed = true;
    }
    return Changed;
  }

private:
  struct Arm {
    GlobalVariable *Global = nullptr;
    uint64_t Begin = 0;
    uint64_t End = 0;
  };
  struct Plan {
    SelectInst *Root = nullptr;
    Value *Address = nullptr;
    Value *Fallback = nullptr;
    Value *BaseInteger = nullptr;
    bool NullFallsThrough = false;
    SmallVector<SelectInst *, 8> Selects;
    SmallVector<Arm, 8> Arms;
  };

  Function &F;
  const DataLayout &DL;
  DominatorTree &DT;
  AssumptionCache &AC;

  static bool guestRange(GlobalVariable *GV, uint64_t &Begin, uint64_t &End) {
    MDNode *Range = GV ? GV->getMetadata("brighten.guest.range") : nullptr;
    if (!Range || Range->getNumOperands() != 2)
      return false;
    auto *B = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
    auto *E = dyn_cast<ConstantAsMetadata>(Range->getOperand(1));
    auto *BC = B ? dyn_cast<ConstantInt>(B->getValue()) : nullptr;
    auto *EC = E ? dyn_cast<ConstantInt>(E->getValue()) : nullptr;
    if (!BC || !EC)
      return false;
    Begin = BC->getZExtValue();
    End = EC->getZExtValue();
    return Begin < End;
  }

  static bool exactRangeCondition(Value *V, Value *Address, uint64_t Begin,
                                  uint64_t End) {
    auto *Cmp = dyn_cast<ICmpInst>(V);
    auto *Span = Cmp ? dyn_cast<ConstantInt>(Cmp->getOperand(1)) : nullptr;
    auto *Delta = Cmp ? dyn_cast<BinaryOperator>(Cmp->getOperand(0)) : nullptr;
    if (Cmp && Cmp->getPredicate() == ICmpInst::ICMP_ULT && Span && Delta &&
        Span->getZExtValue() == End - Begin) {
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
    }
    // Lifter alignment form: `(address & -span) == begin`.  This denotes the
    // exact half-open range only for an aligned power-of-two span, never a
    // general address mask/tag test.
    if (Cmp && Cmp->getPredicate() == ICmpInst::ICMP_EQ &&
        isPowerOf2_64(End - Begin) && Begin % (End - Begin) == 0) {
      auto *Mask = dyn_cast<BinaryOperator>(Cmp->getOperand(0));
      auto *Expected = dyn_cast<ConstantInt>(Cmp->getOperand(1));
      if (Mask && Mask->getOpcode() == Instruction::And && Expected &&
          Expected->getZExtValue() == Begin) {
        Value *Other = Mask->getOperand(0) == Address ? Mask->getOperand(1)
                                                       : Mask->getOperand(0);
        if (auto *C = dyn_cast<ConstantInt>(Other))
          return C->getValue() ==
                 APInt(C->getBitWidth(), 0) - APInt(C->getBitWidth(), End - Begin);
      }
    }
    return false;
  }

  bool mappedStaticArm(Value *V, Value *&Address, Arm &Result) const {
    auto *GEP = dyn_cast<GetElementPtrInst>(V);
    if (!GEP || !GEP->getSourceElementType()->isIntegerTy(8) ||
        GEP->getNumIndices() != 1)
      return false;
    Value *Index = GEP->getOperand(1);
    auto *PT = dyn_cast<PointerType>(GEP->getPointerOperand()->getType());
    if (!PT)
      return false;

    // 040 preserves the host-pointer sidecar but may leave an equivalent
    // relocation form as `(global + address) - guest_begin`.  Match that
    // pair structurally; do not infer an object from a numeric address.
    if (auto *Inner = dyn_cast<GetElementPtrInst>(GEP->getPointerOperand())) {
      if (!Inner->getSourceElementType()->isIntegerTy(8) ||
          Inner->getNumIndices() != 1)
        return false;
      auto *Delta = dyn_cast<ConstantInt>(Index);
      if (!Delta || !Delta->getValue().isSignedIntN(64))
        return false;
      auto *InnerPT = dyn_cast<PointerType>(
          Inner->getPointerOperand()->getType());
      if (!InnerPT || InnerPT->getAddressSpace() != PT->getAddressSpace())
        return false;
      APInt InnerOffset(DL.getIndexTypeSizeInBits(InnerPT), 0);
      Value *InnerBase = Inner->getPointerOperand()
                             ->stripAndAccumulateConstantOffsets(
                                 DL, InnerOffset,
                                 /*AllowNonInbounds=*/true);
      auto *GV = dyn_cast_or_null<GlobalVariable>(
          InnerBase ? InnerBase->stripPointerCasts() : nullptr);
      uint64_t Begin = 0, End = 0;
      if (!GV || !guestRange(GV, Begin, End) || !InnerOffset.isZero() ||
          Begin > static_cast<uint64_t>(
                      std::numeric_limits<int64_t>::max()) ||
          Delta->getSExtValue() != -static_cast<int64_t>(Begin) ||
          (Address && Address != Inner->getOperand(1)))
        return false;
      Address = Inner->getOperand(1);
      Result = {GV, Begin, End};
      return true;
    }

    if (Address && Address != Index)
      return false;
    APInt Offset(DL.getIndexTypeSizeInBits(PT), 0);
    Value *Base = GEP->getPointerOperand()->stripAndAccumulateConstantOffsets(
        DL, Offset, /*AllowNonInbounds=*/true);
    auto *GV = dyn_cast_or_null<GlobalVariable>(
        Base ? Base->stripPointerCasts() : nullptr);
    uint64_t Begin = 0, End = 0;
    if (!GV || !guestRange(GV, Begin, End) || !Offset.isSignedIntN(64) ||
        Begin > static_cast<uint64_t>(std::numeric_limits<int64_t>::max()) ||
        Offset.getSExtValue() != -static_cast<int64_t>(Begin))
      return false;
    Address = Index;
    Result = {GV, Begin, End};
    return true;
  }

  bool parseResolver(SelectInst &Sel, Plan &P,
                     SmallPtrSetImpl<Value *> &Seen) const {
    if (!Seen.insert(&Sel).second)
      return false;
    if (auto *Inner = dyn_cast<SelectInst>(Sel.getFalseValue())) {
      if (!parseResolver(*Inner, P, Seen))
        return false;
    } else {
      P.Fallback = Sel.getFalseValue();
    }

    Arm A;
    if (!mappedStaticArm(Sel.getTrueValue(), P.Address, A) || !P.Address)
      return false;
    P.Selects.push_back(&Sel);
    P.Arms.push_back(A);
    P.Root = &Sel;
    return true;
  }

  static bool nonOverlapping(ArrayRef<Arm> Arms) {
    for (unsigned I = 0; I < Arms.size(); ++I)
      for (unsigned J = I + 1; J < Arms.size(); ++J)
        if (Arms[I].Begin < Arms[J].End && Arms[J].Begin < Arms[I].End) {
          // A single enclosing image arm is a structural residual fallback,
          // not competing object recovery.  Partial overlap remains
          // ambiguous and is refused.
          bool IContainsJ = Arms[I].Begin <= Arms[J].Begin &&
                            Arms[J].End <= Arms[I].End;
          bool JContainsI = Arms[J].Begin <= Arms[I].Begin &&
                            Arms[I].End <= Arms[J].End;
          if (!IContainsJ && !JContainsI)
            return false;
        }
    return true;
  }

  bool matchHeapFallback(Plan &P, Value *&Heap) const {
    Value *BaseInteger = nullptr;
    auto findBaseInteger = [&](Value *Address) -> Value * {
      if (recoverIntegerPointerRoot(Address))
        return Address;
      auto *BO = dyn_cast<BinaryOperator>(Address);
      if (!BO || (BO->getOpcode() != Instruction::Add &&
                  BO->getOpcode() != Instruction::Sub))
        return nullptr;
      if (recoverIntegerPointerRoot(BO->getOperand(0)))
        return BO->getOperand(0);
      if (BO->getOpcode() == Instruction::Add &&
          recoverIntegerPointerRoot(BO->getOperand(1)))
        return BO->getOperand(1);
      return nullptr;
    };
    BaseInteger = findBaseInteger(P.Address);
    Value *Base = recoverIntegerPointerRoot(BaseInteger);
    if (!Base || !IsProvenAllocationRoot(Base))
      return false;
    auto *PointerTy = dyn_cast<PointerType>(Base->getType());
    if (!PointerTy || DL.isNonIntegralPointerType(PointerTy) ||
        !BaseInteger->getType()->isIntegerTy() ||
        cast<IntegerType>(BaseInteger->getType())->getBitWidth() !=
            DL.getIndexTypeSizeInBits(PointerTy))
      return false;
    P.BaseInteger = BaseInteger;
    if (!conditionsUseOnlyHeapAddress(P))
      return false;
    // The post-040 sidecar retains the original pointer as fallback.  Older
    // input may still carry inttoptr(address); both are representation-only
    // after the same provenance proof.
    if (auto *PTI = dyn_cast<PtrToIntOperator>(BaseInteger);
        PTI && P.Fallback == PTI->getPointerOperand() &&
        P.Address == BaseInteger) {
      Heap = Base;
      P.NullFallsThrough = staticArmsExcludeNull(P);
      return true;
    }
    auto *ITP = dyn_cast<IntToPtrInst>(P.Fallback);
    if (!ITP || ITP->getOperand(0) != P.Address ||
        ITP->getType()->getPointerAddressSpace() != PointerTy->getAddressSpace())
      return false;
    Heap = Base;
    P.NullFallsThrough = P.Address == BaseInteger && staticArmsExcludeNull(P);
    return true;
  }

  // A raw pointer-sized slot is accepted only when it is a single-definition
  // serialization of a proven allocation root.  The integer load itself is
  // intentionally retained: this proof changes only the resolver's object
  // choice, never an observable ptrtoint value or its poison/undef behavior.
  Value *recoverSerializedIntegerSlotRoot(
      LoadInst &Load, SmallPtrSetImpl<Value *> &Active) const {
    if (Load.isVolatile() || Load.isAtomic() || !Load.getType()->isIntegerTy())
      return nullptr;
    auto *PointerTy = dyn_cast<PointerType>(Load.getPointerOperand()->getType());
    if (!PointerTy || DL.isNonIntegralPointerType(PointerTy) ||
        Load.getType()->getIntegerBitWidth() !=
            DL.getIndexTypeSizeInBits(PointerTy))
      return nullptr;
    std::optional<uint64_t> Size = GetFixedStoreSize(Load.getType(), DL);
    if (!Size)
      return nullptr;
    std::optional<AllocaCell> Cell =
        GetAllocaCell(Load.getPointerOperand(), *Size, DL);
    if (!Cell || !Cell->Base->isStaticAlloca() ||
        PointerMayBeCaptured(Cell->Base, /*ReturnCaptures=*/true))
      return nullptr;

    StoreInst *Source = nullptr;
    for (Instruction &I : instructions(F)) {
      Value *AccessPointer = nullptr;
      uint64_t AccessSize = 0;
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        AccessPointer = LI->getPointerOperand();
        auto Size = GetFixedStoreSize(LI->getType(), DL);
        if (!Size)
          return nullptr;
        AccessSize = *Size;
      } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
        AccessPointer = SI->getPointerOperand();
        auto Size = GetFixedStoreSize(SI->getValueOperand()->getType(), DL);
        if (!Size)
          return nullptr;
        AccessSize = *Size;
      } else {
        continue;
      }
      std::optional<AllocaCell> Access =
          GetAllocaCell(AccessPointer, AccessSize, DL);
      if (!Access || Access->Base != Cell->Base ||
          !Overlaps(Access->Offset, Access->Size, Cell->Offset, Cell->Size))
        continue;
      if (auto *LI = dyn_cast<LoadInst>(&I))
        if (LI->isVolatile() || LI->isAtomic())
          return nullptr;
      if (auto *SI = dyn_cast<StoreInst>(&I))
        if (SI->isVolatile() || SI->isAtomic())
          return nullptr;
      if (Access->Offset != Cell->Offset || Access->Size != Cell->Size)
        return nullptr;
      auto *SI = dyn_cast<StoreInst>(&I);
      if (!SI)
        continue;
      auto *PTI = dyn_cast<PtrToIntOperator>(SI->getValueOperand());
      if (!PTI || PTI->getType() != Load.getType() || Source ||
          !DT.dominates(SI, &Load))
        return nullptr;
      Source = SI;
    }
    if (!Source)
      return nullptr;
    auto *PTI = cast<PtrToIntOperator>(Source->getValueOperand());
    return recoverPointerSlotRoot(PTI->getPointerOperand());
  }

  Value *recoverIntegerPointerRoot(Value *Integer) const {
    SmallPtrSet<Value *, 8> Active;
    return recoverIntegerPointerRoot(Integer, Active);
  }

  Value *recoverIntegerPointerRoot(Value *Integer,
                                   SmallPtrSetImpl<Value *> &Active) const {
    if (!Integer || !Integer->getType()->isIntegerTy() ||
        !Active.insert(Integer).second)
      return nullptr;
    Value *Root = nullptr;
    if (auto *PTI = dyn_cast<PtrToIntOperator>(Integer)) {
      Root = recoverPointerSlotRoot(PTI->getPointerOperand());
    } else if (auto *Load = dyn_cast<LoadInst>(Integer)) {
      Root = recoverSerializedIntegerSlotRoot(*Load, Active);
    } else if (auto *Phi = dyn_cast<PHINode>(Integer)) {
      for (Value *Incoming : Phi->incoming_values()) {
        Value *IncomingRoot = recoverIntegerPointerRoot(Incoming, Active);
        if (!IncomingRoot || (Root && Root != IncomingRoot)) {
          Root = nullptr;
          break;
        }
        Root = IncomingRoot;
      }
    } else if (auto *Select = dyn_cast<SelectInst>(Integer)) {
      Value *TrueRoot = recoverIntegerPointerRoot(Select->getTrueValue(), Active);
      Value *FalseRoot =
          recoverIntegerPointerRoot(Select->getFalseValue(), Active);
      if (TrueRoot && TrueRoot == FalseRoot)
        Root = TrueRoot;
    }
    Active.erase(Integer);
    return Root;
  }

  Value *recoverPointerSlotRoot(Value *Pointer) const {
    Pointer = Pointer ? Pointer->stripPointerCasts() : nullptr;
    if (IsProvenAllocationRoot(Pointer))
      return Pointer;
    auto *Load = dyn_cast_or_null<LoadInst>(Pointer);
    if (!Load || Load->isVolatile() || Load->isAtomic() ||
        !Load->getType()->isPointerTy())
      return nullptr;
    auto *Slot = dyn_cast<AllocaInst>(
        Load->getPointerOperand()->stripPointerCasts());
    if (!Slot || !Slot->getAllocatedType()->isPointerTy() ||
        !Slot->isStaticAlloca() ||
        PointerMayBeCaptured(Slot, /*ReturnCaptures=*/true))
      return nullptr;

    StoreInst *Source = nullptr;
    for (User *U : Slot->users()) {
      auto *I = dyn_cast<Instruction>(U);
      if (!I)
        return nullptr;
      if (auto *LI = dyn_cast<LoadInst>(I)) {
        if (LI->isVolatile() || LI->isAtomic() ||
            LI->getPointerOperand()->stripPointerCasts() != Slot)
          return nullptr;
        continue;
      }
      auto *SI = dyn_cast<StoreInst>(I);
      if (!SI || SI->isVolatile() || SI->isAtomic() ||
          SI->getPointerOperand()->stripPointerCasts() != Slot ||
          !SI->getValueOperand()->getType()->isPointerTy())
        return nullptr;
      if (Source || !DT.dominates(SI, Load))
        return nullptr;
      Source = SI;
    }
    if (!Source)
      return nullptr;
    Value *Root = Source->getValueOperand()->stripPointerCasts();
    return IsProvenAllocationRoot(Root) ? Root : nullptr;
  }

  bool conditionsUseOnlyHeapAddress(const Plan &P) const {
    if (P.Selects.size() != P.Arms.size())
      return false;
    SmallPtrSet<Value *, 32> Visited;
    for (unsigned I = 0; I < P.Selects.size(); ++I)
      if (!exactRangeCondition(P.Selects[I]->getCondition(), P.Address,
                               P.Arms[I].Begin, P.Arms[I].End) ||
          !isHeapAddressExpression(P.Selects[I]->getCondition(),
                                   P.BaseInteger, Visited))
        return false;
    return true;
  }

  static bool staticArmsExcludeNull(const Plan &P) {
    // `conditionsUseOnlyHeapAddress` has already established that every
    // select condition is its arm's exact half-open range test.  Therefore
    // begin > 0 is a proof that a null pointer's integer representation (0)
    // reaches the original fallback rather than a static image candidate.
    return llvm::all_of(P.Arms, [](const Arm &A) { return A.Begin != 0; });
  }

  static bool isHeapAddressExpression(Value *V, Value *BaseInteger,
                                      SmallPtrSetImpl<Value *> &Visited) {
    if (V == BaseInteger || isa<Constant>(V) ||
        (isa<Argument>(V) && V->getType()->isIntegerTy()))
      return true;
    if (!Visited.insert(V).second)
      return true;
    auto *I = dyn_cast<Instruction>(V);
    if (!I)
      return false;
    switch (I->getOpcode()) {
    case Instruction::Add:
    case Instruction::Sub:
    case Instruction::And:
    case Instruction::ICmp:
      for (Value *Operand : I->operands())
        if (!isHeapAddressExpression(Operand, BaseInteger, Visited))
          return false;
      return true;
    default:
      return false;
    }
  }

  bool isKnownNonNull(Value *Heap, Instruction *At) const {
    SimplifyQuery SQ(DL, &DT, &AC, At);
    return isKnownNonZero(Heap, SQ);
  }

  static void collectResolverNodes(Value *V, Value *Address,
                                   SmallPtrSetImpl<Value *> &Nodes) {
    if (V == Address || !Nodes.insert(V).second)
      return;
    if (auto *I = dyn_cast<Instruction>(V))
      for (Value *Operand : I->operands())
        collectResolverNodes(Operand, Address, Nodes);
  }

  static bool addressHasNoTagOrComparisonObservation(
      Value *Address, const SmallPtrSetImpl<Value *> &Nodes) {
    for (User *U : Address->users()) {
      if (Nodes.contains(U) || isa<IntToPtrInst>(U) || isa<StoreInst>(U) ||
          isa<BinaryOperator>(U) &&
              (cast<BinaryOperator>(U)->getOpcode() == Instruction::Add ||
               cast<BinaryOperator>(U)->getOpcode() == Instruction::Sub))
        continue;
      // Comparisons, masks, shifts, xor/or and calls observe/tag the integer
      // address rather than merely constructing another resolver address.
      return false;
    }
    return true;
  }

  bool rootHasForbiddenUse(Value *Heap, const Plan &P) const {
    SmallPtrSet<Value *, 16> AllowedSelects;
    for (SelectInst *Sel : P.Selects)
      AllowedSelects.insert(Sel);
    for (User *U : Heap->users()) {
      if (isa<PtrToIntInst>(U))
        continue;
      if (auto *SI = dyn_cast<StoreInst>(U)) {
        // 040's certified sidecar stores the pointer in a local ptr alloca.
        // Storing the pointer anywhere else is an escape and remains refused.
        if (SI->getValueOperand() == Heap && !SI->isVolatile() &&
            !SI->isAtomic()) {
          if (auto *Slot = dyn_cast<AllocaInst>(
                  SI->getPointerOperand()->stripPointerCasts()))
            if (Slot->getAllocatedType()->isPointerTy())
              continue;
        }
        // A direct non-atomic memory write through the heap does not expose
        // pointer identity.  It does not alter the allocation provenance used
        // to prove static image arms unreachable.
        if (SI->getPointerOperand() == Heap && !SI->isVolatile() &&
            !SI->isAtomic())
          continue;
        return true;
      }
      if (auto *LI = dyn_cast<LoadInst>(U)) {
        if (LI->getPointerOperand() == Heap && !LI->isVolatile() &&
            !LI->isAtomic())
          continue;
        return true;
      }
      if (auto *CB = dyn_cast<CallBase>(U)) {
        // A direct call that formally does not capture this exact argument is
        // not an identity escape.  This admits ordinary strlen/scanf/free
        // lifecycles while refusing callbacks and unknown capture contracts.
        if (!CB->isIndirectCall()) {
          bool NoCapture = true;
          for (unsigned I = 0; I < CB->arg_size(); ++I)
            if (CB->getArgOperand(I) == Heap && !CB->doesNotCapture(I)) {
              NoCapture = false;
              break;
            }
          if (NoCapture)
            continue;
        }
        return true;
      }
      if (auto *Cmp = dyn_cast<ICmpInst>(U)) {
        Value *Other = Cmp->getOperand(0) == Heap ? Cmp->getOperand(1)
                                                   : Cmp->getOperand(0);
        if (isa<ConstantPointerNull>(Other))
          continue;
      }
      if (AllowedSelects.contains(U) ||
          (isa<SelectInst>(U) && cast<SelectInst>(U)->getFalseValue() == Heap))
        continue;
      // No direct calls/stores/returns/casts/GEPs: those may capture the
      // allocation or cross a free/realloc lifetime boundary.
      return true;
    }
    return false;
  }
};

// A pointer-sized integer expression is intentionally represented separately
// from the general pointer round-trip recovery above.  This is not an
// algebraic peephole: dropping ptrtoint(P) also drops P's poison/undef
// dependency, so every rewrite is gated on a use-site proof below.
struct AddressAffineExpression {
  Value *Anchor = nullptr;
  APInt Coefficient;
  APInt Offset;
  SmallVector<Value *, 8> Nodes;
  SmallVector<Value *, 4> AnchorOperands;

  explicit AddressAffineExpression(unsigned Width)
      : Coefficient(Width, 0), Offset(Width, 0) {}
};

class AddressCanonicalizer {
public:
  AddressCanonicalizer(Function &F, const DataLayout &DL, DominatorTree &DT,
                       AssumptionCache &AC)
      : F(F), DL(DL), DT(DT), AC(AC) {}

  bool run() {
    SmallVector<std::pair<GetElementPtrInst *, unsigned>, 16> Direct;
    SmallPtrSet<ConstantExpr *, 16> ConstantGEPs;
    for (Instruction &I : instructions(F)) {
      if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
        for (unsigned Op = 1; Op < GEP->getNumOperands(); ++Op)
          Direct.push_back({GEP, Op});
      }
      for (Use &Operand : I.operands()) {
        auto *CE = dyn_cast<ConstantExpr>(Operand.get());
        if (CE && CE->getOpcode() == Instruction::GetElementPtr)
          ConstantGEPs.insert(CE);
      }
    }

    SmallVector<DirectPlan, 16> DirectPlans;
    for (const auto &[GEP, Op] : Direct) {
      if (auto Offset = matchOffset(GEP->getOperand(Op), GEP, GEP))
        DirectPlans.push_back({GEP, Op, GEP->getOperand(Op), *Offset});
    }

    SmallVector<ConstantGEPPlan, 8> ConstantPlans;
    for (ConstantExpr *CE : ConstantGEPs)
      for (User *U : CE->users()) {
        auto *User = dyn_cast<Instruction>(U);
        if (!User || User->getFunction() != &F)
          continue;
        if (auto *Phi = dyn_cast<PHINode>(User)) {
          for (unsigned I = 0; I < Phi->getNumIncomingValues(); ++I) {
            if (Phi->getIncomingValue(I) != CE)
              continue;
            Instruction *InsertBefore = Phi->getIncomingBlock(I)->getTerminator();
            if (auto Recipe = planConstantGEPTree(CE, InsertBefore))
              ConstantPlans.push_back(
                  {CE, Phi, InsertBefore, I, std::move(Recipe)});
          }
          continue;
        }
        if (auto Recipe = planConstantGEPTree(CE, User))
          ConstantPlans.push_back(
              {CE, User, User, std::nullopt, std::move(Recipe)});
      }

    // Planning is side-effect free.  No GEP is changed until every proof for
    // that individual rewrite has succeeded.
    for (const DirectPlan &Plan : DirectPlans)
      Plan.GEP->setOperand(
          Plan.Operand,
          ConstantInt::get(Plan.GEP->getOperand(Plan.Operand)->getType(),
                           Plan.Offset));

    for (const ConstantGEPPlan &Plan : ConstantPlans) {
      Value *Replacement =
          materializeConstantGEPTree(*Plan.Recipe, Plan.InsertBefore);
      if (Plan.PhiIncoming)
        cast<PHINode>(Plan.User)->setIncomingValue(*Plan.PhiIncoming,
                                                   Replacement);
      else
        Plan.User->replaceUsesOfWith(Plan.GEP, Replacement);
    }
    // The direct form leaves ordinary add/sub/ptrtoint instructions dead.
    // Erase only LLVM-proven trivially-dead instructions after all planned
    // rewrites commit, so the next owner sees the recovered GEP rather than a
    // stale, unused integer-address chain.
    SmallVector<WeakTrackingVH, 16> DeadRoots;
    for (const DirectPlan &Plan : DirectPlans)
      if (isa<Instruction>(Plan.Index))
        DeadRoots.push_back(Plan.Index);
    for (const WeakTrackingVH &Root : DeadRoots)
      if (auto *I = dyn_cast_or_null<Instruction>(Root))
        RecursivelyDeleteTriviallyDeadInstructions(I);
    return !DirectPlans.empty() || !ConstantPlans.empty();
  }

private:
  struct DirectPlan {
    GetElementPtrInst *GEP;
    unsigned Operand;
    Value *Index;
    APInt Offset;
  };
  struct ConstantGEPRecipe {
    ConstantExpr *GEP;
    SmallVector<std::pair<unsigned, APInt>, 4> Replacements;
    std::unique_ptr<ConstantGEPRecipe> Base;
  };
  struct ConstantGEPPlan {
    ConstantExpr *GEP;
    Instruction *User;
    Instruction *InsertBefore;
    std::optional<unsigned> PhiIncoming;
    std::unique_ptr<ConstantGEPRecipe> Recipe;
  };

  std::unique_ptr<ConstantGEPRecipe>
  planConstantGEPTree(ConstantExpr *CE, Instruction *Context) const {
    auto *GEP = dyn_cast<GEPOperator>(CE);
    if (!GEP)
      return nullptr;
    if (GEP->getInRange())
      return nullptr;
    auto Recipe = std::make_unique<ConstantGEPRecipe>();
    Recipe->GEP = CE;
    for (unsigned Op = 1; Op < CE->getNumOperands(); ++Op)
      if (auto Offset = matchOffset(CE->getOperand(Op), Context, CE))
        Recipe->Replacements.push_back({Op, *Offset});
    if (auto *Base = dyn_cast<ConstantExpr>(GEP->getPointerOperand()))
      if (Base->getOpcode() == Instruction::GetElementPtr)
        Recipe->Base = planConstantGEPTree(Base, Context);
    if (Recipe->Replacements.empty() && !Recipe->Base)
      return nullptr;
    return Recipe;
  }

  GetElementPtrInst *materializeConstantGEPTree(
      const ConstantGEPRecipe &Recipe, Instruction *User) const {
    auto *GEP = cast<GEPOperator>(Recipe.GEP);
    Value *Base = Recipe.Base
                      ? materializeConstantGEPTree(*Recipe.Base, User)
                      : GEP->getPointerOperand();
    SmallVector<Value *, 8> Indices;
    for (unsigned Op = 1; Op < Recipe.GEP->getNumOperands(); ++Op)
      Indices.push_back(Recipe.GEP->getOperand(Op));
    for (const auto &[Operand, Offset] : Recipe.Replacements)
      Indices[Operand - 1] =
          ConstantInt::get(Recipe.GEP->getOperand(Operand)->getType(), Offset);
    auto *Replacement = GetElementPtrInst::Create(
        GEP->getSourceElementType(), Base, Indices, GEP->getNoWrapFlags(),
        "brighten.address.gep", User->getIterator());
    Replacement->setDebugLoc(User->getDebugLoc());
    return Replacement;
  }

  Function &F;
  const DataLayout &DL;
  DominatorTree &DT;
  AssumptionCache &AC;

  std::optional<AddressAffineExpression>
  parse(Value *V, unsigned Width, SmallPtrSetImpl<Value *> &Active) const {
    if (!V->getType()->isIntegerTy(Width) || !Active.insert(V).second)
      return std::nullopt;

    auto Finish = [&](std::optional<AddressAffineExpression> Result) {
      Active.erase(V);
      return Result;
    };
    if (auto *C = dyn_cast<ConstantInt>(V)) {
      AddressAffineExpression Result(Width);
      Result.Offset = C->getValue();
      return Finish(std::move(Result));
    }
    if (auto *PTI = dyn_cast<PtrToIntOperator>(V)) {
      auto *PointerTy =
          dyn_cast<PointerType>(PTI->getPointerOperand()->getType());
      if (!PointerTy || DL.isNonIntegralPointerType(PointerTy) ||
          DL.getPointerSizeInBits(PointerTy->getAddressSpace()) != Width)
        return Finish(std::nullopt);
      AddressAffineExpression Result(Width);
      Value *Pointer = PTI->getPointerOperand();
      Result.Anchor = canonicalStaticAnchor(Pointer).value_or(Pointer);
      Result.Coefficient = APInt(Width, 1);
      Result.Nodes.push_back(V);
      Result.AnchorOperands.push_back(Pointer);
      return Finish(std::move(Result));
    }

    // freeze is only eliminated after matchOffset proves its ptrtoint roots
    // are non-poison/non-undef at this exact use.  Without that later proof a
    // freeze changes poison semantics, so it is intentionally not a generic
    // simplification.
    if (auto *Freeze = dyn_cast<FreezeInst>(V)) {
      auto Result = parse(Freeze->getOperand(0), Width, Active);
      if (Result)
        Result->Nodes.push_back(V);
      return Finish(std::move(Result));
    }

    auto *Op = dyn_cast<Operator>(V);
    if (!Op || Op->hasPoisonGeneratingAnnotations())
      return Finish(std::nullopt);
    auto *Overflowing = dyn_cast<OverflowingBinaryOperator>(V);
    if (Overflowing && (Overflowing->hasNoSignedWrap() ||
                        Overflowing->hasNoUnsignedWrap()))
      return Finish(std::nullopt);
    if (auto *Exact = dyn_cast<PossiblyExactOperator>(V);
        Exact && Exact->isExact())
      return Finish(std::nullopt);

    if (Op->getOpcode() == Instruction::BitCast &&
        Op->getOperand(0)->getType() == V->getType()) {
      auto Result = parse(Op->getOperand(0), Width, Active);
      if (Result)
        Result->Nodes.push_back(V);
      return Finish(std::move(Result));
    }

    auto Scale = [&](AddressAffineExpression &Expr, const APInt &Factor) {
      Expr.Coefficient *= Factor;
      Expr.Offset *= Factor;
    };
    if (Op->getOpcode() == Instruction::Mul) {
      auto *LeftConstant = dyn_cast<ConstantInt>(Op->getOperand(0));
      auto *RightConstant = dyn_cast<ConstantInt>(Op->getOperand(1));
      if (!!LeftConstant == !!RightConstant)
        return Finish(std::nullopt);
      auto Result = parse(LeftConstant ? Op->getOperand(1) : Op->getOperand(0),
                          Width, Active);
      if (!Result)
        return Finish(std::nullopt);
      Scale(*Result, (LeftConstant ? LeftConstant : RightConstant)->getValue());
      Result->Nodes.push_back(V);
      return Finish(std::move(Result));
    }
    if (Op->getOpcode() == Instruction::Shl) {
      auto *Shift = dyn_cast<ConstantInt>(Op->getOperand(1));
      if (!Shift || Shift->getValue().uge(Width))
        return Finish(std::nullopt);
      auto Result = parse(Op->getOperand(0), Width, Active);
      if (!Result)
        return Finish(std::nullopt);
      Scale(*Result, APInt(Width, 1).shl(Shift->getZExtValue()));
      Result->Nodes.push_back(V);
      return Finish(std::move(Result));
    }
    if (Op->getOpcode() == Instruction::Xor) {
      auto *AllOnes = dyn_cast<ConstantInt>(Op->getOperand(1));
      if (!AllOnes || !AllOnes->isMinusOne())
        return Finish(std::nullopt);
      auto Result = parse(Op->getOperand(0), Width, Active);
      if (!Result)
        return Finish(std::nullopt);
      Result->Coefficient = -Result->Coefficient;
      Result->Offset = -Result->Offset - APInt(Width, 1);
      Result->Nodes.push_back(V);
      return Finish(std::move(Result));
    }
    if (Op->getOpcode() != Instruction::Add &&
        Op->getOpcode() != Instruction::Sub)
      return Finish(std::nullopt);

    auto Left = parse(Op->getOperand(0), Width, Active);
    auto Right = parse(Op->getOperand(1), Width, Active);
    if (!Left || !Right ||
        (Left->Anchor && Right->Anchor && Left->Anchor != Right->Anchor))
      return Finish(std::nullopt);
    APInt RightCoefficient = Right->Coefficient;
    if (Op->getOpcode() == Instruction::Sub)
      RightCoefficient = -RightCoefficient;

    AddressAffineExpression Result(Width);
    Result.Anchor = Left->Anchor ? Left->Anchor : Right->Anchor;
    Result.Coefficient = Left->Coefficient + RightCoefficient;
    Result.Offset = Op->getOpcode() == Instruction::Sub
                        ? Left->Offset - Right->Offset
                        : Left->Offset + Right->Offset;
    Result.Nodes.append(Left->Nodes.begin(), Left->Nodes.end());
    Result.Nodes.append(Right->Nodes.begin(), Right->Nodes.end());
    Result.AnchorOperands.append(Left->AnchorOperands.begin(),
                                 Left->AnchorOperands.end());
    Result.AnchorOperands.append(Right->AnchorOperands.begin(),
                                 Right->AnchorOperands.end());
    Result.Nodes.push_back(V);
    return Finish(std::move(Result));
  }

  static bool isGEPOffsetUse(const User *U, const Value *V) {
    auto *GEP = dyn_cast<GEPOperator>(U);
    if (!GEP)
      return false;
    for (Value *Index : GEP->indices())
      if (Index == V)
        return true;
    return false;
  }

  static bool isOnlyUsedInside(Value *Root, ArrayRef<Value *> Nodes,
                               User *Target) {
    // The cancellation expression itself must have one unobserved use.  Its
    // anchor ptrtoint may be commoned by LLVM across several independently
    // safe GEP indices, so checking every interior node for one use would
    // reject the exact late-IR form this pass owns.
    for (User *U : Root->users())
      if (U != Target && !isGEPOffsetUse(U, Root))
        return false;
    return true;
  }

  // ValueTracking is intentionally conservative for some ConstantExpr GEPs.
  // A constant inbounds GEP rooted at a sized global is nevertheless a useful
  // proof case here, provided its complete byte offset is within that object.
  bool isStaticNonPoisonGlobalPointer(Value *Pointer) const {
    auto *PointerTy = dyn_cast<PointerType>(Pointer->getType());
    if (!PointerTy || !isa<Constant>(Pointer) ||
        DL.isNonIntegralPointerType(PointerTy))
      return false;
    if (isa<GlobalVariable>(Pointer))
      return true;
    auto *GEP = dyn_cast<GEPOperator>(Pointer);
    if (!GEP || !GEP->isInBounds() || GEP->getInRange())
      return false;
    unsigned Width = DL.getIndexTypeSizeInBits(PointerTy);
    APInt Offset(Width, 0);
    Value *Base = Pointer->stripAndAccumulateConstantOffsets(
        DL, Offset, /*AllowNonInbounds=*/true);
    auto *GV = dyn_cast<GlobalVariable>(Base);
    std::optional<uint64_t> Size = GV ? GetAllocationSize(GV, DL)
                                      : std::nullopt;
    return Size && !Offset.isNegative() && Offset.getActiveBits() <= 64 &&
           Offset.getZExtValue() <= *Size;
  }

  // This is a representation canonicalization, not a relaxed affine match.
  // It gives statically proven-equivalent ConstantExpr GEP anchors one exact
  // byte-GEP representative before parse() applies the exact-SSA rule.  A
  // flagged GEP is admitted only if its global offset proves it non-poison;
  // inrange and dynamic forms stay distinct.
  std::optional<Value *> canonicalStaticAnchor(Value *Pointer) const {
    auto *PointerTy = dyn_cast<PointerType>(Pointer->getType());
    if (!PointerTy || !isa<Constant>(Pointer) ||
        DL.isNonIntegralPointerType(PointerTy))
      return std::nullopt;
    if (isa<GlobalVariable>(Pointer))
      return Pointer;
    auto *GEP = dyn_cast<GEPOperator>(Pointer);
    if (!GEP || GEP->getInRange() ||
        (GEP->isInBounds() && !isStaticNonPoisonGlobalPointer(Pointer)))
      return std::nullopt;
    unsigned Width = DL.getIndexTypeSizeInBits(PointerTy);
    APInt Offset(Width, 0);
    Value *Base = Pointer->stripAndAccumulateConstantOffsets(
        DL, Offset, /*AllowNonInbounds=*/true);
    if (!isa<GlobalVariable>(Base))
      return std::nullopt;
    auto *ByteIndex = ConstantInt::get(
        IntegerType::get(F.getContext(), Width), Offset);
    return ConstantExpr::getGetElementPtr(Type::getInt8Ty(F.getContext()),
                                          cast<Constant>(Base), ByteIndex,
                                          GEPNoWrapFlags::none());
  }

  std::optional<APInt> matchOffset(Value *Index, Instruction *Context,
                                   User *Target) const {
    if (!Index->getType()->isIntegerTy())
      return std::nullopt;
    unsigned Width = Index->getType()->getIntegerBitWidth();
    SmallPtrSet<Value *, 16> Active;
    auto Parsed = parse(Index, Width, Active);
    bool ParsedExact = Parsed && Parsed->Anchor &&
                       Parsed->Coefficient.isZero() && !Parsed->Nodes.empty();
    bool AnchorDefined = ParsedExact;
    if (AnchorDefined) {
      for (Value *Anchor : Parsed->AnchorOperands) {
        if (!isGuaranteedNotToBeUndefOrPoison(Anchor, &AC, Context, &DT) &&
            !isStaticNonPoisonGlobalPointer(Anchor)) {
          AnchorDefined = false;
          break;
        }
      }
    }
    bool RootUnobserved =
        ParsedExact && isOnlyUsedInside(Index, Parsed->Nodes, Target);
    if (!ParsedExact || !AnchorDefined || !RootUnobserved)
      return std::nullopt;
    // A ptrtoint(anchor) can legitimately be shared with an integer print,
    // store, or diagnostic.  This rewrite neither replaces that ptrtoint nor
    // changes its observed-use chain: it only replaces the independently
    // proven cancellation root used as this GEP index.  The root-use check
    // above remains strict, and recursive DCE below erases a shared PTI only
    // when LLVM has proved it has no users.
    return Parsed->Offset;
  }
};

} // namespace

bool RecoverNativePointerIntegerRoundTrips(Module &M,
                                           ModuleAnalysisManager &AM) {
  if (M.getDataLayout().isDefault())
    return false;

  FunctionAnalysisManager &FAM =
      AM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
    auto &LI = FAM.getResult<LoopAnalysis>(F);
    auto &SE = FAM.getResult<ScalarEvolutionAnalysis>(F);
    auto &AC = FAM.getResult<AssumptionAnalysis>(F);
    FunctionPointerRecovery Recovery(F, M.getDataLayout(), DT, LI, SE, AC);
    Changed |= Recovery.run();
  }
  return Changed;
}

bool CanonicalizeAddresses(Module &M, ModuleAnalysisManager &AM) {
  if (M.getDataLayout().isDefault())
    return false;
  FunctionAnalysisManager &FAM =
      AM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
    auto &AC = FAM.getResult<AssumptionAnalysis>(F);
    AddressCanonicalizer Canonicalizer(F, M.getDataLayout(), DT, AC);
    Changed |= Canonicalizer.run();
  }
  return Changed;
}

bool CollapseHeapProvenPointerResolvers(Module &M,
                                        ModuleAnalysisManager &AM) {
  if (M.getDataLayout().isDefault())
    return false;
  FunctionAnalysisManager &FAM =
      AM.getResult<FunctionAnalysisManagerModuleProxy>(M).getManager();
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    auto &DT = FAM.getResult<DominatorTreeAnalysis>(F);
    auto &AC = FAM.getResult<AssumptionAnalysis>(F);
    HeapProvenResolverCollapse Collapse(F, M.getDataLayout(), DT, AC);
    Changed |= Collapse.run();
  }
  return Changed;
}

} // namespace brighten_type
