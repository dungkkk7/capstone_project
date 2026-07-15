#include "BrightenRuntimeHelperPass.h"
#include "Helpers.h"

#include <optional>
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"

namespace brighten_runtime {

using namespace llvm;

namespace {

static bool DefineReturnMemory(Function &F) {
  if (!F.isDeclaration()) {
    return false;
  }
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  Type *RetTy = F.getReturnType();
  if (RetTy->isVoidTy()) {
    B.CreateRetVoid();
    return true;
  }
  if (RetTy->isPointerTy()) {
    if (Value *Mem = FindLikelyMemoryArg(F)) {
      B.CreateRet(Mem);
    } else {
      B.CreateRet(ZeroValue(RetTy));
    }
    return true;
  }
  B.CreateRet(ZeroValue(RetTy));
  return true;
}

static bool DefineFence(Function &F, AtomicOrdering Ordering) {
  if (!F.isDeclaration())
    return false;
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  B.CreateFence(Ordering);
  Type *RetTy = F.getReturnType();
  if (RetTy->isVoidTy())
    B.CreateRetVoid();
  else if (RetTy->isPointerTy() && FindLikelyMemoryArg(F))
    B.CreateRet(FindLikelyMemoryArg(F));
  else
    B.CreateRet(ZeroValue(RetTy));
  return true;
}

static std::optional<uint64_t> ParseSizeSuffix(StringRef Name) {
  size_t Pos = Name.rfind('_');
  if (Pos == StringRef::npos) {
    return std::nullopt;
  }
  uint64_t Size = 0;
  if (Name.drop_front(Pos + 1).getAsInteger(10, Size)) {
    return std::nullopt;
  }
  return Size;
}

static bool IsSupportedAtomicWidth(uint64_t Bits) {
  return Bits == 8 || Bits == 16 || Bits == 32 || Bits == 64 || Bits == 128;
}

static bool DefineAtomicRMW(Function &F, Module &M, AtomicRMWInst::BinOp Op) {
  auto Size = ParseSizeSuffix(F.getName());
  if (!F.isDeclaration() || F.arg_size() < 3 || !Size ||
      !IsSupportedAtomicWidth(*Size) ||
      !F.getArg(2)->getType()->isPointerTy() ||
      F.getReturnType() != F.getArg(0)->getType()) {
    return false;
  }
  Function *Translate = GetOrCreateTranslateGuestPointer(M);
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  Value *Addr = CastAddressToI64(B, F.getArg(1));
  Value *Ptr = B.CreateCall(Translate, {Addr, B.getTrue()});
  Value *ValPtr = F.getArg(2);
  Type *ValTy = IntegerType::get(F.getContext(), *Size);
  Value *In = B.CreateLoad(ValTy, ValPtr);
  Value *Old = B.CreateAtomicRMW(Op, Ptr, In, MaybeAlign(),
                                 AtomicOrdering::SequentiallyConsistent);
  B.CreateStore(Old, ValPtr);
  B.CreateRet(F.getArg(0));
  return true;
}

static bool DefineCompareExchange(Function &F, Module &M) {
  auto Size = ParseSizeSuffix(F.getName());
  if (!F.isDeclaration() || F.arg_size() < 4 || !Size ||
      !IsSupportedAtomicWidth(*Size) ||
      !F.getArg(2)->getType()->isPointerTy() ||
      (!F.getArg(3)->getType()->isPointerTy() &&
       !F.getArg(3)->getType()->isIntegerTy()) ||
      F.getReturnType() != F.getArg(0)->getType()) {
    return false;
  }
  Function *Translate = GetOrCreateTranslateGuestPointer(M);
  BasicBlock *BB = BasicBlock::Create(F.getContext(), "entry", &F);
  IRBuilder<> B(BB);
  Type *ValTy = IntegerType::get(F.getContext(), *Size);
  Value *Ptr = B.CreateCall(Translate, {CastAddressToI64(B, F.getArg(1)), B.getTrue()});
  Value *ExpectedPtr = F.getArg(2);
  Value *Desired = F.getArg(3);
  if (Desired->getType()->isPointerTy()) {
    Desired = B.CreateLoad(ValTy, Desired);
  } else if (Desired->getType() != ValTy) {
    Desired = B.CreateIntCast(Desired, ValTy, false);
  }
  Value *Expected = B.CreateLoad(ValTy, ExpectedPtr);
  Value *Pair = B.CreateAtomicCmpXchg(
      Ptr, Expected, Desired, MaybeAlign(),
      AtomicOrdering::SequentiallyConsistent,
      AtomicOrdering::SequentiallyConsistent);
  Value *Old = B.CreateExtractValue(Pair, 0, "cmpxchg.old");
  B.CreateStore(Old, ExpectedPtr);
  B.CreateRet(F.getArg(0));
  return true;
}

}  // namespace

bool BrightenRuntimeHelperPass::DefineRemillAtomicBarrierRuntime(Module &M) {
  bool Changed = false;
  SmallVector<Function *, 32> Work;
  for (Function &F : M) {
    if (!IsRemillDecl(F)) {
      continue;
    }
    StringRef Name = F.getName();
    if (Name.starts_with("__remill_barrier_") ||
        Name == "__remill_atomic_begin" ||
        Name == "__remill_atomic_end" ||
        Name == "__remill_delay_slot_begin" ||
        Name == "__remill_delay_slot_end" ||
        Name.starts_with("__remill_compare_exchange_memory_") ||
        Name.starts_with("__remill_fetch_and_") ||
        Name.starts_with("__remill_read_io_port_") ||
        Name.starts_with("__remill_write_io_port_")) {
      Work.push_back(&F);
    }
  }

  for (Function *F : Work) {
    StringRef Name = F->getName();
    if (Name.starts_with("__remill_compare_exchange_memory_")) {
      Changed |= DefineCompareExchange(*F, M);
    } else if (Name.starts_with("__remill_fetch_and_add_")) {
      Changed |= DefineAtomicRMW(*F, M, AtomicRMWInst::Add);
    } else if (Name.starts_with("__remill_fetch_and_sub_")) {
      Changed |= DefineAtomicRMW(*F, M, AtomicRMWInst::Sub);
    } else if (Name.starts_with("__remill_fetch_and_and_")) {
      Changed |= DefineAtomicRMW(*F, M, AtomicRMWInst::And);
    } else if (Name.starts_with("__remill_fetch_and_or_")) {
      Changed |= DefineAtomicRMW(*F, M, AtomicRMWInst::Or);
    } else if (Name.starts_with("__remill_fetch_and_xor_")) {
      Changed |= DefineAtomicRMW(*F, M, AtomicRMWInst::Xor);
    } else if (Name.starts_with("__remill_fetch_and_nand_")) {
      Changed |= DefineAtomicRMW(*F, M, AtomicRMWInst::Nand);
    } else if (Name == "__remill_barrier_load_load") {
      Changed |= DefineFence(*F, AtomicOrdering::Acquire);
    } else if (Name == "__remill_barrier_store_store") {
      Changed |= DefineFence(*F, AtomicOrdering::Release);
    } else if (Name == "__remill_barrier_load_store" ||
               Name == "__remill_barrier_store_load") {
      Changed |= DefineFence(*F, AtomicOrdering::SequentiallyConsistent);
    } else if (Name == "__remill_delay_slot_begin" ||
               Name == "__remill_delay_slot_end") {
      Changed |= DefineReturnMemory(*F);
    } else if (Name.starts_with("__remill_read_io_port_") ||
               Name.starts_with("__remill_write_io_port_") ||
               Name == "__remill_atomic_begin" ||
               Name == "__remill_atomic_end") {
      errs() << "[brighten-remill-runtime] exact atomic/I/O lowering unavailable: "
             << Name << "\n";
    } else {
      errs() << "[brighten-remill-runtime] unresolved atomic helper: "
             << Name << "\n";
    }
  }
  return Changed;
}

}  // namespace brighten_runtime
