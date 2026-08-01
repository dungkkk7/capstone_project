# Final native cleanup and contract verifier

`brighten-native-cleanup-pass` performs the compatibility recovery/cleanup
rewrites. `brighten-native-cleanup-final-pass` is the final module-wide gate
for the native IR contract in `BRIGHTENING_METHODOLOGY.md`; it reports and
optionally rejects the current IR without modifying it.

The pass removes only proven-dead lifter functions/globals and lifter metadata.
It always prints a whole-module report. Add `-brighten-native-strict` to make
`opt` fail when the module still contains State/lifted ABI, Remill/McSema
calls, guest-address artifacts, guest CFG/stack patterns, segment/data
aliases, or explicit undef/poison.

Explicit `undef`/`poison` seed PHIs are never converted into implicit
uninitialized local memory. Such a rewrite changes the concrete native value
source and can hide the risk from the final contract report.

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
  -passes=brighten-native-cleanup-final-pass -brighten-native-strict \
  -disable-output input.ll
```

The regression runner checks both an accepted native module and a rejected
module that still contains `%struct.State` and the lifted three-argument ABI.

At the post-frame boundary, a local zeroed `native_register_storage` byte
backing is split into typed integer globals only when its complete recursive
use graph consists of exact, in-bounds, non-volatile integer loads/stores.
Overlapping byte/word accesses share one little-endian scalar slot. An overlap
component with no original read is erased before partial stores manufacture a
load/mask/merge sequence. The final bundle then runs LLVM `globalopt` so
single-owner scalar state can become ordinary entrypoint SSA before the native
contract report. Any dynamic offset, address escape, atomic access, unsupported
type, or overlap wider than 16 bytes refuses the whole scalarization.

The same final boundary outlines repeated guest-or-native address resolvers
into one `noinline` internal helper per exact ordered range profile. This is a
structural proof, not a name-only fold: each arm must use an unsigned
`(address - begin) < size` bound, its GEP must normalize to the identical
`global + address - begin` expression, the terminal fallback must be the same
`i64` address, and the range must agree with either authoritative guest-range
metadata or the exact recovered-global allocation size. Identical repeated
arms are canonicalized. A mismatched bound, pointer offset, object size, or
non-generated carrier leaves the complete resolver inline.

Flagged affine forms use a separate exact boundary with `(root, guest_address)`
arguments. The guest-producing operation remains at the call site; the helper
recreates each original `add`/`sub` with the same `nsw`/`nuw` flags and reuses
the exact constant GEP base before applying the root index. The contract
accepts this boundary only when every call passes either the root itself or a
direct constant affine operation of that root. This avoids reassociating
poison-generating arithmetic merely to obtain the one-argument form.

Loop rotation may carry duplicate fallback pointers and range offsets through
parallel PHIs. Before outlining, the boundary canonicalizes such a PHI only
when every incoming leaf is the same unflagged affine expression of one
dominating `i64` root. The final contract independently revalidates the full
helper body; an exact outlined boundary is therefore not reported as a raw
inline mapper, while a named lookalike or one-byte mismatch remains a finding.

After frame recovery, a call to one of those exact outlined resolvers is
removed when its guest-address operand has complete native affine pointer
provenance. The replacement is the original native pointer plus the proven
byte offset, so stack addresses no longer round-trip through an integer range
mapper. This consumer snapshots and structurally revalidates the helper body;
it does not trust the helper name or attributes. Flagged reassociation, a
mixed native/guest PHI, a loaded integer without an exact forwarding proof,
or any non-affine leaf keeps the call and its resolver intact.

Constant byte offsets into a conservatively retained `native_residual_*`
allocation are exposed as named `native_scalar_<guest-address>` or
`native_object_<guest-address>` aliases. A scalar name requires every direct
use at that anchor to be a non-volatile, non-atomic load/store of one identical
single-value type; every other exact constant anchor remains an honest byte
object view. These are LLVM `GlobalAlias` views into the original allocation,
not inferred object splits: the range resolver, unbounded indexes, address
escapes, initialized layout, and cross-boundary aliasing continue to use the
same residual backing. Dynamic roots, negative or out-of-bounds offsets, and
resolver internals are never assigned guessed views.

The post-frame boundary also removes the redundant common-frame component
from a recovered helper ABI when the complete use graph proves translation
invariance.  Starting from `(frame_base, integer_rsp)`, it propagates an exact
integer coefficient for `frame_base` through casts, unflagged affine
arithmetic, byte GEPs, PHIs, and selects.  Every observable memory/call use
must have coefficient zero, and every helper reached with the base must be in
the same all-or-nothing conversion transaction.  Poison-generating flags,
non-affine operations, address escapes, indirect calls, and direct accesses to
`frame_base` refuse the conversion.  Accepted internal helpers receive one
native stack pointer in place of the pair.  For an externally visible helper,
the original symbol remains as a thin compatibility adapter while all module
calls and the implementation use the native-stack ABI; the versioned adapter
attribute makes this boundary idempotent and does not exempt the exported
guest ABI from the final contract report.

When an aggregate live-out field is, on every return edge, the same unflagged
constant displacement from `ptrtoint(stack_pointer)`, each direct caller
materializes that field from its actual native pointer.  The aggregate ABI is
left intact, but subsequent stack arithmetic keeps explicit provenance instead
of becoming an opaque integer extract.  Mixed return offsets, flagged
arithmetic, non-integral pointers, or a non-structural aggregate return refuse
this propagation.

Exact frame-load forwarding uses a signed interprocedural may-write footprint.
It accepts only finite constant GEP/PHI/select alternatives, recursively
summarized direct internal calls, and known bounded destinations such as
`fgets`, `memcpy`/`memmove`/`memset`, and `qsort`.  SysV `v*scanf` is modeled
only when the format is constant, every conversion has a finite destination
width, and the local `va_list` and GP save-area fields have exact dominating
stores.  Overlap, recursion, indirect calls, unbounded sizes, unresolved
pointer-integer escape, or more than 16 alternatives keep the load.  Frame
forwarding, native-affine lowering, exact resolver collapse, and dead-store
cleanup run to a monotonic fixed point so one post-frame invocation is
idempotent.

The executable-only bundle intentionally excludes LLVM `attributor` and
`function-attrs`. On the production corpus, strict differential execution
showed both passes exploiting latent lifted-IR UB/provenance: the optimized
recovered binary segfaulted where the original completed successfully. Only
the explicitly tested `internalize`/`ipsccp`/`deadargelim` sequence is part of
this cleanup contract; verified IR or a lower resolver count alone is not
evidence of behavioral equivalence.

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
