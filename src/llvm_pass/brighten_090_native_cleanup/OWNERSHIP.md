# 090 ownership boundary

This pass is currently a compatibility bridge, not the owner of semantic
recovery. The following functions are transitional calls whose proofs must be
provided by an earlier pass before they can be removed from 090:

| Current transformation | Intended owner | Required proof |
| --- | --- | --- |
| `lowerNativeStateABI` | 030 | architectural state use-def and live-outs |
| `compactProven*FrameBackings` | 040 | affine frame provenance and lifetime |
| `rewriteDynamicGuestAddressIntToPtr` | 070/080 | unique recovered object or native stack |
| `rewriteRecoveredExternalPointerArguments` | 060/070 | external ABI and pointer provenance |
| `normalizeNativeExternalABIs` | 050/060 | callee prototype and vararg contract |
| `collapseProvenNativeRecoveredPointerDispatches` | 070/CFG owner | unique object range and complete edge proof |
| `collapseNativeOutlinedRecoveredAddressResolverCalls` | 070/frame owner | exact outlined resolver plus native affine call-operand provenance |
| `materializeResidualConstantOffsetViews` | 070/080 data-object owner | source-level object boundaries and types; 090 only emits exact same-allocation views |
| `lowerTranslationInvariantGuestFrameABIs` | state-SSA/frame owner | complete affine frame-base cancellation across the helper callgraph |
| `materializeTranslationInvariantStackPointerReturns` | state-SSA/frame owner | identical poison-safe stack displacement on every aggregate return edge |
| `forwardExactDominatingLocalFrameLoads` | 040/060/frame owner | exact signed interprocedural write footprint, including bounded libc and materialized SysV varargs |

The final cleanup contract may reject unresolved instances of these patterns,
but must not guess their meaning. In particular, a range/select resolver,
`inttoptr` fallback, raw frame storage, or lifted ABI is not clean merely
because a name-based artifact scan no longer finds it.

The production pipeline has one narrow
`brighten-native-cleanup-post-frame-pass` immediately after the final 040 and
heap-resolver owners. It may only consume products first exposed at that
boundary (proven frame pointer reloads, native affine pointer round-trips,
their now-redundant inline or exactly outlined range dispatches, exact local
frame-relative PHIs, and dead pointer-integer bookkeeping stores). An outlined
resolver call is folded only after revalidating the complete structural helper
boundary and proving the call operand is a poison-safe native affine pointer;
helper names and attributes are not evidence. A dynamic-looking frame access is
treated as disjoint only when its complete PHI/select address set is finite
(at most 16 exact byte offsets) and every interval misses the target slot.
Direct internal calls are recursively summarized with signed offsets. Known
libc writes require constant byte bounds; a `v*scanf` hidden destination is
accepted only from a constant bounded format and exact dominating local
`va_list`/GP-save stores. Unbounded offsets, overlapping intervals, atomics,
recursion, indirect calls, and unresolved pointer-integer escapes are
refusals. A bookkeeping store is erased only when no load or other
memory-reading operation can touch its exact byte interval.
At this boundary, a surviving synthetic local byte frame may be split into
typed local slots only when its complete pointer-use graph consists of loads,
stores, and non-escaping GEP/PHI/select/freeze/bitcast derivations; every
access has at most 16 exact offsets; and all accessed byte intervals are
either identical or disjoint. Pointer observation or escape, an unbounded
index, a partial overlap, an out-of-bounds interval, or a mixed root refuses
the entire frame transaction. This is storage partitioning backed by an exact
alias proof, not a rename that hides guest-stack storage from the contract.
Within one invocation the native-pointer forwarding, affine lowering,
resolver collapse, exact scalar forwarding, and unread-store cleanup form a
monotonic fixed point. The final artifact bundle may invoke this same narrow
consumer again after standard instcombine because LLVM can newly respell a
recovered GEP as an integer affine address; each invocation is independently
idempotent and is not a retry of broad semantic recovery. The following
`brighten-native-cleanup-final-pass` remains diagnostic-only.
The second invocation is the final mutation boundary, after all late
`ipsccp`/`deadargelim`/instcombine work, because instcombine may also respell a
fully overwritten aggregate with a poison seed. The fixed-point consumer
defines that seed before the diagnostic contract observes the artifact.
Because that bundle always links a complete executable, it runs LLVM
whole-program internalization after the first post-frame consumer. `main` and
compiler-retained roots stay public; unused source-ABI adapters become dead
only there. Standard interprocedural constant propagation first exposes
closed-callgraph State arguments that have one constant value; dead-argument
elimination then removes only parameters and aggregate result fields made
unused by that proof. Both run once more after late scalar cleanup exposes
additional constants and dead fields. Reusable module cleanup never assumes a
closed world.

This deliberately does **not** authorize LLVM `attributor` or
`function-attrs`. Strict differential execution on the production corpus
showed that both can exploit latent lifted-IR UB/provenance and turn a
successful original execution into a recovered-binary segmentation fault.
The final bundle therefore permits only its enumerated narrow closed-callgraph
rewrites; adding either attribute-inference pass is a contract violation even
when the resulting IR verifies and looks substantially smaller.

The same boundary may replace a `(frame_base, integer_rsp)` helper pair with a
native pointer only after every value derived from `frame_base` has an exact
affine coefficient and every observable use cancels that coefficient to zero.
Calls through the conversion set are checked transactionally; flagged
arithmetic, non-byte GEPs with a live base coefficient, indirect/address-taken
functions, direct base memory accesses, and escapes are refusals. Externally
visible symbols keep a versioned compatibility adapter, which remains visible
to the final contract instead of being renamed away.

An aggregate stack live-out remains ABI-compatible, but a direct caller may
reconstruct an extracted field from its actual stack pointer only when every
return edge proves one identical, flag-free constant displacement. This is a
provenance propagation, not a guessed return convention; mixed fields,
poison-generating operations, aggregate ambiguity, and non-integral address
spaces remain untouched.

A `native_residual_*` aggregate may be reclassified as `native_storage_*`
only after a closed-use proof shows that every consumer is a direct,
non-volatile GEP/load/store or a known memory intrinsic/libc memory call.
Pointer selects, integer conversions, address comparisons, escaped addresses,
and guest-range metadata all keep the residual classification. The aggregate
is not split, so unbounded-index aliasing and its exact initialized layout are
preserved.

At the final presentation boundary, a constant-offset anchor may receive a
named `GlobalAlias` view without changing that rule. The alias denotes the
exact same address inside the same allocation. A scalar view additionally
requires uniform direct load/store type evidence; otherwise the name is a byte
object view. Resolver bodies and dynamic, negative, or out-of-bounds anchors
stay on the residual backing. Moving from these views to independent globals
or stronger source types belongs to the 070/080 data-object owner and requires
a complete boundary and alias proof.

Changes that add a new semantic rewrite to 090 require a negative test for
ambiguous provenance and an ownership update here. The final pass remains
diagnostic-only; mutation belongs to the non-final cleanup invocation.
