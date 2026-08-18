; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge -S < %s | FileCheck %s

; Test: malloc/free recovery with return value in RAX

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]

declare ptr @__remill_function_call(ptr, i64, ptr)
declare ptr @malloc(i64)
declare void @free(ptr)

; --- Test p = malloc(n) ---
; CHECK-LABEL: define ptr @sub_c000
; CHECK: %malloc.ret = call ptr @malloc(i64 256)
; CHECK: store {{.*}}, ptr %rax.ptr
; CHECK-NOT: @__remill_function_call
define ptr @sub_c000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store i64 256, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @malloc to i64), ptr %mem)
  ; Read RAX after call
  %rax.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2216
  %rax.val = load i64, ptr %rax.ptr, align 8
  ret ptr %ret
}

; --- Test free(p) ---
; free takes a pointer. In NativeStrict, p must be native.
; Since the arg comes from malloc return (heap object), it should work.
; CHECK-LABEL: define ptr @sub_d000
; CHECK: call void @free(ptr %heapptr)
; CHECK-NOT: @__remill_function_call
define ptr @sub_d000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %heapptr = call ptr @malloc(i64 128)
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store ptr %heapptr, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @free to i64), ptr %mem)
  ret ptr %ret
}
