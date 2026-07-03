; Test: FIX #3 — scanf %*d is assignment suppression, does NOT consume a vararg

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]
@.str.sd = private constant [7 x i8] c"%*d %d\00"

declare ptr @__remill_function_call(ptr, i64, ptr)
declare i32 @scanf(ptr, ...)

; scanf("%*d %d", &x) — %*d suppressed, only one pointer arg consumed
; CHECK-LABEL: define ptr @sub_s1
; CHECK: call i32 (ptr, ...) @scanf(ptr @.str.sd, ptr %x)
; CHECK-NOT: @__remill_function_call
define ptr @sub_s1(ptr %state, i64 %pc, ptr %mem) {
entry:
  %x = alloca i32, align 4
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.str.sd, ptr %rdi.ptr, align 8
  ; RSI = &x (only one vararg: the %d after %*d)
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store ptr %x, ptr %rsi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @scanf to i64), ptr %mem)
  ret ptr %ret
}
