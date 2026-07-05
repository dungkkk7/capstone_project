; RUN: opt-21 -load-pass-plugin=%builddir/BrightenTypeReconstructionPass.so -passes=brighten-type-reconstruct -S < %s | FileCheck-21 %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_dyn_array_scaled(i64 %idx) {
entry:
  ; CHECK: %obj = alloca [16 x i32]
  %obj = alloca [64 x i8], align 4

  %idx_scaled = shl i64 %idx, 2

  ; CHECK: {{%brighten.gep.*}} = getelementptr [16 x i32], ptr %obj, i32 0, i64 %idx
  %p = getelementptr [64 x i8], ptr %obj, i64 0, i64 %idx_scaled
  store i32 100, ptr %p, align 4

  ret void
}
