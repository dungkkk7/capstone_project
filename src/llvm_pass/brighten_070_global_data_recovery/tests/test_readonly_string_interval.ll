; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass,verify -S < %s | FileCheck %s

; A printable NUL interval may be extracted from a larger readonly image only
; when the string reference is exact.  The identity-observing carrier keeps
; unrelated image bytes live, proving that this is not whole-blob relabeling.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_403000__rodata = constant [16 x i8] c"\01\02\03\04%d\00\AA\BB\CC\DD\EE\FF\10\11\12"

declare i32 @printf(ptr, ...)

; CHECK: @seg_403000__rodata = constant [16 x i8]
; CHECK: @.str.0 = private unnamed_addr constant [3 x i8] c"%d\00"
; CHECK-LABEL: define i64 @exact_format_interval
; CHECK: call i32 (ptr, ...) @printf(ptr @.str.0, i32 7)
; CHECK: icmp eq i64
define i64 @exact_format_interval() {
entry:
  %format = getelementptr [16 x i8], ptr @seg_403000__rodata, i64 0, i64 4
  %printed = call i32 (ptr, ...) @printf(ptr %format, i32 7)
  ; Numeric observation of an unrelated address must retain the mixed source
  ; image rather than making the extracted string a replacement for it.
  %base = ptrtoint ptr @seg_403000__rodata to i64
  %same = icmp eq i64 %base, 4206592
  %result = zext i1 %same to i64
  ret i64 %result
}
