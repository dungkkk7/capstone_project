; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; A dynamic GEP inside the generated guest-pointer translator is not a program
; data consumer.  An uncovered segment base there must not cancel recovery of
; independently discovered objects.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_408000__rodata = global [4 x i8] c"\01\00\02\00"
@seg_409000__rodata = global [6 x i8] c"hello\00"

declare i32 @printf(ptr, ...)

; CHECK: @.str.0 = private unnamed_addr constant [6 x i8] c"hello\00"

define internal ptr @__translate_guest_pointer(i64 %addr, i1 %is_write) {
entry:
  %offset = sub i64 %addr, 4227072
  %ptr = getelementptr i8, ptr @seg_408000__rodata, i64 %offset
  ret ptr %ptr
}

define i32 @print_string(ptr %value) {
entry:
  %format = getelementptr [6 x i8], ptr @seg_409000__rodata, i64 0, i64 0
  %result = call i32 (ptr, ...) @printf(ptr %format, ptr %value)
  ret i32 %result
}
