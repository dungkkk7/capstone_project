; RUN: opt-21 -load-pass-plugin=%S/../build/BrightenNativeCleanupPass.so \
; RUN:   -passes=brighten-native-cleanup-pass -S %s -o - | FileCheck %s

@g_scalar_1 = internal global i32 5, align 4
@g_arr_2 = internal global [100 x [4 x i8]] zeroinitializer, align 1, !brighten.guest.range !0

define i8 @main(i64 %index) {
entry:
  %p = getelementptr i8, ptr @g_arr_2, i64 %index
  %v = load i8, ptr %p, align 1
  ret i8 %v
}

define ptr @dynamic_guest_ptr(i64 %index) {
entry:
  %base = ptrtoint ptr getelementptr (i8, ptr @g_arr_2, i64 40) to i64
  %addr = add i64 %base, %index
  %p = inttoptr i64 %addr to ptr
  ret ptr %p
}

; Without a dereference/use-site proof, retain the guest arithmetic and its raw
; fault behavior rather than silently redirecting an out-of-range value to a
; synthetic scratch object.
; CHECK-NOT: @g_arr_2_with_invalid_prefix
; CHECK-NOT: @native.recovered.oob.scratch
; CHECK-NOT: ptrtoint (ptr getelementptr
; CHECK: add i64 4136, %index
; CHECK: %p = inttoptr i64 %addr to ptr

!0 = !{i64 4096, i64 4496}
