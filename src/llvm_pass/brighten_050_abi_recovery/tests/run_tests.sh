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
  "$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-abi-recovery-pass \
    -verify-each -S "$Test" | "$FILECHECK" "$Test"
done

echo "ABI recovery tests: PASS"
