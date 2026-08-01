#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT_BIN="${OPT_BIN:-$(command -v opt-21 || command -v opt || true)}"
FILECHECK_BIN="${FILECHECK_BIN:-$(command -v FileCheck-21 || command -v FileCheck || true)}"
PLUGIN="${PLUGIN:-$ROOT/build/BrightenRepairPass.so}"

if [[ ! -x "$OPT_BIN" ]]; then
  echo "ERROR: opt not found at $OPT_BIN" >&2
  exit 1
fi
if [[ ! -x "$FILECHECK_BIN" ]]; then
  echo "ERROR: FileCheck not found at $FILECHECK_BIN" >&2
  exit 1
fi
if [[ ! -f "$PLUGIN" ]]; then
  echo "ERROR: plugin not found at $PLUGIN" >&2
  exit 1
fi

run_one() {
  local test_file="$1"
  "$OPT_BIN" -load-pass-plugin "$PLUGIN" -passes=brighten-repair-pass,verify -S "$test_file" -o - \
    | "$FILECHECK_BIN" "$test_file"
}

run_one "$ROOT/tests/ub_flags.ll"
run_one "$ROOT/tests/ub_flags_constexpr.ll"
run_one "$ROOT/tests/ub_attrs.ll"
run_one "$ROOT/tests/callback_direct_call_preserved.ll"
run_one "$ROOT/tests/x86_fptosi_nan_indefinite.ll"

# The remaining historical fixtures exercise runtime materialization,
# devirtualization and State/stack lowering from the former monolithic pass.
# They must not be asserted against the phase-1 repair plugin.

echo "Brighten repair tests: PASS"
