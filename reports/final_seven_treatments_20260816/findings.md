# Final observed results

This report is generated only from the 7 frozen campaigns listed in `final_analysis.json`. The 40 cases are paired by sample ID.

## Primary result

- B0 passed 10/40 cases (25.0%).
- B1 passed 39/40 cases (97.5%); the paired gain over B0 was 72.5% (95% CI 57.5% to 85.0%; exact McNemar p=3.725e-09).
- B1 is the feedback-policy ablation: it preserves B0's Ghidra representation and byte-identical first request, then permits validation-guided repair.
- B2 raw assembly one-shot passed 6/40 (15.0%); B3 raw assembly plus validation loop passed 38/40 (95.0%). Their paired delta was 80.0% (95% CI 67.5% to 92.5%; exact McNemar p=4.657e-10).
- The best F3 treatment was F3-O1, passing 38/40 cases (95.0%).
- Its paired absolute gain over B0 was 70.0% (paired bootstrap 95% CI 52.5% to 85.0%; exact McNemar p=5.774e-08).

## What the iterative loop contributed

Cases that eventually passed after parser, compiler, or behavioral feedback: B1=33, B3=33, F3-O1=11, F3-O2=15, F3-O3=14. Cases requiring multiple physical calls are reported separately because a `MAX_TOKENS` retry is not evidence that validation feedback helped.

## Interpretation boundary

B0 versus B1 isolates the configured feedback-policy difference on Ghidra pseudocode; B2 versus B3 isolates the same permission on raw objdump assembly. Both remain subject to stochastic model sampling because the first responses come from separate calls. B1/B3 versus F3 changes representation and prompt profile, so it is informative but not a complete factorial estimate of Clean IR alone. A Clean-IR one-shot arm and repeated model seeds would be needed for a full representation-by-feedback interaction and sampling-variance estimate. O1/O2/O3 differ only in the frozen standard LLVM optimization treatment and therefore provide the cleanest optimization-specific comparison. Native-contract compliance is reported separately from behavioral equivalence; compatibility-runnable IR is not called fully native.
