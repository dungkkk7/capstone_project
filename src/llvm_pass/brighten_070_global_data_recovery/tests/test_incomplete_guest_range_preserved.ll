; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; A guest address outside every recovered range has no object provenance.
; Recovery may still materialize a separately proven object, but it must leave
; this unknown pointer carrier untouched rather than guessing an object/type.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; The only recovered range is [0x408000, 0x408003).
@seg_408000__rodata = global [3 x i8] c"ok\00"

declare i32 @puts(ptr)

; Positive control: a fully covered constant address is recovered normally.
; CHECK: @.str.0 = private unnamed_addr constant [3 x i8] c"ok\00"
; CHECK-LABEL: define i32 @read_known
; CHECK: call i32 @puts(ptr
define i32 @read_known() {
entry:
  %ptr = getelementptr [3 x i8], ptr @seg_408000__rodata, i64 0, i64 0
  %value = call i32 @puts(ptr %ptr)
  ret i32 %value
}

; Negative case: 0x409010 lies outside the complete recovered range.  The
; dynamic address remains unresolved, including its volatile alias boundary.
; CHECK-LABEL: define i8 @read_incomplete_range
; CHECK: %guest.address = add i64 4231184, %offset
; CHECK: %guest.pointer = inttoptr i64 %guest.address to ptr
; CHECK: load volatile i8, ptr %guest.pointer
define i8 @read_incomplete_range(i64 %offset) {
entry:
  %guest.address = add i64 4231184, %offset
  %guest.pointer = inttoptr i64 %guest.address to ptr
  %value = load volatile i8, ptr %guest.pointer, align 1
  ret i8 %value
}
