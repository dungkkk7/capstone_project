; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Recovered scalar/array values follow the module DataLayout rather than the
; host running opt.

target datalayout = "E-m:e-p:64:64-i64:64-n32:64-S128"
target triple = "powerpc64-unknown-linux-gnu"

@seg_405000__data = global [8 x i8] c"\01\02\03\04\05\06\07\08"

; CHECK: @g_arr_0 = internal global [2 x i32] [i32 16909060, i32 84281096]
; CHECK-NOT: @seg_405000__data
define i32 @sum() {
entry:
  %p0 = getelementptr [8 x i8], ptr @seg_405000__data, i64 0, i64 0
  %v0 = load i32, ptr %p0, align 4
  %p4 = getelementptr [8 x i8], ptr @seg_405000__data, i64 0, i64 4
  %v4 = load i32, ptr %p4, align 4
  %r = add i32 %v0, %v4
  ret i32 %r
}
