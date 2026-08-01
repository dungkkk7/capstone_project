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
CYCLIC_OUT="$(mktemp)"
NONFINITE_OUT="$(mktemp)"
READ_FIRST_OUT="$(mktemp)"
POST_STATE_OUT="$(mktemp)"
POST_STATE_REFUSED_OUT="$(mktemp)"
POST_STATE_KNOWN_CALL_OUT="$(mktemp)"
POST_STATE_CALL_REFUSED_OUT="$(mktemp)"
POST_STATE_VOLATILE_ATOMIC_OUT="$(mktemp)"
POST_STATE_PTRINT_OUT="$(mktemp)"
POST_STATE_SCANF_OUT="$(mktemp)"
POST_STATE_SCANF_REFUSED_OUT="$(mktemp)"
POST_STATE_PERSISTENT_OUT="$(mktemp)"
POST_STATE_ENTRY_CONTRACT_REFUSED_OUT="$(mktemp)"
POST_STATE_PROOF_REFUSED_OUT="$(mktemp)"
ENTRY_ABI_SLOT_OUT="$(mktemp)"
POINTER_SLOT_OUT="$(mktemp)"
POINTER_SLOT_LIFECYCLE_OUT="$(mktemp)"
SCALAR_SLOT_OUT="$(mktemp)"
AUDIT_OFF_OUT="$(mktemp)"
AUDIT_ON_OUT="$(mktemp)"
AUDIT_LOG="$(mktemp)"
NATIVE_PLUGIN="$ROOT/../brighten_090_native_cleanup/build/BrightenNativeCleanupPass.so"
trap 'rm -f "$OUT" "$DISJOINT_OUT" "$PARTIAL_OUT" "$MIXED_OUT" "$CALL_OUT" "$LARGE_OUT" "$CYCLIC_OUT" "$NONFINITE_OUT" "$READ_FIRST_OUT" "$POST_STATE_OUT" "$POST_STATE_REFUSED_OUT" "$POST_STATE_KNOWN_CALL_OUT" "$POST_STATE_CALL_REFUSED_OUT" "$POST_STATE_VOLATILE_ATOMIC_OUT" "$POST_STATE_PTRINT_OUT" "$POST_STATE_SCANF_OUT" "$POST_STATE_SCANF_REFUSED_OUT" "$POST_STATE_PERSISTENT_OUT" "$POST_STATE_ENTRY_CONTRACT_REFUSED_OUT" "$POST_STATE_PROOF_REFUSED_OUT" "$ENTRY_ABI_SLOT_OUT" "$POINTER_SLOT_OUT" "$POINTER_SLOT_LIFECYCLE_OUT" "$SCALAR_SLOT_OUT" "$AUDIT_OFF_OUT" "$AUDIT_ON_OUT" "$AUDIT_LOG"' EXIT

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_promoted_rsp_slot.ll" -o "$OUT"

grep -q 'native_local_frame = alloca \[8 x i8\]' "$OUT"
grep -q 'store i64 42, ptr %frame_ptr' "$OUT"
grep -q 'load i64, ptr %frame_ptr' "$OUT"
! grep -q 'llvm.memcpy' "$OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_entry_rsp_abi_slot_refused.ll" \
  -o "$ENTRY_ABI_SLOT_OUT"

! grep -q 'native_local_frame' "$ENTRY_ABI_SLOT_OUT"
grep -q 'store i64 %rbp, ptr %abi.ptr' "$ENTRY_ABI_SLOT_OUT"
grep -q 'load i64, ptr %abi.ptr' "$ENTRY_ABI_SLOT_OUT"

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

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_cyclic_affine_frame.ll" -o "$CYCLIC_OUT"

grep -q 'native_local_frame = alloca \[41 x i8\]' "$CYCLIC_OUT"
grep -Eq 'store i64 11, ptr %frame_ptr[0-9]*' "$CYCLIC_OUT"
grep -Eq 'store i8 1, ptr %frame_ptr[0-9]*' "$CYCLIC_OUT"
grep -Eq 'load i8, ptr %frame_ptr[0-9]*' "$CYCLIC_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_nonfinite_stack_phi.ll" -o "$NONFINITE_OUT"

! grep -q 'native_local_frame' "$NONFINITE_OUT"
grep -q 'call ptr @__translate_guest_pointer(i64 %addr, i1 true)' "$NONFINITE_OUT"
grep -q 'store i64 7, ptr %ptr' "$NONFINITE_OUT"
grep -q 'store i64 9, ptr %ptr' "$NONFINITE_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-stack-frame-pass \
  -verify-each -S "$ROOT/tests/test_finite_read_before_write.ll" \
  -o "$READ_FIRST_OUT"

! grep -q 'native_local_frame' "$READ_FIRST_OUT"
grep -q 'load i8, ptr %flag.ptr' "$READ_FIRST_OUT"
grep -q 'store i8 1, ptr %flag.ptr' "$READ_FIRST_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_compaction.ll" \
  -o "$POST_STATE_OUT"

grep -q 'native_frame = alloca \[4 x i8\]' "$POST_STATE_OUT"
! grep -q '@backing' "$POST_STATE_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_compaction_refused.ll" \
  -o "$POST_STATE_REFUSED_OUT"

grep -q '@backing = internal global' "$POST_STATE_REFUSED_OUT"
! grep -q 'native_frame = alloca' "$POST_STATE_REFUSED_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_known_call.ll" \
  -o "$POST_STATE_KNOWN_CALL_OUT"

grep -q 'native_frame = alloca \[4 x i8\]' "$POST_STATE_KNOWN_CALL_OUT"
grep -q 'llvm.memset.p0.i64(ptr align 4 %native.frame.slot' "$POST_STATE_KNOWN_CALL_OUT"
! grep -q '@backing = internal global' "$POST_STATE_KNOWN_CALL_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_call_refused.ll" \
  -o "$POST_STATE_CALL_REFUSED_OUT"

# Both failures must leave the module byte-for-byte in its global-backed form:
# this is the transactional refusal regression.
grep -q '@nocapture_backing = internal global' "$POST_STATE_CALL_REFUSED_OUT"
grep -q '@unknown_backing = internal global' "$POST_STATE_CALL_REFUSED_OUT"
! grep -q 'native_frame = alloca' "$POST_STATE_CALL_REFUSED_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_volatile_atomic_refused.ll" \
  -o "$POST_STATE_VOLATILE_ATOMIC_OUT"

grep -q '@volatile_backing = internal global' "$POST_STATE_VOLATILE_ATOMIC_OUT"
grep -q '@atomic_backing = internal global' "$POST_STATE_VOLATILE_ATOMIC_OUT"
! grep -q 'native_frame = alloca' "$POST_STATE_VOLATILE_ATOMIC_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_ptrint_refused.ll" \
  -o "$POST_STATE_PTRINT_OUT"

grep -q '@backing = internal global' "$POST_STATE_PTRINT_OUT"
grep -q 'add nsw i64 %base, 4' "$POST_STATE_PTRINT_OUT"
! grep -q 'native_frame = alloca' "$POST_STATE_PTRINT_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_scanf_contract.ll" \
  -o "$POST_STATE_SCANF_OUT"

# A may-write input call has no local-frame memory summary.  It must not be
# localized merely because a prior producer used a broad stack contract.
grep -q '@backing = internal global' "$POST_STATE_SCANF_OUT"
! grep -q 'native_frame = alloca' "$POST_STATE_SCANF_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_persistent_read.ll" \
  -o "$POST_STATE_PERSISTENT_OUT"

# A load before its store observes persistent state from a prior invocation.
# The candidate must be left globally backed and the refusal must be atomic.
grep -q '@backing = internal global' "$POST_STATE_PERSISTENT_OUT"
grep -q 'load i32, ptr %slot' "$POST_STATE_PERSISTENT_OUT"
grep -q 'store i32 %next, ptr %slot' "$POST_STATE_PERSISTENT_OUT"
! grep -q 'native_frame = alloca' "$POST_STATE_PERSISTENT_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_scanf_contract_refused.ll" \
  -o "$POST_STATE_SCANF_REFUSED_OUT"

grep -q '@wrong_version = internal global' "$POST_STATE_SCANF_REFUSED_OUT"
grep -q '@wrong_index = internal global' "$POST_STATE_SCANF_REFUSED_OUT"
grep -q '@wrong_size = internal global' "$POST_STATE_SCANF_REFUSED_OUT"
grep -q '@retained = internal global' "$POST_STATE_SCANF_REFUSED_OUT"
grep -q '@duplicate_use = internal global' "$POST_STATE_SCANF_REFUSED_OUT"
grep -q '@bundle_use = internal global' "$POST_STATE_SCANF_REFUSED_OUT"
! grep -q 'native_frame = alloca' "$POST_STATE_SCANF_REFUSED_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_entry_contract_refused.ll" \
  -o "$POST_STATE_ENTRY_CONTRACT_REFUSED_OUT"

# A manually annotated preexisting backing and duplicate producer records do
# not establish that 090 synthesized a fresh per-entry object.
grep -q '@preexisting = internal global' "$POST_STATE_ENTRY_CONTRACT_REFUSED_OUT"
grep -q '@duplicate = internal global' "$POST_STATE_ENTRY_CONTRACT_REFUSED_OUT"
! grep -q 'native_frame = alloca' "$POST_STATE_ENTRY_CONTRACT_REFUSED_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_post_state_frame_proof_refused.ll" \
  -o "$POST_STATE_PROOF_REFUSED_OUT"

# Every candidate has the explicit capability; each must be refused by its
# own graph, lifetime, callback, overlap, or saved-RBP proof failure.
grep -q '@ptrint_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@dynamic_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@escape_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@call_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@qsort_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@recursive_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@address_taken_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@volatile_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@atomic_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@lifetime_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@overlap_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@scanf_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
grep -q '@rbp_backing = internal global' "$POST_STATE_PROOF_REFUSED_OUT"
! grep -q 'native_frame = alloca' "$POST_STATE_PROOF_REFUSED_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_pointer_slot_retyping.ll" \
  -o "$POINTER_SLOT_OUT"

grep -q 'native.pointer.slot = alloca ptr, align 8' "$POINTER_SLOT_OUT"
grep -q 'store ptr %p, ptr %native.pointer.slot, align 8' "$POINTER_SLOT_OUT"
grep -q 'load ptr, ptr %native.pointer.slot, align 8' "$POINTER_SLOT_OUT"
grep -q 'icmp eq ptr %native.pointer.slot.load, null' "$POINTER_SLOT_OUT"
! grep -q 'ptrtoint ptr %p to i64' "$POINTER_SLOT_OUT"
grep -q 'call void @print_i64(i64 %raw)' "$POINTER_SLOT_OUT"
grep -q 'add nsw i64 %bits, 1' "$POINTER_SLOT_OUT"
grep -q 'store i64 %bits, ptr %slot, align 8' "$POINTER_SLOT_OUT"

"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass \
  -verify-each -S "$ROOT/tests/test_scalar_slot_localization.ll" \
  -o "$SCALAR_SLOT_OUT"

grep -q 'native.scalar.slot = alloca i32, align 4' "$SCALAR_SLOT_OUT"
grep -q 'native.scalar.slot = alloca i8, align 1' "$SCALAR_SLOT_OUT"
grep -q 'native.scalar.slot = alloca i16, align 2' "$SCALAR_SLOT_OUT"
grep -q 'native.scalar.slot = alloca i64, align 8' "$SCALAR_SLOT_OUT"
grep -q 'store i32 0, ptr %native.scalar.slot, align 4' "$SCALAR_SLOT_OUT"
grep -q 'store i16 1, ptr %slot, align 2' "$SCALAR_SLOT_OUT"
grep -q 'store i8 99, ptr %neighbor, align 1' "$SCALAR_SLOT_OUT"
grep -q 'call void @capture(ptr %slot)' "$SCALAR_SLOT_OUT"
grep -q 'store volatile i32 1, ptr %slot, align 4' "$SCALAR_SLOT_OUT"
grep -q 'store atomic i32 1, ptr %slot monotonic, align 4' "$SCALAR_SLOT_OUT"
grep -q 'store volatile i64 %bits, ptr %slot, align 8' "$POINTER_SLOT_OUT"
grep -q 'store atomic i64 %bits, ptr %slot monotonic, align 8' "$POINTER_SLOT_OUT"
grep -q 'define void @recursive_access()' "$POINTER_SLOT_OUT"
grep -q 'store i64 %bits, ptr %slot, align 8' "$POINTER_SLOT_OUT"
grep -Eq 'native.pointer.slot[0-9]* = alloca ptr, align 8' "$POINTER_SLOT_OUT"
grep -q 'define void @conditional_store(i1 %take_store)' "$POINTER_SLOT_OUT"
grep -q 'call void @reentrant_callback(ptr %slot)' "$POINTER_SLOT_OUT"
grep -q 'native.pointer.slot.bits' "$POINTER_SLOT_OUT"
grep -q 'native.data.pointer.select = select i1 %in.range' "$POINTER_SLOT_OUT"

# This is the final post-canonical lifecycle: no SROA/O3 producer runs after
# 040, and the native-contract pass only reports.  A pointer slot and its one
# address sidecar must therefore reach the final IR unchanged.
[[ -f "$NATIVE_PLUGIN" ]]
"$OPT" -load-pass-plugin="$PLUGIN" -load-pass-plugin="$NATIVE_PLUGIN" \
  -passes=brighten-post-state-frame-pass,brighten-native-cleanup-final-pass,verify \
  -verify-each -S "$ROOT/tests/test_pointer_slot_lifecycle.ll" \
  -o "$POINTER_SLOT_LIFECYCLE_OUT"

grep -q 'native.pointer.slot = alloca ptr, align 8' "$POINTER_SLOT_LIFECYCLE_OUT"
grep -q 'store ptr %p, ptr %native.pointer.slot, align 8' "$POINTER_SLOT_LIFECYCLE_OUT"
grep -q 'native.pointer.slot.bits = ptrtoint ptr %native.pointer.slot.load to i64' "$POINTER_SLOT_LIFECYCLE_OUT"
! grep -q 'store i64 .*slot_backing' "$POINTER_SLOT_LIFECYCLE_OUT"
! grep -q 'load i64, ptr.*slot_backing' "$POINTER_SLOT_LIFECYCLE_OUT"

# Audit mode is deliberately analysis-only: the serialized IR must be exactly
# identical with the flag on and off, while stderr carries deterministic
# candidate/refusal evidence.
"$OPT" -load-pass-plugin="$PLUGIN" -passes=brighten-post-state-frame-pass,verify \
  -S "$ROOT/tests/test_activation_frame_audit.ll" -o "$AUDIT_OFF_OUT"

BRIGHTEN_ACTIVATION_FRAME_AUDIT=1 "$OPT" -load-pass-plugin="$PLUGIN" \
  -passes=brighten-post-state-frame-pass,verify -S \
  "$ROOT/tests/test_activation_frame_audit.ll" -o "$AUDIT_ON_OUT" \
  2>"$AUDIT_LOG"

cmp -s "$AUDIT_OFF_OUT" "$AUDIT_ON_OUT"
grep -q 'function=positive_owner .*root=ssa .*init=dominating_write blocker=none candidate=true' "$AUDIT_LOG"
grep -q 'function=cross_owner .*candidate=false' "$AUDIT_LOG"
grep -q 'function=recursive_owner .*blocker=lifetime_or_recursion candidate=false' "$AUDIT_LOG"
grep -q 'function=observed_owner .*blocker=pointer_integer_observation candidate=false' "$AUDIT_LOG"
grep -q 'function=volatile_owner .*blocker=volatile_or_atomic candidate=false' "$AUDIT_LOG"
grep -q 'function=unknown_init_owner .*init=unknown blocker=unknown_init candidate=false' "$AUDIT_LOG"
grep -q 'function=nonzero_root_owner .*blocker=root_shape candidate=false' "$AUDIT_LOG"
grep -q 'function=dynamic_root_owner .*blocker=root_shape candidate=false' "$AUDIT_LOG"

echo "Stack frame recovery tests: PASS"
