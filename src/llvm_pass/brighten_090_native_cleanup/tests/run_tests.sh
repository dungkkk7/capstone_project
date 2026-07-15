#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT="${OPT:-$(command -v opt-21 || command -v opt)}"
PLUGIN="$ROOT/build/BrightenNativeCleanupPass.so"

[[ -x "$OPT" ]]
[[ -f "$PLUGIN" ]]

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-final-pass \
  -brighten-native-strict -disable-output "$ROOT/tests/clean_native.ll"

if "$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-final-pass \
    -brighten-native-strict -disable-output \
    "$ROOT/tests/frozen_undefined.ll" >/dev/null 2>&1; then
  echo "FAIL: strict verifier accepted frozen undef/poison" >&2
  exit 1
fi

SCAFFOLD_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,brighten-native-cleanup-final-pass,verify' \
  -brighten-native-strict -S \
  "$ROOT/tests/fully_overwritten_undefined_scaffold.ll" -o "$SCAFFOLD_OUT"
if grep -Eq '\b(undef|poison)\b' "$SCAFFOLD_OUT"; then
  echo "FAIL: fully-overwritten construction scaffold remained undefined" >&2
  exit 1
fi

if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes='brighten-native-cleanup-pass,brighten-native-cleanup-final-pass,verify' \
    -brighten-native-strict -disable-output \
    "$ROOT/tests/partially_overwritten_undefined_scaffold.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: partially observable poison scaffold was certified" >&2
  exit 1
fi

if "$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-final-pass \
    -brighten-native-strict -disable-output "$ROOT/tests/lifted_not_native.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: strict cleanup accepted lifted IR" >&2
  exit 1
fi

if "$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-final-pass \
    -brighten-native-strict -disable-output \
    "$ROOT/tests/residual_guest_artifacts.ll" >/dev/null 2>&1; then
  echo "FAIL: strict cleanup accepted residual guest artifacts" >&2
  exit 1
fi

if "$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-final-pass \
    -brighten-native-strict -disable-output \
    "$ROOT/tests/residual_flattened_stack.ll" >/dev/null 2>&1; then
  echo "FAIL: strict cleanup accepted fake stack / flattened dispatcher" >&2
  exit 1
fi

if "$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-final-pass \
    -brighten-native-strict -disable-output \
    "$ROOT/tests/residual_zero_initialized_fake_stack.ll" >/dev/null 2>&1; then
  echo "FAIL: strict cleanup accepted zero-initialized fake stack" >&2
  exit 1
fi

echo "Native cleanup tests: PASS"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,default<O3>,brighten-native-cleanup-final-pass,verify' \
  -brighten-native-state-ssa -brighten-native-strict -disable-output \
  "$ROOT/tests/state_ssa_native.ll"

NULL_BOUNDARY_OUT="$(mktemp)"
trap 'rm -f "$NULL_BOUNDARY_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,default<O3>,brighten-native-cleanup-final-pass,verify' \
  -brighten-native-state-ssa -brighten-native-strict -S \
  "$ROOT/tests/state_ssa_null_boundary.ll" -o "$NULL_BOUNDARY_OUT"
if grep -Eq '__mcsema_reg_state|inttoptr|native_state_storage' \
    "$NULL_BOUNDARY_OUT"; then
  echo "FAIL: null State boundary left a hidden State object/address" >&2
  exit 1
fi
grep -Eq 'ret i32 7' "$NULL_BOUNDARY_OUT"

EXPLICIT_NATIVE_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/explicit_native_global_state.ll" -o "$EXPLICIT_NATIVE_OUT"
grep -Eq 'define internal i64 @worker\(ptr %frame_base, i64 %state_in_2312, i64 %arg_RDI\)' \
  "$EXPLICIT_NATIVE_OUT"
if grep -Eq 'define .*@worker\.native' "$EXPLICIT_NATIVE_OUT"; then
  echo "FAIL: explicit-native State-global function was not planned" >&2
  exit 1
fi

EXPLICIT_OVERRIDE_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/explicit_argument_overrides_state.ll" \
  -o "$EXPLICIT_OVERRIDE_OUT"
grep -Eq 'define internal i64 @worker\(i64 %state_in_2280, i64 %arg_RSI\)' \
  "$EXPLICIT_OVERRIDE_OUT"
grep -Eq 'add i64 %arg_RSI, %arg_RSI' "$EXPLICIT_OVERRIDE_OUT"
if grep -Eq 'add i64 %state_in_2280, %arg_RSI|add i64 %arg_RSI, %state_in_2280' \
    "$EXPLICIT_OVERRIDE_OUT"; then
  echo "FAIL: stale State snapshot remained authoritative over explicit argument" >&2
  exit 1
fi

MIXED_NATIVE_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/mixed_native_memory_token.ll" -o "$MIXED_NATIVE_OUT"
grep -Eq 'define internal i64 @worker\(ptr %frame_base, i64 %state_in_2312, i64 %arg_RDI\)' \
  "$MIXED_NATIVE_OUT"
if grep -Eq 'define .*@worker\.native|%memory' "$MIXED_NATIVE_OUT"; then
  echo "FAIL: mixed native Memory token leaked into the application ABI" >&2
  exit 1
fi

RELATIVE_STACK_OUT="$(mktemp)"
CONSERVATIVE_STACK_OUT="$(mktemp)"
ENTRY_RSP_SEED_OUT="$(mktemp)"
MIXED_VARARG_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/scanf_does_not_retype_unrelated_varargs.ll" \
  -o "$MIXED_VARARG_OUT"
if grep -Eq 'native\.vararg\.address' "$MIXED_VARARG_OUT"; then
  echo "FAIL: scanf retyped an unrelated integer vararg slot as a pointer" >&2
  exit 1
fi
grep -Eq 'store i64 %numeric_value, ptr %integer_slot' "$MIXED_VARARG_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/relative_stack_absolute_carrier.ll" -o "$RELATIVE_STACK_OUT"
if grep -Eq 'getelementptr.*ptrtoint.*frame_storage_backing\.worker' \
    "$RELATIVE_STACK_OUT"; then
  echo "FAIL: absolute stack carrier was rebased twice" >&2
  exit 1
fi
grep -Eq 'native\.stack\.absolute\.delta = sub i64 %absolute\.stack\.address, %native\.stack\.anchor' \
  "$RELATIVE_STACK_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/conservative_stack_relativization.ll" \
  -o "$CONSERVATIVE_STACK_OUT"
grep -Eq 'ptrtoint ptr %(native_stack_top|frame_top) to i64' \
  "$CONSERVATIVE_STACK_OUT"
if grep -Eq 'attributes .*brighten\.relative-stack' \
    "$CONSERVATIVE_STACK_OUT"; then
  echo "FAIL: mixed absolute-delta stack transaction was relativized" >&2
  exit 1
fi

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/entry_rsp_seed_not_rbp.ll" -o "$ENTRY_RSP_SEED_OUT"
grep -Eq 'native\.stack\.entry\.delta = sub i64 %state_2312, %native\.boundary\.rsp' \
  "$ENTRY_RSP_SEED_OUT"
if grep -Eq 'native\.stack\.entry\.delta = sub i64 %state_2312, %entry\.rbp' \
    "$ENTRY_RSP_SEED_OUT"; then
  echo "FAIL: entry stack address was rebased against initial RBP" >&2
  exit 1
fi

python3 "$ROOT/tests/test_pipeline_order.py"
python3 "$ROOT/tests/test_native_contract_report.py"

NESTED_RSP_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/nested_rsp_return.ll" -o "$NESTED_RSP_OUT"
grep -Eq 'state\.call\.out\.2312 = extractvalue .*native_result.*, 1' \
  "$NESTED_RSP_OUT"
grep -Eq 'insertvalue .*%state\.call\.out\.2312, 1' "$NESTED_RSP_OUT"
if grep -Eq '@(__mcsema_reg_state|RSP_pointer_view)' "$NESTED_RSP_OUT"; then
  echo "FAIL: nested RSP State global/alias survived native State-SSA" >&2
  exit 1
fi

NESTED_RBP_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/nested_rbp_return.ll" -o "$NESTED_RBP_OUT"
grep -Eq 'state\.call\.out\.2328 = extractvalue .*native_result.*, 1' \
  "$NESTED_RBP_OUT"
# A visible caller-side output is insufficient if the recovered callee fills
# that field from a transient epilogue stack load.  RBP is callee-saved: the
# native result must carry the proven incoming State-SSA value itself.
grep -Eq 'insertvalue %callee\.native_result .*i64 %state_in_2328, 1' \
  "$NESTED_RBP_OUT"
if grep -Eq '@__mcsema_reg_state' "$NESTED_RBP_OUT"; then
  echo "FAIL: nested RBP State global survived native State-SSA" >&2
  exit 1
fi

NESTED_DYNAMIC_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,default<O3>,brighten-native-cleanup-final-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/nested_dynamic_stack_index.ll" -o "$NESTED_DYNAMIC_OUT"
ANCHOR_COUNT="$(grep -o 'ptrtoint' "$NESTED_DYNAMIC_OUT" | wc -l)"
if [[ "$ANCHOR_COUNT" -gt 2 ]]; then
  echo "FAIL: nested absolute stack carrier applied incoming depth twice" >&2
  exit 1
fi

NESTED_FIXED_SLOT_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/nested_fixed_frame_slot.ll" -o "$NESTED_FIXED_SLOT_OUT"
grep -Eq 'frame\.frame\.rsp = add i64 %state_in_2312, -72' \
  "$NESTED_FIXED_SLOT_OUT"
grep -Eq 'frame\.local\.offset = add i64 %frame\.incoming\.depth, 16' \
  "$NESTED_FIXED_SLOT_OUT"

NESTED_STACK_ARG_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/nested_incoming_stack_arg.ll" -o "$NESTED_STACK_ARG_OUT"
grep -Eq 'frame\.local\.offset = add i64 %frame\.incoming\.depth, 16' \
  "$NESTED_STACK_ARG_OUT"
if grep -Eq 'frame\.frame\.rsp = add i64 %state_in_2312, -568' \
  "$NESTED_STACK_ARG_OUT"; then
  echo "FAIL: incoming stack argument was rebased on allocated-frame RSP" >&2
  exit 1
fi

EXACT_STATE_MEMSET_OUT="$(mktemp)"
PARTIAL_STATE_MEMSET_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/exact_state_slot_memset.ll" -o "$EXACT_STATE_MEMSET_OUT"
if grep -Eq 'call void @llvm\.memset|define .*@worker\.native' "$EXACT_STATE_MEMSET_OUT"; then
  echo "FAIL: exact whole-slot State memset was not lowered" >&2
  exit 1
fi
grep -Eq 'insertvalue .* i128 0, 1' "$EXACT_STATE_MEMSET_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/partial_state_slot_memset_refused.ll" \
  -o "$PARTIAL_STATE_MEMSET_OUT"
grep -Eq 'llvm\.memset.*i64 8' "$PARTIAL_STATE_MEMSET_OUT"
grep -Eq 'define internal i128 @worker\.native' "$PARTIAL_STATE_MEMSET_OUT"

DFA_OUT="$(mktemp)"
trap 'rm -f "$NULL_BOUNDARY_OUT" "$EXPLICIT_NATIVE_OUT" "$MIXED_NATIVE_OUT" "$MIXED_VARARG_OUT" "$RELATIVE_STACK_OUT" "$CONSERVATIVE_STACK_OUT" "$ENTRY_RSP_SEED_OUT" "$NESTED_RSP_OUT" "$NESTED_RBP_OUT" "$NESTED_DYNAMIC_OUT" "$NESTED_FIXED_SLOT_OUT" "$NESTED_STACK_ARG_OUT" "$EXACT_STATE_MEMSET_OUT" "$PARTIAL_STATE_MEMSET_OUT" "$DFA_OUT"' EXIT
"$OPT" -passes='dfa-jump-threading,simplifycfg,adce,verify' -S \
  "$ROOT/tests/flattened_ssa.ll" -o "$DFA_OUT"
if grep -Eq 'switch i32' "$DFA_OUT"; then
  echo "FAIL: SSA flattening dispatcher survived DFA threading" >&2
  exit 1
fi
grep -Eq 'ret i32 7' "$DFA_OUT"

FRAME_COMPACT_OUT="$(mktemp)"
FRAME_REFUSE_OUT="$(mktemp)"
FRAME_POS_BIN="$(mktemp)"
FRAME_NEG_BIN="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/proven_constant_frame_compaction.ll" -o "$FRAME_COMPACT_OUT"
if grep -Eq '@frame_storage_backing\.main' "$FRAME_COMPACT_OUT"; then
  echo "FAIL: fully-proven constant fake stack was not compacted" >&2
  exit 1
fi
grep -Eq 'alloca \[4 x i8\]' "$FRAME_COMPACT_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/uninitialized_frame_compaction_refused.ll" \
  -o "$FRAME_REFUSE_OUT"
grep -Eq '@frame_storage_backing\.main.*zeroinitializer' "$FRAME_REFUSE_OUT"
if grep -Eq 'native_frame = alloca' "$FRAME_REFUSE_OUT"; then
  echo "FAIL: zero-initialized read was unsafely changed to uninitialized stack" >&2
  exit 1
fi

CLANG="${CLANG:-$(command -v clang-21 || command -v clang)}"
"$CLANG" -x ir "$FRAME_COMPACT_OUT" -o "$FRAME_POS_BIN"
"$CLANG" -x ir "$FRAME_REFUSE_OUT" -o "$FRAME_NEG_BIN"
set +e
"$FRAME_POS_BIN"
FRAME_POS_STATUS=$?
"$FRAME_NEG_BIN"
FRAME_NEG_STATUS=$?
set -e
if [[ "$FRAME_POS_STATUS" -ne 7 || "$FRAME_NEG_STATUS" -ne 0 ]]; then
  echo "FAIL: frame compaction executable semantics changed" >&2
  exit 1
fi
rm -f "$FRAME_COMPACT_OUT" "$FRAME_REFUSE_OUT" \
  "$FRAME_POS_BIN" "$FRAME_NEG_BIN"

echo "Native State SSA tests: PASS"
