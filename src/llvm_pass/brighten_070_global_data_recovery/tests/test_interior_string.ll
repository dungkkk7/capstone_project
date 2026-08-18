; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Test: interior string pointer recovery

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; String "abcdef\00" at guest addr 0x408000
@seg_408000__rodata = global [7 x i8] c"abcdef\00"

declare i32 @puts(ptr)

; CHECK: @.str.0 = private unnamed_addr constant [7 x i8] c"abcdef\00"

; --- Test puts("abcdef" + 2) = puts("cdef") ---
; CHECK-LABEL: define void @test_interior_ptr
; CHECK: getelementptr
; CHECK: call i32 @puts
define void @test_interior_ptr() {
entry:
  %ptr = getelementptr [7 x i8], ptr @seg_408000__rodata, i64 0, i64 2
  call i32 @puts(ptr %ptr)
  ret void
}
