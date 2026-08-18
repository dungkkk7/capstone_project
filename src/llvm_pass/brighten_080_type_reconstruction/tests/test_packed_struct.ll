; RUN: opt-21 -load-pass-plugin=%builddir/BrightenTypeReconstructionPass.so -passes=brighten-type-reconstruct -S < %s | FileCheck-21 %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_packed.obj = type <{ i32, [1 x i8], i32, [3 x i8] }>

define void @test_packed() {
entry:
  %obj = alloca [12 x i8], align 8

  %p0 = getelementptr [12 x i8], ptr %obj, i64 0, i64 0
  store i32 12, ptr %p0, align 4

  %p5 = getelementptr [12 x i8], ptr %obj, i64 0, i64 5
  store i32 56, ptr %p5, align 1

  ret void
}
