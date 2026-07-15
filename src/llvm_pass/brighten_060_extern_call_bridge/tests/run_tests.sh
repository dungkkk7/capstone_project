#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT="${OPT:-$(command -v opt-21 || command -v opt)}"
PLUGIN="$ROOT/build/BrightenExternCallBridgePass.so"
FILECHECK="${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}"

[[ -x "$OPT" ]]
[[ -f "$PLUGIN" ]]
[[ -x "$FILECHECK" ]]

for Test in "$ROOT"/tests/*.ll; do
  if grep -q 'CHECK:' "$Test"; then
    "$OPT" -load-pass-plugin="$PLUGIN" \
      -passes=brighten-extern-call-bridge -verify-each -S "$Test" \
      | "$FILECHECK" "$Test"
  else
    "$OPT" -load-pass-plugin="$PLUGIN" \
      -passes=brighten-extern-call-bridge -verify-each -disable-output "$Test"
  fi
done

echo "External call bridge tests: PASS"
