#ifndef BRIGHTEN_060_EXTERN_CALL_CONTEXT_H
#define BRIGHTEN_060_EXTERN_CALL_CONTEXT_H

#include "LibcSignatureDB.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

namespace brighten_extern {

enum class ExternRecoveryMode {
  NativeStrict,
  CompatFallback,
};

enum class PointerProvenance {
  NativeGlobalString,
  NativeGlobalObject,
  NativeStackObject,
  NativeHeapObject,
  GuestAddressConstant,
  GuestAddressDynamic,
  Unknown,
};

struct ExternCallTarget {
  llvm::Function *ExtFn = nullptr;
  std::string SymbolName;
  const LibcSignature *Signature = nullptr;
  bool Resolved = false;
  std::string UnresolvedReason;
};

struct RecoveredArg {
  llvm::Value *Val = nullptr;
  llvm::Type *Ty = nullptr;
  PointerProvenance Provenance = PointerProvenance::Unknown;
  bool IsWritePointer = false;
  bool IsFallbackTranslated = false;
  bool IsValid = false;
  std::string SkipReason;
};

struct VarargInfo {
  bool FormatResolved = false;
  std::string FormatString;
  llvm::SmallVector<VarargSpecifier, 16> Specifiers;
  unsigned IntRegIndex = 0;
  unsigned XmmRegIndex = 0;
  unsigned StackArgIndex = 0;
};

struct ExternCallsite {
  llvm::CallInst *OrigCall = nullptr;
  llvm::Function *Caller = nullptr;
  ExternCallTarget Target;

  llvm::SmallVector<RecoveredArg, 8> Args;
  VarargInfo Vararg;

  bool Rewritten = false;
  bool FallbackUsed = false;
  std::string Action;
  std::string SkipReason;
};

struct ExternCallReport {
  unsigned Discovered = 0;
  unsigned RewrittenNative = 0;
  unsigned RewrittenCompat = 0;
  unsigned Preserved = 0;
  unsigned VarargRecovered = 0;
  unsigned FormatStringsRecovered = 0;
  unsigned PointerArgsNative = 0;
  unsigned PointerArgsFallback = 0;
  unsigned VerifierErrors = 0;
  std::vector<std::string> Details;
};

struct ExternCallContext {
  llvm::Module &M;
  const llvm::DataLayout &DL;
  ExternRecoveryMode Mode = ExternRecoveryMode::NativeStrict;
  bool Debug = true;

  LibcSignatureDB SigDB;
  llvm::SmallVector<std::unique_ptr<ExternCallsite>, 64> Callsites;
  ExternCallReport Report;

  llvm::Function *TranslateFn = nullptr;

  explicit ExternCallContext(llvm::Module &Mod)
      : M(Mod), DL(Mod.getDataLayout()) {}
};

} // namespace brighten_extern

#endif
