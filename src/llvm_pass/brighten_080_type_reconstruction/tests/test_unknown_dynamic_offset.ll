target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_unknown_dyn(i64 %idx) {
entry:
  ; CHECK: %obj = alloca [64 x i8]
  ; CHECK-NOT: brighten.gep
  %obj = alloca [64 x i8], align 4

  ; Unknown offset calculation: shift left by a dynamic variable or non-linear arithmetic
  %shift = shl i64 %idx, %idx
  %p = getelementptr [64 x i8], ptr %obj, i64 0, i64 %shift
  store i32 100, ptr %p, align 4

  ret void
}
