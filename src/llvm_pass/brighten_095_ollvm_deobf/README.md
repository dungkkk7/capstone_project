# Proof-guided OLLVM deobfuscation (LLVM 21)

The preceding State-SSA stage promotes both lifted State arguments/globals and
non-escaping local State/frame objects with byte-accurate overlapping views:
connected intervals share one integer SSA object and every load/store becomes
endian-correct extract/insert logic. Global components are flushed and reloaded
across calls and flushed on return. Padded types, dynamic aliases, escapes,
volatile/atomic accesses and unsupported pointer users remain in memory.

This plugin runs after the lifted-IR brightening passes and before Souper. It
implements a proof-gated subset of `ollvm_deobfuscation_design_vi.md`:

- inventory metrics and an embedded `!ollvm.deobf.profile`;
- a JSON/metadata proof ledger;
- lifted-function `nsw`/`nuw`/`exact`/GEP no-wrap sanitization;
- width-correct APInt identities and exact classic OLLVM substitutions;
- bounded local affine bit-vector saturation for add/sub/constant-mul regions,
  with a lower-cost extraction rule and a fresh Z3 UNSAT equivalence proof for
  every committed rewrite;
- bounded AC saturation for `and`/`or`/`xor`, including idempotence and safe
  cancellation, with identical poison-support required before the Z3 gate;
- cost-reducing De Morgan rewrites and `zext`/`sext` factoring through bitwise
  operators, restricted to exclusively used local nodes and independently
  validated for poison support and fixed-width equivalence;
- common-mask factoring for bitwise OR/XOR and its AND/OR dual, again only for
  exclusively used nodes and only after the same poison/Z3 proof gates;
- constant-count rotate idiom recovery to `llvm.fshl`, with in-range shift
  proof, poison-support equality and Z3 rotate equivalence;
- adjacent-product parity opaque-predicate proofs and bogus-edge pruning;
- Z3 bit-vector fallback for pure SSA predicate slices (UNSAT proofs only);
- SAT-checked path-sensitive predicate proofs using dominating branch facts and
  `llvm.assume`; inconsistent constraints are never accepted as a proof;
- exact two-arm SSA diamond PHIs translated to path-state ITE expressions,
  including arm-local computations; non-diamond and cyclic PHIs remain opaque
  symbols rather than being guessed;
- exhaustive multi-arm switch-funnel PHIs translated to nested ITEs when every
  switch successor is a single-predecessor arm that jumps directly to the
  merge; malformed or non-exhaustive funnels remain symbolic;
- cyclic integer PHIs resolved only by induction: a constant seed must arrive
  from a non-backedge and every backedge recurrence must evaluate back to that
  same seed; casts, in-range shifts and state-dependent `icmp`/boolean/select
  recurrences are evaluated exactly, while changing or poison-generating
  recurrences remain unresolved;
- multi-incoming SSA dispatchers with a self-looping default are removed by an
  exhaustive reachability induction: an external seed must exist, every
  non-default incoming state must resolve to a real case, the default must be
  header-only, and exact header plumbing is cloned on every direct edge;
- MemorySSA/AA-backed predicate slices that substitute an exact reaching
  non-atomic, non-volatile store and equal-value MemoryPhi joins; calls,
  unequal/recursive MemoryPhi, pointer/type mismatches, volatile and atomic
  accesses remain barriers;
- bounded case-transition evaluation tracks exact local frame-object stores,
  crosses only byte ranges proved disjoint, evaluates rotate/bswap/bitreverse/
  ctpop, and summarizes single-block `memory(none)`/`memory(read)` callees only
  when every argument, constant-global load, and return expression reduces
  exactly; unknown aliasing, mutable reads, and unsupported calls are barriers;
- auxiliary frame-object loads walk up to 12 predecessor blocks and merge up
  to eight incoming paths only when every path reaches the same exact APInt;
  cycles, unequal values, or an unknown write stop evaluation;
- nested acyclic select/PHI transition expressions are executed as bounded
  fork/merge choices, including arithmetic around the merge.  A multi-edge is
  emitted only after Z3 proves that the enumerated APInt set exhausts the raw
  transition value; cyclic choices, unsupported slices, and more than 32
  outcomes remain residual;
- state stores performed on separate CFG arms can be merged into a proof-only
  SSA PHI at a write-free join when every predecessor has one exact reaching
  store of the same location/type.  The original stores and arm side effects
  remain in place; the synthesized value is used only to prove/direct dispatch;
- when a next-state expression is genuinely symbolic but the header and
  default plumbing are cloneable and every switch target is PHI-free, the
  pass clones the exact original encoded switch at the case edge.  This
  preserves an exhaustive dynamic transition without guessing a target and
  still removes that edge from the central dispatcher;
- opaque-predicate SMT slices model symbolic modulo-width `fshl`/`fshr` rotates
  plus `bswap`, `bitreverse`, and `ctpop`, enabling proof of intrinsic
  round-trips without replacing them by unconstrained leaves;
- cyclic predicates over one integer PHI use Z3 1-induction: all external
  seeds must establish the same predicate value and every backedge recurrence
  must preserve it for all symbolic inputs.  Non-inductive recurrences remain;
- affine saturation groups equivalent roots when one extraction point
  dominates the whole group, builds one shared expression, and validates the
  full old-root tuple against it in a single Z3 query before any RAUW;
- AC saturation likewise groups equivalent `and`/`or`/`xor` roots after
  idempotence/cancellation normalization, shares one dominating extraction,
  and performs two-phase RAUW then tracked DCE only after one tuple proof;
- bounded mixed-operator regions (up to 40 pure integer nodes, 32 candidate
  roots, and 96 candidate comparisons per transaction) form semantic
  e-classes across different AST/opcode shapes.  Extraction reuses only a
  cheaper existing representative that dominates every member, requires two
  non-representative roots, identical poison support, and one final tuple Z3
  proof;
- proof-gated x86 flag-cone recovery for standalone sign bits, subtraction
  ZF/NZ, bitwise add-carry CF, bitwise sub-borrow CF, and the canonical
  low-byte xor-fold PF cone lowered to `llvm.ctpop`; compound flag consumers
  are preserved until the terminal predicate can be recognized, covering
  `E/NE/B/AE/BE/A/L/GE/LE/G`, and every committed root is checked by Z3 at
  its exact bit width;
- `cmp`/`sub`, `add`, and `test`/`and` producers use bundle transactions: the
  pass unions every recognized flag cone, rejects uncovered internal users,
  builds all direct predicates, proves the complete old/new tuple, and only
  then replaces the bundle together.  Subtraction covers ZF/NZ/SF/OF/CF/PF
  and terminal conditions, addition covers ZF/NZ/SF/OF/CF/PF, and TEST covers
  ZF/NZ/SF/PF (its architectural CF/OF values are constant zero).  PF is
  always reconstructed from the low byte even for wider producers;
- complete SSA dispatcher recovery for constant/select transitions, including
  affine encodings made from add/sub/mul/xor/and/or.
- exact SSA loop-variable preservation for multi-PHI dispatchers by lowering
  header/latch PHIs to private slots and cloning the executed plumbing on each
  proved edge; terminal cases and case-local control flow are retained;
- funnel dispatcher recovery with affine frame-address canonicalization and
  preservation of state-store plumbing.
- memory-join recurrence recovery with invertible modular state decoding and a
  fixed-width evaluator for state-dependent next-state expressions;
- path-local edge splitting for conditional join edges, so dispatcher effects
  execute on exactly the original path;
- exact cloning/remapping of dispatcher plumbing and cloneable default-entry
  blocks, including their loads, stores, and branch behavior;
- fixed-point proof reconciliation: a dispatcher is marked recovered only when
  the original block is actually gone after proof-backed rewrites and cleanup.

Unknown aliases, non-unique entry states, non-cloneable default paths, general
compare ladders and poison-sensitive expressions
are retained and recorded as unresolved. The affine saturation deliberately
does not claim to be a general e-graph. `pass_detected_scope` means every
candidate detected by the current implementation was discharged and LLVM
verification passed; it is not a claim that every P00-P60 component exists.
`partial_with_residuals` always includes a machine-readable reason for each
retained candidate.

The production driver runs proof/cleanup rounds to semantic-IR hash stability
before Souper (default hard cap: eight rounds). Proofs are imported across
rounds; unresolved items are reclassified after `jump-threading`,
`simplifycfg`, and `adce`. A cap hit writes `fixed_point_cap_reached`, returns
failure, and prevents Souper from running.

After Souper, the driver runs the mutation-limited final native cleanup and
LLVM verifier on the exact module that will be published, then atomically
replaces the output and native-contract report. The earlier cleanup report is
diagnostic only. Affine recovered-frame pointers are normalized only when the
ptrtoint terms cancel exactly. Fake-stack compaction remains all-or-nothing and
is refused for unknown escapes, unbounded calls, cross-function use, or
overlapping variadic destinations. Bounded constant-format scanf destinations
are isolated through private shadows before compaction so LLVM 21's incomplete
variadic ModRef model cannot let GVN replace post-scanf loads with pre-call
zeros; failed conversions retain the old destination bytes.

Production mode is residual-strict: convergence alone is insufficient. Any
remaining proof obligation also returns failure and prevents Souper.
`BRIGHTEN_DEOBF_ALLOW_RESIDUALS=1` is an explicit diagnostic override only;
the ledger still reports `partial_with_residuals`.

The JSON report includes `component_coverage` for every P00-P60 identifier in
the design. It distinguishes implemented, partial, and upstream components so
a successful detected-scope run cannot be mistaken for unsupported general
path execution or a general-purpose bit-vector e-graph.

The p00008 regression used during development removes both detected CFF
dispatchers (zero remaining `switch i32`) and passes 97/97 exact payloads
against both the pre-pass bitcode and original obfuscated ELF. Corpus results
are evidence for that fixture, not a substitute for proof obligations or wider
corpus testing.

Build and test:

```sh
cmake -S . -B build
cmake --build build -j2
tests/run_tests.sh
```

Corpus differential validation can compare the pre-pass bitcode, transformed
bitcode, and original ELF using the exact base64 payload list from an existing
semantic report:

```sh
python3 tests/differential_validate.py \
  --input-bc case_before_deobf.bc \
  --plugin build/BrightenOLLVMDeobfPass.so \
  --payload-report case_semantic_report.json \
  --original-elf case_obfuscated.elf \
  --report case_deobf_differential.json
```

Standalone use:

```sh
opt-21 \
  -load-pass-plugin build/BrightenOLLVMDeobfPass.so \
  -ollvm-deobf-report=proof-ledger.json \
  -passes='brighten-ollvm-deobf-pass,simplifycfg,adce,verify' \
  input.bc -o output.bc
```
