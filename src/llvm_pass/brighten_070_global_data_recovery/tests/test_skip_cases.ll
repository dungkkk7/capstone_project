; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Test: cases that should be preserved (not recovered)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Segment without parseable base address - should be preserved
; CHECK: @seg_unknown_section = global
@seg_unknown_section = global [16 x i8] c"some random data"

; Dynamic address use - should be preserved
@seg_407000__rodata = global [32 x i8] c"data that is not a clean string!"

; CHECK-LABEL: define i64 @test_dynamic_addr
; Arithmetic on guest address - should not be rewritten in NativeStrict
define i64 @test_dynamic_addr(i64 %offset) {
entry:
  %base = ptrtoint ptr @seg_407000__rodata to i64
  %addr = add i64 %base, %offset
  ret i64 %addr
}

; CHECK-LABEL: define i1 @test_addr_comparison
; Address identity comparison - should be preserved
define i1 @test_addr_comparison(ptr %p) {
entry:
  %seg_ptr = getelementptr [32 x i8], ptr @seg_407000__rodata, i64 0, i64 0
  %cmp = icmp eq ptr %p, %seg_ptr
  ret i1 %cmp
}

; Mutable write into rodata candidate - should skip
; CHECK-LABEL: define void @test_mutable_rodata
define void @test_mutable_rodata() {
entry:
  %ptr = getelementptr [32 x i8], ptr @seg_407000__rodata, i64 0, i64 0
  store i8 65, ptr %ptr
  ret void
}
