; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; A dynamic array can lack an alias for element 1 while later consecutive
; element aliases still prove that they are interior entries, not boundaries.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_405000__bss = global [40 x i8] zeroinitializer
@data_405000 = alias i8, getelementptr inbounds ([40 x i8], ptr @seg_405000__bss, i64 0, i64 0)
@data_405008 = alias i8, getelementptr inbounds ([40 x i8], ptr @seg_405000__bss, i64 0, i64 8)
@data_40500c = alias i8, getelementptr inbounds ([40 x i8], ptr @seg_405000__bss, i64 0, i64 12)
@data_405020 = alias i8, getelementptr inbounds ([40 x i8], ptr @seg_405000__bss, i64 0, i64 32)

; CHECK: @g_arr_0 = internal global [8 x [4 x i8]] zeroinitializer
; CHECK-SAME: !brighten.guest.range ![[RANGE:[0-9]+]]
; CHECK-LABEL: define i32 @lookup
; CHECK: getelementptr i8, ptr @g_arr_0, i32 %scaled
; CHECK: ![[RANGE]] = !{i64 4214784, i64 4214816}
define i32 @lookup(i32 %index) {
entry:
  %scaled = mul i32 %index, 4
  %pointer = getelementptr i8, ptr @data_405000, i32 %scaled
  %value = load i32, ptr %pointer, align 4
  ret i32 %value
}
