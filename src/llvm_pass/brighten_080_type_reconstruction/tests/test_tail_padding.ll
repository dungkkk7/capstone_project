target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_tail_pad.obj = type { i32, [12 x i8] }

define void @test_tail_pad() {
entry:
  %obj = alloca [16 x i8], align 8
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p, align 4
  ret void
}
