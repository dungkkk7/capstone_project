; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Test: array candidate with constant boundary references and dynamic indexing

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Data segment with int arr[3] = {1, 2, 3} at guest addr 0x405000
@seg_405000__data = global [12 x i8] c"\01\00\00\00\02\00\00\00\03\00\00\00"

; CHECK: @g_arr_0 = internal global [3 x i32]

; --- Test load arr[idx] with dynamic GEP ---
; CHECK-LABEL: define i32 @test_load_dynamic
define i32 @test_load_dynamic(i64 %idx) {
entry:
  %ptr = getelementptr [12 x i8], ptr @seg_405000__data, i64 0, i64 %idx
  %val = load i32, ptr %ptr
  ret i32 %val
}

; Constant accesses that define the array candidate boundary + indexed GEP flag
define i32 @test_defines(i64 %idx) {
entry:
  %ptr0 = getelementptr [12 x i8], ptr @seg_405000__data, i64 0, i64 0
  %v0 = load i32, ptr %ptr0
  %ptr1 = getelementptr [12 x i8], ptr @seg_405000__data, i64 0, i64 4
  %v1 = load i32, ptr %ptr1
  %ptr2 = getelementptr [12 x i8], ptr @seg_405000__data, i64 0, i64 8
  %v2 = load i32, ptr %ptr2
  %sum = add i32 %v0, %v1
  %total = add i32 %sum, %v2
  ret i32 %total
}
