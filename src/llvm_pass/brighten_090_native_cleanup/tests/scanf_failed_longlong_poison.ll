; Failed 64-bit scanf destinations are kept as an unmapped poison value so
; raw input that leaves the slot unwritten cannot silently become a valid
; native pointer later in the recovered frame.
; RUN: opt-21 -load-pass-plugin=%S/../build/BrightenNativeCleanupPass.so \
; RUN:   -passes=brighten-native-cleanup-pass -S %s -o - | FileCheck %s

@format = private constant [9 x i8] c"%lld%lld\00"
declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %native_stack_storage = alloca i64, align 8
  %second = getelementptr i64, ptr %native_stack_storage, i64 1
  %result = call i32 (ptr, ...) @scanf(ptr @format,
      ptr %native_stack_storage, ptr %second)
  %failed = icmp slt i32 %result, 2
  br i1 %failed, label %read, label %read

read:
  %value = load i64, ptr %second, align 8
  %low = trunc i64 %value to i32
  ret i32 %low
}

; CHECK: store i64 -4096
