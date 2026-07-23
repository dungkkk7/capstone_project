; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; A program dynamic GEP without an object candidate remains unsafe to rewrite.
; Its presence must preserve the entire module instead of partially recovering
; an unrelated string object.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @seg_408000__rodata = global
; CHECK: @seg_409000__data = global
; CHECK-NOT: @.str.0 =
@seg_408000__rodata = global [6 x i8] c"hello\00"
@seg_409000__data = global [16 x i8] zeroinitializer

declare i32 @puts(ptr)

define i32 @print_string() {
entry:
  %string = getelementptr [6 x i8], ptr @seg_408000__rodata, i64 0, i64 0
  %result = call i32 @puts(ptr %string)
  ret i32 %result
}

define i8 @load_dynamic(i64 %index) {
entry:
  %ptr = getelementptr i8, ptr @seg_409000__data, i64 %index
  %value = load i8, ptr %ptr
  ret i8 %value
}
