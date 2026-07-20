#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

// The external-call bridge runs before global recovery and therefore may
// leave an integer-typed libc argument as `guest_base + dynamic_index` after
// the translator call has been simplified away.  At that point the argument
// is still an integer because McSema's declaration uses i64 for pointers.
// Repair the call operand directly once the recovered segment metadata is
// available.  This covers the common memcmp/strcmp family without touching
// ordinary native heap or stack integers.
bool isRecoveredPointerExternalArgument(StringRef Name,
                                               unsigned Index) {
  // McSema lowers variadic arguments to the same i64 carrier.  For printf
  // and scanf the format string determines whether a value is numeric or a
  // pointer; passing a native fallback through the mapper is value-preserving
  // for numeric integers and fixes the %s / %p / scanf pointer cases.
  if (Name == "printf" || Name == "__isoc99_scanf" || Name == "scanf")
    return true;
  if (Name == "free" || Name == "puts" || Name == "printf" ||
      Name == "__isoc99_scanf" || Name == "scanf" || Name == "strlen" ||
      Name == "strcmp" || Name == "strncmp" || Name == "strcpy" ||
      Name == "strncpy" || Name == "strcat" || Name == "strncat" ||
      Name == "strstr" || Name == "strchr" || Name == "strrchr" ||
      Name == "memcpy" || Name == "memmove" || Name == "memcmp")
    return Index < 2;
  if (Name == "memset")
    return Index == 0;
  if (Name == "fgets")
    return Index == 0 || Index == 2;
  if (Name == "fread" || Name == "fwrite")
    return Index == 0 || Index == 3;
  if (Name == "realloc")
    return Index == 0;
  return false;
}

Function *getOrCreateRecoveredDataPointerMapper(Module &M) {
  if (Function *Existing = M.getFunction("__brighten_native_data_pointer"))
    return Existing;

  struct Range {
    GlobalVariable *GV;
    uint64_t Begin;
    uint64_t End;
    unsigned Priority;
  };
  SmallVector<Range, 16> Ranges;
  for (GlobalVariable &GV : M.globals()) {
    MDNode *RangeMD = GV.getMetadata("brighten.guest.range");
    if (!RangeMD || RangeMD->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(RangeMD->getOperand(0));
    auto *EndMD = dyn_cast<ConstantAsMetadata>(RangeMD->getOperand(1));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue()) : nullptr;
    auto *End = EndMD ? dyn_cast<ConstantInt>(EndMD->getValue()) : nullptr;
    if (!Begin || !End)
      continue;
    bool Duplicate = false;
    for (const Range &R : Ranges)
      Duplicate |= R.Begin == Begin->getZExtValue() &&
                   R.End == End->getZExtValue();
    if (!Duplicate)
      Ranges.push_back({&GV, Begin->getZExtValue(), End->getZExtValue()});
  }
  if (Ranges.empty())
    return nullptr;

  LLVMContext &Ctx = M.getContext();
  Type *I64 = Type::getInt64Ty(Ctx);
  Type *PtrTy = PointerType::getUnqual(Ctx);
  Function *Mapper = Function::Create(
      FunctionType::get(PtrTy, {I64}, false), GlobalValue::InternalLinkage,
      "__brighten_native_data_pointer", M);
  Mapper->setDSOLocal(true);
  Argument *Address = Mapper->getArg(0);
  Address->setName("guest_or_native_address");
  BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", Mapper);
  IRBuilder<> EntryBuilder(Entry);
  BasicBlock *Current = Entry;
  for (size_t I = 0; I < Ranges.size(); ++I) {
    BasicBlock *Hit = BasicBlock::Create(Ctx, "data.hit", Mapper);
    BasicBlock *Next = BasicBlock::Create(Ctx, "data.next", Mapper);
    IRBuilder<> B(Current);
    Value *AtOrAfter = B.CreateICmpUGE(Address, B.getInt64(Ranges[I].Begin));
    Value *BeforeEnd = B.CreateICmpULT(Address, B.getInt64(Ranges[I].End));
    Value *InRange = B.CreateAnd(AtOrAfter, BeforeEnd);
    B.CreateCondBr(InRange, Hit, Next);

    IRBuilder<> HitBuilder(Hit);
    Value *Offset = HitBuilder.CreateSub(Address, HitBuilder.getInt64(Ranges[I].Begin));
    Value *NativePtr = HitBuilder.CreateGEP(
        HitBuilder.getInt8Ty(), Ranges[I].GV, Offset, "native.data.dynamic.ptr");
    HitBuilder.CreateRet(NativePtr);
    Current = Next;
  }
  IRBuilder<> Fallback(Current);
  Fallback.CreateRet(Fallback.CreateIntToPtr(Address, PtrTy,
                                              "native.address.fallback"));
  return Mapper;
}

GlobalVariable *getOrCreateRecoveredOobScratch(Module &M) {
  constexpr uint64_t OobScratchBytes = 1u << 20;
  if (GlobalVariable *Existing =
          M.getNamedGlobal("native.recovered.oob.scratch"))
    return Existing;
  auto *ScratchTy =
      ArrayType::get(Type::getInt8Ty(M.getContext()), OobScratchBytes);
  auto *Scratch = new GlobalVariable(
      M, ScratchTy, false, GlobalValue::InternalLinkage,
      ConstantAggregateZero::get(ScratchTy), "native.recovered.oob.scratch");
  Scratch->setAlignment(Align(1));
  return Scratch;
}

Value *createRecoveredOobScratchPointer(Module &M, IRBuilder<> &B,
                                               Value *GuestAddress,
                                               StringRef Name) {
  constexpr uint64_t OobScratchBytes = 1u << 20;
  constexpr uint64_t MaxAccessBytes = 8;
  if (!GuestAddress || !GuestAddress->getType()->isIntegerTy())
    return nullptr;
  Value *Key = GuestAddress;
  if (!Key->getType()->isIntegerTy(64))
    Key = B.CreateZExtOrTrunc(Key, B.getInt64Ty(), (Name + ".key").str());
  GlobalVariable *Scratch = getOrCreateRecoveredOobScratch(M);
  Value *Offset = B.CreateAnd(Key, B.getInt64(OobScratchBytes - MaxAccessBytes),
                              (Name + ".offset").str());
  return B.CreateInBoundsGEP(Scratch->getValueType(), Scratch,
                             {B.getInt64(0), Offset}, Name);
}

// Lower a guest-address integer at the use site.  Keeping the range dispatch
// inline avoids introducing a native helper whose only purpose is to translate
// the old guest address space; the final IR then contains ordinary native GEPs
// and a dynamic native-pointer fallback for values that are already native.
Value *materializeRecoveredDataPointer(Module &M, IRBuilder<> &B,
                                              Value *Address) {
  if (!Address || !Address->getType()->isIntegerTy())
    return nullptr;

  LLVMContext &Ctx = M.getContext();
  if (Value *NativeCarrier = getDirectNativePointerCarrier(Address)) {
    // Range dispatches produced by this function are already the complete
    // guest-or-native mapping.  Their fallback intentionally remains a raw
    // inttoptr so an address outside every proven object keeps its original
    // fault behavior; that fallback makes the generic native-pointer
    // classifier reject the select and used to cause a second range rebase.
    // Recognize our own generated carrier explicitly to make lowering
    // idempotent across repeated cleanup sweeps.
    if (NativeCarrier->hasName() &&
        NativeCarrier->getName().starts_with("native.data.pointer.select"))
      return NativeCarrier;
    SmallPtrSet<Value *, 16> Seen;
    if (isNativePointerValue(NativeCarrier, Seen))
      return NativeCarrier;
  }

  Type *I64 = Type::getInt64Ty(Ctx);
  Value *Address64 = Address;
  if (Address64->getType() != I64)
    Address64 = B.CreateZExtOrTrunc(Address64, I64, "native.data.address");
  SmallPtrSet<Value *, 32> StackSeen;
  if (containsNativeStackInteger(Address, StackSeen))
    return B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                            "native.stack.address.fallback");
  SmallPtrSet<Value *, 32> NativeSeen;
  if (isNativeInteger(Address, NativeSeen))
    return B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                            "native.integer.pointer");

  struct Range {
    GlobalVariable *GV;
    uint64_t Begin;
    uint64_t End;
    unsigned Priority;
  };
  SmallVector<Range, 16> Ranges;
  uint64_t MinGuest = std::numeric_limits<uint64_t>::max();
  uint64_t MaxGuest = 0;
  for (GlobalVariable &GV : M.globals()) {
    MDNode *RangeMD = GV.getMetadata("brighten.guest.range");
    if (!RangeMD || RangeMD->getNumOperands() != 2)
      continue;
    auto *BeginMD = dyn_cast<ConstantAsMetadata>(RangeMD->getOperand(0));
    auto *EndMD = dyn_cast<ConstantAsMetadata>(RangeMD->getOperand(1));
    auto *Begin = BeginMD ? dyn_cast<ConstantInt>(BeginMD->getValue())
                          : nullptr;
    auto *End = EndMD ? dyn_cast<ConstantInt>(EndMD->getValue()) : nullptr;
    if (!Begin || !End || Begin->getZExtValue() >= End->getZExtValue())
      continue;
    uint64_t BeginValue = Begin->getZExtValue();
    uint64_t EndValue = End->getZExtValue();
    StringRef Name = GV.getName();
    unsigned Priority = 1;
    if (Name.starts_with("native_data_") ||
        Name.starts_with("native_residual_") ||
        Name.starts_with("dyn_bytes_") ||
        Name.starts_with("g_bytes_"))
      Priority = 0;
    if (Name.starts_with("g_arr_") || Name.starts_with("g_scalar_"))
      Priority = 2;
    Ranges.push_back({&GV, BeginValue, EndValue, Priority});
    MinGuest = std::min(MinGuest, BeginValue);
    MaxGuest = std::max(MaxGuest, EndValue);
  }
  if (Ranges.empty())
    return B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                            "native.address.fallback");

  Value *RawFallback = B.CreateIntToPtr(Address64, PointerType::getUnqual(Ctx),
                                        "native.address.fallback");
  // Type/object recovery can split one guest data segment into compact typed
  // globals.  A value that falls in no recovered object is not a proven native
  // object access.  Do not silently redirect such gaps to scratch: raw fuzzing
  // can drive negative indices into unmapped guest addresses, and the original
  // binary observes that as a fault.  Keep the raw fallback unless a concrete
  // recovered range below proves a native object mapping.
  llvm::stable_sort(Ranges, [](const Range &L, const Range &R) {
    if (L.Priority != R.Priority)
      return L.Priority < R.Priority;
    uint64_t LSize = L.End - L.Begin;
    uint64_t RSize = R.End - R.Begin;
    if (LSize != RSize)
      return LSize > RSize;
    return L.Begin < R.Begin;
  });
  Value *Result = RawFallback;
  for (const Range &R : Ranges) {
    Value *AtOrAfter = B.CreateICmpUGE(Address64, B.getInt64(R.Begin));
    Value *BeforeEnd = B.CreateICmpULT(Address64, B.getInt64(R.End));
    Value *InRange = B.CreateAnd(AtOrAfter, BeforeEnd);
    Value *Offset = B.CreateSub(Address64, B.getInt64(R.Begin));
    Value *NativePtr = B.CreateGEP(B.getInt8Ty(), R.GV, Offset,
                                   "native.data.dynamic.ptr");
    Result = B.CreateSelect(InRange, NativePtr, Result,
                            "native.data.pointer.select");
  }
  return Result;
}

// Frame lowering preserves the contents of a guest stack slot, but that slot
// can itself hold a guest BSS pointer.  The later load then becomes an
// inttoptr whose operand has no remaining constant-expression provenance, so
// rewriteDynamicGuestAddressIntToPtr cannot recognize it.  Resolve every
// residual generic-pointer conversion against the recovered ranges after the
// stack-specific rewrite has run.  Native addresses retain their original
// behavior through materializeRecoveredDataPointer's fallback arm.
unsigned rewriteResidualRecoveredDataIntToPtrs(Module &M,
                                                       bool &Changed) {
  bool HasRanges = false;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.getMetadata("brighten.guest.range")) {
      HasRanges = true;
      break;
    }
  }
  if (!HasRanges)
    return 0;

  SmallVector<IntToPtrInst *, 128> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *ITP = dyn_cast<IntToPtrInst>(&I);
        if (!ITP || !ITP->getOperand(0)->getType()->isIntegerTy() ||
            ITP->getType()->getPointerAddressSpace() != 0 ||
            ITP->getName().starts_with("native.address.fallback"))
          continue;
        Candidates.push_back(ITP);
      }
    }
  }

  unsigned Rewritten = 0;
  for (IntToPtrInst *ITP : Candidates) {
    if (!ITP->getParent())
      continue;
    IRBuilder<> B(ITP);
    Value *NativePtr =
        materializeRecoveredDataPointer(M, B, ITP->getOperand(0));
    if (!NativePtr)
      continue;
    if (NativePtr->getType() != ITP->getType())
      NativePtr = B.CreatePointerCast(NativePtr, ITP->getType(),
                                      "native.residual.ptr.cast");
    ITP->replaceAllUsesWith(NativePtr);
    ITP->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

Value *
findMaterializedRecoveredGuestAddress(Value *V, SmallPtrSetImpl<Value *> &Seen) {
  if (!V || !Seen.insert(V).second)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *Sel = dyn_cast<SelectInst>(V)) {
    if (Value *Addr =
            findMaterializedRecoveredGuestAddress(Sel->getTrueValue(), Seen))
      return Addr;
    return findMaterializedRecoveredGuestAddress(Sel->getFalseValue(), Seen);
  }
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP ||
      GEP->getSourceElementType() != Type::getInt8Ty(V->getContext()) ||
      GEP->getNumIndices() != 1)
    return nullptr;
  Value *Index = *GEP->idx_begin();
  if (!Index || isa<ConstantInt>(Index) || !Index->getType()->isIntegerTy())
    return nullptr;

  if (auto *DirectGV = dyn_cast<GlobalVariable>(
          GEP->getPointerOperand()->stripPointerCasts())) {
    if (!DirectGV->isDeclaration() &&
        DirectGV->getMetadata("brighten.guest.range")) {
      if (auto *BO = dyn_cast<BinaryOperator>(Index)) {
        if (BO->getOpcode() == Instruction::Sub &&
            isa<ConstantInt>(BO->getOperand(1)) &&
            BO->getOperand(0)->getType()->isIntegerTy())
          return BO->getOperand(0);
        if (BO->getOpcode() == Instruction::Add) {
          if (isa<ConstantInt>(BO->getOperand(1)) &&
              BO->getOperand(0)->getType()->isIntegerTy())
            return BO->getOperand(0);
          if (isa<ConstantInt>(BO->getOperand(0)) &&
              BO->getOperand(1)->getType()->isIntegerTy())
            return BO->getOperand(1);
        }
      }
    }
  }

  auto *BaseGEP = dyn_cast<GEPOperator>(GEP->getPointerOperand());
  if (!BaseGEP || BaseGEP->getSourceElementType() !=
                      Type::getInt8Ty(V->getContext()) ||
      BaseGEP->getNumIndices() != 1 ||
      !isa<ConstantInt>(*BaseGEP->idx_begin()))
    return nullptr;
  auto *GV = dyn_cast_or_null<GlobalVariable>(
      BaseGEP->getPointerOperand()->stripPointerCasts());
  if (!GV || GV->isDeclaration() ||
      !GV->getMetadata("brighten.guest.range"))
    return nullptr;
  return Index;
}

// In flat guest memory, inttoptr(A) followed by byte GEP K means address A+K.
// If A is first materialized to a compact recovered LLVM global, the host GEP
// can cross an artificial object boundary.  Dispatch the adjusted guest
// address instead.
unsigned rewriteMaterializedRecoveredPointerByteGEPs(Module &M,
                                                            bool &Changed) {
  SmallVector<GetElementPtrInst *, 128> Candidates;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I))
          if (GEP->getSourceElementType() == Type::getInt8Ty(M.getContext()) &&
              GEP->getNumIndices() == 1 &&
              isa<ConstantInt>(*GEP->idx_begin()) &&
              !cast<ConstantInt>(*GEP->idx_begin())->isZero())
            Candidates.push_back(GEP);
  }

  unsigned Rewritten = 0;
  for (GetElementPtrInst *GEP : Candidates) {
    if (!GEP->getParent())
      continue;
    SmallPtrSet<Value *, 16> Seen;
    Value *GuestAddress =
        findMaterializedRecoveredGuestAddress(GEP->getPointerOperand(), Seen);
    if (!GuestAddress)
      continue;

    auto *Index = cast<ConstantInt>(*GEP->idx_begin());
    IRBuilder<> B(GEP);
    Value *Address64 = GuestAddress;
    if (!Address64->getType()->isIntegerTy(64))
      Address64 = B.CreateZExtOrTrunc(Address64, B.getInt64Ty(),
                                      "native.byte.gep.base");
    Value *AdjustedAddress =
        B.CreateAdd(Address64,
                    ConstantInt::get(B.getInt64Ty(), Index->getSExtValue(),
                                     true),
                    "native.byte.gep.address");
    Value *NativePtr = materializeRecoveredDataPointer(M, B, AdjustedAddress);
    if (!NativePtr)
      continue;
    if (NativePtr->getType() != GEP->getType())
      NativePtr = B.CreatePointerCast(NativePtr, GEP->getType(),
                                      "native.byte.gep.ptr.cast");
    GEP->replaceAllUsesWith(NativePtr);
    GEP->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

unsigned rewriteRecoveredGlobalStackIndexedGEPs(Module &M,
                                                       bool &Changed) {
  auto StackIndexForRecoveredGEP = [](Value *V) -> Value * {
    auto *GEP = dyn_cast<GEPOperator>(V ? V->stripPointerCasts() : nullptr);
    if (!GEP || GEP->getNumIndices() != 1 ||
        !GEP->getSourceElementType()->isIntegerTy(8))
      return nullptr;
    auto *GV = dyn_cast<GlobalVariable>(
        GEP->getPointerOperand()->stripPointerCasts());
    if (!GV || !GV->getName().starts_with("g_arr_"))
      return nullptr;
    Value *Index = *GEP->idx_begin();
    if (!Index || !Index->getType()->isIntegerTy())
      return nullptr;
    SmallPtrSet<Value *, 32> Seen;
    if (!containsNativeStackInteger(Index, Seen))
      return nullptr;
    return Index;
  };

  unsigned Rewritten = 0;
  SmallVector<GetElementPtrInst *, 32> GEPs;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *GEP = dyn_cast<GetElementPtrInst>(&I)) {
          if (StackIndexForRecoveredGEP(GEP))
            GEPs.push_back(GEP);
        }
      }
    }
  }
  for (GetElementPtrInst *GEP : GEPs) {
    if (!GEP->getParent())
      continue;
    Value *Index = StackIndexForRecoveredGEP(GEP);
    if (!Index)
      continue;
    IRBuilder<> B(GEP);
    Value *NativePtr =
        B.CreateIntToPtr(Index, GEP->getType(), "native.stack.gep.recovered");
    GEP->replaceAllUsesWith(NativePtr);
    GEP->eraseFromParent();
    ++Rewritten;
    Changed = true;
  }

  SmallVector<std::tuple<Instruction *, unsigned, ConstantExpr *>, 64> Operands;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo) {
          auto *CE = dyn_cast<ConstantExpr>(I.getOperand(OpNo));
          if (CE && CE->getOpcode() == Instruction::GetElementPtr &&
              StackIndexForRecoveredGEP(CE))
            Operands.emplace_back(&I, OpNo, CE);
        }
      }
    }
  }
  for (auto [I, OpNo, CE] : Operands) {
    if (!I->getParent())
      continue;
    Value *Index = StackIndexForRecoveredGEP(CE);
    if (!Index)
      continue;
    IRBuilder<> B(I);
    Value *NativePtr =
        B.CreateIntToPtr(Index, CE->getType(), "native.stack.gep.recovered");
    I->setOperand(OpNo, NativePtr);
    ++Rewritten;
    Changed = true;
  }
  return Rewritten;
}

unsigned rewriteRecoveredExternalPointerArguments(Module &M,
                                                          bool &Changed,
                                                          bool ScanfOnly) {
  auto LowerStackPointerArms = [&](Value *Root, Function &F) {
    SmallVector<Value *, 32> Worklist;
    SmallPtrSet<Value *, 32> Seen;
    Worklist.push_back(Root);
    while (!Worklist.empty()) {
      Value *V = Worklist.pop_back_val();
      if (!V || !Seen.insert(V).second)
        continue;
      if (auto *ITP = dyn_cast<IntToPtrInst>(V)) {
        if (!ITP->getOperand(0)->getType()->isIntegerTy())
          continue;
        IRBuilder<> B(ITP);
        if (Value *NativePtr = lowerNativeStackInteger(
                B, ITP->getOperand(0), F)) {
          if (NativePtr->getType() != ITP->getType())
            NativePtr = B.CreatePointerCast(NativePtr, ITP->getType(),
                                            "native.scanf.stack.ptr.cast");
          ITP->replaceAllUsesWith(NativePtr);
          ITP->eraseFromParent();
          Changed = true;
        }
        continue;
      }
      if (auto *I = dyn_cast<Instruction>(V)) {
        for (Value *Op : I->operands())
          if (Op->getType()->isPointerTy())
            Worklist.push_back(Op);
      } else if (auto *CE = dyn_cast<ConstantExpr>(V)) {
        for (Value *Op : CE->operands())
          if (Op->getType()->isPointerTy())
            Worklist.push_back(Op);
      }
    }
  };
  unsigned Rewritten = 0;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!CB || !Callee || !Callee->isDeclaration())
          continue;
        StringRef Name = Callee->getName();
        if (ScanfOnly && Name != "scanf" && Name != "__isoc99_scanf")
          continue;
        for (unsigned Index = 0; Index < CB->arg_size(); ++Index) {
          if (!isRecoveredPointerExternalArgument(Name, Index))
            continue;
          Value *Arg = CB->getArgOperand(Index);
          IRBuilder<> B(CB);
          if (Arg->getType()->isPointerTy()) {
            // scanf destinations can be a recovered-data select whose
            // fallback arm is an inttoptr carrying a guest stack address.
            // Normalize only proven stack arms; global/data arms remain
            // untouched and retain their range dispatch.
            LowerStackPointerArms(Arg, *CB->getFunction());
            // The root argument itself may have been an inttoptr.  In that
            // case LowerStackPointerArms RAUWs it with the recovered frame
            // GEP and erases the old instruction; refresh the call operand
            // before doing any further type/provenance inspection.
            Arg = CB->getArgOperand(Index);
            if (!Arg || !Arg->getType()->isPointerTy())
              continue;
            // LowerStackPointerArms has already reconstructed this argument
            // from the recovered frame.  Do not subsequently search through
            // its integer index expression for a vararg carrier: a lifted
            // RBP/RSP PHI may also carry unrelated function-pointer values on
            // other dispatcher edges.  Peeling one of those nested carriers
            // replaces a correct scanf destination with (for example) a
            // callback address.
            SmallPtrSet<Value *, 16> StackArgSeen;
            if (isNativeStackPointer(Arg, StackArgSeen)) {
              ++Rewritten;
              continue;
            }
            SmallPtrSet<Value *, 32> VarargSeen;
            if (Value *NativeCarrier =
                    findNativeVarargAddressCarrier(Arg, VarargSeen)) {
              if (NativeCarrier->getType() != Arg->getType())
                NativeCarrier = B.CreatePointerCast(
                    NativeCarrier, Arg->getType(),
                    "native.vararg.pointer.cast");
              CB->setArgOperand(Index, NativeCarrier);
              ++Rewritten;
              Changed = true;
              continue;
            }
            Value *GuestAddress = nullptr;
            if (auto *ITP = dyn_cast<IntToPtrInst>(Arg))
              GuestAddress = ITP->getOperand(0);
            else if (auto *CE = dyn_cast<ConstantExpr>(Arg)) {
              if (CE->getOpcode() == Instruction::IntToPtr)
                GuestAddress = CE->getOperand(0);
            }
            if (!GuestAddress || !GuestAddress->getType()->isIntegerTy())
              continue;
            Value *NativePtr = lowerNativeStackInteger(
                B, GuestAddress, *CB->getFunction());
            if (!NativePtr)
              NativePtr = materializeRecoveredDataPointer(M, B, GuestAddress);
            if (!NativePtr)
              continue;
            CB->setArgOperand(Index, NativePtr);
            ++Rewritten;
            Changed = true;
            continue;
          }
          if (!Arg->getType()->isIntegerTy())
            continue;
          // A recovered string/global already has a real native address.  It
          // is commonly carried through McSema's integer pointer carrier as
          // ptrtoint(native_object); sending it through the guest-range
          // mapper would needlessly resurrect every temporary segment copy.
          if (auto *PTI = dyn_cast<PtrToIntInst>(Arg)) {
            SmallPtrSet<Value *, 16> Seen;
            if (isNativePointerValue(PTI->getPointerOperand(), Seen))
              continue;
          } else if (auto *CE = dyn_cast<ConstantExpr>(Arg)) {
            if (CE->getOpcode() == Instruction::PtrToInt) {
              SmallPtrSet<Value *, 16> Seen;
              if (isNativePointerValue(CE->getOperand(0), Seen))
                continue;
            }
          }
          Value *NativePtr = lowerNativeStackInteger(
              B, Arg, *CB->getFunction());
          if (!NativePtr)
            NativePtr = materializeRecoveredDataPointer(M, B, Arg);
          if (!NativePtr)
            continue;
          Value *NativeAddr = B.CreatePtrToInt(
              NativePtr, Arg->getType(), "native.external.addr");
          CB->setArgOperand(Index, NativeAddr);
          ++Rewritten;
          Changed = true;
        }
      }
    }
  }
  return Rewritten;
}

unsigned rewriteNativeVarargExternalPointerArguments(Module &M,
                                                            bool &Changed) {
  unsigned Rewritten = 0;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!CB || !Callee || !Callee->isDeclaration())
          continue;
        StringRef Name = Callee->getName();
        for (unsigned Index = 0; Index < CB->arg_size(); ++Index) {
          if (!isRecoveredPointerExternalArgument(Name, Index))
            continue;
          Value *Arg = CB->getArgOperand(Index);
          if (!Arg || !Arg->getType()->isPointerTy())
            continue;
          // A preceding stack-address sweep may already have replaced the
          // raw inttoptr with a recovered-frame GEP.  Searching inside that
          // GEP can reach unrelated native.vararg.address values through a
          // dispatcher PHI and incorrectly peel out a callback/global arm.
          SmallPtrSet<Value *, 16> StackSeen;
          if (isNativeStackPointer(Arg, StackSeen))
            continue;
          SmallPtrSet<Value *, 32> Seen;
          Value *NativeCarrier = findNativeVarargAddressCarrier(Arg, Seen);
          if (!NativeCarrier)
            NativeCarrier = findNativeVarargCarrierInRecoveredDispatch(Arg);
          if (!NativeCarrier || NativeCarrier == Arg)
            continue;
          IRBuilder<> B(CB);
          if (NativeCarrier->getType() != Arg->getType())
            NativeCarrier = B.CreatePointerCast(
                NativeCarrier, Arg->getType(), "native.vararg.pointer.cast");
          CB->setArgOperand(Index, NativeCarrier);
          ++Rewritten;
          Changed = true;
        }
      }
    }
  }
  return Rewritten;
}

unsigned rewriteRecoveredVarargSaveSlots(Module &M, bool &Changed) {
  struct FormatRule {
    AllocaInst *RegSaveArea = nullptr;
    SmallVector<unsigned, 8> PointerOffsets;
  };

  const DataLayout &DL = M.getDataLayout();
  SmallVector<FormatRule, 32> Rules;
  SmallPtrSet<AllocaInst *, 32> UnresolvedPrintfRegSaveAreas;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!CB || !Callee || CB->arg_empty())
          continue;
        StringRef Name = Callee->getName();
        bool IsScanf = Name == "vscanf" || Name == "vfscanf" ||
                       Name == "vsscanf";
        bool IsPrintf = Name == "vprintf" || Name == "vfprintf" ||
                        Name == "vsprintf" || Name == "vsnprintf";
        if (!IsScanf && !IsPrintf)
          continue;

        unsigned FormatIndex = 0;
        unsigned FixedArguments = 1;
        if (Name == "vfprintf" || Name == "vfscanf") {
          FormatIndex = 1;
          FixedArguments = 2;
        } else if (Name == "vsprintf" || Name == "vsscanf") {
          FormatIndex = 1;
          FixedArguments = 2;
        } else if (Name == "vsnprintf") {
          FormatIndex = 2;
          FixedArguments = 3;
        }
        if (FormatIndex >= CB->arg_size() - 1)
          continue;
        auto Format = readConstantFormatString(CB->getArgOperand(FormatIndex),
                                               DL);
        if (!Format)
          continue;

        AllocaInst *VAList = getRootAlloca(CB->getArgOperand(CB->arg_size() - 1));
        if (!VAList)
          continue;
        AllocaInst *RegSaveArea = nullptr;
        for (BasicBlock &ScanBB : F) {
          for (Instruction &ScanI : ScanBB) {
            auto *SI = dyn_cast<StoreInst>(&ScanI);
            if (!SI)
              continue;
            auto Offset = getConstantGEPByteOffset(
                SI->getPointerOperand(), VAList, DL);
            if (Offset && *Offset == 16) {
              RegSaveArea = getRootAlloca(SI->getValueOperand());
              break;
            }
          }
          if (RegSaveArea)
            break;
        }
        if (!RegSaveArea) {
          // Some optimized lifted forms hide the store of va_list.reg_save_area
          // behind a cast/phi.  The save area is still an explicit alloca in
          // this function; use it as a conservative fallback for scanf-only
          // pointer slots rather than leaving guest addresses in va_list.
          for (BasicBlock &FallbackBB : F) {
            for (Instruction &FallbackI : FallbackBB) {
              auto *AI = dyn_cast<AllocaInst>(&FallbackI);
              if (AI && AI->getName().contains("reg_save_area")) {
                RegSaveArea = AI;
                break;
              }
            }
            if (RegSaveArea)
              break;
          }
        }
        if (!RegSaveArea)
          continue;

        FormatRule Rule;
        Rule.RegSaveArea = RegSaveArea;
        collectFormatPointerSlots(*Format, IsScanf, FixedArguments * 8,
                                  Rule.PointerOffsets);
        if (IsPrintf && !formatHasAnyConversion(*Format))
          UnresolvedPrintfRegSaveAreas.insert(RegSaveArea);
        if (IsScanf) {
          // Every non-suppressed scanf conversion consumes a pointer.  Keep
          // the first GP slots covered even when format provenance was folded
          // and the parser could not recover a conversion list.
          for (unsigned Offset = FixedArguments * 8; Offset <= 40;
               Offset += 8)
            Rule.PointerOffsets.push_back(Offset);
        }
        Rules.push_back(Rule);
      }
    }
  }

  unsigned Rewritten = 0;
  SmallPtrSet<StoreInst *, 32> Seen;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *SI = dyn_cast<StoreInst>(&I);
        if (!SI || !IsNativeVarargSaveSlot(SI->getPointerOperand()))
          continue;
        auto *SlotRoot = getRootAlloca(SI->getPointerOperand());
        auto SlotOffset = getConstantGEPByteOffset(
            SI->getPointerOperand(), SlotRoot, DL);
        if (!SlotRoot || !SlotOffset)
          continue;

        bool IsPointerSlot = false;
        for (const FormatRule &Rule : Rules) {
          if (Rule.RegSaveArea != SlotRoot)
            continue;
          for (unsigned PointerOffset : Rule.PointerOffsets) {
            if (PointerOffset == *SlotOffset) {
              IsPointerSlot = true;
              break;
            }
          }
        if (IsPointerSlot)
          break;
        }
        if (!IsPointerSlot &&
            UnresolvedPrintfRegSaveAreas.contains(SlotRoot)) {
          if (auto *CI = dyn_cast<ConstantInt>(SI->getValueOperand())) {
            if (FindRecoveredGlobalForGuestAddress(M, CI->getZExtValue()))
              IsPointerSlot = true;
          }
        }
        if (!IsPointerSlot || !Seen.insert(SI).second)
          continue;

        Value *Stored = SI->getValueOperand();
        IRBuilder<> B(SI);
        if (Stored->getType()->isIntegerTy()) {
          // Global-data recovery may already have converted this slot to
          // ptrtoint(native_object).  Feeding that native address through the
          // guest-range mapper again rebases it a second time and produces an
          // invalid pointer such as native_base + (native_addr - guest_base).
          Value *NativeCarrier = nullptr;
          if (auto *PTI = dyn_cast<PtrToIntInst>(Stored))
            NativeCarrier = PTI->getPointerOperand();
          else if (auto *CE = dyn_cast<ConstantExpr>(Stored)) {
            if (CE->getOpcode() == Instruction::PtrToInt)
              NativeCarrier = CE->getOperand(0);
          }
          if (NativeCarrier) {
            SmallPtrSet<Value *, 16> NativeSeen;
            if (isNativePointerValue(NativeCarrier, NativeSeen))
              continue;
          }
          // scanf destination slots may carry either a guest-stack address or
          // a recovered BSS/global address.  Resolve the exact recovered data
          // object first: a State-derived global integer can otherwise look
          // stack-provenant and gets rebased into frame_storage_backing, so
          // scanf writes input where the program never reads it.
          Value *NativePtr = nullptr;
          if (auto *CI = dyn_cast<ConstantInt>(Stored)) {
            if (auto Match = FindRecoveredGlobalForGuestAddress(
                    M, CI->getZExtValue())) {
              NativePtr = B.CreateConstGEP1_64(
                  B.getInt8Ty(), Match->first, Match->second,
                  "native.vararg.constant.ptr");
            }
          }
          if (!NativePtr)
            NativePtr = materializeRecoveredDataPointer(M, B, Stored);
          if (!NativePtr)
            NativePtr = lowerNativeStackInteger(
                B, Stored, *SI->getFunction());
          if (!NativePtr)
            continue;
          Value *NativeAddr = B.CreatePtrToInt(NativePtr, Stored->getType(),
                                               "native.vararg.address");
          SI->setOperand(0, NativeAddr);
          ++Rewritten;
          Changed = true;
        } else if (Stored->getType()->isPointerTy()) {
          Value *GuestAddress = nullptr;
          if (auto *ITP = dyn_cast<IntToPtrInst>(Stored))
            GuestAddress = ITP->getOperand(0);
          else if (auto *CE = dyn_cast<ConstantExpr>(Stored)) {
            if (CE->getOpcode() == Instruction::IntToPtr)
              GuestAddress = CE->getOperand(0);
          }
          if (!GuestAddress || !GuestAddress->getType()->isIntegerTy())
            continue;
          Value *NativePtr = materializeRecoveredDataPointer(
              M, B, GuestAddress);
          if (!NativePtr)
            continue;
          SI->setOperand(0, NativePtr);
          ++Rewritten;
          Changed = true;
        }
    }
  }
  }
  return Rewritten;
}

} // namespace brighten_native_cleanup
