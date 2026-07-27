#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT_BIN="${OPT_BIN:-$(command -v opt-21 || command -v opt)}"
FILECHECK_BIN="${FILECHECK_BIN:-$(command -v FileCheck-21 || command -v FileCheck)}"
PLUGIN="${PLUGIN:-$ROOT/build/BrightenRuntimeHelperPass.so}"

for test in unresolved_helpers_preserved atomic_runtime no_fabricated_entry_stack divide_faults \
  entry_single_invocation_positive entry_single_invocation_two_calls \
  entry_single_invocation_address_taken entry_single_invocation_recursive \
  entry_single_invocation_indirect_callback \
  entry_single_invocation_dead_provenance_global \
  entry_single_invocation_used_provenance_global \
  entry_single_invocation_live_provenance_global \
  entry_single_invocation_entry_recursive \
  entry_single_invocation_entry_address_taken; do
  "$OPT_BIN" -load-pass-plugin "$PLUGIN" \
    -passes=brighten-remill-runtime-pass,verify -S \
    "$ROOT/tests/$test.ll" -o - \
    | "$FILECHECK_BIN" "$ROOT/tests/$test.ll"
done

# Compile the transformed helper into a native executable.  argc selects the
# signed-zero, unsigned-zero, and signed-overflow fault paths respectively.
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT
"$OPT_BIN" -load-pass-plugin "$PLUGIN" \
  -passes=brighten-remill-runtime-pass,verify -S \
  "$ROOT/tests/divide_fault_signal.ll" -o "$TMPDIR_TEST/divide_fault_signal.ll"
CLANG_BIN="${CLANG_BIN:-$(command -v clang-21 || command -v clang)}"
"$CLANG_BIN" -O2 "$TMPDIR_TEST/divide_fault_signal.ll" -o "$TMPDIR_TEST/divide_fault_signal"
for args in '' 'one' 'one two'; do
  set +e
  # shellcheck disable=SC2086
  "$TMPDIR_TEST/divide_fault_signal" $args >/dev/null 2>/dev/null
  rc=$?
  set -e
  if [[ "$rc" -ne 136 ]]; then
    echo "expected SIGFPE (exit 136), got $rc for args: $args" >&2
    exit 1
  fi
done

echo "Brighten runtime helper tests: PASS"
