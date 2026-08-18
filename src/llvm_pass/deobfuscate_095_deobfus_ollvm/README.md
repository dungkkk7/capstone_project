# LLVM deobfuscation pass 095

`lib095.so` is an LLVM 21 New Pass Manager module pass. The production plugin
contains the pass coordinator, the Z3 bit-vector prover and plugin registration;
the former direct pattern-rule authority has been physically removed.

## Build and run

```bash
cmake -S . -B build -G Ninja \
  -DLLVM_DIR=/usr/lib/llvm-21/lib/cmake/llvm \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build -j"$(nproc)"

opt-21 -load-pass-plugin ./build/lib095.so \
  -095-report=output.095.json \
  -passes='095' input.ll -S -o output.ll
```

Z3 is required through `pkg-config`. `-095-z3-timeout-ms=N` controls the
per-query timeout. `sat` disproves a candidate; `unknown`, including timeout,
is treated as no evidence and never authorizes a rewrite.

Run the hermetic regression and differential test with:

```bash
bash tests/run_hermetic_tests.sh
```

## Proof boundary

The pass normalizes LLVM expressions, translates supported integer/boolean DAGs
to bit-vectors, and applies only equivalence-proven MBA/opaque-predicate
rewrites. CFG cleanup is accepted only when the branch predicate is proven.
Undefined or poison-sensitive carriers, dynamic targets and unsupported
control flow remain unchanged. `verifyModule` runs after mutation and a report
records proof, rewrite, timeout and refusal counts.
