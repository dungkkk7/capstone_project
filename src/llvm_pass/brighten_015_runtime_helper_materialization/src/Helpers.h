#pragma once

#include <cstdint>
#include <optional>
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/GlobalValue.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"

namespace brighten_runtime {

bool IsRemillDecl(const llvm::Function &F);
bool HasPrefixAny(llvm::StringRef Name, llvm::ArrayRef<llvm::StringRef> Prefixes);
std::optional<uint64_t> ParseHexAtStart(llvm::StringRef S);
std::optional<uint64_t> ParseAddressName(llvm::StringRef Name);
uint64_t ResolveGuestAddress(llvm::GlobalValue *GV);
bool HasMemoryThreadingSignature(const llvm::Function &F);
llvm::Value *FindLikelyMemoryArg(llvm::Function &F);
llvm::Constant *ZeroValue(llvm::Type *Ty);
llvm::Value *CastAddressToI64(llvm::IRBuilder<> &B, llvm::Value *Addr);
llvm::Function *GetOrCreateTranslateGuestPointer(llvm::Module &M);

}  // namespace brighten_runtime
