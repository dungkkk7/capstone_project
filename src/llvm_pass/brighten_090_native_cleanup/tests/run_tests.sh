#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT="${OPT:-$(command -v opt-21 || command -v opt)}"
PLUGIN="$ROOT/build/BrightenNativeCleanupPass.so"

[[ -x "$OPT" ]]
[[ -f "$PLUGIN" ]]

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-pass \
  -brighten-native-strict -disable-output "$ROOT/tests/clean_native.ll"

if "$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-pass \
    -brighten-native-strict -disable-output "$ROOT/tests/lifted_not_native.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: strict cleanup accepted lifted IR" >&2
  exit 1
fi

echo "Native cleanup tests: PASS"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-pass \
  -brighten-native-state-ssa -brighten-native-strict -disable-output \
  "$ROOT/tests/state_ssa_native.ll"

echo "Native State SSA tests: PASS"
