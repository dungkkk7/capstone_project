#include "NativeCleanupInternal.h"
#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/LazyValueInfo.h"

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
evaluateFrameInteger(Value *V, Value &Backing, const DataLayout &DL,
                     unsigned Bits, SmallPtrSetImpl<Value *> &IntegerSeen) {
  if (!V || !V->getType()->isIntegerTy() ||
      V->getType()->getIntegerBitWidth() != Bits)
    return std::nullopt;
  if (auto *CI = dyn_cast<ConstantInt>(V))
    return FrameAffineInteger{CI->getValue(), 0};
  if (auto *PN = dyn_cast<PHINode>(V)) {
    Value *Common = nullptr;
    for (Value *Incoming : PN->incoming_values()) {
      if (Incoming == PN)
        continue;
      if (!Common)
        Common = Incoming;
      else if (Incoming != Common)
        return std::nullopt;
    }
    if (Common)
      return evaluateFrameInteger(Common, Backing, DL, Bits, IntegerSeen);
  }
  if (auto *SI = dyn_cast<SelectInst>(V))
    if (SI->getTrueValue() == SI->getFalseValue())
      return evaluateFrameInteger(SI->getTrueValue(), Backing, DL, Bits,
                                  IntegerSeen);

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
evaluateFramePointerOffset(Value *V, Value &Backing,
                           const DataLayout &DL,
                           SmallPtrSetImpl<Value *> &PointerSeen) {
  if (!V || !V->getType()->isPointerTy() ||
      !PointerSeen.insert(V).second)
    return std::nullopt;
  if (V->stripPointerCasts() == &Backing)
    return int64_t(0);
  if (auto *Op = dyn_cast<Operator>(V);
      Op && Op->getOpcode() == Instruction::IntToPtr) {
    auto *IntegerTy = dyn_cast<IntegerType>(Op->getOperand(0)->getType());
    unsigned AddressSpace = V->getType()->getPointerAddressSpace();
    unsigned PointerBits = DL.getIndexSizeInBits(AddressSpace);
    if (!IntegerTy || IntegerTy->getBitWidth() != PointerBits)
      return std::nullopt;
    SmallPtrSet<Value *, 32> IntegerSeen;
    auto Address = evaluateFrameInteger(Op->getOperand(0), Backing, DL,
                                        PointerBits, IntegerSeen);
    // inttoptr(ptrtoint(Backing) + C) is exactly Backing+C.  Any other root
    // coefficient would change or discard provenance and must remain an
    // integer-derived pointer.
    if (!Address || Address->RootCoefficient != 1 ||
        !Address->Constant.isSignedIntN(64))
      return std::nullopt;
    return Address->Constant.getSExtValue();
  }
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

static bool evaluateFiniteFrameIntegerAlternatives(
    Value *V, Value &Backing, const DataLayout &DL,
    SmallPtrSetImpl<Value *> &Active,
    SmallVectorImpl<FrameAffineInteger> &Out, unsigned Depth = 0) {
  if (!V || !V->getType()->isIntegerTy() || Depth > 64 ||
      !Active.insert(V).second)
    return false;
  auto Finish = [&](bool Result) {
    Active.erase(V);
    return Result;
  };
  constexpr size_t MaxAlternatives = 128;
  auto Normalize = [&]() {
    llvm::sort(Out, [](const FrameAffineInteger &Left,
                       const FrameAffineInteger &Right) {
      if (Left.RootCoefficient != Right.RootCoefficient)
        return Left.RootCoefficient < Right.RootCoefficient;
      return Left.Constant.ult(Right.Constant);
    });
    Out.erase(std::unique(Out.begin(), Out.end(),
                          [](const FrameAffineInteger &Left,
                             const FrameAffineInteger &Right) {
                            return Left.RootCoefficient ==
                                       Right.RootCoefficient &&
                                   Left.Constant == Right.Constant;
                          }),
              Out.end());
    return Out.size() <= MaxAlternatives;
  };

  SmallPtrSet<Value *, 16> ExactSeen;
  if (auto Exact = evaluateFrameInteger(
          V, Backing, DL, V->getType()->getIntegerBitWidth(), ExactSeen)) {
    Out.push_back(std::move(*Exact));
    return Finish(true);
  }
  if (auto *PN = dyn_cast<PHINode>(V)) {
    for (Value *Incoming : PN->incoming_values()) {
      SmallVector<FrameAffineInteger, 8> Alternatives;
      if (!evaluateFiniteFrameIntegerAlternatives(
              Incoming, Backing, DL, Active, Alternatives, Depth + 1))
        return Finish(false);
      Out.append(Alternatives.begin(), Alternatives.end());
      if (Out.size() > MaxAlternatives)
        return Finish(false);
    }
    return Finish(Normalize());
  }
  if (auto *SI = dyn_cast<SelectInst>(V)) {
    for (Value *Arm : {SI->getTrueValue(), SI->getFalseValue()}) {
      SmallVector<FrameAffineInteger, 8> Alternatives;
      if (!evaluateFiniteFrameIntegerAlternatives(
              Arm, Backing, DL, Active, Alternatives, Depth + 1))
        return Finish(false);
      Out.append(Alternatives.begin(), Alternatives.end());
    }
    return Finish(Normalize());
  }
  auto *BO = dyn_cast<BinaryOperator>(V);
  if (!BO || (BO->getOpcode() != Instruction::Add &&
              BO->getOpcode() != Instruction::Sub))
    return Finish(false);
  SmallVector<FrameAffineInteger, 8> Left;
  SmallVector<FrameAffineInteger, 8> Right;
  if (!evaluateFiniteFrameIntegerAlternatives(
          BO->getOperand(0), Backing, DL, Active, Left, Depth + 1) ||
      !evaluateFiniteFrameIntegerAlternatives(
          BO->getOperand(1), Backing, DL, Active, Right, Depth + 1))
    return Finish(false);
  int64_t Sign = BO->getOpcode() == Instruction::Add ? 1 : -1;
  for (const FrameAffineInteger &L : Left)
    for (const FrameAffineInteger &R : Right) {
      if (Out.size() >= MaxAlternatives)
        return Finish(false);
      Out.push_back({Sign == 1 ? L.Constant + R.Constant
                              : L.Constant - R.Constant,
                     L.RootCoefficient + Sign * R.RootCoefficient});
    }
  return Finish(Normalize());
}

unsigned canonicalizeFrameBackingAffinePointers(Module &M,
                                                        bool &Changed) {
  unsigned Rewritten = 0;
  const DataLayout &DL = M.getDataLayout();
  SmallVector<Value *, 16> Backings;
  for (GlobalVariable &Backing : M.globals()) {
    if (Backing.getName().starts_with("frame_storage_backing."))
      Backings.push_back(&Backing);
  }
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : F.getEntryBlock()) {
      auto *AI = dyn_cast<AllocaInst>(&I);
      auto *AT = AI ? dyn_cast<ArrayType>(AI->getAllocatedType()) : nullptr;
      if (!AI || !AT || !AT->getElementType()->isIntegerTy(8))
        continue;
      if (AI->getName().starts_with("frame_storage") ||
          AI->getName().starts_with("native_stack_storage"))
        Backings.push_back(AI);
    }
  }
  for (Value *Backing : Backings) {
    if (!Backing)
      continue;
    Function *Owner =
        isa<AllocaInst>(Backing) ? cast<AllocaInst>(Backing)->getFunction()
                                : nullptr;
    SmallVector<std::pair<Instruction *, unsigned>, 64> Operands;
    for (Function &F : M) {
      if (F.isDeclaration() || (Owner && Owner != &F))
        continue;
      for (BasicBlock &BB : F)
        for (Instruction &I : BB)
          for (unsigned OpNo = 0; OpNo < I.getNumOperands(); ++OpNo)
            if (I.getOperand(OpNo)->getType()->isPointerTy()) {
              Value *Operand = I.getOperand(OpNo);
              if (Operand == Backing)
                continue;
              if (auto *DirectGEP = dyn_cast<GEPOperator>(Operand)) {
                APInt DirectOffset(
                    DL.getIndexSizeInBits(
                        DirectGEP->getPointerAddressSpace()),
                    0, true);
                if (DirectGEP->getPointerOperand()->stripPointerCasts() ==
                        Backing &&
                    DirectGEP->accumulateConstantOffset(DL, DirectOffset))
                  continue;
              }
              SmallPtrSet<Value *, 32> Seen;
              auto Evaluated = evaluateFramePointerOffset(
                  Operand, *Backing, DL, Seen);
              if (Evaluated)
                Operands.push_back({&I, OpNo});
            }
    }
    for (auto [I, OpNo] : Operands) {
      SmallPtrSet<Value *, 32> Seen;
      auto Offset = evaluateFramePointerOffset(I->getOperand(OpNo), *Backing,
                                               DL, Seen);
      if (!Offset)
        continue;
      Instruction *InsertBefore = I;
      if (auto *PN = dyn_cast<PHINode>(I)) {
        BasicBlock *Incoming = PN->getIncomingBlock(OpNo);
        if (!Incoming || !Incoming->getTerminator())
          continue;
        // A non-PHI instruction inserted directly before PN can split the
        // contiguous PHI prefix and produce invalid IR.  The backing and its
        // constant offset dominate every incoming edge, so materialize this
        // particular operand in the corresponding predecessor instead.
        InsertBefore = Incoming->getTerminator();
      }
      IRBuilder<> B(InsertBefore);
      Value *Direct = B.CreateGEP(B.getInt8Ty(), Backing,
                                  B.getInt64(*Offset), "native.frame.direct");
      I->setOperand(OpNo, Direct);
      ++Rewritten;
      Changed = true;
    }
    if (auto *GV = dyn_cast<GlobalVariable>(Backing))
      GV->removeDeadConstantUsers();
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
        // A nested native function can retain a runtime RSP/RBP delta while
        // still being rooted unambiguously in the module's recovered frame
        // backing.  Exact constant-offset evaluation is unnecessary for
        // provenance: generated native.data.pointer.select chains must honor
        // the earlier stack-first classification for every such address.
        if (auto *GV = dyn_cast<GlobalVariable>(P))
          return GV->getName().starts_with("frame_storage_backing.");
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

struct BoundedPointerCallAccess {
  uint64_t Size = 0;
  bool Reads = false;
  bool Writes = false;
};

// Small, contract-based memory summaries for libc calls that take an explicit
// byte count.  These are sufficient to relocate a recovered stack object;
// unbounded string APIs, unknown callees and dynamic/overflowing sizes remain
// escapes.  scanf is handled separately from its parsed format string.
static std::optional<BoundedPointerCallAccess>
getBoundedPointerCallAccess(CallBase &CB, unsigned ArgNo) {
  Function *Callee = CB.getCalledFunction();
  if (!Callee)
    return std::nullopt;
  StringRef Name = Callee->getName();
  auto ConstantSize = [&](unsigned Index) -> std::optional<uint64_t> {
    if (Index >= CB.arg_size())
      return std::nullopt;
    auto *CI = dyn_cast<ConstantInt>(CB.getArgOperand(Index));
    if (!CI || CI->getValue().getActiveBits() > 63)
      return std::nullopt;
    return CI->getZExtValue();
  };
  if ((Name == "memcpy" || Name == "memmove") && CB.arg_size() >= 3) {
    auto Size = ConstantSize(2);
    if (!Size || !*Size)
      return std::nullopt;
    if (ArgNo == 0)
      return BoundedPointerCallAccess{*Size, Name == "memmove", true};
    if (ArgNo == 1)
      return BoundedPointerCallAccess{*Size, true, false};
  }
  if (Name == "fgets" && ArgNo == 0 && CB.arg_size() >= 2) {
    auto *Count = dyn_cast<ConstantInt>(CB.getArgOperand(1));
    if (!Count || !Count->getValue().isStrictlyPositive() ||
        Count->getValue().getActiveBits() > 63)
      return std::nullopt;
    return BoundedPointerCallAccess{Count->getZExtValue(), false, true};
  }
  if ((Name == "read" || Name == "write") && ArgNo == 1 &&
      CB.arg_size() >= 3) {
    auto Size = ConstantSize(2);
    if (!Size || !*Size)
      return std::nullopt;
    return BoundedPointerCallAccess{*Size, Name == "write", Name == "read"};
  }
  if ((Name == "fread" || Name == "fwrite") && ArgNo == 0 &&
      CB.arg_size() >= 3) {
    auto ElementSize = ConstantSize(1);
    auto Count = ConstantSize(2);
    if (!ElementSize || !Count || !*ElementSize || !*Count ||
        *ElementSize > std::numeric_limits<uint64_t>::max() / *Count)
      return std::nullopt;
    uint64_t Size = *ElementSize * *Count;
    return BoundedPointerCallAccess{Size, Name == "fwrite", Name == "fread"};
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
    Value *Backing = nullptr;
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
          SmallVector<Value *, 8> FrameObjects;
          for (GlobalVariable &GV : M.globals())
            if (GV.getName().starts_with("frame_storage_backing."))
              FrameObjects.push_back(&GV);
          for (Instruction &EntryI : F.getEntryBlock()) {
            auto *AI = dyn_cast<AllocaInst>(&EntryI);
            auto *AT = AI ? dyn_cast<ArrayType>(AI->getAllocatedType())
                          : nullptr;
            if (!AI || !AT || !AT->getElementType()->isIntegerTy(8))
              continue;
            StringRef Name = AI->getName();
            if (Name.starts_with("frame_storage") ||
                Name.starts_with("native_stack_storage"))
              FrameObjects.push_back(AI);
          }
          for (Value *FrameObject : FrameObjects) {
            SmallPtrSet<Value *, 32> Seen;
            auto Offset = evaluateFramePointerOffset(
                CI->getArgOperand(ArgNo), *FrameObject, DL, Seen);
            if (!Offset || *Offset < 0)
              continue;
            Calls[CI].push_back({CI, ArgNo, CI->getArgOperand(ArgNo),
                                 *Size, *Offset, FrameObject});
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

static bool proveConstantFrameObject(
    Value &Backing, ArrayType &AT, const DataLayout &DL,
    SmallVectorImpl<ProvenFrameAccess> &Out, Function *&Owner,
    uint64_t &ObjectSize) {
  if (!AT.getElementType()->isIntegerTy(8))
    return false;
  ObjectSize = AT.getNumElements();
  if (!ObjectSize || ObjectSize > uint64_t(std::numeric_limits<int64_t>::max()))
    return false;
  std::set<std::pair<Value *, int64_t>> Visited;

  std::function<bool(Value *, int64_t)> Walk = [&](Value *Pointer,
                                                    int64_t Offset) {
    if (!Visited.insert({Pointer, Offset}).second)
      return true;
    for (User *U : Pointer->users()) {
      if (auto *GEP = dyn_cast<GEPOperator>(U)) {
        if (GEP->getPointerOperand() != Pointer) {
          return false;
        }
        unsigned Bits = DL.getIndexSizeInBits(GEP->getPointerAddressSpace());
        APInt Delta(Bits, 0, true);
        if (!GEP->accumulateConstantOffset(DL, Delta) ||
            !Delta.isSignedIntN(64)) {
          if (!GEP->getSourceElementType()->isIntegerTy(8) ||
              GEP->getNumIndices() != 1)
            return false;
          SmallPtrSet<Value *, 32> Active;
          SmallVector<FrameAffineInteger, 16> Alternatives;
          SmallVector<int64_t, 16> Offsets;
          if (evaluateFiniteFrameIntegerAlternatives(
                  GEP->idx_begin()->get(), Backing, DL, Active,
                  Alternatives)) {
            for (const FrameAffineInteger &Alternative : Alternatives) {
              if (Alternative.RootCoefficient != 0 ||
                  !Alternative.Constant.isSignedIntN(64))
                return false;
              int64_t Next = 0;
              if (!addSignedOffset(
                      Offset, Alternative.Constant.getSExtValue(), Next))
                return false;
              Offsets.push_back(Next);
            }
          } else {
            // For a genuine loop/input-dependent local-array index, use the
            // path-sensitive range established by dominating CFG guards at
            // this exact access.  Full/wrapped/oversized ranges remain
            // unsupported; the compact frame is published only when every
            // possible byte offset lies in one finite native-local window.
            auto *GEPI = dyn_cast<Instruction>(cast<Value>(U));
            Function *F = GEPI ? GEPI->getFunction() : nullptr;
            if (!F)
              return false;
            AssumptionCache AC(*F);
            LazyValueInfo LVI(&AC, &DL);
            ConstantRange Range = LVI.getConstantRange(
                GEP->idx_begin()->get(), GEPI, false);
            if (Range.isEmptySet() || Range.isFullSet())
              return false;
            APInt Lower = Range.getSignedMin();
            APInt Upper = Range.getSignedMax();
            if (!Lower.isSignedIntN(64) || !Upper.isSignedIntN(64))
              return false;
            int64_t MinIndex = Lower.getSExtValue();
            int64_t MaxIndex = Upper.getSExtValue();
            int64_t LargestAllowed = 0;
            if (MinIndex > MaxIndex ||
                !addSignedOffset(MinIndex, 1024 * 1024, LargestAllowed) ||
                MaxIndex > LargestAllowed)
              return false;
            int64_t MinOffset = 0;
            int64_t MaxOffset = 0;
            if (!addSignedOffset(Offset, MinIndex, MinOffset) ||
                !addSignedOffset(Offset, MaxIndex, MaxOffset))
              return false;
            Offsets.push_back(MinOffset);
            Offsets.push_back(MaxOffset);
          }
          llvm::sort(Offsets);
          Offsets.erase(std::unique(Offsets.begin(), Offsets.end()),
                        Offsets.end());
          for (int64_t Next : Offsets)
            if (!Walk(cast<Value>(U), Next))
              return false;
          continue;
        }
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
      if (auto *PN = dyn_cast<PHINode>(U)) {
        if (!PN->getType()->isPointerTy())
          return false;
        SmallVector<int64_t, 8> AlternativeOffsets;
        for (Value *Incoming : PN->incoming_values()) {
          SmallPtrSet<Value *, 16> Seen;
          auto IncomingOffset = evaluateFramePointerOffset(
              Incoming, Backing, DL, Seen);
          if (!IncomingOffset)
            return false;
          AlternativeOffsets.push_back(*IncomingOffset);
        }
        llvm::sort(AlternativeOffsets);
        AlternativeOffsets.erase(
            std::unique(AlternativeOffsets.begin(),
                        AlternativeOffsets.end()),
            AlternativeOffsets.end());
        for (int64_t AlternativeOffset : AlternativeOffsets)
          if (!Walk(PN, AlternativeOffset))
            return false;
        continue;
      }
      if (auto *Select = dyn_cast<SelectInst>(U)) {
        if (!Select->getType()->isPointerTy())
          return false;
        SmallVector<int64_t, 2> AlternativeOffsets;
        for (Value *Arm : {Select->getTrueValue(), Select->getFalseValue()}) {
          SmallPtrSet<Value *, 16> Seen;
          auto ArmOffset = evaluateFramePointerOffset(Arm, Backing, DL, Seen);
          if (!ArmOffset)
            return false;
          AlternativeOffsets.push_back(*ArmOffset);
        }
        llvm::sort(AlternativeOffsets);
        AlternativeOffsets.erase(
            std::unique(AlternativeOffsets.begin(),
                        AlternativeOffsets.end()),
            AlternativeOffsets.end());
        for (int64_t AlternativeOffset : AlternativeOffsets)
          if (!Walk(Select, AlternativeOffset))
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
      if (auto *PTI = dyn_cast<PtrToIntInst>(U)) {
        if (PTI->getPointerOperand() != Pointer) return false;
        Function *F = PTI->getFunction();
        if (!F || (Owner && Owner != F)) return false;
        Owner = F;
        // A ptrtoint of a proven constant frame address is a relocatable
        // frame anchor, not an escape of the backing object.  Record it as a
        // zero-width access so compaction rewrites the operand to the same
        // byte offset in the compact object.  All integer consumers then see
        // one consistently relocated frame address space.
        Out.push_back({PTI, 0, Offset, Offset, false, false});
        continue;
      }
      if (auto *CB = dyn_cast<CallBase>(U)) {
        bool FoundBounded = false;
        for (unsigned ArgNo = 0; ArgNo < CB->arg_size(); ++ArgNo) {
          if (CB->getArgOperand(ArgNo) != Pointer)
            continue;
          auto Access = getBoundedPointerCallAccess(*CB, ArgNo);
          if (!Access || FoundBounded ||
              !AddSizedAccess(CB, ArgNo, Access->Size, Access->Reads,
                              Access->Writes))
            return false;
          FoundBounded = true;
        }
        if (FoundBounded)
          continue;
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

bool proveConstantFrameBacking(GlobalVariable &Backing,
                               SmallVectorImpl<ProvenFrameAccess> &Out,
                               Function *&Owner, uint64_t &ObjectSize) {
  auto *AT = dyn_cast<ArrayType>(Backing.getValueType());
  if (!AT || !Backing.hasInternalLinkage() || !Backing.hasInitializer() ||
      !Backing.getInitializer()->isNullValue())
    return false;
  return proveConstantFrameObject(Backing, *AT,
                                  Backing.getParent()->getDataLayout(), Out,
                                  Owner, ObjectSize);
}

static bool proveConstantFrameAlloca(
    AllocaInst &Backing, SmallVectorImpl<ProvenFrameAccess> &Out,
    Function *&Owner, uint64_t &ObjectSize) {
  auto *AT = dyn_cast<ArrayType>(Backing.getAllocatedType());
  if (!AT || !Backing.isStaticAlloca() || Backing.isArrayAllocation() ||
      !AT->getElementType()->isIntegerTy(8))
    return false;
  StringRef Name = Backing.getName();
  if (!Name.starts_with("frame_storage") &&
      !Name.starts_with("native_stack_storage"))
    return false;
  return proveConstantFrameObject(Backing, *AT,
                                  Backing.getModule()->getDataLayout(), Out,
                                  Owner, ObjectSize);
}

static bool readsAreMustInitialized(ArrayRef<ProvenFrameAccess> Accesses,
                                    Function &Owner) {
  // A single dominating store is sufficient but unnecessarily rejects a
  // common recovered shape where both arms of a branch initialize the same
  // slot before they merge.  Compute a forward must-written dataflow over the
  // exact byte-interval partition induced by the accesses.  Intersection at
  // joins proves initialization on every path; loop headers start at top and
  // converge downward, while the real entry starts empty.
  SmallVector<int64_t, 64> Boundaries;
  DenseMap<Instruction *, SmallVector<const ProvenFrameAccess *, 2>> ByInst;
  for (const ProvenFrameAccess &A : Accesses) {
    if (!A.Inst || A.Begin >= A.End)
      return false;
    Boundaries.push_back(A.Begin);
    Boundaries.push_back(A.End);
    ByInst[A.Inst].push_back(&A);
  }
  llvm::sort(Boundaries);
  Boundaries.erase(std::unique(Boundaries.begin(), Boundaries.end()),
                   Boundaries.end());
  if (Boundaries.size() < 2 || Boundaries.size() > 2048)
    return false;
  unsigned Segments = Boundaries.size() - 1;

  auto ApplyRange = [&](BitVector &Bits, int64_t Begin, int64_t End) {
    for (unsigned I = 0; I < Segments; ++I)
      if (Boundaries[I] >= Begin && Boundaries[I + 1] <= End)
        Bits.set(I);
  };
  auto ContainsRange = [&](const BitVector &Bits, int64_t Begin,
                           int64_t End) {
    for (unsigned I = 0; I < Segments; ++I)
      if (Boundaries[I] >= Begin && Boundaries[I + 1] <= End &&
          !Bits.test(I))
        return false;
    return true;
  };
  auto TransferWrites = [&](BasicBlock &BB, BitVector State) {
    for (Instruction &I : BB)
      if (auto It = ByInst.find(&I); It != ByInst.end())
        for (const ProvenFrameAccess *A : It->second)
          if (A->Writes)
            ApplyRange(State, A->Begin, A->End);
    return State;
  };

  SmallPtrSet<BasicBlock *, 32> Reachable;
  SmallVector<BasicBlock *, 64> Worklist{&Owner.getEntryBlock()};
  while (!Worklist.empty()) {
    BasicBlock *BB = Worklist.pop_back_val();
    if (!Reachable.insert(BB).second)
      continue;
    for (BasicBlock *Succ : successors(BB))
      Worklist.push_back(Succ);
  }

  DenseMap<BasicBlock *, BitVector> In;
  DenseMap<BasicBlock *, BitVector> Out;
  for (BasicBlock *BB : Reachable) {
    bool IsEntry = BB == &Owner.getEntryBlock();
    In[BB] = BitVector(Segments, !IsEntry);
    Out[BB] = TransferWrites(*BB, In[BB]);
  }
  bool DataflowChanged = true;
  unsigned Iterations = 0;
  while (DataflowChanged && ++Iterations <= Owner.size() * 4 + 4) {
    DataflowChanged = false;
    for (BasicBlock &BBRef : Owner) {
      BasicBlock *BB = &BBRef;
      if (!Reachable.contains(BB) || BB == &Owner.getEntryBlock())
        continue;
      BitVector NewIn(Segments, true);
      bool HasReachablePred = false;
      for (BasicBlock *Pred : predecessors(BB)) {
        if (!Reachable.contains(Pred))
          continue;
        NewIn &= Out[Pred];
        HasReachablePred = true;
      }
      if (!HasReachablePred)
        NewIn.reset();
      BitVector NewOut = TransferWrites(*BB, NewIn);
      if (NewIn != In[BB] || NewOut != Out[BB]) {
        In[BB] = std::move(NewIn);
        Out[BB] = std::move(NewOut);
        DataflowChanged = true;
      }
    }
  }
  if (DataflowChanged)
    return false;

  for (BasicBlock &BB : Owner) {
    if (!Reachable.contains(&BB))
      continue;
    BitVector State = In[&BB];
    for (Instruction &I : BB) {
      auto It = ByInst.find(&I);
      if (It == ByInst.end())
        continue;
      for (const ProvenFrameAccess *A : It->second)
        if (A->Reads && !ContainsRange(State, A->Begin, A->End))
          return false;
      for (const ProvenFrameAccess *A : It->second)
        if (A->Writes)
          ApplyRange(State, A->Begin, A->End);
    }
  }
  return true;
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
    if (Cursor < Read.End)
      return false;
  }
  return true;
}

// State-SSA can expose an inlined guest callee as one dynamic frame root:
//
//   %root = gep i8, %frame_top,
//               (%logical_rsp - ptrtoint(%frame_top))
//   %local = gep i8, %root, -N
//
// Keeping that root attached to the compatibility backing prevents SROA from
// recovering ordinary native locals even when the complete pointed-to region
// is private.  Split only regions whose pointer graph is closed, every access
// has a constant negative offset, and every read is dominated by a write in
// the same native invocation.  A store-only root is removed only when the
// module-wide affine alias proof establishes that no load can observe it;
// this covers dead lifted return-address traffic without recognizing code
// addresses or relying on dataset constants.
unsigned localizeProvenDynamicFrameRegions(Module &M, bool &Changed) {
  struct RootEntry {
    GetElementPtrInst *Root = nullptr;
    int64_t LogicalOffset = 0;
  };
  struct Candidate {
    SmallVector<RootEntry, 4> Roots;
    Value *Backing = nullptr;
    Value *LogicalAddress = nullptr;
    Function *Owner = nullptr;
  };

  const DataLayout &DL = M.getDataLayout();
  SmallVector<Value *, 16> Backings;
  for (GlobalVariable &GV : M.globals())
    if (GV.getName().starts_with("frame_storage_backing."))
      Backings.push_back(&GV);
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : F.getEntryBlock()) {
      auto *AI = dyn_cast<AllocaInst>(&I);
      auto *AT = AI ? dyn_cast<ArrayType>(AI->getAllocatedType()) : nullptr;
      if (!AI || !AT || !AT->getElementType()->isIntegerTy(8))
        continue;
      StringRef Name = AI->getName();
      if (Name.starts_with("frame_storage") ||
          Name.starts_with("native_stack_storage"))
        Backings.push_back(AI);
    }
  }

  SmallVector<Candidate, 32> Candidates;
  for (Value *Backing : Backings) {
    Function *Owner = nullptr;
    if (auto *AI = dyn_cast<AllocaInst>(Backing))
      Owner = AI->getFunction();
    for (Function &F : M) {
      if (F.isDeclaration() || (Owner && Owner != &F))
        continue;
      for (BasicBlock &BB : F) {
        for (Instruction &I : BB) {
          auto *Root = dyn_cast<GetElementPtrInst>(&I);
          if (!Root || !Root->getSourceElementType()->isIntegerTy(8) ||
              Root->getNumIndices() != 1)
            continue;
          Value *Base = Root->getPointerOperand();
          SmallPtrSet<Value *, 16> BaseSeen;
          auto BaseOffset =
              evaluateFramePointerOffset(Base, *Backing, DL, BaseSeen);
          if (!BaseOffset)
            continue;
          auto *Delta = dyn_cast<BinaryOperator>(Root->idx_begin()->get());
          auto *Anchor = Delta && Delta->getOpcode() == Instruction::Sub
                             ? dyn_cast<PtrToIntOperator>(Delta->getOperand(1))
                             : nullptr;
          if (!Anchor)
            continue;
          SmallPtrSet<Value *, 16> AnchorSeen;
          auto AnchorOffset = evaluateFramePointerOffset(
              Anchor->getPointerOperand(), *Backing, DL, AnchorSeen);
          if (!AnchorOffset ||
              *AnchorOffset == std::numeric_limits<int64_t>::min())
            continue;
          int64_t LogicalOffset = 0;
          if (!addSignedOffset(*BaseOffset, -*AnchorOffset, LogicalOffset))
            continue;
          Value *LogicalAddress = Delta->getOperand(0);
          auto Existing = llvm::find_if(Candidates, [&](const Candidate &C) {
            return C.Backing == Backing && C.Owner == &F &&
                   C.LogicalAddress == LogicalAddress;
          });
          if (Existing == Candidates.end()) {
            Candidate Group;
            Group.Roots.push_back({Root, LogicalOffset});
            Group.Backing = Backing;
            Group.LogicalAddress = LogicalAddress;
            Group.Owner = &F;
            Candidates.push_back(std::move(Group));
          } else {
            Existing->Roots.push_back({Root, LogicalOffset});
          }
        }
      }
    }
  }

  unsigned Localized = 0;
  for (const Candidate &Candidate : Candidates) {
    SmallVector<RootEntry, 4> Roots;
    for (const RootEntry &Entry : Candidate.Roots)
      if (Entry.Root && Entry.Root->getParent())
        Roots.push_back(Entry);
    if (Roots.empty())
      continue;
    Function *Owner = Candidate.Owner;
    SmallVector<ProvenFrameAccess, 32> Accesses;
    std::set<std::pair<Value *, int64_t>> Visited;
    std::function<bool(Value *, int64_t)> Walk =
        [&](Value *Pointer, int64_t Offset) -> bool {
      if (!Visited.insert({Pointer, Offset}).second)
        return true;
      for (User *U : Pointer->users()) {
        if (auto *GEP = dyn_cast<GEPOperator>(U)) {
          APInt DeltaOffset(
              DL.getIndexSizeInBits(GEP->getPointerAddressSpace()), 0, true);
          if (GEP->getPointerOperand() != Pointer ||
              !GEP->accumulateConstantOffset(DL, DeltaOffset) ||
              !DeltaOffset.isSignedIntN(64))
            return false;
          int64_t Next = 0;
          if (!addSignedOffset(Offset, DeltaOffset.getSExtValue(), Next) ||
              !Walk(cast<Value>(U), Next))
            return false;
          continue;
        }
        if (auto *BC = dyn_cast<BitCastOperator>(U)) {
          if (BC->getOperand(0) != Pointer ||
              !Walk(cast<Value>(U), Offset))
            return false;
          continue;
        }
        auto AddAccess = [&](Instruction *Access, unsigned PointerOperand,
                             Type *Ty, bool Reads, bool Writes) {
          TypeSize Size = DL.getTypeStoreSize(Ty);
          if (Size.isScalable() || !Size.getFixedValue() ||
              Size.getFixedValue() > uint64_t(INT64_MAX))
            return false;
          int64_t End = 0;
          if (!addSignedOffset(Offset, int64_t(Size.getFixedValue()), End))
            return false;
          Accesses.push_back(
              {Access, PointerOperand, Offset, End, Reads, Writes});
          return true;
        };
        auto AddSizedAccess = [&](Instruction *Access,
                                  unsigned PointerOperand, uint64_t Size,
                                  bool Reads, bool Writes) {
          if (!Size || Size > uint64_t(INT64_MAX))
            return false;
          int64_t End = 0;
          if (!addSignedOffset(Offset, int64_t(Size), End))
            return false;
          Accesses.push_back(
              {Access, PointerOperand, Offset, End, Reads, Writes});
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
          if (MS->getRawDest() != Pointer || MS->isVolatile() || !Length ||
              Length->getValue().getActiveBits() > 63)
            return false;
          int64_t End = 0;
          uint64_t Size = Length->getZExtValue();
          if (!Size || !addSignedOffset(Offset, int64_t(Size), End))
            return false;
          Accesses.push_back({MS, 0, Offset, End, false, true});
          continue;
        }
        if (auto *CB = dyn_cast<CallBase>(U)) {
          bool Found = false;
          for (unsigned ArgNo = 0; ArgNo < CB->arg_size(); ++ArgNo) {
            if (CB->getArgOperand(ArgNo) != Pointer)
              continue;
            if (auto Size = getScanfDestinationSize(*CB, ArgNo, DL)) {
              // A failed or partially successful scanf preserves bytes it
              // did not assign.  Treat each destination as read/write so the
              // region proof requires a prior definition on every path.
              if (Found || !AddSizedAccess(CB, ArgNo, *Size, true, true))
                return false;
              Found = true;
              continue;
            }
            auto Summary = getBoundedPointerCallAccess(*CB, ArgNo);
            if (!Summary || Found ||
                !AddSizedAccess(CB, ArgNo, Summary->Size,
                                Summary->Reads || Summary->Writes,
                                Summary->Writes))
              return false;
            Found = true;
          }
          if (Found)
            continue;
        }
        return false;
      }
      return true;
    };
    bool Complete = true;
    for (const RootEntry &Entry : Roots)
      Complete &= Walk(Entry.Root, Entry.LogicalOffset);
    if (!Complete || Accesses.empty())
      continue;

    bool HasRead = llvm::any_of(Accesses, [](const ProvenFrameAccess &A) {
      return A.Reads;
    });
    if (!HasRead) {
      bool WriteOnly = llvm::all_of(Accesses, [&](const ProvenFrameAccess &A) {
        auto *SI = dyn_cast<StoreInst>(A.Inst);
        return SI && isProvenWriteOnlyAffineFrameSlot(
                         *Owner, SI->getPointerOperand());
      });
      if (!WriteOnly)
        continue;
      SmallVector<Instruction *, 16> Stores;
      for (const ProvenFrameAccess &A : Accesses)
        Stores.push_back(A.Inst);
      for (Instruction *I : Stores)
        I->eraseFromParent();
      for (const RootEntry &Entry : Roots)
        if (Entry.Root->getParent())
          RecursivelyDeleteTriviallyDeadInstructions(Entry.Root);
      ++Localized;
      Changed = true;
      continue;
    }

    int64_t Min = Accesses.front().Begin;
    int64_t Max = Accesses.front().End;
    bool NegativeRegion = true;
    Align RegionAlign(1);
    for (const ProvenFrameAccess &A : Accesses) {
      Min = std::min(Min, A.Begin);
      Max = std::max(Max, A.End);
      NegativeRegion &= A.Begin < 0 && A.End <= 0;
      if (auto *LI = dyn_cast<LoadInst>(A.Inst))
        RegionAlign = std::max(RegionAlign, LI->getAlign());
      else if (auto *SI = dyn_cast<StoreInst>(A.Inst))
        RegionAlign = std::max(RegionAlign, SI->getAlign());
      else if (auto *MS = dyn_cast<MemSetInst>(A.Inst))
        RegionAlign = std::max(
            RegionAlign, MS->getDestAlign().value_or(Align(1)));
    }
    bool Initialized = readsAreMustInitialized(Accesses, *Owner);
    if (!NegativeRegion || Min >= 0 || Max > 0 ||
        Min < -(1024 * 1024) || !Initialized)
      continue;

    uint64_t RegionSize = uint64_t(-Min);
    IRBuilder<> EntryBuilder(&*Owner->getEntryBlock().getFirstInsertionPt());
    ArrayType *RegionTy =
        ArrayType::get(Type::getInt8Ty(M.getContext()), RegionSize);
    AllocaInst *Storage = EntryBuilder.CreateAlloca(
        RegionTy, nullptr, "native.local.region");
    Storage->setAlignment(RegionAlign);
    Value *Top = EntryBuilder.CreateInBoundsGEP(
        RegionTy, Storage,
        {EntryBuilder.getInt64(0), EntryBuilder.getInt64(RegionSize)},
        "native.local.region.top");
    for (const RootEntry &Entry : Roots) {
      Value *Replacement = Top;
      if (Entry.LogicalOffset != 0) {
        IRBuilder<> B(Entry.Root);
        Replacement = B.CreateGEP(B.getInt8Ty(), Top,
                                  B.getInt64(Entry.LogicalOffset),
                                  "native.local.region.root");
      }
      Entry.Root->replaceAllUsesWith(Replacement);
    }
    for (const RootEntry &Entry : Roots)
      if (Entry.Root->getParent())
        RecursivelyDeleteTriviallyDeadInstructions(Entry.Root);
    ++Localized;
    Changed = true;
  }

  // Recursive dead-instruction deletion above is allowed to consume an
  // alloca backing once its final anchor disappears.  Do not revisit the raw
  // Backings pointers here; ordinary cleanup/GlobalDCE removes any surviving
  // unused global backing without risking a use-after-free.
  return Localized;
}

// State-SSA initially carries one shared frame_base through every recovered
// call. Some callees, however, touch only their own negative-offset locals;
// retaining the caller's backing object in that ABI is unnecessary once all
// reads are proven to follow local writes. Convert precisely those callees to
// a private native alloca and rebuild their direct-call ABI without
// frame_base. Positive/incoming slots, pointer escapes, dynamic offsets,
// mutually-recursive SCCs and unknown calls remain fail-closed. Direct
// recursion is supported: every invocation receives a fresh private alloca,
// and the self edge is contracted together with the external call sites.
unsigned localizeProvenPrivateFrameArguments(Module &M, bool &Changed) {
  SmallVector<Function *, 16> Candidates;
  for (Function &F : M) {
    bool ContractibleLinkage =
        F.hasLocalLinkage() ||
        (F.isDSOLocal() && F.getCallingConv() == CallingConv::Fast);
    if (F.isDeclaration() || !ContractibleLinkage || F.isVarArg() ||
        F.hasAddressTaken())
      continue;
    Argument *Frame = findNativeStackArgument(F);
    if (!Frame || Frame->getName() != "frame_base")
      continue;
    bool DirectCallsOnly = true;
    for (User *U : F.users()) {
      auto *CI = dyn_cast<CallInst>(U);
      if (!CI || CI->getCalledOperand()->stripPointerCasts() != &F) {
        DirectCallsOnly = false;
        break;
      }
    }
    if (DirectCallsOnly && !F.use_empty())
      Candidates.push_back(&F);
  }

  unsigned Localized = 0;
  const DataLayout &DL = M.getDataLayout();
  for (Function *F : Candidates) {
    if (!F || F->isDeclaration())
      continue;
    Argument *Frame = findNativeStackArgument(*F);
    if (!Frame)
      continue;
    const unsigned RemovedIndex = Frame->getArgNo();

    SmallPtrSet<PtrToIntInst *, 8> Anchors;
    bool ShapeOK = true;
    for (User *U : Frame->users()) {
      if (auto *PTI = dyn_cast<PtrToIntInst>(U)) {
        Anchors.insert(PTI);
        continue;
      }
      // A direct recursive edge carries the old shared frame only until the
      // signature transaction below removes that operand. It is not an
      // address escape: the recursive invocation will own its own alloca.
      if (auto *CI = dyn_cast<CallInst>(U)) {
        bool ExactSelfFrameOperand =
            CI->getCalledOperand()->stripPointerCasts() == F &&
            RemovedIndex < CI->arg_size() &&
            CI->getArgOperand(RemovedIndex) == Frame;
        if (ExactSelfFrameOperand)
          continue;
      }
      auto *GEP = dyn_cast<GetElementPtrInst>(U);
      if (!GEP || GEP->getPointerOperand() != Frame ||
          !GEP->getSourceElementType()->isIntegerTy(8) ||
          GEP->getNumIndices() != 1) {
        ShapeOK = false;
        break;
      }
    }
    if (!ShapeOK || Anchors.empty())
      continue;

    Argument *IncomingRSP = nullptr;
    for (Argument &A : F->args())
      if (A.getName() == "state_in_2312" && A.getType()->isIntegerTy()) {
        IncomingRSP = &A;
        break;
      }
    if (!IncomingRSP)
      continue;

    // Prove each direct frame-base alias to be exactly
    //   frame_base + ((incoming_rsp + C) - ptrtoint(frame_base))
    // and retain C as that alias's logical stack offset. Lifted functions
    // commonly materialize several such aliases rather than one canonical
    // root. Requiring coefficient one for incoming_rsp prevents unrelated
    // state arithmetic from being mistaken for a private stack address.
    struct IncomingAffine {
      int IncomingCoefficient = 0;
      int AnchorCoefficient = 0;
      SmallVector<int64_t, 8> Constants;
    };
    using IncomingEnvironment =
        DenseMap<const Argument *, IncomingAffine>;
    auto NormalizeIncomingConstants = [](SmallVectorImpl<int64_t> &Constants) {
      llvm::sort(Constants);
      Constants.erase(std::unique(Constants.begin(), Constants.end()),
                      Constants.end());
      return Constants.size() <= 64;
    };
    std::function<std::optional<IncomingAffine>(
        Value *, const IncomingEnvironment &, SmallPtrSetImpl<Value *> &,
        unsigned)>
        EvaluateIncoming =
            [&](Value *V, const IncomingEnvironment &Environment,
                SmallPtrSetImpl<Value *> &Seen, unsigned Depth)
            -> std::optional<IncomingAffine> {
      if (!V || Depth > 64)
        return std::nullopt;
      if (auto *Arg = dyn_cast<Argument>(V)) {
        auto It = Environment.find(Arg);
        if (It != Environment.end())
          return It->second;
        if (Arg == IncomingRSP)
          return IncomingAffine{1, 0, {0}};
        return std::nullopt;
      }
      auto *CI = dyn_cast<ConstantInt>(V);
      if (CI) {
        if (!CI->getValue().isSignedIntN(64))
          return std::nullopt;
        return IncomingAffine{0, 0, {CI->getSExtValue()}};
      }
      if (!Seen.insert(V).second)
        return std::nullopt;
      auto Finish = [&](std::optional<IncomingAffine> Result) {
        Seen.erase(V);
        return Result;
      };
      if (auto *PTI = dyn_cast<PtrToIntInst>(V)) {
        if (PTI->getPointerOperand() == Frame &&
            PTI->getType() == IncomingRSP->getType())
          return Finish(IncomingAffine{0, 1, {0}});
        return Finish(std::nullopt);
      }
      if (auto *BO = dyn_cast<BinaryOperator>(V)) {
        if (BO->getOpcode() == Instruction::Xor) {
          auto *AllOnes = dyn_cast<ConstantInt>(BO->getOperand(1));
          if (!AllOnes || !AllOnes->isMinusOne())
            return Finish(std::nullopt);
          auto Value = EvaluateIncoming(BO->getOperand(0), Environment, Seen,
                                        Depth + 1);
          if (!Value)
            return Finish(std::nullopt);
          Value->IncomingCoefficient = -Value->IncomingCoefficient;
          Value->AnchorCoefficient = -Value->AnchorCoefficient;
          for (int64_t &Constant : Value->Constants) {
            if (Constant == std::numeric_limits<int64_t>::min())
              return Finish(std::nullopt);
            Constant = -Constant - 1;
          }
          if (!NormalizeIncomingConstants(Value->Constants))
            return Finish(std::nullopt);
          return Finish(std::move(Value));
        }
        if (BO->getOpcode() != Instruction::Add &&
            BO->getOpcode() != Instruction::Sub)
          return Finish(std::nullopt);
        auto L = EvaluateIncoming(BO->getOperand(0), Environment, Seen,
                                  Depth + 1);
        auto R = EvaluateIncoming(BO->getOperand(1), Environment, Seen,
                                  Depth + 1);
        if (!L || !R)
          return Finish(std::nullopt);
        int Sign = BO->getOpcode() == Instruction::Add ? 1 : -1;
        IncomingAffine Result;
        Result.IncomingCoefficient =
            L->IncomingCoefficient + Sign * R->IncomingCoefficient;
        Result.AnchorCoefficient =
            L->AnchorCoefficient + Sign * R->AnchorCoefficient;
        for (int64_t Left : L->Constants) {
          for (int64_t Right : R->Constants) {
            if (Sign == -1 &&
                Right == std::numeric_limits<int64_t>::min())
              return Finish(std::nullopt);
            int64_t SignedRight = Sign == 1 ? Right : -Right;
            int64_t Constant = 0;
            if (!addSignedOffset(Left, SignedRight, Constant))
              return Finish(std::nullopt);
            Result.Constants.push_back(Constant);
            if (Result.Constants.size() > 64)
              return Finish(std::nullopt);
          }
        }
        if (!NormalizeIncomingConstants(Result.Constants))
          return Finish(std::nullopt);
        return Finish(std::move(Result));
      }
      if (auto *EV = dyn_cast<ExtractValueInst>(V)) {
        if (EV->getNumIndices() != 1)
          return Finish(std::nullopt);
        auto *CB = dyn_cast<CallBase>(EV->getAggregateOperand());
        Function *Callee = CB ? CB->getCalledFunction() : nullptr;
        if (!CB || !Callee || Callee->isDeclaration())
          return Finish(std::nullopt);

        IncomingEnvironment CalleeEnvironment;
        unsigned ArgNo = 0;
        for (Argument &Arg : Callee->args()) {
          if (ArgNo >= CB->arg_size())
            return Finish(std::nullopt);
          SmallPtrSet<Value *, 32> ArgSeen;
          auto Actual = EvaluateIncoming(CB->getArgOperand(ArgNo), Environment,
                                         ArgSeen, Depth + 1);
          if (Actual)
            CalleeEnvironment[&Arg] = std::move(*Actual);
          ++ArgNo;
        }

        unsigned Field = *EV->idx_begin();
        std::optional<IncomingAffine> Result;
        bool SawReturn = false;
        for (BasicBlock &CalleeBB : *Callee) {
          auto *RI = dyn_cast<ReturnInst>(CalleeBB.getTerminator());
          if (!RI || !RI->getReturnValue())
            continue;
          SawReturn = true;
          Value *Aggregate = RI->getReturnValue();
          Value *FieldValue = nullptr;
          while (auto *IV = dyn_cast<InsertValueInst>(Aggregate)) {
            if (IV->getNumIndices() == 1 && *IV->idx_begin() == Field) {
              FieldValue = IV->getInsertedValueOperand();
              break;
            }
            Aggregate = IV->getAggregateOperand();
          }
          if (!FieldValue)
            if (auto *C = dyn_cast<Constant>(Aggregate))
              FieldValue = C->getAggregateElement(Field);
          if (!FieldValue)
            return Finish(std::nullopt);
          auto Returned = EvaluateIncoming(FieldValue, CalleeEnvironment,
                                           Seen, Depth + 1);
          if (!Returned ||
              (Result &&
               (Result->IncomingCoefficient !=
                    Returned->IncomingCoefficient ||
                Result->AnchorCoefficient != Returned->AnchorCoefficient)))
            return Finish(std::nullopt);
          if (!Result)
            Result = IncomingAffine{Returned->IncomingCoefficient,
                                    Returned->AnchorCoefficient, {}};
          Result->Constants.append(Returned->Constants.begin(),
                                   Returned->Constants.end());
          if (Result->Constants.size() > 64 ||
              !NormalizeIncomingConstants(Result->Constants))
            return Finish(std::nullopt);
        }
        if (!SawReturn || !Result)
          return Finish(std::nullopt);
        return Finish(std::move(Result));
      }
      SmallVector<Value *, 8> Arms;
      if (auto *PN = dyn_cast<PHINode>(V))
        Arms.append(PN->incoming_values().begin(),
                    PN->incoming_values().end());
      else if (auto *SI = dyn_cast<SelectInst>(V)) {
        Arms.push_back(SI->getTrueValue());
        Arms.push_back(SI->getFalseValue());
      } else {
        return Finish(std::nullopt);
      }
      std::optional<IncomingAffine> Result;
      for (Value *Arm : Arms) {
        auto Value = EvaluateIncoming(Arm, Environment, Seen, Depth + 1);
        if (!Value ||
            (Result &&
             (Result->IncomingCoefficient != Value->IncomingCoefficient ||
              Result->AnchorCoefficient != Value->AnchorCoefficient)))
          return Finish(std::nullopt);
        if (!Result)
          Result = IncomingAffine{Value->IncomingCoefficient,
                                  Value->AnchorCoefficient, {}};
        Result->Constants.append(Value->Constants.begin(),
                                 Value->Constants.end());
        if (Result->Constants.size() > 64 ||
            !NormalizeIncomingConstants(Result->Constants))
          return Finish(std::nullopt);
      }
      return Finish(std::move(Result));
    };

    struct PrivateFrameRoot {
      GetElementPtrInst *Pointer = nullptr;
      SmallVector<Value *, 4> IndexTerms;
      SmallVector<int64_t, 8> Offsets;
    };
    SmallVector<PrivateFrameRoot, 8> FrameRoots;
    auto AddAffine = [&](IncomingAffine &Left,
                         const IncomingAffine &Right) {
      Left.IncomingCoefficient += Right.IncomingCoefficient;
      Left.AnchorCoefficient += Right.AnchorCoefficient;
      SmallVector<int64_t, 16> Constants;
      for (int64_t L : Left.Constants) {
        for (int64_t R : Right.Constants) {
          int64_t Sum = 0;
          if (!addSignedOffset(L, R, Sum))
            return false;
          Constants.push_back(Sum);
          if (Constants.size() > 64)
            return false;
        }
      }
      Left.Constants = std::move(Constants);
      return NormalizeIncomingConstants(Left.Constants);
    };
    SmallPtrSet<GetElementPtrInst *, 16> CollectedPointerNodes;
    std::function<bool(GetElementPtrInst *, IncomingAffine,
                       SmallVector<Value *, 4>)>
        CollectFrameRoot = [&](GetElementPtrInst *GEP,
                               IncomingAffine Accumulated,
                               SmallVector<Value *, 4> IndexTerms) {
      if (!GEP || !CollectedPointerNodes.insert(GEP).second ||
          !GEP->getSourceElementType()->isIntegerTy(8) ||
          GEP->getNumIndices() != 1 ||
          GEP->idx_begin()->get()->getType() != IncomingRSP->getType())
        return false;
      Value *Index = GEP->idx_begin()->get();
      SmallPtrSet<Value *, 32> Seen;
      IncomingEnvironment Environment;
      auto IndexAffine = EvaluateIncoming(Index, Environment, Seen, 0);
      if (!IndexAffine || !AddAffine(Accumulated, *IndexAffine))
        return false;
      IndexTerms.push_back(Index);

      if (Accumulated.IncomingCoefficient == 1 &&
          Accumulated.AnchorCoefficient == -1) {
        FrameRoots.push_back(
            {GEP, std::move(IndexTerms),
             std::move(Accumulated.Constants)});
        return true;
      }

      // Some optimizer forms split a logical stack address and the negated
      // frame anchor across adjacent i8 GEPs (or put a constant invariant GEP
      // in front). Accumulate that pointer chain until the exact
      // incoming_rsp - ptrtoint(frame_base) relation is complete. An
      // incomplete pointer with any non-GEP observer is an address escape.
      bool SawChild = false;
      for (User *U : GEP->users()) {
        auto *Child = dyn_cast<GetElementPtrInst>(U);
        if (!Child || Child->getPointerOperand() != GEP)
          return false;
        SawChild = true;
        if (!CollectFrameRoot(Child, Accumulated, IndexTerms))
          return false;
      }
      return SawChild;
    };
    for (User *U : Frame->users()) {
      auto *GEP = dyn_cast<GetElementPtrInst>(U);
      if (!GEP)
        continue;
      IncomingAffine Empty{0, 0, {0}};
      if (!CollectFrameRoot(GEP, std::move(Empty), {})) {
        ShapeOK = false;
        break;
      }
    }
    if (!ShapeOK || FrameRoots.empty())
      continue;

    // A private alloca changes the native address corresponding to
    // incoming_rsp. Memory operands rooted in FrameRoots are rewritten below,
    // but an integer derived from incoming_rsp can also be stored and later
    // converted back to a pointer. Such an address would still name the
    // caller's old backing after localization (p00715), so reject the whole
    // transaction unless every address-capable dataflow ends at a proven root.
    // Comparisons and control-flow uses do not preserve an address; returning
    // the integer/aggregate is allowed because it is the recovered RSP state,
    // not a dereference inside this invocation.
    SmallPtrSet<Value *, 16> ProvenRoots;
    for (const PrivateFrameRoot &Root : FrameRoots)
      ProvenRoots.insert(Root.Pointer);
    SmallVector<Value *, 32> RSPWorklist{IncomingRSP};
    SmallPtrSet<Value *, 32> RSPSeen;
    bool RSPAddressEscapes = false;
    auto TraceLogicalOnlyCalleeValue = [&](CallBase &CB, Value *Actual) {
      Function *Callee = CB.getCalledFunction();
      if (!Callee || Callee->isDeclaration() ||
          findNativeStackArgument(*Callee))
        return false;
      SmallVector<Argument *, 4> TaintedFormals;
      SmallVector<Value *, 16> CalleeWorklist;
      for (unsigned I = 0; I < CB.arg_size(); ++I) {
        if (CB.getArgOperand(I) != Actual)
          continue;
        if (I >= Callee->arg_size())
          return false;
        Argument *Formal = Callee->getArg(I);
        if (!Formal->getType()->isIntegerTy())
          return false;
        TaintedFormals.push_back(Formal);
        CalleeWorklist.push_back(Formal);
      }
      if (CalleeWorklist.empty())
        return false;
      SmallPtrSet<Value *, 32> Seen;
      while (!CalleeWorklist.empty()) {
        Value *Current = CalleeWorklist.pop_back_val();
        if (!Seen.insert(Current).second)
          continue;
        for (User *U : Current->users()) {
          if (isa<ReturnInst, BranchInst, SwitchInst, ICmpInst>(U))
            continue;
          if (auto *SI = dyn_cast<StoreInst>(U)) {
            if (SI->getValueOperand() == Current &&
                isProvenWriteOnlyAffineFrameSlot(
                    *Callee, SI->getPointerOperand()))
              continue;
          }
          if (isa<IntToPtrInst, GetElementPtrInst, CallBase, StoreInst,
                  AtomicRMWInst, AtomicCmpXchgInst>(U))
            return false;
          auto *I = dyn_cast<Instruction>(U);
          if (!I || I->getType()->isVoidTy() ||
              (!I->getType()->isIntegerTy() &&
               !I->getType()->isAggregateType()))
            return false;
          CalleeWorklist.push_back(I);
        }
      }

      SmallPtrSet<Value *, 32> FormalSet;
      for (Argument *Formal : TaintedFormals)
        FormalSet.insert(Formal);
      std::function<bool(Value *, SmallPtrSetImpl<Value *> &)>
          DependsOnFormal = [&](Value *V,
                                SmallPtrSetImpl<Value *> &DependencySeen) {
        if (FormalSet.contains(V))
          return true;
        if (!V || isa<Constant>(V) || !DependencySeen.insert(V).second)
          return false;
        auto *I = dyn_cast<Instruction>(V);
        if (!I || I->getFunction() != Callee)
          return false;
        for (Value *Operand : I->operand_values())
          if (DependsOnFormal(Operand, DependencySeen))
            return true;
        return false;
      };

      SmallDenseSet<unsigned, 8> TaintedFields;
      bool ScalarTainted = false;
      for (BasicBlock &BB : *Callee) {
        auto *RI = dyn_cast<ReturnInst>(BB.getTerminator());
        if (!RI || !RI->getReturnValue())
          continue;
        Value *Returned = RI->getReturnValue();
        if (!Returned->getType()->isStructTy()) {
          SmallPtrSet<Value *, 32> DependencySeen;
          ScalarTainted |= DependsOnFormal(Returned, DependencySeen);
          continue;
        }
        auto *ST = cast<StructType>(Returned->getType());
        for (unsigned Field = 0; Field < ST->getNumElements(); ++Field) {
          Value *Aggregate = Returned;
          Value *FieldValue = nullptr;
          while (auto *IV = dyn_cast<InsertValueInst>(Aggregate)) {
            if (IV->getNumIndices() == 1 && *IV->idx_begin() == Field) {
              FieldValue = IV->getInsertedValueOperand();
              break;
            }
            Aggregate = IV->getAggregateOperand();
          }
          if (!FieldValue)
            continue;
          SmallPtrSet<Value *, 32> DependencySeen;
          if (DependsOnFormal(FieldValue, DependencySeen))
            TaintedFields.insert(Field);
        }
      }
      if (ScalarTainted)
        RSPWorklist.push_back(&CB);
      for (User *CallUser : CB.users()) {
        auto *EV = dyn_cast<ExtractValueInst>(CallUser);
        if (!EV || EV->getNumIndices() != 1) {
          if (ScalarTainted)
            continue;
          return false;
        }
        if (TaintedFields.contains(*EV->idx_begin()))
          RSPWorklist.push_back(EV);
      }
      return true;
    };
    while (!RSPWorklist.empty() && !RSPAddressEscapes) {
      Value *Current = RSPWorklist.pop_back_val();
      if (!RSPSeen.insert(Current).second)
        continue;
      for (User *U : Current->users()) {
        if (auto *GEP = dyn_cast<GetElementPtrInst>(U)) {
          if (ProvenRoots.contains(GEP))
            continue;
          RSPAddressEscapes = true;
          break;
        }
        if (auto *CB = dyn_cast<CallBase>(U)) {
          bool ExactSelfRSPOperand =
              CB->getCalledOperand()->stripPointerCasts() == F;
          for (unsigned I = 0; I < CB->arg_size(); ++I) {
            if (CB->getArgOperand(I) != Current)
              continue;
            if (I != IncomingRSP->getArgNo()) {
              ExactSelfRSPOperand = false;
              break;
            }
          }
          if (ExactSelfRSPOperand ||
              TraceLogicalOnlyCalleeValue(*CB, Current))
            continue;
          RSPAddressEscapes = true;
          break;
        }
        if (isa<IntToPtrInst, AtomicRMWInst, AtomicCmpXchgInst>(U)) {
          RSPAddressEscapes = true;
          break;
        }
        if (auto *SI = dyn_cast<StoreInst>(U)) {
          if (SI->getValueOperand() == Current) {
            // A recovered call sequence often spills the exact outgoing RSP
            // solely to feed generated address-dispatch code.  After affine
            // load forwarding and stack-select collapse, such a slot can be
            // write-only.  It no longer carries address data to an observer;
            // the complete frame walk below still rejects calls, escapes,
            // non-local offsets, and every surviving read.
            if (isProvenWriteOnlyAffineFrameSlot(
                    *F, SI->getPointerOperand()))
              continue;
            RSPAddressEscapes = true;
            break;
          }
          continue;
        }
        if (isa<ReturnInst, BranchInst, SwitchInst, ICmpInst>(U))
          continue;
        auto *I = dyn_cast<Instruction>(U);
        if (!I || I->getType()->isVoidTy()) {
          RSPAddressEscapes = true;
          break;
        }
        RSPWorklist.push_back(I);
      }
    }
    if (RSPAddressEscapes)
      continue;

    SmallVector<ProvenFrameAccess, 32> Accesses;
    std::set<std::pair<Value *, int64_t>> Visited;
    std::function<bool(Value *, int64_t)> Walk =
        [&](Value *Pointer, int64_t Offset) -> bool {
      if (!Visited.insert({Pointer, Offset}).second)
        return true;
      for (User *U : Pointer->users()) {
        if (auto *GEP = dyn_cast<GEPOperator>(U)) {
          APInt DeltaOffset(
              DL.getIndexSizeInBits(GEP->getPointerAddressSpace()), 0, true);
          if (GEP->getPointerOperand() != Pointer ||
              !GEP->accumulateConstantOffset(DL, DeltaOffset) ||
              !DeltaOffset.isSignedIntN(64))
            return false;
          int64_t Next = 0;
          if (!addSignedOffset(Offset, DeltaOffset.getSExtValue(), Next) ||
              !Walk(cast<Value>(U), Next))
            return false;
          continue;
        }
        if (auto *BC = dyn_cast<BitCastOperator>(U)) {
          if (BC->getOperand(0) != Pointer ||
              !Walk(cast<Value>(U), Offset))
            return false;
          continue;
        }
        auto AddAccess = [&](Instruction *I, unsigned PointerOperand,
                             Type *Ty, bool Reads, bool Writes) {
          TypeSize TS = DL.getTypeStoreSize(Ty);
          if (TS.isScalable() || !TS.getFixedValue() ||
              TS.getFixedValue() > uint64_t(INT64_MAX))
            return false;
          int64_t End = 0;
          if (!addSignedOffset(Offset, int64_t(TS.getFixedValue()), End) ||
              Offset >= 0 || End > 0)
            return false;
          Accesses.push_back(
              {I, PointerOperand, Offset, End, Reads, Writes});
          return true;
        };
        auto AddSizedAccess = [&](Instruction *I, unsigned PointerOperand,
                                  uint64_t Size, bool Reads, bool Writes) {
          if (!Size || Size > uint64_t(INT64_MAX))
            return false;
          int64_t End = 0;
          if (!addSignedOffset(Offset, int64_t(Size), End) || Offset >= 0 ||
              End > 0)
            return false;
          Accesses.push_back(
              {I, PointerOperand, Offset, End, Reads, Writes});
          return true;
        };
        if (auto *LI = dyn_cast<LoadInst>(U)) {
          if (LI->getPointerOperand() != Pointer || LI->isVolatile() ||
              LI->isAtomic() ||
              !AddAccess(LI, 0, LI->getType(), true, false))
            return false;
          continue;
        }
        if (auto *SI = dyn_cast<StoreInst>(U)) {
          if (SI->getValueOperand() == Pointer ||
              SI->getPointerOperand() != Pointer || SI->isVolatile() ||
              SI->isAtomic() ||
              !AddAccess(SI, 1, SI->getValueOperand()->getType(), false,
                         true))
            return false;
          continue;
        }
        if (auto *MS = dyn_cast<MemSetInst>(U)) {
          auto *Length = dyn_cast<ConstantInt>(MS->getLength());
          if (MS->getRawDest() != Pointer || MS->isVolatile() || !Length ||
              Length->getValue().getActiveBits() > 63)
            return false;
          int64_t End = 0;
          uint64_t Size = Length->getZExtValue();
          if (!Size || !addSignedOffset(Offset, int64_t(Size), End) ||
              Offset >= 0 || End > 0)
            return false;
          Accesses.push_back({MS, 0, Offset, End, false, true});
          continue;
        }
        if (auto *CB = dyn_cast<CallBase>(U)) {
          bool Found = false;
          for (unsigned ArgNo = 0; ArgNo < CB->arg_size(); ++ArgNo) {
            if (CB->getArgOperand(ArgNo) != Pointer)
              continue;
            if (auto Size = getScanfDestinationSize(*CB, ArgNo, DL)) {
              // Failed or partial conversion preserves old bytes.  Model the
              // destination as read/write; the must-initialization proof below
              // then permits localization only when this invocation already
              // established every byte that libc might retain.
              if (Found || !AddSizedAccess(CB, ArgNo, *Size, true, true))
                return false;
              Found = true;
              continue;
            }
            auto Summary = getBoundedPointerCallAccess(*CB, ArgNo);
            if (!Summary || Found ||
                !AddSizedAccess(CB, ArgNo, Summary->Size,
                                Summary->Reads || Summary->Writes,
                                Summary->Writes))
              return false;
            Found = true;
          }
          if (Found)
            continue;
        }
        // Unknown calls, pointer escapes and unbounded library accesses remain
        // hard barriers for frame-ABI localization.
        return false;
      }
      return true;
    };
    // A recovered frame region can be reused by multiple calls. Moving it to
    // a fresh alloca is valid only when every read is covered by a dominating
    // write in this invocation; otherwise stale caller/previous-call bytes
    // are observable (p00355 is a real example). Pointer escape and every
    // non-negative incoming slot are also rejected by Walk.
    for (const PrivateFrameRoot &Root : FrameRoots) {
      for (int64_t Offset : Root.Offsets)
        if (!Walk(Root.Pointer, Offset)) {
          ShapeOK = false;
          break;
        }
      if (!ShapeOK)
        break;
    }
    if (!ShapeOK || Accesses.empty())
      continue;
    if (!readsAreDominatedByWrites(Accesses, *F))
      continue;

    int64_t Min = Accesses.front().Begin;
    for (const ProvenFrameAccess &A : Accesses)
      Min = std::min(Min, A.Begin);
    if (Min >= 0 || Min < -(1024 * 1024))
      continue;

    // Everything below mutates the source body before constructing the
    // contracted-signature clone. Keep an exact body snapshot so any failed
    // verifier preflight restores the original function instead of leaving a
    // half-localized ABI in the module.
    ValueToValueMapTy BackupMap;
    Function *Backup = CloneFunction(F, BackupMap);
    Backup->setName(F->getName() + ".frame.rollback");
    auto RollbackBody = [&]() {
      auto TargetArg = F->arg_begin();
      for (Argument &BackupArg : Backup->args()) {
        BackupArg.replaceAllUsesWith(&*TargetArg);
        ++TargetArg;
      }
      Backup->replaceAllUsesWith(F);
      F->deleteBody();
      F->splice(F->end(), Backup);
      Backup->eraseFromParent();
      Backup = nullptr;
    };

    uint64_t FrameSize = uint64_t(-Min);
    ArrayType *StorageTy =
        ArrayType::get(Type::getInt8Ty(M.getContext()), FrameSize);
    IRBuilder<> EntryB(&*F->getEntryBlock().getFirstInsertionPt());
    AllocaInst *Storage =
        EntryB.CreateAlloca(StorageTy, nullptr, "native.local.frame");
    Storage->setAlignment(Align(16));
    Value *Top = EntryB.CreateInBoundsGEP(
        StorageTy, Storage,
        {EntryB.getInt64(0), EntryB.getInt64(FrameSize)},
        "native.local.frame.top");
    auto IsFrameAnchor = [&](Value *V) {
      auto *PTI = dyn_cast<PtrToIntInst>(V);
      return PTI && PTI->getPointerOperand() == Frame &&
             PTI->getType() == IncomingRSP->getType();
    };
    std::function<Value *(Value *, IRBuilder<> &,
                          SmallPtrSetImpl<Value *> &)>
        CancelOneFrameAnchor =
            [&](Value *V, IRBuilder<> &B,
                SmallPtrSetImpl<Value *> &Seen) -> Value * {
      if (!V || !Seen.insert(V).second)
        return nullptr;
      auto Finish = [&](Value *Result) {
        Seen.erase(V);
        return Result;
      };
      if (auto *BO = dyn_cast<BinaryOperator>(V)) {
        if (BO->getOpcode() == Instruction::Sub &&
            IsFrameAnchor(BO->getOperand(1)))
          return Finish(BO->getOperand(0));
        if (BO->getOpcode() == Instruction::Xor &&
            IsFrameAnchor(BO->getOperand(0))) {
          auto *AllOnes = dyn_cast<ConstantInt>(BO->getOperand(1));
          if (AllOnes && AllOnes->isMinusOne())
            return Finish(ConstantInt::getSigned(BO->getType(), -1));
        }
        if (BO->getOpcode() == Instruction::Add ||
            BO->getOpcode() == Instruction::Sub) {
          for (unsigned OperandNo = 0; OperandNo != 2; ++OperandNo) {
            SmallPtrSet<Value *, 32> AffineSeen;
            IncomingEnvironment Environment;
            auto Affine = EvaluateIncoming(BO->getOperand(OperandNo),
                                           Environment, AffineSeen, 0);
            if (!Affine || Affine->AnchorCoefficient != -1)
              continue;
            unsigned OtherNo = 1 - OperandNo;
            AffineSeen.clear();
            auto Other = EvaluateIncoming(BO->getOperand(OtherNo),
                                          Environment, AffineSeen, 0);
            if (!Other || Other->AnchorCoefficient != 0 ||
                (BO->getOpcode() == Instruction::Sub && OperandNo == 1))
              continue;
            Value *Cancelled = CancelOneFrameAnchor(
                BO->getOperand(OperandNo), B, Seen);
            if (!Cancelled)
              return Finish(nullptr);
            Value *Result = OperandNo == 0
                                ? B.CreateBinOp(
                                      static_cast<Instruction::BinaryOps>(
                                          BO->getOpcode()),
                                      Cancelled, BO->getOperand(OtherNo))
                                : B.CreateAdd(BO->getOperand(OtherNo),
                                              Cancelled);
            return Finish(Result);
          }
        }
      }
      if (auto *SI = dyn_cast<SelectInst>(V)) {
        Value *True = CancelOneFrameAnchor(SI->getTrueValue(), B, Seen);
        Value *False = CancelOneFrameAnchor(SI->getFalseValue(), B, Seen);
        if (!True || !False)
          return Finish(nullptr);
        return Finish(B.CreateSelect(SI->getCondition(), True, False,
                                     SI->getName() + ".without.anchor"));
      }
      if (auto *PN = dyn_cast<PHINode>(V)) {
        IRBuilder<> PhiB(&*PN->getParent()->getFirstInsertionPt());
        PHINode *NewPN = PhiB.CreatePHI(PN->getType(),
                                       PN->getNumIncomingValues(),
                                       PN->getName() + ".without.anchor");
        for (unsigned I = 0; I < PN->getNumIncomingValues(); ++I) {
          IRBuilder<> IncomingB(PN->getIncomingBlock(I)->getTerminator());
          Value *Incoming = CancelOneFrameAnchor(
              PN->getIncomingValue(I), IncomingB, Seen);
          if (!Incoming) {
            NewPN->eraseFromParent();
            return Finish(nullptr);
          }
          NewPN->addIncoming(Incoming, PN->getIncomingBlock(I));
        }
        return Finish(NewPN);
      }
      return Finish(nullptr);
    };
    for (const PrivateFrameRoot &Root : FrameRoots) {
      Value *Replacement = Top;
      if (Root.Offsets.size() == 1) {
        int64_t Offset = Root.Offsets.front();
        if (Offset != 0)
          Replacement = EntryB.CreateInBoundsGEP(
              Type::getInt8Ty(M.getContext()), Top, EntryB.getInt64(Offset),
              Root.Pointer->getName() + ".local");
      } else {
        IRBuilder<> RootB(Root.Pointer);
        Value *NativeOffset = ConstantInt::get(IncomingRSP->getType(), 0);
        bool AnchorCancelled = false;
        for (Value *Term : Root.IndexTerms) {
          if (!AnchorCancelled) {
            SmallPtrSet<Value *, 32> AffineSeen;
            IncomingEnvironment Environment;
            auto Affine = EvaluateIncoming(Term, Environment, AffineSeen, 0);
            if (Affine && Affine->AnchorCoefficient == -1) {
              SmallPtrSet<Value *, 32> CancelSeen;
              Value *Cancelled =
                  CancelOneFrameAnchor(Term, RootB, CancelSeen);
              if (Cancelled) {
                Term = Cancelled;
                AnchorCancelled = true;
              }
            }
          }
          NativeOffset = RootB.CreateAdd(
              NativeOffset, Term,
              Root.Pointer->getName() + ".native.offset");
        }
        if (!AnchorCancelled)
          NativeOffset = RootB.CreateAdd(
              NativeOffset, *Anchors.begin(),
              Root.Pointer->getName() + ".logical.address");
        Value *LocalOffset = RootB.CreateSub(
            NativeOffset, IncomingRSP,
            Root.Pointer->getName() + ".local.offset");
        Replacement = RootB.CreateGEP(
            Type::getInt8Ty(M.getContext()), Top, LocalOffset,
            Root.Pointer->getName() + ".local");
      }
      Root.Pointer->replaceAllUsesWith(Replacement);
    }
    for (const PrivateFrameRoot &Root : FrameRoots)
      RecursivelyDeleteTriviallyDeadInstructions(Root.Pointer);
    auto HasOnlyContractibleSelfFrameUses = [&]() {
      for (User *U : Frame->users()) {
        auto *CI = dyn_cast<CallInst>(U);
        if (!CI || CI->getCalledOperand()->stripPointerCasts() != F ||
            RemovedIndex >= CI->arg_size() ||
            CI->getArgOperand(RemovedIndex) != Frame)
          return false;
      }
      return true;
    };
    if (!HasOnlyContractibleSelfFrameUses()) {
      RollbackBody();
      continue;
    }

    SmallVector<Type *, 16> ParamTypes;
    for (Argument &A : F->args())
      if (A.getArgNo() != RemovedIndex)
        ParamTypes.push_back(A.getType());
    FunctionType *NewTy = FunctionType::get(
        F->getReturnType(), ParamTypes, false);
    auto WithoutFrameAttributes =
        [&](AttributeList OldAttrs) -> AttributeList {
      SmallVector<AttributeSet, 16> ParamAttrs;
      for (unsigned I = 0; I < F->arg_size(); ++I)
        if (I != RemovedIndex)
          ParamAttrs.push_back(OldAttrs.getParamAttrs(I));
      return AttributeList::get(M.getContext(), OldAttrs.getFnAttrs(),
                                OldAttrs.getRetAttrs(), ParamAttrs);
    };
    std::string OriginalName = F->getName().str();
    F->setName(OriginalName + ".with_frame");
    Function *NewF = Function::Create(
        NewTy, F->getLinkage(), OriginalName, &M);
    NewF->setCallingConv(F->getCallingConv());
    NewF->setAttributes(WithoutFrameAttributes(F->getAttributes()));
    NewF->setDSOLocal(F->isDSOLocal());
    NewF->setUnnamedAddr(F->getUnnamedAddr());

    ValueToValueMapTy VMap;
    auto NewArg = NewF->arg_begin();
    for (Argument &OldArg : F->args()) {
      if (OldArg.getArgNo() == RemovedIndex) {
        // Direct self calls in the cloned body still temporarily target F and
        // therefore retain its old pointer operand. Give that transient use a
        // well-typed value; all F call sites, including those cloned self
        // edges, are redirected to NewF immediately after preflight.
        VMap[&OldArg] = PoisonValue::get(OldArg.getType());
        continue;
      }
      NewArg->setName(OldArg.getName());
      VMap[&OldArg] = &*NewArg++;
    }
    SmallVector<ReturnInst *, 8> Returns;
    CloneFunctionBodyInto(*NewF, *F, VMap, RF_None, Returns);

    // Signature contraction is a transaction. Optimizer-exposed lifted
    // value graphs can remain valid with the original frame argument yet fail
    // dominance or aggregate typing after that argument is removed. Validate
    // the clone before redirecting any callsite or deleting the source
    // function. A rejected clone leaves the localized memory in the old,
    // valid ABI and never publishes malformed IR.
    raw_null_ostream NullDiagnostics;
    if (verifyFunction(*NewF, &NullDiagnostics)) {
      NewF->eraseFromParent();
      RollbackBody();
      F->setName(OriginalName);
      continue;
    }
    Backup->eraseFromParent();
    Backup = nullptr;

    SmallVector<CallInst *, 16> Calls;
    for (User *U : F->users())
      Calls.push_back(cast<CallInst>(U));
    for (CallInst *OldCall : Calls) {
      SmallVector<Value *, 16> Args;
      for (unsigned I = 0; I < OldCall->arg_size(); ++I)
        if (I != RemovedIndex)
          Args.push_back(OldCall->getArgOperand(I));
      SmallVector<OperandBundleDef, 2> Bundles;
      OldCall->getOperandBundlesAsDefs(Bundles);
      IRBuilder<> B(OldCall);
      CallInst *NewCall = B.CreateCall(NewF, Args, Bundles,
                                       OldCall->getName());
      NewCall->setCallingConv(OldCall->getCallingConv());
      NewCall->setAttributes(
          WithoutFrameAttributes(OldCall->getAttributes()));
      NewCall->setTailCallKind(OldCall->getTailCallKind());
      NewCall->setDebugLoc(OldCall->getDebugLoc());
      OldCall->replaceAllUsesWith(NewCall);
      OldCall->eraseFromParent();
    }
    F->eraseFromParent();
    ++Localized;
    Changed = true;
  }
  return Localized;
}

// Removing the last dynamic call-frame access can leave a loop-carried RSP
// PHI and its constant add/sub recurrence as a closed, dead SCC.  LLVM's
// ordinary recursive dead-instruction helper intentionally cannot delete
// cycles, so that SCC would keep the old backing alive even though none of
// its values is observable.  Delete only the portion of the backing's user
// graph that has neither side effects nor a user outside the graph.  Any
// return, branch predicate, memory operation, call, or other external use
// marks its complete producer slice live and therefore preserves it.
static unsigned eraseClosedDeadBackingUserSCCs(Value &Backing) {
  SmallVector<Instruction *, 32> Worklist;
  SmallPtrSet<Instruction *, 32> Graph;
  for (User *U : Backing.users())
    if (auto *I = dyn_cast<Instruction>(U))
      Worklist.push_back(I);
  while (!Worklist.empty()) {
    Instruction *I = Worklist.pop_back_val();
    if (!Graph.insert(I).second)
      continue;
    for (User *U : I->users())
      if (auto *UserI = dyn_cast<Instruction>(U))
        Worklist.push_back(UserI);
  }
  if (Graph.empty())
    return 0;

  SmallPtrSet<Instruction *, 32> Live;
  SmallVector<Instruction *, 32> LiveWorklist;
  for (Instruction *I : Graph) {
    bool ExternallyObserved = I->mayHaveSideEffects();
    for (User *U : I->users())
      if (auto *UserI = dyn_cast<Instruction>(U)) {
        if (!Graph.contains(UserI))
          ExternallyObserved = true;
      } else {
        ExternallyObserved = true;
      }
    if (ExternallyObserved && Live.insert(I).second)
      LiveWorklist.push_back(I);
  }
  while (!LiveWorklist.empty()) {
    Instruction *I = LiveWorklist.pop_back_val();
    for (Value *Operand : I->operands())
      if (auto *Producer = dyn_cast<Instruction>(Operand);
          Producer && Graph.contains(Producer) && Live.insert(Producer).second)
        LiveWorklist.push_back(Producer);
  }

  SmallVector<Instruction *, 32> Dead;
  for (Instruction *I : Graph)
    if (!Live.contains(I))
      Dead.push_back(I);
  for (Instruction *I : Dead)
    I->dropAllReferences();
  for (Instruction *I : llvm::reverse(Dead))
    I->eraseFromParent();
  return Dead.size();
}

unsigned compactProvenConstantFrameBackings(Module &M, bool &Changed) {
  struct FrameCandidate {
    Value *Backing = nullptr;
    bool ZeroInitialized = false;
    Align Alignment = Align(1);
  };
  SmallVector<FrameCandidate, 16> Candidates;
  for (GlobalVariable &GV : M.globals())
    if (GV.getName().starts_with("frame_storage_backing."))
      Candidates.push_back(
          {&GV, true, GV.getAlign().valueOrOne()});
  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : F.getEntryBlock()) {
      auto *AI = dyn_cast<AllocaInst>(&I);
      auto *AT = AI ? dyn_cast<ArrayType>(AI->getAllocatedType()) : nullptr;
      if (!AI || !AT || !AT->getElementType()->isIntegerTy(8) ||
          AT->getNumElements() < 1024 * 1024)
        continue;
      StringRef Name = AI->getName();
      if (Name.starts_with("frame_storage") ||
          Name.starts_with("native_stack_storage"))
        Candidates.push_back({AI, false, AI->getAlign()});
    }
  }

  unsigned Compacted = 0;
  for (const FrameCandidate &Candidate : Candidates) {
    Value *Backing = Candidate.Backing;
    if (!Backing)
      continue;
    SmallVector<ProvenFrameAccess, 16> Accesses;
    Function *Owner = nullptr;
    uint64_t ObjectSize = 0;
    bool Proven = false;
    if (auto *GV = dyn_cast<GlobalVariable>(Backing))
      Proven = proveConstantFrameBacking(*GV, Accesses, Owner, ObjectSize);
    else if (auto *AI = dyn_cast<AllocaInst>(Backing))
      Proven = proveConstantFrameAlloca(*AI, Accesses, Owner, ObjectSize);
    if (!Proven)
      continue;

    bool IsProcessEntrypoint = Owner->getName() == "main" && Owner->use_empty();
    // A zero-initialized global supplies defined zero bytes before the first
    // write.  Preserve that only for the process entrypoint; otherwise require
    // every read to be dominated by a write.  A stack alloca is already
    // uninitialized, so shrinking its proven constant-access window does not
    // add a new initialization requirement.
    if (Candidate.ZeroInitialized && !IsProcessEntrypoint &&
        !readsAreDominatedByWrites(Accesses, *Owner))
      continue;

    int64_t Min = Accesses.front().Begin;
    int64_t Max = Accesses.front().End;
    Align FrameAlign = Candidate.Alignment;
    std::set<std::pair<Instruction *, unsigned>> SeenAccessOperands;
    bool HasMergedPointerAccess = false;
    for (const ProvenFrameAccess &Access : Accesses) {
      Min = std::min(Min, Access.Begin);
      Max = std::max(Max, Access.End);
      if (!SeenAccessOperands.insert(
              {Access.Inst, Access.PointerOperand}).second)
        HasMergedPointerAccess = true;
      if (auto *LI = dyn_cast<LoadInst>(Access.Inst))
        FrameAlign = std::max(FrameAlign, LI->getAlign());
      else if (auto *SI = dyn_cast<StoreInst>(Access.Inst))
        FrameAlign = std::max(FrameAlign, SI->getAlign());
      else if (auto *MS = dyn_cast<MemSetInst>(Access.Inst))
        FrameAlign = std::max(
            FrameAlign, MS->getDestAlign().value_or(Align(1)));
    }

    // A fixed-offset pointer PHI/select produces several proven alternatives
    // for one memory operand.  Replacing that operand with one static slot
    // would discard the control-dependent choice.  In this mode rebase every
    // direct constant GEP root instead; the existing merge graph and all of
    // its users then remain intact.  Require the complete backing user set to
    // consist of such roots so no virtual out-of-object base is needed.
    SmallVector<std::pair<GetElementPtrInst *, int64_t>, 16> MergeRoots;
    if (HasMergedPointerAccess) {
      bool RootsProven = true;
      for (User *U : Backing->users()) {
        auto *GEP = dyn_cast<GetElementPtrInst>(U);
        SmallPtrSet<Value *, 16> Seen;
        auto Offset =
            GEP ? evaluateFramePointerOffset(GEP, *Backing,
                                             M.getDataLayout(), Seen)
                          : std::nullopt;
        if (!GEP || !Offset) {
          RootsProven = false;
          break;
        }
        MergeRoots.push_back({GEP, *Offset});
        Min = std::min(Min, *Offset);
        Max = std::max(Max, *Offset);
      }
      if (!RootsProven || MergeRoots.empty())
        continue;
    }
    // The proof rejects address observation and retains only bounded memory
    // accesses, so the compact object does not need to preserve the absolute
    // residue of the old guest address.  Stale lifted alignment promises are
    // capped below from the original backing plus byte offset; adding leading
    // padding would only retain unused guest-frame bytes.
    constexpr uint64_t Prefix = 0;
    uint64_t FrameSize = uint64_t(Max - Min);
    if (!FrameSize || FrameSize > 1024 * 1024)
      continue;
    ArrayType *FrameTy = ArrayType::get(Type::getInt8Ty(M.getContext()),
                                        FrameSize);
    IRBuilder<> EntryBuilder(&*Owner->getEntryBlock().getFirstInsertionPt());
    AllocaInst *Frame = EntryBuilder.CreateAlloca(
        FrameTy, nullptr, "native_frame.compact");
    Frame->setAlignment(FrameAlign);
    if (Candidate.ZeroInitialized && IsProcessEntrypoint)
      EntryBuilder.CreateMemSet(Frame, EntryBuilder.getInt8(0), FrameSize,
                                FrameAlign);

    if (HasMergedPointerAccess) {
      for (auto [Root, Offset] : MergeRoots) {
        IRBuilder<> B(Root);
        Value *Local = B.CreateInBoundsGEP(
            FrameTy, Frame,
            {B.getInt64(0),
             B.getInt64(Prefix + uint64_t(Offset - Min))},
            "native.frame.root");
        Root->replaceAllUsesWith(Local);
        Root->eraseFromParent();
      }
    }
    SeenAccessOperands.clear();
    for (const ProvenFrameAccess &Access : Accesses) {
      if (!HasMergedPointerAccess) {
        IRBuilder<> B(Access.Inst);
        Value *Local = B.CreateInBoundsGEP(
            FrameTy, Frame,
            {B.getInt64(0),
             B.getInt64(Prefix + uint64_t(Access.Begin - Min))},
            "native.frame.slot");
        Access.Inst->setOperand(Access.PointerOperand, Local);
      }
      // Lifted IR frequently overstates alignment after byte-address stack
      // recovery (for example align 16 at backing+8).  That is immediate UB
      // and lets O2 choose a different result merely because a global became
      // an alloca.  The backing alignment plus proven absolute byte offset is
      // the strongest alignment actually established by the IR object.
      Align ProvenAlign = commonAlignment(
          Candidate.Alignment, uint64_t(Access.Begin));
      if (!SeenAccessOperands.insert(
              {Access.Inst, Access.PointerOperand}).second)
        ProvenAlign = Align(1);
      if (auto *LI = dyn_cast<LoadInst>(Access.Inst))
        LI->setAlignment(ProvenAlign);
      else if (auto *SI = dyn_cast<StoreInst>(Access.Inst))
        SI->setAlignment(ProvenAlign);
      else if (auto *MS = dyn_cast<MemSetInst>(Access.Inst))
        MS->setDestAlignment(ProvenAlign);
    }
    if (auto *GV = dyn_cast<GlobalVariable>(Backing))
      GV->removeDeadConstantUsers();
    else {
      // Replacing terminal accesses leaves the old constant GEP/bitcast tree
      // dead.  Delete it bottom-up so the original oversized alloca becomes
      // use-empty without relying on a later optimization pipeline.
      bool Deleted = true;
      while (Deleted && !Backing->use_empty()) {
        Deleted = false;
        SmallVector<Instruction *, 16> DeadUsers;
        for (User *U : Backing->users())
          if (auto *I = dyn_cast<Instruction>(U); I && I->use_empty())
            DeadUsers.push_back(I);
        for (Instruction *I : DeadUsers) {
          I->eraseFromParent();
          Deleted = true;
        }
      }
      if (!Backing->use_empty())
        eraseClosedDeadBackingUserSCCs(*Backing);
    }
    if (!Backing->use_empty())
      report_fatal_error("proven frame compaction left an unexpected use");
    if (auto *GV = dyn_cast<GlobalVariable>(Backing))
      GV->eraseFromParent();
    else
      cast<AllocaInst>(Backing)->eraseFromParent();
    ++Compacted;
    Changed = true;
  }
  return Compacted;
}

} // namespace brighten_native_cleanup
