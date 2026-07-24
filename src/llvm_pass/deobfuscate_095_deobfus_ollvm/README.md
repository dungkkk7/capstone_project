# LLVM deobfuscation pass 095

`lib095.so` is one LLVM 21 New Pass Manager module pass. It is intentionally
separate from `britening_ir.py`: development and validation use already
brightened IR under `result/pass 40`, and this directory does not modify the
brightening pipeline.

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

Z3 is required through `pkg-config`. `-095-z3-timeout-ms=N` sets the per-query
timeout (default 100 ms), and `-095-max-z3-candidates=N` bounds work per
function. `sat` disproves a candidate; `unknown`, including timeout, is always
treated as no evidence and never authorizes a rewrite.

Run the regression and compile-and-execute differential test with:

```bash
bash tests/run_tests.sh
```

## Chernobog to LLVM mapping

The implementation transfers the applicable ideas from Chernobog's
`src/deobf/handlers` without using IDA or Hex-Rays APIs:

| Chernobog family | LLVM implementation and proof boundary |
|---|---|
| `deflatten`, recurrent switch, `hikari_cfg` | Discover a switch controlled by a header PHI and a latch state PHI. Constant/select state updates are mapped to switch successors. Each rewritten edge gets a bridge containing a `ValueToValueMapTy` clone of the executed dispatcher payload; `SSAUpdater` rebuilds all loop-carried values and target PHIs are repaired only when dominance proves every incoming. Unmapped recurrent states remain fail-closed. |
| `bogus_cf`, `native_opaque` | Translate poison-safe integer/`icmp` DAGs to Z3 bit-vectors. Replace a conditional edge only when the negation is `unsat`. Dead successor PHIs are updated before replacement. |
| `mba_simplify`, `vm_mba`, peephole rules | Run bounded candidate synthesis for constants, leaves, arithmetic and Boolean operators; install only a strictly smaller Z3-proved equivalent. LLVM InstCombine/EarlyCSE handle canonical identities first. |
| `select_chain` | Collapse same-condition nested selects and equal arms; flattened state selects become exact conditional CFG edges during deflattening. |
| `indirect_branch`, `indirect_call`, `savedregs` | Follow LLVM aliases, immutable function-pointer globals, casts and equal-target selects. An `indirectbr` becomes direct only for a unique listed `blockaddress`. |
| `global_const`, `const_decrypt`, `ptr_resolve` | Use LLVM constant folding, `DataLayout`, underlying objects and immutable initializers; unresolved dynamic objects remain unchanged. |
| stack/fake-stack handlers | SROA and mem2reg recover provable local objects. Large or escaping frames remain and are reported. |
| register-state cleanup | DominatorTree, LoopInfo and MemorySSA are materialized and verified; DSE, mem2reg, ADCE and InstCombine remove only proven dead/local state. |

The internal order is fixed:

`normalize → resolve objects/pointers → MBA → BCF → deflatten → CFG cleanup → fake stack → register state`

This is an explicit cleanup sequence, not an opaque `-O3` pipeline.

## Safety and reporting

`verifyModule` runs after BCF, deflatten, CFG cleanup and final register-state
cleanup. A verifier failure aborts without producing output. CFG rewrites repair
PHIs before replacing terminators. Every report contains stage change counts,
unresolved counts/reasons, per-function before/after size, observed loop and
MemorySSA counts, and Z3 query outcomes.

The pass deliberately retains dispatcher transitions with unproved state
values, computed indirect targets and escaping fake stacks. Multi-carrier
dispatchers are rewritten only where every carrier can be reconstructed on a
bridge edge. That is the production fail-closed contract: an incomplete
cleanup is acceptable; an unproved semantic change is not.
