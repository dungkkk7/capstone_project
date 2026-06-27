#include "BrightenStateSSAPass.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/CFG.h"

namespace brighten_state_ssa {

using namespace llvm;

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
    if (Arg->getArgNo() == 0 && Arg->getParent()->getName() != "main") {
      return total_offset;
    }
  }
  return -1;
}

static Value *buildStateFieldGEP(IRBuilder<> &B, Value *StatePtr, unsigned offset, Type *Ty) {
  return B.CreateConstGEP1_64(B.getInt8Ty(), StatePtr, offset);
}

bool BrightenStateSSAPass::PromoteStateToSSA(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  LLVMContext &Ctx = M.getContext();

  GlobalVariable *StateGV = M.getGlobalVariable("__mcsema_reg_state");

  for (Function &F : M) {
    if (F.isDeclaration()) continue;
    if (F.getName() == "main") continue;

    Value *StatePtr = (F.arg_size() > 0) ? cast<Value>(F.getArg(0)) : cast<Value>(StateGV);
    if (!StatePtr) continue;

    struct FieldInfo {
      unsigned offset;
      Type *type = nullptr;
      unsigned max_access_size = 0;
      SmallVector<LoadInst *, 4> loads;
      SmallVector<StoreInst *, 4> stores;
    };

    DenseMap<unsigned, FieldInfo> fields;

    for (BasicBlock &BB : F) {
      for (Instruction &I : BB) {
        if (auto *LI = dyn_cast<LoadInst>(&I)) {
          int64_t off = resolveStateOffset(LI->getPointerOperand(), DL);
          if (off >= 0) {
            unsigned u_off = static_cast<unsigned>(off);
            auto &info = fields[u_off];
            info.offset = u_off;
            unsigned sz = DL.getTypeStoreSize(LI->getType());
            if (sz > info.max_access_size) {
              info.max_access_size = sz;
              info.type = LI->getType();
            }
            info.loads.push_back(LI);
          }
        } else if (auto *SI = dyn_cast<StoreInst>(&I)) {
          int64_t off = resolveStateOffset(SI->getPointerOperand(), DL);
          if (off >= 0) {
            unsigned u_off = static_cast<unsigned>(off);
            auto &info = fields[u_off];
            info.offset = u_off;
            unsigned sz = DL.getTypeStoreSize(SI->getValueOperand()->getType());
            if (sz > info.max_access_size) {
              info.max_access_size = sz;
              info.type = SI->getValueOperand()->getType();
            }
            info.stores.push_back(SI);
          }
        }
      }
    }

    if (fields.empty()) continue;

    // Create allocas in the entry block
    IRBuilder<> EntryBuilder(&F.getEntryBlock().front());
    DenseMap<unsigned, AllocaInst *> field_allocas;

    for (auto &pair : fields) {
      unsigned offset = pair.first;
      auto &info = pair.second;

      // Force type to be integer of maximum access size
      Type *AllocaTy = Type::getIntNTy(Ctx, info.max_access_size * 8);
      info.type = AllocaTy;

      AllocaInst *Alloca = EntryBuilder.CreateAlloca(AllocaTy, nullptr, "state_" + std::to_string(offset));
      field_allocas[offset] = Alloca;

      // Initialize alloca from state
      IRBuilder<> B(Alloca->getNextNode());
      Value *GEP = buildStateFieldGEP(B, StatePtr, offset, AllocaTy);
      Value *InitVal = B.CreateLoad(AllocaTy, GEP, "state_init");
      B.CreateStore(InitVal, Alloca);
    }

    // Replace loads
    for (auto &pair : fields) {
      unsigned offset = pair.first;
      auto &info = pair.second;
      AllocaInst *Alloca = field_allocas[offset];

      for (LoadInst *LI : info.loads) {
        IRBuilder<> B(LI);
        Value *Loaded = B.CreateLoad(info.type, Alloca);
        
        Type *LITy = LI->getType();
        Value *Replacement = nullptr;
        if (LITy == info.type) {
          Replacement = Loaded;
        } else if (LITy->isPointerTy()) {
          Replacement = B.CreateIntToPtr(Loaded, LITy);
        } else if (LITy->isIntegerTy()) {
          Replacement = B.CreateTrunc(Loaded, LITy);
        } else {
          // bitcast for floats or vectors
          Value *IntVal = B.CreateTrunc(Loaded, Type::getIntNTy(Ctx, DL.getTypeStoreSize(LITy) * 8));
          Replacement = B.CreateBitCast(IntVal, LITy);
        }

        LI->replaceAllUsesWith(Replacement);
        LI->eraseFromParent();
      }
    }

    // Replace stores
    for (auto &pair : fields) {
      unsigned offset = pair.first;
      auto &info = pair.second;
      AllocaInst *Alloca = field_allocas[offset];

      for (StoreInst *SI : info.stores) {
        IRBuilder<> B(SI);
        Value *StoredVal = SI->getValueOperand();
        Type *SITy = StoredVal->getType();

        Value *IntStoredVal = nullptr;
        if (SITy->isIntegerTy()) {
          IntStoredVal = StoredVal;
        } else if (SITy->isPointerTy()) {
          IntStoredVal = B.CreatePtrToInt(StoredVal, Type::getIntNTy(Ctx, DL.getTypeStoreSize(SITy) * 8));
        } else {
          Type *IntTy = Type::getIntNTy(Ctx, DL.getTypeStoreSize(SITy) * 8);
          IntStoredVal = B.CreateBitCast(StoredVal, IntTy);
        }

        unsigned val_bits = DL.getTypeStoreSize(SITy) * 8;
        unsigned alloca_bits = info.max_access_size * 8;

        if (val_bits == alloca_bits) {
          B.CreateStore(IntStoredVal, Alloca);
        } else {
          // Sub-register write (masking)
          Value *Curr = B.CreateLoad(info.type, Alloca);
          uint64_t mask_val = ~((1ULL << val_bits) - 1);
          if (val_bits == 64) mask_val = 0; // Avoid shift overflow if 64 bits
          Value *Mask = ConstantInt::get(info.type, mask_val);
          Value *Cleared = B.CreateAnd(Curr, Mask);
          Value *ZextVal = B.CreateZExt(IntStoredVal, info.type);
          Value *NewVal = B.CreateOr(Cleared, ZextVal);
          B.CreateStore(NewVal, Alloca);
        }

        SI->eraseFromParent();
      }
    }

    // Flush/reload around calls
    for (BasicBlock &BB : F) {
      for (auto InstIt = BB.begin(); InstIt != BB.end(); ) {
        Instruction &I = *InstIt++;
        auto *CI = dyn_cast<CallInst>(&I);
        if (!CI || CI->isInlineAsm()) continue;

        Function *Callee = CI->getCalledFunction();
        if (Callee) {
          // Skip libc calls and declarations unless they take State parameter
          bool takes_state = false;
          for (auto &arg : CI->args()) {
            if (arg.get() == StatePtr || arg.get() == StateGV) { takes_state = true; break; }
          }
          if (Callee->isDeclaration() && !takes_state) {
            continue;
          }
        }

        if (CI->arg_size() < 1) continue;
        Value *CallStatePtr = CI->getArgOperand(0);
        if (!CallStatePtr->getType()->isPointerTy()) continue;

        // Flush before call
        {
          IRBuilder<> B(CI);
          for (auto &pair : fields) {
            unsigned offset = pair.first;
            auto &info = pair.second;
            AllocaInst *Alloca = field_allocas[offset];
            Value *Val = B.CreateLoad(info.type, Alloca);
            Value *GEP = buildStateFieldGEP(B, CallStatePtr, offset, info.type);
            B.CreateStore(Val, GEP);
          }
        }

        // Reload after call
        {
          IRBuilder<> B(CI->getNextNode());
          for (auto &pair : fields) {
            unsigned offset = pair.first;
            auto &info = pair.second;
            AllocaInst *Alloca = field_allocas[offset];
            Value *GEP = buildStateFieldGEP(B, CallStatePtr, offset, info.type);
            Value *Val = B.CreateLoad(info.type, GEP);
            B.CreateStore(Val, Alloca);
          }
        }
      }
    }

    // Flush before returns
    for (BasicBlock &BB : F) {
      Instruction *Term = BB.getTerminator();
      if (auto *RI = dyn_cast<ReturnInst>(Term)) {
        IRBuilder<> B(RI);
        for (auto &pair : fields) {
          unsigned offset = pair.first;
          auto &info = pair.second;
          AllocaInst *Alloca = field_allocas[offset];
          Value *Val = B.CreateLoad(info.type, Alloca);
          Value *GEP = buildStateFieldGEP(B, StatePtr, offset, info.type);
          B.CreateStore(Val, GEP);
        }
      }
    }

    Changed = true;
  }

  return Changed;
}

} // namespace brighten_state_ssa
