target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_arr_structs.obj.elem = type { i32, [4 x i8], double }

define void @test_arr_structs(i64 %idx) {
entry:
  %obj = alloca [48 x i8], align 8
  %off = shl i64 %idx, 4

  %p0 = getelementptr [48 x i8], ptr %obj, i64 0, i64 %off
  store i32 100, ptr %p0, align 4

  %off8 = add i64 %off, 8
  %p8 = getelementptr [48 x i8], ptr %obj, i64 0, i64 %off8
  store double 2.5, ptr %p8, align 8

  ret void
}
