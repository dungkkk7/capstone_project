#include "BrightenGlobalDataRecoveryPass.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"

#include <algorithm>
#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <vector>

using namespace llvm;

namespace brighten_global {
namespace {

struct Segment {
  GlobalVariable *GV = nullptr;
  uint64_t GuestBase = 0;
  uint64_t Size = 0;
  SmallVector<uint8_t, 64> Bytes;
  bool HasExactBytes = false;
};

struct PointerRef {
  Segment *Seg = nullptr;
  uint64_t Offset = 0;
};

struct AccessRange {
  Segment *Seg = nullptr;
  uint64_t Offset = 0;
  uint64_t Bytes = 0;
  Type *Ty = nullptr;
  SmallVector<Instruction *, 8> MemoryUsers;
};

struct StringUse {
  Segment *Seg = nullptr;
  uint64_t Offset = 0;
  CallBase *Call = nullptr;
  unsigned ArgNo = 0;
};

static std::optional<uint64_t> parseSegmentBase(StringRef Name) {
  if (!Name.starts_with("seg_"))
    return std::nullopt;
  StringRef Tail = Name.drop_front(4);
  size_t End = Tail.find("__");
  if (End == StringRef::npos)
    End = Tail.find('_');
  StringRef Hex = End == StringRef::npos ? Tail : Tail.take_front(End);
  if (Hex.empty())
    return std::nullopt;
  uint64_t V = 0;
  if (Hex.getAsInteger(16, V))
    return std::nullopt;
  return V;
}

static bool extractBytes(Constant *C, uint64_t Size,
                         SmallVectorImpl<uint8_t> &Out) {
  Out.clear();
  if (isa<ConstantAggregateZero>(C)) {
    Out.assign(Size, 0);
    return true;
  }
  if (auto *CDS = dyn_cast<ConstantDataSequential>(C)) {
    if (!CDS->getElementType()->isIntegerTy(8) ||
        CDS->getNumElements() != Size)
      return false;
    for (unsigned I = 0; I < CDS->getNumElements(); ++I)
      Out.push_back(static_cast<uint8_t>(CDS->getElementAsInteger(I)));
    return true;
  }
  if (auto *CA = dyn_cast<ConstantArray>(C)) {
    if (!CA->getType()->getElementType()->isIntegerTy(8) ||
        CA->getNumOperands() != Size)
      return false;
    for (Value *V : CA->operand_values()) {
      auto *CI = dyn_cast<ConstantInt>(V);
      if (!CI || CI->getBitWidth() != 8)
        return false;
      Out.push_back(static_cast<uint8_t>(CI->getZExtValue()));
    }
    return true;
  }
  return false;
}

static SmallVector<Segment, 16> discoverSegments(Module &M) {
  SmallVector<Segment, 16> Segs;
  const DataLayout &DL = M.getDataLayout();
  for (GlobalVariable &GV : M.globals()) {
    auto Base = parseSegmentBase(GV.getName());
    if (!Base || !GV.getValueType()->isSized())
      continue;
    TypeSize TS = DL.getTypeAllocSize(GV.getValueType());
    if (TS.isScalable() || TS.getFixedValue() == 0)
      continue;
    Segment S;
    S.GV = &GV;
    S.GuestBase = *Base;
    S.Size = TS.getFixedValue();
    if (GV.hasInitializer())
      S.HasExactBytes = extractBytes(GV.getInitializer(), S.Size, S.Bytes);
    Segs.push_back(std::move(S));
  }
  llvm::sort(Segs, [](const Segment &A, const Segment &B) {
    return A.GuestBase < B.GuestBase;
  });
  return Segs;
}

static Segment *segmentForGuestAddress(MutableArrayRef<Segment> Segs,
                                       uint64_t Address) {
  for (Segment &S : Segs)
    if (Address >= S.GuestBase && Address - S.GuestBase < S.Size)
      return &S;
  return nullptr;
}

static Segment *segmentForGV(MutableArrayRef<Segment> Segs, GlobalVariable *GV) {
  for (Segment &S : Segs)
    if (S.GV == GV)
      return &S;
  return nullptr;
}

static std::optional<PointerRef>
resolvePointer(Value *V, MutableArrayRef<Segment> Segs, const DataLayout &DL,
               SmallPtrSetImpl<Value *> &Seen, unsigned Depth = 0) {
  if (!V || Depth > 24)
    return std::nullopt;
  V = V->stripPointerCasts();
  if (!Seen.insert(V).second)
    return std::nullopt;
  auto Done = [&](std::optional<PointerRef> R) {
    Seen.erase(V);
    return R;
  };

  if (auto *GV = dyn_cast<GlobalVariable>(V))
    if (Segment *S = segmentForGV(Segs, GV))
      return Done(PointerRef{S, 0});

  if (auto *GEP = dyn_cast<GEPOperator>(V)) {
    APInt Delta(DL.getPointerSizeInBits(GEP->getPointerAddressSpace()), 0, true);
    if (!GEP->accumulateConstantOffset(DL, Delta) || Delta.isNegative())
      return Done(std::nullopt);
    auto Base = resolvePointer(GEP->getPointerOperand(), Segs, DL, Seen, Depth + 1);
    if (!Base || Delta.getZExtValue() > UINT64_MAX - Base->Offset)
      return Done(std::nullopt);
    uint64_t O = Base->Offset + Delta.getZExtValue();
    if (O >= Base->Seg->Size)
      return Done(std::nullopt);
    Base->Offset = O;
    return Done(Base);
  }

  if (auto *ITP = dyn_cast<IntToPtrOperator>(V)) {
    auto *CI = dyn_cast<ConstantInt>(ITP->getOperand(0));
    if (!CI || CI->getBitWidth() > 64)
      return Done(std::nullopt);
    uint64_t A = CI->getZExtValue();
    if (Segment *S = segmentForGuestAddress(Segs, A))
      return Done(PointerRef{S, A - S->GuestBase});
  }

  if (auto *CB = dyn_cast<CallBase>(V)) {
    Function *Callee = CB->getCalledFunction();
    if (Callee && Callee->getName().starts_with("__translate_guest_pointer") &&
        CB->arg_size() >= 1) {
      auto *CI = dyn_cast<ConstantInt>(CB->getArgOperand(0));
      if (!CI || CI->getBitWidth() > 64)
        return Done(std::nullopt);
      uint64_t A = CI->getZExtValue();
      if (Segment *S = segmentForGuestAddress(Segs, A))
        return Done(PointerRef{S, A - S->GuestBase});
    }
  }

  if (auto *PN = dyn_cast<PHINode>(V)) {
    std::optional<PointerRef> Common;
    for (Value *I : PN->incoming_values()) {
      auto R = resolvePointer(I, Segs, DL, Seen, Depth + 1);
      if (!R)
        return Done(std::nullopt);
      if (!Common)
        Common = R;
      else if (Common->Seg != R->Seg || Common->Offset != R->Offset)
        return Done(std::nullopt);
    }
    return Done(Common);
  }
  if (auto *SI = dyn_cast<SelectInst>(V)) {
    auto A = resolvePointer(SI->getTrueValue(), Segs, DL, Seen, Depth + 1);
    auto B = resolvePointer(SI->getFalseValue(), Segs, DL, Seen, Depth + 1);
    if (A && B && A->Seg == B->Seg && A->Offset == B->Offset)
      return Done(A);
  }
  return Done(std::nullopt);
}

static std::optional<unsigned> immutableStringArg(const CallBase &CB) {
  Function *F = CB.getCalledFunction();
  if (!F)
    return std::nullopt;
  StringRef N = F->getName();
  if (N == "puts" || N == "printf" || N == "scanf" || N == "strlen")
    return 0;
  if (N == "fprintf" || N == "fscanf" || N == "sprintf" || N == "sscanf")
    return 1;
  if (N == "snprintf")
    return 2;
  return std::nullopt;
}

static uint64_t memoryBytes(Instruction &I, const DataLayout &DL) {
  Type *Ty = nullptr;
  if (auto *L = dyn_cast<LoadInst>(&I))
    Ty = L->getType();
  else if (auto *S = dyn_cast<StoreInst>(&I))
    Ty = S->getValueOperand()->getType();
  if (!Ty || !Ty->isSized())
    return 0;
  TypeSize TS = DL.getTypeStoreSize(Ty);
  return TS.isScalable() ? 0 : TS.getFixedValue();
}

static bool analyze(Module &M, MutableArrayRef<Segment> Segs,
                    SmallVectorImpl<AccessRange> &Ranges,
                    SmallVectorImpl<StringUse> &Strings,
                    DenseSet<GlobalVariable *> &Unsafe) {
  const DataLayout &DL = M.getDataLayout();
  std::map<std::pair<GlobalVariable *, uint64_t>, unsigned> RangeIndex;

  for (Function &F : M) {
    if (F.isDeclaration())
      continue;
    for (Instruction &I : instructions(F)) {
      if (auto *L = dyn_cast<LoadInst>(&I)) {
        if (L->isVolatile() || L->isAtomic())
          continue;
        SmallPtrSet<Value *, 16> Seen;
        auto P = resolvePointer(L->getPointerOperand(), Segs, DL, Seen);
        if (!P)
          continue;
        uint64_t N = memoryBytes(I, DL);
        if (!N || P->Offset > P->Seg->Size || N > P->Seg->Size - P->Offset) {
          Unsafe.insert(P->Seg->GV);
          continue;
        }
        auto Key = std::make_pair(P->Seg->GV, P->Offset);
        auto [It, Inserted] = RangeIndex.emplace(Key, Ranges.size());
        if (Inserted)
          Ranges.push_back({P->Seg, P->Offset, N, L->getType(), {}});
        AccessRange &R = Ranges[It->second];
        if (R.Bytes != N || R.Ty != L->getType())
          Unsafe.insert(P->Seg->GV);
        R.MemoryUsers.push_back(L);
        continue;
      }
      if (auto *S = dyn_cast<StoreInst>(&I)) {
        if (S->isVolatile() || S->isAtomic())
          continue;
        SmallPtrSet<Value *, 16> Seen;
        auto P = resolvePointer(S->getPointerOperand(), Segs, DL, Seen);
        if (!P)
          continue;
        uint64_t N = memoryBytes(I, DL);
        if (!N || P->Offset > P->Seg->Size || N > P->Seg->Size - P->Offset) {
          Unsafe.insert(P->Seg->GV);
          continue;
        }
        auto Key = std::make_pair(P->Seg->GV, P->Offset);
        auto [It, Inserted] = RangeIndex.emplace(Key, Ranges.size());
        if (Inserted)
          Ranges.push_back({P->Seg, P->Offset, N,
                            S->getValueOperand()->getType(), {}});
        AccessRange &R = Ranges[It->second];
        if (R.Bytes != N || R.Ty != S->getValueOperand()->getType())
          Unsafe.insert(P->Seg->GV);
        R.MemoryUsers.push_back(S);
        continue;
      }
      if (auto *CB = dyn_cast<CallBase>(&I)) {
        auto Arg = immutableStringArg(*CB);
        if (!Arg || *Arg >= CB->arg_size())
          continue;
        SmallPtrSet<Value *, 16> Seen;
        auto P = resolvePointer(CB->getArgOperand(*Arg), Segs, DL, Seen);
        if (P)
          Strings.push_back({P->Seg, P->Offset, CB, *Arg});
      }
    }
  }

  // Overlapping but non-identical typed objects would create divergent LLVM
  // storage for the same guest bytes. Reject the whole segment instead.
  for (unsigned I = 0; I < Ranges.size(); ++I)
    for (unsigned J = I + 1; J < Ranges.size(); ++J) {
      AccessRange &A = Ranges[I], &B = Ranges[J];
      if (A.Seg != B.Seg)
        continue;
      uint64_t AE = A.Offset + A.Bytes, BE = B.Offset + B.Bytes;
      if (A.Offset < BE && B.Offset < AE &&
          (A.Offset != B.Offset || A.Bytes != B.Bytes))
        Unsafe.insert(A.Seg->GV);
    }
  return true;
}

static Constant *integerInitializer(const AccessRange &R) {
  if (!R.Seg->HasExactBytes || !R.Ty->isIntegerTy() || R.Bytes > 8 ||
      R.Offset > R.Seg->Bytes.size() ||
      R.Bytes > R.Seg->Bytes.size() - R.Offset)
    return nullptr;
  uint64_t V = 0;
  for (uint64_t I = 0; I < R.Bytes; ++I)
    V |= uint64_t(R.Seg->Bytes[R.Offset + I]) << (I * 8);
  return ConstantInt::get(cast<IntegerType>(R.Ty), V);
}

static bool materializeRanges(Module &M, MutableArrayRef<AccessRange> Ranges,
                              const DenseSet<GlobalVariable *> &Unsafe) {
  bool Changed = false;
  unsigned ID = 0;
  for (AccessRange &R : Ranges) {
    if (Unsafe.contains(R.Seg->GV) || R.MemoryUsers.empty())
      continue;
    Constant *Init = integerInitializer(R);
    if (!Init)
      continue;
    auto *G = new GlobalVariable(
        M, R.Ty, false, GlobalValue::InternalLinkage, Init,
        ("g_recovered_" + Twine(ID++)).str());
    G->setAlignment(Align(std::max<uint64_t>(1, std::min<uint64_t>(R.Bytes, 8))));
    for (Instruction *I : R.MemoryUsers) {
      if (auto *L = dyn_cast<LoadInst>(I))
        L->setOperand(0, G);
      else
        cast<StoreInst>(I)->setOperand(1, G);
    }
    Changed = true;
  }
  return Changed;
}

static bool materializeStrings(Module &M, MutableArrayRef<StringUse> Uses,
                               const DenseSet<GlobalVariable *> &Unsafe) {
  bool Changed = false;
  std::map<std::pair<GlobalVariable *, uint64_t>, GlobalVariable *> Cache;
  unsigned ID = 0;
  for (StringUse &U : Uses) {
    if (Unsafe.contains(U.Seg->GV) || !U.Seg->HasExactBytes ||
        U.Offset >= U.Seg->Bytes.size())
      continue;
    uint64_t End = U.Offset;
    while (End < U.Seg->Bytes.size() && U.Seg->Bytes[End] != 0)
      ++End;
    if (End >= U.Seg->Bytes.size())
      continue;
    ++End; // include terminator
    auto Key = std::make_pair(U.Seg->GV, U.Offset);
    GlobalVariable *G = Cache[Key];
    if (!G) {
      ArrayRef<uint8_t> Raw(U.Seg->Bytes.data() + U.Offset, End - U.Offset);
      Constant *Init = ConstantDataArray::get(M.getContext(), Raw);
      G = new GlobalVariable(M, Init->getType(), true,
                             GlobalValue::PrivateLinkage, Init,
                             (".str.recovered." + Twine(ID++)).str());
      G->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);
      G->setAlignment(Align(1));
      Cache[Key] = G;
    }
    U.Call->setArgOperand(U.ArgNo, G);
    Changed = true;
  }
  return Changed;
}

static bool deleteDeadSegmentCarriers(Module &M, MutableArrayRef<Segment> Segs) {
  bool Changed = false;
  bool Again = true;
  while (Again) {
    Again = false;
    for (Function &F : M) {
      if (F.isDeclaration())
        continue;
      SmallVector<Instruction *, 32> Dead;
      for (Instruction &I : instructions(F))
        if (I.use_empty() && isInstructionTriviallyDead(&I))
          Dead.push_back(&I);
      for (Instruction *I : Dead)
        if (I->getParent() && isInstructionTriviallyDead(I)) {
          RecursivelyDeleteTriviallyDeadInstructions(I);
          Again = Changed = true;
        }
    }
  }
  SmallVector<GlobalVariable *, 16> DeadGVs;
  for (Segment &S : Segs)
    if (S.GV->use_empty() && S.GV->hasLocalLinkage())
      DeadGVs.push_back(S.GV);
  for (GlobalVariable *G : DeadGVs) {
    G->eraseFromParent();
    Changed = true;
  }
  return Changed;
}

static void verifyOrDie(Module &M) {
  std::string E;
  raw_string_ostream OS(E);
  if (verifyModule(M, &OS))
    report_fatal_error("070 v2 produced invalid IR:\n" + OS.str());
}

} // namespace

PreservedAnalyses BrightenGlobalDataRecoveryPass::run(
    Module &M, ModuleAnalysisManager &) {
  SmallVector<Segment, 16> Segs = discoverSegments(M);
  if (Segs.empty())
    return PreservedAnalyses::all();

  SmallVector<AccessRange, 32> Ranges;
  SmallVector<StringUse, 32> Strings;
  DenseSet<GlobalVariable *> Unsafe;
  analyze(M, Segs, Ranges, Strings, Unsafe);

  bool Changed = false;
  Changed |= materializeRanges(M, Ranges, Unsafe);
  Changed |= materializeStrings(M, Strings, Unsafe);
  Changed |= deleteDeadSegmentCarriers(M, Segs);
  verifyOrDie(M);

  errs() << "070 v2: segments=" << Segs.size()
         << " typed_ranges=" << Ranges.size()
         << " strings=" << Strings.size()
         << " unsafe_segments=" << Unsafe.size() << "\n";
  return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
}

} // namespace brighten_global
