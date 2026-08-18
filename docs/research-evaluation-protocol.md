# Research and evaluation protocol

Status: protocol draft implemented in code; numerical results are not yet
available. Protocol version: `two-flow-b0-f3-v1`.

## 1. Research claim

The project does not claim a newly trained or fine-tuned LLM. The recovery
model is used as an unchanged external component. McSema/Remill, Ghidra and
AFL++ are also not modified.

The proposed contribution is narrower and testable:

1. a source-grounded LLVM recovery/deobfuscation pipeline (passes 010–100)
   with explicit proof/refusal boundaries for lifted state, ABI, storage,
   globals, CFF/BCF/MBA and final native-contract recovery;
2. an empirical analysis of when standard LLVM optimization (`O1`, `O2`,
   `O3`) helps or harms that custom pipeline;
3. an end-to-end recovery configuration that gives Clean IR to an unchanged
   LLM and repairs candidates only from compiler diagnostics and reproducible
   behavioral counterexamples.

The LLM, Ghidra and AFL++ integration is system infrastructure, not the novelty
claim by itself.

## 2. Where optimization is used

`BRIGHTEN_OPT_LEVEL=O1|O2|O3` selects one registered treatment for all standard
LLVM optimization points. It does not select or disable the custom passes.

| Boundary | Before optimizer | Why standard optimization is used | Consumer after optimizer |
|---|---|---|---|
| Main pipeline, treatment 1 | pass 095, late devirtualization/ABI/type recovery and scalar CFG cleanup | expose constants, simplify dispatcher residue, promote scalar storage | native cleanup, ABI/extern bridge and residual-string recovery |
| Main pipeline, treatment 2 | local-state SSA, region unflattening, jump threading and scalar cleanup | converge loop/CFG and remove dead lifted state | final address/frame/heap cleanup and native-contract reporter |
| Delift bundle, treatment 1 | verified input and exact pointer passes | canonicalize storage access before storage delifting | `delift_storage.py` |
| Delift bundle, treatment 2 | storage delift and residual unpinning | clean artifacts introduced by delifting | deterministic MBA-only 095 and bounded scalar/native cleanup |

Vectorization and loop unrolling remain disabled at these boundaries because
the target is analyzable source recovery, not code-generation speed. The final
executable is always compiled with the same `-O2` code-generation setting, so
the independent variable is the IR optimization treatment, not the machine
code compiler setting.

The exact pass order and refusal rules are documented in
[`docs/llvm-passes`](llvm-passes/README.md). The source of truth is
`src/llvm_pass/britening_ir.py` plus the pass-100 bundle script.

## 3. Primary end-to-end comparison

There are exactly two primary LLM flows.

| ID | Input path | LLM policy | Role |
|---|---|---|---|
| `B0` | original obfuscated ELF → Ghidra Headless → program pseudocode | one provider call; no compiler/test/counterexample feedback | external baseline |
| `F3` | original obfuscated ELF → McSema → custom pass 010–100 → Clean IR | up to five calls; compiler and reproducible-counterexample repair | proposed method |

`B0` uses the instruction printed in Section 4.2.1 of
[LLM4Decompile](https://arxiv.org/abs/2403.05286v3): the paper's Ghidra-to-LLM
refinement baseline. The paper instruction is byte-frozen in
`src/evaluation/two_flow_protocol.py`. The repository-owned serialization
choice (instruction, two linefeeds, raw Ghidra export) is recorded separately;
it is not misrepresented as text specified by the paper.

Both flows must use the same model version, temperature, output budget,
eligible cases, obfuscated reference ELF, valid-input domain and fuzz budget.
They also use one frozen provider region (default `us-central1`); a region
failure is recorded instead of silently retrying elsewhere.
Ghidra receives the original ELF and is forbidden from consuming a brightened,
final or recovered artifact. B0 compilation/fuzzing occurs only after its one
model call and never feeds back into the model.

The historical multi-flow experiment is an exploratory artifact only. Its
rows and percentages remain auditable but are excluded from the primary claim
and must not be relabeled as B0 results.

### 3.1 Registered representation/feedback ablations

The final analysis adds three non-primary treatments without changing the
frozen B0/F3 claim:

| ID | Frozen evidence | First request | Later requests | Question isolated |
|---|---|---|---|---|
| `B1` | same Ghidra export as B0 | byte-identical to B0 | validation feedback, at most five responses | effect of allowing repair on Ghidra evidence |
| `B2` | original ELF → `objdump -d` → cleaned raw assembly | exact LLM4Decompile assembly template | none | paper-derived raw-assembly one-shot baseline |
| `B3` | byte-identical assembly and first prompt as B2 | byte-identical to B2 | validation feedback, at most five responses | effect of allowing repair on assembly evidence |

B2 follows the End2End representation and prompt shown in Section 4.1.1 of
[LLM4Decompile](https://arxiv.org/html/2403.05286v3) and its
[official repository](https://github.com/albertan017/LLM4Decompile): disassemble
with `objdump -d`, remove address/machine-byte columns and `#` comments, then
serialize `# This is the assembly code:\n[ASM]\n# What is the source code?\n`.
The paper example extracts one function; because the evaluation unit here is a
complete command-line program with helpers, the registered exporter applies
the same deterministic cleaning to every function in the original ELF. This
program-level extension is explicit in each representation manifest. B3 is
not claimed as a paper treatment: it is the repository's feedback-policy
ablation over B2.

## 4. Optimization-level study

Run `F3` at `O1`, `O2` and `O3` on the same frozen cases. B0 is invariant to
this factor and is not interpreted as an optimization-level treatment.

Primary questions:

- RQ1: Does F3 improve Canonical E2E recovery over B0?
- RQ2: For which program/IR categories does `O3` improve over `O1`/`O2`?
- RQ3: For which cases does a higher level lose semantic validity, native-
  contract compliance, structural recovery, or source analyzability?
- RQ4: Does the F3-over-B0 effect persist on `own_dataset`?

Do not assume that `O3` is globally best. Report per-case transitions such as
`O2 PASS → O3 FAIL`, and inspect the last verified checkpoint plus pass-095
report for each transition. Group failures by the first failing boundary:
verification, native contract, compilation, behavioral oracle, or recovery.

## 5. Data-contamination protocol

The 40 `pXXXXX/sXXXXXXXXX` cases are treated as a public-corpus evaluation set.
They may be useful for regression and historical comparability, but they cannot
by themselves refute training-data contamination.

The primary contamination-resistant set is `data/own_dataset`:

- 40 exact C11 program instances created on 2026-08-15;
- eight feature categories with five cases each;
- source and seed SHA-256, frozen stdout oracle and creation provenance;
- source, seed, oracle and manifest excluded from every recovery prompt;
- separate result table and denominator from the public set;
- any post-freeze edit requires a new dataset version.

This follows the defensible direction used by later decompilation work: create
manually crafted or post-cutoff evaluation material to mitigate leakage. See
[Decompile-Bench](https://arxiv.org/abs/2505.12668), whose evaluation includes
manually crafted binaries and post-2025 repositories for that reason.

The claim boundary is important: a new exact source/hash makes verbatim answer
memorization implausible, but does not prove that a model has never learned the
underlying algorithms. Report this as contamination-resistant evidence, never
as proof of zero training overlap. Codex assistance used to author the exact
instances is recorded in the manifest rather than hidden.

## 6. Metrics and statistical analysis

Primary metric: Canonical E2E rate over all eligible cases. A success requires
generation, compilation and no reproducible divergence under the registered
valid-input domain and budget. “No divergence found” is not universal semantic
equivalence. A registered case is eligible once its original reference ELF and
valid-input contract pass the preflight gate. Subsequent Ghidra, lifting,
custom-pass, generation or compilation failures remain in the denominator;
they are not silently dropped.

Secondary metrics:

- executable availability;
- first/final behavioral pass rate;
- instruction/basic-block/conditional-branch counts;
- native-contract status;
- model calls, provider tokens and wall-clock runtime;
- failure category and first failing pipeline boundary.

Use paired statistics because every treatment runs on the same cases. Report
the paired success difference with a confidence interval and an exact McNemar
test for B0 versus F3 and for each optimization-level pair. With 40 repository-
owned cases, always show raw numerator/denominator and per-case outcomes; do not rely
on a p-value alone. Readability is optional and may only be evaluated on
behaviorally accepted sources, with its selection bias stated explicitly.

## 7. Reproduction gates

Before the first provider call:

1. run `python3 tools/build_own_dataset.py --plain-only`;
2. rebuild all 40 repository-owned OLLVM-style binaries and verify pass markers
   plus the obfuscated seed oracle;
3. freeze Git commit, model ID, prompt hash, Ghidra version, LLVM version,
   pass pipeline, optimization level, source/binary/seed hashes and fuzz
   configuration;
4. run a one-case B0/F3 pilot without changing prompt/pass policy afterward;
5. start new campaign IDs for `O1`, `O2` and `O3`; never resume across a
   fingerprint change.

Commands and expected artifact locations are documented in the root README.
