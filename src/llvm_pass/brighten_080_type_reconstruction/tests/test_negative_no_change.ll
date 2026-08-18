target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_no_evidence() {
entry:
  ; CHECK: %obj = alloca [16 x i8]
  %obj = alloca [16 x i8], align 8
  ret void
}
