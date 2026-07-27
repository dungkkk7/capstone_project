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

The final cleanup contract may reject unresolved instances of these patterns,
but must not guess their meaning. In particular, a range/select resolver,
`inttoptr` fallback, raw frame storage, or lifted ABI is not clean merely
because a name-based artifact scan no longer finds it.

Changes that add a new semantic rewrite to 090 require a negative test for
ambiguous provenance and an ownership update here. The final pass remains
diagnostic-only; mutation belongs to the non-final cleanup invocation.
