target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @raw_pointer = internal global [8 x i8] c"\01\00\00\00\00\00\00\00"
; CHECK-NOT: brighten.struct.global.raw_pointer
@raw_pointer = internal global [8 x i8] c"\01\00\00\00\00\00\00\00"

define ptr @read_raw_pointer() {
entry:
  %p = getelementptr [8 x i8], ptr @raw_pointer, i64 0, i64 0
  %v = load ptr, ptr %p, align 8
  ret ptr %v
}
