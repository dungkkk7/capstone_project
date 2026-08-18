target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_nested.obj = type { i32, [4 x i8], i64, i32, [4 x i8] }

define void @test_nested() {
entry:
  %obj = alloca [24 x i8], align 8

  %p0 = getelementptr [24 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p0, align 4

  %p8 = getelementptr [24 x i8], ptr %obj, i64 0, i64 8
  store i64 200, ptr %p8, align 8

  %p16 = getelementptr [24 x i8], ptr %obj, i64 0, i64 16
  store i32 300, ptr %p16, align 4

  ret void
}
