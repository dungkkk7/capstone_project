; A failed single %lld must not be forced to INT64_MIN.  The native
; destination is an unwritten stack slot, so its value is environment
; dependent and must remain untouched by this seeding rule.
; RUN: opt-21 -load-pass-plugin=%S/../build/BrightenNativeCleanupPass.so \
; RUN:   -passes=brighten-native-cleanup-pass -S %s -o - | FileCheck %s

@format = private constant [5 x i8] c"%lld\00"
declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %native_stack_storage = alloca i64, align 8
  %result = call i32 (ptr, ...) @scanf(ptr @format, ptr %native_stack_storage)
  %value = load i64, ptr %native_stack_storage, align 8
  %low = trunc i64 %value to i32
  ret i32 %low
}

; CHECK-NOT: store i64 -9223372036854775808
