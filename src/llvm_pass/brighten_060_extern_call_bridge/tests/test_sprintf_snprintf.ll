; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge -S < %s | FileCheck %s

; Test: sprintf/snprintf with write pointer provenance check

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]
@.str.d = private constant [3 x i8] c"%d\00"
@.str.s = private constant [3 x i8] c"%s\00"

declare ptr @__remill_function_call(ptr, i64, ptr)
declare i32 @sprintf(ptr, ptr, ...)
declare i32 @snprintf(ptr, i64, ptr, ...)

; --- Test sprintf(buf, "%d", x) ---
; CHECK-LABEL: define ptr @sub_7000
; CHECK: call i32 (ptr, ptr, ...) @sprintf(ptr %buf, ptr @.str.d, i32
; CHECK-NOT: @__remill_function_call
define ptr @sub_7000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %buf = alloca [128 x i8], align 1
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr %buf, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store ptr @.str.d, ptr %rsi.ptr, align 8
  %rdx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2264
  store i64 123, ptr %rdx.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @sprintf to i64), ptr %mem)
  ret ptr %ret
}

; --- Test snprintf(buf, 32, "%s", s) ---
; CHECK-LABEL: define ptr @sub_8000
; CHECK: call i32 (ptr, i64, ptr, ...) @snprintf(ptr %buf2, i64 32, ptr @.str.s, ptr @.str.d)
; CHECK-NOT: @__remill_function_call
define ptr @sub_8000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %buf2 = alloca [128 x i8], align 1
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr %buf2, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store i64 32, ptr %rsi.ptr, align 8
  %rdx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2264
  store ptr @.str.s, ptr %rdx.ptr, align 8
  %rcx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2248
  store ptr @.str.d, ptr %rcx.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @snprintf to i64), ptr %mem)
  ret ptr %ret
}
