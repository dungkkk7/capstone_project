; Test: printf("%*.*s") — width and precision stars each consume an int arg

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]
@.str.ws = private constant [6 x i8] c"%*.*s\00"
@.str.data = private constant [4 x i8] c"abc\00"

declare ptr @__remill_function_call(ptr, i64, ptr)
declare i32 @printf(ptr, ...)

; printf("%*.*s", width, precision, str)
; RDI=fmt, RSI=width(int), RDX=prec(int), RCX=str(ptr)
; CHECK-LABEL: define ptr @sub_ws1
; CHECK: call i32 (ptr, ...) @printf(ptr @.str.ws, i32 10, i32 3, ptr @.str.data)
; CHECK-NOT: @__remill_function_call
define ptr @sub_ws1(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.str.ws, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store i64 10, ptr %rsi.ptr, align 8
  %rdx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2264
  store i64 3, ptr %rdx.ptr, align 8
  %rcx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2248
  store ptr @.str.data, ptr %rcx.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @printf to i64), ptr %mem)
  ret ptr %ret
}
