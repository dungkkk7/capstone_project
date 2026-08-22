# Five-flow evaluation protocol

This is the active protocol. It contains exactly five flows: `B1`, `B2`,
`F1`, `F2`, and `F3`. `O1/O2/O3` are LLVM implementation settings, not flow
IDs or experimental treatments in this protocol.

## Input and reference

Each row of `data/custom_dataset.csv` names one stripped, obfuscated x86-64 ELF
and its source/input-contract metadata. The behavioral oracle is the original
obfuscated ELF. The source is used only to build the paired artifact and its
input contract; it is never sent to the model.

## Flow contracts

| Flow | Artifact sent to the LLM | Prompt/policy | LLM loop |
|---|---|---|---|
| `B1` | Ghidra pseudocode exported directly from the obfuscated binary | LLM4Decompile paper-derived Ghidra prompt, no system prompt | one-shot |
| `B2` | deterministic objdump assembly exported directly from the obfuscated binary | LLM4Decompile assembly wrapper, no system prompt | one-shot |
| `F1` | Clean LLVM IR after lifting and the custom cleanup pipeline | project evidence-grounded IR prompt | iterative, up to 5 calls |
| `F2` | Raw LLVM IR directly after lifting, before the cleanup pipeline | project raw-IR prompt | iterative, up to 5 calls |
| `F3` | the same Clean LLVM IR as F1 | project evidence-grounded IR prompt | one-shot, no repair loop |

`B1/B2` are the two binary-to-representation baselines. They must never receive
Clean IR, Raw IR, or a pipeline-produced binary. `F1/F2/F3` are the three IR
flows: Clean IR with loop, Raw IR with loop, and Clean IR without loop.

The F-flow input distinction is represented in the code by
`FlowSpec.requires_clean_ir`, `FlowSpec.requires_raw_ir`, and
`FlowSpec.iterative`. It is not represented by an `O1/O2/O3` suffix.

## Verification

Every generated candidate is compiled and compared with the original
obfuscated ELF using the input contract. The observation tuple includes stdout,
stderr, exit code, terminating signal, and timeout status. Fuzzing uses the
declared campaign budget. F3 still undergoes behavioral validation; it simply
cannot issue a second LLM request after its first candidate.

## Full campaign

```bash
cd /home/dungbv/clau
BRIGHTEN_OPT_TIMEOUT=0 rtk python3 src/evaluation/run_experiment.py \
  data/custom_dataset.csv \
  --max-workers 15 \
  --fuzz-iterations 1000
```

The expected cardinality for the 40-row dataset is 200 `flow_result.json`
files: 40 cases × 5 flows. Reports are written under
`reports/experiment_<timestamp>/` and must contain only the five active IDs.
