#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/GlobalAlias.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include <optional>
#include <string>
#include <cstdlib>

using namespace llvm;

namespace {

struct AliasKey {
  std::string name;
  std::string reg;
  int64_t offset = 0;

  bool operator==(const AliasKey &Other) const {
    return name == Other.name;
  }
};

struct LastStore {
  Value *Val;
  Type *Ty;
};

} // namespace

namespace llvm {

template <> struct DenseMapInfo<AliasKey> {
  static inline AliasKey getEmptyKey() {
    return AliasKey{"", "", 0};
  }
  static inline AliasKey getTombstoneKey() {
    return AliasKey{"<tombstone>", "", 0};
  }
  static unsigned getHashValue(const AliasKey &Val) {
    return DenseMapInfo<StringRef>::getHashValue(Val.name);
  }
  static bool isEqual(const AliasKey &LHS, const AliasKey &RHS) {
    return LHS == RHS;
  }
};

} // namespace llvm

namespace {

bool IsKnownStateReg(StringRef Reg) {
  return Reg == "RAX" || Reg == "RBX" || Reg == "RCX" || Reg == "RDX" ||
         Reg == "RSI" || Reg == "RDI" || Reg == "RBP" || Reg == "RSP" ||
         Reg == "R8"  || Reg == "R9"  || Reg == "R10" || Reg == "R11" ||
         Reg == "R12" || Reg == "R13" || Reg == "R14" || Reg == "R15" ||
         Reg == "RIP" || Reg == "CF"  || Reg == "PF"  || Reg == "AF"  ||
         Reg == "ZF"  || Reg == "SF"  || Reg == "OF"  || Reg == "DF";
}

bool TraceEnabled() {
  return std::getenv("REMILL_STATE_FORWARD_TRACE") != nullptr;
}

std::optional<AliasKey> ClassifyStateAlias(Value *V) {
  if (!V) return std::nullopt;
  Value *Stripped = V->stripPointerCasts();
  auto *Alias = dyn_cast_or_null<GlobalAlias>(Stripped);
  if (!Alias) return std::nullopt;

  StringRef Name = Alias->getName();
  size_t Pos = Name.find('_');
  if (Pos == StringRef::npos) return std::nullopt;

  StringRef Prefix = Name.take_front(Pos);
  if (!IsKnownStateReg(Prefix)) return std::nullopt;

  size_t NextPos = Name.find('_', Pos + 1);
  if (NextPos == StringRef::npos) return std::nullopt;

  StringRef Slice = Name.slice(Pos + 1, NextPos);
  if (Slice.empty()) return std::nullopt;

  long Val = 0;
  if (Slice.getAsInteger(10, Val)) {
    return std::nullopt;
  }

  AliasKey Key;
  Key.name = (Prefix + "_" + Slice).str();
  Key.reg = Prefix.str();
  Key.offset = 0;
  return Key;
}

Value *CastStoredValue(IRBuilder<> &Builder, Value *Val, Type *DestTy) {
  Type *SrcTy = Val->getType();
  if (SrcTy == DestTy) {
    return Val;
  }
  if (SrcTy->isPointerTy() && DestTy->isIntegerTy()) {
    return Builder.CreatePtrToInt(Val, DestTy, Val->getName() + ".ptrint");
  }
  if (SrcTy->isIntegerTy() && DestTy->isPointerTy()) {
    return Builder.CreateIntToPtr(Val, DestTy, Val->getName() + ".intptr");
  }
  auto *SrcIntTy = dyn_cast<IntegerType>(SrcTy);
  auto *DestIntTy = dyn_cast<IntegerType>(DestTy);
  if (SrcIntTy && DestIntTy) {
    unsigned SrcBits = SrcIntTy->getBitWidth();
    unsigned DestBits = DestIntTy->getBitWidth();
    if (SrcBits > DestBits) {
      return Builder.CreateTrunc(Val, DestTy, Val->getName() + ".trunc");
    } else {
      return Builder.CreateZExt(Val, DestTy, Val->getName() + ".zext");
    }
  }
  return nullptr;
}

bool IsBarrierCall(CallBase &Call) {
  return !isa<DbgInfoIntrinsic>(&Call);
}

bool ForwardFunction(Function &F) {
  if (F.isDeclaration() || F.empty()) {
    return false;
  }

  bool Changed = false;
  int32_t NumLoadsReplaced = 0;
  SmallVector<Instruction *, 32> ToErase;

  for (BasicBlock &BB : F) {
    DenseMap<AliasKey, LastStore> LastStores;
    for (Instruction &I : BB) {
      if (auto *Load = dyn_cast<LoadInst>(&I)) {
        if (Load->isVolatile() || Load->isAtomic()) {
          LastStores.clear();
        } else {
          Value *Ptr = Load->getPointerOperand();
          if (auto Key = ClassifyStateAlias(Ptr)) {
            auto It = LastStores.find(*Key);
            if (It != LastStores.end()) {
              IRBuilder<> Builder(Load);
              Value *StoredValue = It->second.Val;
              Value *CastValue = CastStoredValue(Builder, StoredValue, Load->getType());
              if (CastValue) {
                Load->replaceAllUsesWith(CastValue);
                ToErase.push_back(Load);
                Changed = true;
                NumLoadsReplaced++;
              }
            }
          }
        }
      } else if (auto *Store = dyn_cast<StoreInst>(&I)) {
        if (Store->isVolatile() || Store->isAtomic()) {
          LastStores.clear();
        } else {
          Value *Ptr = Store->getPointerOperand();
          if (auto Key = ClassifyStateAlias(Ptr)) {
            Value *ValOp = Store->getValueOperand();
            LastStores[*Key] = {ValOp, ValOp->getType()};
          } else {
            LastStores.clear();
          }
        }
      } else if (auto *Call = dyn_cast<CallBase>(&I)) {
        if (IsBarrierCall(*Call)) {
          LastStores.clear();
        }
      } else {
        if (I.mayWriteToMemory()) {
          LastStores.clear();
        }
      }
    }
  }

  for (Instruction *I : ToErase) {
    I->eraseFromParent();
  }

  if (Changed && TraceEnabled()) {
    errs() << "brighten-state-forward-pass function=" << F.getName()
           << " loads=" << NumLoadsReplaced << "\n";
  }

  return Changed;
}

struct BrightenStateForwardPass : public PassInfoMixin<BrightenStateForwardPass> {
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
    bool Changed = false;
    for (Function &F : M) {
      Changed |= ForwardFunction(F);
    }
    return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
  }
};

} // namespace

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
  return {
    LLVM_PLUGIN_API_VERSION,
    "BrightenStateForwardPass",
    "0.1.0",
    [](PassBuilder &PB) {
      PB.registerPipelineParsingCallback(
        [](StringRef Name, ModulePassManager &MPM, ArrayRef<PassBuilder::PipelineElement>) {
          if (Name == "brighten-state-forward-pass") {
            MPM.addPass(BrightenStateForwardPass());
            return true;
          }
          return false;
        }
      );
    }
  };
}
