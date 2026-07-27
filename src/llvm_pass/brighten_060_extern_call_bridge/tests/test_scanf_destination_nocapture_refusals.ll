; RUN: opt -load-pass-plugin=%builddir/BrightenExternCallBridgePass.so \
; RUN:   -passes=brighten-extern-call-bridge,verify -S < %s | FileCheck %s

target triple = "x86_64-unknown-linux-gnu"

@.suppressed = private constant [6 x i8] c"%*d%d\00"
@.positional = private constant [5 x i8] c"%2$d\00"
@.count = private constant [3 x i8] c"%n\00"
@.malformed = private constant [2 x i8] c"%\00"

declare i32 @scanf(ptr, ...)

; CHECK-LABEL: define i32 @dynamic_format
; CHECK: call i32 (ptr, ...) @scanf(ptr %fmt, ptr %dst)
define i32 @dynamic_format(ptr %fmt, ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr %fmt, ptr %dst)
  ret i32 %r
}

; CHECK-LABEL: define i32 @suppression
; CHECK: call i32 (ptr, ...) @scanf(ptr @.suppressed, ptr %dst)
define i32 @suppression(ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr @.suppressed, ptr %dst)
  ret i32 %r
}

; CHECK-LABEL: define i32 @positional
; CHECK: call i32 (ptr, ...) @scanf(ptr @.positional, ptr %dst)
define i32 @positional(ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr @.positional, ptr %dst)
  ret i32 %r
}

; CHECK-LABEL: define i32 @count_conversion
; CHECK: call i32 (ptr, ...) @scanf(ptr @.count, ptr %dst)
define i32 @count_conversion(ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr @.count, ptr %dst)
  ret i32 %r
}

; CHECK-LABEL: define i32 @malformed
; CHECK: call i32 (ptr, ...) @scanf(ptr @.malformed, ptr %dst)
define i32 @malformed(ptr %dst) {
  %r = call i32 (ptr, ...) @scanf(ptr @.malformed, ptr %dst)
  ret i32 %r
}

; CHECK-LABEL: define i32 @indirect
; CHECK: call i32 (ptr, ...) %callback(ptr @.count, ptr %dst)
define i32 @indirect(ptr %callback, ptr %dst) {
  %r = call i32 (ptr, ...) %callback(ptr @.count, ptr %dst)
  ret i32 %r
}
