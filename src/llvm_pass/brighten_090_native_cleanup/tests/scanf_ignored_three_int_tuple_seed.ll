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

; Failed raw query scans with ignored return must fail closed.  Successful
; conversions overwrite these seeds.
; CHECK: %native.scanf.tuple.seed = select i1 %native.scanf.tuple.had_success.pre, i32 %native.scanf.tuple.current, i32 -2147483648
; CHECK: store i32 %native.scanf.tuple.seed, ptr %t
; CHECK: store i32 {{.*}}, ptr %x
; CHECK: store i32 {{.*}}, ptr %y
