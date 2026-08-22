# Five-flow source recovery evaluation

Experiment: `experiment_20260821_162746`

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

| Flow | N | Eligible N | First-pass RSR | Final RSR@R | Program Behavioral Pass Rate | Initial Behavioral Pass Rate | Final Behavioral Pass Rate | Input Match Macro | Input Match Micro | Counterexample Detection Rate | Re-executability Rate | Canonical E2E Rate | Flow-specific Recovery Rate | Compilation Repair Gain | Behavioral Repair Gain | Mean Tokens | Mean Runtime | Mean API Cost |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| B1 | 40 | 40 | 4/4 (100.0%) | 4/4 (100.0%) | 4/4 (100.0%) | 4/4 (100.0%) | 4/4 (100.0%) | 100.0% | 100.0% | 0/4 (0.0%) | 4/40 (10.0%) | 4/40 (10.0%) | 4/40 (10.0%) | N/A | N/A | 62534 | 48.0s | N/A |
| B2 | 40 | 40 | 33/37 (89.2%) | 33/37 (89.2%) | 7/33 (21.2%) | 7/33 (21.2%) | 7/33 (21.2%) | 31.7% | 32.2% | 26/33 (78.8%) | 33/40 (82.5%) | 7/40 (17.5%) | 7/40 (17.5%) | N/A | N/A | 75224 | 61.1s | N/A |
| F1 | 40 | 40 | 39/39 (100.0%) | 39/39 (100.0%) | 36/39 (92.3%) | 26/39 (66.7%) | 36/39 (92.3%) | 93.7% | 96.4% | 3/39 (7.7%) | 39/40 (97.5%) | 36/40 (90.0%) | 36/40 (90.0%) | +0.0 pp | +25.6 pp | 266027 | 151.6s | N/A |
| F2 | 40 | 40 | 38/38 (100.0%) | 38/38 (100.0%) | 26/38 (68.4%) | 11/38 (28.9%) | 26/38 (68.4%) | 78.8% | 81.4% | 12/38 (31.6%) | 38/40 (95.0%) | 26/40 (65.0%) | 26/40 (65.0%) | +0.0 pp | +39.5 pp | 1335857 | 360.4s | N/A |
| F3 | 40 | 40 | 35/35 (100.0%) | 35/35 (100.0%) | 23/35 (65.7%) | 23/35 (65.7%) | 23/35 (65.7%) | 83.8% | 87.6% | 12/35 (34.3%) | 35/40 (87.5%) | 23/40 (57.5%) | 23/40 (57.5%) | N/A | N/A | 103672 | 63.7s | N/A |

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

| Flow | Accepted | Evaluated | Coverage | SLOC Evaluated | Original SLOC | Recovered SLOC | SLOC Ratio | Variables | Loops | Conditions | Logic flow | Structural integrity | Overall | Evaluator Overall | Overall Source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| B1 | 4 | 4 | 4/4 (100.0%) | 4 | 69.5 | 363.8 | 5.540 | 1.50 | 2.50 | 2.00 | 2.25 | 2.00 | 3.25 | 2.05 | MANUAL_OVERRIDE |
| B2 | 7 | 7 | 7/7 (100.0%) | 7 | 105.9 | 40.1 | 0.702 | 3.86 | 4.57 | 4.43 | 4.57 | 4.43 | 2.95 | 4.37 | MANUAL_OVERRIDE |
| F1 | 36 | 36 | 36/36 (100.0%) | 36 | 111.2 | 63.2 | 0.933 | 3.42 | 4.17 | 4.03 | 4.14 | 4.11 | 3.97 | 3.97 | EVALUATOR |
| F2 | 26 | 26 | 26/26 (100.0%) | 26 | 118.8 | 53.8 | 0.810 | 3.85 | 4.65 | 4.58 | 4.73 | 4.62 | 3.42 | 4.48 | MANUAL_OVERRIDE |
| F3 | 23 | 23 | 23/23 (100.0%) | 23 | 123.1 | 53.2 | 0.830 | 3.52 | 4.35 | 4.04 | 4.35 | 4.09 | 3.50 | 4.07 | MANUAL_OVERRIDE |

Manual source-quality Overall overrides are applied for report presentation: B1=3.25, B2=2.95, F2=3.42, F3=3.50. User-specified manual flow-level source-quality target; raw evaluator records are preserved.

Readability measures analyzability only. It is never used to infer semantic
correctness, behavioral equivalence, or Re-executability success. `Evaluator
Overall` remains the raw evaluator aggregate; `Overall` is the report value.

## Data validity and historical limitations

- Validation: 0 error(s), 403 provenance warning(s).
- 0 run(s) violate the one-shot invariant and are excluded from
  eligible aggregates and paired inference.

- Exact five-tuple comparison is implemented for schema-v2 observations.
- Readability scores are available from persisted evaluator records. SLOC uses `clang-format` when available and a documented
  lexical comment-stripped fallback otherwise; it is N/A only when a source
  artifact is missing.
- LLVM reduction measures simplification only and is not a correctness oracle.

See `data_validation_errors.csv` for every affected paired key.

## Main paired contrasts (Re-executability)

| Contrast | Metric | n | A | B | Difference | W/T/L |
|---|---|---|---|---|---|---|
| F1_VS_F2_CLEAN_IR_VS_RAW_IR | Re-executability Rate | 40 | 0.975 | 0.95 | 0.025 | 2/37/1 |
| F1_VS_F3_ITERATIVE_VS_ONESHOT | Re-executability Rate | 40 | 0.975 | 0.875 | 0.1 | 4/36/0 |
| B1_VS_B2_BASELINE_REPRESENTATIONS | Re-executability Rate | 40 | 0.1 | 0.825 | -0.725 | 2/7/31 |
| F1_VS_B1_CLEAN_IR_VS_GHIDRA_MULTIFACTOR | Re-executability Rate | 40 | 0.975 | 0.1 | 0.875 | 35/5/0 |
| F1_VS_B2_CLEAN_IR_VS_ASSEMBLY_MULTIFACTOR | Re-executability Rate | 40 | 0.975 | 0.825 | 0.15 | 7/32/1 |

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
