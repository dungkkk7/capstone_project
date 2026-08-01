#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT="${OPT:-$(command -v opt-21 || command -v opt)}"
FILECHECK="${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}"
PLUGIN="$ROOT/build/BrightenABIRecoveryPass.so"

[[ -x "$OPT" ]]
[[ -x "$FILECHECK" ]]
[[ -f "$PLUGIN" ]]

for Test in "$ROOT"/tests/*.ll; do
  [[ "$Test" == "$ROOT/tests/test_guest_boundary_clone.ll" ]] && continue
  "$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-abi-recovery-pass \
    -verify-each -S "$Test" | "$FILECHECK" "$Test"
done

BOUNDARY_OUT="$(mktemp)"
BOUNDARY_O3_OUT="$(mktemp)"
BOUNDARY_DEFAULT_OUT="$(mktemp)"
trap 'rm -f "$BOUNDARY_OUT" "$BOUNDARY_O3_OUT" "$BOUNDARY_DEFAULT_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-abi-recovery-pass,verify \
  -S "$ROOT/tests/test_guest_boundary_clone.ll" -o "$BOUNDARY_DEFAULT_OUT"
! grep -q 'brighten.preserve.guest.boundary' "$BOUNDARY_DEFAULT_OUT"
! grep -Eq 'define internal.*noinline.*@sub_pinned\.native' "$BOUNDARY_DEFAULT_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-abi-recovery-pass,verify \
  -brighten-050-preserve-guest-boundary \
  -S "$ROOT/tests/test_guest_boundary_clone.ll" -o "$BOUNDARY_OUT"
grep -Eq 'define internal.*@sub_pinned\.native.*#[0-9]+' "$BOUNDARY_OUT"
grep -q 'noinline "brighten.preserve.guest.boundary"="v1"' "$BOUNDARY_OUT"
! grep -Eq 'define internal.*noinline.*@sub_plain\.native' "$BOUNDARY_OUT"
"$OPT" -passes='default<O3>,verify' -S "$BOUNDARY_OUT" -o "$BOUNDARY_O3_OUT"
grep -Eq 'call.*@sub_pinned\.native' "$BOUNDARY_O3_OUT"
grep -Eq 'define internal.*@sub_pinned\.native' "$BOUNDARY_O3_OUT"

ScanfTest="$ROOT/tests/test_scanf_i32_boundary.ll"
"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-abi-recovery-pass \
  -verify-each -S "$ScanfTest" | \
  "$OPT" -passes='default<O3>,verify' -S | \
  "$FILECHECK" --check-prefix=O3 "$ScanfTest"

echo "ABI recovery tests: PASS"
