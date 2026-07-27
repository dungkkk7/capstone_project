; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s

; A constant-width load at a relocation field is not evidence for an integer
; global.  The address-sized bytes carry native pointer provenance.  Either
; the pointer-table rule owns the whole range as ptr fields or 070 leaves the
; original segment residual; it must never emit [N x i64] ptrtoint(...).

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @target0()
declare void @target1()

@seg_405000__data = global { ptr, ptr } { ptr @target0, ptr @target1 }

; CHECK-NOT: ptrtoint (ptr @target0 to i64)
; CHECK-NOT: ptrtoint (ptr @target1 to i64)
; CHECK: @g_ptrtable_0 = internal global [2 x ptr] [ptr @target0, ptr @target1]
; CHECK-LABEL: define i64 @read_pointer_bits
; CHECK: load i64, ptr @g_ptrtable_0
define i64 @read_pointer_bits() {
entry:
  %first = getelementptr { ptr, ptr }, ptr @seg_405000__data, i64 0, i32 0
  %bits = load i64, ptr %first, align 8
  ret i64 %bits
}
