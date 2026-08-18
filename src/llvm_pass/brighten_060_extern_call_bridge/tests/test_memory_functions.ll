; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge -S < %s | FileCheck %s

; Test: memcpy, memset, memcmp with pointer provenance

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]
@.data = private constant [16 x i8] c"source_data_abc\00"

declare ptr @__remill_function_call(ptr, i64, ptr)
declare ptr @memcpy(ptr, ptr, i64)
declare ptr @memset(ptr, i32, i64)
declare i32 @memcmp(ptr, ptr, i64)

; --- Test memcpy(dst, src, n) ---
; CHECK-LABEL: define ptr @sub_9000
; CHECK: call ptr @memcpy(ptr %dst, ptr @.data, i64 16)
; CHECK-NOT: @__remill_function_call
define ptr @sub_9000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %dst = alloca [64 x i8], align 1
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr %dst, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store ptr @.data, ptr %rsi.ptr, align 8
  %rdx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2264
  store i64 16, ptr %rdx.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @memcpy to i64), ptr %mem)
  ret ptr %ret
}

; --- Test memset(dst, 0, n) ---
; CHECK-LABEL: define ptr @sub_a000
; CHECK: call ptr @memset(ptr %dst2, i32 0, i64 64)
; CHECK-NOT: @__remill_function_call
define ptr @sub_a000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %dst2 = alloca [64 x i8], align 1
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr %dst2, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store i64 0, ptr %rsi.ptr, align 8
  %rdx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2264
  store i64 64, ptr %rdx.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @memset to i64), ptr %mem)
  ret ptr %ret
}

; --- Test memcmp(a, b, n) ---
; CHECK-LABEL: define ptr @sub_b000
; CHECK: call i32 @memcmp(ptr @.data, ptr @.data, i64 4)
; CHECK-NOT: @__remill_function_call
define ptr @sub_b000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.data, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store ptr @.data, ptr %rsi.ptr, align 8
  %rdx.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2264
  store i64 4, ptr %rdx.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @memcmp to i64), ptr %mem)
  ret ptr %ret
}
