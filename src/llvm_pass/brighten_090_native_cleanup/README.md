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
