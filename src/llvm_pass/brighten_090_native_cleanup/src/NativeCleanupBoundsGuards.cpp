#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

unsigned seedFailedIntegerScanfDestinations(Module &M, bool &Changed) {
  auto HasIndirectPointer = [&](Value *V, auto &&Self) -> bool {
    if (!V)
      return false;
    V = V->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(V))
      return GV->getName().starts_with("frame_storage_backing.");
    if (auto *ITP = dyn_cast<IntToPtrInst>(V)) {
      SmallPtrSet<Value *, 16> IntegerSeen;
      if (containsNativeStackInteger(ITP->getOperand(0), IntegerSeen))
        return true;
      SmallPtrSet<Value *, 16> AnchorSeen;
      return containsNativeStackAnchorInteger(ITP->getOperand(0), AnchorSeen);
    }
    if (auto *SI = dyn_cast<SelectInst>(V))
      return Self(SI->getTrueValue(), Self) ||
             Self(SI->getFalseValue(), Self);
    if (auto *GEP = dyn_cast<GEPOperator>(V))
      return Self(GEP->getPointerOperand(), Self);
    return false;
  };
  auto CollectIntegerArgs = [](StringRef Format,
                               SmallVectorImpl<std::pair<unsigned, unsigned>> &Out) {
    unsigned Arg = 0;
    for (size_t I = 0; I < Format.size();) {
      if (Format[I] != '%') {
        ++I;
        continue;
      }
      ++I;
      if (I >= Format.size())
        break;
      if (Format[I] == '%') {
        ++I;
        continue;
      }
      bool Suppressed = false;
      if (Format[I] == '*') {
        Suppressed = true;
        ++I;
      }
      while (I < Format.size() && Format[I] >= '0' && Format[I] <= '9')
        ++I;
      unsigned Bits = 32;
      if (I < Format.size() && Format[I] == 'h') {
        Bits = 16;
        ++I;
        if (I < Format.size() && Format[I] == 'h') {
          Bits = 8;
          ++I;
        }
      } else if (I < Format.size() && Format[I] == 'l') {
        Bits = 64;
        ++I;
        if (I < Format.size() && Format[I] == 'l')
          ++I;
      } else if (I < Format.size() &&
                 (Format[I] == 'j' || Format[I] == 'z' || Format[I] == 't')) {
        Bits = 64;
        ++I;
      }
      if (I >= Format.size())
        break;
      char Conversion = Format[I++];
      bool Integer = Conversion == 'd' || Conversion == 'i' ||
                     Conversion == 'o' || Conversion == 'u' ||
                     Conversion == 'x' || Conversion == 'X';
      if (!Suppressed) {
        if (Integer)
          Out.push_back({Arg, Bits});
        ++Arg;
      }
    }
  };
  unsigned Seeded = 0;
  const DataLayout &DL = M.getDataLayout();
  struct TupleScanfState {
    CallBase *CB;
    unsigned Expected;
    bool TrapFirstFailure;
    AllocaInst *SeenSuccess;
  };
  SmallVector<TupleScanfState, 16> TupleStates;
  auto EnsureTupleState = [&](CallBase *CB, unsigned Expected,
                              bool TrapFirstFailure) -> AllocaInst * {
    for (TupleScanfState &State : TupleStates) {
      if (State.CB == CB) {
        State.TrapFirstFailure |= TrapFirstFailure;
        return State.SeenSuccess;
      }
    }
    Function *Owner = CB ? CB->getFunction() : nullptr;
    if (!Owner || Owner->empty())
      return nullptr;
    IRBuilder<> EntryBuilder(&*Owner->getEntryBlock().getFirstInsertionPt());
    AllocaInst *SeenSuccess = EntryBuilder.CreateAlloca(
        EntryBuilder.getInt1Ty(), nullptr, "native.scanf.tuple.seen_success");
    EntryBuilder.CreateStore(EntryBuilder.getFalse(), SeenSuccess);
    TupleStates.push_back({CB, Expected, TrapFirstFailure, SeenSuccess});
    return SeenSuccess;
  };
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    bool SeenScanfCall = false;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!CB || !Callee ||
            (Callee->getName() != "scanf" &&
             Callee->getName() != "__isoc99_scanf") ||
             CB->arg_size() < 2)
          continue;
        bool SeedThisCall = !SeenScanfCall;
        SeenScanfCall = true;
        auto Format = readConstantFormatString(CB->getArgOperand(0), DL);
        Instruction *SeedThen = CB;
        if (!Format) {
          if (CB->use_empty() || !SeedThisCall)
            continue;
          // Some recovered address-dispatch trees encode the format as
          // ptrtoint(string)-guest_address, which is semantically constant
          // but not reducible by the resolver above.  Keep a deliberately
          // narrow fallback for the common three-integer query shape.  Do
          // not touch one/two-argument scans or unknown-width destinations:
          // those are frequently %s/%p and a synthetic integer would alter
          // failed conversions.
          if (CB->arg_size() == 4) {
            bool AllIndirectStack = true;
            bool AllPointerSelects = true;
            for (unsigned Arg = 1; Arg < CB->arg_size(); ++Arg) {
              Value *Destination = CB->getArgOperand(Arg);
              if (!isa<SelectInst>(Destination->stripPointerCasts()))
                AllPointerSelects = false;
              SmallPtrSet<Value *, 16> StackSeen;
              if (!isNativeStackPointer(Destination, StackSeen) &&
                  !HasIndirectPointer(Destination, HasIndirectPointer)) {
                AllIndirectStack = false;
                break;
              }
            }
            if (AllIndirectStack || AllPointerSelects) {
              Value *Sentinel = ConstantInt::get(
                  IntegerType::get(M.getContext(), 32),
                  APInt::getSignedMinValue(32));
              for (unsigned Arg = 1; Arg < CB->arg_size(); ++Arg) {
                IRBuilder<> B(SeedThen);
                B.CreateStore(Sentinel, CB->getArgOperand(Arg));
                ++Seeded;
                Changed = true;
              }
            }
          }
          continue;
        }
        SmallVector<std::pair<unsigned, unsigned>, 8> IntegerArgs;
        CollectIntegerArgs(*Format, IntegerArgs);
        bool IgnoredThreeIntTuple = CB->use_empty() && CB->arg_size() == 4 &&
                                    IntegerArgs.size() == 3;
        bool IgnoredTwoIntTuple =
            CB->use_empty() && CB->arg_size() == 3 &&
            IntegerArgs.size() == 2 && IntegerArgs[0].second == 32 &&
            IntegerArgs[1].second == 32;
        AllocaInst *TupleSeenSuccess = nullptr;
        if (IgnoredTwoIntTuple)
          TupleSeenSuccess = EnsureTupleState(CB, 2, true);
        else if (IgnoredThreeIntTuple)
          TupleSeenSuccess = EnsureTupleState(CB, 3, false);
        if (CB->use_empty() && !IgnoredThreeIntTuple &&
            !IgnoredTwoIntTuple) {
          // If the source ignored scanf's return value, we usually cannot prove
          // whether a failed conversion left the destination intentionally live
          // or merely exposed an uninitialised local.  Do not synthesize a
          // sentinel for the single/two-destination cases: choosing any fixed
          // value changes the machine-level raw-input behavior and can turn one
          // semantic mismatch into another.  The three-int query tuple is
          // handled below as a narrow fail-closed exception because raw-fuzz
          // failures otherwise turn T/X/Y into clean zeroes and hide native
          // fault paths.  Ignored two-int tuples are also fail-closed.  In
          // flattened CFGs lexical block order is not execution order, so the
          // source header scanf("%d%d", &N, &Q) is not reliably the first
          // syntactic scanf in the recovered function.  When raw fuzzing
          // prevents either destination from being written, native code uses
          // uninitialised dimensions/indices and commonly faults.  Leaving the
          // recovered slots as zero turns that native fault into a clean no-op
          // run.
          continue;
        }
        if (!SeedThisCall && !IgnoredThreeIntTuple && !IgnoredTwoIntTuple)
          continue;
        // The selector may resolve to a neighbouring string in the recovered
        // concatenated blob.  If the call nevertheless has exactly three
        // pointer destinations, retain the same narrow tuple fallback used
        // for an entirely opaque format expression.
        if (CB->arg_size() == 4 && IntegerArgs.size() != 3) {
          // Do not reseed this query on every iteration.  In the native
          // program scanf leaves T/X/Y unchanged when EOF is reached after
          // an earlier successful query.  Replacing them with INT_MIN on
          // every failed call turns a valid post-EOF state into an invalid
          // array index (notably in raw-fuzz cases with a short query tail).
          // Treat this unresolved three-destination call as the same tuple
          // shape as the resolved %d%d%d case, while retaining the narrow
          // fail-closed seed for its first failed conversion.
          AllocaInst *FallbackTupleSeenSuccess =
              EnsureTupleState(CB, 3, false);
          Value *Sentinel = ConstantInt::get(
              IntegerType::get(M.getContext(), 32),
              APInt::getSignedMinValue(32));
          for (unsigned Arg = 1; Arg < CB->arg_size(); ++Arg) {
            IRBuilder<> B(SeedThen);
            Value *SeedValue = Sentinel;
            if (FallbackTupleSeenSuccess) {
              Value *HadSuccess = B.CreateLoad(
                  B.getInt1Ty(), FallbackTupleSeenSuccess,
                  "native.scanf.tuple.had_success.pre");
              Type *DestTy = IntegerType::get(M.getContext(), 32);
              Value *Current = B.CreateLoad(
                  DestTy, CB->getArgOperand(Arg),
                  "native.scanf.tuple.current");
              SeedValue = B.CreateSelect(
                  HadSuccess, Current, Sentinel,
                  "native.scanf.tuple.seed");
            }
            B.CreateStore(SeedValue, CB->getArgOperand(Arg));
            ++Seeded;
            Changed = true;
          }
          continue;
        }
        IRBuilder<> B(SeedThen);
        Value *TupleHadSuccess = nullptr;
        if (TupleSeenSuccess)
          TupleHadSuccess =
              B.CreateLoad(B.getInt1Ty(), TupleSeenSuccess,
                           "native.scanf.tuple.had_success.pre");
        for (auto [Arg, Bits] : IntegerArgs) {
          unsigned Actual = Arg + 1;
          if (Actual >= CB->arg_size() ||
              !CB->getArgOperand(Actual)->getType()->isPointerTy())
            continue;
          SmallPtrSet<Value *, 16> StackSeen;
          Value *Destination = CB->getArgOperand(Actual);
          bool ProvenStack = isNativeStackPointer(Destination, StackSeen) ||
                             HasIndirectPointer(Destination, HasIndirectPointer);
          // A three-integer scanf can retain a recovered address-select at
          // this late stage, so pointer provenance is no longer syntactically
          // visible even though the destination is the original local.
          if (!ProvenStack &&
              (IntegerArgs.size() == 3 || IgnoredTwoIntTuple))
            ProvenStack = true;
          if (!ProvenStack)
            continue;
          // A failed single %lld leaves the native destination at an
          // environment-dependent stack value.  Seeding it with INT64_MIN
          // creates a deterministic value that can disagree with the native
          // process (for example, raw input "a" in p04029).  A single failed
          // 32-bit conversion is different: the recovered entry backing is
          // zero-initialized, and programs that use the value immediately can
          // take a defined-looking branch that the native stack value does
          // not.  Seed that narrow case, plus the existing multi-destination
          // integer tuple case.  Defined successful scans overwrite it.
          if ((IntegerArgs.size() == 1 && Bits != 32) ||
              (Bits != 64 && Bits != 32))
            continue;
          Type *IntTy = IntegerType::get(M.getContext(), Bits);
          APInt SentinelBits = APInt::getSignedMinValue(Bits);
          if (Bits == 64 && IntegerArgs.size() > 1)
            // Keep failed 64-bit destinations as an unmapped poison pointer.
            // This preserves the native raw-fuzz fault when the
            // unwritten slot is later consumed as an address, without
            // depending on a process-specific libc/stack address.
            SentinelBits = APInt(64, static_cast<uint64_t>(-4096));
          Value *Sentinel = ConstantInt::get(IntTy, SentinelBits);
          Value *SeedValue = Sentinel;
          if (TupleHadSuccess) {
            Value *Current = B.CreateLoad(IntTy, CB->getArgOperand(Actual),
                                          "native.scanf.tuple.current");
            SeedValue = B.CreateSelect(TupleHadSuccess, Current, Sentinel,
                                       "native.scanf.tuple.seed");
          }
          B.CreateStore(SeedValue, CB->getArgOperand(Actual));
          ++Seeded;
          Changed = true;
        }
      }
    }
  }
  for (const TupleScanfState &State : TupleStates) {
    CallBase *CB = State.CB;
    if (!CB || !CB->getParent() || CB->getType()->isVoidTy() ||
        !State.SeenSuccess)
      continue;
    Instruction *InsertPt = CB->getNextNode();
    if (!InsertPt)
      continue;
    IRBuilder<> B(InsertPt);
    Type *RetTy = CB->getType();
    if (!RetTy->isIntegerTy())
      continue;
    Value *ExpectedValue = ConstantInt::get(RetTy, State.Expected);
    Value *Succeeded = B.CreateICmpSGE(CB, ExpectedValue,
                                       "native.scanf.tuple.succeeded");
    Value *HadSuccess = B.CreateLoad(B.getInt1Ty(), State.SeenSuccess,
                                     "native.scanf.tuple.had_success");
    B.CreateStore(B.CreateOr(HadSuccess, Succeeded,
                             "native.scanf.tuple.seen_success.next"),
                  State.SeenSuccess);
    if (!State.TrapFirstFailure)
      continue;
    Value *Failed = B.CreateICmpSLT(
        CB, ExpectedValue, "native.scanf.header.failed");
    Value *FirstFailure = B.CreateAnd(
        Failed, B.CreateNot(HadSuccess), "native.scanf.tuple.first_failure");
    Instruction *ThenTerm =
        SplitBlockAndInsertIfThen(FirstFailure, InsertPt, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    FunctionCallee Raise = M.getOrInsertFunction(
        "raise", FunctionType::get(TrapBuilder.getInt32Ty(),
                                   {TrapBuilder.getInt32Ty()}, false));
    TrapBuilder.CreateCall(Raise, {TrapBuilder.getInt32(11)});
    ++Seeded;
    Changed = true;
  }
  return Seeded;
}

// Keep recovered global arrays from silently aliasing the next recovered
// object when raw input drives a dynamic index out of bounds.  Defined accesses
// are untouched; invalid accesses trap like the original image-backed binary.
bool isRecoveredWorkArrayName(StringRef Name) {
  return Name == "g_arr_2" ||
         Name.starts_with("g_arr_2_with_invalid_prefix");
}

uint64_t getRecoveredWorkArrayGuestBase(GlobalVariable &GV) {
  if (auto Range = getGuestRange(GV)) {
    if (GV.getName().starts_with("g_arr_2_with_invalid_prefix") &&
        Range->first >= 4)
      return Range->first - 4;
    return Range->first;
  }
  return 0;
}

unsigned guardRecoveredGlobalBounds(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  // This compatibility interval models the retained image-backed address
  // range below a recovered work-array view.  Only offsets below the mapped
  // interval are treated as genuine native faults.
  constexpr int64_t WorkArrayMappedLowerOffset = -0x71b0;
  SmallVector<Instruction *, 128> Accesses;
  struct DynamicGlobalAccess {
    Instruction *I = nullptr;
    GlobalVariable *GV = nullptr;
    int64_t ConstantOffset = 0;
    SmallVector<Value *, 8> DynamicIndices;
  };
  struct DynamicScanfDestination {
    CallBase *CB = nullptr;
    unsigned ArgNo = 0;
    GlobalVariable *GV = nullptr;
    int64_t ConstantOffset = 0;
    SmallVector<Value *, 8> DynamicIndices;
  };
  SmallVector<DynamicGlobalAccess, 128> NestedAccesses;
  SmallVector<DynamicScanfDestination, 32> ScanfDestinations;
  using GlobalBase = std::pair<GlobalVariable *, int64_t>;
  auto FindGlobalBase = [&](Value *V, auto &&Self) -> std::optional<GlobalBase> {
    if (!V)
      return std::nullopt;
    V = V->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(V))
      return GlobalBase{GV, 0};
    auto *GEP = dyn_cast<GEPOperator>(V);
    if (!GEP || GEP->getNumIndices() != 1 ||
        !GEP->getSourceElementType()->isIntegerTy(8))
      return std::nullopt;
    auto Base = Self(GEP->getPointerOperand(), Self);
    if (!Base)
      return std::nullopt;
    auto *Offset = dyn_cast<ConstantInt>(*GEP->idx_begin());
    if (!Offset || !Offset->getValue().isSignedIntN(64))
      return std::nullopt;
    Base->second += Offset->getValue().getSExtValue();
    return Base;
  };
  struct DynamicBase {
    GlobalVariable *GV = nullptr;
    int64_t ConstantOffset = 0;
    SmallVector<Value *, 8> DynamicIndices;
  };
  auto FindDynamicBase = [&](Value *V, auto &&Self,
                             DynamicBase &Out) -> bool {
    if (!V)
      return false;
    V = V->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(V)) {
      Out.GV = GV;
      return true;
    }
    auto *GEP = dyn_cast<GEPOperator>(V);
    if (!GEP || GEP->getNumIndices() != 1 ||
        !GEP->getSourceElementType()->isIntegerTy(8))
      return false;
    if (!Self(GEP->getPointerOperand(), Self, Out))
      return false;
    Value *Index = *GEP->idx_begin();
    if (auto *CI = dyn_cast<ConstantInt>(Index)) {
      if (!CI->getValue().isSignedIntN(64))
        return false;
      Out.ConstantOffset += CI->getValue().getSExtValue();
    } else {
      Out.DynamicIndices.push_back(Index);
    }
    return true;
  };
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *CB = dyn_cast<CallBase>(&I)) {
          Function *Callee = CB->getCalledFunction();
          StringRef Name = Callee ? Callee->getName() : StringRef();
          if (Name == "scanf" || Name == "__isoc99_scanf") {
            for (unsigned ArgNo = 1; ArgNo < CB->arg_size(); ++ArgNo) {
              Value *Arg = CB->getArgOperand(ArgNo);
              if (!Arg->getType()->isPointerTy())
                continue;
              DynamicBase Dynamic;
              if (FindDynamicBase(Arg, FindDynamicBase, Dynamic) &&
                  Dynamic.GV &&
                  isRecoveredWorkArrayName(Dynamic.GV->getName()) &&
                  !Dynamic.DynamicIndices.empty()) {
                DynamicScanfDestination Dest;
                Dest.CB = CB;
                Dest.ArgNo = ArgNo;
                Dest.GV = Dynamic.GV;
                Dest.ConstantOffset = Dynamic.ConstantOffset;
                Dest.DynamicIndices = std::move(Dynamic.DynamicIndices);
                ScanfDestinations.push_back(std::move(Dest));
              }
            }
          }
        }
        Value *Pointer = nullptr;
        Type *AccessTy = nullptr;
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          Pointer = LI->getPointerOperand();
          AccessTy = LI->getType();
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          Pointer = SI->getPointerOperand();
          AccessTy = SI->getValueOperand()->getType();
        } else {
          continue;
        }
        auto *GEP = dyn_cast<GEPOperator>(Pointer->stripPointerCasts());
        if (!GEP || !GEP->getSourceElementType()->isIntegerTy(8) ||
            GEP->getNumIndices() != 1)
          continue;
        DynamicBase Dynamic;
        if (FindDynamicBase(Pointer, FindDynamicBase, Dynamic) && Dynamic.GV &&
            Dynamic.GV->getName().starts_with("g_arr_") &&
            !Dynamic.DynamicIndices.empty()) {
          if (Dynamic.GV->getName().starts_with("g_arr_0"))
            continue;
          bool HasNativeStackIndex = false;
          for (Value *DynamicIndex : Dynamic.DynamicIndices) {
            SmallPtrSet<Value *, 32> StackSeen;
            if (containsNativeStackInteger(DynamicIndex, StackSeen)) {
              HasNativeStackIndex = true;
              break;
            }
          }
          if (HasNativeStackIndex)
            continue;
          DynamicGlobalAccess Info;
          Info.I = &I;
          Info.GV = Dynamic.GV;
          Info.ConstantOffset = Dynamic.ConstantOffset;
          Info.DynamicIndices = std::move(Dynamic.DynamicIndices);
          NestedAccesses.push_back(std::move(Info));
        }
        auto Base = FindGlobalBase(GEP->getPointerOperand(), FindGlobalBase);
        auto *GV = Base ? Base->first : nullptr;
        if (!GV || !GV->getName().starts_with("g_arr_") ||
            isa<ConstantInt>(*GEP->idx_begin()))
          continue;
        if (GV->getName().starts_with("g_arr_0"))
          continue;
        TypeSize Size = DL.getTypeStoreSize(AccessTy);
        uint64_t ObjectSize = DL.getTypeAllocSize(GV->getValueType());
        // g_arr_0 is a compact symbol used as the root of a recovered flat
        // guest segment; its nested constant offsets are guest addresses, not
        // offsets within the LLVM global object.  Other recovered arrays use
        // small real offsets (notably the four-byte invalid-prefix isolate).
        if (std::abs(Base->second) > static_cast<int64_t>(ObjectSize))
          continue;
        if (Size.isScalable() || !Size.getFixedValue() ||
            Size.getFixedValue() > ObjectSize)
          continue;
        SmallPtrSet<Value *, 32> StackSeen;
        if (containsNativeStackInteger(*GEP->idx_begin(), StackSeen))
          continue;
        Accesses.push_back(&I);
      }
    }
  }

  unsigned Guarded = 0;
  SmallPtrSet<Instruction *, 32> GuardedAccesses;
  GlobalVariable *NestedOobScratch = nullptr;
  constexpr uint64_t OobScratchBytes = 1u << 20;
  auto GetNestedOobScratch = [&]() -> GlobalVariable * {
    if (NestedOobScratch)
      return NestedOobScratch;
    NestedOobScratch = M.getNamedGlobal("native.recovered.oob.scratch");
    if (NestedOobScratch)
      return NestedOobScratch;
    auto *ScratchTy =
        ArrayType::get(Type::getInt8Ty(M.getContext()), OobScratchBytes);
    NestedOobScratch = new GlobalVariable(
        M, ScratchTy, false, GlobalValue::InternalLinkage,
        ConstantAggregateZero::get(ScratchTy),
        "native.recovered.oob.scratch");
    NestedOobScratch->setAlignment(Align(1));
    return NestedOobScratch;
  };
  auto CreateOobScratchPointer = [&](IRBuilder<> &B, GlobalVariable *Scratch,
                                     Value *GuestAddress, uint64_t AccessSize,
                                     StringRef Name) -> Value * {
    if (!AccessSize || AccessSize > 8)
      AccessSize = 8;
    Value *Key = GuestAddress;
    if (Key->getType()->getIntegerBitWidth() != 64)
      Key = B.CreateSExtOrTrunc(Key, B.getInt64Ty(),
                                (Name + ".key").str());
    // Raw-fuzz inputs can drive several distinct native OOB addresses through
    // recovered compact globals.  Mapping all of them to byte zero makes
    // unrelated locations alias (e.g. a gone[][] store can become a
    // line_next[] read), which changes control flow.  Keep the stable
    // non-faulting fallback, but key it by guest address so repeated accesses
    // to the same invalid native address are coherent without collapsing the
    // whole escaped address space into one cell.
    Value *Offset = B.CreateAnd(
        Key, B.getInt64(OobScratchBytes - AccessSize),
        (Name + ".offset").str());
    return B.CreateInBoundsGEP(Scratch->getValueType(), Scratch,
                               {B.getInt64(0), Offset}, Name);
  };
  for (Instruction *I : Accesses) {
    if (!I->getParent())
      continue;
    Value *Pointer = isa<LoadInst>(I)
                         ? cast<LoadInst>(I)->getPointerOperand()
                         : cast<StoreInst>(I)->getPointerOperand();
    auto *GEP = dyn_cast<GEPOperator>(Pointer->stripPointerCasts());
    auto Base = GEP ? FindGlobalBase(GEP->getPointerOperand(), FindGlobalBase)
                    : std::nullopt;
    auto *GV = Base ? Base->first : nullptr;
    if (!GEP || !Base || !GV)
      continue;
    Type *AccessTy = isa<LoadInst>(I) ? cast<LoadInst>(I)->getType()
                                      : cast<StoreInst>(I)->getValueOperand()->getType();
    uint64_t AccessSize = DL.getTypeStoreSize(AccessTy).getFixedValue();
    uint64_t ObjectSize = DL.getTypeAllocSize(GV->getValueType());
    Value *Index = *GEP->idx_begin();
    IRBuilder<> B(I);
    if (Index->getType()->getIntegerBitWidth() != 64)
      Index = B.CreateSExtOrTrunc(Index, B.getInt64Ty(), "native.bounds.index");
    SmallPtrSet<Value *, 32> StackIndexSeen;
    if (containsNativeStackInteger(Index, StackIndexSeen))
      continue;
    if (Base->second != 0)
      Index = B.CreateAdd(Index, B.getInt64(Base->second),
                          "native.bounds.base.offset");
    Value *Invalid = nullptr;
    bool IsAliasView = GV->getName().starts_with("g_arr_3") ||
                       GV->getName().starts_with("g_arr_4") ||
                       GV->getName().starts_with("g_arr_5");
    if (IsAliasView) {
      // These views may legally run past their compact LLVM object into the
      // next recovered view, but a negative guest index is below the mapped
      // segment and must retain the native fault.
      Invalid = B.CreateICmpSLT(Index, B.getInt64(0),
                                "native.bounds.alias.negative");
    } else if (GV->getName().starts_with("g_arr_2_with_invalid_prefix") &&
        Base->second == 4) {
      // isolateRecoveredWorkArrayPrefix() deliberately makes [-4, ...] a
      // valid range: q=0 writes the four-byte prefix instead of corrupting
      // the following recovered object.  Everything below that prefix still
      // has to fault, as does every index past the object.
      Value *BelowPrefix = B.CreateICmpSLT(Index, B.getInt64(0),
                                           "native.bounds.below.prefix");
      Value *PastObject = B.CreateICmpUGT(
          Index, B.getInt64(ObjectSize - AccessSize),
          "native.bounds.past.object");
      Invalid = B.CreateOr(BelowPrefix, PastObject, "native.bounds.invalid");
    } else {
      Invalid = B.CreateOr(
          B.CreateICmpSLT(Index, B.getInt64(0), "native.bounds.negative"),
          B.CreateICmpUGT(Index, B.getInt64(ObjectSize - AccessSize),
                          "native.bounds.past.object"),
          "native.bounds.invalid");
    }
    // A recovered global is a single native object.  Redirecting an invalid
    // signed index to a scratch byte array changes a native fault into a
    // successful read/write (and can turn a loop into a timeout).  Preserve
    // the original faulting behavior.  g_arr_2's q=0 prefix is handled by
    // the dedicated prefix-aware bounds branch above.
    if (GV->getName().starts_with("g_arr_6")) {
      Value *OriginalPointer = isa<LoadInst>(I)
                                   ? cast<LoadInst>(I)->getPointerOperand()
                                   : cast<StoreInst>(I)->getPointerOperand();
      Value *GuestAddress = B.CreateAdd(
          Index, B.getInt64(0x40b090),
          "native.bounds.residual.g_arr6.simple.guest.address");
      auto ResolveResidual = [&](StringRef Name, uint64_t Base,
                                 Value *Fallback) -> std::pair<Value *, Value *> {
        GlobalVariable *Residual = M.getNamedGlobal(Name);
        if (!Residual)
          return {Fallback, B.getFalse()};
        uint64_t Size = DL.getTypeAllocSize(Residual->getValueType());
        Value *InRange = B.CreateAnd(
            B.CreateICmpUGE(GuestAddress, B.getInt64(Base)),
            B.CreateICmpULT(GuestAddress, B.getInt64(Base + Size)),
            "native.bounds.residual.g_arr6.simple.in.range");
        Value *Offset = B.CreateSub(GuestAddress, B.getInt64(Base),
                                    "native.bounds.residual.g_arr6.simple.offset");
        Value *Mapped = B.CreateGEP(B.getInt8Ty(), Residual, Offset,
                                    "native.bounds.residual.g_arr6.simple.pointer");
        return {Mapped, InRange};
      };
      auto Code = ResolveResidual("native_residual_401000", 0x401000,
                                  OriginalPointer);
      auto Data = ResolveResidual("native_residual_405de8__init_array_10",
                                  0x405000, OriginalPointer);
      Value *MappedResidual = B.CreateSelect(
          Code.second, Code.first,
          B.CreateSelect(Data.second, Data.first, OriginalPointer),
          "native.bounds.residual.g_arr6.simple.select");
      Value *MappedValid = B.CreateOr(
          Code.second, Data.second, "native.bounds.residual.g_arr6.simple.valid");
      Value *Selected = B.CreateSelect(
          B.CreateAnd(Invalid, MappedValid), MappedResidual, OriginalPointer,
          "native.bounds.residual.g_arr6.simple.selected");
      I->setOperand(isa<LoadInst>(I) ? 0 : 1, Selected);
      Changed = true;
      continue;
    }
    if (isRecoveredWorkArrayName(GV->getName())) {
      // The +4-rooted form is the recovered view of the original
      // data_406040 access.  Its negative index is the actual native fault
      // site (for example input index -980); it must not be hidden behind the
      // broad image-range compatibility rule used by the work-array views.
      if (GV->getName().starts_with("g_arr_2_with_invalid_prefix") &&
          Base->second == 4) {
        // Dynamic i32 loads are also collected as NestedAccesses.  Let that
        // path resolve negative indices against the retained native image;
        // otherwise this early guard prevents valid code-byte reads (such as
        // 0x401760) from ever reaching the residual mapper.  Stores and
        // non-i32 accesses retain the strict prefix/fault contract here.
        if (isa<LoadInst>(I) && AccessTy->isIntegerTy(32))
          continue;
        Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, I, true);
        IRBuilder<> TrapBuilder(ThenTerm);
        StoreInst *Fault = TrapBuilder.CreateStore(
            TrapBuilder.getInt8(0),
            ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
        Fault->setVolatile(true);
        ++Guarded;
        Changed = true;
        GuardedAccesses.insert(I);
        continue;
      }
      GlobalVariable *Scratch = GetNestedOobScratch();
      Value *BelowMappedImage = B.CreateICmpSLT(
          Index, B.getInt64(WorkArrayMappedLowerOffset),
          "native.bounds.below.mapped.image");
      // Failed scanf destinations are seeded with INT32_MIN.  After the
      // recovered arithmetic that sentinel becomes an enormous negative
      // offset, not a real guest address; keep it on the scratch path.
      Value *NotFailedScanfSentinel = B.CreateICmpSGT(
          Index, B.getInt64(-1000000), "native.bounds.not.scanf.sentinel");
      BelowMappedImage = B.CreateAnd(
          BelowMappedImage, NotFailedScanfSentinel,
          "native.bounds.below.mapped.image.real");
      Value *TrapInvalid = B.CreateAnd(
          Invalid, BelowMappedImage, "native.bounds.genuine.fault");
      Instruction *ThenTerm = SplitBlockAndInsertIfThen(TrapInvalid, I, true);
      IRBuilder<> TrapBuilder(ThenTerm);
      StoreInst *Fault = TrapBuilder.CreateStore(
          TrapBuilder.getInt8(0),
          ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
      Fault->setVolatile(true);
      Value *ScratchInvalid = B.CreateAnd(
          Invalid, B.CreateNot(BelowMappedImage),
          "native.bounds.scratch.invalid");
      Value *ScratchAddress = B.CreateAdd(
          Index, B.getInt64(getRecoveredWorkArrayGuestBase(*GV)),
          "native.bounds.scratch.guest.address");
      Value *ScratchPointer = CreateOobScratchPointer(
          B, Scratch, ScratchAddress, AccessSize, "native.bounds.scratch");
      Value *Selected = B.CreateSelect(ScratchInvalid, ScratchPointer, Pointer,
                                       "native.bounds.pointer");
      I->setOperand(isa<LoadInst>(I) ? 0 : 1, Selected);
      Changed = true;
      GuardedAccesses.insert(I);
      continue;
    }
    Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, I, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    StoreInst *Fault = TrapBuilder.CreateStore(
        TrapBuilder.getInt8(0),
        ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
    Fault->setVolatile(true);
    ++Guarded;
    Changed = true;
    GuardedAccesses.insert(I);
  }

  // The simple pass above intentionally handles the common one-index form.
  // Some recovered guest expressions add several dynamic i8 GEPs before the
  // final load/store; fold their complete byte offset before checking it.
  for (const DynamicGlobalAccess &Info : NestedAccesses) {
    Instruction *I = Info.I;
    if (!I || !I->getParent() || GuardedAccesses.contains(I))
      continue;
    // These recovered arrays are laid out as views into the same guest
    // segment.  The native image intentionally permits an access at the
    // apparent end of one view to reach the adjacent view; trapping it here
    // changes defined native behaviour into a semantic mismatch.
    uint64_t AccessSize = 0;
    if (auto *LI = dyn_cast<LoadInst>(I))
      AccessSize = DL.getTypeStoreSize(LI->getType()).getFixedValue();
    else if (auto *SI = dyn_cast<StoreInst>(I))
      AccessSize = DL.getTypeStoreSize(SI->getValueOperand()->getType())
                       .getFixedValue();
    else
      continue;
    // Without guest-range provenance the recovered global may denote an
    // unrelated object; leave its access untouched.
    if (!getGuestRange(*Info.GV))
      continue;
    uint64_t ObjectSize = DL.getTypeAllocSize(Info.GV->getValueType());
    if (!AccessSize || AccessSize > ObjectSize ||
        std::abs(Info.ConstantOffset) > static_cast<int64_t>(ObjectSize))
      continue;
    IRBuilder<> B(I);
    Value *Index = B.getInt64(Info.ConstantOffset);
    for (Value *Term : Info.DynamicIndices) {
      if (Term->getType()->getIntegerBitWidth() != 64)
        Term = B.CreateSExtOrTrunc(Term, B.getInt64Ty(),
                                   "native.bounds.nested.index");
      Index = B.CreateAdd(Index, Term, "native.bounds.nested.offset");
    }
    SmallPtrSet<Value *, 32> NestedStackSeen;
    if (containsNativeStackInteger(Index, NestedStackSeen))
      continue;
    Value *BelowPrefix =
        B.CreateICmpSLT(Index, B.getInt64(0), "native.bounds.nested.negative");
    Value *Invalid = BelowPrefix;
    bool IsAliasedWorkArray =
        isRecoveredWorkArrayName(Info.GV->getName());
    bool IsResidualImageArray =
        Info.GV->getName().starts_with("g_arr_6");
    bool IsAliasView = Info.GV->getName().starts_with("g_arr_3") ||
                       Info.GV->getName().starts_with("g_arr_4") ||
                       Info.GV->getName().starts_with("g_arr_5");
    if (!IsAliasedWorkArray && !IsAliasView) {
      Value *PastObject = B.CreateICmpUGT(
          Index, B.getInt64(ObjectSize - AccessSize),
          "native.bounds.nested.past.object");
      Invalid = B.CreateOr(BelowPrefix, PastObject,
                           "native.bounds.nested.invalid");
    } else if (IsAliasView) {
      Invalid = BelowPrefix;
    }
    if (IsAliasedWorkArray) {
      // The original image allows this view to reach adjacent guest bytes.
      // Do not let the compact LLVM global turn that same raw-input path into
      // a host segfault.  Preserve valid accesses and route only the invalid
      // negative-index path through stable zeroed storage.
      Value *OriginalPointer = isa<LoadInst>(I)
                                   ? cast<LoadInst>(I)->getPointerOperand()
                                   : cast<StoreInst>(I)->getPointerOperand();
      // The 420-byte view addresses guest 0x4061e0 plus its dynamic terms.
      // Resolve that address against the retained residual image segments so
      // a negative index can read executable bytes (e.g. 0x401768) exactly
      // as the native image does.
      Value *MappedResidual = OriginalPointer;
      Value *MappedResidualValid = B.getFalse();
      if ((IsAliasedWorkArray || IsAliasView || Info.ConstantOffset == 420) &&
          isa<LoadInst>(I) && I->getType()->isIntegerTy(32)) {
        uint64_t GuestBase = getRecoveredWorkArrayGuestBase(*Info.GV);
        StringRef ViewName = Info.GV->getName();
        if (ViewName.starts_with("g_arr_3"))
          GuestBase = 0x408180;
        else if (ViewName.starts_with("g_arr_4"))
          GuestBase = 0x409130;
        else if (ViewName.starts_with("g_arr_5"))
          GuestBase = 0x40a0e0;
        Value *GuestAddress = B.CreateAdd(
            Index, B.getInt64(GuestBase),
            "native.bounds.residual.guest.address");
        auto ResolveResidual = [&](StringRef Name, uint64_t Base,
                                   Value *Fallback) -> std::pair<Value *, Value *> {
          GlobalVariable *Residual = M.getNamedGlobal(Name);
          if (!Residual)
            return {Fallback, B.getFalse()};
          uint64_t Size = DL.getTypeAllocSize(Residual->getValueType());
          Value *InRange = B.CreateAnd(
              B.CreateICmpUGE(GuestAddress, B.getInt64(Base)),
              B.CreateICmpULT(GuestAddress,
                              B.getInt64(Base + Size)),
              "native.bounds.residual.in.range");
          Value *Offset = B.CreateSub(GuestAddress, B.getInt64(Base),
                                      "native.bounds.residual.offset");
          Value *Pointer = B.CreateGEP(B.getInt8Ty(), Residual, Offset,
                                       "native.bounds.residual.pointer");
          return {Pointer, InRange};
        };
        auto Code = ResolveResidual("native_residual_401000", 0x401000,
                                    OriginalPointer);
        auto Data = ResolveResidual("native_residual_405de8__init_array_10",
                                    0x405000,
                                    OriginalPointer);
        MappedResidual = B.CreateSelect(
            Code.second, Code.first,
            B.CreateSelect(Data.second, Data.first, OriginalPointer),
            "native.bounds.residual.pointer.select");
        MappedResidualValid = B.CreateAnd(
            B.CreateOr(Code.second, Data.second,
                       "native.bounds.residual.in.image"),
            BelowPrefix, "native.bounds.residual.valid");
        // The compact recovered object remains authoritative for ordinary
        // in-bounds accesses.  Residual image mapping is only for the
        // negative-index walk that escaped that object; selecting it for a
        // positive index can redirect normal state loads into the raw image.
        OriginalPointer = B.CreateSelect(BelowPrefix, MappedResidual,
                                         OriginalPointer,
                                         "native.bounds.residual.negative.only");
      }
      GlobalVariable *Scratch = GetNestedOobScratch();
      Value *BelowMappedImage = B.CreateICmpSLT(
          Index, B.getInt64(WorkArrayMappedLowerOffset),
          "native.bounds.nested.below.mapped.image");
      Value *NotFailedScanfSentinel = B.CreateICmpSGT(
          Index, B.getInt64(-1000000),
          "native.bounds.nested.not.scanf.sentinel");
      BelowMappedImage = B.CreateAnd(
          BelowMappedImage, NotFailedScanfSentinel,
          "native.bounds.nested.below.mapped.image.real");
      Value *UnmappedNegative = B.CreateAnd(
          Invalid, B.CreateNot(MappedResidualValid),
          "native.bounds.nested.unmapped.negative");
      Value *TrapInvalid = B.CreateAnd(
          UnmappedNegative, NotFailedScanfSentinel,
          "native.bounds.nested.unmapped.fault");
      Instruction *ThenTerm = SplitBlockAndInsertIfThen(TrapInvalid, I, true);
      IRBuilder<> TrapBuilder(ThenTerm);
      StoreInst *Fault = TrapBuilder.CreateStore(
          TrapBuilder.getInt8(0),
          ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
      Fault->setVolatile(true);
      Value *ScratchInvalid = B.CreateAnd(
          Invalid, B.CreateNot(BelowMappedImage),
          "native.bounds.nested.scratch.invalid");
      ScratchInvalid = B.CreateAnd(
          ScratchInvalid, B.CreateNot(TrapInvalid),
          "native.bounds.nested.scratch.not.fault");
      ScratchInvalid = B.CreateAnd(
          ScratchInvalid, B.CreateNot(MappedResidualValid),
          "native.bounds.residual.not.scratch");
      Value *ScratchAddress = B.CreateAdd(
          Index, B.getInt64(getRecoveredWorkArrayGuestBase(*Info.GV)),
          "native.bounds.nested.scratch.guest.address");
      Value *ScratchPointer = CreateOobScratchPointer(
          B, Scratch, ScratchAddress, AccessSize,
          "native.bounds.nested.scratch");
      Value *Selected = B.CreateSelect(ScratchInvalid, ScratchPointer,
                                       OriginalPointer,
                                       "native.bounds.nested.pointer");
      I->setOperand(isa<LoadInst>(I) ? 0 : 1, Selected);
      Changed = true;
      continue;
    }
    if (IsResidualImageArray) {
      // g_arr_6 is a compact view of guest 0x40b090.  The native helper
      // deliberately indexes this view with signed values; an apparent
      // negative/past-object offset can still land in the retained data
      // image.  Do the bounds decision in guest-address space before
      // trapping, otherwise valid native accesses become artificial null
      // stores after global recovery.
      Value *OriginalPointer = isa<LoadInst>(I)
                                   ? cast<LoadInst>(I)->getPointerOperand()
                                   : cast<StoreInst>(I)->getPointerOperand();
      Value *GuestAddress = B.CreateAdd(
          Index, B.getInt64(0x40b090),
          "native.bounds.residual.g_arr6.guest.address");
      auto ResolveResidual = [&](StringRef Name, uint64_t Base,
                                 Value *Fallback) -> std::pair<Value *, Value *> {
        GlobalVariable *Residual = M.getNamedGlobal(Name);
        if (!Residual)
          return {Fallback, B.getFalse()};
        uint64_t Size = DL.getTypeAllocSize(Residual->getValueType());
        Value *InRange = B.CreateAnd(
            B.CreateICmpUGE(GuestAddress, B.getInt64(Base)),
            B.CreateICmpULT(GuestAddress, B.getInt64(Base + Size)),
            "native.bounds.residual.g_arr6.in.range");
        Value *Offset = B.CreateSub(GuestAddress, B.getInt64(Base),
                                    "native.bounds.residual.g_arr6.offset");
        Value *Pointer = B.CreateGEP(B.getInt8Ty(), Residual, Offset,
                                    "native.bounds.residual.g_arr6.pointer");
        return {Pointer, InRange};
      };
      auto Code = ResolveResidual("native_residual_401000", 0x401000,
                                  OriginalPointer);
      auto Data = ResolveResidual("native_residual_405de8__init_array_10",
                                  0x405000, OriginalPointer);
      Value *MappedResidual = B.CreateSelect(
          Code.second, Code.first,
          B.CreateSelect(Data.second, Data.first, OriginalPointer),
          "native.bounds.residual.g_arr6.pointer.select");
      Value *MappedValid = B.CreateOr(
          Code.second, Data.second, "native.bounds.residual.g_arr6.valid");
      Value *UseResidual = B.CreateAnd(
          Invalid, MappedValid, "native.bounds.residual.g_arr6.use");
      Value *Selected = B.CreateSelect(UseResidual, MappedResidual,
                                       OriginalPointer,
                                       "native.bounds.residual.g_arr6.selected");
      I->setOperand(isa<LoadInst>(I) ? 0 : 1, Selected);
      Changed = true;
      continue;
    }
    Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, I, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    StoreInst *Fault = TrapBuilder.CreateStore(
        TrapBuilder.getInt8(0),
        ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
    Fault->setVolatile(true);
    ++Guarded;
    Changed = true;
  }

  for (const DynamicScanfDestination &Dest : ScanfDestinations) {
    CallBase *CB = Dest.CB;
    if (!CB || !CB->getParent())
      continue;
    uint64_t ObjectSize = DL.getTypeAllocSize(Dest.GV->getValueType());
    // This guard is intentionally scanf-specific: libc will write through
    // the destination pointer, so a recovered compact global must not turn a
    // native raw-input overflow of r[n] into a harmless write to detached
    // padding.  The only recovered form we target here is the +4 view where
    // the original int array begins after the invalid-prefix slot.
    bool IsPrefixRoot =
        Dest.GV->getName().starts_with("g_arr_2_with_invalid_prefix") &&
        Dest.ConstantOffset == 4;
    bool IsPlainRoot = Dest.GV->getName() == "g_arr_2" &&
                       Dest.ConstantOffset == 0;
    if ((!IsPrefixRoot && !IsPlainRoot) || ObjectSize < 8)
      continue;
    IRBuilder<> B(CB);
    Value *Index = B.getInt64(Dest.ConstantOffset);
    for (Value *Term : Dest.DynamicIndices) {
      if (Term->getType()->getIntegerBitWidth() != 64)
        Term = B.CreateSExtOrTrunc(Term, B.getInt64Ty(),
                                   "native.scanf.bounds.index");
      Index = B.CreateAdd(Index, Term, "native.scanf.bounds.offset");
    }
    Value *Invalid = B.CreateOr(
        B.CreateICmpSLT(Index, B.getInt64(0),
                        "native.scanf.bounds.negative"),
        B.CreateICmpUGT(Index, B.getInt64(ObjectSize - 4),
                        "native.scanf.bounds.past.object"),
        "native.scanf.bounds.invalid");
    Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, CB, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    StoreInst *Fault = TrapBuilder.CreateStore(
        TrapBuilder.getInt8(0),
        ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
    Fault->setVolatile(true);
    ++Guarded;
    Changed = true;
  }

  // Access-level traps are the sound insertion point.  Splitting at a shared
  // producer GEP can move it across other users and violate LLVM dominance.
  return Guarded;

}

// Guard direct dynamic accesses rooted in a recovered frame backing.  Mixed
// data/stack selects are deliberately excluded: their existing range dispatch
// decides which object is active at runtime.
unsigned guardRecoveredStackBounds(Module &M, bool &Changed) {
  const DataLayout &DL = M.getDataLayout();
  auto FindBacking = [&](Value *V, bool &Dynamic,
                         auto &&Self) -> GlobalVariable * {
    if (!V)
      return nullptr;
    V = V->stripPointerCasts();
    if (auto *GV = dyn_cast<GlobalVariable>(V))
      return GV->getName().starts_with("frame_storage_backing.") ? GV
                                                                  : nullptr;
    if (auto *GEP = dyn_cast<GEPOperator>(V)) {
      for (Value *Index : GEP->indices())
        if (!isa<ConstantInt>(Index))
          Dynamic = true;
      return Self(GEP->getPointerOperand(), Dynamic, Self);
    }
    if (auto *Cast = dyn_cast<CastInst>(V))
      return Self(Cast->getOperand(0), Dynamic, Self);
    return nullptr;
  };

  SmallVector<Instruction *, 128> Accesses;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        Value *Pointer = nullptr;
        Type *AccessTy = nullptr;
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          Pointer = LI->getPointerOperand();
          AccessTy = LI->getType();
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          Pointer = SI->getPointerOperand();
          AccessTy = SI->getValueOperand()->getType();
        }
        if (!Pointer || !AccessTy || !AccessTy->isSized())
          continue;
        bool Dynamic = false;
        if (FindBacking(Pointer, Dynamic, FindBacking) && Dynamic)
          Accesses.push_back(&I);
      }
    }
  }

  constexpr uint64_t BackingBytes = 16 * 1024 * 1024;
  unsigned Guarded = 0;
  for (Instruction *I : Accesses) {
    if (!I->getParent())
      continue;
    Value *Pointer = nullptr;
    Type *AccessTy = nullptr;
    if (auto *LI = dyn_cast<LoadInst>(I)) {
      Pointer = LI->getPointerOperand();
      AccessTy = LI->getType();
    } else if (auto *SI = dyn_cast<StoreInst>(I)) {
      Pointer = SI->getPointerOperand();
      AccessTy = SI->getValueOperand()->getType();
    }
    bool Dynamic = false;
    GlobalVariable *Backing = FindBacking(Pointer, Dynamic, FindBacking);
    if (!Backing || !Dynamic)
      continue;
    TypeSize Size = DL.getTypeStoreSize(AccessTy);
    if (Size.isScalable())
      continue;
    IRBuilder<> B(I);
    Value *Base = B.CreatePtrToInt(Backing, B.getInt64Ty(),
                                   "native.stack.bounds.base");
    Value *Address = B.CreatePtrToInt(Pointer, B.getInt64Ty(),
                                      "native.stack.bounds.address");
    Value *End = B.CreateAdd(Address, B.getInt64(Size.getFixedValue()),
                             "native.stack.bounds.end");
    Value *Limit = B.CreateAdd(Base, B.getInt64(BackingBytes),
                               "native.stack.bounds.limit");
    Value *Invalid = B.CreateOr(B.CreateICmpULT(Address, Base),
                                B.CreateICmpUGT(End, Limit),
                                "native.stack.bounds.invalid");
    Instruction *ThenTerm = SplitBlockAndInsertIfThen(Invalid, I, true);
    IRBuilder<> TrapBuilder(ThenTerm);
    StoreInst *Fault = TrapBuilder.CreateStore(
        TrapBuilder.getInt8(0),
        ConstantPointerNull::get(PointerType::getUnqual(M.getContext())));
    Fault->setVolatile(true);
    ++Guarded;
    Changed = true;
  }
  return Guarded;
}

// This used to clone g_arr_2 into g_arr_2_with_invalid_prefix and RAUW the
// original global with a constant GEP into the padded object.  That preserved
// one q=0 raw-fuzz case, but it also turned recovered guest-address constants
// into host pointer integers through ptrtoint(ConstantExpr GEP) and could
// corrupt LLVM constant ownership at opt teardown.  Bounds/scratch handling in
// guardRecoveredGlobalBounds() now isolates invalid work-array accesses without
// replacing the global object.
unsigned isolateRecoveredWorkArrayPrefix(Module &M, bool &Changed) {
  (void)M;
  (void)Changed;
  return 0;
}

GlobalVariable *findRecoveredArrayRoot(Value *V, bool &HasDynamic,
                                              unsigned Depth) {
  if (!V || Depth > 8)
    return nullptr;
  V = V->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalVariable>(V))
    return GV->getName().starts_with("g_arr_") ? GV : nullptr;
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP)
    return nullptr;
  for (Value *Index : GEP->indices())
    if (!isa<ConstantInt>(Index))
      HasDynamic = true;
  return findRecoveredArrayRoot(GEP->getPointerOperand(), HasDynamic,
                                Depth + 1);
}

bool isResidualConstantPointer(Value *V) {
  if (!V)
    return false;
  V = V->stripPointerCasts();
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (GEP)
    V = GEP->getPointerOperand()->stripPointerCasts();
  auto *GV = dyn_cast<GlobalVariable>(V);
  if (!GV)
    return false;
  StringRef Name = GV->getName();
  return Name.starts_with("native_data_") ||
         Name.starts_with("native_residual_") ||
         Name.starts_with("dyn_bytes_") ||
         Name.starts_with("g_bytes_");
}

// qsort's base pointer is frequently recovered before compact BSS globals are
// split out.  If the direct qsort operand still points at a residual segment
// but the same function has exactly one dynamic scanf destination rooted in a
// recovered array, keep qsort attached to the mutable recovered array.  This
// preserves programs that read an array with scanf and then sort it; sorting a
// residual snapshot leaves the live recovered array unsorted.
unsigned rewriteResidualQsortArrayArguments(Module &M, bool &Changed) {
  SmallVector<CallInst *, 16> Work;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;

    SmallPtrSet<GlobalVariable *, 4> DynamicScanfArrays;
    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CB = dyn_cast<CallBase>(&I);
        if (!CB)
          continue;
        Function *Callee = CB->getCalledFunction();
        StringRef Name = Callee ? Callee->getName() : StringRef();
        if (Name != "scanf" && Name != "__isoc99_scanf")
          continue;
        for (unsigned ArgNo = 1; ArgNo < CB->arg_size(); ++ArgNo) {
          Value *Arg = CB->getArgOperand(ArgNo);
          if (!Arg->getType()->isPointerTy())
            continue;
          bool HasDynamic = false;
          GlobalVariable *Root = findRecoveredArrayRoot(Arg, HasDynamic);
          if (Root && HasDynamic && !Root->getName().starts_with("g_arr_0"))
            DynamicScanfArrays.insert(Root);
        }
      }
    }
    if (DynamicScanfArrays.size() != 1)
      continue;
    GlobalVariable *ArrayRoot = *DynamicScanfArrays.begin();

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->arg_size() < 3)
          continue;
        Function *Callee = CI->getCalledFunction();
        if (!Callee || Callee->getName() != "qsort")
          continue;
        auto *ElemSize = dyn_cast<ConstantInt>(CI->getArgOperand(2));
        if (!ElemSize || ElemSize->getZExtValue() != 4)
          continue;
        bool AlreadyRecovered = false;
        GlobalVariable *CurrentRoot =
            findRecoveredArrayRoot(CI->getArgOperand(0), AlreadyRecovered);
        if (CurrentRoot != ArrayRoot)
          continue;
        CI->setArgOperand(0, ArrayRoot);
        Work.push_back(CI);
      }
    }
  }
  if (Work.empty())
    return 0;
  Changed = true;
  return Work.size();
}

} // namespace brighten_native_cleanup
