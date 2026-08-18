# 070 — global data recovery

Plugin: `BrightenGlobalDataRecoveryPass.so`  
Pipeline name: `brighten-global-data-recovery-pass`

The production implementation is the single byte-range provenance engine in
`GlobalDataV2.cpp`. The former multi-stage candidate/rule catalogue has been
physically removed from this pass.

## Pipeline

The pass performs:

```text
discoverSegments → analyze → materializeRanges/materializeStrings
→ deleteDeadSegmentCarriers → verify
```

`discoverSegments` identifies guest-backed globals and their byte ranges.
`analyze` resolves constant GEP/pointer provenance and records load, store and
string-call evidence. Materialization happens only after the complete analysis
has accepted a range; unresolved or dynamically aliased consumers remain on
the original byte carrier.

The key invariant is one LLVM storage owner per observable guest byte. A typed
global is never created while an unresolved access could still observe the
original segment, so recovery cannot silently introduce a non-aliasing sibling
allocation.

## Refusal boundaries

The engine refuses a candidate when pointer provenance is dynamic, an access
range is incomplete, a writable segment has unresolved aliases, or the access
type is incompatible with the proposed range. Read-only string uses can be
materialized when their exact interval is proven; unrelated or unresolved
uses keep the source segment alive.

## Verification

The verifier runs after mutation and rejects malformed IR. The regression suite
in `tests/run_tests.py` covers byte-range ownership, constant data recovery,
dynamic-offset refusal, writable alias refusal, external globals and
idempotence.
