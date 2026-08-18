; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Test: string literal recovery from rodata segment

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Segment with two null-terminated strings:
;   offset 0x00: "hello\0A\00"  (7 bytes)
;   offset 0x07: "x=%d\0A\00"  (6 bytes)
@seg_402000__rodata = global [13 x i8] c"hello\0A\00x=%d\0A\00"

declare i32 @puts(ptr)
declare i32 @printf(ptr, ...)

; CHECK: @.str.0 = private unnamed_addr constant [7 x i8] c"hello\0A\00"
; CHECK: @.str.1 = private unnamed_addr constant [6 x i8] c"x=%d\0A\00"

; --- Test puts("hello\n") ---
; CHECK-LABEL: define void @test_puts
; CHECK: call i32 @puts(ptr
; CHECK-NOT: @seg_402000__rodata
define void @test_puts() {
entry:
  %ptr = getelementptr [13 x i8], ptr @seg_402000__rodata, i64 0, i64 0
  call i32 @puts(ptr %ptr)
  ret void
}

; --- Test printf("x=%d\n", 42) ---
; CHECK-LABEL: define void @test_printf
; CHECK: call i32 (ptr, ...) @printf(ptr
; CHECK-NOT: @seg_402000__rodata
define void @test_printf() {
entry:
  %ptr = getelementptr [13 x i8], ptr @seg_402000__rodata, i64 0, i64 7
  call i32 (ptr, ...) @printf(ptr %ptr, i32 42)
  ret void
}
