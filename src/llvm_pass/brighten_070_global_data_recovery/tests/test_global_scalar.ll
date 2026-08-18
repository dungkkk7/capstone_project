; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Test: global scalar recovery from data segment

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Data segment with a 32-bit integer at offset 0 = guest addr 0x404000
; Value: 42 (0x2a000000 in LE = 0x0000002a)
@seg_404000__data = global [8 x i8] c"\2A\00\00\00\00\00\00\00"

; CHECK: @g_scalar_0 = internal global i32

; --- Test load of g_counter ---
; CHECK-LABEL: define i32 @test_load_scalar
; CHECK: load i32, ptr @g_scalar_0
define i32 @test_load_scalar() {
entry:
  %ptr = getelementptr [8 x i8], ptr @seg_404000__data, i64 0, i64 0
  %val = load i32, ptr %ptr
  ret i32 %val
}

; --- Test store to g_counter ---
; CHECK-LABEL: define void @test_store_scalar
; CHECK: store i32 100, ptr @g_scalar_0
define void @test_store_scalar() {
entry:
  %ptr = getelementptr [8 x i8], ptr @seg_404000__data, i64 0, i64 0
  store i32 100, ptr %ptr
  ret void
}
