; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge -S < %s | FileCheck %s

; Test: printf vararg recovery with various format specifiers

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]
@.str.xd = private constant [6 x i8] c"x=%d\0A\00"
@.str.sdp = private constant [10 x i8] c"%s %d %p\0A\00"

declare ptr @__remill_function_call(ptr, i64, ptr)
declare i32 @printf(ptr, ...)

; --- Test printf("x=%d\n", x) ---
; CHECK-LABEL: define ptr @sub_4000
; CHECK: call i32 (ptr, ...) @printf(ptr @.str.xd, i32
; CHECK-NOT: @__remill_function_call
define ptr @sub_4000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.str.xd, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store i64 42, ptr %rsi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @printf to i64), ptr %mem)
  ret ptr %ret
}

; --- Test printf("%s %d %p\n", s, n, p) ---
; Requires string arg (RDI=fmt, RSI=s, RDX=n, RCX=p)
; In NativeStrict, RSI must be a native pointer
; CHECK-LABEL: define ptr @sub_5000
; CHECK: call i32 (ptr, ...) @printf(ptr @.str.sdp, ptr @.str.xd, i32
; CHECK-NOT: @__remill_function_call
define ptr @sub_5000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.str.sdp, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store ptr @.str.xd, ptr %rsi.ptr, align 8
  %rdx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2264
  store i64 99, ptr %rdx.ptr, align 8
  %rcx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2248
  store ptr @.str.xd, ptr %rcx.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @printf to i64), ptr %mem)
  ret ptr %ret
}
