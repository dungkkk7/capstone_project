# 080 — type reconstruction

Plugin: `BrightenTypeReconstructionPass.so`  
Pipeline names: `brighten-type-reconstruct`, `brighten-struct-recover`, and
`brighten-array-recover`

The production implementation is split into discovery, offset analysis,
evidence collection, constraint solving, rewrite planning and verification.
Only the active sources listed in `CMakeLists.txt` participate in the plugin;
the former standalone pointer-provenance engine and its lifecycle fixtures have
been physically removed.

## Pipeline

```text
exact pointer round-trip cleanup
→ DiscoverCandidates
→ AnalyzePointerOffsets
→ CollectAccessEvidence
→ SolveTypeConstraints
→ PlanAndRewrite
→ VerifyReconstruction
```

The round-trip cleanup only handles an exact `ptrtoint`/`inttoptr` pair with a
matching integral pointer width. It does not infer arbitrary integer address
provenance. Type reconstruction starts from byte-array allocas/globals and
requires compatible, bounded access evidence before changing their layout.

## Safety boundaries

Escaped objects, dynamic or unknown offsets, volatile/atomic accesses,
conflicting overlapping fields, externally owned storage and unsupported
initializers remain in their original representation. Rewrites are planned and
validated before mutation; a failed proof leaves the original object intact.

The pass supports conservative, balanced and aggressive candidate selection,
but no mode bypasses provenance, layout or verifier checks.

## Tests

`tests/run_tests.py` covers structs, arrays, padding, globals, pointer/float
fields, conflicts, dynamic offsets, escapes, atomics, memcpy/memset,
initializers, address spaces and idempotence. Tests for the removed pointer
resolver/provenance engine are not part of this runner.
