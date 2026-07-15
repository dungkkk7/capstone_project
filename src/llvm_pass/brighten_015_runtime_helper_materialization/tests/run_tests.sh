#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT_BIN="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
FILECHECK_BIN="${FILECHECK_BIN:-$(command -v FileCheck-21 || command -v FileCheck)}"
PLUGIN="${PLUGIN:-$ROOT/build/BrightenRuntimeHelperPass.so}"

for test in unresolved_helpers_preserved atomic_runtime no_fabricated_entry_stack; do
  "$OPT_BIN" -load-pass-plugin "$PLUGIN" \
    -passes=brighten-remill-runtime-pass,verify -S \
    "$ROOT/tests/$test.ll" -o - \
    | "$FILECHECK_BIN" "$ROOT/tests/$test.ll"
done

echo "Brighten runtime helper tests: PASS"
