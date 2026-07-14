#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT="${OPT:-$(command -v opt-21 || command -v opt)}"
PLUGIN="$ROOT/build/BrightenExternCallBridgePass.so"

[[ -x "$OPT" ]]
[[ -f "$PLUGIN" ]]

for Test in "$ROOT"/tests/*.ll; do
  "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes=brighten-extern-call-bridge -verify-each -disable-output "$Test"
done

echo "External call bridge tests: PASS"
