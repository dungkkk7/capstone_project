#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

namespace brighten_global {

using namespace llvm;

static Value *CreateGEPToObject(IRBuilder<> &Builder, RecoveredObject *Obj,
                                 uint64_t GuestAddr) {
  if (!Obj || !Obj->GV)
    return nullptr;

  uint64_t Offset = GuestAddr - Obj->Begin;
  Type *ObjTy = Obj->GV->getValueType();

  if (Obj->Kind == ObjectKind::StringLiteral) {
    if (Offset == 0) {
      return Builder.CreateGEP(
          ObjTy, Obj->GV,
          {Builder.getInt64(0), Builder.getInt64(0)});
    }
    return Builder.CreateGEP(
        ObjTy, Obj->GV,
        {Builder.getInt64(0), Builder.getInt64(Offset)});
  }

  if (Obj->Kind == ObjectKind::Scalar) {
    if (Offset != 0)
      return nullptr;
    return Obj->GV;
  }

  if (Obj->Kind == ObjectKind::Array || Obj->Kind == ObjectKind::RawBytes) {
    if (!isa<ArrayType>(ObjTy))
      return nullptr;
    // Use a byte GEP for recovered arrays.  This is required for packed
    // records and for field references whose offset is not an element-sized
    // multiple (for example input[i].index at record+4).
    return Builder.CreateGEP(Builder.getInt8Ty(), Obj->GV,
                             Builder.getInt64(Offset), "native.data.ptr");
  }

  if (Obj->Kind == ObjectKind::PointerTable) {
    auto *ArrTy = dyn_cast<ArrayType>(ObjTy);
    if (!ArrTy)
      return nullptr;
    unsigned ElemSize = Obj->GV->getParent()->getDataLayout().getTypeStoreSize(
        ArrTy->getElementType());
    if (ElemSize == 0 || Offset % ElemSize != 0)
      return nullptr;
    uint64_t Idx = Offset / ElemSize;
    return Builder.CreateGEP(
        ObjTy, Obj->GV,
        {Builder.getInt64(0), Builder.getInt64(Idx)});
  }

  return nullptr;
}

static Constant *CreateConstantGEPToObject(RecoveredObject *Obj,
                                           uint64_t GuestAddr,
                                           Type *ExpectedTy) {
  if (!Obj || !Obj->GV)
    return nullptr;

  uint64_t Offset = GuestAddr - Obj->Begin;
  Type *ObjTy = Obj->GV->getValueType();
  LLVMContext &LCtx = Obj->GV->getContext();

  Constant *GEP = nullptr;
  if (Obj->Kind == ObjectKind::StringLiteral) {
    GEP = ConstantExpr::getGetElementPtr(
        ObjTy, Obj->GV,
        ArrayRef<Constant *>{ConstantInt::get(Type::getInt64Ty(LCtx), 0),
                             ConstantInt::get(Type::getInt64Ty(LCtx), Offset)});
  } else if (Obj->Kind == ObjectKind::Scalar) {
    if (Offset == 0)
      GEP = Obj->GV;
  } else if (Obj->Kind == ObjectKind::Array || Obj->Kind == ObjectKind::PointerTable ||
             Obj->Kind == ObjectKind::RawBytes) {
    auto *ArrTy = dyn_cast<ArrayType>(ObjTy);
    if (ArrTy) {
      (void)ArrTy;
      GEP = ConstantExpr::getGetElementPtr(
          Type::getInt8Ty(LCtx), Obj->GV,
          ArrayRef<Constant *>{ConstantInt::get(Type::getInt64Ty(LCtx), Offset)});
    }
  }

  if (GEP && GEP->getType() != ExpectedTy) {
    if (ExpectedTy->isPointerTy())
      GEP = ConstantExpr::getBitCast(GEP, ExpectedTy);
    else if (ExpectedTy->isIntegerTy())
      GEP = ConstantExpr::getPtrToInt(GEP, ExpectedTy);
  }
  return GEP;
}

static bool HasDynamicGEPIndex(const GEPOperator *GEP) {
  if (!GEP)
    return false;
  for (unsigned I = 1; I < GEP->getNumOperands(); ++I)
    if (!isa<ConstantInt>(GEP->getOperand(I)))
      return true;
  return false;
}

static bool IsVolatileOrAtomicMemoryAccess(const Instruction *I) {
  if (const auto *LI = dyn_cast_or_null<LoadInst>(I))
    return LI->isVolatile() || LI->isAtomic();
  if (const auto *SI = dyn_cast_or_null<StoreInst>(I))
    return SI->isVolatile() || SI->isAtomic();
  return isa_and_nonnull<AtomicRMWInst>(I) ||
         isa_and_nonnull<AtomicCmpXchgInst>(I);
}

static bool IsAddressIdentitySensitive(GuestAddressRef *Ref);

// Recheck the all-use proof immediately before mutation.  Candidate discovery
// runs before conflict resolution/materialization and must be conservative,
// but this fence keeps a future collector from turning a direct scalar split
// into duplicate storage when it records an additional carrier.
static bool HasTransactionalDirectScalarRewriteProof(
    GlobalDataContext &Ctx, const RecoveredObject *Obj) {
  if (!Obj || !Obj->RequiresTransactionalDirectRewrite || !Obj->SourceSegment ||
      !Obj->Ty || !Obj->Ty->isSized())
    return false;
  const uint64_t Width = Ctx.DL.getTypeStoreSize(Obj->Ty).getFixedValue();
  if (Width == 0 || Obj->Begin > UINT64_MAX - Width ||
      Obj->End != Obj->Begin + Width)
    return false;
  bool SawDirectAccess = false;
  for (const auto &Ref : Ctx.AddressRefs) {
    if (!Ref || Ref->Segment != Obj->SourceSegment || !Ref->UserInst)
      continue;
    Instruction *Use = Ref->UserInst;
    if (auto *GEP = dyn_cast<GEPOperator>(Use)) {
      bool Dynamic = false;
      for (unsigned I = 1; I < GEP->getNumOperands(); ++I)
        Dynamic |= !isa<ConstantInt>(GEP->getOperand(I));
      if (Dynamic && Ref->GuestAddr <= Obj->Begin)
        return false;
    }
    Type *AccessTy = nullptr;
    uint64_t AccessWidth = 0;
    bool Direct = false;
    if (auto *LI = dyn_cast<LoadInst>(Use)) {
      Direct = LI->getPointerOperand() == Ref->OriginalValue;
      if (LI->isVolatile() || LI->isAtomic())
        return false;
      AccessTy = LI->getType();
    } else if (auto *SI = dyn_cast<StoreInst>(Use)) {
      Direct = SI->getPointerOperand() == Ref->OriginalValue;
      if (SI->isVolatile() || SI->isAtomic())
        return false;
      AccessTy = SI->getValueOperand()->getType();
    } else if (isa<AtomicRMWInst>(Use) || isa<AtomicCmpXchgInst>(Use)) {
      return false;
    }
    if (AccessTy && AccessTy->isSized())
      AccessWidth = Ctx.DL.getTypeStoreSize(AccessTy).getFixedValue();
    if (!AccessTy) {
      if (Ref->GuestAddr >= Obj->Begin && Ref->GuestAddr < Obj->End &&
          IsAddressIdentitySensitive(Ref.get()))
        return false;
      continue;
    }
    const bool Overlaps = Ref->GuestAddr < Obj->End &&
        (AccessWidth == 0 ? Ref->GuestAddr >= Obj->Begin
                          : (Ref->GuestAddr > UINT64_MAX - AccessWidth ||
                             Ref->GuestAddr + AccessWidth > Obj->Begin));
    if (!Overlaps)
      continue;
    if (!Direct || AccessTy != Obj->Ty || AccessWidth != Width ||
        IsAddressIdentitySensitive(Ref.get()))
      return false;
    SawDirectAccess = true;
  }
  return SawDirectAccess;
}

// A guest data address is often used as an opaque-predicate constant before
// it is ever materialized as a pointer.  Replacing that integer with
// ptrtoint(@recovered_object) changes its value under PIE/ASLR and therefore
// changes control flow.  Follow only value-preserving integer operations: a
// load, store, or call is a pointer/data boundary rather than evidence that
// the address identity itself is observed.
static bool HasGuestAddressIdentityUse(Value *V,
                                       SmallPtrSetImpl<Value *> &Seen,
                                       unsigned Depth = 0) {
  if (!V || Depth > 12 || !Seen.insert(V).second)
    return false;
  if (isa<ICmpInst>(V) || isa<SwitchInst>(V))
    return true;
  // ConstantData (notably ConstantInt guest addresses) has no LLVM use-list;
  // asking for users() asserts in debug builds.  Its identity observation is
  // classified at the consuming instruction instead.
  if (isa<ConstantData>(V))
    return false;

  for (User *U : V->users()) {
    if (isa<ICmpInst>(U) || isa<SwitchInst>(U))
      return true;
    if (isa<GetElementPtrInst>(U) || isa<PtrToIntInst>(U) ||
        isa<CastInst>(U) ||
        isa<BinaryOperator>(U) || isa<PHINode>(U) ||
        isa<SelectInst>(U) || isa<FreezeInst>(U)) {
      if (HasGuestAddressIdentityUse(cast<Value>(U), Seen, Depth + 1))
        return true;
      continue;
    }
    if (auto *CE = dyn_cast<ConstantExpr>(U)) {
      if (HasGuestAddressIdentityUse(CE, Seen, Depth + 1))
        return true;
    }
    if (auto *SI = dyn_cast<StoreInst>(U)) {
      if (SI->getValueOperand() != V)
        continue;
      Value *StoredAt = SI->getPointerOperand()->stripPointerCasts();
      for (BasicBlock &BB : *SI->getFunction())
        for (Instruction &I : BB) {
          auto *LI = dyn_cast<LoadInst>(&I);
          if (!LI || LI->getPointerOperand()->stripPointerCasts() != StoredAt)
            continue;
          if (HasGuestAddressIdentityUse(LI, Seen, Depth + 1))
            return true;
        }
    }
  }
  return false;
}

static bool EventuallyFeedsPointerConsumer(Value *V,
                                           SmallPtrSetImpl<Value *> &Seen,
                                           unsigned Depth = 0) {
  if (!V || Depth > 12 || !Seen.insert(V).second)
    return false;
  for (User *U : V->users()) {
    if (isa<IntToPtrInst>(U))
      return true;
    if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
      // An integer derived from ptrtoint(data_<base>) and consumed as a GEP
      // index is pointer arithmetic even without an explicit inttoptr.  This
      // includes source-level pointer differences such as
      // cnt[strchr(moji, c) - moji].
      for (Value *Index : GEP->indices())
        if (Index == V)
          return true;
    }
    if (auto *CI = dyn_cast<CallInst>(U)) {
      if (Function *Callee = CI->getCalledFunction()) {
        if (Callee->getName() == "__translate_guest_pointer")
          return true;
      }
    }
    if (auto *CE = dyn_cast<ConstantExpr>(U)) {
      if (CE->getOpcode() == Instruction::IntToPtr)
        return true;
      continue;
    }
    if (isa<CastInst>(U) || isa<BinaryOperator>(U) || isa<PHINode>(U) ||
        isa<SelectInst>(U) || isa<FreezeInst>(U)) {
      if (EventuallyFeedsPointerConsumer(cast<Value>(U), Seen, Depth + 1))
        return true;
    }
    if (auto *SI = dyn_cast<StoreInst>(U)) {
      if (SI->getValueOperand() != V)
        continue;
      Value *StoredAt = SI->getPointerOperand()->stripPointerCasts();
      for (BasicBlock &BB : *SI->getFunction())
        for (Instruction &I : BB) {
          auto *LI = dyn_cast<LoadInst>(&I);
          if (!LI || LI->getPointerOperand()->stripPointerCasts() != StoredAt)
            continue;
          if (EventuallyFeedsPointerConsumer(LI, Seen, Depth + 1))
            return true;
        }
    }
  }
  return false;
}

static bool EventuallyNarrowsBelowPointerWidth(Value *V, unsigned PointerBits,
                                               SmallPtrSetImpl<Value *> &Seen,
                                               unsigned Depth = 0) {
  if (!V || Depth > 12 || !Seen.insert(V).second)
    return false;
  if (auto *IT = dyn_cast<IntegerType>(V->getType()))
    if (IT->getBitWidth() < PointerBits)
      return true;
  if (isa<ConstantData>(V))
    return false;
  for (User *U : V->users()) {
    if (isa<CastInst>(U) || isa<BinaryOperator>(U) || isa<PHINode>(U) ||
        isa<SelectInst>(U) || isa<FreezeInst>(U))
      if (EventuallyNarrowsBelowPointerWidth(cast<Value>(U), PointerBits,
                                             Seen, Depth + 1))
        return true;
  }
  return false;
}

static bool IsGuestAddressIntegerConstant(Value *V) {
  if (isa<ConstantInt>(V))
    return true;

  auto *CE = dyn_cast<ConstantExpr>(V);
  if (!CE || CE->getOpcode() != Instruction::PtrToInt)
    return false;
  Value *Pointer = CE->getOperand(0)->stripPointerCasts();
  auto *GV = dyn_cast<GlobalValue>(Pointer);
  return GV && GV->getName().starts_with("data_");
}

static bool IsAddressIdentitySensitive(GuestAddressRef *Ref) {
  if (!Ref || !Ref->UserInst)
    return false;
  // Direct pointer equality is identity-sensitive regardless of whether the
  // lifted operand is spelled as an integer guest address, a data alias, or a
  // GEP rooted at a segment.  The spelling must not decide whether replacing
  // it with an ASLR-dependent recovered-object address is legal.
  if (Ref->ConsumerKind == DataConsumerKind::ComparisonOnly)
    return true;
  // Preserve producer nodes whose result flows to an identity boundary as
  // well.  Address collection records both the final comparison operand and
  // intermediate GEP/cast nodes; rewriting an intermediate segment operand
  // would still mutate the comparison even if its own GuestAddressRef is
  // skipped.  This test is intentionally spelling-independent.
  // Start from the address operand, not from the consuming instruction.  A
  // load is a data boundary: comparisons of the loaded value observe the
  // object contents, not the numeric identity of the pointer used by the
  // load.  Starting at UserInst incorrectly preserves essentially every
  // global scalar whose value later participates in a comparison, leaving
  // its lifted data_<addr> alias disconnected from the recovered object.
  // Follow this reference's use edge rather than the shared producer.  A
  // segment/global value can feed both a libc pointer use and an unrelated
  // identity comparison; inspecting all producer users would preserve the
  // safe libc use as well.  GEP/cast/arithmetic nodes propagate the address,
  // while load/call nodes are data boundaries.
  Instruction *Use = Ref->UserInst;
  if (isa<GetElementPtrInst>(Use) || isa<CastInst>(Use) ||
      isa<BinaryOperator>(Use) || isa<PHINode>(Use) ||
      isa<SelectInst>(Use) || isa<FreezeInst>(Use)) {
    SmallPtrSet<Value *, 32> DirectIdentitySeen;
    if (HasGuestAddressIdentityUse(Use, DirectIdentitySeen))
      return true;
  }
  // McSema also represents an integer immediate as ptrtoint(data_<addr>)
  // whenever it falls inside a broad BSS mapping.  That symbolic form is not
  // proof of pointer intent: flattened dispatcher states routinely use it as
  // an opaque numeric value.  Preserve the guest integer at an identity
  // boundary and let the native-pointer lowering handle actual dereferences.
  if (!IsGuestAddressIntegerConstant(Ref->OriginalValue))
    return false;
  if (Ref->ConsumerKind != DataConsumerKind::ArithmeticOnly &&
      Ref->ConsumerKind != DataConsumerKind::IntegerAddressConsumer &&
      Ref->ConsumerKind != DataConsumerKind::Unknown)
    return false;
  SmallPtrSet<Value *, 32> PointerSeen;
  if (EventuallyFeedsPointerConsumer(Ref->UserInst, PointerSeen))
    return false;
  const DataLayout &DL = Ref->UserInst->getModule()->getDataLayout();
  unsigned PointerBits = DL.getPointerSizeInBits(0);
  SmallPtrSet<Value *, 32> NarrowSeen;
  return EventuallyNarrowsBelowPointerWidth(Ref->OriginalValue, PointerBits,
                                            NarrowSeen) ||
         EventuallyNarrowsBelowPointerWidth(Ref->UserInst, PointerBits,
                                            NarrowSeen);
}

static bool FindSegmentBase(Value *Ptr, GlobalVariable *Segment,
                            const DataLayout &DL, uint64_t &Offset,
                            SmallPtrSetImpl<Value *> &Seen) {
  if (!Ptr || !Seen.insert(Ptr).second)
    return false;
  Ptr = Ptr->stripPointerCasts();
  if (Ptr == Segment)
    return true;
  if (auto *GA = dyn_cast<GlobalAlias>(Ptr)) {
    StringRef Name = GA->getName();
    if (Name.starts_with("data_")) {
      uint64_t GuestAddress = 0;
      StringRef Hex = Name.drop_front(StringRef("data_").size());
      if (!Hex.empty() && !Hex.getAsInteger(16, GuestAddress)) {
        uint64_t SegmentSize = DL.getTypeAllocSize(Segment->getValueType())
                                   .getFixedValue();
        for (auto &S : Segment->getParent()->globals()) {
          if (&S != Segment)
            continue;
          (void)S;
          MDNode *Range = Segment->getMetadata("brighten.guest.range");
          if (!Range || Range->getNumOperands() != 2)
            break;
          auto *BeginMD = dyn_cast<ConstantAsMetadata>(Range->getOperand(0));
          auto *Begin = BeginMD
                            ? dyn_cast<ConstantInt>(BeginMD->getValue())
                            : nullptr;
          if (Begin && GuestAddress >= Begin->getZExtValue() &&
              GuestAddress < Begin->getZExtValue() + SegmentSize) {
            Offset = GuestAddress - Begin->getZExtValue();
            return true;
          }
          break;
        }
      }
    }
    if (Constant *Aliasee = GA->getAliasee())
      return FindSegmentBase(Aliasee, Segment, DL, Offset, Seen);
  }
  auto *GEP = dyn_cast<GEPOperator>(Ptr);
  if (!GEP)
    return false;

  APInt Local(DL.getPointerSizeInBits(0), 0, true);
  bool HasOnlyConstantOffset = GEP->accumulateConstantOffset(DL, Local);
  if (!FindSegmentBase(GEP->getPointerOperand(), Segment, DL, Offset, Seen))
    return false;
  if (HasOnlyConstantOffset) {
    if (Local.isNegative() || Offset > UINT64_MAX - Local.getZExtValue())
      return false;
    Offset += Local.getZExtValue();
  }
  return true;
}

static bool IsVarargPointerSaveSlot(Value *Ptr) {
  auto *GEP = dyn_cast<GEPOperator>(Ptr ? Ptr->stripPointerCasts() : nullptr);
  if (!GEP || GEP->getNumIndices() == 0)
    return false;

  Value *Base = GEP->getPointerOperand()->stripPointerCasts();
  auto *AI = dyn_cast<AllocaInst>(Base);
  if (!AI || !AI->getName().contains("reg_save_area"))
    return false;

  auto It = GEP->idx_end();
  --It;
  auto *Slot = dyn_cast<ConstantInt>(*It);
  if (!Slot)
    return false;
  // The inlined helper usually addresses the byte offsets directly (8..40)
  // rather than using the original array element index.  Slot zero contains
  // the fixed format/stream argument; slots one through five are the GP
  // variadic arguments used by scanf-family calls.
  uint64_t ByteOffset = Slot->getZExtValue();
  return ByteOffset >= 8 && ByteOffset <= 40 && (ByteOffset % 8) == 0;
}

static bool RewriteDynamicScanfPointerAddresses(GlobalDataContext &Ctx,
                                                 unsigned &Count) {
  bool Changed = false;
  SmallVector<std::pair<StoreInst *, BinaryOperator *>, 64> Stores;

  for (Function &F : Ctx.M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *BO = dyn_cast<BinaryOperator>(&I);
        if (!BO || BO->getOpcode() != Instruction::Add ||
            !BO->getType()->isIntegerTy())
          continue;

        for (User *U : BO->users()) {
          auto *SI = dyn_cast<StoreInst>(U);
          if (SI && SI->getValueOperand() == BO &&
              IsVarargPointerSaveSlot(SI->getPointerOperand()))
            Stores.push_back({SI, BO});
        }
      }
    }
  }

  for (auto [SI, BO] : Stores) {
    ConstantInt *BaseConst = dyn_cast<ConstantInt>(BO->getOperand(0));
    Value *DynamicOffset = BO->getOperand(1);
    if (!BaseConst) {
      BaseConst = dyn_cast<ConstantInt>(BO->getOperand(1));
      DynamicOffset = BO->getOperand(0);
    }
    if (!BaseConst || !DynamicOffset)
      continue;

    const RecoveredObject *Obj =
        Ctx.findObjectAt(BaseConst->getZExtValue());
    if (!Obj || !Obj->GV ||
        BaseConst->getZExtValue() < Obj->Begin ||
        BaseConst->getZExtValue() >= Obj->End)
      continue;

    IRBuilder<> Builder(SI);
    uint64_t BaseOffset = BaseConst->getZExtValue() - Obj->Begin;
    Value *ByteOffset = DynamicOffset;
    if (BaseOffset != 0)
      ByteOffset = Builder.CreateAdd(
          DynamicOffset, Builder.getInt64(BaseOffset),
          "native.vararg.offset");
    Value *NativePtr = Builder.CreateGEP(
        Builder.getInt8Ty(), Obj->GV, ByteOffset, "native.vararg.ptr");
    Value *NativeInt = Builder.CreatePtrToInt(
        NativePtr, BO->getType(), "native.vararg.addr");
    SI->setOperand(0, NativeInt);
    ++Count;
    Changed = true;
  }
  return Changed;
}

static std::optional<uint64_t>
FindNamedDataAddressInIntegerExpr(Value *V,
                                  SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return std::nullopt;

  if (auto *GA = dyn_cast<GlobalAlias>(V->stripPointerCasts())) {
    StringRef Name = GA->getName();
    if (Name.starts_with("data_")) {
      uint64_t Addr = 0;
      StringRef Hex = Name.drop_front(StringRef("data_").size());
      if (!Hex.empty() && !Hex.getAsInteger(16, Addr))
        return Addr;
    }
    if (Constant *Aliasee = GA->getAliasee())
      return FindNamedDataAddressInIntegerExpr(Aliasee, Seen);
  }

  if (auto *CE = dyn_cast<ConstantExpr>(V)) {
    if (CE->getOpcode() == Instruction::PtrToInt)
      return FindNamedDataAddressInIntegerExpr(CE->getOperand(0), Seen);
  }
  if (auto *PTI = dyn_cast<PtrToIntInst>(V))
    return FindNamedDataAddressInIntegerExpr(PTI->getPointerOperand(), Seen);

  if (auto *BO = dyn_cast<BinaryOperator>(V)) {
    if (BO->getOpcode() == Instruction::Add ||
        BO->getOpcode() == Instruction::Sub) {
      if (auto Addr = FindNamedDataAddressInIntegerExpr(BO->getOperand(0), Seen))
        return Addr;
      if (auto Addr = FindNamedDataAddressInIntegerExpr(BO->getOperand(1), Seen))
        return Addr;
    }
  }
  return std::nullopt;
}

static bool RewriteDynamicDataIntToPtrs(GlobalDataContext &Ctx,
                                        unsigned &Count) {
  SmallVector<IntToPtrInst *, 64> Work;
  for (Function &F : Ctx.M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *ITP = dyn_cast<IntToPtrInst>(&I))
          Work.push_back(ITP);
  }

  bool Changed = false;
  for (IntToPtrInst *ITP : Work) {
    Value *Address = ITP->getOperand(0);
    SmallPtrSet<Value *, 32> Seen;
    std::optional<uint64_t> GuestBase;
    if (auto *CI = dyn_cast<ConstantInt>(Address))
      GuestBase = CI->getZExtValue();
    else
      GuestBase = FindNamedDataAddressInIntegerExpr(Address, Seen);
    if (!GuestBase)
      continue;
    const RecoveredObject *Obj = Ctx.findObjectAt(*GuestBase);
    if (!Obj || !Obj->GV ||
        (Obj->Kind != ObjectKind::Array && Obj->Kind != ObjectKind::RawBytes) ||
        *GuestBase < Obj->Begin || *GuestBase >= Obj->End)
      continue;

    // A PT_LOAD page tail is a zero-filled mapping, not range proof for an
    // arbitrary dynamic guest integer.  In particular, the lifted physical
    // aggregate can still carry values outside the tail through this inttoptr
    // path.  Re-basing that carrier to the tail makes those values alias zero
    // storage.  Leave it on the original lifted backing until a bounded range
    // proof can rewrite every alias in the interval transactionally.
    if (Obj->SourceSegment && Obj->SourceSegment->IsMappedPageTail)
      continue;

    IRBuilder<> Builder(ITP);
    Value *Address64 = Address;
    Type *I64 = Type::getInt64Ty(Ctx.M.getContext());
    if (Address64->getType() != I64) {
      if (Address64->getType()->isIntegerTy())
        Address64 = Builder.CreateZExtOrTrunc(Address64, I64,
                                              "native.data.address");
      else
        continue;
    }
    Value *Offset = Builder.CreateSub(
        Address64, Builder.getInt64(Obj->Begin), "native.data.offset");
    Value *NativePtr = Builder.CreateGEP(
        Builder.getInt8Ty(), Obj->GV, Offset, "native.data.dynamic.ptr");
    if (NativePtr->getType() != ITP->getType())
      NativePtr = Builder.CreateBitCast(NativePtr, ITP->getType());
    ITP->replaceAllUsesWith(NativePtr);
    ITP->eraseFromParent();
    ++Count;
    Changed = true;
  }
  return Changed;
}

bool BrightenGlobalDataRecoveryPass::RewriteGuestDataReferences(
    GlobalDataContext &Ctx) {
  unsigned Count = 0;

  // Keep the original data aliases alive until all AddressRefs have been
  // consumed.  Erasing an alias here invalidates GuestAddressRef::OriginalValue
  // and makes a later rewrite depend on a dangling LLVM Value.  Alias uses are
  // rewritten through the same provenance/object path as every other constant
  // reference; a fallback alias-to-string shortcut is intentionally not used.
  bool AliasChanged = false;

  // Freeze every transactional proof before mutating any use.  Otherwise the
  // first rewritten store changes its pointer operand and makes a later load
  // appear to be an unresolved carrier of the old residual address.
  DenseMap<const RecoveredObject *, bool> TransactionalProof;
  for (const auto &[Begin, Obj] : Ctx.RecoveredObjects) {
    (void)Begin;
    if (Obj && Obj->RequiresTransactionalDirectRewrite)
      TransactionalProof[Obj.get()] =
          HasTransactionalDirectScalarRewriteProof(Ctx, Obj.get());
  }

  // 1. Constant Address Refs (including new raw byte locations)
  for (auto &Ref : Ctx.AddressRefs) {
    if (Ref->Rewritten)
      continue;
    if (Ref->SkipReason.size() > 0) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }
    if (!Ref->Segment || !Ref->Segment->BaseResolved) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    auto It = Ctx.RecoveredObjects.upper_bound(Ref->GuestAddr);
    RecoveredObject *Obj = nullptr;
    if (It != Ctx.RecoveredObjects.begin()) {
      --It;
      if (Ref->GuestAddr >= It->second->Begin &&
          Ref->GuestAddr < It->second->End)
        Obj = It->second.get();
    }

    if (!Obj) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    if (Obj->RequiresTransactionalDirectRewrite && !TransactionalProof.lookup(Obj)) {
      Ref->SkipReason = "direct-scalar-transaction-preflight-failed";
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    // A constant base can feed both a direct string/scalar reference and an
    // unbounded dynamic GEP.  Replacing the shared base with the small
    // recovered object makes the latter an out-of-bounds LLVM pointer even
    // though the original merged image legitimately covered it.  Dynamic
    // indexing is only rewritten for Array/RawBytes objects, whose own
    // recovery rules established an indexed backing range.  A scalar/string
    // prefix needs full-source coverage before it can replace a dynamic base.
    if (auto *GEP = dyn_cast<GEPOperator>(Ref->UserInst);
        HasDynamicGEPIndex(GEP) &&
        Obj->Kind != ObjectKind::Array && Obj->Kind != ObjectKind::RawBytes &&
        (Obj->Begin != Ref->Segment->GuestBase ||
         Obj->End != Ref->Segment->GuestBase + Ref->Segment->Size)) {
      Ref->SkipReason = "dynamic-range-not-covered-by-object";
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    // Classify each use independently.  A libc use elsewhere in the same
    // recovered object does not make a numeric comparison of this guest
    // address safe to replace with an ASLR-dependent host pointer.  The libc
    // reference is rewritten by its own GuestAddressRef while this identity
    // boundary keeps the original guest value.
    if (IsAddressIdentitySensitive(Ref.get())) {
      Ref->SkipReason = "address-identity-observable";
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    Instruction *UserInst = Ref->UserInst;
    if (!UserInst) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    // Do not change the address operand of volatile/atomic memory accesses.
    // The readonly-string rule refuses such candidates, but preserving this
    // boundary here prevents a later producer from weakening that contract.
    if (Obj->Kind == ObjectKind::StringLiteral &&
        IsVolatileOrAtomicMemoryAccess(UserInst)) {
      Ref->SkipReason = "volatile-or-atomic-string-access";
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    Value *OrigVal = Ref->OriginalValue;
    if (!OrigVal) {
      ++Ctx.Report.PreservedRefs;
      continue;
    }

    bool LocalRewritten = false;
    if (auto *C = dyn_cast<Constant>(OrigVal)) {
      Constant *NewConst = CreateConstantGEPToObject(Obj, Ref->GuestAddr, C->getType());
      if (NewConst) {
        UserInst->replaceUsesOfWith(C, NewConst);
        Ref->Rewritten = true;
        LocalRewritten = true;
        ++Count;
      }
    }

    if (!LocalRewritten) {
      IRBuilder<> Builder(UserInst);
      Value *NewPtr = CreateGEPToObject(Builder, Obj, Ref->GuestAddr);
      if (NewPtr) {
        Type *ExpectedTy = OrigVal->getType();
        bool TypeOk = true;
        if (NewPtr->getType() != ExpectedTy) {
          if (ExpectedTy->isPointerTy())
            NewPtr = Builder.CreateBitCast(NewPtr, ExpectedTy);
          else if (ExpectedTy->isIntegerTy())
            NewPtr = Builder.CreatePtrToInt(NewPtr, ExpectedTy);
          else
            TypeOk = false;
        }

        if (TypeOk) {
          UserInst->replaceUsesOfWith(OrigVal, NewPtr);
          Ref->Rewritten = true;
          LocalRewritten = true;
          ++Count;
        }
      }
    }

    if (!Ref->Rewritten) {
      ++Ctx.Report.PreservedRefs;
    }
  }

  // A scanf vararg destination can be computed as guest_base + dynamic
  // index*stride before it is placed in the ABI register-save area.  Direct
  // constant-reference rewriting cannot see that pointer context; materialize
  // the same address from the recovered native object instead.
  RewriteDynamicScanfPointerAddresses(Ctx, Count);
  // The same address form also appears in ordinary stores after the lifted
  // code materializes a pointer with inttoptr(add(ptrtoint(data_alias), ...)).
  // Rewrite it from the recovered object provenance before native cleanup can
  // mistake the expression for an opaque integer address.
  RewriteDynamicDataIntToPtrs(Ctx, Count);

  // 2. Rewrite dynamic users of segment globals to typed recovered objects.
  // Unresolved dynamic references are deliberately left intact; creating a
  // whole-segment byte blob would hide missing provenance and violate the
  // native IR contract.
  for (auto &Seg : Ctx.Segments) {
    if (!Seg->GV || !Seg->BaseResolved)
      continue;

    const RecoveredObject *Obj = Ctx.findObjectAt(Seg->GuestBase);
    if (Obj && Obj->GV) {
      SmallVector<User *, 8> Users(Seg->GV->users());
      for (User *U : Users) {
        if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
          Value *Idx = nullptr;
          uint64_t BaseOffset = 0;
          if (GEP->getNumIndices() == 1) {
            Idx = GEP->getOperand(1);
          } else if (GEP->getNumIndices() >= 2) {
            Idx = GEP->getOperand(2);
          }

          if (Idx && !isa<ConstantInt>(Idx)) {
            uint64_t GuestAddr = Seg->GuestBase + BaseOffset;
            const RecoveredObject *Obj = Ctx.findObjectAt(GuestAddr);
            if (Obj && Obj->GV && (Obj->End - Obj->Begin == Seg->Size)) {
              IRBuilder<> Builder(GEP);
              Value *NewBase = Obj->GV;
              if (NewBase->getType() != GEP->getPointerOperand()->getType()) {
                NewBase = Builder.CreateBitCast(
                    NewBase, GEP->getPointerOperand()->getType());
              }
              GEP->setOperand(0, NewBase);
              ++Count;
            }
          }
        }
      }
    }

    for (Function &F : Ctx.M) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          auto *GEP = dyn_cast<GetElementPtrInst>(&I);
          if (!GEP || GEP->getNumIndices() == 0)
            continue;
          bool HasDynamicIndex = false;
          for (unsigned Index = 1; Index < GEP->getNumOperands(); ++Index) {
            if (!isa<ConstantInt>(GEP->getOperand(Index))) {
              HasDynamicIndex = true;
              break;
            }
          }
          if (!HasDynamicIndex)
            continue;

          uint64_t ConstantOffset = 0;
          SmallPtrSet<Value *, 8> Seen;
          if (!FindSegmentBase(GEP, Seg->GV, Ctx.DL, ConstantOffset, Seen))
            continue;

          const RecoveredObject *DynamicObj =
              Ctx.findObjectAt(Seg->GuestBase + ConstantOffset);
          if (!DynamicObj || !DynamicObj->GV ||
              Seg->GuestBase + ConstantOffset < DynamicObj->Begin)
            continue;

          // Do not use a page-tail object as the target of an unbounded GEP.
          // Its mapped interval is exact but the dynamic index is not; this is
          // an all-or-nothing writable ownership boundary.
          if (DynamicObj->SourceSegment &&
              DynamicObj->SourceSegment->IsMappedPageTail)
            continue;

          // This GEP has an unconstrained dynamic index.  A recovered prefix
          // is not a proof that every possible index remains inside it; keep
          // the original merged residual unless the object is exactly the
          // complete source range.  Array/RawBytes are the exception: their
          // recovery rule, rather than this generic rewrite, owns the indexed
          // backing-range proof.
          if ((DynamicObj->Kind != ObjectKind::Array &&
               DynamicObj->Kind != ObjectKind::RawBytes) &&
              (DynamicObj->Begin != Seg->GuestBase ||
               DynamicObj->End != Seg->GuestBase + Seg->Size))
            continue;

          Value *NativeBase = DynamicObj->GV;
          uint64_t ObjectOffset =
              Seg->GuestBase + ConstantOffset - DynamicObj->Begin;
          if (ObjectOffset != 0) {
            NativeBase = IRBuilder<>(GEP).CreateGEP(
                Type::getInt8Ty(Ctx.M.getContext()), NativeBase,
                ConstantInt::get(Type::getInt64Ty(Ctx.M.getContext()),
                                 ObjectOffset));
          }
          GEP->setOperand(0, NativeBase);
          ++Count;
        }
      }
    }
  }

  Ctx.Report.DataRefsRewritten = Count;
  if (Ctx.Debug && Count > 0)
    errs() << "[brighten-global-data] rewritten " << Count
           << " data references\n";

  return AliasChanged || Count > 0;
}



bool BrightenGlobalDataRecoveryPass::RewriteGuestPointerTranslatorCalls(
    GlobalDataContext &Ctx) {
  Module &M = Ctx.M;
  Function *TranslateFn = M.getFunction("__translate_guest_pointer");
  if (!TranslateFn)
    return false;

  bool Changed = false;
  unsigned TranslatorCount = 0;
  SmallVector<CallInst *, 64> Calls;
  for (User *U : TranslateFn->users()) {
    if (auto *CI = dyn_cast<CallInst>(U)) {
      if (CI->getCalledFunction() == TranslateFn) {
        Calls.push_back(CI);
      }
    }
  }

  for (CallInst *CI : Calls) {
    Value *AddrVal = CI->getArgOperand(0);

    // Case 1: Constant address
    if (auto *CI_Addr = dyn_cast<ConstantInt>(AddrVal)) {
      uint64_t Addr = CI_Addr->getZExtValue();
      const RecoveredObject *Obj = Ctx.findObjectAt(Addr);
      if (Obj && Obj->GV) {
        IRBuilder<> Builder(CI);
        Value *NewPtr = CreateGEPToObject(Builder, const_cast<RecoveredObject *>(Obj), Addr);
        if (NewPtr) {
          if (NewPtr->getType() != CI->getType()) {
            NewPtr = Builder.CreateBitCast(NewPtr, CI->getType());
          }
          CI->replaceAllUsesWith(NewPtr);
          CI->eraseFromParent();
          Changed = true;
          ++TranslatorCount;
          continue;
        }
      }
    }
  }

  if (TranslatorCount > 0) {
    Ctx.Report.DataRefsRewritten += TranslatorCount;
  }



  return Changed;
}

} // namespace brighten_global
