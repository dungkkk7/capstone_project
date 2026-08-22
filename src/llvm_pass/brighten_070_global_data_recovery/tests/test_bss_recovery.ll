; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Test: BSS segment recovery (zero-initialized globals)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; BSS segment: 256-byte buffer at guest addr 0x406000
@seg_406000__bss = global [256 x i8] zeroinitializer

; CHECK: @g_scalar_0 = internal global i32

; --- Test store + load from bss ---
; CHECK-LABEL: define i32 @test_bss_rw
define i32 @test_bss_rw() {
entry:
  %ptr = getelementptr [256 x i8], ptr @seg_406000__bss, i64 0, i64 0
  store i32 99, ptr %ptr
  %val = load i32, ptr %ptr
  ret i32 %val
}
