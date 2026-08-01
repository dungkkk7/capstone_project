; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s

; No typed split when the same residual bytes have incompatible widths,
; relocation/function provenance, observed address identity, or atomic access.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @target()

@seg_405000__bss = global [32 x i8] zeroinitializer
@seg_406000__data = global { ptr, [8 x i8] } { ptr @target, [8 x i8] zeroinitializer }
@seg_407000__bss = global [16 x i8] zeroinitializer
@seg_408000__bss = global [16 x i8] zeroinitializer

; CHECK-NOT: @g_scalar_
; CHECK-LABEL: define i32 @overlap_width
; CHECK: load i64, ptr @seg_405000__bss
; CHECK: load i32, ptr %middle
define i32 @overlap_width() {
entry:
  %whole = load i64, ptr @seg_405000__bss, align 1
  %middle = getelementptr [32 x i8], ptr @seg_405000__bss, i64 0, i64 2
  %part = load i32, ptr %middle, align 1
  %trunc = trunc i64 %whole to i32
  %sum = add i32 %trunc, %part
  ret i32 %sum
}

; CHECK-LABEL: define i64 @relocation_bits
; CHECK: load i64, ptr @seg_406000__data
define i64 @relocation_bits() {
entry:
  %bits = load i64, ptr @seg_406000__data, align 8
  ret i64 %bits
}

; CHECK-LABEL: define i1 @address_observed
; CHECK: ptrtoint ptr %p to i64
define i1 @address_observed() {
entry:
  %p = getelementptr [16 x i8], ptr @seg_407000__bss, i64 0, i64 8
  %v = load i32, ptr %p, align 1
  %addr = ptrtoint ptr %p to i64
  %same = icmp eq i64 %addr, 4222984
  %nonzero = icmp ne i32 %v, 0
  %both = and i1 %same, %nonzero
  ret i1 %both
}

; CHECK-LABEL: define i32 @atomic_fixed
; CHECK: load atomic i32, ptr %p seq_cst
define i32 @atomic_fixed() {
entry:
  %p = getelementptr [16 x i8], ptr @seg_408000__bss, i64 0, i64 4
  %v = load atomic i32, ptr %p seq_cst, align 4
  ret i32 %v
}
