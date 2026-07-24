# ĐẶC TẢ TRIỂN KHAI B0, A0 VÀ EVALUATION CHO PIPELINE P0

**Phiên bản:** 1.0 — 23/07/2026  
**Trạng thái:** Implementation-ready

## Quyết định bắt buộc

- **B0:** original obfuscated ELF → Ghidra full obfuscated pseudocode only → common LLM → C → common evaluator.
- **A0:** original obfuscated ELF → McSema raw `.ll` only → common LLM → C → common evaluator.
- **P0:** full current enhancement pipeline → brightened/simplified IR + C-like/Ghidra pseudocode → common LLM → C → common evaluator.
- **Primary protocol:** `strict_one_shot`: exactly one model call; no compiler feedback; no test/fuzz feedback; no regeneration.
- **Final oracle:** original obfuscated ELF for all methods.
- **Common inputs:** same frozen ordered input bytes and hashes for P0/A0/B0 of each sample.
- **Independent branches:** P0 brightening/precheck failure must not stop B0/A0.
- **No leakage:** clean source, expected output, semantic reports and counterexamples must never enter LLM requests.

## Current gaps that must be fixed

The supplied current P0 log shows `max_iter=5`, candidate fuzz feedback, a hybrid P0 request containing Ghidra pseudocode plus brightened `.ll`, and final candidate comparison against `brightened_ref.bin`. The experiment runner must separate strict evaluation from this engineering loop, preserve the latter as `iterative_repair`, and compare all final candidates directly to the original obfuscated binary.

## Target modules

```text
src/experiments/
  models.py
  config.py
  runner.py
  representations.py
  evaluator.py
  corpus.py
  persistence.py
  aggregate.py
```

`src/llm_recovery/llm_recovery.py` exposes a generation-only `generate_candidate(request)`. `fuzzing.py` supports replay of `precomputed_inputs`.

## CLI

```bash
python3 src/main.py data/custom_dataset.csv experiment \
  --methods P0,A0,B0 \
  --protocol strict_one_shot \
  --config configs/experiment_primary.yaml \
  --pilot 1
```

## Required acceptance checks

1. B0 request has no `.ll`, `.bc`, `_brightened` artifact and decompiles the original ELF.
2. A0 primary hash equals the raw McSema `.ll` hash; no P0 pass/optimization/Ghidra call occurs.
3. P0 contains brightened IR plus P0 pseudocode and may have its own precheck.
4. Every strict request has `model_call_count == 1` and no feedback/regeneration.
5. `reference_sha256` and `corpus_manifest_sha256` are identical across variants for a sample.
6. Every enrolled sample/variant has a terminal result and remains in the denominator.
7. Resume is idempotent and variant order does not affect request/evaluation hashes.

The full DOCX contains the detailed architecture, dataclasses, JSON schema, file-by-file PR plan, unit/integration tests, pilot checklist and a copy-ready coding-agent prompt.
