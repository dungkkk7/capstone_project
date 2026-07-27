; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s

; Direct i32 accesses at residual+4144 have one exact writable interval.
; The large BSS source must remain for every other guest address.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_405000__bss = global [8192 x i8] zeroinitializer, align 4096

; CHECK: @seg_405000__bss = global [8192 x i8] zeroinitializer, align 4096
; CHECK: @g_scalar_0 = internal global i32 0, align 16
; CHECK-LABEL: define i32 @rw_fixed_scalar
; CHECK: store i32 %value, ptr @g_scalar_0
; CHECK: load i32, ptr @g_scalar_0
define i32 @rw_fixed_scalar(i32 %value) {
entry:
  %slot = getelementptr [8192 x i8], ptr @seg_405000__bss, i64 0, i64 4144
  store i32 %value, ptr %slot, align 4
  %loaded = load i32, ptr %slot, align 4
  ret i32 %loaded
}
