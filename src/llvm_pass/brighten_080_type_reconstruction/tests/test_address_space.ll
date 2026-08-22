target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_addrspace() {
entry:
  ; CHECK: %obj = alloca %brighten.struct.stack.test_addrspace.obj, align 8, addrspace(3)
  %obj = alloca [16 x i8], align 8, addrspace(3)

  ; CHECK: store i32 100
  %p = getelementptr [16 x i8], ptr addrspace(3) %obj, i64 0, i64 0
  store i32 100, ptr addrspace(3) %p, align 4

  ret void
}
