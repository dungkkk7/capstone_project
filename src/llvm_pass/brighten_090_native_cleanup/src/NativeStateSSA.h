#ifndef BRIGHTEN_NATIVE_STATE_SSA_H
#define BRIGHTEN_NATIVE_STATE_SSA_H

#include "llvm/IR/Module.h"

namespace brighten_native_cleanup {

// Replace the remaining internal `.native(ptr state, ...)` ABI with explicit
// state-slot arguments and an aggregate of state-slot outputs.  This is kept
// separate from artifact cleanup because it is a semantic ABI transformation.
bool lowerNativeStateABI(llvm::Module &M);

// Remove the entrypoint's byte-addressed CPU-State scratch buffer after all
// native calls have been rewritten to explicit arguments/results.
bool lowerNativeMainStateBuffer(llvm::Module &M);

// Replace the legacy multi-megabyte guest-stack scratch allocation with a
// bounded native stack allocation used only as storage for recovered frames.
bool lowerNativeMainStackBuffer(llvm::Module &M);

// Turn constant-offset addresses derived from recovered RSP/RBP values into
// native pointer GEPs instead of repeated integer guest-address round trips.
bool lowerNativeStackAddresses(llvm::Module &M);

// Delete dead arithmetic and address scaffolding exposed by the ABI/stack
// rewrites without applying a whole-module optimizer that can invent poison
// for unresolved lifted branches.
bool cleanupNativeDeadInstructions(llvm::Module &M);

} // namespace brighten_native_cleanup

#endif
