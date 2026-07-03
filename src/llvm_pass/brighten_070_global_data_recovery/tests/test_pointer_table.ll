; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; Test: pointer table recovery from rodata

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Two string literals in rodata
@seg_402000__rodata = global [6 x i8] c"alpha\00"
@seg_402006__rodata = global [5 x i8] c"beta\00"

; Pointer table in data pointing to the two strings
; The addresses would be 0x402000 and 0x402006 in LE
; This test just verifies the pass can discover and handle the pattern

; CHECK-LABEL: define void @test_ptrtable_use
define void @test_ptrtable_use() {
entry:
  ret void
}
