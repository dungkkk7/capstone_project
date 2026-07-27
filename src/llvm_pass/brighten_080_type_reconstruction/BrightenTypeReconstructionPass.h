#ifndef BRIGHTEN_080_TYPE_RECONSTRUCTION_PASS_H
#define BRIGHTEN_080_TYPE_RECONSTRUCTION_PASS_H

#include "TypeReconstructionContext.h"
#include "llvm/IR/PassManager.h"

namespace brighten_type {

class BrightenTypeReconstructionPass
    : public llvm::PassInfoMixin<BrightenTypeReconstructionPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

class BrightenStructRecoverPass
    : public llvm::PassInfoMixin<BrightenStructRecoverPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

class BrightenArrayRecoverPass
    : public llvm::PassInfoMixin<BrightenArrayRecoverPass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

// Internal engine function
bool RunTypeReconstruction(llvm::Module &M, TypeMode Mode, bool OnlyStruct, bool OnlyArray);

// Recover exact native pointer provenance hidden behind pointer-sized integer
// round trips before aggregate type inference inspects the remaining accesses.
bool RecoverNativePointerIntegerRoundTrips(
    llvm::Module &M, llvm::ModuleAnalysisManager &AM);

// Proof-only canonicalization for modular affine address arithmetic used as a
// GEP index.  It deliberately does not recover arbitrary inttoptr/resolver
// expressions: cancellation is valid only after proving that the root pointer
// is neither undef nor poison at the use and that its integer bits are not
// observed anywhere else.
bool CanonicalizeAddresses(
    llvm::Module &M, llvm::ModuleAnalysisManager &AM);

// Collapse a fully validated guest-address resolver only when its fallback is
// derived from a non-null, noalias allocation result.  Static-image arms are
// then unreachable by allocation provenance; the replacement is a non-
// inbounds GEP so this pass never adds a bounds or lifetime assumption.
bool CollapseHeapProvenPointerResolvers(
    llvm::Module &M, llvm::ModuleAnalysisManager &AM);


class BrightenAddressCanonicalizePass
    : public llvm::PassInfoMixin<BrightenAddressCanonicalizePass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

class BrightenHeapProvenResolverCollapsePass
    : public llvm::PassInfoMixin<BrightenHeapProvenResolverCollapsePass> {
public:
  llvm::PreservedAnalyses run(llvm::Module &M,
                              llvm::ModuleAnalysisManager &AM);
};

} // namespace brighten_type

#endif
