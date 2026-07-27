#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT_BIN="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
FILECHECK_BIN="${FILECHECK_BIN:-$(command -v FileCheck-21 || command -v FileCheck)}"
PLUGIN="${PLUGIN:-$ROOT/build/BrightenDevirtPass.so}"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" -passes=brighten-devirt-pass,verify \
  -S "$ROOT/tests/return_rax_reaching_definition.ll" -o - \
  | "$FILECHECK_BIN" "$ROOT/tests/return_rax_reaching_definition.ll"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" -passes=brighten-devirt-pass,verify \
  -S "$ROOT/tests/mutable_guest_pc.ll" -o - \
  | "$FILECHECK_BIN" "$ROOT/tests/mutable_guest_pc.ll"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" -passes=brighten-devirt-pass,verify \
  -S "$ROOT/tests/late_dispatcher_internalize.ll" -o - \
  | "$FILECHECK_BIN" "$ROOT/tests/late_dispatcher_internalize.ll"

TRANSFORMED="$(mktemp)"
REGION_TRANSFORMED="$(mktemp)"
SELF_HUB_TRANSFORMED="$(mktemp)"
CROSS_TRANSFORMED="$(mktemp)"
PHI_CARRIED_TRANSFORMED="$(mktemp)"
PHI_CROSS_TRANSFORMED="$(mktemp)"
SELF_CARRIED_REFUSED_TRANSFORMED="$(mktemp)"
HEADER_VALUE_REFUSED_TRANSFORMED="$(mktemp)"
EDGE_LOCAL_CARRIED_TRANSFORMED="$(mktemp)"
trap 'rm -f "$TRANSFORMED" "$REGION_TRANSFORMED" "$SELF_HUB_TRANSFORMED" "$CROSS_TRANSFORMED" "$PHI_CARRIED_TRANSFORMED" "$PHI_CROSS_TRANSFORMED" "$SELF_CARRIED_REFUSED_TRANSFORMED" "$HEADER_VALUE_REFUSED_TRANSFORMED" "$EDGE_LOCAL_CARRIED_TRANSFORMED"' EXIT
"$OPT_BIN" -load-pass-plugin "$PLUGIN" -passes=brighten-devirt-pass,verify \
  -S "$ROOT/tests/proven_state_switch.ll" -o "$TRANSFORMED"
"$FILECHECK_BIN" "$ROOT/tests/proven_state_switch.ll" < "$TRANSFORMED"

# Executable guard: both original and transformed state machines return 3.
set +e
lli-21 "$ROOT/tests/proven_state_switch.ll"
ORIGINAL_STATUS=$?
lli-21 "$TRANSFORMED"
TRANSFORMED_STATUS=$?
set -e
test "$ORIGINAL_STATUS" -eq 3
test "$TRANSFORMED_STATUS" -eq "$ORIGINAL_STATUS"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" -passes=brighten-devirt-pass,verify \
  -S "$ROOT/tests/dynamic_state_switch.ll" -o - \
  | "$FILECHECK_BIN" "$ROOT/tests/dynamic_state_switch.ll"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" -passes=brighten-devirt-pass,verify \
  -S "$ROOT/tests/carried_state_switch.ll" -o - \
  | "$FILECHECK_BIN" "$ROOT/tests/carried_state_switch.ll"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-region-ssa-unflatten-pass,verify \
  -S "$ROOT/tests/region_ssa_state_switch.ll" -o "$REGION_TRANSFORMED"
"$FILECHECK_BIN" "$ROOT/tests/region_ssa_state_switch.ll" \
  < "$REGION_TRANSFORMED"
set +e
lli-21 "$ROOT/tests/region_ssa_state_switch.ll"
REGION_ORIGINAL_STATUS=$?
lli-21 "$REGION_TRANSFORMED"
REGION_TRANSFORMED_STATUS=$?
set -e
test "$REGION_ORIGINAL_STATUS" -eq 3
test "$REGION_TRANSFORMED_STATUS" -eq "$REGION_ORIGINAL_STATUS"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-region-ssa-unflatten-pass,simplifycfg,adce,verify \
  -S "$ROOT/tests/region_ssa_self_hub.ll" -o "$SELF_HUB_TRANSFORMED"
"$FILECHECK_BIN" "$ROOT/tests/region_ssa_self_hub.ll" \
  < "$SELF_HUB_TRANSFORMED"
set +e
lli-21 "$ROOT/tests/region_ssa_self_hub.ll"
SELF_HUB_ORIGINAL_STATUS=$?
lli-21 "$SELF_HUB_TRANSFORMED"
SELF_HUB_TRANSFORMED_STATUS=$?
set -e
test "$SELF_HUB_ORIGINAL_STATUS" -eq 3
test "$SELF_HUB_TRANSFORMED_STATUS" -eq "$SELF_HUB_ORIGINAL_STATUS"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-region-ssa-unflatten-pass,verify \
  -S "$ROOT/tests/region_ssa_cross_carried.ll" -o "$CROSS_TRANSFORMED"
if grep -q 'region.thread' "$CROSS_TRANSFORMED"; then
  echo "FAIL: cross-carried region was partially threaded" >&2
  exit 1
fi

"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-region-ssa-unflatten-pass,simplifycfg,adce,verify \
  -S "$ROOT/tests/region_ssa_phi_carried.ll" -o "$PHI_CARRIED_TRANSFORMED"
"$FILECHECK_BIN" "$ROOT/tests/region_ssa_phi_carried.ll" \
  < "$PHI_CARRIED_TRANSFORMED"
set +e
lli-21 "$ROOT/tests/region_ssa_phi_carried.ll"
PHI_CARRIED_ORIGINAL_STATUS=$?
lli-21 "$PHI_CARRIED_TRANSFORMED"
PHI_CARRIED_TRANSFORMED_STATUS=$?
set -e
test "$PHI_CARRIED_ORIGINAL_STATUS" -eq 13
test "$PHI_CARRIED_TRANSFORMED_STATUS" -eq "$PHI_CARRIED_ORIGINAL_STATUS"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-region-ssa-unflatten-pass,verify \
  -S "$ROOT/tests/region_ssa_phi_cross_carried.ll" -o "$PHI_CROSS_TRANSFORMED"
"$FILECHECK_BIN" "$ROOT/tests/region_ssa_phi_cross_carried.ll" \
  < "$PHI_CROSS_TRANSFORMED"

# A header/self-carried value is not valid on a new direct edge that bypasses
# the header. These are matcher-level negative guards for the transactional
# refusal, while the edge-local case remains a positive rewrite.
"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-region-ssa-unflatten-pass,verify \
  -S "$ROOT/tests/region_ssa_self_carried_refused.ll" \
  -o "$SELF_CARRIED_REFUSED_TRANSFORMED"
"$FILECHECK_BIN" "$ROOT/tests/region_ssa_self_carried_refused.ll" \
  < "$SELF_CARRIED_REFUSED_TRANSFORMED"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-region-ssa-unflatten-pass,verify \
  -S "$ROOT/tests/region_ssa_header_value_refused.ll" \
  -o "$HEADER_VALUE_REFUSED_TRANSFORMED"
"$FILECHECK_BIN" "$ROOT/tests/region_ssa_header_value_refused.ll" \
  < "$HEADER_VALUE_REFUSED_TRANSFORMED"

"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-region-ssa-unflatten-pass,simplifycfg,adce,verify \
  -S "$ROOT/tests/region_ssa_edge_local_carried.ll" \
  -o "$EDGE_LOCAL_CARRIED_TRANSFORMED"
"$FILECHECK_BIN" "$ROOT/tests/region_ssa_edge_local_carried.ll" \
  < "$EDGE_LOCAL_CARRIED_TRANSFORMED"
set +e
lli-21 "$ROOT/tests/region_ssa_edge_local_carried.ll"
EDGE_LOCAL_ORIGINAL_STATUS=$?
lli-21 "$EDGE_LOCAL_CARRIED_TRANSFORMED"
EDGE_LOCAL_TRANSFORMED_STATUS=$?
set -e
test "$EDGE_LOCAL_ORIGINAL_STATUS" -eq 12
test "$EDGE_LOCAL_TRANSFORMED_STATUS" -eq "$EDGE_LOCAL_ORIGINAL_STATUS"

# The full production pipeline supplies its linked candidate explicitly. This
# keeps the 020 unit suite hermetic while retaining the frozen p00033
# differential gate in the owner pass's lifecycle.
if [[ -n "${P00033_CANDIDATE:-}" ]]; then
  python3 "$ROOT/tests/test_p00033_lifecycle.py" \
    --candidate "$P00033_CANDIDATE" \
    --reference "${P00033_REFERENCE:-$ROOT/../../../data/obfuscated/p00033/s763935897_fla_bcf_instsub.elf}"
fi

echo "Brighten devirtualization tests: PASS"
