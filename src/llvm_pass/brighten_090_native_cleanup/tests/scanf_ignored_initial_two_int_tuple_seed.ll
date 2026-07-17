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

; The initial N/Q header scan controls allocation and loop bounds.  If raw
; input makes scanf fail and the source ignores its return, leaving recovered
; zero-backed locals unchanged turns native uninitialised-dimension faults into
; clean exits.  Successful scans overwrite these sentinels.
; CHECK: %native.scanf.tuple.seed = select i1 %native.scanf.tuple.had_success.pre, i32 %native.scanf.tuple.current, i32 -2147483648
; CHECK: store i32 %native.scanf.tuple.seed, ptr %n
; CHECK: store i32 {{.*}}, ptr %q
; CHECK: native.scanf.header.failed = icmp slt i32 %ignored, 2
; CHECK: call i32 @raise(i32 11)
