#include "Helpers.h"

#include <algorithm>
#include <cctype>
#include <limits>
#include <vector>

#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Operator.h"

namespace brighten_runtime {

using namespace llvm;

namespace {
static std::optional<uint64_t> ProvenGuestStart(Module &M, GlobalVariable &GV,
                                                const DataLayout &DL) {
  std::optional<uint64_t> Found;
  bool SawAlias = false;
  for (GlobalAlias &A : M.aliases()) {
    auto AliasAddr = ResolveGuestAddress(&A);
    if (!AliasAddr) continue;
    const Value *V = A.getAliasee();
    APInt Offset(64, 0);
    while (auto *CE = dyn_cast<ConstantExpr>(V)) {
      if (CE->isCast()) { V = CE->getOperand(0); continue; }
      auto *GEP = dyn_cast<GEPOperator>(CE);
      if (!GEP || !GEP->accumulateConstantOffset(DL, Offset) || Offset.isNegative()) break;
      V = GEP->getPointerOperand();
    }
    if (V != &GV) continue;
    SawAlias = true;
    uint64_t Off = Offset.getZExtValue();
    if (AliasAddr < Off) return std::nullopt;
    uint64_t Start = AliasAddr - Off;
    if (Found && *Found != Start) return std::nullopt;
    Found = Start;
  }
  if (SawAlias) return Found;
  if (auto *ST = dyn_cast<StructType>(GV.getValueType()))
    if (ST->getNumElements() && isa<ArrayType>(ST->getElementType(0)))
      return std::nullopt;
  uint64_t Named = ResolveGuestAddress(&GV);
  return Named ? std::optional<uint64_t>(Named) : std::nullopt;
}
} // namespace

bool IsRemillDecl(const Function &F) {
  return F.isDeclaration() && F.getName().starts_with("__remill_");
}

bool HasPrefixAny(StringRef Name, ArrayRef<StringRef> Prefixes) {
  for (StringRef Prefix : Prefixes) {
    if (Name.starts_with(Prefix)) {
      return true;
    }
  }
  return false;
}

std::optional<uint64_t> ParseHexAtStart(StringRef S) {
  if (S.empty()) {
    return std::nullopt;
  }
  size_t End = 0;
  while (End < S.size() && std::isxdigit(static_cast<unsigned char>(S[End]))) {
    ++End;
  }
  if (!End) {
    return std::nullopt;
  }
  uint64_t Val = 0;
  if (S.take_front(End).getAsInteger(16, Val)) {
    return std::nullopt;
  }
  return Val;
}

std::optional<uint64_t> ParseAddressName(StringRef Name) {
  if (Name.starts_with("sub_")) {
    return ParseHexAtStart(Name.drop_front(4));
  }
  if (Name.starts_with("callback_sub_")) {
    return ParseHexAtStart(Name.drop_front(13));
  }
  if (Name.starts_with("data_")) {
    return ParseHexAtStart(Name.drop_front(5));
  }
  if (Name.starts_with("seg_")) {
    return ParseHexAtStart(Name.drop_front(4));
  }
  if (Name.starts_with("ext_")) {
    return ParseHexAtStart(Name.drop_front(4));
  }
  if (!Name.empty() && std::isxdigit(static_cast<unsigned char>(Name.front()))) {
    bool AllHex = true;
    for (char C : Name) {
      if (!std::isxdigit(static_cast<unsigned char>(C))) {
        AllHex = false;
        break;
      }
    }
    if (AllHex) {
      return ParseHexAtStart(Name);
    }
  }
  return std::nullopt;
}

uint64_t ResolveGuestAddress(GlobalValue *GV) {
  if (!GV) {
    return 0;
  }
  auto Addr = ParseAddressName(GV->getName());
  return Addr.value_or(0);
}

bool HasMemoryThreadingSignature(const Function &F) {
  FunctionType *FTy = F.getFunctionType();
  if (!FTy->getReturnType()->isPointerTy() || FTy->getNumParams() != 3) {
    return false;
  }
  return FTy->getParamType(0)->isPointerTy() &&
         FTy->getParamType(1)->isIntegerTy() &&
         FTy->getParamType(2)->isPointerTy();
}

Value *FindLikelyMemoryArg(Function &F) {
  Value *LastPtr = nullptr;
  for (Argument &Arg : F.args()) {
    if (Arg.getType()->isPointerTy()) {
      LastPtr = &Arg;
    }
  }
  return LastPtr;
}

Constant *ZeroValue(Type *Ty) {
  if (Ty->isVoidTy()) {
    return nullptr;
  }
  if (Ty->isPointerTy()) {
    return ConstantPointerNull::get(cast<PointerType>(Ty));
  }
  return Constant::getNullValue(Ty);
}

Value *CastAddressToI64(IRBuilder<> &B, Value *Addr) {
  if (Addr->getType()->isIntegerTy(64)) {
    return Addr;
  }
  if (Addr->getType()->isIntegerTy()) {
    return B.CreateZExtOrTrunc(Addr, B.getInt64Ty());
  }
  if (Addr->getType()->isPointerTy()) {
    return B.CreatePtrToInt(Addr, B.getInt64Ty());
  }
  return B.getInt64(0);
}

Function *GetOrCreateTranslateGuestPointer(Module &M) {
  if (Function *Existing = M.getFunction("__translate_guest_pointer")) {
    if (!Existing->isDeclaration()) {
      return Existing;
    }
    Existing->eraseFromParent();
  }

  LLVMContext &Ctx = M.getContext();
  Type *I64 = Type::getInt64Ty(Ctx);
  Type *I1 = Type::getInt1Ty(Ctx);
  Type *I8 = Type::getInt8Ty(Ctx);
  Type *Ptr = PointerType::get(Ctx, 0);
  FunctionType *FTy = FunctionType::get(Ptr, {I64, I1}, false);
  Function *F = Function::Create(FTy, GlobalValue::InternalLinkage,
                                 "__translate_guest_pointer", M);

  const DataLayout &DL = M.getDataLayout();
  struct Range {
    uint64_t Start;
    uint64_t End;
    GlobalValue *GV;
  };
  std::vector<Range> Ranges;

  for (GlobalVariable &GV : M.globals()) {
    if (GV.isDeclaration()) {
      continue;
    }
    auto Addr = ProvenGuestStart(M, GV, DL);
    if (!Addr) {
      continue;
    }
    uint64_t Size = std::max<uint64_t>(1, DL.getTypeAllocSize(GV.getValueType()));
    Ranges.push_back({*Addr, *Addr + Size, &GV});
  }
  for (Function &Fn : M) {
    if (Fn.isDeclaration()) {
      continue;
    }
    uint64_t Addr = ResolveGuestAddress(&Fn);
    if (!Addr) {
      continue;
    }
    Ranges.push_back({Addr, Addr + 1, &Fn});
  }
  std::sort(Ranges.begin(), Ranges.end(), [](const Range &A, const Range &B) {
    return A.Start < B.Start;
  });

  BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", F);
  Value *GuestAddr = F->getArg(0);
  BasicBlock *Cur = Entry;

  for (const Range &R : Ranges) {
    BasicBlock *Match = BasicBlock::Create(Ctx, "match", F);
    BasicBlock *Next = BasicBlock::Create(Ctx, "next", F);
    IRBuilder<> B(Cur);
    Value *GEStart = B.CreateICmpUGE(GuestAddr, B.getInt64(R.Start));
    Value *LTEnd = B.CreateICmpULT(GuestAddr, B.getInt64(R.End));
    B.CreateCondBr(B.CreateAnd(GEStart, LTEnd), Match, Next);

    IRBuilder<> MB(Match);
    Value *Offset = MB.CreateSub(GuestAddr, MB.getInt64(R.Start));
    Value *Base = ConstantExpr::getBitCast(R.GV, Ptr);
    Value *PtrVal = MB.CreateGEP(I8, Base, Offset);
    MB.CreateRet(PtrVal);
    Cur = Next;
  }

  IRBuilder<> B(Cur);
  B.CreateRet(B.CreateIntToPtr(GuestAddr, Ptr));
  return F;
}

Function *GetOrCreateGuestAddressFromPointer(Module &M) {
  if (Function *Existing = M.getFunction("__guest_pointer_to_address")) {
    if (!Existing->isDeclaration())
      return Existing;
    Existing->eraseFromParent();
  }

  LLVMContext &Ctx = M.getContext();
  Type *I64 = Type::getInt64Ty(Ctx);
  Type *I8 = Type::getInt8Ty(Ctx);
  Type *Ptr = PointerType::get(Ctx, 0);
  FunctionType *FTy = FunctionType::get(I64, {Ptr}, false);
  Function *F = Function::Create(FTy, GlobalValue::InternalLinkage,
                                 "__guest_pointer_to_address", M);
  // This bridge is representation-sensitive: folding a global pointer to its
  // guest image literal would compare host pointers against guest addresses.
  // Keep its tiny proof CFG intact until code generation materializes the
  // actual native object addresses.
  F->addFnAttr(Attribute::NoInline);
  F->addFnAttr(Attribute::OptimizeNone);

  struct Range {
    uint64_t GuestStart;
    uint64_t Size;
    GlobalVariable *GV;
  };
  const DataLayout &DL = M.getDataLayout();
  std::vector<Range> Ranges;
  for (GlobalVariable &GV : M.globals()) {
    if (GV.isDeclaration() || GV.isThreadLocal())
      continue;
    auto GuestStart = ProvenGuestStart(M, GV, DL);
    if (!GuestStart)
      continue;
    const uint64_t Size = std::max<uint64_t>(1, DL.getTypeAllocSize(GV.getValueType()));
    // A wrapped guest range has no single proven address interval.
    if (Size > std::numeric_limits<uint64_t>::max() - *GuestStart)
      continue;
    Ranges.push_back({*GuestStart, Size, &GV});
  }
  std::sort(Ranges.begin(), Ranges.end(), [](const Range &A, const Range &B) {
    return A.GuestStart < B.GuestStart;
  });

  BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", F);
  Value *HostPtr = F->getArg(0);
  IRBuilder<> EntryBuilder(Entry);
  Value *HostInt = EntryBuilder.CreatePtrToInt(HostPtr, I64, "host_ptr_int");
  BasicBlock *Cur = Entry;
  for (const Range &R : Ranges) {
    BasicBlock *Match = BasicBlock::Create(Ctx, "match", F);
    BasicBlock *Next = BasicBlock::Create(Ctx, "next", F);
    IRBuilder<> B(Cur);
    Value *Base = ConstantExpr::getBitCast(R.GV, Ptr);
    // Do not use IRBuilder's folder here: it canonicalizes a named lifted
    // global to its guest numeric address. This must remain a runtime host
    // object identity conversion.
    Value *BaseInt = new PtrToIntInst(Base, I64, "guest_object_base", Cur);
    // The subtraction is modulo arithmetic but the UGE guard proves it is a
    // real object offset before the ULT check admits the mapping.  No nowrap
    // flag is attached, so poison/wrapping behavior is not strengthened.
    Value *Offset = B.CreateSub(HostInt, BaseInt, "guest_object_offset");
    Value *AtOrAfterBase = B.CreateICmpUGE(HostInt, BaseInt);
    Value *InObject = B.CreateICmpULT(Offset, B.getInt64(R.Size));
    B.CreateCondBr(B.CreateAnd(AtOrAfterBase, InObject), Match, Next);

    IRBuilder<> MB(Match);
    Value *GuestAddress = MB.CreateAdd(MB.getInt64(R.GuestStart), Offset,
                                       "guest_address");
    MB.CreateRet(GuestAddress);
    Cur = Next;
  }

  IRBuilder<> Fallback(Cur);
  // Dynamic allocations, host callbacks and unknown pointer provenance are
  // not guessed.  They keep exactly the integer pointer representation the
  // direct ABI bridge observed.
  Fallback.CreateRet(HostInt);
  return F;
}

}  // namespace brighten_runtime
