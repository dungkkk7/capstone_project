# Six-flow source recovery evaluation

Experiment: `experiment_20260801_182616`

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
| Re-executability Rate | Recovered C produced an executable; semantic correctness is not required. | All eligible samples, including generation and compile failures. |
| Canonical E2E | The complete canonical pipeline ended with an accepted behavioral PASS. | All eligible samples, including generation and compile failures. |
| Repair Gain | Final rate minus initial rate, measured in percentage points. | N/A for F2 and F6 because error context and repair are disabled. |
| Mean Tokens / Runtime | Average recorded LLM tokens and total execution time per run. | Eligible runs with a recorded value. |

Flow order: F1 Full; F2 no error context; F3 no pseudocode; F4 no direct
Clean IR; F5 Raw IR iterative; F6 Raw IR one-call derived from F5. F6 is not
an independent recovery run. Error bars in rate figures are 95% confidence
intervals. `n` is the number of eligible samples after data validation.

## Flow summary

| Flow | N | Eligible N | First-pass RSR | Final RSR@R | Program Behavioral Pass Rate | Initial Behavioral Pass Rate | Final Behavioral Pass Rate | Input Match Macro | Input Match Micro | Counterexample Detection Rate | Re-executability Rate | Compilation Repair Gain | Behavioral Repair Gain | Mean Tokens | Mean Runtime |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| F1 | 40 | 40 | 37/37 (100.0%) | 37/37 (100.0%) | 36/37 (97.3%) | 27/37 (73.0%) | 36/37 (97.3%) | 97.3% | 100.0% | 1/37 (2.7%) | 37/40 (92.5%) | +0.0 pp | +24.3 pp | 467513 | 169.5s |
| F2 | 40 | 40 | 30/31 (96.8%) | 30/31 (96.8%) | 21/30 (70.0%) | 21/30 (70.0%) | 21/30 (70.0%) | 90.7% | 95.8% | 9/30 (30.0%) | 30/40 (75.0%) | N/A | N/A | 158288 | 75.7s |
| F3 | 40 | 40 | 37/37 (100.0%) | 37/37 (100.0%) | 36/37 (97.3%) | 25/37 (67.6%) | 36/37 (97.3%) | 97.3% | 100.0% | 1/37 (2.7%) | 37/40 (92.5%) | +0.0 pp | +29.7 pp | 279570 | 143.0s |
| F4 | 40 | 40 | 39/40 (97.5%) | 40/40 (100.0%) | 36/40 (90.0%) | 21/40 (52.5%) | 36/40 (90.0%) | 96.9% | 99.4% | 4/40 (10.0%) | 40/40 (100.0%) | +2.5 pp | +37.5 pp | 237525 | 176.5s |
| F5 | 40 | 40 | 36/38 (94.7%) | 38/38 (100.0%) | 24/38 (63.2%) | 14/38 (36.8%) | 24/38 (63.2%) | 70.3% | 82.6% | 14/38 (36.8%) | 38/40 (95.0%) | +5.3 pp | +26.3 pp | 1154891 | 293.3s |
| F6 | 40 | 40 | 23/23 (100.0%) | 23/23 (100.0%) | 11/23 (47.8%) | 11/23 (47.8%) | 11/23 (47.8%) | 63.2% | 66.0% | 12/23 (52.2%) | 23/40 (57.5%) | N/A | N/A | 367079 | N/A |

`Re-executability Rate` measures executable availability only: recovered C must
produce an executable, with all eligible samples in the denominator. It does
not check semantic output. `Canonical E2E` remains the stricter behavioral /
semantic metric. The flow-specific rate remains available in machine-readable
CSV output.
Rate cells show `numerator/denominator (percentage)`. F2 and derived F6
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
| F1 | 36 | 36 | 36/36 (100.0%) | 2.94 | 3.86 | 3.61 | 3.78 | 3.58 | 3.56 |
| F2 | 21 | 21 | 21/21 (100.0%) | 2.71 | 3.95 | 3.48 | 3.81 | 3.67 | 3.52 |
| F3 | 36 | 36 | 36/36 (100.0%) | 3.53 | 4.14 | 3.97 | 4.19 | 4.06 | 3.98 |
| F4 | 36 | 36 | 36/36 (100.0%) | 2.81 | 3.86 | 3.56 | 3.86 | 3.64 | 3.54 |
| F5 | 24 | 24 | 24/24 (100.0%) | 3.83 | 4.46 | 4.38 | 4.50 | 4.38 | 4.31 |
| F6 | 11 | 11 | 11/11 (100.0%) | 4.00 | 4.73 | 4.64 | 4.73 | 4.64 | 4.55 |

Readability measures analyzability only. It is never used to infer semantic
correctness, behavioral equivalence, or Re-executability success.

## Data validity and historical limitations

- Validation: 0 error(s), 525 provenance warning(s).
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
| F1_VS_F2_ERROR_CONTEXT | Re-executability Rate | 40 | 0.925 | 0.75 | 0.175 | 9/29/2 |
| F1_VS_F3_PSEUDOCODE | Re-executability Rate | 40 | 0.925 | 0.925 | 0 | 1/38/1 |
| F1_VS_F4_CLEAN_IR_DIRECT | Re-executability Rate | 40 | 0.925 | 1 | -0.075 | 0/37/3 |
| F3_VS_F5_DEOBFUSCATION | Re-executability Rate | 40 | 0.925 | 0.95 | -0.025 | 2/35/3 |
| F5_VS_F6_RAW_ERROR_CONTEXT | Re-executability Rate | 40 | 0.95 | 0.575 | 0.375 | 15/25/0 |
| F1_VS_F5_FULL_VS_RAW_MULTIFACTOR | Re-executability Rate | 40 | 0.925 | 0.95 | -0.025 | 2/35/3 |

F1 vs F5 is the full-configuration versus Raw-IR baseline and is a multi-factor comparison, not a single-factor ablation. Statistical inference is marked underpowered when paired
n < 20; descriptive statistics are still emitted.

## Figures

- `overall_performance`: Primary recovery outcomes with executable availability over all eligible samples; F6 is derived from F5's first provider call.
- `compilation_performance`: Compilation success before and after repair.
- `behavioral_performance`: Behavioral outcomes over conclusive campaigns.
- `repair_effectiveness`: Behavioral repair effectiveness; F2, F6 repair fields are N/A.
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
