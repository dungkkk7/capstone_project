#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Operator.h"
#include <string>
#include <vector>
#include <set>
#include <map>
#include <algorithm>

using namespace llvm;

namespace {

// Resolve a pointer to its State byte offset relative to arg 0.
int64_t resolveStateOffset(Value *ptr, const DataLayout &DL) {
  int64_t total_offset = 0;
  Value *base = ptr;

  int limit = 100;
  while (limit-- > 0) {
    if (auto *GA = dyn_cast<GlobalAlias>(base)) {
      base = GA->getAliasee();
      continue;
    }
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
    break;
  }

  if (auto *arg = dyn_cast<Argument>(base)) {
    if (arg->getArgNo() == 0 && total_offset >= 0) {
      return total_offset;
    }
  }

  if (auto *GV = dyn_cast<GlobalValue>(base)) {
    if (GV->hasName()) {
      StringRef Name = GV->getName();
      if (Name == "__mcsema_reg_state" || Name.contains("reg_state")) {
        if (total_offset >= 0) {
          return total_offset;
        }
      }
      // Parse offset from name: e.g. RDI_2296_xxxx or RDI_2296
      size_t FirstUnderscore = Name.find('_');
      if (FirstUnderscore != StringRef::npos) {
        size_t SecondUnderscore = Name.find('_', FirstUnderscore + 1);
        StringRef OffsetPart;
        if (SecondUnderscore != StringRef::npos) {
          OffsetPart = Name.slice(FirstUnderscore + 1, SecondUnderscore);
        } else {
          OffsetPart = Name.substr(FirstUnderscore + 1);
        }
        if (!OffsetPart.empty()) {
          int64_t OffsetVal = 0;
          if (!OffsetPart.getAsInteger(10, OffsetVal)) {
            if (OffsetVal >= 0 && total_offset >= 0) {
              return OffsetVal + total_offset;
            }
          }
        }
      }
    }
  }

  return -1;
}

// Compute live-in and live-out offsets for a function F
void computeLiveness(Function &F, const DataLayout &DL,
                     std::set<unsigned> &entry_live_in,
                     std::set<unsigned> &live_out) {
  std::set<unsigned> written_in_entry;
  std::set<unsigned> ever_written;

  // Entry block: track read-before-write
  if (!F.empty()) {
    for (auto &I : F.getEntryBlock()) {
      if (auto *LI = dyn_cast<LoadInst>(&I)) {
        int64_t off = resolveStateOffset(LI->getPointerOperand(), DL);
        if (off >= 0) {
          unsigned u = static_cast<unsigned>(off);
          if (!written_in_entry.count(u)) {
            entry_live_in.insert(u);
          }
        }
      }
      if (auto *SI = dyn_cast<StoreInst>(&I)) {
        int64_t off = resolveStateOffset(SI->getPointerOperand(), DL);
        if (off >= 0) {
          unsigned u = static_cast<unsigned>(off);
          written_in_entry.insert(u);
          ever_written.insert(u);
        }
      }
    }
  }

  // Other blocks: track writes to determine live-out registers
  for (auto &BB : F) {
    for (auto &I : BB) {
      if (auto *SI = dyn_cast<StoreInst>(&I)) {
        int64_t off = resolveStateOffset(SI->getPointerOperand(), DL);
        if (off >= 0) {
          ever_written.insert(static_cast<unsigned>(off));
        }
      }
    }
  }

  live_out = ever_written;
}

struct FunctionABI {
  unsigned NumParams = 0;
  bool HasReturn = false;
  std::vector<unsigned> ParamOffsets;
  unsigned ReturnOffset = 2216; // RAX
};

Value *BuildStateLoad(IRBuilder<> &Builder, Value *StatePtr, unsigned Offset) {
  Value *GEP = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StatePtr, Offset);
  return Builder.CreateLoad(Builder.getInt64Ty(), GEP);
}

void BuildStateStore(IRBuilder<> &Builder, Value *StatePtr, unsigned Offset, Value *Val) {
  Value *GEP = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StatePtr, Offset);
  Builder.CreateStore(Val, GEP);
}

struct BrightenInternalCallArgifyPass : public PassInfoMixin<BrightenInternalCallArgifyPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    const DataLayout &DL = M.getDataLayout();
    
    // Look up the State struct type once
    StructType *StateTy = StructType::getTypeByName(M.getContext(), "struct.State");

    // Map register offsets to global variable / alias pointers
    std::map<int64_t, GlobalValue *> OffsetToGlobal;
    for (GlobalVariable &GV : M.globals()) {
      int64_t off = resolveStateOffset(&GV, DL);
      if (off > 0) {
        OffsetToGlobal[off] = &GV;
      }
    }
    for (GlobalAlias &GA : M.aliases()) {
      int64_t off = resolveStateOffset(&GA, DL);
      if (off > 0) {
        OffsetToGlobal[off] = &GA;
      }
    }

    // Standard x86_64 calling convention parameter registers
    const std::vector<unsigned> x86_64_param_offsets = { 2296, 2280, 2264, 2248, 2344, 2360 }; // RDI, RSI, RDX, RCX, R8, R9
    const unsigned RAX_OFFSET = 2216;

    std::vector<Function *> LiftedFunctions;
    for (Function &F : M) {
      if (F.isDeclaration() || F.empty()) continue;
      // Process functions starting with "sub_" or "callback_" that don't have wrappers yet
      if ((F.getName().starts_with("sub_") || F.getName().starts_with("callback_")) && 
          !F.getName().ends_with("_native")) {
        LiftedFunctions.push_back(&F);
      }
    }

    bool Changed = false;

    for (Function *F : LiftedFunctions) {
      std::set<unsigned> entry_live_in;
      std::set<unsigned> live_out;
      computeLiveness(*F, DL, entry_live_in, live_out);

      errs() << "argify: function=" << F->getName() << "\n";
      errs() << "  entry_live_in:";
      for (unsigned u : entry_live_in) errs() << " " << u;
      errs() << "\n  live_out:";
      for (unsigned u : live_out) errs() << " " << u;
      errs() << "\n";

      FunctionABI ABI;
      // Score sequential GPR parameters
      for (unsigned i = 0; i < x86_64_param_offsets.size(); ++i) {
        if (entry_live_in.count(x86_64_param_offsets[i])) {
          ABI.NumParams = i + 1;
        } else {
          break;
        }
      }
      for (unsigned i = 0; i < ABI.NumParams; ++i) {
        ABI.ParamOffsets.push_back(x86_64_param_offsets[i]);
      }

      // Check return register (RAX)
      if (live_out.count(RAX_OFFSET)) {
        ABI.HasReturn = true;
      }

      // Create native wrapper
      LLVMContext &Ctx = M.getContext();
      Type *RetTy = ABI.HasReturn ? Type::getInt64Ty(Ctx) : Type::getVoidTy(Ctx);
      std::vector<Type *> ParamTypes(ABI.NumParams, Type::getInt64Ty(Ctx));
      FunctionType *FTy = FunctionType::get(RetTy, ParamTypes, false);
      std::string NativeName = F->getName().str() + "_native";

      // If native wrapper already exists, skip
      if (M.getFunction(NativeName)) continue;

      Function *NativeF = Function::Create(FTy, Function::ExternalLinkage, NativeName, M);
      NativeF->addFnAttr(Attribute::MustProgress);
      NativeF->addFnAttr(Attribute::NoUnwind);
      if (F->hasFnAttribute("omill.output_root")) {
        NativeF->addFnAttr("omill.output_root");
      }

      BasicBlock *Entry = BasicBlock::Create(Ctx, "entry", NativeF);
      IRBuilder<> Builder(Entry);

      // Allocate local state struct (used as a dummy parameter for original function call)
      Value *StateAlloca;
      if (StateTy) {
        StateAlloca = Builder.CreateAlloca(StateTy, nullptr, "state");
        uint64_t StateSize = DL.getTypeAllocSize(StateTy);
        Builder.CreateMemSet(StateAlloca, Builder.getInt8(0), StateSize, MaybeAlign(16));
      } else {
        Type *RawTy = ArrayType::get(Builder.getInt8Ty(), 4096);
        StateAlloca = Builder.CreateAlloca(RawTy, nullptr, "state_raw");
        Builder.CreateMemSet(StateAlloca, Builder.getInt8(0), 4096, MaybeAlign(16));
      }

      // Allocate synthetic stack: 64KB + 4KB
      uint64_t TotalStackSize = 65536 + 4096;
      Type *StackTy = ArrayType::get(Builder.getInt8Ty(), TotalStackSize);
      Value *StackAlloca = Builder.CreateAlloca(StackTy, nullptr, "native_stack");
      Builder.CreateMemSet(StackAlloca, Builder.getInt8(0xCC), TotalStackSize, MaybeAlign(16));

      Value *StackTop = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StackAlloca, 65536 - 32);
      Value *StackTopI64 = Builder.CreatePtrToInt(StackTop, Builder.getInt64Ty());

      // Store stack top to RSP (2312) and RBP (2328) in the dummy State
      Value *RSPPtr = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StateAlloca, 2312);
      Builder.CreateStore(StackTopI64, RSPPtr);
      Value *RBPPtr = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StateAlloca, 2328);
      Builder.CreateStore(StackTopI64, RBPPtr);

      // Copy GPR arguments directly to local state alloca and global register aliases / variables
      errs() << "argify: function=" << NativeF->getName() << " num_params=" << ABI.NumParams << "\n";
      for (unsigned i = 0; i < ABI.NumParams; ++i) {
        Value *ArgVal = NativeF->getArg(i);

        // 1. Store to local StateAlloca at the offset
        Value *LocalRegPtr = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StateAlloca, ABI.ParamOffsets[i]);
        Value *LocalStore = Builder.CreateStore(ArgVal, LocalRegPtr);
        errs() << "argify: created local store: " << *LocalStore << "\n";
      }

      // Prepare arguments for original lifted function
      FunctionType *LiftedTy = F->getFunctionType();
      std::vector<Value *> CallArgs;
      if (LiftedTy->getNumParams() > 0) {
        CallArgs.push_back(StateAlloca);
      }

      if (LiftedTy->getNumParams() > 1) {
        uint64_t EntryVA = 0;
        std::string NameStr = F->getName().str();
        size_t Underscore = NameStr.find('_');
        if (Underscore != std::string::npos) {
          std::string HexStr = NameStr.substr(Underscore + 1);
          size_t Dot = HexStr.find('.');
          if (Dot != std::string::npos) HexStr = HexStr.substr(0, Dot);
          for (char c : HexStr) {
            if (c >= '0' && c <= '9') {
              EntryVA = (EntryVA << 4) | (c - '0');
            } else if (c >= 'a' && c <= 'f') {
              EntryVA = (EntryVA << 4) | (c - 'a' + 10);
            } else if (c >= 'A' && c <= 'F') {
              EntryVA = (EntryVA << 4) | (c - 'A' + 10);
            } else {
              break;
            }
          }
        }
        CallArgs.push_back(Builder.getInt64(EntryVA));
      }

      if (LiftedTy->getNumParams() > 2) {
        CallArgs.push_back(Constant::getNullValue(LiftedTy->getParamType(2)));
      }

      Builder.CreateCall(F, CallArgs);

      // Load return value directly from local StateAlloca or return void
      if (ABI.HasReturn) {
        Value *RetPtr = Builder.CreateConstGEP1_64(Builder.getInt8Ty(), StateAlloca, RAX_OFFSET);
        Value *RetVal = Builder.CreateLoad(Type::getInt64Ty(Ctx), RetPtr, "retval");
        Builder.CreateRet(RetVal);
      } else {
        Builder.CreateRetVoid();
      }

      // Rewrite call sites
      std::vector<User *> Users(F->user_begin(), F->user_end());
      for (User *U : Users) {
        if (auto *CI = dyn_cast<CallInst>(U)) {
          if (CI->getCalledFunction() == F) {
            if (CI->getFunction() == NativeF) {
              continue;
            }
            IRBuilder<> CallBuilder(CI);
            Value *StatePtr = CI->getArgOperand(0);

            std::vector<Value *> Args;
            for (unsigned offset : ABI.ParamOffsets) {
              Args.push_back(BuildStateLoad(CallBuilder, StatePtr, offset));
            }

            Value *CallResult = CallBuilder.CreateCall(NativeF, Args);

            if (ABI.HasReturn) {
              BuildStateStore(CallBuilder, StatePtr, RAX_OFFSET, CallResult);
            }

            // Emulate stack pointer adjustment (+8) for caller
            Value *SP = BuildStateLoad(CallBuilder, StatePtr, 2312);
            Value *NewSP = CallBuilder.CreateAdd(SP, CallBuilder.getInt64(8));
            BuildStateStore(CallBuilder, StatePtr, 2312, NewSP);

            if (!CI->getType()->isVoidTy()) {
              if (CI->arg_size() > 2) {
                CI->replaceAllUsesWith(CI->getArgOperand(2));
              } else {
                CI->replaceAllUsesWith(UndefValue::get(CI->getType()));
              }
            }
            CI->eraseFromParent();
          }
        }
      }

      // Internalize original function and mark as always-inline
      F->setLinkage(GlobalValue::InternalLinkage);
      F->removeFnAttr(Attribute::OptimizeNone);
      F->removeFnAttr(Attribute::NoInline);
      F->addFnAttr(Attribute::AlwaysInline);

      Changed = true;
    }

    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
    LLVM_PLUGIN_API_VERSION,
    "BrightenInternalCallArgifyPass",
    LLVM_VERSION_STRING,
    [](PassBuilder &PB) {
      PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "brighten-internal-call-argify-pass") {
            MPM.addPass(BrightenInternalCallArgifyPass());
            return true;
          }
          return false;
        }
      );
    }
  };
}
