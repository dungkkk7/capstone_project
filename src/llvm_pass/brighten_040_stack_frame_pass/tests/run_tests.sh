#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT="${OPT:-$(command -v opt-21 || command -v opt)}"
PLUGIN="$ROOT/build/BrightenStackFramePass.so"

[[ -x "$OPT" ]]
[[ -f "$PLUGIN" ]]

OUT="$(mktemp)"
DISJOINT_OUT="$(mktemp)"
PARTIAL_OUT="$(mktemp)"
MIXED_OUT="$(mktemp)"
CALL_OUT="$(mktemp)"
LARGE_OUT="$(mktemp)"
trap 'rm -f "$OUT" "$DISJOINT_OUT" "$PARTIAL_OUT" "$MIXED_OUT" "$CALL_OUT" "$LARGE_OUT"' EXIT

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_promoted_rsp_slot.ll" -o "$OUT"

grep -q 'native_local_frame = alloca \[8 x i8\]' "$OUT"
grep -q 'store i64 42, ptr %frame_ptr' "$OUT"
grep -q 'load i64, ptr %frame_ptr' "$OUT"
! grep -q 'llvm.memcpy' "$OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_disjoint_read_before_write.ll" \
  -o "$DISJOINT_OUT"

! grep -q 'native_local_frame' "$DISJOINT_OUT"
grep -q 'load i64, ptr %incoming.ptr' "$DISJOINT_OUT"
grep -q 'store i64 42, ptr %local.ptr' "$DISJOINT_OUT"
grep -q 'load i64, ptr %local.ptr' "$DISJOINT_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_partial_unsafe_base.ll" \
  -o "$PARTIAL_OUT"

! grep -q 'native_local_frame' "$PARTIAL_OUT"
grep -q 'store i64 42, ptr %local.ptr' "$PARTIAL_OUT"
grep -q 'store i64 %local, ptr %shared.ptr' "$PARTIAL_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_mixed_stack_bases.ll" \
  -o "$MIXED_OUT"

! grep -q 'native_local_frame' "$MIXED_OUT"
grep -q 'store i64 42, ptr %local.ptr' "$MIXED_OUT"
grep -q 'store i64 %local, ptr %other.ptr' "$MIXED_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_call_clobbers_stack_state.ll" \
  -o "$CALL_OUT"

! grep -q 'native_local_frame' "$CALL_OUT"
grep -q 'call ptr @sub_callee' "$CALL_OUT"
grep -q 'store i64 1, ptr %before.ptr' "$CALL_OUT"
grep -q 'store i64 2, ptr %after.ptr' "$CALL_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_large_unproven_frame.ll" -o "$LARGE_OUT"

! grep -q 'native_local_frame' "$LARGE_OUT"
grep -q 'store i64 5, ptr %ptr.5' "$LARGE_OUT"
grep -q 'load i64, ptr %ptr.5' "$LARGE_OUT"

echo "Stack frame recovery tests: PASS"
