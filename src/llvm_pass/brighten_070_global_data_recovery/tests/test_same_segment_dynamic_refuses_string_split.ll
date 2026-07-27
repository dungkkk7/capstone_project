; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s

; An exact string candidate and an unbounded dynamic GEP share the same
; source segment, but no Array/RawBytes recovery rule owns the dynamic range.
; Splitting the string would duplicate guest storage, so retain the one source
; object.  This is deliberately different from the distinct-segment positive.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_408000__rodata = constant [16 x i8] c"ok\00............."

declare i32 @puts(ptr)

; CHECK: @seg_408000__rodata = constant [16 x i8]
; CHECK-NOT: @.str.0 =
define i32 @same_segment_dynamic(i64 %index) {
entry:
  %string = getelementptr [16 x i8], ptr @seg_408000__rodata, i64 0, i64 0
  %printed = call i32 @puts(ptr %string)
  %dynamic = getelementptr i8, ptr @seg_408000__rodata, i64 %index
  %loaded = load i8, ptr %dynamic, align 1
  %extended = zext i8 %loaded to i32
  ret i32 %extended
}

; CHECK-LABEL: define i32 @same_segment_dynamic
; CHECK: call i32 @puts(ptr %string)
; CHECK: getelementptr i8, ptr @seg_408000__rodata, i64 %index
