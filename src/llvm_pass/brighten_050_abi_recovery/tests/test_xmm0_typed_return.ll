; An integer-backed State SSA slot can still represent a proven double XMM0
; result.  Caller observation of XMM0 must select the floating-point return
; channel even when scratch RAX state is also present.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer

define ptr @sub_fp(ptr %state, i64 %pc, ptr %memory) {
entry:
  %typed.xmm0 = alloca i64, align 8, !brighten.state.abi_type !0
  store i64 4607182418800017408, ptr %typed.xmm0, align 8
  %bits = load i64, ptr %typed.xmm0, align 8
  %xmm0 = getelementptr i8, ptr %state, i64 16
  store i64 %bits, ptr %xmm0, align 8
  %rax = getelementptr i8, ptr %state, i64 2216
  store i64 99, ptr %rax, align 8
  ret ptr %memory
}

define i32 @main() {
entry:
  %memory = call ptr @sub_fp(ptr @__mcsema_reg_state, i64 0, ptr null)
  %xmm0 = getelementptr i8, ptr @__mcsema_reg_state, i64 16
  %result = load double, ptr %xmm0, align 8
  %exit = fptosi double %result to i32
  ret i32 %exit
}

; CHECK-LABEL: define i32 @main()
; CHECK: call double @sub_fp.native
; CHECK-LABEL: define internal double @sub_fp.native(
; CHECK: ret double

!0 = !{!"double"}
