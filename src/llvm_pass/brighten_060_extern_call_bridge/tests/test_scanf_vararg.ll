; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge -S < %s | FileCheck %s

; Test: scanf vararg recovery - destination pointers must be native

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]
@.str.ds = private constant [6 x i8] c"%d %s\00"

declare ptr @__remill_function_call(ptr, i64, ptr)
declare i32 @scanf(ptr, ...)

; --- Test scanf("%d %s", &x, buf) with native stack objects ---
; CHECK-LABEL: define ptr @sub_6000
; CHECK: call i32 (ptr, ...) @scanf(ptr @.str.ds, ptr captures(none) %x, ptr captures(none) %buf)
; CHECK-NOT: @__remill_function_call
define ptr @sub_6000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %x = alloca i32, align 4
  %buf = alloca [64 x i8], align 1
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.str.ds, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store ptr %x, ptr %rsi.ptr, align 8
  %rdx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2264
  store ptr %buf, ptr %rdx.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @scanf to i64), ptr %mem)
  ret ptr %ret
}
