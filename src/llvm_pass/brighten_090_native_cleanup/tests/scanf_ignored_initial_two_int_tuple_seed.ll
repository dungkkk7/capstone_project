; RUN: opt-21 -load-pass-plugin=%S/../build/BrightenNativeCleanupPass.so \
; RUN:   -passes=brighten-native-cleanup-pass -S %s -o - | FileCheck %s

@format = private constant [5 x i8] c"%d%d\00"
declare i32 @scanf(ptr, ...)
declare i32 @raise(i32)

define i32 @main() {
entry:
  %n = alloca i32, align 4
  %q = alloca i32, align 4
  %ignored = call i32 (ptr, ...) @scanf(ptr @format, ptr %n, ptr %q)
  %vn = load i32, ptr %n, align 4
  ret i32 %vn
}

; A malformed/EOF header follows the program's existing CFG.  Cleanup must
; neither overwrite destinations before scanf nor synthesize a SIGSEGV.
; CHECK-NOT: native.scanf.tuple.seed
; CHECK-NOT: store i32 -2147483648
; CHECK-NOT: call i32 @raise(i32 11)
