; Test: FIX #7 — exit(1) should produce valid CFG with unreachable

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]

declare ptr @__remill_function_call(ptr, i64, ptr)
declare void @exit(i32)

; CHECK-LABEL: define ptr @sub_exit1
; CHECK: call void @exit(i32 1)
; CHECK-NEXT: unreachable
; CHECK-NOT: ret ptr
define ptr @sub_exit1(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store i64 1, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @exit to i64), ptr %mem)
  ret ptr %ret
}

; A live dependency in the noreturn tail must make the rewrite preserve the
; original State-ABI call; the pass must not RAUW the dependency with null.
; CHECK-LABEL: define ptr @sub_exit_live_tail
; CHECK: call ptr @__remill_function_call
; CHECK-NOT: call void @exit
define ptr @sub_exit_live_tail(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store i64 1, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @exit to i64), ptr %mem)
  %tail_value = add i64 1, 2
  %tail_use = add i64 %tail_value, 3
  ret ptr %ret
}
