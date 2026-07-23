; RUN: opt -load-pass-plugin=%builddir/BrightenGlobalDataRecoveryPass.so \
; RUN:   -passes=brighten-global-data-recovery-pass -S < %s | FileCheck %s

; A ptrtoint(data_<base>) subtracted from a pointer return and scaled into a
; GEP index is a native pointer difference.  An unrelated arithmetic use of
; the same base remains guest identity.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@seg_405048__rodata = constant [7 x i8] c"AIDUNY\00"
@data_405048 = alias i8, ptr @seg_405048__rodata
@seg_405070__bss = global [32 x i8] zeroinitializer

declare ptr @strchr(ptr, i32)

; CHECK: @seg_405048__rodata = constant [7 x i8] c"AIDUNY\00"
; CHECK: @.str.0 = private unnamed_addr constant [7 x i8] c"AIDUNY\00"
; CHECK-LABEL: define i32 @pointer_difference
; CHECK: %pointer = call ptr @strchr(ptr @.str.0, i32 %character)
; CHECK: %difference = sub i64 %pointer.bits, ptrtoint (ptr @.str.0 to i64)
; CHECK: %slot = getelementptr i8, ptr @g_arr_0, i64 %scaled
define i32 @pointer_difference(i32 %character) {
entry:
  %pointer = call ptr @strchr(ptr @data_405048, i32 %character)
  %pointer.bits = ptrtoint ptr %pointer to i64
  %difference = sub i64 %pointer.bits, ptrtoint (ptr @data_405048 to i64)
  %scaled = mul i64 %difference, 4
  %slot = getelementptr i8, ptr @seg_405070__bss, i64 %scaled
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; CHECK-LABEL: define i32 @opaque_identity
; CHECK: %difference = sub i64 %value, ptrtoint (ptr @data_405048 to i64)
; CHECK: %narrow = trunc i64 %difference to i32
define i32 @opaque_identity(i64 %value) {
entry:
  %difference = sub i64 %value, ptrtoint (ptr @data_405048 to i64)
  %narrow = trunc i64 %difference to i32
  ret i32 %narrow
}
