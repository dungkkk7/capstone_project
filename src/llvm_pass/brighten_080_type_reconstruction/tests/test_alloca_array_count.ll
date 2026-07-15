target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @dynamic_count(i64 %count) {
entry:
  ; CHECK: %obj = alloca [16 x i8], i64 %count, align 8
  ; CHECK-NOT: brighten.stack
  %obj = alloca [16 x i8], i64 %count, align 8
  %p = getelementptr [16 x i8], ptr %obj, i64 1, i64 0
  store i32 42, ptr %p, align 4
  ret void
}

define void @constant_multi_count() {
entry:
  ; CHECK: %obj = alloca [16 x i8], i64 3, align 8
  %obj = alloca [16 x i8], i64 3, align 8
  %p = getelementptr [16 x i8], ptr %obj, i64 2, i64 0
  store i32 7, ptr %p, align 4
  ret void
}
