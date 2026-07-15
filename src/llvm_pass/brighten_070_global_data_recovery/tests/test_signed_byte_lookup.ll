; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; A table indexed by sext(i8) has a proven non-negative domain [0, 128).
; Named aliases inside that domain are entries, not object boundaries.  This
; models lookup tables such as tr[input_char], where an ASCII index above the
; first interior symbol must still address the same recovered object.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_405000__data = global [192 x i8] zeroinitializer
@data_405020 = alias i8, getelementptr inbounds ([192 x i8], ptr @seg_405000__data, i64 0, i64 32)
@data_405085 = alias i8, getelementptr inbounds ([192 x i8], ptr @seg_405000__data, i64 0, i64 133)

; CHECK: @dyn_bytes_405020 = internal global [128 x i8]
; CHECK-NOT: @seg_405000__data

define i8 @lookup(i8 %key) {
entry:
  %index = sext i8 %key to i64
  %slot = getelementptr i8, ptr @data_405020, i64 %index
  %value = load i8, ptr %slot, align 1
  ret i8 %value
}

define void @initialize_ascii_n() {
entry:
  %slot = getelementptr i8, ptr @data_405020, i64 110
  store i8 4, ptr %slot, align 1
  ret void
}
