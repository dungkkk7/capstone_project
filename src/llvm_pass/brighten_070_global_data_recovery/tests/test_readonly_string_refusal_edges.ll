; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s

; Constant-looking strings are not split when a same-interval memory access
; crosses the NUL boundary or has volatile/atomic semantics.  Dynamic overlap
; is covered separately by test_same_segment_dynamic_refuses_string_split.ll;
; relocation/function-pointer preservation by test_relocation_not_integerized.ll.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_404000__rodata = constant [8 x i8] c"%d\00ABCDE"
@seg_405000__rodata = constant [8 x i8] c"%d\00FGHIJ"
@seg_406000__rodata = constant [8 x i8] c"%d\00JKLMN"

declare i32 @printf(ptr, ...)

; CHECK-NOT: @.str.
; CHECK-LABEL: define i64 @crossing_access
; CHECK: call i32 (ptr, ...) @printf(ptr @seg_404000__rodata, i32 1)
; CHECK: load i64, ptr @seg_404000__rodata
define i64 @crossing_access() {
entry:
  %printed = call i32 (ptr, ...) @printf(ptr @seg_404000__rodata, i32 1)
  %wide = load i64, ptr @seg_404000__rodata, align 1
  ret i64 %wide
}

; CHECK-LABEL: define i8 @volatile_access
; CHECK: call i32 (ptr, ...) @printf(ptr @seg_405000__rodata, i32 2)
; CHECK: load volatile i8, ptr @seg_405000__rodata
define i8 @volatile_access() {
entry:
  %printed = call i32 (ptr, ...) @printf(ptr @seg_405000__rodata, i32 2)
  %byte = load volatile i8, ptr @seg_405000__rodata, align 1
  ret i8 %byte
}

; CHECK-LABEL: define i8 @atomic_access
; CHECK: call i32 (ptr, ...) @printf(ptr @seg_406000__rodata, i32 3)
; CHECK: load atomic i8, ptr @seg_406000__rodata seq_cst, align 1
define i8 @atomic_access() {
entry:
  %printed = call i32 (ptr, ...) @printf(ptr @seg_406000__rodata, i32 3)
  %byte = load atomic i8, ptr @seg_406000__rodata seq_cst, align 1
  ret i8 %byte
}
