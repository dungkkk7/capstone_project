; RUN: opt -load-pass-plugin ../build/BrightenNativeCleanupPass.so -passes='brighten-native-cleanup-pass,verify' -S %s | FileCheck %s

target triple = "x86_64-pc-linux-gnu-elf"

@fmt = internal constant [7 x i8] c"%d%d%d\00", align 1

declare i32 @scanf(ptr, ...)

define i32 @main() {
entry:
  %a = alloca i32, align 4
  %b = alloca i32, align 4
  ; GEP +2 points at "%d%d", not the full "%d%d%d" blob.
  %r = call i32 (ptr, ...) @scanf(ptr getelementptr inbounds (i8, ptr @fmt, i64 2), ptr %a, ptr %b)
  ret i32 %r
}

; CHECK: call i32 (ptr, ...) @scanf(ptr getelementptr inbounds (i8, ptr @fmt, i64 2), ptr %a, ptr %b)
; CHECK-NOT: native.scanf.missing.destination
