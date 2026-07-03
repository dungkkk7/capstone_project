; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge -S < %s | FileCheck %s

; Test: Pattern 3 - ext_ADDR_name stub calls

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]
@.str.test = private constant [5 x i8] c"test\00"

declare ptr @puts(ptr)

; ext_ stub with Remill signature
declare ptr @ext_401030_puts(ptr, i64, ptr)

; --- Test ext_401030_puts ---
; CHECK-LABEL: define ptr @sub_12000
; CHECK: call i32 @puts(ptr @.str.test)
; CHECK-NOT: @ext_401030_puts
define ptr @sub_12000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr @.str.test, ptr %rdi.ptr, align 8
  %ret = call ptr @ext_401030_puts(ptr %state, i64 0, ptr %mem)
  ret ptr %ret
}
