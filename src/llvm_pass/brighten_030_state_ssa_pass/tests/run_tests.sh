#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT_BIN="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
FILECHECK_BIN="${FILECHECK_BIN:-$(command -v FileCheck-21 || command -v FileCheck)}"
LLI_BIN="${LLI_BIN:-$(command -v lli-21 || command -v lli)}"
PLUGIN="${PLUGIN:-$ROOT/build/BrightenStateSSAPass.so}"

for test in state_promotion_boundaries flag_memory_observability raw_flag_phi_preserved local_state_alloca_promotion local_state_alloca_big_endian global_state_overlap global_state_overlap_big_endian; do
  "$OPT_BIN" -load-pass-plugin "$PLUGIN" \
    -passes=brighten-state-ssa-pass,verify -S \
    "$ROOT/tests/$test.ll" -o - \
    | "$FILECHECK_BIN" "$ROOT/tests/$test.ll"
done

global_overlap_bc="$(mktemp --suffix=.bc)"
trap 'rm -f "$global_overlap_bc"' EXIT
"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-state-ssa-pass,verify \
  "$ROOT/tests/global_state_overlap.ll" -o "$global_overlap_bc"
"$LLI_BIN" "$ROOT/tests/global_state_overlap.ll"
"$LLI_BIN" "$global_overlap_bc"

runtime_bc="$(mktemp --suffix=.bc)"
trap 'rm -f "$runtime_bc"' EXIT
"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-local-state-ssa-pass,verify \
  "$ROOT/tests/local_state_alloca_promotion.ll" -o "$runtime_bc"
"$LLI_BIN" "$ROOT/tests/local_state_alloca_promotion.ll"
"$LLI_BIN" "$runtime_bc"

python3 "$ROOT/tests/property_validate.py" --plugin "$PLUGIN"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-local-state-ssa-pass,brighten-local-state-ssa-pass,verify -S \
  "$ROOT/tests/local_state_alloca_promotion.ll" -o - \
  | "$FILECHECK_BIN" "$ROOT/tests/local_state_alloca_promotion.ll"

echo "Brighten State SSA tests: PASS"
