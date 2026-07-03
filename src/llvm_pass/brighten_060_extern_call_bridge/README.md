# Phase 6: External Call / Libc ABI Recovery Pass

**Pass name:** `brighten-extern-call-bridge`

## Overview

Conservative production-grade external/libc call recovery pass. Rewrites proven-safe libc callsites from Remill `__remill_function_call` form to native LLVM calls. Preserves unsafe/ambiguous cases with actionable diagnostics.

## Pipeline

```
DiscoverExternalSymbols → AnalyzeExternalCallsites → RecoverLibcArguments →
RecoverVarargArguments → RewriteExternalCallsites → RewriteExternalReturns →
CleanupExternalCallArtifacts → VerifyExternalCallRecovery →
PrintExternalCallRecoveryReport
```

## Recovery Modes

- **NativeStrict** (default): Only rewrites when all pointer arguments have proven native provenance. No `__translate_guest_pointer` calls.
- **CompatFallback**: May use `__translate_guest_pointer` for guest addresses, but reports every fallback translation.

## Supported External Symbols

### Non-vararg
`puts`, `strlen`, `strcmp`, `strncmp`, `strcpy`, `strncpy`, `strcat`, `strncat`, `memcpy`, `memmove`, `memset`, `memcmp`, `malloc`, `calloc`, `realloc`, `free`, `exit`, `atoi`, `atol`, `atoll`, `abs`, `labs`

### Vararg (format-string recovery)
`printf`, `fprintf`, `sprintf`, `snprintf`, `scanf`, `fscanf`, `sscanf`, `__isoc99_scanf`, `__isoc99_sscanf`, `__isoc99_fscanf`

## External Symbol Discovery Patterns

1. `__remill_function_call` with `ptrtoint(@printf)`
2. `__remill_function_call` with constant guest PC → symbol mapping
3. `ext_ADDR_name` stub functions (e.g. `ext_401030_printf`)
4. `.remill` wrapper functions containing known libc calls

## Pointer Provenance Classification

- `NativeGlobalString` — constant global data arrays
- `NativeGlobalObject` — non-constant globals
- `NativeStackObject` — alloca instructions
- `NativeHeapObject` — malloc/calloc/realloc returns
- `GuestAddressConstant` — inttoptr of constant
- `GuestAddressDynamic` — inttoptr of dynamic value
- `Unknown` — unclassifiable

## Skip Reasons

Every preserved callsite has an actionable skip reason:
`unresolved-external-target`, `unsupported-libc-symbol`, `unsupported-abi`, `unsupported-vararg-format`, `format-not-constant`, `arg-provenance-unknown`, `arg-type-conflict`, `stack-arg-unavailable`, `xmm-arg-unavailable`, `memory-result-use-unsafe`, `external-declaration-conflict`, `writes-unknown-guest-memory`

## Build

```bash
mkdir build && cd build
cmake .. -DLLVM_DIR=$(llvm-config --cmakedir)
make
```

## Usage

```bash
opt -load-pass-plugin=build/BrightenExternCallBridgePass.so \
    -passes=brighten-extern-call-bridge -S input.ll
```

## Architecture

x86_64 System V ABI only (integer args: RDI/RSI/RDX/RCX/R8/R9, float args: XMM0-7, return: RAX/XMM0).
