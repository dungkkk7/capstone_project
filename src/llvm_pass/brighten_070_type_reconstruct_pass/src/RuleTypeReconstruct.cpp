#include "BrightenTypeReconstructPass.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PatternMatch.h"

namespace brighten_type_reconstruct {

using namespace llvm;
using namespace llvm::PatternMatch;

namespace {

static Value *asI64Index(IRBuilder<> &B, Value *V) {
  if (!V->getType()->isIntegerTy()) {
    return nullptr;
  }

  Type *I64Ty = B.getInt64Ty();
  if (V->getType() == I64Ty) {
    return V;
  }

  return B.CreateSExtOrTrunc(V, I64Ty, "ptr.idx");
}

static Value *addOffset(IRBuilder<> &B, Value *A, Value *BVal) {
  A = asI64Index(B, A);
  BVal = asI64Index(B, BVal);
  if (!A || !BVal) {
    return nullptr;
  }
  if (auto *CA = dyn_cast<ConstantInt>(A); CA && CA->isZero()) {
    return BVal;
  }
  if (auto *CB = dyn_cast<ConstantInt>(BVal); CB && CB->isZero()) {
    return A;
  }
  return B.CreateAdd(A, BVal, "ptr.off");
}

static Value *subOffset(IRBuilder<> &B, Value *A, Value *BVal) {
  A = asI64Index(B, A);
  BVal = asI64Index(B, BVal);
  if (!A || !BVal) {
    return nullptr;
  }
  if (auto *CB = dyn_cast<ConstantInt>(BVal); CB && CB->isZero()) {
    return A;
  }
  return B.CreateSub(A, BVal, "ptr.off");
}

static bool decomposePointerArith(Value *V, IRBuilder<> &B, Value *&Base,
                                  Value *&Offset) {
  if (auto *PTI = dyn_cast<PtrToIntOperator>(V)) {
    Base = PTI->getPointerOperand();
    Offset = B.getInt64(0);
    return true;
  }

  Value *LHS = nullptr;
  Value *RHS = nullptr;
  if (match(V, m_Add(m_Value(LHS), m_Value(RHS)))) {
    if (decomposePointerArith(LHS, B, Base, Offset)) {
      if (Value *NewOffset = addOffset(B, Offset, RHS)) {
        Offset = NewOffset;
        return true;
      }
    }
    if (decomposePointerArith(RHS, B, Base, Offset)) {
      if (Value *NewOffset = addOffset(B, Offset, LHS)) {
        Offset = NewOffset;
        return true;
      }
    }
  }

  if (match(V, m_Sub(m_Value(LHS), m_Value(RHS)))) {
    if (decomposePointerArith(LHS, B, Base, Offset)) {
      if (Value *NewOffset = subOffset(B, Offset, RHS)) {
        Offset = NewOffset;
        return true;
      }
    }
  }

  if (match(V, m_Or(m_Value(LHS), m_Value(RHS)))) {
    auto *CI = dyn_cast<ConstantInt>(RHS);
    if (!CI) {
      return false;
    }
    if (!decomposePointerArith(LHS, B, Base, Offset)) {
      return false;
    }
    int64_t Val = CI->getSExtValue();
    if (Val < 0 || Val >= 8) {
      return false;
    }
    if (Value *NewOffset = addOffset(B, Offset, B.getInt64(Val))) {
      Offset = NewOffset;
      return true;
    }
  }

  return false;
}

static bool foldTranslateGuestPointer(Function &F,
                                      SmallVectorImpl<Instruction *> &Dead) {
  bool Changed = false;

  for (auto It = inst_begin(F), End = inst_end(F); It != End; ++It) {
    auto *CI = dyn_cast<CallInst>(&*It);
    if (!CI || !CI->getType()->isPointerTy() || CI->arg_size() < 1) {
      continue;
    }

    Function *Callee = CI->getCalledFunction();
    if (!Callee || Callee->getName() != "__translate_guest_pointer") {
      continue;
    }

    IRBuilder<> B(CI);
    Value *Base = nullptr;
    Value *Offset = nullptr;
    if (!decomposePointerArith(CI->getArgOperand(0), B, Base, Offset)) {
      continue;
    }

    Value *Recovered = nullptr;
    if (auto *ConstOffset = dyn_cast<ConstantInt>(Offset);
        ConstOffset && ConstOffset->isZero()) {
      Recovered = Base;
    } else {
      Recovered = B.CreateGEP(B.getInt8Ty(), Base, Offset, "guest.ptr");
    }

    if (Recovered->getType() != CI->getType()) {
      continue;
    }

    CI->replaceAllUsesWith(Recovered);
    Dead.push_back(CI);
    Changed = true;
  }

  return Changed;
}

static bool foldPtrToIntOfIntToPtr(Function &F,
                                   SmallVectorImpl<Instruction *> &Dead) {
  bool Changed = false;

  for (auto It = inst_begin(F), End = inst_end(F); It != End; ++It) {
    auto *PTI = dyn_cast<PtrToIntInst>(&*It);
    if (!PTI) {
      continue;
    }

    auto *ITP = dyn_cast<IntToPtrInst>(PTI->getOperand(0));
    if (!ITP) {
      continue;
    }

    Value *IntVal = ITP->getOperand(0);
    if (IntVal->getType() != PTI->getType()) {
      continue;
    }

    PTI->replaceAllUsesWith(IntVal);
    Dead.push_back(PTI);
    if (ITP->use_empty()) {
      Dead.push_back(ITP);
    }
    Changed = true;
  }

  return Changed;
}

static bool foldIntToPtrOfPtrToInt(Function &F,
                                   SmallVectorImpl<Instruction *> &Dead) {
  bool Changed = false;

  for (auto It = inst_begin(F), End = inst_end(F); It != End; ++It) {
    auto *ITP = dyn_cast<IntToPtrInst>(&*It);
    if (!ITP) {
      continue;
    }

    auto *PTI = dyn_cast<PtrToIntInst>(ITP->getOperand(0));
    if (!PTI) {
      continue;
    }

    Value *OrigPtr = PTI->getPointerOperand();
    if (OrigPtr->getType() != ITP->getType()) {
      continue;
    }

    ITP->replaceAllUsesWith(OrigPtr);
    Dead.push_back(ITP);
    if (PTI->use_empty()) {
      Dead.push_back(PTI);
    }
    Changed = true;
  }

  return Changed;
}

static bool foldPointerArithToGEP(Function &F,
                                  SmallVectorImpl<Instruction *> &Dead) {
  bool Changed = false;

  for (auto It = inst_begin(F), End = inst_end(F); It != End; ++It) {
    auto *ITP = dyn_cast<IntToPtrInst>(&*It);
    if (!ITP || isa<PtrToIntInst>(ITP->getOperand(0))) {
      continue;
    }

    IRBuilder<> B(ITP);
    Value *Base = nullptr;
    Value *Offset = nullptr;
    if (!decomposePointerArith(ITP->getOperand(0), B, Base, Offset)) {
      continue;
    }

    Value *Recovered = nullptr;
    if (auto *ConstOffset = dyn_cast<ConstantInt>(Offset);
        ConstOffset && ConstOffset->isZero()) {
      Recovered = Base;
    } else {
      Recovered = B.CreateGEP(B.getInt8Ty(), Base, Offset, "ptr.recover");
    }

    if (Recovered->getType() != ITP->getType()) {
      continue;
    }

    ITP->replaceAllUsesWith(Recovered);
    Dead.push_back(ITP);
    Changed = true;
  }

  return Changed;
}

static bool isAllocaDerivedPointer(Value *V) {
  V = V->stripPointerCasts();
  while (auto *GEP = dyn_cast<GetElementPtrInst>(V)) {
    V = GEP->getPointerOperand()->stripPointerCasts();
  }
  return isa<AllocaInst>(V);
}

static uint64_t accessSizeBytes(const DataLayout &DL, Instruction *I,
                                Value *Ptr) {
  if (auto *LI = dyn_cast<LoadInst>(I)) {
    if (LI->getPointerOperand() == Ptr) {
      return DL.getTypeStoreSize(LI->getType()).getFixedValue();
    }
  } else if (auto *SI = dyn_cast<StoreInst>(I)) {
    if (SI->getPointerOperand() == Ptr) {
      return DL.getTypeStoreSize(SI->getValueOperand()->getType())
          .getFixedValue();
    }
  }
  return 0;
}

static bool reachesMemoryAccessOfSize(const DataLayout &DL, Value *Ptr,
                                      uint64_t ElemBytes, unsigned Depth,
                                      SmallPtrSetImpl<Value *> &Seen) {
  if (!Seen.insert(Ptr).second) {
    return false;
  }

  for (User *UserVal : Ptr->users()) {
    if (auto *I = dyn_cast<Instruction>(UserVal)) {
      if (accessSizeBytes(DL, I, Ptr) == ElemBytes) {
        return true;
      }
    }

    if (Depth == 0) {
      continue;
    }

    if (auto *GEP = dyn_cast<GetElementPtrInst>(UserVal)) {
      if (!GEP->hasAllConstantIndices()) {
        continue;
      }
      if (reachesMemoryAccessOfSize(DL, GEP, ElemBytes, Depth - 1, Seen)) {
        return true;
      }
      continue;
    }

    auto *Cast = dyn_cast<BitCastInst>(UserVal);
    if (Cast && reachesMemoryAccessOfSize(DL, Cast, ElemBytes, Depth - 1, Seen)) {
      return true;
    }
  }

  return false;
}

static bool isAlreadyLow32(Value *V) {
  if (auto *ZExt = dyn_cast<ZExtInst>(V)) {
    return ZExt->getSrcTy()->isIntegerTy(32);
  }

  Value *LHS = nullptr;
  ConstantInt *Mask = nullptr;
  return match(V, m_And(m_Value(LHS), m_ConstantInt(Mask))) &&
         Mask->getZExtValue() == 0xFFFFFFFFULL;
}

static bool narrowScaledStackIndex(Function &F) {
  const DataLayout &DL = F.getParent()->getDataLayout();
  bool Changed = false;

  for (BasicBlock &BB : F) {
    for (Instruction &I : BB) {
      auto *GEP = dyn_cast<GetElementPtrInst>(&I);
      if (!GEP || GEP->getNumIndices() != 1 ||
          !GEP->getSourceElementType()->isIntegerTy(8) ||
          !isAllocaDerivedPointer(GEP->getPointerOperand())) {
        continue;
      }

      auto *Shift = dyn_cast<BinaryOperator>(GEP->idx_begin()->get());
      if (!Shift || Shift->getOpcode() != Instruction::Shl) {
        continue;
      }

      auto *Amount = dyn_cast<ConstantInt>(Shift->getOperand(1));
      if (!Amount || Amount->getZExtValue() >= 4) {
        continue;
      }

      uint64_t ElemBytes = 1ULL << Amount->getZExtValue();
      if (ElemBytes != 4) {
        continue;
      }

      SmallPtrSet<Value *, 8> Seen;
      if (!reachesMemoryAccessOfSize(DL, GEP, ElemBytes, 3, Seen)) {
        continue;
      }

      Value *Index = Shift->getOperand(0);
      if (!Index->getType()->isIntegerTy(64) || isAlreadyLow32(Index)) {
        continue;
      }

      IRBuilder<> B(Shift);
      Value *Lo = B.CreateTrunc(Index, B.getInt32Ty(), "idx.low32");
      Value *Wide = B.CreateZExt(Lo, B.getInt64Ty(), "idx.zext64");
      Shift->setOperand(0, Wide);
      Changed = true;
    }
  }

  return Changed;
}

struct ByteFieldAccess {
  uint64_t Offset;
  Type *AccessTy;
  Instruction *UserInst;
};

static Type *pointerAccessType(Instruction *I, Value *Ptr) {
  if (auto *LI = dyn_cast<LoadInst>(I)) {
    if (LI->getPointerOperand() == Ptr) {
      return LI->getType();
    }
  } else if (auto *SI = dyn_cast<StoreInst>(I)) {
    if (SI->getPointerOperand() == Ptr) {
      return SI->getValueOperand()->getType();
    }
  }
  return nullptr;
}

static StructType *getImmediateArrayElementStructType(Value *Base) {
  while (auto *BC = dyn_cast<BitCastOperator>(Base)) {
    Base = BC->getOperand(0);
  }

  if (auto *GEP = dyn_cast<GEPOperator>(Base)) {
    if (auto *ArrTy = dyn_cast<ArrayType>(GEP->getResultElementType())) {
      return dyn_cast<StructType>(ArrTy->getElementType());
    }
  }
  if (auto *AI = dyn_cast<AllocaInst>(Base)) {
    if (auto *ArrTy = dyn_cast<ArrayType>(AI->getAllocatedType())) {
      return dyn_cast<StructType>(ArrTy->getElementType());
    }
  }
  if (auto *GV = dyn_cast<GlobalVariable>(Base)) {
    if (auto *ArrTy = dyn_cast<ArrayType>(GV->getValueType())) {
      return dyn_cast<StructType>(ArrTy->getElementType());
    }
  }
  return nullptr;
}

static bool isScaledStructElementOffset(Value *V, uint64_t ElemBytes) {
  if (auto *CI = dyn_cast<ConstantInt>(V)) {
    return CI->isZero();
  }

  Value *Idx = nullptr;
  ConstantInt *Scale = nullptr;
  if (match(V, m_Mul(m_Value(Idx), m_ConstantInt(Scale))) ||
      match(V, m_Mul(m_ConstantInt(Scale), m_Value(Idx)))) {
    return Scale->getValue().getZExtValue() == ElemBytes;
  }

  ConstantInt *Shift = nullptr;
  if (match(V, m_Shl(m_Value(Idx), m_ConstantInt(Shift)))) {
    uint64_t Pow2 = 1ULL << Shift->getZExtValue();
    return Pow2 == ElemBytes;
  }

  return false;
}

static StructType *getKnownStructPointeeTypeImpl(Value *Base, const DataLayout &DL,
                                                 SmallPtrSetImpl<Value *> &Visiting) {
  while (true) {
    if (auto *GEP = dyn_cast<GEPOperator>(Base)) {
      Type *ElemTy = GEP->getResultElementType();
      if (auto *ST = dyn_cast<StructType>(ElemTy)) {
        return ST;
      }
      if (ElemTy->isIntegerTy(8)) {
        if (StructType *InnerST =
                getImmediateArrayElementStructType(GEP->getPointerOperand())) {
          uint64_t ElemBytes =
              DL.getTypeAllocSize(InnerST).getFixedValue();
          if (GEP->getNumIndices() == 1 &&
              isScaledStructElementOffset(GEP->idx_begin()->get(), ElemBytes)) {
            return InnerST;
          }
        }
        Base = GEP->getPointerOperand();
        continue;
      }
      if (!ElemTy->isIntegerTy(8)) {
        return nullptr;
      }
    }
    if (auto *BC = dyn_cast<BitCastOperator>(Base)) {
      Base = BC->getOperand(0);
      continue;
    }
    break;
  }

  Base = Base->stripPointerCasts();

  if (auto *PHI = dyn_cast<PHINode>(Base)) {
    if (!Visiting.insert(PHI).second) {
      return nullptr;
    }

    StructType *Common = nullptr;
    for (Value *Incoming : PHI->incoming_values()) {
      Incoming = Incoming->stripPointerCasts();
      if (isa<UndefValue>(Incoming) || Incoming == PHI) {
        continue;
      }
      if (Visiting.contains(Incoming)) {
        continue;
      }

      StructType *IncomingST =
          getKnownStructPointeeTypeImpl(Incoming, DL, Visiting);
      if (!IncomingST) {
        Visiting.erase(PHI);
        return nullptr;
      }
      if (!Common) {
        Common = IncomingST;
        continue;
      }
      if (Common != IncomingST) {
        Visiting.erase(PHI);
        return nullptr;
      }
    }

    Visiting.erase(PHI);
    return Common;
  }

  if (auto *Sel = dyn_cast<SelectInst>(Base)) {
    if (!Visiting.insert(Sel).second) {
      return nullptr;
    }

    StructType *Common = nullptr;
    for (Value *Candidate : {Sel->getTrueValue(), Sel->getFalseValue()}) {
      Candidate = Candidate->stripPointerCasts();
      if (isa<UndefValue>(Candidate) || Visiting.contains(Candidate)) {
        continue;
      }

      StructType *CandidateST =
          getKnownStructPointeeTypeImpl(Candidate, DL, Visiting);
      if (!CandidateST) {
        Visiting.erase(Sel);
        return nullptr;
      }
      if (!Common) {
        Common = CandidateST;
        continue;
      }
      if (Common != CandidateST) {
        Visiting.erase(Sel);
        return nullptr;
      }
    }

    Visiting.erase(Sel);
    return Common;
  }

  if (auto *AI = dyn_cast<AllocaInst>(Base)) {
    return dyn_cast<StructType>(AI->getAllocatedType());
  }
  if (auto *GV = dyn_cast<GlobalVariable>(Base)) {
    return dyn_cast<StructType>(GV->getValueType());
  }
  return nullptr;
}

static StructType *getKnownStructPointeeType(Value *Base, const DataLayout &DL) {
  SmallPtrSet<Value *, 8> Visiting;
  return getKnownStructPointeeTypeImpl(Base, DL, Visiting);
}

static void collectByteFieldAccesses(
    Value *Base, SmallVectorImpl<GetElementPtrInst *> &ByteGEPs,
    SmallVectorImpl<ByteFieldAccess> &Accesses) {
  for (User *U : Base->users()) {
    if (auto *I = dyn_cast<Instruction>(U)) {
      if (Type *AccessTy = pointerAccessType(I, Base)) {
        Accesses.push_back({0, AccessTy, I});
        continue;
      }
    }

    auto *GEP = dyn_cast<GetElementPtrInst>(U);
    if (!GEP || GEP->getNumIndices() != 1 ||
        !GEP->getSourceElementType()->isIntegerTy(8)) {
      continue;
    }

    auto *Offset = dyn_cast<ConstantInt>(GEP->idx_begin()->get());
    if (!Offset || Offset->isNegative()) {
      continue;
    }

    ByteGEPs.push_back(GEP);
    for (User *GU : GEP->users()) {
      auto *GI = dyn_cast<Instruction>(GU);
      if (!GI) {
        continue;
      }
      if (Type *AccessTy = pointerAccessType(GI, GEP)) {
        Accesses.push_back({Offset->getZExtValue(), AccessTy, GI});
      }
    }
  }
}

static bool matchStructFieldAccesses(const DataLayout &DL, StructType *ST,
                                     ArrayRef<ByteFieldAccess> Accesses,
                                     DenseMap<uint64_t, unsigned> &FieldMap) {
  if (!ST || ST->isOpaque() || !ST->isSized()) {
    return false;
  }

  const StructLayout *Layout = DL.getStructLayout(ST);
  for (const ByteFieldAccess &Access : Accesses) {
    bool Matched = false;
    for (unsigned I = 0, E = ST->getNumElements(); I != E; ++I) {
      if (Layout->getElementOffset(I) != Access.Offset) {
        continue;
      }
      if (ST->getElementType(I) != Access.AccessTy) {
        continue;
      }
      FieldMap[Access.Offset] = I;
      Matched = true;
      break;
    }
    if (!Matched) {
      return false;
    }
  }

  return true;
}

static StructType *inferStructTypeFromAccesses(Function &F,
                                               ArrayRef<ByteFieldAccess> Accesses,
                                               DenseMap<uint64_t, unsigned> &FieldMap) {
  if (Accesses.empty()) {
    return nullptr;
  }

  DenseMap<uint64_t, bool> UniqueOffsets;
  for (const ByteFieldAccess &Access : Accesses) {
    UniqueOffsets[Access.Offset] = true;
  }
  if (UniqueOffsets.size() < 2) {
    return nullptr;
  }

  StructType *Matched = nullptr;
  DenseMap<uint64_t, unsigned> CandidateMap;
  for (StructType *ST : F.getParent()->getIdentifiedStructTypes()) {
    CandidateMap.clear();
    if (!matchStructFieldAccesses(F.getParent()->getDataLayout(), ST, Accesses,
                                  CandidateMap)) {
      continue;
    }
    if (Matched && Matched != ST) {
      return nullptr;
    }
    Matched = ST;
    FieldMap = CandidateMap;
  }

  return Matched;
}

static bool rewriteByteOffsetStructFields(Function &F,
                                          SmallVectorImpl<Instruction *> &Dead) {
  const DataLayout &DL = F.getParent()->getDataLayout();
  bool Changed = false;

  DenseMap<Value *, SmallVector<GetElementPtrInst *, 8>> BaseToGEPs;
  for (Instruction &I : instructions(F)) {
    auto *GEP = dyn_cast<GetElementPtrInst>(&I);
    if (!GEP || GEP->getNumIndices() != 1 ||
        !GEP->getSourceElementType()->isIntegerTy(8)) {
      continue;
    }

    auto *Offset = dyn_cast<ConstantInt>(GEP->idx_begin()->get());
    if (!Offset || Offset->isNegative()) {
      continue;
    }

    BaseToGEPs[GEP->getPointerOperand()].push_back(GEP);
  }

  for (auto &Entry : BaseToGEPs) {
    Value *Base = Entry.first;
    SmallVector<GetElementPtrInst *, 8> ByteGEPs;
    SmallVector<ByteFieldAccess, 8> Accesses;
    collectByteFieldAccesses(Base, ByteGEPs, Accesses);
    if (ByteGEPs.empty()) {
      continue;
    }

    DenseMap<uint64_t, unsigned> FieldMap;
    StructType *ST = getKnownStructPointeeType(Base, DL);
    if (ST) {
      SmallVector<ByteFieldAccess, 8> CompatibleAccesses;
      for (const ByteFieldAccess &Access : Accesses) {
        DenseMap<uint64_t, unsigned> Tmp;
        if (matchStructFieldAccesses(DL, ST, {Access}, Tmp)) {
          CompatibleAccesses.push_back(Access);
          FieldMap[Access.Offset] = Tmp[Access.Offset];
        }
      }
      Accesses = std::move(CompatibleAccesses);
    } else {
      ST = inferStructTypeFromAccesses(F, Accesses, FieldMap);
      if (!ST) {
        continue;
      }
    }

    const StructLayout *Layout = DL.getStructLayout(ST);
    for (unsigned I = 0, E = ST->getNumElements(); I != E; ++I) {
      FieldMap.try_emplace(Layout->getElementOffset(I), I);
    }

    for (GetElementPtrInst *GEP : ByteGEPs) {
      auto *Offset = cast<ConstantInt>(GEP->idx_begin()->get());
      auto It = FieldMap.find(Offset->getZExtValue());
      if (It == FieldMap.end()) {
        continue;
      }

      IRBuilder<> B(GEP);
      Value *NewGEP = B.CreateStructGEP(ST, Base, It->second, GEP->getName());
      GEP->replaceAllUsesWith(NewGEP);
      Dead.push_back(GEP);
      Changed = true;
    }

    for (const ByteFieldAccess &Access : Accesses) {
      auto It = FieldMap.find(Access.Offset);
      if (It == FieldMap.end()) {
        continue;
      }
      if (Access.Offset != 0) {
        continue;
      }
      if (ST->getElementType(It->second) != Access.AccessTy) {
        continue;
      }

      IRBuilder<> B(Access.UserInst);
      Value *FieldPtr = B.CreateStructGEP(ST, Base, It->second, "field0");
      if (auto *LI = dyn_cast<LoadInst>(Access.UserInst)) {
        LI->setOperand(LI->getPointerOperandIndex(), FieldPtr);
      } else if (auto *SI = dyn_cast<StoreInst>(Access.UserInst)) {
        SI->setOperand(SI->getPointerOperandIndex(), FieldPtr);
      }
      Changed = true;
    }
  }

  return Changed;
}

static bool rewriteDirectStructFieldZeroAccesses(Function &F) {
  bool Changed = false;

  for (Instruction &I : instructions(F)) {
    Type *AccessTy = nullptr;
    Value *Ptr = nullptr;
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      AccessTy = LI->getType();
      Ptr = LI->getPointerOperand();
    } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
      AccessTy = SI->getValueOperand()->getType();
      Ptr = SI->getPointerOperand();
    } else {
      continue;
    }

    StructType *ST = getKnownStructPointeeType(Ptr, F.getParent()->getDataLayout());
    if (!ST || ST->isOpaque() || ST->getNumElements() == 0) {
      continue;
    }
    if (ST->getElementType(0) != AccessTy) {
      continue;
    }

    auto *GEP = dyn_cast<GetElementPtrInst>(Ptr);
    if (GEP && isa<StructType>(GEP->getSourceElementType()) &&
        GEP->getNumIndices() >= 2) {
      continue;
    }

    IRBuilder<> B(&I);
    Value *Field0 = B.CreateStructGEP(ST, Ptr, 0, "field0");
    if (auto *LI = dyn_cast<LoadInst>(&I)) {
      LI->setOperand(LI->getPointerOperandIndex(), Field0);
    } else {
      cast<StoreInst>(&I)->setOperand(cast<StoreInst>(&I)->getPointerOperandIndex(),
                                      Field0);
    }
    Changed = true;
  }

  return Changed;
}

static void eraseDeadInstructions(SmallVectorImpl<Instruction *> &Dead) {
  for (auto It = Dead.rbegin(); It != Dead.rend(); ++It) {
    Instruction *I = *It;
    if (I->use_empty()) {
      I->eraseFromParent();
    }
  }
  Dead.clear();
}

static bool reconstructFunctionTypes(Function &F) {
  bool Changed = false;
  SmallVector<Instruction *, 16> Dead;

  for (unsigned Iter = 0; Iter < 8; ++Iter) {
    bool Progress = false;
    Progress |= foldTranslateGuestPointer(F, Dead);
    Progress |= foldPtrToIntOfIntToPtr(F, Dead);
    Progress |= foldIntToPtrOfPtrToInt(F, Dead);
    Progress |= foldPointerArithToGEP(F, Dead);
    Progress |= rewriteByteOffsetStructFields(F, Dead);
    Progress |= rewriteDirectStructFieldZeroAccesses(F);
    Progress |= narrowScaledStackIndex(F);
    eraseDeadInstructions(Dead);

    if (!Progress) {
      break;
    }
    Changed = true;
  }

  return Changed;
}

} // namespace

bool BrightenTypeReconstructPass::ReconstructTypes(Module &M) {
  bool Changed = false;
  for (Function &F : M) {
    if (F.isDeclaration()) {
      continue;
    }
    Changed |= reconstructFunctionTypes(F);
  }
  return Changed;
}

} // namespace brighten_type_reconstruct
