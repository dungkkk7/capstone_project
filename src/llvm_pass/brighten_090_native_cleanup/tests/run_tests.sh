#!/usr/bin/env bash
set -euo pipefail
ulimit -c 0

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPT="${OPT:-$(command -v opt-21 || command -v opt)}"
PLUGIN="$ROOT/build/BrightenNativeCleanupPass.so"

[[ -x "$OPT" ]]
[[ -f "$PLUGIN" ]]

ENTRY_STACK_CONTRACT_OUT="$(mktemp)"
ENTRY_STACK_TWO_CALLS_OUT="$(mktemp)"
ENTRY_STACK_RECURSIVE_OUT="$(mktemp)"
ENTRY_STACK_TAKEN_OUT="$(mktemp)"
STATE_SSA_BOUNDARY_OUT="$(mktemp)"
STATE_SSA_BOUNDARY_O3_OUT="$(mktemp)"
STATE_SSA_BOUNDARY_DEFAULT_OUT="$(mktemp)"
trap 'rm -f "$ENTRY_STACK_CONTRACT_OUT" "$ENTRY_STACK_TWO_CALLS_OUT" "$ENTRY_STACK_RECURSIVE_OUT" "$ENTRY_STACK_TAKEN_OUT" "$STATE_SSA_BOUNDARY_OUT" "$STATE_SSA_BOUNDARY_O3_OUT" "$STATE_SSA_BOUNDARY_DEFAULT_OUT"' EXIT

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -brighten-native-state-ssa -S \
  "$ROOT/tests/state_ssa_guest_boundary.ll" -o "$STATE_SSA_BOUNDARY_DEFAULT_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  --check-prefix=STATE-DEFAULT "$ROOT/tests/state_ssa_guest_boundary.ll" \
  < "$STATE_SSA_BOUNDARY_DEFAULT_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -brighten-native-state-ssa \
  -brighten-090-propagate-guest-boundary -S \
  "$ROOT/tests/state_ssa_guest_boundary.ll" -o "$STATE_SSA_BOUNDARY_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  --check-prefix=STATE-PIN "$ROOT/tests/state_ssa_guest_boundary.ll" \
  < "$STATE_SSA_BOUNDARY_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  --check-prefix=STATE-PLAIN "$ROOT/tests/state_ssa_guest_boundary.ll" \
  < "$STATE_SSA_BOUNDARY_OUT"
"$OPT" -passes='default<O3>,verify' -S "$STATE_SSA_BOUNDARY_OUT" \
  -o "$STATE_SSA_BOUNDARY_O3_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  --check-prefix=O3 "$ROOT/tests/state_ssa_guest_boundary.ll" \
  < "$STATE_SSA_BOUNDARY_O3_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -brighten-native-state-ssa -S \
  "$ROOT/tests/entrypoint_stack_contract_positive.ll" -o "$ENTRY_STACK_CONTRACT_OUT"
grep -Eq '@frame_storage_backing\.main = internal global \[16777216 x i8\].*!brighten\.entry\.stack\.contract' "$ENTRY_STACK_CONTRACT_OUT"
grep -q '!brighten.entry.stack.producer' "$ENTRY_STACK_CONTRACT_OUT"
grep -q '!brighten.entry.stack.owner' "$ENTRY_STACK_CONTRACT_OUT"
grep -q '!brighten.entry.stack.inline.origin' "$ENTRY_STACK_CONTRACT_OUT"

for ENTRY_STACK_NEGATIVE in two_calls recursive address_taken; do
  case "$ENTRY_STACK_NEGATIVE" in
    two_calls) ENTRY_STACK_OUT="$ENTRY_STACK_TWO_CALLS_OUT" ;;
    recursive) ENTRY_STACK_OUT="$ENTRY_STACK_RECURSIVE_OUT" ;;
    address_taken) ENTRY_STACK_OUT="$ENTRY_STACK_TAKEN_OUT" ;;
  esac
  "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes='brighten-native-cleanup-pass,verify' -S \
    "$ROOT/tests/entrypoint_stack_contract_${ENTRY_STACK_NEGATIVE}_refused.ll" \
    -o "$ENTRY_STACK_OUT"
  if grep -q 'brighten.entry.stack.contract' "$ENTRY_STACK_OUT"; then
    echo "FAIL: entry stack contract accepted $ENTRY_STACK_NEGATIVE boundary" >&2
    exit 1
  fi
done

NATIVE_STACK_SAFE_OUT="$(mktemp)"
NATIVE_STACK_READ_REFUSE_OUT="$(mktemp)"
NATIVE_STACK_PARTIAL_REFUSE_OUT="$(mktemp)"
NATIVE_STACK_CALL_REFUSE_OUT="$(mktemp)"
NATIVE_STACK_SAFE_TWICE_OUT="$(mktemp)"
NATIVE_STACK_UNSUPPORTED_OUT="$(mktemp)"
NATIVE_STACK_UNSUPPORTED_BASELINE="$(mktemp)"
NATIVE_STACK_NONZERO_ROOT_OUT="$(mktemp)"
trap 'rm -f "$NATIVE_STACK_SAFE_OUT" "$NATIVE_STACK_READ_REFUSE_OUT" "$NATIVE_STACK_PARTIAL_REFUSE_OUT" "$NATIVE_STACK_CALL_REFUSE_OUT" "$NATIVE_STACK_SAFE_TWICE_OUT" "$NATIVE_STACK_UNSUPPORTED_OUT" "$NATIVE_STACK_UNSUPPORTED_BASELINE" "$NATIVE_STACK_NONZERO_ROOT_OUT"' EXIT

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -brighten-native-state-ssa -S \
  "$ROOT/tests/native_main_stack_fully_initialized.ll" -o "$NATIVE_STACK_SAFE_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/native_main_stack_fully_initialized.ll" < "$NATIVE_STACK_SAFE_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -brighten-native-state-ssa -S \
  "$NATIVE_STACK_SAFE_OUT" -o "$NATIVE_STACK_SAFE_TWICE_OUT"
cmp <(sed '1{/^; ModuleID = /d;}' "$NATIVE_STACK_SAFE_OUT") \
    <(sed '1{/^; ModuleID = /d;}' "$NATIVE_STACK_SAFE_TWICE_OUT")

for NATIVE_STACK_REFUSAL in read_before_write partial_write unknown_call; do
  case "$NATIVE_STACK_REFUSAL" in
    read_before_write) NATIVE_STACK_OUT="$NATIVE_STACK_READ_REFUSE_OUT" ;;
    partial_write) NATIVE_STACK_OUT="$NATIVE_STACK_PARTIAL_REFUSE_OUT" ;;
    unknown_call) NATIVE_STACK_OUT="$NATIVE_STACK_CALL_REFUSE_OUT" ;;
  esac
  "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes='brighten-native-cleanup-pass,verify' -brighten-native-state-ssa -S \
    "$ROOT/tests/native_main_stack_${NATIVE_STACK_REFUSAL}_refused.ll" \
    -o "$NATIVE_STACK_OUT"
  "${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
    "$ROOT/tests/native_main_stack_${NATIVE_STACK_REFUSAL}_refused.ll" < "$NATIVE_STACK_OUT"
done

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -brighten-native-state-ssa -S \
  "$ROOT/tests/native_main_stack_unsupported_user_rollback.ll" \
  -o "$NATIVE_STACK_UNSUPPORTED_BASELINE"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -brighten-native-state-ssa -S \
  "$ROOT/tests/native_main_stack_unsupported_user_rollback.ll" \
  -o "$NATIVE_STACK_UNSUPPORTED_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/native_main_stack_unsupported_user_rollback.ll" < "$NATIVE_STACK_UNSUPPORTED_OUT"
cmp <(sed '1{/^; ModuleID = /d;}' "$NATIVE_STACK_UNSUPPORTED_BASELINE") \
    <(sed '1{/^; ModuleID = /d;}' "$NATIVE_STACK_UNSUPPORTED_OUT")

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -brighten-native-state-ssa -S \
  "$ROOT/tests/native_main_stack_nonzero_root_gep_refused.ll" \
  -o "$NATIVE_STACK_NONZERO_ROOT_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/native_main_stack_nonzero_root_gep_refused.ll" < "$NATIVE_STACK_NONZERO_ROOT_OUT"

MEMSET_SIZE_OUT="$(mktemp)"
trap 'rm -f "$MEMSET_SIZE_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/memset_size_guest_identity.ll" -o "$MEMSET_SIZE_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/memset_size_guest_identity.ll" < "$MEMSET_SIZE_OUT"

SCANF_SEED_OUT="$(mktemp)"
trap 'rm -f "$SCANF_SEED_OUT"' EXIT

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/scanf_failed_integer_seed.ll" -o "$SCANF_SEED_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/scanf_failed_integer_seed.ll" < "$SCANF_SEED_OUT"

SCANF_IGNORED_OUT="$(mktemp)"
trap 'rm -f "$SCANF_IGNORED_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/scanf_ignored_return_no_seed.ll" -o "$SCANF_IGNORED_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/scanf_ignored_return_no_seed.ll" < "$SCANF_IGNORED_OUT"

MULTI_SCANF_OUT="$(mktemp)"
trap 'rm -f "$MULTI_SCANF_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/scanf_failed_multi_integer_seed.ll" -o "$MULTI_SCANF_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/scanf_failed_multi_integer_seed.ll" < "$MULTI_SCANF_OUT"

IGNORED_TUPLE_SCANF_OUT="$(mktemp)"
trap 'rm -f "$IGNORED_TUPLE_SCANF_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/scanf_ignored_three_int_tuple_seed.ll" -o "$IGNORED_TUPLE_SCANF_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/scanf_ignored_three_int_tuple_seed.ll" < "$IGNORED_TUPLE_SCANF_OUT"

IGNORED_INITIAL_TUPLE_SCANF_OUT="$(mktemp)"
trap 'rm -f "$IGNORED_INITIAL_TUPLE_SCANF_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/scanf_ignored_initial_two_int_tuple_seed.ll" \
  -o "$IGNORED_INITIAL_TUPLE_SCANF_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/scanf_ignored_initial_two_int_tuple_seed.ll" \
  < "$IGNORED_INITIAL_TUPLE_SCANF_OUT"

SCANF_OFFSET_OUT="$(mktemp)"
trap 'rm -f "$SCANF_OFFSET_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/scanf_format_offset_no_extra_destination.ll" \
  -o "$SCANF_OFFSET_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/scanf_format_offset_no_extra_destination.ll" \
  < "$SCANF_OFFSET_OUT"

QSORT_OUT="$(mktemp)"
trap 'rm -f "$QSORT_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,brighten-native-cleanup-final-pass,verify' -S \
  "$ROOT/tests/qsort_callback_abi.ll" -o "$QSORT_OUT"
grep -Eq 'define internal x86_64_sysvcc i32 @callback_sub_test\.qsort_callback\(ptr %lhs, ptr %rhs\)' \
  "$QSORT_OUT"
grep -Eq 'declare x86_64_sysvcc void @qsort\(ptr, i64, i64, ptr\)' \
  "$QSORT_OUT"
grep -Eq 'call x86_64_sysvcc void @qsort\(ptr null, i64 0, i64 16, ptr @callback_sub_test\.qsort_callback\)' \
  "$QSORT_OUT"
rm -f "$QSORT_OUT"

WORK_ARRAY_OUT="$(mktemp)"
trap 'rm -f "$WORK_ARRAY_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/recovered_work_array_prefix.ll" -o "$WORK_ARRAY_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/recovered_work_array_prefix.ll" < "$WORK_ARRAY_OUT"
rm -f "$WORK_ARRAY_OUT"

WORK_ARRAY_UNMAPPED_OUT="$(mktemp)"
trap 'rm -f "$WORK_ARRAY_UNMAPPED_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/recovered_work_array_unmapped_negative_fault.ll" \
  -o "$WORK_ARRAY_UNMAPPED_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/recovered_work_array_unmapped_negative_fault.ll" \
  < "$WORK_ARRAY_UNMAPPED_OUT"
rm -f "$WORK_ARRAY_UNMAPPED_OUT"

MISSING_SCANF_OUT="$(mktemp)"
trap 'rm -f "$MISSING_SCANF_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/scanf_missing_destination.ll" -o "$MISSING_SCANF_OUT"
MISSING_SCANF_COUNT="$(grep -o 'native.scanf.missing.destination' "$MISSING_SCANF_OUT" | wc -l)"
if [[ "$MISSING_SCANF_COUNT" -lt 2 ]]; then
  echo "FAIL: scanf missing destinations were not materialized" >&2
  exit 1
fi
rm -f "$MISSING_SCANF_OUT"

GLOBAL_PTR_ROUNDTRIP_OUT="$(mktemp)"
trap 'rm -f "$GLOBAL_PTR_ROUNDTRIP_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/recovered_global_ptrtoint_roundtrip.ll" \
  -o "$GLOBAL_PTR_ROUNDTRIP_OUT"
grep -Eq 'call i32 @puts\(ptr %ok\)' "$GLOBAL_PTR_ROUNDTRIP_OUT"
if grep -Eq '\binttoptr\b|native\.data\.pointer\.select|native\.address\.fallback' \
    "$GLOBAL_PTR_ROUNDTRIP_OUT"; then
  echo "FAIL: recovered global ptrtoint round-trip was rematerialized as a guest address" >&2
  exit 1
fi
rm -f "$GLOBAL_PTR_ROUNDTRIP_OUT"

REVERSE_GUEST_POINTER_OUT="$(mktemp)"
trap 'rm -f "$REVERSE_GUEST_POINTER_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/reverse_guest_pointer_identity.ll" \
  -o "$REVERSE_GUEST_POINTER_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/reverse_guest_pointer_identity.ll" \
  < "$REVERSE_GUEST_POINTER_OUT"
rm -f "$REVERSE_GUEST_POINTER_OUT"

RESIDUAL_RELOCATION_OUT="$(mktemp)"
trap 'rm -f "$RESIDUAL_RELOCATION_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/residual_relocation_load.ll" -o "$RESIDUAL_RELOCATION_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/residual_relocation_load.ll" < "$RESIDUAL_RELOCATION_OUT"
rm -f "$RESIDUAL_RELOCATION_OUT"

VARARG_EXTERNAL_PTR_OUT="$(mktemp)"
trap 'rm -f "$VARARG_EXTERNAL_PTR_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/native_vararg_external_pointer_select.ll" \
  -o "$VARARG_EXTERNAL_PTR_OUT"
grep -Eq 'call i32 @puts\(ptr %ok\)' "$VARARG_EXTERNAL_PTR_OUT"
if grep -Eq 'call i32 @puts\(ptr %arg\)|native\.data\.pointer\.select|native\.address\.fallback' \
    "$VARARG_EXTERNAL_PTR_OUT"; then
  echo "FAIL: native vararg external pointer select was not restored" >&2
  exit 1
fi
rm -f "$VARARG_EXTERNAL_PTR_OUT"

NATIVE_DISPATCH_OUT="$(mktemp)"
NATIVE_DISPATCH_POST_FRAME_OUT="$(mktemp)"
trap 'rm -f "$NATIVE_DISPATCH_OUT" "$NATIVE_DISPATCH_POST_FRAME_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/native_pointer_dispatch_collapse.ll" \
  -o "$NATIVE_DISPATCH_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/native_pointer_dispatch_collapse.ll" \
  < "$NATIVE_DISPATCH_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/native_pointer_dispatch_collapse.ll" \
  -o "$NATIVE_DISPATCH_POST_FRAME_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  --check-prefix=POST-FRAME \
  "$ROOT/tests/native_pointer_dispatch_collapse.ll" \
  < "$NATIVE_DISPATCH_POST_FRAME_OUT"
rm -f "$NATIVE_DISPATCH_OUT"
rm -f "$NATIVE_DISPATCH_POST_FRAME_OUT"

WRITE_ONLY_FRAME_OUT="$(mktemp)"
trap 'rm -f "$WRITE_ONLY_FRAME_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/write_only_local_frame_cleanup.ll" \
  -o "$WRITE_ONLY_FRAME_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/write_only_local_frame_cleanup.ll" \
  < "$WRITE_ONLY_FRAME_OUT"
rm -f "$WRITE_ONLY_FRAME_OUT"

FINITE_FRAME_SPLIT_OUT="$(mktemp)"
trap 'rm -f "$FINITE_FRAME_SPLIT_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/finite_local_frame_split.ll" \
  -o "$FINITE_FRAME_SPLIT_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/finite_local_frame_split.ll" \
  < "$FINITE_FRAME_SPLIT_OUT"
rm -f "$FINITE_FRAME_SPLIT_OUT"

SHARED_STATE_SCALAR_OUT="$(mktemp)"
SHARED_STATE_SCALAR_BEFORE="$(mktemp)"
SHARED_STATE_SCALAR_AFTER="$(mktemp)"
trap 'rm -f "$SHARED_STATE_SCALAR_OUT" "$SHARED_STATE_SCALAR_BEFORE" "$SHARED_STATE_SCALAR_AFTER"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/shared_state_scalarization.ll" \
  -o "$SHARED_STATE_SCALAR_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/shared_state_scalarization.ll" \
  < "$SHARED_STATE_SCALAR_OUT"
"${CLANG:-$(command -v clang-21 || command -v clang)}" -O2 \
  "$ROOT/tests/shared_state_scalarization.ll" -o "$SHARED_STATE_SCALAR_BEFORE"
"${CLANG:-$(command -v clang-21 || command -v clang)}" -O2 \
  -x ir "$SHARED_STATE_SCALAR_OUT" -o "$SHARED_STATE_SCALAR_AFTER"
"$SHARED_STATE_SCALAR_BEFORE"
"$SHARED_STATE_SCALAR_AFTER"
rm -f "$SHARED_STATE_SCALAR_OUT" "$SHARED_STATE_SCALAR_BEFORE" \
  "$SHARED_STATE_SCALAR_AFTER"

SHARED_STATE_DYNAMIC_OUT="$(mktemp)"
trap 'rm -f "$SHARED_STATE_DYNAMIC_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/shared_state_scalarization_dynamic.ll" \
  -o "$SHARED_STATE_DYNAMIC_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/shared_state_scalarization_dynamic.ll" \
  < "$SHARED_STATE_DYNAMIC_OUT"
rm -f "$SHARED_STATE_DYNAMIC_OUT"

UNINITIALIZED_SEED_OUT="$(mktemp)"
trap 'rm -f "$UNINITIALIZED_SEED_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/uninitialized_local_seed_phi.ll" \
  -o "$UNINITIALIZED_SEED_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/uninitialized_local_seed_phi.ll" \
  < "$UNINITIALIZED_SEED_OUT"
rm -f "$UNINITIALIZED_SEED_OUT"

NATIVE_STORAGE_OUT="$(mktemp)"
trap 'rm -f "$NATIVE_STORAGE_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/native_residual_storage_classification.ll" \
  -o "$NATIVE_STORAGE_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/native_residual_storage_classification.ll" \
  < "$NATIVE_STORAGE_OUT"
rm -f "$NATIVE_STORAGE_OUT"

SHARED_STATE_FRAME_OUT="$(mktemp)"
trap 'rm -f "$SHARED_STATE_FRAME_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,default<O3>,brighten-native-cleanup-final-pass,verify' \
  -S "$ROOT/tests/shared_state_unblocks_frame_compaction.ll" \
  -o "$SHARED_STATE_FRAME_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/shared_state_unblocks_frame_compaction.ll" \
  < "$SHARED_STATE_FRAME_OUT"
rm -f "$SHARED_STATE_FRAME_OUT"

LOWERED_STATE_OUT="$(mktemp)"
trap 'rm -f "$LOWERED_STATE_OUT"' EXIT
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -S "$ROOT/tests/lowered_state_localization.ll" \
  -o "$LOWERED_STATE_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/lowered_state_localization.ll" \
  < "$LOWERED_STATE_OUT"
rm -f "$LOWERED_STATE_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-native-cleanup-final-pass \
  -brighten-native-strict -disable-output "$ROOT/tests/clean_native.ll"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' \
  -brighten-native-strict -disable-output \
  "$ROOT/tests/final_contract_native_malloc.ll"

TRANSITIONAL_ENTRY_STACK_REPORT="$(mktemp)"
trap 'rm -f "$TRANSITIONAL_ENTRY_STACK_REPORT"' EXIT
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes='brighten-native-cleanup-final-pass,verify' \
    -brighten-native-strict -disable-output \
    "$ROOT/tests/final_contract_transitional_entry_stack.ll" \
    > /dev/null 2>"$TRANSITIONAL_ENTRY_STACK_REPORT"; then
  echo "FAIL: strict verifier accepted transitional entry guest stack" >&2
  exit 1
fi
grep -Fq 'transitional entry guest stack: main' \
  "$TRANSITIONAL_ENTRY_STACK_REPORT"
rm -f "$TRANSITIONAL_ENTRY_STACK_REPORT"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' \
  -brighten-native-strict -disable-output \
  "$ROOT/tests/final_contract_structural_pointer_native.ll"

STRUCTURAL_POINTER_CONTROL="$(mktemp)"
STRUCTURAL_POINTER_FINAL="$(mktemp)"
STRUCTURAL_POINTER_REPORT="$(mktemp)"
trap 'rm -f "$STRUCTURAL_POINTER_CONTROL" "$STRUCTURAL_POINTER_FINAL" "$STRUCTURAL_POINTER_REPORT"' EXIT
"$OPT" -passes=verify -S \
  "$ROOT/tests/final_contract_structural_pointer_residuals.ll" \
  -o "$STRUCTURAL_POINTER_CONTROL"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -S \
  "$ROOT/tests/final_contract_structural_pointer_residuals.ll" \
  -o "$STRUCTURAL_POINTER_FINAL" 2>"$STRUCTURAL_POINTER_REPORT"
cmp "$STRUCTURAL_POINTER_CONTROL" "$STRUCTURAL_POINTER_FINAL"
grep -Fq \
  'native contract finding: semantic_risk/memory_model: range-dispatched pointer memory access: f' \
  "$STRUCTURAL_POINTER_REPORT"
grep -Fq \
  'native contract finding: semantic_risk/memory_model: range-dispatched pointer memory access: g' \
  "$STRUCTURAL_POINTER_REPORT"
grep -Fq \
  'native contract finding: semantic_risk/pointer_model: integerized guarded pointer reconstruction: h' \
  "$STRUCTURAL_POINTER_REPORT"
grep -Fq \
  'native contract finding: semantic_risk/pointer_model: integerized guarded pointer reconstruction: i' \
  "$STRUCTURAL_POINTER_REPORT"
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes=brighten-native-cleanup-final-pass -brighten-native-strict \
    -disable-output \
    "$ROOT/tests/final_contract_structural_pointer_residuals.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: strict verifier accepted structural pointer residuals" >&2
  exit 1
fi
rm -f "$STRUCTURAL_POINTER_CONTROL" "$STRUCTURAL_POINTER_FINAL" \
  "$STRUCTURAL_POINTER_REPORT"

FINAL_CONTROL_OUT="$(mktemp)"
FINAL_VERIFY_OUT="$(mktemp)"
FINAL_REPORT="$(mktemp)"
trap 'rm -f "$FINAL_CONTROL_OUT" "$FINAL_VERIFY_OUT" "$FINAL_REPORT"' EXIT
"$OPT" -passes=verify -S "$ROOT/tests/final_contract_residuals.ll" \
  -o "$FINAL_CONTROL_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -S \
  "$ROOT/tests/final_contract_residuals.ll" -o "$FINAL_VERIFY_OUT" \
  2>"$FINAL_REPORT"
cmp "$FINAL_CONTROL_OUT" "$FINAL_VERIFY_OUT"
for FINDING in \
  'generated raw pointer fallback' \
  'surviving mapper/select fallback chain' \
  'synthetic raw byte frame/storage' \
  'residual image/map global' \
  'segment pointer mapper' \
  'guest CFG / flattened dispatcher model'; do
  grep -Fq "native contract finding: $FINDING" "$FINAL_REPORT"
done
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes=brighten-native-cleanup-final-pass -brighten-native-strict \
    -disable-output "$ROOT/tests/final_contract_residuals.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: strict verifier accepted generated recovery artifacts" >&2
  exit 1
fi
rm -f "$FINAL_CONTROL_OUT" "$FINAL_VERIFY_OUT" "$FINAL_REPORT"

OVERLAPPING_FALLBACK_CONTROL="$(mktemp)"
OVERLAPPING_FALLBACK_FINAL="$(mktemp)"
OVERLAPPING_FALLBACK_REPORT="$(mktemp)"
trap 'rm -f "$OVERLAPPING_FALLBACK_CONTROL" "$OVERLAPPING_FALLBACK_FINAL" "$OVERLAPPING_FALLBACK_REPORT"' EXIT
"$OPT" -passes=verify -S \
  "$ROOT/tests/final_contract_overlapping_pointer_fallback.ll" \
  -o "$OVERLAPPING_FALLBACK_CONTROL"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -S \
  "$ROOT/tests/final_contract_overlapping_pointer_fallback.ll" \
  -o "$OVERLAPPING_FALLBACK_FINAL" 2>"$OVERLAPPING_FALLBACK_REPORT"
cmp "$OVERLAPPING_FALLBACK_CONTROL" "$OVERLAPPING_FALLBACK_FINAL"
grep -Fq 'native contract finding: generated raw pointer fallback: ambiguous_overlap_store' \
  "$OVERLAPPING_FALLBACK_REPORT"
grep -Fq 'native contract finding: surviving mapper/select fallback chain: ambiguous_overlap_store' \
  "$OVERLAPPING_FALLBACK_REPORT"
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes=brighten-native-cleanup-final-pass -brighten-native-strict \
    -disable-output "$ROOT/tests/final_contract_overlapping_pointer_fallback.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: strict verifier accepted overlapping pointer fallback" >&2
  exit 1
fi
rm -f "$OVERLAPPING_FALLBACK_CONTROL" "$OVERLAPPING_FALLBACK_FINAL" \
  "$OVERLAPPING_FALLBACK_REPORT"

DEAD_INLINE_ASM_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" -passes='brighten-native-cleanup-final-pass,verify' \
  -S "$ROOT/tests/final_dead_inline_asm.ll" \
  -o "$DEAD_INLINE_ASM_OUT"
if ! grep -Fq ' asm ' "$DEAD_INLINE_ASM_OUT"; then
  echo "FAIL: final verifier mutated an unused inline asm call" >&2
  exit 1
fi
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes=brighten-native-cleanup-final-pass -brighten-native-strict \
    -disable-output "$ROOT/tests/final_dead_inline_asm.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: strict verifier accepted residual inline asm" >&2
  exit 1
fi
rm -f "$DEAD_INLINE_ASM_OUT"

SIDE_EFFECT_INLINE_ASM_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" -passes='brighten-native-cleanup-final-pass,verify' \
  -S "$ROOT/tests/sideeffect_inline_asm_preserved.ll" \
  -o "$SIDE_EFFECT_INLINE_ASM_OUT"
grep -Eq 'asm sideeffect "nop"' "$SIDE_EFFECT_INLINE_ASM_OUT"
rm -f "$SIDE_EFFECT_INLINE_ASM_OUT"

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

CONSTANT_DISPATCH_CONTROL="$(mktemp)"
CONSTANT_DISPATCH_FINAL="$(mktemp)"
"$OPT" -passes=verify -S "$ROOT/tests/constant_expr_dispatcher_slot.ll" \
  -o "$CONSTANT_DISPATCH_CONTROL"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -S \
  "$ROOT/tests/constant_expr_dispatcher_slot.ll" \
  -o "$CONSTANT_DISPATCH_FINAL" 2>/dev/null
cmp "$CONSTANT_DISPATCH_CONTROL" "$CONSTANT_DISPATCH_FINAL"
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes=brighten-native-cleanup-final-pass -brighten-native-strict \
    -disable-output "$ROOT/tests/constant_expr_dispatcher_slot.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: final verifier promoted residual dispatcher storage" >&2
  exit 1
fi
rm -f "$CONSTANT_DISPATCH_CONTROL" "$CONSTANT_DISPATCH_FINAL"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' \
  -brighten-native-strict -disable-output \
  "$ROOT/tests/native_inst_label.ll"

THREAD_POINTER_CONTROL="$(mktemp)"
THREAD_POINTER_FINAL="$(mktemp)"
"$OPT" -passes=verify -S "$ROOT/tests/thread_pointer_inline_asm.ll" \
  -o "$THREAD_POINTER_CONTROL"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -S \
  "$ROOT/tests/thread_pointer_inline_asm.ll" -o "$THREAD_POINTER_FINAL" \
  2>/dev/null
cmp "$THREAD_POINTER_CONTROL" "$THREAD_POINTER_FINAL"
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes=brighten-native-cleanup-final-pass -brighten-native-strict \
    -disable-output "$ROOT/tests/thread_pointer_inline_asm.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: strict verifier accepted residual TLS inline asm" >&2
  exit 1
fi
rm -f "$THREAD_POINTER_CONTROL" "$THREAD_POINTER_FINAL"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/thread_pointer_inline_asm.ll" -o - |
  "${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
    "$ROOT/tests/thread_pointer_inline_asm.ll"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,default<O3>,verify' -S \
  "$ROOT/tests/unique_local_frame_boundary.ll" -o - |
  "${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
    "$ROOT/tests/unique_local_frame_boundary.ll"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,brighten-native-cleanup-final-pass,verify' \
  -brighten-native-strict -S \
  "$ROOT/tests/direct_overwritten_undefined_scaffold.ll" -o - |
  "${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
    "$ROOT/tests/direct_overwritten_undefined_scaffold.ll"

# The same exact scaffold proof must run after late O3/095, where aggregate
# return builders can first become visible at the post-frame boundary.
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,brighten-native-cleanup-final-pass,verify' \
  -brighten-native-strict -S \
  "$ROOT/tests/direct_overwritten_undefined_scaffold.ll" -o - |
  "${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
    "$ROOT/tests/direct_overwritten_undefined_scaffold.ll"

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,brighten-native-cleanup-final-pass,verify' \
  -brighten-native-strict -S \
  "$ROOT/tests/unused_lifted_segment_in_llvm_used.ll" -o - |
  "${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
    "$ROOT/tests/unused_lifted_segment_in_llvm_used.ll"

RESIDUAL_ARTIFACT_CONTROL="$(mktemp)"
RESIDUAL_ARTIFACT_FINAL="$(mktemp)"
"$OPT" -passes=verify -S "$ROOT/tests/residual_artifacts_cleanup.ll" \
  -o "$RESIDUAL_ARTIFACT_CONTROL"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -S \
  "$ROOT/tests/residual_artifacts_cleanup.ll" \
  -o "$RESIDUAL_ARTIFACT_FINAL" 2>/dev/null
cmp "$RESIDUAL_ARTIFACT_CONTROL" "$RESIDUAL_ARTIFACT_FINAL"
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes=brighten-native-cleanup-final-pass -brighten-native-strict \
    -disable-output "$ROOT/tests/residual_artifacts_cleanup.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: strict verifier accepted residual image globals" >&2
  exit 1
fi
rm -f "$RESIDUAL_ARTIFACT_CONTROL" "$RESIDUAL_ARTIFACT_FINAL"

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
grep -Eq 'define internal i64 @worker\(ptr %(frame_base|native_stack), i64 %state_in_2312, i64 %arg_RDI\)' \
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
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/explicit_argument_overrides_state.ll" < "$EXPLICIT_OVERRIDE_OUT"
grep -Eq 'define internal i64 @worker\(i64 %state_in_2280, i64 %arg_RSI\)' \
  "$EXPLICIT_OVERRIDE_OUT"
grep -Eq 'add i64 %arg_RSI, %arg_RSI' "$EXPLICIT_OVERRIDE_OUT"
if grep -Eq 'add i64 %state_in_2280, %arg_RSI|add i64 %arg_RSI, %state_in_2280' \
    "$EXPLICIT_OVERRIDE_OUT"; then
  echo "FAIL: stale State snapshot remained authoritative over explicit argument" >&2
  exit 1
fi

EXPLICIT_OVERRIDE_FINAL_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,brighten-native-cleanup-final-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/explicit_argument_overrides_state.ll" \
  -o "$EXPLICIT_OVERRIDE_FINAL_OUT"
if grep -Eq 'native\.explicit\.integer\.pointer' \
    "$EXPLICIT_OVERRIDE_FINAL_OUT"; then
  echo "FAIL: final pointer identity normalization left a raw native carrier" >&2
  exit 1
fi
grep -Eq 'getelementptr i8, ptr @g_arr_2' "$EXPLICIT_OVERRIDE_FINAL_OUT"

MIXED_NATIVE_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/mixed_native_memory_token.ll" -o "$MIXED_NATIVE_OUT"
grep -Eq 'define internal i64 @worker\(ptr %(frame_base|native_stack), i64 %state_in_2312, i64 %arg_RDI\)' \
  "$MIXED_NATIVE_OUT"
if grep -Eq 'define .*@worker\.native|%memory' "$MIXED_NATIVE_OUT"; then
  echo "FAIL: mixed native Memory token leaked into the application ABI" >&2
  exit 1
fi

RELATIVE_STACK_OUT="$(mktemp)"
RELATIVE_STACK_FRAME_TOP_OUT="$(mktemp)"
SCANF_ABSOLUTE_FRAME_OUT="$(mktemp)"
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
VSCANF_OVERFLOW_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/vscanf_overflow_pointer.ll" -o "$VSCANF_OVERFLOW_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/vscanf_overflow_pointer.ll" < "$VSCANF_OVERFLOW_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/relative_stack_absolute_carrier.ll" -o "$RELATIVE_STACK_OUT"
if grep -Eq 'getelementptr.*ptrtoint.*frame_storage_backing\.worker' \
    "$RELATIVE_STACK_OUT"; then
  echo "FAIL: absolute stack carrier was rebased twice" >&2
  exit 1
fi
if grep -Eq 'native\.stack\.absolute\.delta = sub i64 %absolute\.stack\.address, %native\.stack\.anchor' \
    "$RELATIVE_STACK_OUT"; then
  :
else
  # If the State-SSA transaction is conservatively rolled back, preserving
  # the absolute carrier is valid as long as it is not turned into an unsafe
  # host pointer or rebased twice.
  grep -Eq 'ptrtoint.*frame_storage_backing\.worker' "$RELATIVE_STACK_OUT"
  if grep -Eq 'inttoptr' "$RELATIVE_STACK_OUT"; then
    echo "FAIL: conservative relative-stack fallback left inttoptr" >&2
    exit 1
  fi
fi

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
grep -Eq 'native\.stack\.entry\.delta = sub i64 %(address|state_2312), %native\.boundary\.rsp' \
  "$ENTRY_RSP_SEED_OUT"
if grep -Eq 'native\.stack\.entry\.delta = sub i64 %state_2312, %native\.boundary\.rsp' \
    "$ENTRY_RSP_SEED_OUT"; then
  grep -Eq 'getelementptr i8, ptr %native\.stack\.gep, i64 -32' \
    "$ENTRY_RSP_SEED_OUT"
fi
if grep -Eq 'native\.stack\.entry\.delta = sub i64 %(address|state_2312), %entry\.rbp' \
    "$ENTRY_RSP_SEED_OUT"; then
  echo "FAIL: entry stack address was rebased against initial RBP" >&2
  exit 1
fi
if grep -Eq 'inttoptr' "$ENTRY_RSP_SEED_OUT"; then
  echo "FAIL: entry RSP stack address still contains inttoptr" >&2
  exit 1
fi

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/relative_stack_global_frame_top.ll" \
  -o "$RELATIVE_STACK_FRAME_TOP_OUT"
grep -Eq 'getelementptr (\(i8, ptr |i8, ptr )getelementptr \(i8, ptr @frame_storage_backing\.main, i64 16711680\), i64 (-32|%native\.stack\.absolute\.delta)' \
  "$RELATIVE_STACK_FRAME_TOP_OUT"
if grep -Eq 'getelementptr i8, ptr @frame_storage_backing\.main, i64 %native\.stack\.absolute\.delta|getelementptr i8, ptr @frame_storage_backing\.main, i64 -32' \
    "$RELATIVE_STACK_FRAME_TOP_OUT"; then
  echo "FAIL: relative stack frame-top address was materialized from frame backing base" >&2
  exit 1
fi

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/scanf_absolute_frame_anchor_delta.ll" \
  -o "$SCANF_ABSOLUTE_FRAME_OUT"
grep -Eq 'call i32 \(ptr, \.\.\.\) @scanf\(ptr @fmt, ptr getelementptr .*@frame_storage_backing\.main, i64 16711680.*i64 -16' \
  "$SCANF_ABSOLUTE_FRAME_OUT"
if grep -Eq 'call i32 \(ptr, \.\.\.\) @scanf\(ptr @fmt, ptr getelementptr \(i8, ptr @frame_storage_backing\.main, i64 16711680\)\)' \
    "$SCANF_ABSOLUTE_FRAME_OUT"; then
  echo "FAIL: scanf absolute frame-anchor delta collapsed to frame_top" >&2
  exit 1
fi

SCANF_LATE_RANGE_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/scanf_late_recovered_range.ll" \
  -o "$SCANF_LATE_RANGE_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/scanf_late_recovered_range.ll" < "$SCANF_LATE_RANGE_OUT"

STRCMP_LATE_RANGE_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/strcmp_late_recovered_range.ll" \
  -o "$STRCMP_LATE_RANGE_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/strcmp_late_recovered_range.ll" < "$STRCMP_LATE_RANGE_OUT"

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
trap 'rm -f "$NULL_BOUNDARY_OUT" "$EXPLICIT_NATIVE_OUT" "$EXPLICIT_OVERRIDE_FINAL_OUT" "$MIXED_NATIVE_OUT" "$MIXED_VARARG_OUT" "$RELATIVE_STACK_OUT" "$RELATIVE_STACK_FRAME_TOP_OUT" "$CONSERVATIVE_STACK_OUT" "$ENTRY_RSP_SEED_OUT" "$NESTED_RSP_OUT" "$NESTED_RBP_OUT" "$NESTED_DYNAMIC_OUT" "$NESTED_FIXED_SLOT_OUT" "$NESTED_STACK_ARG_OUT" "$EXACT_STATE_MEMSET_OUT" "$PARTIAL_STATE_MEMSET_OUT" "$DFA_OUT"' EXIT
"$OPT" -passes='dfa-jump-threading,simplifycfg,adce,verify' -S \
  "$ROOT/tests/flattened_ssa.ll" -o "$DFA_OUT"
if grep -Eq 'switch i32' "$DFA_OUT"; then
  echo "FAIL: SSA flattening dispatcher survived DFA threading" >&2
  exit 1
fi
grep -Eq 'ret i32 7' "$DFA_OUT"

FRAME_COMPACT_OUT="$(mktemp)"
FRAME_REFUSE_OUT="$(mktemp)"
AFFINE_FRAME_OUT="$(mktemp)"
AFFINE_FRAME_REFUSE_OUT="$(mktemp)"
AFFINE_DISPATCHER_REFUSE_OUT="$(mktemp)"
AFFINE_DISPATCHER_REFUSE_TWICE="$(mktemp)"
AFFINE_PROOF_REFUSE_OUT="$(mktemp)"
FRAME_POS_BIN="$(mktemp)"
FRAME_NEG_BIN="$(mktemp)"
AFFINE_FRAME_BIN="$(mktemp)"
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

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/proven_affine_frame_compaction.ll" -o "$AFFINE_FRAME_OUT"
if grep -Eq '@frame_storage_backing\.main' "$AFFINE_FRAME_OUT"; then
  echo "FAIL: finite affine fake stack was not compacted" >&2
  exit 1
fi
if grep -Eq 'define internal i32 @worker' "$AFFINE_FRAME_OUT"; then
  echo "FAIL: single-use affine frame worker was not inlined" >&2
  exit 1
fi
grep -Eq 'native_frame = alloca \[[0-9]+ x i8\]' "$AFFINE_FRAME_OUT"
grep -Eq 'call void @llvm\.memset' "$AFFINE_FRAME_OUT"

POST_FRAME_OUT="$(mktemp)"
POST_FRAME_CONTROL="$(mktemp)"
"$OPT" -passes=verify -S \
  "$ROOT/tests/proven_affine_frame_compaction.ll" -o "$POST_FRAME_CONTROL"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -S \
  "$ROOT/tests/proven_affine_frame_compaction.ll" -o "$POST_FRAME_OUT" \
  2>/dev/null
cmp "$POST_FRAME_CONTROL" "$POST_FRAME_OUT"
if "$OPT" -load-pass-plugin="$PLUGIN" \
    -passes=brighten-native-cleanup-final-pass -brighten-native-strict \
    -disable-output "$ROOT/tests/proven_affine_frame_compaction.ll" \
    >/dev/null 2>&1; then
  echo "FAIL: strict verifier accepted unresolved affine frame artifacts" >&2
  exit 1
fi

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/cyclic_affine_frame_compaction_refused.ll" \
  -o "$AFFINE_FRAME_REFUSE_OUT"
grep -Eq '@frame_storage_backing\.main.*zeroinitializer' \
  "$AFFINE_FRAME_REFUSE_OUT"
if grep -Eq 'native_frame = alloca' "$AFFINE_FRAME_REFUSE_OUT"; then
  echo "FAIL: cyclic affine stack was unsafely compacted" >&2
  exit 1
fi

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/affine_frame_helper_dispatcher_refused.ll" \
  -o "$AFFINE_DISPATCHER_REFUSE_OUT"
grep -Eq '@frame_storage_backing\.main.*zeroinitializer' \
  "$AFFINE_DISPATCHER_REFUSE_OUT"
grep -Eq 'define internal i32 @worker' "$AFFINE_DISPATCHER_REFUSE_OUT"
if [[ "$(grep -Ec '^dispatch:' "$AFFINE_DISPATCHER_REFUSE_OUT")" -ne 1 ]]; then
  echo "FAIL: dispatcher-refused affine helper duplicated CFG blocks" >&2
  exit 1
fi
if [[ "$(grep -Ec 'call i32 @worker\(\)' "$AFFINE_DISPATCHER_REFUSE_OUT")" -ne 2 ]]; then
  echo "FAIL: dispatcher-refused affine helper call graph changed" >&2
  exit 1
fi
if grep -Eq 'native_frame = alloca' "$AFFINE_DISPATCHER_REFUSE_OUT"; then
  echo "FAIL: dispatcher-refused affine helper was compacted" >&2
  exit 1
fi
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S "$AFFINE_DISPATCHER_REFUSE_OUT" \
  -o "$AFFINE_DISPATCHER_REFUSE_TWICE"
# opt derives ModuleID from its input filename.  Ignore that volatile banner
# while asserting the pass is idempotent.
cmp <(sed '1{/^; ModuleID = /d;}' "$AFFINE_DISPATCHER_REFUSE_OUT") \
    <(sed '1{/^; ModuleID = /d;}' "$AFFINE_DISPATCHER_REFUSE_TWICE")

"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' \
  -brighten-native-state-ssa -S \
  "$ROOT/tests/affine_frame_helper_proof_refused.ll" \
  -o "$AFFINE_PROOF_REFUSE_OUT"
grep -Eq '@frame_storage_backing\.main.*zeroinitializer' \
  "$AFFINE_PROOF_REFUSE_OUT"
grep -Eq 'define internal i32 @worker' "$AFFINE_PROOF_REFUSE_OUT"
if [[ "$(grep -Ec 'call i32 @worker\(\)' "$AFFINE_PROOF_REFUSE_OUT")" -ne 2 ]]; then
  echo "FAIL: affine-proof refusal changed helper call graph" >&2
  exit 1
fi
if grep -Eq 'native_frame = alloca' "$AFFINE_PROOF_REFUSE_OUT"; then
  echo "FAIL: affine-proof refusal compacted fake frame" >&2
  exit 1
fi

CLANG="${CLANG:-$(command -v clang-21 || command -v clang)}"
"$CLANG" -x ir "$FRAME_COMPACT_OUT" -o "$FRAME_POS_BIN"
"$CLANG" -x ir "$FRAME_REFUSE_OUT" -o "$FRAME_NEG_BIN"
"$CLANG" -x ir "$AFFINE_FRAME_OUT" -o "$AFFINE_FRAME_BIN"
set +e
"$FRAME_POS_BIN"
FRAME_POS_STATUS=$?
"$FRAME_NEG_BIN"
FRAME_NEG_STATUS=$?
"$AFFINE_FRAME_BIN"
AFFINE_FRAME_STATUS=$?
set -e
if [[ "$FRAME_POS_STATUS" -ne 7 || "$FRAME_NEG_STATUS" -ne 0 ||
      "$AFFINE_FRAME_STATUS" -ne 7 ]]; then
  echo "FAIL: frame compaction executable semantics changed" >&2
  exit 1
fi
rm -f "$FRAME_COMPACT_OUT" "$FRAME_REFUSE_OUT" \
  "$AFFINE_FRAME_OUT" "$AFFINE_FRAME_REFUSE_OUT" \
  "$AFFINE_DISPATCHER_REFUSE_OUT" "$AFFINE_DISPATCHER_REFUSE_TWICE" \
  "$AFFINE_PROOF_REFUSE_OUT" "$POST_FRAME_OUT" \
  "$POST_FRAME_CONTROL" \
  "$FRAME_POS_BIN" "$FRAME_NEG_BIN" "$AFFINE_FRAME_BIN"

POINTER_DIFFERENCE_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/recovered_pointer_difference.ll" \
  -o "$POINTER_DIFFERENCE_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/recovered_pointer_difference.ll" < "$POINTER_DIFFERENCE_OUT"
rm -f "$POINTER_DIFFERENCE_OUT"

SAME_BASE_OFFSET_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/same_base_pointer_offset.ll" \
  -o "$SAME_BASE_OFFSET_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/same_base_pointer_offset.ll" < "$SAME_BASE_OFFSET_OUT"
rm -f "$SAME_BASE_OFFSET_OUT"

STATE_SSA_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/single_function_state_ssa.ll" \
  -o "$STATE_SSA_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/single_function_state_ssa.ll" < "$STATE_SSA_OUT"
rm -f "$STATE_SSA_OUT"

SHARED_STATE_CONTEXT_OUT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-pass,verify' -S \
  "$ROOT/tests/shared_state_context.ll" \
  -o "$SHARED_STATE_CONTEXT_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/shared_state_context.ll" < "$SHARED_STATE_CONTEXT_OUT"
rm -f "$SHARED_STATE_CONTEXT_OUT"

RESOLVER_OUTLINE_OUT="$(mktemp)"
RESOLVER_OUTLINE_TWICE="$(mktemp)"
RESOLVER_CONTRACT_REPORT="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/recovered_resolver_outlining.ll" \
  -o "$RESOLVER_OUTLINE_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/recovered_resolver_outlining.ll" < "$RESOLVER_OUTLINE_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$RESOLVER_OUTLINE_OUT" -o "$RESOLVER_OUTLINE_TWICE"
cmp <(sed '1{/^; ModuleID = /d;}' "$RESOLVER_OUTLINE_OUT") \
    <(sed '1{/^; ModuleID = /d;}' "$RESOLVER_OUTLINE_TWICE")
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-final-pass,verify' -disable-output \
  "$RESOLVER_OUTLINE_OUT" 2>"$RESOLVER_CONTRACT_REPORT"
grep -Fq 'native contract finding: generated raw pointer fallback: mismatched_resolver' \
  "$RESOLVER_CONTRACT_REPORT"
grep -Fq 'native contract finding: surviving mapper/select fallback chain: mismatched_resolver' \
  "$RESOLVER_CONTRACT_REPORT"
if grep -Fq 'native contract finding: generated raw pointer fallback: __brighten_resolve_recovered_address' \
    "$RESOLVER_CONTRACT_REPORT" || \
   grep -Fq 'native contract finding: surviving mapper/select fallback chain: __brighten_resolve_recovered_address' \
    "$RESOLVER_CONTRACT_REPORT"; then
  echo "FAIL: exact recovered-address resolver boundary was reported as an inline mapper" >&2
  exit 1
fi
rm -f "$RESOLVER_OUTLINE_OUT" "$RESOLVER_OUTLINE_TWICE" \
  "$RESOLVER_CONTRACT_REPORT"

NATIVE_RESOLVER_CALL_OUT="$(mktemp)"
NATIVE_RESOLVER_CALL_TWICE="$(mktemp)"
NATIVE_RESOLVER_CALL_BEFORE="$(mktemp)"
NATIVE_RESOLVER_CALL_AFTER="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/native_outlined_resolver_call.ll" \
  -o "$NATIVE_RESOLVER_CALL_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/native_outlined_resolver_call.ll" \
  < "$NATIVE_RESOLVER_CALL_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$NATIVE_RESOLVER_CALL_OUT" -o "$NATIVE_RESOLVER_CALL_TWICE"
cmp <(sed '1{/^; ModuleID = /d;}' "$NATIVE_RESOLVER_CALL_OUT") \
    <(sed '1{/^; ModuleID = /d;}' "$NATIVE_RESOLVER_CALL_TWICE")
"${CLANG:-$(command -v clang-21 || command -v clang)}" -x ir \
  "$ROOT/tests/native_outlined_resolver_call.ll" \
  -o "$NATIVE_RESOLVER_CALL_BEFORE"
"${CLANG:-$(command -v clang-21 || command -v clang)}" -x ir \
  "$NATIVE_RESOLVER_CALL_OUT" -o "$NATIVE_RESOLVER_CALL_AFTER"
"$NATIVE_RESOLVER_CALL_BEFORE"
"$NATIVE_RESOLVER_CALL_AFTER"
rm -f "$NATIVE_RESOLVER_CALL_OUT" "$NATIVE_RESOLVER_CALL_TWICE" \
  "$NATIVE_RESOLVER_CALL_BEFORE" "$NATIVE_RESOLVER_CALL_AFTER"

RESIDUAL_VIEWS_OUT="$(mktemp)"
RESIDUAL_VIEWS_TWICE="$(mktemp)"
RESIDUAL_VIEWS_BEFORE="$(mktemp)"
RESIDUAL_VIEWS_AFTER="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/residual_constant_offset_views.ll" \
  -o "$RESIDUAL_VIEWS_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/residual_constant_offset_views.ll" \
  < "$RESIDUAL_VIEWS_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$RESIDUAL_VIEWS_OUT" -o "$RESIDUAL_VIEWS_TWICE"
cmp <(sed '1{/^; ModuleID = /d;}' "$RESIDUAL_VIEWS_OUT") \
    <(sed '1{/^; ModuleID = /d;}' "$RESIDUAL_VIEWS_TWICE")
"${CLANG:-$(command -v clang-21 || command -v clang)}" -x ir \
  "$ROOT/tests/residual_constant_offset_views.ll" \
  -o "$RESIDUAL_VIEWS_BEFORE"
"${CLANG:-$(command -v clang-21 || command -v clang)}" -x ir \
  "$RESIDUAL_VIEWS_OUT" -o "$RESIDUAL_VIEWS_AFTER"
"$RESIDUAL_VIEWS_BEFORE"
"$RESIDUAL_VIEWS_AFTER"
rm -f "$RESIDUAL_VIEWS_OUT" "$RESIDUAL_VIEWS_TWICE" \
  "$RESIDUAL_VIEWS_BEFORE" "$RESIDUAL_VIEWS_AFTER"

CALL_FOOTPRINT_OUT="$(mktemp)"
CALL_FOOTPRINT_TWICE="$(mktemp)"
CALL_FOOTPRINT_BEFORE="$(mktemp)"
CALL_FOOTPRINT_AFTER="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/disjoint_internal_call_frame_forwarding.ll" \
  -o "$CALL_FOOTPRINT_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/disjoint_internal_call_frame_forwarding.ll" \
  < "$CALL_FOOTPRINT_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$CALL_FOOTPRINT_OUT" -o "$CALL_FOOTPRINT_TWICE"
cmp <(sed '1{/^; ModuleID = /d;}' "$CALL_FOOTPRINT_OUT") \
    <(sed '1{/^; ModuleID = /d;}' "$CALL_FOOTPRINT_TWICE")
"${CLANG:-$(command -v clang-21 || command -v clang)}" -x ir \
  "$ROOT/tests/disjoint_internal_call_frame_forwarding.ll" \
  -o "$CALL_FOOTPRINT_BEFORE"
"${CLANG:-$(command -v clang-21 || command -v clang)}" -x ir \
  "$CALL_FOOTPRINT_OUT" -o "$CALL_FOOTPRINT_AFTER"
"$CALL_FOOTPRINT_BEFORE"
"$CALL_FOOTPRINT_AFTER"
rm -f "$CALL_FOOTPRINT_OUT" "$CALL_FOOTPRINT_TWICE" \
  "$CALL_FOOTPRINT_BEFORE" "$CALL_FOOTPRINT_AFTER"

GUEST_FRAME_ABI_OUT="$(mktemp)"
GUEST_FRAME_ABI_TWICE="$(mktemp)"
GUEST_FRAME_ABI_BEFORE="$(mktemp)"
GUEST_FRAME_ABI_AFTER="$(mktemp)"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$ROOT/tests/translation_invariant_guest_frame_abi.ll" \
  -o "$GUEST_FRAME_ABI_OUT"
"${FILECHECK:-$(command -v FileCheck-21 || command -v FileCheck)}" \
  "$ROOT/tests/translation_invariant_guest_frame_abi.ll" \
  < "$GUEST_FRAME_ABI_OUT"
"$OPT" -load-pass-plugin="$PLUGIN" \
  -passes='brighten-native-cleanup-post-frame-pass,verify' -S \
  "$GUEST_FRAME_ABI_OUT" -o "$GUEST_FRAME_ABI_TWICE"
cmp <(sed '1{/^; ModuleID = /d;}' "$GUEST_FRAME_ABI_OUT") \
    <(sed '1{/^; ModuleID = /d;}' "$GUEST_FRAME_ABI_TWICE")
"${CLANG:-$(command -v clang-21 || command -v clang)}" -x ir \
  "$ROOT/tests/translation_invariant_guest_frame_abi.ll" \
  -o "$GUEST_FRAME_ABI_BEFORE"
"${CLANG:-$(command -v clang-21 || command -v clang)}" -x ir \
  "$GUEST_FRAME_ABI_OUT" -o "$GUEST_FRAME_ABI_AFTER"
"$GUEST_FRAME_ABI_BEFORE"
"$GUEST_FRAME_ABI_AFTER"
rm -f "$GUEST_FRAME_ABI_OUT" "$GUEST_FRAME_ABI_TWICE" "$GUEST_FRAME_ABI_BEFORE" \
  "$GUEST_FRAME_ABI_AFTER"

echo "Native State SSA tests: PASS"
