#ifndef BRIGHTEN_050_ABI_ANALYSIS_H
#define BRIGHTEN_050_ABI_ANALYSIS_H

#include "ABIModel.h"
#include "RegisterAccess.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ValueMap.h"

#include <map>
#include <memory>
#include <set>
#include <string>

namespace brighten_abi {

struct ABIArgInfo {
  ABIReg Reg = ABIReg::Unknown;
  llvm::Type *Ty = nullptr;
  bool LiveIn = false;
  bool CallsiteEvidence = false;
  unsigned LoadCount = 0;
  unsigned StoreEvidenceCount = 0;
};

struct CallsiteABIInfo {
  llvm::CallInst *Call = nullptr;
  llvm::Function *Caller = nullptr;
  llvm::Function *Target = nullptr;
  std::map<ABIReg, llvm::Value *> StoredArgs;
  std::map<ABIReg, llvm::Type *> ArgTypes;
  bool ObservesRAX = false;
  bool ObservesRDX = false;
  bool ObservesXMM0 = false;
  bool RewritableMemoryResult = false;
  bool Rewritten = false;
};

struct FunctionABISummary {
  llvm::Function *OriginalFn = nullptr;
  llvm::Function *RemillFn = nullptr;
  llvm::Function *NativeFn = nullptr;
  llvm::Function *WrapperFn = nullptr;
  std::string OriginalName;
  llvm::GlobalValue::LinkageTypes OriginalLinkage =
      llvm::GlobalValue::InternalLinkage;

  bool Eligible = false;
  bool SkipNative = false;
  bool Cloned = false;
  bool NativeBodyRewritten = false;
  bool WrapperCreated = false;
  bool HasForbiddenInlineAsm = false;
  bool Recursive = false;
  bool AddressTaken = false;
  bool DynamicUse = false;
  bool ReturnsOriginalMemoryArg = false;
  std::string SkipReason;

  bool HiddenState = false;
  bool HiddenPC = false;
  bool HiddenMemory = false;

  std::set<ABIReg> LiveIns;
  std::map<ABIReg, llvm::Type *> LiveInTypes;
  std::map<ABIReg, unsigned> LiveInLoadCounts;
  std::set<ABIReg> LiveOutStores;
  std::map<ABIReg, llvm::Type *> CallsiteArgTypes;
  llvm::SmallVector<ABIArgInfo, 8> Args;
  llvm::SmallVector<CallsiteABIInfo, 16> Calls;

  ReturnKind RetKind = ReturnKind::Void;
  llvm::Type *RetTy = nullptr;
  bool HasReturnMetadata = false;
  bool HasRAXStoreBeforeReturn = false;
  bool HasCompleteReturnValues = false;
  bool HasCompleteRDXValues = false;
  bool HasCompleteXMM0Values = false;
  bool ReturnObservedByCaller = false;
  bool ReturnRDXObservedByCaller = false;
  bool ReturnXMM0ObservedByCaller = false;
  bool XMM0ReturnDerivedFromRAX = false;
  ReturnKind XMM0ReturnKind = ReturnKind::Unknown;
  // A SysV i128 return is justified only when one callsite observes both
  // physical return registers.  Aggregating independent RAX and RDX uses
  // from different callsites fabricates a composite return ABI.
  bool ReturnRDXRAXObservedBySameCallsite = false;
};

struct ABIRecoveryContext {
  llvm::Module &M;
  const llvm::DataLayout &DL;
  bool Debug = true;

  llvm::DenseMap<llvm::Function *, std::unique_ptr<FunctionABISummary>>
      OwnedSummaries;
  llvm::SmallVector<FunctionABISummary *, 32> Summaries;

  explicit ABIRecoveryContext(llvm::Module &Mod)
      : M(Mod), DL(Mod.getDataLayout()) {}
};

bool LooksLikeRemillFunction(llvm::Function &F);
bool IsEligibleRemillFunction(llvm::Function &F);
bool HasForbiddenInlineAsm(llvm::Function &F);
llvm::Function *ResolveCalledFunction(llvm::Value *Callee);
FunctionABISummary *FindSummary(ABIRecoveryContext &Ctx, llvm::Function *F);
FunctionABISummary *FindSummaryByOriginalName(ABIRecoveryContext &Ctx,
                                              llvm::StringRef Name);

llvm::Type *MergeABIType(llvm::Type *A, llvm::Type *B,
                         const llvm::DataLayout &DL);
llvm::Value *CoerceValue(llvm::IRBuilder<> &B, llvm::Value *V,
                         llvm::Type *DstTy, llvm::Twine Name = "");

llvm::Value *FindRegisterValueBeforeReturn(llvm::ReturnInst *RI, ABIReg Reg);
bool ReturnOperandIsOriginalMemoryArg(llvm::Function &F, llvm::ReturnInst &RI);

void DebugCandidate(FunctionABISummary &S);
void DebugLiveIns(FunctionABISummary &S);
void DebugReturn(FunctionABISummary &S);

} // namespace brighten_abi

#endif
