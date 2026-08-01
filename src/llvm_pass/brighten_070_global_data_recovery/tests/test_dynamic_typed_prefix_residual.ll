; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; A typed prefix at the folded dynamic base must not suppress recovery of the
; rest of the writable segment.  The dynamic address is carried through a
; stack slot so it cannot be mistaken for a direct typed-array GEP.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_405000__bss = global [64 x i8] zeroinitializer

define i32 @dynamic_after_typed_prefix(i64 %index) {
entry:
  %carrier = alloca i64, align 8

  %fixed0 = getelementptr [64 x i8], ptr @seg_405000__bss,
      i64 0, i64 0
  store i32 1, ptr %fixed0, align 4
  %fixed1 = getelementptr [64 x i8], ptr @seg_405000__bss,
      i64 0, i64 4
  store i32 2, ptr %fixed1, align 4

  %scaled = mul i64 %index, 4
  %guest_address = add i64 4214784, %scaled
  store i64 %guest_address, ptr %carrier, align 8
  %loaded_address = load i64, ptr %carrier, align 8
  %dynamic_pointer = inttoptr i64 %loaded_address to ptr
  store i32 3, ptr %dynamic_pointer, align 4
  ret i32 0
}

; CHECK: @g_arr_0 = internal global [2 x i32]
; CHECK: @dyn_bytes_405008 = internal global [56 x i8]
; CHECK-SAME: !brighten.guest.range ![[TAIL:[0-9]+]]
; CHECK: ![[TAIL]] = !{i64 4214792, i64 4214848}
