# Experiment Completion Audit

Audit date: `2026-07-24`

Authoritative audited run: `real_three_case_20260724_03`

Superseded runs: `_01` used incomplete count coverage; `_02` used the same
coverage fix but retained a 0.1s reference timeout. Their artifacts remain
available for forensic audit and are not primary outcomes.

Scope: `p00001`, `p00008`, `p00033`; P0, A0 and B0; full primary evaluation
budgets. The run is scoped evidence from a dirty worktree, not the canonical
clean-commit full-dataset primary study.

## 1. Audit standard

An item is marked proved only when an authoritative source artifact, executable
test, run artifact or integrity verifier directly establishes it. Passing tests
alone are not treated as proof of empirical recovery quality. Fake-provider
runs are accepted only as orchestration evidence.

## 2. Requirement-to-evidence matrix

| Requirement | Authoritative evidence | Finding |
|---|---|---|
| P0 preserves the current pipeline | `src/experiments/p0_legacy.py`; real P0 representation manifests; recovery logs | Proved: brightened IR, P0-generated Ghidra pseudocode, internal precheck and iterative compiler/fuzz feedback are retained |
| P0 uses no more than five accepted responses | Config validation, unit test, per-case generation counters | Proved: real cases used 1, 2 and 4 accepted responses; cap remains 5 |
| P0 request contains brightened IR and pseudocode | Attachment unit test and P0 representation manifests with two hashes | Proved |
| A0 is raw McSema IR only | Raw-lift manifest, empty pass pipeline, A0 representation/request hashes | Proved |
| B0 decompiles the original OLLVM ELF | B0 provenance source hash equals enrolled original ELF hash; Ghidra script/tool hash | Proved |
| B0 prompt is byte-exact to the supplied policy | Prompt unit test plus persisted `request.json` prompt and SHA-256 | Proved |
| A0/B0 are strict one-shot | Source invariant, unit tests, integrity verifier, real counters | Proved: each real variant has one logical generation and one accepted call |
| Model/sampling fairness | Resolved config, manifest model block, request decoding blocks, P0 model freeze | Proved for model ID, location, temperature, top-p, candidate count, output cap and thinking level |
| Context is not silently truncated | Config invariant, context-check artifacts, no-truncation flag | Proved for A0/B0; P0 intentionally preserves its legacy attachment path |
| 429 does not consume a generation | Quota-controller tests and counter semantics | Proved in tests; not exercised empirically because the real run had no 429 |
| Quota resume preserves request and iteration | Interruption/resume and P0 hash-drift tests | Proved in tests |
| Waiting variant cannot freeze union early | Regression test `test_waiting_variant_defers_union_corpus_freeze` | Proved after audit fix |
| Same final oracle and union corpus | Per-case union/reference hashes and integrity verifier | Proved |
| Original obfuscated ELF is the final reference | Evaluation artifacts and enrolled SHA-256 verification | Proved |
| Output metrics include reasoning cost | Generation schema, aggregate test and real usage metadata | Proved after audit fix: billable output = response + reasoning |
| Audit log is tamper evident | Hash-chain test and real integrity report | Proved: 39 events |
| Artifacts are sealed | Artifact mutation test and real manifest verification | Proved: 3,207 artifacts |
| Visualization derives from structured metrics | Figure manifest, five parseable SVGs and visually inspected dashboard | Proved |
| Fake results cannot be cited as research evidence | Fake-run metadata/report/dashboard warning tests | Proved |
| Real three-case experiment completed | Real provider artifacts and integrity report | Proved |
| A0 is weaker than P0 on the scoped cases | Paired outcomes | Supported descriptively: P0 3/3, A0 0/3 |
| B0 is weaker than P0 on the scoped cases | Paired outcomes | Supported descriptively: P0 3/3, B0 2/3 |

## 3. Defects found during completion audit

### 3.1. Premature union freeze under quota wait

Previous behavior could evaluate ready methods while another method was
`WAITING_FOR_QUOTA`. This could freeze a union corpus before the resumed method
contributed discovery inputs. The runner now defers the entire sample until
every nonterminal variant has completed generation/build. A regression test
directly verifies that no union manifest is created while B0 waits.

### 3.2. Reasoning tokens omitted from cost

Previous cost used only `candidatesTokenCount`. Gemini pricing counts response
and reasoning output, while usage metadata exposes reasoning as
`thoughtsTokenCount`. Generation and aggregate schemas now report:

- `output_tokens`;
- `thinking_tokens`;
- `billable_output_tokens = output_tokens + thinking_tokens`.

Cost uses billable output. The integrity verifier rejects inconsistent token
components.

### 3.3. Ambiguous evidence scope

Real runs were previously labeled generically as research evidence. Metrics,
report and dashboard now record sample count, study scope, Git commit/dirty
state and a precise eligibility label. This run is
`scoped_research_evidence_dirty_worktree`.

### 3.4. Count-boundary coverage

The original contract generator preserved the leading count for
`counted_long_list`, so it could never reach valid growth probes such as
`N=8`. The generator now adds deterministic count probes `{1,2,4,8,16,64}`
within contract bounds, with a regression test. On `p00033`, the original ELF
aborts with `malloc(): corrupted top size` for the boundary probes; the old
`_01` PASS result therefore had false confidence.

### 3.5. Reference timeout calibration

The 0.1s evaluation timeout classified those same `p00033` probes as
`INCONCLUSIVE_REFERENCE_TIMEOUT` even though they terminate with SIGABRT after
about 1.3s. The authoritative `_03` run freezes `per_input_timeout_sec=2.0`.
It records three `INCONCLUSIVE_BOTH_CRASH` probes for P0 and three confirmed
crash asymmetries for B0; the inconclusive fraction remains below the
pre-registered 0.20 ceiling.

## 4. Verification evidence

- Test suite: `75 passed`.
- Python compile check: passed.
- Git diff whitespace check: passed.
- Synthetic end-to-end gate: `debug_fake_audit8`, integrity passed.
- Authoritative run source snapshot: 34 source files,
  SHA-256 `e5becde46b8883fa61b66f413d44dade5be42cb8d8737a8c593293c6f802f6c1`.
- Authoritative run integrity: passed with zero errors (39 events, 3,207 artifacts).
- External seal stored outside the run directory:
- `result/experiments/real_three_case_20260724_03.external_seal.json`.
- All five real-run SVG figures parsed successfully.
- Dashboard was rendered in headless Chrome and visually inspected.

## 5. Empirical conclusion

| Method | PASS | E2E | Calls | Estimated cost |
|---|---:|---:|---:|---:|
| P0 | 3/3 | 100% | 7 | $3.607287 |
| A0 | 0/3 | 0% | 3 | $2.151878 |
| B0 | 2/3 | 66.67% | 3 | $0.484121 |

P0 clearly outperformed A0 descriptively. Two A0 responses hit `MAX_TOKENS`
because reasoning plus response reached 65,531 output tokens; the remaining A0
candidate built but mismatched the full p00001 union.

P0 outperformed B0 descriptively by one paired case in the corrected run. B0's
`p00033` candidate had three confirmed crash asymmetries on the count-boundary
inputs; P0's final candidate reproduced the same crash on those probes. P0's
iterative mechanism was exercised on all three cases and used four accepted
responses on `p00033` before final PASS.

No confirmatory claim should be made from `n=3`; the paired bootstrap interval
for P0−B0 is `[0,+100]` percentage points and McNemar `p=1`. The next step is
a clean-commit, preregistered, larger paired primary run. The corrected result
must be reported together with the superseded runs and their audit caveats.
