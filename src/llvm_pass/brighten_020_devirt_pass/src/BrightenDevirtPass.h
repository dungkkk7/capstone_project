#ifndef BRIGHTEN_DEVIRT_PASS_H
#define BRIGHTEN_DEVIRT_PASS_H

#include "llvm/IR/PassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Value.h"
#include <optional>

namespace brighten_devirt {

class BrightenDevirtPass : public llvm::PassInfoMixin<BrightenDevirtPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);

  static bool LowerExternalCalls(llvm::Module &M);
  static bool DevirtualizeRemillFunctionCalls(llvm::Module &M);
  static bool DevirtualizeRemillJumps(llvm::Module &M);
  static bool AnnotateRemillReturns(llvm::Module &M);
  static bool CleanupCallbackThunks(llvm::Module &M);
  static bool CleanupUnusedRemillDispatchers(llvm::Module &M);
  static bool LowerProvenConstantStateSwitches(llvm::Module &M);
  static bool LowerRegionSSAStateSwitches(llvm::Module &M);
  static bool VerifyDevirtualization(llvm::Module &M);
};

class BrightenRegionSSAUnflattenPass
    : public llvm::PassInfoMixin<BrightenRegionSSAUnflattenPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

// Target discovery and PC resolution helpers
std::optional<uint64_t> ParseAddressName(llvm::StringRef Name);
std::optional<uint64_t> ExtractConstantPC(llvm::Value *V, const llvm::DataLayout &DL);
llvm::Function *FindLiftedSubroutineByPC(llvm::Module &M, uint64_t PC);
llvm::Function *FindExternalFunctionByPC(llvm::Module &M, uint64_t PC);
llvm::Function *ResolveExternalFunction(llvm::Module &M, llvm::Value *PCVal, const llvm::DataLayout &DL);
llvm::Function *GetTranslateGuestPointerIfDefined(llvm::Module &M);
llvm::Function *ResolveCalledFunction(llvm::Value *Callee);
bool LowerFiniteRemillPCSwitch(llvm::Module &M, llvm::CallInst *CI,
                               llvm::Function *Dispatcher, bool IsJump);

} // namespace brighten_devirt

#endif // BRIGHTEN_DEVIRT_PASS_H
