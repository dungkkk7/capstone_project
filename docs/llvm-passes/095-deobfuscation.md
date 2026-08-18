# 095 — proof-driven OLLVM deobfuscation

Plugin: `lib095.so`  
Pipeline name: `095`

The production pass is deliberately small: `Deobfuscate095.cpp` coordinates
the transformation, `Z3Prover.cpp` provides bit-vector proofs, and `Plugin.cpp`
registers the pass. The former direct rule-authority layer has been physically
removed; no pattern catalogue is allowed to publish a rewrite without the
validator proving equivalence.

## Contract

For each candidate predicate or MBA expression, the pass builds a bounded
bit-vector model and accepts a rewrite only when Z3 proves the old and new
expressions equivalent. `unknown` is evidence to refuse, not permission to
rewrite. CFG changes are similarly restricted to predicates whose truth value
is proven.

The pass reports proof counts, rewrites, timeout/unknown counts and stage
metadata through `-095-report`. It verifies the resulting module before
returning.

## Tests

`tests/run_hermetic_tests.sh` covers opaque predicates, MBA simplification,
dynamic branches, verifier validity and before/after differential behavior.
The fixtures retain historical family names where useful for semantic coverage;
they do not restore the deleted implementation layer.
