; RUN: opt-21 -load-pass-plugin=%S/../build/BrightenNativeCleanupPass.so \
; RUN:   -passes=brighten-native-cleanup-pass -S %s -o - | FileCheck %s

@g_arr_2_with_invalid_prefix = internal global [8516 x i8] zeroinitializer, align 1

define i32 @main(i64 %city, i64 %ticket) {
entry:
  %city.bytes = mul i64 %city, 40
  %ticket.bytes = mul i64 %ticket, 4
  %p0 = getelementptr i8, ptr @g_arr_2_with_invalid_prefix, i64 4
  %p1 = getelementptr i8, ptr %p0, i64 %city.bytes
  %p2 = getelementptr i8, ptr %p1, i64 %ticket.bytes
  %v = load i32, ptr %p2, align 4
  ret i32 %v
}

; Without guest-range provenance, cleanup must not attach binary-specific
; bounds or redirect this ordinal-named object.  Preserve the original access.
; CHECK: %p0 = getelementptr i8, ptr @g_arr_2_with_invalid_prefix, i64 4
; CHECK-NOT: native.bounds.nested.unmapped.fault
; CHECK-NOT: store volatile i8 0, ptr null
