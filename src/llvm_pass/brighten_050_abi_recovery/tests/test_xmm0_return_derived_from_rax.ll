; A floating-point result may be assembled in an integer register value before
; being copied to XMM0.  Its direct data dependency proves that RAX is a bit
; carrier rather than a competing integer return.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer

define ptr @sub_derived_fp(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rax.bits = xor i64 4607182418800017408, -9223372036854775808
  %rax = getelementptr i8, ptr %state, i64 2216
  store i64 %rax.bits, ptr %rax, align 8
  %fp = bitcast i64 %rax.bits to double
  %xmm0 = getelementptr i8, ptr %state, i64 16
  store double %fp, ptr %xmm0, align 8
  ret ptr %memory
}

define void @observe_derived_both() {
entry:
  %memory = call ptr @sub_derived_fp(
      ptr @__mcsema_reg_state, i64 0, ptr null)
  %rax.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2216
  %rax = load i64, ptr %rax.ptr, align 8
  %xmm.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 16
  %xmm = load double, ptr %xmm.ptr, align 8
  call void @consume_i64(i64 %rax)
  call void @consume_double(double %xmm)
  ret void
}

declare void @consume_i64(i64)
declare void @consume_double(double)

; CHECK: define internal double @sub_derived_fp.native
