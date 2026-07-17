; RUN: opt-21 -load-pass-plugin=%S/../build/BrightenNativeCleanupPass.so \
; RUN:   -passes=brighten-native-cleanup-pass -S %s -o - | FileCheck %s

@format = private constant [5 x i8] c"%d%d\00"
declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %native_stack_storage_a = alloca i32, align 4
  %native_stack_storage_b = alloca i32, align 4
  %result = call i32 (ptr, ...) @scanf(ptr @format, ptr %native_stack_storage_a, ptr %native_stack_storage_b)
  %failed = icmp slt i32 %result, 2
  br i1 %failed, label %read, label %read

read:
  %va = load i32, ptr %native_stack_storage_a, align 4
  %vb = load i32, ptr %native_stack_storage_b, align 4
  %sum = add i32 %va, %vb
  ret i32 %sum
}

; Multi-destination integer scans use the fail-closed sentinel.  A single
; destination remains untouched because its native stack value is undefined.
; CHECK: store i32 -2147483648, ptr %native_stack_storage_a
; CHECK: store i32 -2147483648, ptr %native_stack_storage_b
