; RUN: opt -load-pass-plugin %builddir/BrightenNativeCleanupPass.so -passes=brighten-native-cleanup-pass,verify -S < %s | FileCheck %s
;
; A pointer stored in a preserved residual image is still a guest virtual
; address when loaded.  The direct inttoptr must become the same guarded
; recovered-data mapping used for other dynamic guest addresses.  An identical
; integer from an unrelated global is intentionally not matched.

@native_residual_1000__data = internal global { [16 x i8], i64 }
    { [16 x i8] zeroinitializer, i64 4112 }, !brighten.guest.range !0
@native_residual_1000__oob = internal global i64 9000,
    !brighten.guest.range !0
@unrelated_integer = internal global i64 4112
@volatile_integer = internal global i64 4112
@atomic_integer = internal global i64 4112

define i8 @positive(i1 %choose) {
entry:
  %slot = getelementptr i8, ptr @native_residual_1000__data, i64 16
  %guest = load i64, ptr %slot, align 8
  %ptr = inttoptr i64 %guest to ptr
  %value = load i8, ptr %ptr, align 1
  %next = add i64 %guest, 1
  %next.ptr = inttoptr i64 %next to ptr
  %next.value = load i8, ptr %next.ptr, align 1
  br i1 %choose, label %use.base, label %use.next

use.base:
  br label %join

use.next:
  br label %join

join:
  %cursor = phi i64 [ %guest, %use.base ], [ %next, %use.next ]
  %cursor.ptr = inttoptr i64 %cursor to ptr
  %cursor.value = load i8, ptr %cursor.ptr, align 1
  %result = add i8 %value, %cursor.value
  ret i8 %result
}

define ptr @negative_unrelated() {
entry:
  %integer = load i64, ptr @unrelated_integer, align 8
  %ptr = inttoptr i64 %integer to ptr
  ret ptr %ptr
}

define ptr @negative_volatile() {
entry:
  %integer = load volatile i64, ptr @volatile_integer, align 8
  %ptr = inttoptr i64 %integer to ptr
  ret ptr %ptr
}

define ptr @negative_atomic() {
entry:
  %integer = load atomic i64, ptr @atomic_integer seq_cst, align 8
  %ptr = inttoptr i64 %integer to ptr
  ret ptr %ptr
}

define ptr @negative_select_tag(i1 %choose) {
entry:
  %slot = getelementptr i8, ptr @native_residual_1000__data, i64 16
  %guest = load i64, ptr %slot, align 8
  %tagged = select i1 %choose, i64 %guest, i64 9223372036854775808
  %ptr = inttoptr i64 %tagged to ptr
  ret ptr %ptr
}

define ptr @out_of_range_fallback() {
entry:
  %integer = load i64, ptr @native_residual_1000__oob, align 8
  %ptr = inttoptr i64 %integer to ptr
  ret ptr %ptr
}

; CHECK-LABEL: define i8 @positive(i1 %choose)
; CHECK: icmp uge i64 %guest, 4096
; CHECK: getelementptr i8, ptr @native_residual_1000__data
; CHECK-NOT: %ptr = inttoptr i64 %guest to ptr
; CHECK-NOT: %next.ptr = inttoptr i64 %next to ptr
; CHECK-NOT: %cursor.ptr = inttoptr i64 %cursor to ptr
; CHECK-LABEL: define ptr @negative_unrelated()
; CHECK: %ptr = inttoptr i64 %integer to ptr
; CHECK-LABEL: define ptr @negative_volatile()
; CHECK: %ptr = inttoptr i64 %integer to ptr
; CHECK-LABEL: define ptr @negative_atomic()
; CHECK: %ptr = inttoptr i64 %integer to ptr
; CHECK-LABEL: define ptr @negative_select_tag(i1 %choose)
; CHECK: %ptr = inttoptr i64 %tagged to ptr
; CHECK-LABEL: define ptr @out_of_range_fallback()
; CHECK: %native.address.fallback = inttoptr i64 %integer to ptr
; CHECK: %native.data.pointer.select = select i1

!0 = !{i64 4096, i64 4160}
