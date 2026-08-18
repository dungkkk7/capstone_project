target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define void @test_memcpy(ptr %src) {
entry:
  ; CHECK: %obj = alloca [16 x i8]
  ; CHECK-NOT: %brighten.struct.stack.test_memcpy.obj
  %obj = alloca [16 x i8], align 8

  ; CHECK: call void @llvm.memcpy
  %p = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  call void @llvm.memcpy.p0.p0.i64(ptr %p, ptr %src, i64 16, i1 false)

  ret void
}
