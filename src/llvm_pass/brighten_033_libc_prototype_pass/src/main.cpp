#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"

using namespace llvm;

namespace {

Value *BuildStateLoad(IRBuilder<> &Builder, Value *StatePtr, unsigned Offset) {
  Value *GEP = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StatePtr, Offset);
  return Builder.CreateLoad(Builder.getInt64Ty(), GEP);
}

void BuildStateStore(IRBuilder<> &Builder, Value *StatePtr, unsigned Offset, Value *Val) {
  Value *GEP = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StatePtr, Offset);
  Builder.CreateStore(Val, GEP);
}

FunctionCallee getOrInsertCorrectPrototype(Module &M, StringRef Name, FunctionType *FTy) {
  Function *OldF = M.getFunction(Name);
  if (OldF) {
    if (OldF->getFunctionType() == FTy) {
      return OldF;
    }
    Function *NewF = Function::Create(FTy, OldF->getLinkage(), Name + "_temp_name", M);
    NewF->copyAttributesFrom(OldF);
    OldF->replaceAllUsesWith(NewF);
    OldF->eraseFromParent();
    NewF->setName(Name);
    return NewF;
  }
  return M.getOrInsertFunction(Name, FTy);
}

struct BrightenLibcPrototypePass : public PassInfoMixin<BrightenLibcPrototypePass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    LLVMContext &Ctx = M.getContext();
    bool Changed = false;

    for (Function &F : M) {
      if (F.isDeclaration() || F.empty()) continue;
      StringRef Name = F.getName();
      if (!Name.starts_with("ext_")) continue;

      size_t Pos = Name.find('_', 4);
      if (Pos == StringRef::npos) continue;
      StringRef LibcName = Name.substr(Pos + 1);

      // Found a libc thunk. Rebuild its body to call native libc directly.
      F.deleteBody();
      BasicBlock *BB = BasicBlock::Create(Ctx, "entry", &F);
      IRBuilder<> Builder(BB);

      Value *StatePtr = F.getArg(0);
      Value *MemoryPtr = F.getArg(2);

      // Load parameters from state
      Value *RDI = BuildStateLoad(Builder, StatePtr, 2296);
      Value *RSI = BuildStateLoad(Builder, StatePtr, 2280);
      Value *RDX = BuildStateLoad(Builder, StatePtr, 2264);
      Value *RCX = BuildStateLoad(Builder, StatePtr, 2248);
      Value *R8  = BuildStateLoad(Builder, StatePtr, 2344);
      Value *R9  = BuildStateLoad(Builder, StatePtr, 2360);

      Value *RetVal = nullptr;

      if (LibcName == "printf") {
        FunctionCallee PrintfCallee = getOrInsertCorrectPrototype(M, "printf", 
          FunctionType::get(Builder.getInt32Ty(), {Builder.getPtrTy()}, true));
        Value *Fmt = Builder.CreateIntToPtr(RDI, Builder.getPtrTy());
        CallInst *CI = Builder.CreateCall(PrintfCallee, {Fmt, RSI, RDX, RCX, R8, R9});
        CI->addFnAttr(Attribute::NoBuiltin);
        RetVal = CI;
      }
      else if (LibcName == "__isoc99_scanf" || LibcName == "scanf") {
        FunctionCallee ScanfCallee = getOrInsertCorrectPrototype(M, LibcName, 
          FunctionType::get(Builder.getInt32Ty(), {Builder.getPtrTy()}, true));
        if (auto *ScanfF = dyn_cast<Function>(ScanfCallee.getCallee())) {
          errs() << "[DEBUG_PASS] Adding NoBuiltin to " << ScanfF->getName() << "\n";
          ScanfF->addFnAttr(Attribute::NoBuiltin);
        }
        Value *Fmt = Builder.CreateIntToPtr(RDI, Builder.getPtrTy());
        Value *PtrSI = Builder.CreateIntToPtr(RSI, Builder.getPtrTy());
        Value *PtrDX = Builder.CreateIntToPtr(RDX, Builder.getPtrTy());
        Value *PtrCX = Builder.CreateIntToPtr(RCX, Builder.getPtrTy());
        Value *Ptr8  = Builder.CreateIntToPtr(R8,  Builder.getPtrTy());
        Value *Ptr9  = Builder.CreateIntToPtr(R9,  Builder.getPtrTy());
        CallInst *CI = Builder.CreateCall(ScanfCallee, {Fmt, PtrSI, PtrDX, PtrCX, Ptr8, Ptr9});
        CI->addFnAttr(Attribute::NoBuiltin);
        RetVal = CI;
      }
      else if (LibcName == "malloc") {
        FunctionCallee MallocCallee = getOrInsertCorrectPrototype(M, "malloc", 
          FunctionType::get(Builder.getPtrTy(), {Builder.getInt64Ty()}, false));
        Value *Ptr = Builder.CreateCall(MallocCallee, {RDI});
        RetVal = Builder.CreatePtrToInt(Ptr, Builder.getInt64Ty());
      }
      else if (LibcName == "free") {
        FunctionCallee FreeCallee = getOrInsertCorrectPrototype(M, "free", 
          FunctionType::get(Builder.getVoidTy(), {Builder.getPtrTy()}, false));
        Value *Ptr = Builder.CreateIntToPtr(RDI, Builder.getPtrTy());
        Builder.CreateCall(FreeCallee, {Ptr});
      }
      else if (LibcName == "realloc") {
        FunctionCallee ReallocCallee = getOrInsertCorrectPrototype(M, "realloc", 
          FunctionType::get(Builder.getPtrTy(), {Builder.getPtrTy(), Builder.getInt64Ty()}, false));
        Value *Ptr = Builder.CreateIntToPtr(RDI, Builder.getPtrTy());
        Value *NewPtr = Builder.CreateCall(ReallocCallee, {Ptr, RSI});
        RetVal = Builder.CreatePtrToInt(NewPtr, Builder.getInt64Ty());
      }
      else if (LibcName == "abort") {
        FunctionCallee AbortCallee = getOrInsertCorrectPrototype(M, "abort", 
          FunctionType::get(Builder.getVoidTy(), {}, false));
        Builder.CreateCall(AbortCallee, {});
      }
      else if (LibcName == "__cxa_finalize") {
        FunctionCallee FinalizeCallee = getOrInsertCorrectPrototype(M, "__cxa_finalize", 
          FunctionType::get(Builder.getVoidTy(), {Builder.getPtrTy()}, false));
        Value *Ptr = Builder.CreateIntToPtr(RDI, Builder.getPtrTy());
        Builder.CreateCall(FinalizeCallee, {Ptr});
      }
      else if (LibcName == "puts") {
        FunctionCallee PutsCallee = getOrInsertCorrectPrototype(M, "puts", 
          FunctionType::get(Builder.getInt32Ty(), {Builder.getPtrTy()}, false));
        Value *Ptr = Builder.CreateIntToPtr(RDI, Builder.getPtrTy());
        RetVal = Builder.CreateCall(PutsCallee, {Ptr});
      }
      else if (LibcName == "putchar") {
        FunctionCallee PutcharCallee = getOrInsertCorrectPrototype(M, "putchar", 
          FunctionType::get(Builder.getInt32Ty(), {Builder.getInt32Ty()}, false));
        Value *CharVal = Builder.CreateTrunc(RDI, Builder.getInt32Ty());
        RetVal = Builder.CreateCall(PutcharCallee, {CharVal});
      }
      else if (LibcName == "getchar") {
        FunctionCallee GetcharCallee = getOrInsertCorrectPrototype(M, "getchar", 
          FunctionType::get(Builder.getInt32Ty(), {}, false));
        RetVal = Builder.CreateCall(GetcharCallee, {});
      }

      // Store return value to RAX (2216) in state
      if (RetVal) {
        Value *CastRet = RetVal;
        if (RetVal->getType()->isIntegerTy() && RetVal->getType()->getIntegerBitWidth() < 64) {
          CastRet = Builder.CreateSExt(RetVal, Builder.getInt64Ty());
        }
        BuildStateStore(Builder, StatePtr, 2216, CastRet);
      }

      Builder.CreateRet(MemoryPtr);
      Changed = true;
    }

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
    LLVM_PLUGIN_API_VERSION,
    "BrightenLibcPrototypePass",
    LLVM_VERSION_STRING,
    [](PassBuilder &PB) {
      PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "brighten-libc-prototype-pass") {
            MPM.addPass(BrightenLibcPrototypePass());
            return true;
          }
          return false;
        }
      );
    }
  };
}
