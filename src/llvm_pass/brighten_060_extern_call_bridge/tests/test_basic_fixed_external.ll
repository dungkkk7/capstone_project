; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge -S < %s | FileCheck %s

; Test: basic fixed-arg external calls (puts, strlen, strcmp)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]
@.str.hello = private constant [6 x i8] c"hello\00"
@.str.abc = private constant [4 x i8] c"abc\00"
@.str.def = private constant [4 x i8] c"def\00"

declare ptr @__remill_function_call(ptr, i64, ptr)
declare ptr @puts(ptr)
declare i64 @strlen(ptr)
declare i32 @strcmp(ptr, ptr)

; --- Test puts("hello") ---
; CHECK-LABEL: define ptr @sub_1000
; CHECK: call i32 @puts(ptr @.str.hello)
; CHECK-NOT: @__remill_function_call
define ptr @sub_1000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.str.hello, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @puts to i64), ptr %mem)
  ret ptr %ret
}

; --- Test strlen("abc") ---
; CHECK-LABEL: define ptr @sub_2000
; CHECK: call i64 @strlen(ptr @.str.abc)
; CHECK-NOT: @__remill_function_call
define ptr @sub_2000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.str.abc, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @strlen to i64), ptr %mem)
  ret ptr %ret
}

; --- Test strcmp("abc", "def") ---
; CHECK-LABEL: define ptr @sub_3000
; CHECK: call i32 @strcmp(ptr @.str.abc, ptr @.str.def)
; CHECK-NOT: @__remill_function_call
define ptr @sub_3000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.str.abc, ptr %rdi.ptr, align 8
  %rsi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2280
  store ptr @.str.def, ptr %rsi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @strcmp to i64), ptr %mem)
  ret ptr %ret
}
