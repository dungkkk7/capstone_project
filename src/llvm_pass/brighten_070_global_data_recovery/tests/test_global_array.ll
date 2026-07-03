; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Test: global array recovery from data segment

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Data segment with int arr[3] = {1, 2, 3} at guest addr 0x405000
; LE bytes: 01000000 02000000 03000000
@seg_405000__data = global [12 x i8] c"\01\00\00\00\02\00\00\00\03\00\00\00"

; CHECK: @g_arr_0 = internal global [3 x i32]

; --- Test load arr[0] ---
; CHECK-LABEL: define i32 @test_load_arr0
; CHECK: load i32, ptr
define i32 @test_load_arr0() {
entry:
  %ptr = getelementptr [12 x i8], ptr @seg_405000__data, i64 0, i64 0
  %val = load i32, ptr %ptr
  ret i32 %val
}

; --- Test load arr[1] ---
; CHECK-LABEL: define i32 @test_load_arr1
; CHECK: load i32, ptr
define i32 @test_load_arr1() {
entry:
  %ptr = getelementptr [12 x i8], ptr @seg_405000__data, i64 0, i64 4
  %val = load i32, ptr %ptr
  ret i32 %val
}

; --- Test load arr[2] ---
; CHECK-LABEL: define i32 @test_load_arr2
; CHECK: load i32, ptr
define i32 @test_load_arr2() {
entry:
  %ptr = getelementptr [12 x i8], ptr @seg_405000__data, i64 0, i64 8
  %val = load i32, ptr %ptr
  ret i32 %val
}
