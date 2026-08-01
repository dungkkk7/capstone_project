; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; A pointer consumer and an address-identity consumer may refer to the same
; guest object.  Only the pointer use is safe to nativeize: replacing the
; comparison with ptrtoint/native-address semantics makes it ASLR-dependent.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_406000__rodata = constant [6 x i8] c"hello\00"

declare i32 @puts(ptr)

; CHECK: @seg_406000__rodata = constant [6 x i8]
; CHECK: @.str.0 = private unnamed_addr constant [6 x i8] c"hello\00"
; CHECK-LABEL: define i1 @mixed_use
; CHECK: call i32 @puts(ptr @.str.0)
; CHECK: %identity = getelementptr [6 x i8], ptr @seg_406000__rodata, i64 0, i64 0
; CHECK: %same = icmp eq ptr %p, %identity
define i1 @mixed_use(ptr %p) {
entry:
  %buffer = getelementptr [6 x i8], ptr @seg_406000__rodata, i64 0, i64 0
  %ignored = call i32 @puts(ptr %buffer)
  %identity = getelementptr [6 x i8], ptr @seg_406000__rodata, i64 0, i64 0
  %same = icmp eq ptr %p, %identity
  ret i1 %same
}
