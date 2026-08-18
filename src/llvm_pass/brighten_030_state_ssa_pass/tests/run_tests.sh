#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT_BIN="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
FILECHECK_BIN="${FILECHECK_BIN:-$(command -v FileCheck-21 || command -v FileCheck)}"
PLUGIN="${PLUGIN:-$ROOT/build/BrightenStateSSAPass.so}"

for test in \
  state_promotion_boundaries \
  flag_memory_observability \
  raw_flag_phi_preserved \
  local_state_alloca_promotion \
  state_register_write_semantics; do
  "$OPT_BIN" -load-pass-plugin "$PLUGIN" \
    -passes=brighten-state-ssa-pass,verify -S \
    "$ROOT/tests/$test.ll" -o - \
    | "$FILECHECK_BIN" "$ROOT/tests/$test.ll"
done

"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-local-state-ssa-pass,brighten-local-state-ssa-pass,verify -S \
  "$ROOT/tests/local_state_alloca_promotion.ll" -o - \
  | "$FILECHECK_BIN" "$ROOT/tests/local_state_alloca_promotion.ll"

echo "Brighten State SSA tests: PASS"
