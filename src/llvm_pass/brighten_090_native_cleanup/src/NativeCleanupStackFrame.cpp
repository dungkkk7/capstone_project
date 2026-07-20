#include "NativeCleanupInternal.h"

using namespace llvm;

namespace brighten_native_cleanup {

bool addSignedOffset(int64_t Base, int64_t Delta, int64_t &Result) {
  if ((Delta > 0 && Base > std::numeric_limits<int64_t>::max() - Delta) ||
      (Delta < 0 && Base < std::numeric_limits<int64_t>::min() - Delta))
    return false;
  Result = Base + Delta;
  return true;
}

std::optional<FrameAffineInteger>
evaluateFrameInteger(Value *V, GlobalVariable &Backing, const DataLayout &DL,
                     unsigned Bits, SmallPtrSetImpl<Value *> &IntegerSeen) {
  if (!V || !V->getType()->isIntegerTy() ||
      V->getType()->getIntegerBitWidth() != Bits)
    return std::nullopt;
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return FrameAffineInteger{CI->getValue(), 0};

  auto FinishBinary = [&](unsigned Opcode, Value *LHS, Value *RHS)
      -> std::optional<FrameAffineInteger> {
    auto L = evaluateFrameInteger(LHS, Backing, DL, Bits, IntegerSeen);
    auto R = evaluateFrameInteger(RHS, Backing, DL, Bits, IntegerSeen);
    if (!L || !R)
      return std::nullopt;
    if (Opcode == Instruction::Add)
      return FrameAffineInteger{L->Constant + R->Constant,
                                L->RootCoefficient + R->RootCoefficient};
    if (Opcode == Instruction::Sub)
      return FrameAffineInteger{L->Constant - R->Constant,
                                L->RootCoefficient - R->RootCoefficient};
    return std::nullopt;
  };

  if (auto *Op = dyn_cast<Operator>(V)) {
    if (Op->getOpcode() == Instruction::Add ||
        Op->getOpcode() == Instruction::Sub)
      return FinishBinary(Op->getOpcode(), Op->getOperand(0),
                          Op->getOperand(1));
    if (Op->getOpcode() == Instruction::PtrToInt) {
      SmallPtrSet<Value *, 32> PointerSeen;
      auto Offset = evaluateFramePointerOffset(Op->getOperand(0), Backing, DL,
                                               PointerSeen);
      if (!Offset)
        return std::nullopt;
      return FrameAffineInteger{APInt(Bits, uint64_t(*Offset), true), 1};
    }
  }
  return std::nullopt;
}

std::optional<int64_t>
evaluateFramePointerOffset(Value *V, GlobalVariable &Backing,
                           const DataLayout &DL,
                           SmallPtrSetImpl<Value *> &PointerSeen) {
  if (!V || !V->getType()->isPointerTy() ||
      !PointerSeen.insert(V).second)
    return std::nullopt;
  if (V->stripPointerCasts() == &Backing)
    return int64_t(0);
  auto *GEP = dyn_cast<GEPOperator>(V);
  if (!GEP)
    return std::nullopt;
  auto Base = evaluateFramePointerOffset(GEP->getPointerOperand(), Backing,
                                         DL, PointerSeen);
  if (!Base)
    return std::nullopt;

  unsigned Bits = DL.getIndexSizeInBits(GEP->getPointerAddressSpace());
  APInt ConstantDelta(Bits, 0, true);
  if (GEP->accumulateConstantOffset(DL, ConstantDelta)) {
    if (!ConstantDelta.isSignedIntN(64))
      return std::nullopt;
    int64_t Result = 0;
    if (!addSignedOffset(*Base, ConstantDelta.getSExtValue(), Result))
      return std::nullopt;
    return Result;
  }

  // The recovered frame arithmetic uses a byte GEP with one affine index.
  // Refuse typed/dimensional dynamic GEPs rather than guessing element scale.
  if (!GEP->getSourceElementType()->isIntegerTy(8) ||
      GEP->getNumIndices() != 1)
    return std::nullopt;
  SmallPtrSet<Value *, 32> IntegerSeen;
  auto Index = evaluateFrameInteger(GEP->idx_begin()->get(), Backing, DL,
                                    Bits, IntegerSeen);
  if (!Index || Index->RootCoefficient != 0 ||
      !Index->Constant.isSignedIntN(64))
    return std::nullopt;
  int64_t Result = 0;
  if (!addSignedOffset(*Base, Index->Constant.getSExtValue(), Result))
    return std::nullopt;
  return Result;
}

unsigned canonicalizeFrameBackingAffinePointers(Module &M,
                                                        bool &Changed) {
  unsigned Rewritten = 0;
  const DataLayout &DL = M.getDataLayout();
  for (GlobalVariable &Backing : M.globals()) {
    if (!Backing.getName().starts_with("frame_storage_backing."))
      continue;
    SmallVector<std::pair<Instruction *, unsigned>, 64> Operands;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo)
            if (I.getOperand(OpNo)->getType()->isPointerTy()) {
              SmallPtrSet<Value *, 32> Seen;
              if (evaluateFramePointerOffset(I.getOperand(OpNo), Backing, DL,
                                             Seen))
                Operands.push_back({&I, OpNo});
            }
    }
    for (auto [I, OpNo] : Operands) {
      SmallPtrSet<Value *, 32> Seen;
      auto Offset = evaluateFramePointerOffset(I->getOperand(OpNo), Backing,
                                               DL, Seen);
      if (!Offset)
        continue;
      IRBuilder<> B(I);
      Value *Direct = B.CreateGEP(B.getInt8Ty(), &Backing,
                                  B.getInt64(*Offset), "native.frame.direct");
      I->setOperand(OpNo, Direct);
      ++Rewritten;
      Changed = true;
    }
    Backing.removeDeadConstantUsers();
  }
  return Rewritten;
}

// Data-pointer recovery is intentionally skipped for stack-provenant integer
// addresses.  Some earlier cleanup orders expose that provenance only after
// the synthetic guest-range select chain has already been built: its raw
// fallback is then canonicalized to frame_storage_backing, while the now
// impossible guest-data arms remain around the store.  Collapse only chains
// created by materializeRecoveredDataPointer, and only when their terminal
// fallback has an exact frame offset.  This restores the classifier's
// original stack-first decision without making any alias assumption about an
// arbitrary user select.
unsigned collapseFrameProvenantDataPointerSelects(Module &M,
                                                          bool &Changed) {
  SmallVector<SelectInst *, 32> Candidates;
  for (Function &F : M)
    if (!F.isDeclaration())
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          if (auto *SI = dyn_cast<SelectInst>(&I);
              SI && SI->getType()->isPointerTy() && SI->hasName() &&
              SI->getName().starts_with("native.data.pointer.select"))
            Candidates.push_back(SI);

  const DataLayout &DL = M.getDataLayout();
  unsigned Collapsed = 0;
  for (SelectInst *Outer : Candidates) {
    if (!Outer->getParent() || Outer->use_empty()) continue;
    Value *Fallback = Outer;
    unsigned Depth = 0;
    while (auto *SI = dyn_cast<SelectInst>(Fallback)) {
      if (!SI->hasName() ||
          !SI->getName().starts_with("native.data.pointer.select") ||
          ++Depth > 64) {
        Fallback = nullptr;
        break;
      }
      Fallback = SI->getFalseValue();
    }
    if (!Fallback) continue;

    bool ExactFrameFallback = false;
    for (GlobalVariable &Backing : M.globals()) {
      if (!Backing.getName().starts_with("frame_storage_backing.")) continue;
      SmallPtrSet<Value *, 32> Seen;
      if (evaluateFramePointerOffset(Fallback, Backing, DL, Seen)) {
        ExactFrameFallback = true;
        break;
      }
    }
    if (!ExactFrameFallback) {
      auto PointsAtLocalFrame = [&](Value *P, auto &&Self) -> bool {
        if (!P)
          return false;
        P = P->stripPointerCasts();
        // NativeStateSSA carries the same private frame through an explicit
        // pointer argument after cloning a lifted function.  At that point
        // the fallback is a GEP rooted at `frame_base`, not at the wrapper's
        // original alloca/global.  Retaining guest-data select arms around
        // this proven frame pointer destroys stack-cell alias precision and
        // hides memory-form CFF recurrences from the deobfuscator.
        if (auto *Arg = dyn_cast<Argument>(P))
          return Arg->getParent() == Outer->getFunction() &&
                 Arg->getType()->isPointerTy() &&
                 (Arg->getName() == "frame_base" ||
                  Arg->getName() == "native_stack");
        if (auto *AI = dyn_cast<AllocaInst>(P)) {
          auto *AT = dyn_cast<ArrayType>(AI->getAllocatedType());
          StringRef Name = AI->getName();
          return AI->getFunction() == Outer->getFunction() && AT &&
                 AT->getElementType()->isIntegerTy(8) &&
                 (Name.starts_with("frame_storage") ||
                  Name.starts_with("native_stack_storage"));
        }
        if (auto *GEP = dyn_cast<GEPOperator>(P))
          return Self(GEP->getPointerOperand(), Self);
        return false;
      };
      ExactFrameFallback = PointsAtLocalFrame(Fallback, PointsAtLocalFrame);
    }
    if (!ExactFrameFallback) continue;

    Outer->replaceAllUsesWith(Fallback);
    RecursivelyDeleteTriviallyDeadInstructions(Outer);
    ++Collapsed;
    Changed = true;
  }
  return Collapsed;
}

std::optional<uint64_t>
getScanfDestinationSize(CallBase &CB, unsigned ArgNo,
                        const DataLayout &DL) {
  Function *Callee = CB.getCalledFunction();
  if (!Callee || (Callee->getName() != "scanf" &&
                  Callee->getName() != "__isoc99_scanf") ||
      ArgNo == 0 || ArgNo >= CB.arg_size())
    return std::nullopt;
  auto Format = readConstantFormatString(CB.getArgOperand(0), DL);
  if (!Format)
    return std::nullopt;

  unsigned Destination = 1;
  for (size_t I = 0; I < Format->size();) {
    if ((*Format)[I++] != '%')
      continue;
    if (I >= Format->size())
      return std::nullopt;
    if ((*Format)[I] == '%') {
      ++I;
      continue;
    }
    bool Suppressed = false;
    if ((*Format)[I] == '*') {
      Suppressed = true;
      ++I;
    }
    uint64_t Width = 0;
    while (I < Format->size() && (*Format)[I] >= '0' &&
           (*Format)[I] <= '9') {
      unsigned Digit = unsigned((*Format)[I++] - '0');
      if (Width > (std::numeric_limits<uint64_t>::max() - Digit) / 10)
        return std::nullopt;
      Width = Width * 10 + Digit;
    }
    enum class Length { None, HH, H, L, LL, J, Z, T, BigL } Len = Length::None;
    if (I < Format->size()) {
      if ((*Format)[I] == 'h') {
        Len = Length::H;
        if (++I < Format->size() && (*Format)[I] == 'h') {
          Len = Length::HH;
          ++I;
        }
      } else if ((*Format)[I] == 'l') {
        Len = Length::L;
        if (++I < Format->size() && (*Format)[I] == 'l') {
          Len = Length::LL;
          ++I;
        }
      } else if ((*Format)[I] == 'j') {
        Len = Length::J;
        ++I;
      } else if ((*Format)[I] == 'z') {
        Len = Length::Z;
        ++I;
      } else if ((*Format)[I] == 't') {
        Len = Length::T;
        ++I;
      } else if ((*Format)[I] == 'L') {
        Len = Length::BigL;
        ++I;
      }
    }
    if (I >= Format->size())
      return std::nullopt;
    char Conversion = (*Format)[I++];
    if (Conversion == '[') {
      if (I < Format->size() && (*Format)[I] == '^')
        ++I;
      if (I < Format->size() && (*Format)[I] == ']')
        ++I;
      while (I < Format->size() && (*Format)[I] != ']')
        ++I;
      if (I >= Format->size())
        return std::nullopt;
      ++I;
    }
    if (Suppressed)
      continue;

    std::optional<uint64_t> Size;
    if (StringRef("diouxXn").contains(Conversion)) {
      switch (Len) {
      case Length::HH: Size = 1; break;
      case Length::H: Size = 2; break;
      case Length::L:
      case Length::LL:
      case Length::J:
      case Length::Z:
      case Length::T: Size = 8; break;
      case Length::None: Size = 4; break;
      case Length::BigL: return std::nullopt;
      }
    } else if (StringRef("aAeEfFgG").contains(Conversion)) {
      Size = Len == Length::BigL ? 16 : Len == Length::L ? 8 : 4;
    } else if (Conversion == 'p') {
      Size = DL.getPointerSize();
    } else if (Conversion == 'c') {
      Size = Width ? Width : 1;
    } else if (Conversion == 's' || Conversion == '[') {
      // Without a field width libc may write an unbounded token plus NUL.
      if (!Width)
        return std::nullopt;
      Size = Width + 1;
    } else {
      return std::nullopt;
    }
    if (Destination++ == ArgNo)
      return Size;
  }
  return std::nullopt;
}

// LLVM's libc-aware ModRef modelling does not enumerate variadic scanf
// destinations.  With a local recovered frame, MemorySSA can consequently
// attach a load after scanf to the pre-call memset and GVN may replace real
// input with zero.  Isolate each bounded destination in its own shadow object,
// seed it from the old value (preserving failed-conversion semantics), then
// perform one volatile boundary read and an explicit frame store after the
// call.  Volatility is confined to the private shadow and is needed only to
// express the write that LLVM's scanf model omits.
unsigned isolateRecoveredScanfDestinations(Module &M, bool &Changed) {
  struct Destination {
    CallInst *Call = nullptr;
    unsigned ArgNo = 0;
    Value *Original = nullptr;
    uint64_t Size = 0;
    int64_t Offset = 0;
    GlobalVariable *Backing = nullptr;
  };

  const DataLayout &DL = M.getDataLayout();
  DenseMap<CallInst *, SmallVector<Destination, 4>> Calls;
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB) {
        auto *CI = dyn_cast<CallInst>(&I);
        Function *Callee = CI ? CI->getCalledFunction() : nullptr;
        if (!CI || !Callee ||
            (Callee->getName() != "scanf" &&
             Callee->getName() != "__isoc99_scanf"))
          continue;
        for (unsigned ArgNo = 1; ArgNo < CI->arg_size(); ++ArgNo) {
          auto Size = getScanfDestinationSize(*CI, ArgNo, DL);
          if (!Size || !*Size || *Size > 4096)
            continue;
          for (GlobalVariable &GV : M.globals()) {
            if (!GV.getName().starts_with("frame_storage_backing."))
              continue;
            SmallPtrSet<Value *, 32> Seen;
            auto Offset = evaluateFramePointerOffset(
                CI->getArgOperand(ArgNo), GV, DL, Seen);
            if (!Offset || *Offset < 0)
              continue;
            Calls[CI].push_back({CI, ArgNo, CI->getArgOperand(ArgNo),
                                 *Size, *Offset, &GV});
            break;
          }
        }
      }
  }

  unsigned Isolated = 0;
  for (auto &Entry : Calls) {
    CallInst *CI = Entry.first;
    SmallVector<Destination, 4> &Destinations = Entry.second;
    bool Safe = !Destinations.empty();
    for (unsigned I = 0; Safe && I < Destinations.size(); ++I) {
      if (Destinations[I].Offset >
          std::numeric_limits<int64_t>::max() -
              int64_t(Destinations[I].Size)) {
        Safe = false;
        break;
      }
      int64_t IEnd = Destinations[I].Offset + Destinations[I].Size;
      for (unsigned J = I + 1; J < Destinations.size(); ++J) {
        if (Destinations[I].Backing != Destinations[J].Backing)
          continue;
        int64_t JEnd = Destinations[J].Offset + Destinations[J].Size;
        if (Destinations[I].Offset < JEnd && Destinations[J].Offset < IEnd) {
          Safe = false;
          break;
        }
      }
    }
    if (!Safe)
      continue;

    Function *Owner = CI->getFunction();
    IRBuilder<> EntryBuilder(&*Owner->getEntryBlock().getFirstInsertionPt());
    IRBuilder<> Before(CI);
    Instruction *AfterPoint = CI->getNextNode();
    if (!AfterPoint)
      continue;
    IRBuilder<> After(AfterPoint);
    for (Destination &D : Destinations) {
      unsigned Bits = unsigned(D.Size * 8);
      IntegerType *StorageTy = Type::getIntNTy(M.getContext(), Bits);
      AllocaInst *Shadow = EntryBuilder.CreateAlloca(
          StorageTy, nullptr, "native.scanf.shadow");
      Shadow->setAlignment(Align(1));
      LoadInst *Old = Before.CreateAlignedLoad(StorageTy, D.Original,
                                                Align(1),
                                                "native.scanf.old");
      Before.CreateAlignedStore(Old, Shadow, Align(1));
      CI->setArgOperand(D.ArgNo, Shadow);

      LoadInst *Written = After.CreateAlignedLoad(
          StorageTy, Shadow, Align(1), "native.scanf.written");
      Written->setVolatile(true);
      After.CreateAlignedStore(Written, D.Original, Align(1));
      ++Isolated;
      Changed = true;
    }
  }
  return Isolated;
}

bool proveConstantFrameBacking(GlobalVariable &Backing,
                                      SmallVectorImpl<ProvenFrameAccess> &Out,
                                      Function *&Owner, uint64_t &ObjectSize) {
  auto *AT = dyn_cast<ArrayType>(Backing.getValueType());
  if (!AT || !AT->getElementType()->isIntegerTy(8) ||
      !Backing.hasInternalLinkage() || !Backing.hasInitializer() ||
      !Backing.getInitializer()->isNullValue())
    return false;

  ObjectSize = AT->getNumElements();
  if (!ObjectSize || ObjectSize > uint64_t(std::numeric_limits<int64_t>::max()))
    return false;
  const DataLayout &DL = Backing.getParent()->getDataLayout();
  std::set<std::pair<Value *, int64_t>> Visited;

  std::function<bool(Value *, int64_t)> Walk = [&](Value *Pointer,
                                                    int64_t Offset) {
    if (!Visited.insert({Pointer, Offset}).second)
      return true;
    for (User *U : Pointer->users()) {
      if (auto *GEP = dyn_cast<GEPOperator>(U)) {
        if (GEP->getPointerOperand() != Pointer)
          return false;
        unsigned Bits = DL.getIndexSizeInBits(GEP->getPointerAddressSpace());
        APInt Delta(Bits, 0, true);
        if (!GEP->accumulateConstantOffset(DL, Delta) ||
            !Delta.isSignedIntN(64))
          return false;
        int64_t Next = 0;
        if (!addSignedOffset(Offset, Delta.getSExtValue(), Next) ||
            !Walk(cast<Value>(U), Next))
          return false;
        continue;
      }
      if (auto *BC = dyn_cast<BitCastOperator>(U)) {
        if (BC->getOperand(0) != Pointer || !Walk(cast<Value>(U), Offset))
          return false;
        continue;
      }

      auto AddAccess = [&](Instruction *I, unsigned PointerOperand,
                           Type *AccessTy, bool Reads, bool Writes) {
        TypeSize Size = DL.getTypeStoreSize(AccessTy);
        if (Size.isScalable() || Size.getFixedValue() == 0 ||
            Size.getFixedValue() > uint64_t(std::numeric_limits<int64_t>::max()))
          return false;
        int64_t End = 0;
        if (Offset < 0 ||
            !addSignedOffset(Offset, int64_t(Size.getFixedValue()), End) ||
            uint64_t(End) > ObjectSize)
          return false;
        Function *F = I->getFunction();
        if (!F || (Owner && Owner != F))
          return false;
        Owner = F;
        Out.push_back({I, PointerOperand, Offset, End, Reads, Writes});
        return true;
      };

      auto AddSizedAccess = [&](Instruction *I, unsigned PointerOperand,
                                uint64_t Size, bool Reads, bool Writes) {
        if (!Size || Size > uint64_t(std::numeric_limits<int64_t>::max()))
          return false;
        int64_t End = 0;
        if (Offset < 0 || !addSignedOffset(Offset, int64_t(Size), End) ||
            uint64_t(End) > ObjectSize)
          return false;
        Function *F = I->getFunction();
        if (!F || (Owner && Owner != F))
          return false;
        Owner = F;
        Out.push_back({I, PointerOperand, Offset, End, Reads, Writes});
        return true;
      };

      if (auto *LI = dyn_cast<LoadInst>(U)) {
        if (LI->getPointerOperand() != Pointer || LI->isVolatile() ||
            LI->isAtomic() || !AddAccess(LI, 0, LI->getType(), true, false))
          return false;
        continue;
      }
      if (auto *SI = dyn_cast<StoreInst>(U)) {
        if (SI->getValueOperand() == Pointer ||
            SI->getPointerOperand() != Pointer || SI->isVolatile() ||
            SI->isAtomic() ||
            !AddAccess(SI, 1, SI->getValueOperand()->getType(), false, true))
          return false;
        continue;
      }
      if (auto *MS = dyn_cast<MemSetInst>(U)) {
        auto *Length = dyn_cast<ConstantInt>(MS->getLength());
        auto *Byte = dyn_cast<ConstantInt>(MS->getValue());
        if (MS->getRawDest() != Pointer || MS->isVolatile() || !Length ||
            !Byte || !Byte->getType()->isIntegerTy(8) ||
            Length->getValue().getActiveBits() > 64 ||
            !AddSizedAccess(MS, 0, Length->getValue().getLimitedValue(),
                            false, true))
          return false;
        continue;
      }
      if (auto *CB = dyn_cast<CallBase>(U)) {
        bool Found = false;
        for (unsigned ArgNo = 1; ArgNo < CB->arg_size(); ++ArgNo) {
          if (CB->getArgOperand(ArgNo) != Pointer)
            continue;
          auto Size = getScanfDestinationSize(*CB, ArgNo, DL);
          if (!Size || Found ||
              !AddSizedAccess(CB, ArgNo, *Size, false, true))
            return false;
          Found = true;
        }
        if (Found)
          continue;
      }
      // Unknown calls, intrinsics and every other escape reject the complete
      // transaction.  scanf destinations above have a format-derived bound
      // and the libc contract does not retain their pointer.
      return false;
    }
    return true;
  };

  return Walk(&Backing, 0) && Owner && !Out.empty();
}

bool readsAreDominatedByWrites(ArrayRef<ProvenFrameAccess> Accesses,
                                      Function &Owner) {
  DominatorTree DT(Owner);
  for (const ProvenFrameAccess &Read : Accesses) {
    if (!Read.Reads)
      continue;
    SmallVector<std::pair<int64_t, int64_t>, 8> Covered;
    for (const ProvenFrameAccess &Write : Accesses) {
      if (!Write.Writes || Write.Inst == Read.Inst ||
          !DT.dominates(Write.Inst, Read.Inst))
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
    // The old backing is zero-initialized.  A byte not definitely written on
    // every path cannot become an uninitialized native-stack byte.
    if (Cursor < Read.End)
      return false;
  }
  return true;
}

unsigned compactProvenConstantFrameBackings(Module &M, bool &Changed) {
  SmallVector<GlobalVariable *, 8> Candidates;
  for (GlobalVariable &GV : M.globals())
    if (GV.getName().starts_with("frame_storage_backing."))
      Candidates.push_back(&GV);

  unsigned Compacted = 0;
  for (GlobalVariable *Backing : Candidates) {
    SmallVector<ProvenFrameAccess, 16> Accesses;
    Function *Owner = nullptr;
    uint64_t ObjectSize = 0;
    if (!proveConstantFrameBacking(*Backing, Accesses, Owner, ObjectSize))
      continue;

    bool IsProcessEntrypoint = Owner->getName() == "main" && Owner->use_empty();
    if (!IsProcessEntrypoint && !readsAreDominatedByWrites(Accesses, *Owner))
      continue;

    int64_t Min = Accesses.front().Begin;
    int64_t Max = Accesses.front().End;
    Align FrameAlign(1);
    for (const ProvenFrameAccess &Access : Accesses) {
      Min = std::min(Min, Access.Begin);
      Max = std::max(Max, Access.End);
      if (auto *LI = dyn_cast<LoadInst>(Access.Inst))
        FrameAlign = std::max(FrameAlign, LI->getAlign());
      else if (auto *SI = dyn_cast<StoreInst>(Access.Inst))
        FrameAlign = std::max(FrameAlign, SI->getAlign());
      else if (auto *MS = dyn_cast<MemSetInst>(Access.Inst))
        FrameAlign = std::max(
            FrameAlign, MS->getDestAlign().value_or(Align(1)));
    }
    // Preserve each old address's residue modulo the strongest surviving
    // access alignment.  Rebasing [Min, Max) directly to byte zero is wrong
    // when Min is not alignment-congruent to zero: the old pointer may be
    // `backing + 8` with align 16 metadata, and changing it to `alloca + 0`
    // lets optimizers make different assumptions.  A small leading pad keeps
    // every new address congruent to its original absolute byte offset.
    uint64_t Prefix = uint64_t(Min) % FrameAlign.value();
    uint64_t FrameSize = Prefix + uint64_t(Max - Min);
    if (!FrameSize || FrameSize > 1024 * 1024)
      continue;
    ArrayType *FrameTy = ArrayType::get(Type::getInt8Ty(M.getContext()),
                                        FrameSize);
    IRBuilder<> EntryBuilder(&*Owner->getEntryBlock().getFirstInsertionPt());
    AllocaInst *Frame = EntryBuilder.CreateAlloca(
        FrameTy, nullptr, "native_frame.compact");
    Frame->setAlignment(FrameAlign);
    if (IsProcessEntrypoint)
      EntryBuilder.CreateMemSet(Frame, EntryBuilder.getInt8(0), FrameSize,
                                FrameAlign);

    for (const ProvenFrameAccess &Access : Accesses) {
      IRBuilder<> B(Access.Inst);
      Value *Local = B.CreateInBoundsGEP(
          FrameTy, Frame,
          {B.getInt64(0),
           B.getInt64(Prefix + uint64_t(Access.Begin - Min))},
          "native.frame.slot");
      Access.Inst->setOperand(Access.PointerOperand, Local);
      // Lifted IR frequently overstates alignment after byte-address stack
      // recovery (for example align 16 at backing+8).  That is immediate UB
      // and lets O2 choose a different result merely because a global became
      // an alloca.  The backing alignment plus proven absolute byte offset is
      // the strongest alignment actually established by the IR object.
      Align ProvenAlign = commonAlignment(
          Backing->getAlign().valueOrOne(), uint64_t(Access.Begin));
      if (auto *LI = dyn_cast<LoadInst>(Access.Inst))
        LI->setAlignment(ProvenAlign);
      else if (auto *SI = dyn_cast<StoreInst>(Access.Inst))
        SI->setAlignment(ProvenAlign);
      else if (auto *MS = dyn_cast<MemSetInst>(Access.Inst))
        MS->setDestAlignment(ProvenAlign);
    }
    Backing->removeDeadConstantUsers();
    if (!Backing->use_empty())
      report_fatal_error("proven frame compaction left an unexpected use");
    Backing->eraseFromParent();
    ++Compacted;
    Changed = true;
  }
  return Compacted;
}

} // namespace brighten_native_cleanup
