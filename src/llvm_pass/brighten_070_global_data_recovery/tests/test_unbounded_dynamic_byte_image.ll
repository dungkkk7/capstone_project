; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; An unbounded byte index can cross aliases that describe interior fields.
; Preserve the writable machine image rather than nativeizing the GEP to a
; short typed prefix.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_405000__bss = global [64 x i8] zeroinitializer
@data_405000 = alias i8, getelementptr inbounds ([64 x i8], ptr @seg_405000__bss, i64 0, i64 0)
@data_405002 = alias i8, getelementptr inbounds ([64 x i8], ptr @seg_405000__bss, i64 0, i64 2)
@data_405028 = alias i8, getelementptr inbounds ([64 x i8], ptr @seg_405000__bss, i64 0, i64 40)

; CHECK: @dyn_bytes_405000 = internal global [64 x i8] zeroinitializer
; CHECK-SAME: !brighten.guest.range ![[RANGE:[0-9]+]]
; CHECK-LABEL: define i8 @lookup
; CHECK: getelementptr i8, ptr @dyn_bytes_405000, i64 %index
; CHECK: ![[RANGE]] = !{i64 4214784, i64 4214848}
define i8 @lookup(i64 %index) {
entry:
  store i16 0, ptr @data_405000, align 2
  %pointer = getelementptr i8, ptr @data_405000, i64 %index
  %value = load i8, ptr %pointer, align 1
  ret i8 %value
}
