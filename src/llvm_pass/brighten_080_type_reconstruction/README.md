# Phase 8 — Type Reconstruction Pass

This pass implements high-level type reconstruction for stack objects (`alloca`) and global variables, raising raw `[N x i8]` byte arrays or integer-based overlays into proper named LLVM structs and typed arrays, and rewriting memory accesses to use typed GetElementPtr (GEP) instructions.

## Passes Registered
* `brighten-type-reconstruct` (aggregate discovery, inference, rewrite, and verification pass)
* `brighten-struct-recover` (standalone struct recovery)
* `brighten-array-recover` (standalone array recovery)

## Build Instructions
From the repository root:
```bash
cd src/llvm_pass/brighten_080_type_reconstruction
mkdir -p build
cd build
cmake ..
make -j
```

## Options
* `-brighten-type-mode=conservative|balanced|aggressive` (Default: `conservative`)
* `-brighten-type-min-confidence=<integer>` (Default: `0`)
* `-brighten-type-max-depth=<integer>` (Default: `4`)
* `-brighten-type-min-array-elements=<integer>` (Default: `2`)
* `-brighten-type-report=<path>` (Path to write JSON execution summary)
* `-brighten-type-verify` (Run verifier after transformation)
* `-brighten-type-dump-rejections` (Print details of rejected candidates to stderr)

## Pipeline Example
```bash
opt-21 -load-pass-plugin=build/BrightenTypeReconstructionPass.so \
  -passes='brighten-type-reconstruct,verify' \
  input.ll -S -o output.ll
```

## Known Conservative Limitations
* Objects that escape to un-analyzable external function calls are rejected in conservative mode.
* Overlapping field accesses (e.g. type conflicts) are rejected in conservative mode, and fallback to `[N x i8]` blob segments in balanced mode.
* PHI/Select node tracking is conservative; when pointer provenance is mixed or ambiguous, the object is marked as escaped.
