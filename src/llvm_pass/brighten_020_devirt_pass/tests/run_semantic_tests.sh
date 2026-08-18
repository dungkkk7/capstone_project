#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT_BIN="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
FILECHECK_BIN="${FILECHECK_BIN:-$(command -v FileCheck-21 || command -v FileCheck)}"
PLUGIN="${PLUGIN:-$ROOT/build/BrightenDevirtPass.so}"

for test in \
  semantic_finite_selector \
  semantic_dynamic_selector \
  semantic_phi_repair; do
  "$OPT_BIN" -load-pass-plugin "$PLUGIN" \
    -passes=brighten-devirt-pass,verify -S \
    "$ROOT/tests/$test.ll" -o - \
    | "$FILECHECK_BIN" "$ROOT/tests/$test.ll"
done

echo "Brighten semantic CFG recovery tests: PASS"
