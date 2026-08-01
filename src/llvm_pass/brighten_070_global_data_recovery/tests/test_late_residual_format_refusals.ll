; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-late-residual-format-string-recovery,verify -S < %s | FileCheck %s

@good = internal constant [4 x i8] c"%d\0A\00", !brighten.guest.range !0
@writable = internal global [4 x i8] c"%d\0A\00", !brighten.guest.range !1
@pointer_field = internal constant <{ ptr, [4 x i8] }> <{ ptr null, [4 x i8] c"%d\0A\00" }>, !brighten.guest.range !2
@malformed = internal constant [4 x i8] c"%d\0A\00", !brighten.guest.range !3
@wide = internal constant [4 x i8] c"%d\0A\00", !brighten.guest.range !4
@slot = internal global ptr @good

declare i32 @printf(ptr, ...)
declare i32 @unknown(ptr)
declare void @callback(ptr)

define i32 @refusals(i64 %index) {
  ; Unknown callee and nonconstant offset must not be touched.
  %u = call i32 @unknown(ptr getelementptr ([4 x i8], ptr @good, i64 0, i64 0))
  %dynamic = getelementptr [4 x i8], ptr @good, i64 0, i64 %index
  %d = call i32 (ptr, ...) @printf(ptr %dynamic)

  ; Writable, pointer-field, malformed metadata, and no-NUL/crossing range.
  %w = call i32 (ptr, ...) @printf(ptr getelementptr ([4 x i8], ptr @writable, i64 0, i64 0))
  %p = call i32 (ptr, ...) @printf(ptr getelementptr (<{ ptr, [4 x i8] }>, ptr @pointer_field, i64 0, i32 0))
  %m = call i32 (ptr, ...) @printf(ptr getelementptr ([4 x i8], ptr @malformed, i64 0, i64 0))
  %widefmt = call i32 (ptr, ...) @printf(ptr getelementptr ([4 x i8], ptr @wide, i64 0, i64 0))
  %cross = call i32 (ptr, ...) @printf(ptr getelementptr ([4 x i8], ptr @good, i64 0, i64 3))

  ; Address observation/capture rejects this otherwise valid format GEP.
  %observed = icmp eq ptr getelementptr ([4 x i8], ptr @good, i64 0, i64 0), null
  call void @callback(ptr getelementptr ([4 x i8], ptr @good, i64 0, i64 0))
  %escaped = call i32 (ptr, ...) @printf(ptr getelementptr ([4 x i8], ptr @good, i64 0, i64 0))

  ; Volatile/atomic-derived values are nonconstant format operands and remain so.
  %v = load volatile ptr, ptr null
  %vol = call i32 (ptr, ...) @printf(ptr %v)
  %a = load atomic ptr, ptr @slot unordered, align 8
  %atom = call i32 (ptr, ...) @printf(ptr %a)
  ret i32 %atom
}

; CHECK-NOT: @.late.residual.str.
; CHECK-DAG: @writable = internal global
; CHECK-DAG: @pointer_field = internal constant
; CHECK: call i32 @unknown(ptr @good)
; CHECK: call i32 (ptr, ...) @printf(ptr %dynamic)
; CHECK: call void @callback(ptr @good)
; CHECK: %v = load volatile ptr, ptr null
; CHECK: %a = load atomic ptr, ptr @slot unordered, align 8

!0 = !{i64 8192, i64 8196}
!1 = !{i64 12288, i64 12292}
!2 = !{i64 16384, i64 16396}
!3 = !{i64 20480}
!4 = !{i128 24576, i128 24580}
