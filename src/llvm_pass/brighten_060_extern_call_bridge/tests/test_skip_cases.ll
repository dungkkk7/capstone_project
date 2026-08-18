; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge -S < %s | FileCheck %s

; Test: cases that must be preserved (not rewritten) with skip reasons

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__mcsema_reg_state = external global [3072 x i8]

declare ptr @__remill_function_call(ptr, i64, ptr)
declare i32 @printf(ptr, ...)
declare i32 @puts(ptr)

; --- Skip: dynamic unresolved target ---
; CHECK-LABEL: define ptr @sub_e000
; CHECK: call ptr @__remill_function_call
define ptr @sub_e000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %dynpc = add i64 %pc, 100
  %ret = call ptr @__remill_function_call(ptr %state, i64 %dynpc, ptr %mem)
  ret ptr %ret
}

; --- Skip: unknown format string ---
; (format in a register, not a constant)
; CHECK-LABEL: define ptr @sub_f000
; CHECK: call ptr @__remill_function_call
define ptr @sub_f000(ptr %state, i64 %pc, ptr %mem) {
entry:
  ; RDI = dynamic pointer (not a known global string)
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  %dynfmt = inttoptr i64 12345678 to ptr
  store ptr %dynfmt, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @printf to i64), ptr %mem)
  ret ptr %ret
}

; --- Skip: unknown pointer provenance for puts ---
; CHECK-LABEL: define ptr @sub_10000
; CHECK: call ptr @__remill_function_call
define ptr @sub_10000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  %unknown = inttoptr i64 48879 to ptr
  store ptr %unknown, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @puts to i64), ptr %mem)
  ret ptr %ret
}

; --- Skip: call result used as non-memory value ---
; CHECK-LABEL: define i64 @sub_11000
; CHECK: call ptr @__remill_function_call
define i64 @sub_11000(ptr %state, i64 %pc, ptr %mem) {
entry:
  %rdi.ptr = getelementptr i8, ptr @__mcsema_reg_state, i64 2296
  store i64 256, ptr %rdi.ptr, align 8
  %ret = call ptr @__remill_function_call(ptr %state, i64 ptrtoint(ptr @puts to i64), ptr %mem)
  ; Use the return value as an integer, not as memory token
  %asint = ptrtoint ptr %ret to i64
  %result = add i64 %asint, 1
  ret i64 %result
}
