# Binary Deobfuscation with LLVM & LLM Recovery Loop

An automated binary deobfuscation framework combining native LLVM IR brightening with an LLM-guided source code recovery and verification loop.

## Architecture & Workflow

The framework operates on a pipeline that automates binary deobfuscation and recovers clean, functionally equivalent C source code:

1. **Lifting**: Obfuscated binaries are analyzed and lifted to LLVM Bitcode (`.bc`) using McSema with IDA Pro.
2. **Brightening & Optimization**: The lifted IR undergoes iterative register simplification, control flow normalization, type reconstruction, and dead-code elimination.
3. **Differential Fuzzing**: A semantic equivalence check is performed on the brightened IR against the original obfuscated binary using AFL++-based differential fuzzing.
4. **IDA Pro Decompilation**: The optimized IR is compiled back to an unoptimized (`-O0`) binary and loaded into IDA Pro headlessly to extract candidate pseudocode for key user functions.
5. **LLM Recovery & Correction Loop**:
   - The raw pseudocode is fed into **DeepSeek V4 Pro** (or local agent models) with prompt templates instructing it to remove McSema register boilerplate and reconstruct clean C code.
   - The recovered C code is compiled. If compilation fails, the error compiler context is sent back to the LLM to fix it.
   - Once it compiles, differential fuzzing checks semantic equivalence against the original binary. If mismatches are found, the inputs/expected outputs are collected and sent back to the LLM for correction.
   - The loop continues until a 100% semantically equivalent C source is successfully generated.

## Prerequisites

- **IDA Pro 9.3+** (installed at `/opt/ida-pro-9.3/` with Hex-Rays x64 decompiler plugin).
- **LLVM / Clang 21** (installed as `clang-21`, `llvm-dis-21`, etc.).
- **AFL++** (for differential fuzzing and seed generation).
- **Python 3.8+** with the following packages:
  - `requests`
  - `simplejson`

## Configuration

To use the LLM Recovery Loop, configure the following environment variables:

```bash
export DEEPSEEK_API_KEY="your_api_key_here"
# Optional overrides:
export DEEPSEEK_API_BASE="https://api.deepseek.com/chat/completions"
export DEEPSEEK_MODEL="deepseek-chat"
export LLM_RECOVERY_MAX_ITERS="5"
```

## Running the Pipeline

Execute the pipeline by providing a CSV file containing the list of obfuscated binaries:

```bash
python3 src/main.py data/obfuscated_bin_list.csv
```

Pipeline output (lifted bitcode, brightened IR, raw pseudocode, and final recovered C source code) is stored under the `result/pipeline_<timestamp>/` directory structure.
