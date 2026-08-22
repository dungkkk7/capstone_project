# Five-flow source recovery evaluation

Experiment: `experiment_20260821_120308`

This report was regenerated only from existing artifacts. It did not call the
LLM, compiler, or fuzzer. A behavioral PASS means: no reproducible final
divergence was detected within the recorded valid-input corpus and fuzzing
budget. It does not prove equivalence for every input.

## How to read the metrics

| Metric | Meaning | Denominator |
|---|---|---|
| First-pass RSR | The first Candidate C compiled, linked, and created an executable. | Samples that produced an initial candidate. |
| Final RSR@R | At least one executable was created within the compile-repair budget. | Samples that produced an initial candidate. |
| Program Behavioral Pass Rate | The final candidate completed fuzzing with no reproducible final mismatch. | Samples that completed behavioral validation; generation and compile failures are excluded. |
| Initial / Final Behavioral Pass | Behavioral success before repair versus after the final repair round. | Candidates that completed the corresponding behavioral validation. |
| Input Match Macro / Micro | Average per-sample match rate / all matching valid inputs pooled together. | Valid inputs executed on both reference and candidate. |
| Counterexample Detection Rate | A reproducible divergence was found for the final candidate. | Samples that completed behavioral validation. |
| Re-executability Rate | Recovered C produced an executable; semantic correctness is not required. | All eligible samples, including generation and compile failures. |
| Canonical E2E | The complete canonical pipeline ended with an accepted behavioral PASS. | All eligible samples, including generation and compile failures. |
| Repair Gain | Final rate minus initial rate, measured in percentage points. | N/A for non-iterative flows because repair is disabled. |
| Mean Tokens / Runtime | Average recorded LLM tokens and total execution time per run. | Eligible runs with a recorded value. |

Flow order: B1 Ghidra pseudocode one-shot; B2 objdump assembly one-shot; F1
Full; F2 no error context; F3 no pseudocode. Error bars in rate figures are
95% confidence intervals. `n` is the number of eligible samples after data
validation.

## Flow summary

| Flow | N | Eligible N | First-pass RSR | Final RSR@R | Program Behavioral Pass Rate | Initial Behavioral Pass Rate | Final Behavioral Pass Rate | Input Match Macro | Input Match Micro | Counterexample Detection Rate | Re-executability Rate | Compilation Repair Gain | Behavioral Repair Gain | Mean Tokens | Mean Runtime |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| B1 | 40 | 40 | 0/1 (0.0%) | 0/1 (0.0%) | N/A | N/A | N/A | N/A | N/A | N/A | 0/40 (0.0%) | N/A | N/A | 34603 | 15.1s |
| B2 | 40 | 40 | 13/15 (86.7%) | 13/15 (86.7%) | 3/13 (23.1%) | 3/13 (23.1%) | 3/13 (23.1%) | 27.6% | 29.9% | 10/13 (76.9%) | 13/40 (32.5%) | N/A | N/A | 63591 | 29.5s |
| F1 | 40 | 40 | 4/4 (100.0%) | 4/4 (100.0%) | 4/4 (100.0%) | 4/4 (100.0%) | 4/4 (100.0%) | 100.0% | 100.0% | 0/4 (0.0%) | 4/40 (10.0%) | +0.0 pp | +0.0 pp | 1148440 | 78.1s |
| F2 | 40 | 40 | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | 0/40 (0.0%) | N/A | N/A | 231926 | 16.4s |
| F3 | 40 | 40 | 6/6 (100.0%) | 6/6 (100.0%) | 3/6 (50.0%) | 3/6 (50.0%) | 3/6 (50.0%) | 62.6% | 76.6% | 3/6 (50.0%) | 6/40 (15.0%) | +0.0 pp | +0.0 pp | 755006 | 81.2s |

`Re-executability Rate` measures executable availability only: recovered C must
produce an executable, with all eligible samples in the denominator. It does
not check semantic output. `Canonical E2E` remains the stricter behavioral /
semantic metric. The flow-specific rate remains available in machine-readable
CSV output.
Rate cells show `numerator/denominator (percentage)`. F2
repair metrics are N/A because error context is disabled.

## Source quality: accepted Recovered C Source only

Readability is judged independently from correctness on a 1-to-5 absolute
rubric. Only Candidate C already accepted by compilation and behavioral
validation is eligible. The five dimensions are Variables, Loops, Conditions,
Logic flow, and Structural integrity; Overall is their arithmetic mean.

| Score | Interpretation |
|---:|---|
| 1 | Very difficult to read; dominated by low-level artifacts. |
| 2 | Recognizably C, but data and control flow remain tangled. |
| 3 | Main logic is understandable, with many temporaries, casts, or gotos. |
| 4 | Structure is reasonably clear and most logic is easy to follow. |
| 5 | Clear C-like source close to conventional human-written C. |

| Flow | Accepted | Evaluated | Coverage | Variables | Loops | Conditions | Logic flow | Structural integrity | Overall |
|---|---|---|---|---|---|---|---|---|---|
| B1 | 0 | 0 | 0/0 (N/A) | N/A | N/A | N/A | N/A | N/A | N/A |
| B2 | 3 | 3 | 3/3 (100.0%) | 3.67 | 4.67 | 4.67 | 4.67 | 4.67 | 4.47 |
| F1 | 4 | 4 | 4/4 (100.0%) | 4.00 | 5.00 | 4.50 | 5.00 | 5.00 | 4.70 |
| F2 | 0 | 0 | 0/0 (N/A) | N/A | N/A | N/A | N/A | N/A | N/A |
| F3 | 3 | 3 | 3/3 (100.0%) | 4.00 | 5.00 | 5.00 | 5.00 | 4.67 | 4.73 |

Readability measures analyzability only. It is never used to infer semantic
correctness, behavioral equivalence, or Re-executability success.

## Data validity and historical limitations

- Validation: 0 error(s), 400 provenance warning(s).
- 0 run(s) violate the one-shot invariant and are excluded from
  eligible aggregates and paired inference.

- Exact five-tuple comparison is implemented for schema-v2 observations.
- Readability scores are available from persisted evaluator records. SLOC Ratio is N/A when the required common `clang-format`
  tool is unavailable.
- LLVM reduction measures simplification only and is not a correctness oracle.

See `data_validation_errors.csv` for every affected paired key.

## Main paired contrasts (Re-executability)

| Contrast | Metric | n | A | B | Difference | W/T/L |
|---|---|---|---|---|---|---|
| F1_VS_F2_ERROR_CONTEXT | Re-executability Rate | 40 | 0.1 | 0 | 0.1 | 4/36/0 |
| F1_VS_F3_PSEUDOCODE | Re-executability Rate | 40 | 0.1 | 0.15 | -0.05 | 1/36/3 |
| B1_VS_B2_BASELINE_REPRESENTATIONS | Re-executability Rate | 40 | 0 | 0.325 | -0.325 | 0/27/13 |
| F1_VS_B1_FULL_VS_GHIDRA_MULTIFACTOR | Re-executability Rate | 40 | 0.1 | 0 | 0.1 | 4/36/0 |
| F1_VS_B2_FULL_VS_ASSEMBLY_MULTIFACTOR | Re-executability Rate | 40 | 0.1 | 0.325 | -0.225 | 2/27/11 |

F1 vs F2 is the full-configuration versus no-error-context baseline and is a multi-factor comparison, not a single-factor ablation. Statistical inference is marked underpowered when paired
n < 20; descriptive statistics are still emitted.

## Figures

- `overall_performance`: Primary recovery outcomes with executable availability over all eligible samples.
- `compilation_performance`: Compilation success before and after repair.
- `behavioral_performance`: Behavioral outcomes over conclusive campaigns.
- `repair_effectiveness`: Behavioral repair effectiveness; B1, B2, F2 repair fields are N/A.
- `iterative_feedback_vs_one_shot`: Matched-evidence re-executability comparison of iterative feedback against one-shot reconstruction.
- `cumulative_compile_success_by_round`: Cumulative executable creation by compile attempt.
- `cumulative_behavioral_success_by_round`: Cumulative behavioral pass by campaign.
- `final_status_breakdown`: Final status distribution without collapsing INCONCLUSIVE into failure.
- `failure_taxonomy`: Compilation, behavioral, and inconclusive taxonomies.
- `sample_flow_status_heatmap`: 0=fail, 1=unresolved, 2=pass by paired sample and flow.
- `sample_flow_match_heatmap`: Input match (%) by paired sample and flow.
- `ablation_forest_plot`: Paired re-executability effects with bootstrap 95% CI.
- `ablation_win_tie_loss`: Paired win/tie/loss counts for re-executability.
- `tokens_vs_e2e`: Total tokens versus Re-executability outcome.
- `runtime_vs_behavioral_pass`: Runtime (seconds) versus Behavioral pass outcome.
- `llvm_reduction_summary`: LLVM simplification metrics; these are not correctness claims.
- `llvm_reduction_vs_behavior`: Association view only; LLVM reduction is not a semantic oracle.
- `stage_completion_funnel`: Stage completion rates with explicit numerators and denominators in the report.
