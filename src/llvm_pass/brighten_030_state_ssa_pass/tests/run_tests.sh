#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT_BIN="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
FILECHECK_BIN="${FILECHECK_BIN:-$(command -v FileCheck-21 || command -v FileCheck)}"
PLUGIN="${PLUGIN:-$ROOT/build/BrightenStateSSAPass.so}"
PASS="${PASS:-brighten-state-ssa-pass}"

if [[ -z "${OPT_BIN:-}" || ! -x "$OPT_BIN" ]]; then
  echo "ERROR: opt not found" >&2
  exit 1
fi
if [[ -z "${FILECHECK_BIN:-}" || ! -x "$FILECHECK_BIN" ]]; then
  echo "ERROR: FileCheck not found" >&2
  exit 1
fi
if [[ ! -f "$PLUGIN" ]]; then
  echo "ERROR: plugin not found at $PLUGIN" >&2
  exit 1
fi

for test_file in "$ROOT"/tests/*.ll; do
  echo "RUN $(basename "$test_file")"
  "$OPT_BIN" -load-pass-plugin "$PLUGIN" -passes="$PASS,verify" -S "$test_file" -o - \
    | "$FILECHECK_BIN" "$test_file"
done

echo "All brighten-state-ssa-pass tests passed."
