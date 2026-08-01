; RUN: opt-21 -load-pass-plugin=%S/../build/BrightenNativeCleanupPass.so \
; RUN:   -passes=brighten-native-cleanup-pass -S %s -o - | FileCheck %s

@format = private constant [7 x i8] c"%d%d%d\00"
declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %t = alloca i32, align 4
  %x = alloca i32, align 4
  %y = alloca i32, align 4
  %ignored = call i32 (ptr, ...) @scanf(ptr @format, ptr %t, ptr %x, ptr %y)
  %vx = load i32, ptr %x, align 4
  ret i32 %vx
}

; Ignoring scanf's return does not authorize pre-seeding its destinations.
; CHECK-NOT: native.scanf.tuple.seed
; CHECK-NOT: store i32 -2147483648
