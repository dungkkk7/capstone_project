target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_struct_arr.obj = type { double, [2 x i32] }

define void @test_struct_arr() {
entry:
  %obj = alloca [16 x i8], align 8

  %p0 = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store double 2.5, ptr %p0, align 8

  %p8 = getelementptr [16 x i8], ptr %obj, i64 0, i64 8
  store i32 12, ptr %p8, align 4

  %p12 = getelementptr [16 x i8], ptr %obj, i64 0, i64 12
  store i32 34, ptr %p12, align 4

  ret void
}
