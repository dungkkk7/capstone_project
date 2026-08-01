; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; A prior pass folded and DCE'd the data_40400a/data_40400d aliases.  Preserve
; string provenance from the read-only guest range and native pointer use.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_404000__rodata = internal constant [16 x i8] c"\01\00\02\00%d\00%s\00NG\00OK\00"
@__mcsema_reg_state = internal global [2400 x i8] zeroinitializer

declare ptr @ext_4060d0_puts(ptr, i64, ptr)
declare void @llvm.sideeffect()

; CHECK: @.str.{{[0-9]+}} = private unnamed_addr constant [3 x i8] c"NG\00"
; CHECK: @.str.{{[0-9]+}} = private unnamed_addr constant [3 x i8] c"OK\00"
; CHECK-LABEL: define void @folded_string_select
; CHECK: select i1 %ok, i64 ptrtoint (ptr @.str.{{[0-9]+}} to i64), i64 ptrtoint (ptr @.str.{{[0-9]+}} to i64)
; CHECK: call ptr @ext_4060d0_puts
define void @folded_string_select(i1 %ok) {
entry:
  %guest = select i1 %ok, i64 4210698, i64 4210701
  store i64 %guest, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2296)
  ; Lifted wrappers flush the rest of the register state before the external
  ; call.  Keep this beyond the old 50-instruction lookahead limit.
  call void @llvm.sideeffect() ; 1
  call void @llvm.sideeffect() ; 2
  call void @llvm.sideeffect() ; 3
  call void @llvm.sideeffect() ; 4
  call void @llvm.sideeffect() ; 5
  call void @llvm.sideeffect() ; 6
  call void @llvm.sideeffect() ; 7
  call void @llvm.sideeffect() ; 8
  call void @llvm.sideeffect() ; 9
  call void @llvm.sideeffect() ; 10
  call void @llvm.sideeffect() ; 11
  call void @llvm.sideeffect() ; 12
  call void @llvm.sideeffect() ; 13
  call void @llvm.sideeffect() ; 14
  call void @llvm.sideeffect() ; 15
  call void @llvm.sideeffect() ; 16
  call void @llvm.sideeffect() ; 17
  call void @llvm.sideeffect() ; 18
  call void @llvm.sideeffect() ; 19
  call void @llvm.sideeffect() ; 20
  call void @llvm.sideeffect() ; 21
  call void @llvm.sideeffect() ; 22
  call void @llvm.sideeffect() ; 23
  call void @llvm.sideeffect() ; 24
  call void @llvm.sideeffect() ; 25
  call void @llvm.sideeffect() ; 26
  call void @llvm.sideeffect() ; 27
  call void @llvm.sideeffect() ; 28
  call void @llvm.sideeffect() ; 29
  call void @llvm.sideeffect() ; 30
  call void @llvm.sideeffect() ; 31
  call void @llvm.sideeffect() ; 32
  call void @llvm.sideeffect() ; 33
  call void @llvm.sideeffect() ; 34
  call void @llvm.sideeffect() ; 35
  call void @llvm.sideeffect() ; 36
  call void @llvm.sideeffect() ; 37
  call void @llvm.sideeffect() ; 38
  call void @llvm.sideeffect() ; 39
  call void @llvm.sideeffect() ; 40
  call void @llvm.sideeffect() ; 41
  call void @llvm.sideeffect() ; 42
  call void @llvm.sideeffect() ; 43
  call void @llvm.sideeffect() ; 44
  call void @llvm.sideeffect() ; 45
  call void @llvm.sideeffect() ; 46
  call void @llvm.sideeffect() ; 47
  call void @llvm.sideeffect() ; 48
  call void @llvm.sideeffect() ; 49
  call void @llvm.sideeffect() ; 50
  call void @llvm.sideeffect() ; 51
  call void @llvm.sideeffect() ; 52
  call void @llvm.sideeffect() ; 53
  call void @llvm.sideeffect() ; 54
  call void @llvm.sideeffect() ; 55
  call void @llvm.sideeffect() ; 56
  call void @llvm.sideeffect() ; 57
  call void @llvm.sideeffect() ; 58
  call void @llvm.sideeffect() ; 59
  call void @llvm.sideeffect() ; 60
  call void @llvm.sideeffect() ; 61
  call void @llvm.sideeffect() ; 62
  call void @llvm.sideeffect() ; 63
  call void @llvm.sideeffect() ; 64
  call ptr @ext_4060d0_puts(ptr @__mcsema_reg_state, i64 0, ptr null)
  ret void
}

; A malformed/non-address wide integer must be ignored instead of reaching
; APInt::getZExtValue(), which asserts for values wider than 64 bits.
define i128 @wide_integer_is_not_an_address(i1 %pick) {
entry:
  %wide = select i1 %pick, i128 1267650600228229401496703205376, i128 0
  ret i128 %wide
}
