#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT_BIN="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
FILECHECK_BIN="${FILECHECK_BIN:-$(command -v FileCheck-21 || command -v FileCheck)}"
PASS_PIPELINE="brighten-repair-pass,brighten-devirt-pass,globaldce,always-inline,brighten-stack-frame-pass,brighten-state-ssa-pass,brighten-global-data-pass,brighten-abi-recovery-pass,deadargelim,always-inline,globaldce,sroa,early-cse,instcombine<no-verify-fixpoint>,simplifycfg,brighten-type-reconstruct-pass,gvn,dce,brighten-native-cleanup-pass,deadargelim,globaldce"
PLUGINS=(
  "$ROOT/brighten_010_repair_pass/build/BrightenRepairPass.so"
  "$ROOT/brighten_020_devirt_pass/build/BrightenDevirtPass.so"
  "$ROOT/brighten_030_state_ssa_pass/build/BrightenStateSSAPass.so"
  "$ROOT/brighten_040_stack_frame_pass/build/BrightenStackFramePass.so"
  "$ROOT/brighten_050_abi_recovery_pass/build/BrightenABIRecoveryPass.so"
  "$ROOT/brighten_060_global_data_pass/build/BrightenGlobalDataPass.so"
  "$ROOT/brighten_070_type_reconstruct_pass/build/BrightenTypeReconstructPass.so"
  "$ROOT/brighten_080_native_cleanup_pass/build/BrightenNativeCleanupPass.so"
)

if [[ -z "${OPT_BIN:-}" || ! -x "$OPT_BIN" ]]; then
  echo "ERROR: opt not found" >&2
  exit 1
fi
if [[ -z "${FILECHECK_BIN:-}" || ! -x "$FILECHECK_BIN" ]]; then
  echo "ERROR: FileCheck not found" >&2
  exit 1
fi

for plugin in "${PLUGINS[@]}"; do
  if [[ ! -f "$plugin" ]]; then
    echo "ERROR: plugin not found at $plugin" >&2
    exit 1
  fi
done

for test_file in "$ROOT"/tests/*.ll; do
  echo "RUN $(basename "$test_file")"
  cmd=("$OPT_BIN")
  for plugin in "${PLUGINS[@]}"; do
    cmd+=(-load-pass-plugin "$plugin")
  done
  cmd+=(-passes "$PASS_PIPELINE" -S "$test_file" -o -)
  "${cmd[@]}" | "$FILECHECK_BIN" "$test_file"
done

echo "All full-pipeline llvm_pass tests passed."
