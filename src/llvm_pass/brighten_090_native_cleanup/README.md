# Final native cleanup and contract verifier

`brighten-native-cleanup-pass` is the final module-wide gate for the native IR
contract in `BRIGHTENING_METHODOLOGY.md`.

The pass removes only proven-dead lifter functions/globals and lifter metadata.
It always prints a whole-module report. Add `-brighten-native-strict` to make
`opt` fail when the module still contains State/lifted ABI, Remill/McSema
calls, guest-address artifacts, guest CFG/stack patterns, segment/data
aliases, or explicit undef/poison.

For modules that still expose the internal `sub_*.native(ptr State, ...)`
ABI, add `-brighten-native-state-ssa`. The production Python driver enables
this lowering by default. It rewrites the connected native callgraph to
explicit slot arguments and aggregate live-out returns, promotes those slots
to SSA, removes the entrypoint State scratch buffer, carries one explicit
native stack anchor through the callgraph, and lowers RSP/RBP-derived accesses
to native GEPs. The strict gate rejects residual guest address conversions,
flattened dispatchers, lifted ABI, or undefined values.

```bash
opt-21 -load-pass-plugin=build/BrightenNativeCleanupPass.so \
  -passes=brighten-native-cleanup-pass -brighten-native-strict \
  -disable-output input.ll
```

The regression runner checks both an accepted native module and a rejected
module that still contains `%struct.State` and the lifted three-argument ABI.

## Conservative boundary and corpus artifact

The pass-40 inputs were re-run through the updated post-lifting cleanup. The
generated IR and per-module verifier logs are under
`result/pass 40/improved_native_cleanup/` (the directory is an ignored
experiment artifact, not a source dependency). Every module completed the
LLVM `verify` gate; all seven pass-40 modules that entered with
`@__mcsema_reg_state` now have that lifted global removed. Shared synchronous
helpers/callbacks use a module-local context pointer to the entrypoint's
typed alloca. The cleanup contract report remains separate from the verifier
result.

The following forms are intentionally reported as unresolved rather than
rewritten when the current proof is insufficient:

* register-state globals whose address escapes through a call, volatile/atomic
  access, an unmodeled alias, or a callback boundary that cannot be proven to
  run synchronously under one entrypoint context;
* dynamic frame addresses whose PHI/range proof is incomplete, whose stored
  pointer value is not proven affine, or whose zero-initialized read is not
  dominated by a full write;
* integer-to-pointer values without exact recovered-object or native-stack
  provenance, including unresolved fallback addresses;
* partial `memcpy`/`memset`, lifetime, aggregate, vararg, and callback storage
  where the access width, alignment, capture behavior, or ABI type cannot be
  proven from def-use and memory analyses;
* arithmetic/flag and division helpers where the original width, signedness,
  wraparound, trap, or poison behavior is not established by the lifted IR.

These refusals preserve observable behavior and are emitted in the native
contract report instead of being replaced with `undef`, `null`, arbitrary
host pointers, or guessed types.
