target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @unknown_external_call(ptr)

define void @test_escape() {
entry:
  ; CHECK: %obj = alloca [16 x i8]
  %obj = alloca [16 x i8], align 8

  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p, align 4

  ; Pass pointer to unknown function -> escaped!
  call void @unknown_external_call(ptr %obj)

  ret void
}
