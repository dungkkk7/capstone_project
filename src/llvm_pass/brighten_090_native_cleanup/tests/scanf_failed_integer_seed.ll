; RUN: opt-21 -load-pass-plugin=%S/../build/BrightenNativeCleanupPass.so \
; RUN:   -passes=brighten-native-cleanup-pass -S %s -o - | FileCheck %s

@format = private constant [3 x i8] c"%i\00"

declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %native_stack_storage = alloca i32, align 4
  %result = call i32 (ptr, ...) @scanf(ptr @format, ptr %native_stack_storage)
  %failed = icmp eq i32 %result, -1
  br i1 %failed, label %read, label %read

read:
  %value = load i32, ptr %native_stack_storage, align 4
  ret i32 %value
}

; Failed single 32-bit destinations receive a deterministic fail-closed seed.
; CHECK: store i32 -2147483648, ptr %native_stack_storage
