# Six-flow source recovery evaluation

Experiment: `experiment_20260728_124405`

This report was regenerated only from existing artifacts. It did not call the
LLM, compiler, or fuzzer. A behavioral PASS means: no reproducible final
divergence was detected within the recorded valid-input corpus and fuzzing
budget. It does not prove equivalence for every input.

**F6 provenance:** F6 is derived from the first actual provider call of each
F5 run. It is a paired one-call checkpoint, not an independent recovery run.
Missing first-call or first-campaign artifacts are marked CANCELLED.

## How to read the metrics

| Metric | Meaning | Denominator |
|---|---|---|
| First-pass RSR | The first Candidate C compiled, linked, and created an executable. | Samples that produced an initial candidate. |
| Final RSR@R | At least one executable was created within the compile-repair budget. | Samples that produced an initial candidate. |
| Program Behavioral Pass Rate | The final candidate completed fuzzing with no reproducible final mismatch. | Samples that completed behavioral validation; generation and compile failures are excluded. |
| Initial / Final Behavioral Pass | Behavioral success before repair versus after the final repair round. | Candidates that completed the corresponding behavioral validation. |
| Input Match Macro / Micro | Average per-sample match rate / all matching valid inputs pooled together. | Valid inputs executed on both reference and candidate. |
| Counterexample Detection Rate | A reproducible divergence was found for the final candidate. | Samples that completed behavioral validation. |
| Canonical E2E | The complete canonical pipeline ended with an accepted behavioral PASS. | All eligible samples, including generation and compile failures. |
| Repair Gain | Final rate minus initial rate, measured in percentage points. | N/A for F2 and F6 because error context and repair are disabled. |
| Mean Tokens / Runtime | Average recorded LLM tokens and total execution time per run. | Eligible runs with a recorded value. |

Flow order: F1 Full; F2 no error context; F3 no pseudocode; F4 no direct
Clean IR; F5 Raw IR iterative; F6 Raw IR one-call derived from F5. F6 is not
an independent recovery run. Error bars in rate figures are 95% confidence
intervals. `n` is the number of eligible samples after data validation.

## Flow summary

| Flow | N | Eligible N | First-pass RSR | Final RSR@R | Program Behavioral Pass Rate | Initial Behavioral Pass Rate | Final Behavioral Pass Rate | Input Match Macro | Input Match Micro | Counterexample Detection Rate | Canonical E2E | Compilation Repair Gain | Behavioral Repair Gain | Mean Tokens | Mean Runtime |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| F1 | 40 | 40 | 37/38 (97.4%) | 38/38 (100.0%) | 31/38 (81.6%) | 21/38 (55.3%) | 31/38 (81.6%) | 87.8% | 92.0% | 7/38 (18.4%) | 31/40 (77.5%) | +2.6 pp | +26.3 pp | 537965 | 220.7s |
| F2 | 40 | 31 | 30/30 (100.0%) | 30/30 (100.0%) | 21/30 (70.0%) | 21/30 (70.0%) | 21/30 (70.0%) | 86.7% | 92.4% | 9/30 (30.0%) | 21/31 (67.7%) | N/A | N/A | 146770 | 67.7s |
| F3 | 40 | 40 | 40/40 (100.0%) | 40/40 (100.0%) | 32/40 (80.0%) | 22/40 (55.0%) | 32/40 (80.0%) | 90.8% | 93.5% | 8/40 (20.0%) | 32/40 (80.0%) | +0.0 pp | +25.0 pp | 517928 | 201.0s |
| F4 | 40 | 40 | 40/40 (100.0%) | 40/40 (100.0%) | 32/40 (80.0%) | 24/40 (60.0%) | 32/40 (80.0%) | 92.1% | 96.4% | 8/40 (20.0%) | 32/40 (80.0%) | +0.0 pp | +20.0 pp | 494691 | 175.1s |
| F5 | 40 | 40 | 36/37 (97.3%) | 37/37 (100.0%) | 25/37 (67.6%) | 10/37 (27.0%) | 25/37 (67.6%) | 74.7% | 77.1% | 12/37 (32.4%) | 25/40 (62.5%) | +2.7 pp | +40.5 pp | 1328970 | 291.8s |
| F6 | 40 | 40 | 22/23 (95.7%) | 22/23 (95.7%) | 7/21 (33.3%) | 7/21 (33.3%) | 7/21 (33.3%) | 54.1% | 57.5% | 14/21 (66.7%) | 7/40 (17.5%) | N/A | N/A | 368247 | N/A |

`Canonical E2E` measures accepted recovery over all eligible samples. The
flow-specific rate remains available in machine-readable CSV output but is
omitted here because it is identical to Canonical E2E in this campaign.
Rate cells show `numerator/denominator (percentage)`. F2 and derived F6
repair metrics are N/A because error context is disabled.

## Data validity and historical limitations

- Validation: 9 error(s), 1559 provenance warning(s).
- 9 run(s) violate the one-shot invariant and are excluded from
  eligible aggregates and paired inference.

- The historical tracker read the wrong provider token keys. This report reads
  token counts directly from per-call metadata.
- Historical prompt bodies, per-attempt latency/cost, exact compiler version,
  and most earlier raw fuzz reports were not persisted; these fields are null.
- The historical oracle replayed mismatches, but stderr comparison was not
  enabled globally, sample-specific policies existed, and the campaign used a
  Clean-IR-compiled reference rather than the mandated obfuscated binary.
  Consequently, behavioral rates are faithful summaries of the historical
  recorded oracle, not a retroactive strict-oracle claim.

- Exact five-tuple comparison is implemented for schema-v2 observations.
- Readability is N/A because no evaluator record exists. SLOC Ratio is N/A when
  the required common `clang-format` tool is unavailable.
- LLVM reduction measures simplification only and is not a correctness oracle.

See `data_validation_errors.csv` for every affected paired key.

## Main paired contrasts (Canonical E2E)

| Contrast | Metric | n | A | B | Difference | W/T/L |
|---|---|---|---|---|---|---|
| F1_VS_F2_ERROR_CONTEXT | Canonical E2E Rate | 31 | 0.871 | 0.677 | 0.194 | 7/23/1 |
| F1_VS_F3_PSEUDOCODE | Canonical E2E Rate | 40 | 0.775 | 0.8 | -0.025 | 2/35/3 |
| F1_VS_F4_CLEAN_IR_DIRECT | Canonical E2E Rate | 40 | 0.775 | 0.8 | -0.025 | 1/37/2 |
| F3_VS_F5_DEOBFUSCATION | Canonical E2E Rate | 40 | 0.8 | 0.625 | 0.175 | 7/33/0 |
| F5_VS_F6_RAW_ERROR_CONTEXT | Canonical E2E Rate | 40 | 0.625 | 0.175 | 0.45 | 18/22/0 |
| F1_VS_F5_FULL_VS_RAW_MULTIFACTOR | Canonical E2E Rate | 40 | 0.775 | 0.625 | 0.15 | 7/32/1 |

F1 vs F5 is the full-configuration versus Raw-IR baseline and is a multi-factor comparison, not a single-factor ablation. Statistical inference is marked underpowered when paired
n < 20; descriptive statistics are still emitted.

## Figures

- `overall_performance`: Primary recovery outcomes with flow order F1–F6; F6 is derived from F5's first provider call.
- `compilation_performance`: Compilation success before and after repair.
- `behavioral_performance`: Behavioral outcomes over conclusive campaigns.
- `repair_effectiveness`: Behavioral repair effectiveness; F2, F6 repair fields are N/A.
- `cumulative_compile_success_by_round`: Cumulative executable creation by compile attempt.
- `cumulative_behavioral_success_by_round`: Cumulative behavioral pass by campaign.
- `final_status_breakdown`: Final status distribution without collapsing INCONCLUSIVE into failure.
- `failure_taxonomy`: Compilation, behavioral, and inconclusive taxonomies.
- `sample_flow_status_heatmap`: 0=fail, 1=unresolved, 2=pass by paired sample and flow.
- `sample_flow_match_heatmap`: Input match (%) by paired sample and flow.
- `ablation_forest_plot`: Paired Canonical E2E effects with bootstrap 95% CI.
- `ablation_win_tie_loss`: Paired win/tie/loss counts for Canonical E2E.
- `tokens_vs_e2e`: Total tokens versus Canonical E2E outcome.
- `runtime_vs_behavioral_pass`: Runtime (seconds) versus Behavioral pass outcome.
- `llvm_reduction_summary`: LLVM simplification metrics; these are not correctness claims.
- `llvm_reduction_vs_behavior`: Association view only; LLVM reduction is not a semantic oracle.
- `stage_completion_funnel`: Stage completion rates with explicit numerators and denominators in the report.
