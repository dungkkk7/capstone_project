; RUN: opt-21 -load-pass-plugin %llvmshlibdir/BrightenRuntimeHelperPass%shlibext -passes=brighten-remill-runtime-pass,verify -S %s -o - | FileCheck-21 %s

; The positive helpers model the explicit fault branches emitted by the
; lifted x86 DIV/IDIV helpers.  The pass must not depend on their names.

declare void @abort() noreturn

define i32 @signed_zero(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %fault, label %check_overflow

check_overflow:
  %ismin = icmp eq i32 %dividend, -2147483648
  %isminusone = icmp eq i32 %divisor, -1
  %overflow = and i1 %ismin, %isminusone
  br i1 %overflow, label %fault, label %normal

fault:
  call void @abort()
  unreachable

normal:
  %quotient = sdiv i32 %dividend, %divisor
  ret i32 %quotient
}

define i32 @unsigned_zero(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %fault, label %normal

fault:
  call void @abort()
  unreachable

normal:
  %quotient = udiv i32 %dividend, %divisor
  ret i32 %quotient
}

define i32 @signed_overflow(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %fault, label %check_overflow

check_overflow:
  %ismin = icmp eq i32 %dividend, -2147483648
  %isminusone = icmp eq i32 %divisor, -1
  %overflow = and i1 %ismin, %isminusone
  br i1 %overflow, label %fault, label %normal

fault:
  call void @abort()
  unreachable

normal:
  %quotient = sdiv i32 %dividend, %divisor
  ret i32 %quotient
}

; Real lifted IDIV helpers can retain distinct zero and overflow abort blocks.
define i32 @signed_separate_fault_blocks(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %zero_fault, label %check_overflow

check_overflow:
  %ismin = icmp eq i32 %dividend, -2147483648
  %isminusone = icmp eq i32 %divisor, -1
  %overflow = and i1 %ismin, %isminusone
  br i1 %overflow, label %overflow_fault, label %normal

zero_fault:
  call void @abort()
  unreachable

overflow_fault:
  call void @abort()
  unreachable

normal:
  %quotient = sdiv i32 %dividend, %divisor
  ret i32 %quotient
}

; Exact p028-style IDIV lowering: guard a widened register, reconstruct the
; divisor with ashr exact, then reject a quotient outside signed i32 range.
define i64 @lifted_idiv_range_faults(i64 %dividend, i64 %divisor_word) {
entry:
  %wide = shl i64 %divisor_word, 32
  %iszero = icmp eq i64 %wide, 0
  br i1 %iszero, label %zero_fault, label %divide

divide:
  %divisor = ashr exact i64 %wide, 32
  %quotient = sdiv i64 %dividend, %divisor
  %biased = add i64 %quotient, 2147483648
  %in_i32_range = icmp ult i64 %biased, 4294967296
  br i1 %in_i32_range, label %normal, label %overflow_fault

zero_fault:
  call void @abort()
  unreachable

overflow_fault:
  call void @abort()
  unreachable

normal:
  ret i64 %quotient
}

; Ordinary process termination is not a CPU divide fault.
define void @ordinary_abort() {
entry:
  call void @abort()
  unreachable
}

; No fault CFG: this must remain untouched despite containing sdiv.
define i32 @unrelated_sdiv(i32 %left, i32 %right) {
entry:
  %quotient = sdiv i32 %left, %right
  ret i32 %quotient
}

; Missing the IDIV overflow guard: reject the whole helper.
define i32 @malformed_signed_guard(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %fault, label %normal

fault:
  call void @abort()
  unreachable

normal:
  %quotient = sdiv i32 %dividend, %divisor
  ret i32 %quotient
}

; A known zero fault plus an unrelated abort must be left entirely unchanged
; when the required signed-overflow guard is absent.
define i32 @missing_overflow_preserves_both(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %zero_fault, label %other_check

other_check:
  %other = icmp eq i32 %dividend, 7
  br i1 %other, label %other_fault, label %normal

zero_fault:
  call void @abort()
  unreachable

other_fault:
  call void @abort()
  unreachable

normal:
  %quotient = sdiv i32 %dividend, %divisor
  ret i32 %quotient
}

; Two divisions make the guard-to-division mapping ambiguous.
define i32 @multiple_divisions(i32 %dividend, i32 %divisor) {
entry:
  %iszero = icmp eq i32 %divisor, 0
  br i1 %iszero, label %fault, label %normal

fault:
  call void @abort()
  unreachable

normal:
  %first = udiv i32 %dividend, %divisor
  %second = udiv i32 %first, %divisor
  ret i32 %second
}

; CHECK-LABEL: define i32 @signed_zero(
; CHECK: fault:
; CHECK-NEXT: call i32 @raise(i32 8)
; CHECK-NEXT: unreachable
; CHECK-LABEL: define i32 @unsigned_zero(
; CHECK: fault:
; CHECK-NEXT: call i32 @raise(i32 8)
; CHECK-NEXT: unreachable
; CHECK-LABEL: define i32 @signed_overflow(
; CHECK: fault:
; CHECK-NEXT: call i32 @raise(i32 8)
; CHECK-NEXT: unreachable
; CHECK-LABEL: define i32 @signed_separate_fault_blocks(
; CHECK: zero_fault:
; CHECK-NEXT: call i32 @raise(i32 8)
; CHECK-NEXT: unreachable
; CHECK: overflow_fault:
; CHECK-NEXT: call i32 @raise(i32 8)
; CHECK-NEXT: unreachable
; CHECK-LABEL: define i64 @lifted_idiv_range_faults(
; CHECK: zero_fault:
; CHECK-NEXT: call i32 @raise(i32 8)
; CHECK-NEXT: unreachable
; CHECK: overflow_fault:
; CHECK-NEXT: call i32 @raise(i32 8)
; CHECK-NEXT: unreachable
; CHECK-LABEL: define void @ordinary_abort(
; CHECK: call void @abort()
; CHECK-NEXT: unreachable
; CHECK-LABEL: define i32 @unrelated_sdiv(
; CHECK: sdiv i32 %left, %right
; CHECK-LABEL: define i32 @malformed_signed_guard(
; CHECK: call void @abort()
; CHECK-NEXT: unreachable
; CHECK-LABEL: define i32 @missing_overflow_preserves_both(
; CHECK: zero_fault:
; CHECK-NEXT: call void @abort()
; CHECK-NEXT: unreachable
; CHECK: other_fault:
; CHECK-NEXT: call void @abort()
; CHECK-NEXT: unreachable
; CHECK-LABEL: define i32 @multiple_divisions(
; CHECK: call void @abort()
; CHECK-NEXT: unreachable
