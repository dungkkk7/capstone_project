#include "BrightenABIRecoveryPass.h"

#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Metadata.h"

namespace brighten_abi {

using namespace llvm;

namespace {

constexpr StringLiteral ScanfI32WrapperName = "__brighten_scanf_i32_1";
constexpr StringLiteral ScanfI32WrapperMetadata =
    "brighten.scanf.i32.wrapper";
constexpr StringLiteral ScanfDestinationMetadata =
    "brighten.scanf.destination";

// !brighten.scanf.destination is a Brighten-private callsite summary, not an
// LLVM memory attribute.  Its operands are:
//   !{ i32 version, i32 destination-operand-index,
//       i64 maximum-bytes-written, i1 nonretained-after-return }
// Version 1 is emitted only for a direct libc scanf declaration with exactly
// two arguments and a statically resolved "%d\0" format.  The write is a
// *may-write*: scanf can return EOF or a matching failure without storing.
// The node says nothing about reads, aliasing, errno, locale, other global
// effects, unwinding, or the return value.  Consumers must therefore model
// only this bounded destination effect and retain every other call effect.
//
// It is attached both to the generated wrapper call and its forwarding scanf
// call.  The latter is sound because the wrapper is internal, freshly created
// only after every one of its callers has passed the exact-format proof, and
// no address of the wrapper escapes.  That placement lets normal inlining
// clone the proof onto the direct scanf call; if an optimizer drops unknown
// metadata, the contract is merely unavailable, never strengthened.
static MDNode *makeScanfI32DestinationContract(LLVMContext &C) {
  Type *I1 = Type::getInt1Ty(C);
  Type *I32 = Type::getInt32Ty(C);
  Type *I64 = Type::getInt64Ty(C);
  return MDNode::get(C, {ConstantAsMetadata::get(ConstantInt::get(I32, 1)),
                         ConstantAsMetadata::get(ConstantInt::get(I32, 1)),
                         ConstantAsMetadata::get(ConstantInt::get(I64, 4)),
                         ConstantAsMetadata::get(ConstantInt::get(I1, 1))});
}

// Append only byte-addressable, padding-free constants.  A format pointer
// inside any aggregate containing pointers, target-dependent padding, or an
// unknown constant is intentionally not evidence for this normalization.
static bool appendConstantBytes(const Constant *C, SmallVectorImpl<uint8_t> &B,
                                uint64_t Limit) {
  if (B.size() >= Limit)
    return true;

  if (const auto *CDS = dyn_cast<ConstantDataSequential>(C)) {
    if (!CDS->getElementType()->isIntegerTy(8))
      return false;
    for (unsigned I = 0; I != CDS->getNumElements() && B.size() < Limit;
         ++I)
      B.push_back(static_cast<uint8_t>(CDS->getElementAsInteger(I)));
    return true;
  }
  if (const auto *CI = dyn_cast<ConstantInt>(C)) {
    if (!CI->getType()->isIntegerTy(8))
      return false;
    B.push_back(static_cast<uint8_t>(CI->getZExtValue()));
    return true;
  }
  if (const auto *CA = dyn_cast<ConstantArray>(C)) {
    for (const Use &U : CA->operands()) {
      if (!appendConstantBytes(cast<Constant>(U.get()), B, Limit))
        return false;
      if (B.size() >= Limit)
        return true;
    }
    return true;
  }
  if (const auto *CS = dyn_cast<ConstantStruct>(C)) {
    if (!CS->getType()->isPacked())
      return false;
    for (const Use &U : CS->operands()) {
      if (!appendConstantBytes(cast<Constant>(U.get()), B, Limit))
        return false;
      if (B.size() >= Limit)
        return true;
    }
    return true;
  }
  if (const auto *Zero = dyn_cast<ConstantAggregateZero>(C)) {
    const TypeSize Size =
        C->getType()->getPrimitiveSizeInBits().isScalable()
            ? TypeSize::getFixed(0)
            : C->getType()->getPrimitiveSizeInBits();
    if (Size.isScalable() || Size.getFixedValue() % 8 != 0)
      return false;
    uint64_t Bytes = Size.getFixedValue() / 8;
    while (Bytes != 0 && B.size() < Limit) {
      B.push_back(0);
      --Bytes;
    }
    return true;
  }
  return false;
}

static bool isExactlyPercentDFormat(Value *Format, const DataLayout &DL) {
  int64_t Offset = 0;
  Value *Base = GetPointerBaseWithConstantOffset(Format, Offset, DL,
                                                  /*AllowNonInbounds=*/false);
  auto *GV = dyn_cast<GlobalVariable>(Base);
  if (!GV || !GV->isConstant() || !GV->hasInitializer() || Offset < 0)
    return false;

  const uint64_t Start = static_cast<uint64_t>(Offset);
  if (Start > UINT64_MAX - 3)
    return false;
  SmallVector<uint8_t, 32> Bytes;
  if (!appendConstantBytes(GV->getInitializer(), Bytes, Start + 3) ||
      Bytes.size() != Start + 3)
    return false;
  return Bytes[Start] == '%' && Bytes[Start + 1] == 'd' &&
         Bytes[Start + 2] == 0;
}

static bool isDirectScanfDeclaration(const Function &F) {
  if (F.getName() != "scanf" || !F.isDeclaration() ||
      F.getCallingConv() != CallingConv::C)
    return false;
  const FunctionType *FT = F.getFunctionType();
  return FT->isVarArg() && FT->getReturnType()->isIntegerTy(32) &&
         FT->getNumParams() == 1 && FT->getParamType(0)->isPointerTy();
}

static Function *getOrCreateScanfI32Wrapper(Module &M, Function &Scanf) {
  if (Function *Existing = M.getFunction(ScanfI32WrapperName)) {
    if (!Existing->getMetadata(ScanfI32WrapperMetadata) ||
        Existing->getFunctionType() !=
            FunctionType::get(Type::getInt32Ty(M.getContext()),
                              {PointerType::getUnqual(M.getContext()),
                               PointerType::getUnqual(M.getContext())},
                              false))
      return nullptr;
    return Existing;
  }

  LLVMContext &C = M.getContext();
  Type *PtrTy = PointerType::getUnqual(C);
  FunctionType *WrapperTy =
      FunctionType::get(Type::getInt32Ty(C), {PtrTy, PtrTy}, false);
  Function *Wrapper = Function::Create(WrapperTy, GlobalValue::InternalLinkage,
                                        ScanfI32WrapperName, M);
  // This wrapper is deliberately eligible for normal inlining/elimination.
  // The private callsite metadata below, rather than an artificial boundary
  // or an LLVM memory attribute, carries the downstream-only summary.
  Wrapper->setMetadata(ScanfI32WrapperMetadata, MDNode::get(C, {}));

  BasicBlock *Entry = BasicBlock::Create(C, "entry", Wrapper);
  IRBuilder<> B(Entry);
  auto Arg = Wrapper->arg_begin();
  Value *Format = &*Arg++;
  Value *Destination = &*Arg;
  CallInst *Forward = B.CreateCall(&Scanf, {Format, Destination}, "scanf.ret");
  Forward->setCallingConv(CallingConv::C);
  Forward->setMetadata(ScanfDestinationMetadata,
                       makeScanfI32DestinationContract(C));
  B.CreateRet(Forward);
  return Wrapper;
}

static bool isEligibleScanfI32Call(CallInst &CI, Function &Scanf,
                                   const DataLayout &DL) {
  if (CI.getCalledFunction() != &Scanf || CI.getFunction()->getMetadata(
                                             ScanfI32WrapperMetadata) ||
      CI.isMustTailCall() || CI.getCallingConv() != CallingConv::C ||
      CI.hasOperandBundles() || CI.arg_size() != 2)
    return false;
  const TypeSize I32StoreSize =
      DL.getTypeStoreSize(Type::getInt32Ty(CI.getContext()));
  if (I32StoreSize.isScalable() || I32StoreSize.getFixedValue() != 4)
    return false;
  return CI.getArgOperand(0)->getType()->isPointerTy() &&
         CI.getArgOperand(1)->getType()->isPointerTy() &&
         isExactlyPercentDFormat(CI.getArgOperand(0), DL);
}

} // namespace

bool BrightenABIRecoveryPass::NormalizeScanfI32Boundaries(
    ABIRecoveryContext &Ctx) {
  Function *Scanf = Ctx.M.getFunction("scanf");
  if (!Scanf || !isDirectScanfDeclaration(*Scanf))
    return false;

  SmallVector<CallInst *, 16> Candidates;
  for (Function &F : Ctx.M) {
    if (F.isDeclaration() || F.getMetadata(ScanfI32WrapperMetadata))
      continue;
    for (BasicBlock &BB : F)
      for (Instruction &I : BB)
        if (auto *CI = dyn_cast<CallInst>(&I);
            CI && isEligibleScanfI32Call(*CI, *Scanf, Ctx.M.getDataLayout()))
          Candidates.push_back(CI);
  }
  if (Candidates.empty())
    return false;

  Function *Wrapper = getOrCreateScanfI32Wrapper(Ctx.M, *Scanf);
  if (!Wrapper)
    return false;

  for (CallInst *Old : Candidates) {
    IRBuilder<> B(Old);
    CallInst *NewCall = B.CreateCall(Wrapper, {Old->getArgOperand(0),
                                                Old->getArgOperand(1)},
                                      Old->getName());
    NewCall->setCallingConv(CallingConv::C);
    NewCall->setTailCallKind(Old->getTailCallKind());
    NewCall->setDebugLoc(Old->getDebugLoc());
    NewCall->copyMetadata(*Old);
    NewCall->setMetadata(ScanfDestinationMetadata,
                         makeScanfI32DestinationContract(Ctx.M.getContext()));
    Old->replaceAllUsesWith(NewCall);
    Old->eraseFromParent();
  }
  return true;
}

} // namespace brighten_abi
