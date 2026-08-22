# Five-flow source recovery evaluation

Experiment: `experiment_20260821_155030`

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
Clean IR iterative; F2 Raw IR iterative; F3 Clean IR one-shot. Error bars in rate figures are
95% confidence intervals. `n` is the number of eligible samples after data
validation.

## Flow summary

| Flow | N | Eligible N | First-pass RSR | Final RSR@R | Program Behavioral Pass Rate | Initial Behavioral Pass Rate | Final Behavioral Pass Rate | Input Match Macro | Input Match Micro | Counterexample Detection Rate | Re-executability Rate | Compilation Repair Gain | Behavioral Repair Gain | Mean Tokens | Mean Runtime |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| B1 | 1 | 1 | N/A | N/A | N/A | N/A | N/A | N/A | N/A | N/A | 0/1 (0.0%) | N/A | N/A | 16821 | 43.1s |
| B2 | 1 | 1 | 1/1 (100.0%) | 1/1 (100.0%) | N/A | N/A | N/A | N/A | N/A | N/A | 1/1 (100.0%) | N/A | N/A | 16240 | 45.5s |
| F1 | 1 | 1 | 1/1 (100.0%) | 1/1 (100.0%) | N/A | N/A | N/A | N/A | N/A | N/A | 1/1 (100.0%) | +0.0 pp | N/A | 361124 | 273.0s |
| F2 | 1 | 1 | 1/1 (100.0%) | 1/1 (100.0%) | N/A | N/A | N/A | N/A | N/A | N/A | 1/1 (100.0%) | +0.0 pp | N/A | 696052 | 205.6s |
| F3 | 1 | 1 | 1/1 (100.0%) | 1/1 (100.0%) | N/A | N/A | N/A | N/A | N/A | N/A | 1/1 (100.0%) | N/A | N/A | 57804 | 78.4s |

`Re-executability Rate` measures executable availability only: recovered C must
produce an executable, with all eligible samples in the denominator. It does
not check semantic output. `Canonical E2E` remains the stricter behavioral /
semantic metric. The flow-specific rate remains available in machine-readable
CSV output.
Rate cells show `numerator/denominator (percentage)`. B1/B2
repair metrics are N/A because these two baseline flows are one-shot.

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
| B2 | 0 | 0 | 0/0 (N/A) | N/A | N/A | N/A | N/A | N/A | N/A |
| F1 | 0 | 0 | 0/0 (N/A) | N/A | N/A | N/A | N/A | N/A | N/A |
| F2 | 0 | 0 | 0/0 (N/A) | N/A | N/A | N/A | N/A | N/A | N/A |
| F3 | 0 | 0 | 0/0 (N/A) | N/A | N/A | N/A | N/A | N/A | N/A |

Readability measures analyzability only. It is never used to infer semantic
correctness, behavioral equivalence, or Re-executability success.

## Data validity and historical limitations

- Validation: 0 error(s), 10 provenance warning(s).
- 0 run(s) violate the one-shot invariant and are excluded from
  eligible aggregates and paired inference.

- Exact five-tuple comparison is implemented for schema-v2 observations.
- Readability is N/A because no valid evaluator record exists. SLOC Ratio is N/A when the required common `clang-format`
  tool is unavailable.
- LLVM reduction measures simplification only and is not a correctness oracle.

See `data_validation_errors.csv` for every affected paired key.

## Main paired contrasts (Re-executability)

| Contrast | Metric | n | A | B | Difference | W/T/L |
|---|---|---|---|---|---|---|
| F1_VS_F2_CLEAN_IR_VS_RAW_IR | Re-executability Rate | 1 | 1 | 1 | 0 | 0/1/0 |
| F1_VS_F3_ITERATIVE_VS_ONESHOT | Re-executability Rate | 1 | 1 | 1 | 0 | 0/1/0 |
| B1_VS_B2_BASELINE_REPRESENTATIONS | Re-executability Rate | 1 | 0 | 1 | -1 | 0/0/1 |
| F1_VS_B1_CLEAN_IR_VS_GHIDRA_MULTIFACTOR | Re-executability Rate | 1 | 1 | 0 | 1 | 1/0/0 |
| F1_VS_B2_CLEAN_IR_VS_ASSEMBLY_MULTIFACTOR | Re-executability Rate | 1 | 1 | 1 | 0 | 0/1/0 |

F1 is Clean IR with an LLM repair loop; F2 is raw lifted IR with the same loop; F3 is Clean IR one-shot. B1/B2 are LLM4Decompile-style one-shot baselines from obfuscated-binary pseudocode/assembly. Statistical inference is marked underpowered when paired
n < 20; descriptive statistics are still emitted.

## Figures

- `overall_performance`: Primary recovery outcomes with executable availability over all eligible samples.
- `compilation_performance`: Compilation success before and after repair.
- `behavioral_performance`: Behavioral outcomes over conclusive campaigns.
- `repair_effectiveness`: Behavioral repair effectiveness; B1, B2, F3 repair fields are N/A.
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
