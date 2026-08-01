; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s

; One merged image contains both an exact readonly string and a dynamic access
; whose range is not bounded.  The dynamic load can read the byte just stored
; through the extracted prefix, so splitting would create two non-aliasing
; LLVM globals for one guest storage range.  070 must retain one source object
; and refuse the otherwise-valid string candidate.  A full-range raw backing
; is allowed because both paths are rewritten to that same one storage.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_408000__rodata = global [16 x i8] c"ok\00............."

declare i32 @puts(ptr)

; CHECK: @dyn_bytes_408000 = internal global [16 x i8]
; CHECK-NOT: @.str.0 =
define i32 @mixed_blob(i64 %index) {
entry:
  store i8 42, ptr @seg_408000__rodata, align 1
  %dynamic = getelementptr i8, ptr @seg_408000__rodata, i64 %index
  %loaded = load i8, ptr %dynamic, align 1
  %extended = zext i8 %loaded to i32
  ret i32 %extended
}

; CHECK-LABEL: define i32 @mixed_blob
; CHECK: store i8 42, ptr @dyn_bytes_408000
; CHECK: getelementptr i8, ptr @dyn_bytes_408000, i64 %index
