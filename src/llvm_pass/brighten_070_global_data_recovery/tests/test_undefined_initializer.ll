; RUN: env BRIGHTEN_GLOBAL_AUDIT_ONLY=1 opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Undefined bytes are not evidence for a zero initializer.  Preserve the
; unresolved source object so strict cleanup can diagnose it; never synthesize
; a concrete recovered zero global.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @seg_408000__data = global [4 x i8] undef
; CHECK-NOT: @g_scalar_
@seg_408000__data = global [4 x i8] undef

define i32 @read_unresolved() {
entry:
  %p = getelementptr [4 x i8], ptr @seg_408000__data, i64 0, i64 0
  %v = load i32, ptr %p, align 4
  ret i32 %v
}
