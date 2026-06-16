# refine_semantic_pass

Refine pass moi (lam lai tu dau) cho lifted IR.

## Kien truc

- `src/main.cpp`: entry duy nhat cua pass plugin + `run(...)`.
- Moi van de semantic nam o 1 rule rieng:
  - `src/RuleStripPoisonDrivingFlags.cpp`
  - `src/RuleForwardMcSemaFlagLoads.cpp`
  - `src/RulePruneDeadMcSemaFlagStores.cpp`
  - `src/RulePruneDeadRipStores.cpp`
  - `src/RuleForwardMcSemaStateLoads.cpp`
  - `src/RuleForwardMcSemaGuestStackSlots.cpp`
  - `src/RuleHardenUnsafeScanf.cpp`
  - `src/RuleCanonicalizeObfuscatedCompares.cpp`
  - `src/RuleSanitizeDangerousStrlen.cpp`
  - `src/RuleNormalizeRemillFunctionCalls.cpp`
- `src/Helpers.cpp`: helper dung chung.

## Muc tieu hien tai

1. Giam UB/poison do flag IR qua manh:
- xoa `nsw` / `nuw` tren integer arithmetic.
- xoa `inbounds` tren `getelementptr`.

2. On dinh hoa call remill bi sai target:
- tim `call @__remill_function_call(..., i64 <const_pc>, ...)`.
- neu co lifted subroutine `@sub_<hex(pc)>` thi doi thanh call truc tiep den subroutine do.
- neu khong resolve duoc target thi doi sang helper no-op `@__lifter_refine_noop_call` de tranh crash hard do jump vao host address invalid.

## Build

```bash
cd /home/dungbv/WorkSpace/lifter/third_party/llvm_custome/refine_semantic_pass
cmake -S . -B build \
  -DLLVM_DIR=/home/dungbv/WorkSpace/lifter/third_party/lifting-bits-downloads/vcpkg_ubuntu-20.04_llvm-11_amd64/installed/x64-linux-rel/share/llvm
cmake --build build -j
```

Artifact:
- `build/RefineSemanticPass.so`

## Test (test-first)

```bash
cd /home/dungbv/WorkSpace/lifter/third_party/llvm_custome/refine_semantic_pass
./tests/run_tests.sh
```

Test cases:
- `tests/ub_flags.ll`
- `tests/remill_call_resolve.ll`
- `tests/remill_call_unresolved.ll`

## Integrate vao pipeline

```bash
REFINE_PASS_PLUGIN=/home/dungbv/WorkSpace/lifter/third_party/llvm_custome/refine_semantic_pass/build/RefineSemanticPass.so \
REFINE_PASS_PIPELINE=refine-semantic-pass \
REQUIRE_REFINE_PASS=1 \
EXTERNAL_LIFTER_CMD="bash /home/dungbv/WorkSpace/lifter/tools/external_lifter_remill.sh --in {input_binary} --out-ir {ir_out} --work-dir {work_dir}" \
bash /home/dungbv/WorkSpace/lifter/tools/run_lifter_pipeline.sh
```
