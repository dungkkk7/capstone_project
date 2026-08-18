target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_misaligned() {
entry:
  ; CHECK: %obj = alloca %brighten.struct.stack.test_misaligned.obj
  %obj = alloca [16 x i8], align 8

  ; CHECK: store i32 100, ptr {{%brighten.gep.*}}, align 1
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p, align 1

  ret void
}
