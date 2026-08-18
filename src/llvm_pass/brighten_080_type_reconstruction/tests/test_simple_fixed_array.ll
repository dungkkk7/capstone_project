; RUN: opt-21 -load-pass-plugin=%builddir/BrightenTypeReconstructionPass.so -passes=brighten-type-reconstruct -S < %s | FileCheck-21 %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_array() {
entry:
  ; CHECK: %obj = alloca [4 x i32]
  %obj = alloca [16 x i8], align 4

  ; CHECK: {{%brighten.gep.*}} = getelementptr [4 x i32], ptr %obj, i32 0, i64 0
  %p0 = getelementptr [16 x i8], ptr %obj, i64 0, i64 0
  store i32 1, ptr %p0, align 4

  ; CHECK: {{%brighten.gep.*}} = getelementptr [4 x i32], ptr %obj, i32 0, i64 1
  %p4 = getelementptr [16 x i8], ptr %obj, i64 0, i64 4
  store i32 2, ptr %p4, align 4

  ; CHECK: {{%brighten.gep.*}} = getelementptr [4 x i32], ptr %obj, i32 0, i64 2
  %p8 = getelementptr [16 x i8], ptr %obj, i64 0, i64 8
  store i32 3, ptr %p8, align 4

  ; CHECK: {{%brighten.gep.*}} = getelementptr [4 x i32], ptr %obj, i32 0, i64 3
  %p12 = getelementptr [16 x i8], ptr %obj, i64 0, i64 12
  store i32 4, ptr %p12, align 4

  ret void
}
