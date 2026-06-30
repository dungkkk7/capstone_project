#include "BrightenABIRecoveryPass.h"
#include "Brighten/StateLayout.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/CFG.h"
#include <algorithm>

namespace brighten_abi_recovery {

using namespace llvm;
namespace StateLayout = ::brighten::StateLayout;

static int64_t resolveStateOffset(Value *ptr, const DataLayout &DL) {
  int64_t total_offset = 0;
  Value *base = ptr;

  while (true) {
    if (auto *GEP = dyn_cast<GEPOperator>(base)) {
      APInt ap_offset(64, 0);
      if (GEP->accumulateConstantOffset(DL, ap_offset)) {
        total_offset += ap_offset.getSExtValue();
        base = GEP->getPointerOperand();
        continue;
      }
      return -1;
    }
    if (auto *BC = dyn_cast<BitCastOperator>(base)) {
      base = BC->getOperand(0);
      continue;
    }
    if (auto *GA = dyn_cast<GlobalAlias>(base)) {
      StringRef Name = GA->getName();
      if (Name.contains("RSP")) {
        return 2312;
      }
      if (Name.contains("RBP")) {
        return 2328;
      }
      base = GA->getAliasee();
      continue;
    }
    break;
  }

  base = base->stripPointerCasts();
  if (auto *GV = dyn_cast<GlobalVariable>(base)) {
    if (GV->getName() == "__mcsema_reg_state") {
      return total_offset;
    }
  }
  if (auto *Arg = dyn_cast<Argument>(base)) {
    if (Arg->getType()->isPointerTy()) {
      StringRef Name = Arg->getName();
      if (Name.contains_insensitive("state")) {
        return total_offset;
      }
    }
    if (Arg->getArgNo() == 0 && Arg->getType()->isPointerTy() &&
        Arg->getParent()->getName() != "main") {
      return total_offset;
    }
  }
  return -1;
}

bool BrightenABIRecoveryPass::RecoverABISignatures(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  LLVMContext &Ctx = M.getContext();
  Type *Int64Ty = Type::getInt64Ty(Ctx);
  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");
  if (!StateGV) {
    return false;
  }

  // 1. Identify functions to rewrite.
  SmallVector<Function *, 16> TargetFunctions;
  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    StringRef Name = F.getName();
    if (Name.starts_with("sub_") && !Name.ends_with("_native")) {
      // Exclude main subroutine
      if (Name.contains("main")) {
        continue;
      }
      TargetFunctions.push_back(&F);
    }
  }

  DenseMap<Function *, Function *> RewrittenMap;

  for (Function *F : TargetFunctions) {
    // Parse correct PC from name
    uint64_t PC = 0;
    StringRef FName = F->getName();
    if (FName.starts_with("sub_")) {
      StringRef Hex = FName.drop_front(4);
      size_t Underscore = Hex.find('_');
      if (Underscore != StringRef::npos) {
        Hex = Hex.substr(0, Underscore);
      }
      Hex.getAsInteger(16, PC);
    }

    // Determine parameters used and return value
    int MaxParamIndex = -1;
    bool ReturnsValue = false;
    DenseSet<uint64_t> WrittenOffsets;
    DenseSet<int> ActiveParams;

    if (!F->empty()) {
      BasicBlock &EntryBB = F->getEntryBlock();
      for (Instruction &I : EntryBB) {
        if (auto *SI = dyn_cast<StoreInst>(&I)) {
          int64_t off = resolveStateOffset(SI->getPointerOperand(), DL);
          if (off >= 0) {
            WrittenOffsets.insert(off);
          }
        }
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          int64_t off = resolveStateOffset(LI->getPointerOperand(), DL);
          if (off >= 0 && !WrittenOffsets.count(off)) {
            for (int i = 0; i < 6; ++i) {
              if (off == static_cast<int64_t>(StateLayout::kSysVParamOffsets[i])) {
                ActiveParams.insert(i);
              }
            }
          }
        }
      }
    }

    for (BasicBlock &BB : *F) {
      for (Instruction &I : BB) {
        if (auto *SI = dyn_cast<StoreInst>(&I)) {
          int64_t off = resolveStateOffset(SI->getPointerOperand(), DL);
          if (off == static_cast<int64_t>(StateLayout::kRAX)) {
            ReturnsValue = true;
          }
        }
      }
    }

    for (int i : ActiveParams) {
      MaxParamIndex = std::max(MaxParamIndex, i);
    }

    int NumParams = MaxParamIndex + 1;
    Type *RetTy = ReturnsValue ? Int64Ty : Type::getVoidTy(Ctx);

    SmallVector<Type *, 8> ParamTypes;
    for (int i = 0; i < NumParams; ++i) {
      ParamTypes.push_back(Int64Ty);
    }
    ParamTypes.push_back(PointerType::get(Ctx, 0)); // memory pointer

    FunctionType *NewFTy = FunctionType::get(RetTy, ParamTypes, false);
    std::string NewName = (F->getName() + "_native").str();
    Function *FNew = Function::Create(NewFTy, F->getLinkage(), NewName, &M);
    FNew->setAttributes(AttributeList::get(Ctx, AttributeList::FunctionIndex, F->getAttributes().getFnAttrs()));

    // Make F alwaysinline, internal linkage so it is completely optimized out after inlining
    F->removeFnAttr(Attribute::NoInline);
    F->removeFnAttr(Attribute::OptimizeNone);
    F->addFnAttr(Attribute::AlwaysInline);
    F->setLinkage(GlobalValue::InternalLinkage);

    // Populate FNew as the native-to-lifted wrapper
    {
      BasicBlock *EntryBB = BasicBlock::Create(Ctx, "entry", FNew);
      IRBuilder<> B(EntryBB);

      // Allocate local State struct: [4096 x i8]
      Type *StateArrayTy = ArrayType::get(B.getInt8Ty(), 4096);
      AllocaInst *StateAlloca = B.CreateAlloca(StateArrayTy, nullptr, "state_alloca");
      B.CreateMemSet(StateAlloca, B.getInt8(0), 4096, Align(16));

      // Allocate synthetic stack: [65536 x i8]
      Type *StackArrayTy = ArrayType::get(B.getInt8Ty(), 65536);
      AllocaInst *StackAlloca = B.CreateAlloca(StackArrayTy, nullptr, "stack_alloca");
      B.CreateMemSet(StackAlloca, B.getInt8(0xCC), 65536, Align(16));

      // Set up synthetic RSP
      Value *StackTop = B.CreateConstGEP1_64(B.getInt8Ty(), StackAlloca, 60000);
      Value *StackTopInt = B.CreatePtrToInt(StackTop, Int64Ty);
      Value *RSPPtr = B.CreateConstGEP1_64(B.getInt8Ty(), StateAlloca, StateLayout::kRSP);
      B.CreateAlignedStore(StackTopInt, RSPPtr, Align(8));

      // Store native arguments into StateAlloca parameter offsets
      for (int i = 0; i < NumParams; ++i) {
        Value *ParamGEP = B.CreateConstGEP1_64(
            B.getInt8Ty(), StateAlloca, StateLayout::kSysVParamOffsets[i]);
        B.CreateAlignedStore(FNew->getArg(i), ParamGEP, Align(8));
      }

      // Call original lifted function F
      Value *MemArg = FNew->getArg(NumParams);
      SmallVector<Value *, 3> CallArgs;
      CallArgs.push_back(StateAlloca);
      CallArgs.push_back(ConstantInt::get(Int64Ty, PC));
      CallArgs.push_back(MemArg);

      CallInst *CI = B.CreateCall(F->getFunctionType(), F, CallArgs);
      CI->setCallingConv(F->getCallingConv());

      // Return RAX if ReturnsValue, else void
      if (ReturnsValue) {
        Value *RAXPtr = B.CreateConstGEP1_64(B.getInt8Ty(), StateAlloca, StateLayout::kRAX);
        Value *RetVal = B.CreateAlignedLoad(Int64Ty, RAXPtr, Align(8));
        B.CreateRet(RetVal);
      } else {
        B.CreateRetVoid();
      }
    }

    RewrittenMap[F] = FNew;
    Changed = true;
  }

  // 2. Rewrite call sites
  for (auto &Pair : RewrittenMap) {
    Function *F = Pair.first;
    Function *FNew = Pair.second;

    SmallVector<CallInst *, 16> Calls;
    for (User *U : F->users()) {
      if (auto *CI = dyn_cast<CallInst>(U)) {
        Value *CalleeVal = CI->getCalledOperand()->stripPointerCasts();
        if (CalleeVal == F && CI->getFunction() != FNew) {
          Calls.push_back(CI);
        }
      }
    }

    for (CallInst *CI : Calls) {
      IRBuilder<> B(CI);
      Value *CallerState = CI->getArgOperand(0);

      SmallVector<Value *, 8> Args;
      unsigned NumNativeABIParams = FNew->getFunctionType()->getNumParams() - 1; // last is memory
      for (unsigned i = 0; i < NumNativeABIParams; ++i) {
        Value *GEP = B.CreateConstGEP1_64(
            B.getInt8Ty(), CallerState, StateLayout::kSysVParamOffsets[i]);
        Value *Load = B.CreateAlignedLoad(Int64Ty, GEP, Align(8));
        Args.push_back(Load);
      }
      Args.push_back(CI->getArgOperand(2)); // memory

      CallInst *NewCall = B.CreateCall(FNew->getFunctionType(), FNew, Args);
      NewCall->setCallingConv(CI->getCallingConv());

      if (!FNew->getReturnType()->isVoidTy()) {
        Value *GEP =
            B.CreateConstGEP1_64(B.getInt8Ty(), CallerState, StateLayout::kRAX);
        B.CreateAlignedStore(NewCall, GEP, Align(8));
      }

      if (CI->arg_size() >= 3) {
        CI->replaceAllUsesWith(CI->getArgOperand(2));
      }
      CI->eraseFromParent();
    }
  }

  return Changed;
}

} // namespace brighten_abi_recovery
