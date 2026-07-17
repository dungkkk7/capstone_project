; RUN: opt-21 -load-pass-plugin=%S/../build/BrightenNativeCleanupPass.so \
; RUN:   -passes=brighten-native-cleanup-pass -S %s -o - | FileCheck %s

@format = private constant [3 x i8] c"%d\00"

declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %native_stack_storage = alloca i32, align 4
  %ignored = call i32 (ptr, ...) @scanf(ptr @format, ptr %native_stack_storage)
  %value = load i32, ptr %native_stack_storage, align 4
  ret i32 %value
}

; If the source ignores scanf's return, a failed conversion leaves the
; destination unchanged.  Seeding here changes loops like p00399 where the
; previous successful value is intentionally reused after later failures.
; CHECK-NOT: store i32 -2147483648, ptr %native_stack_storage
