; RUN: opt-21 -load-pass-plugin=%builddir/BrightenTypeReconstructionPass.so -passes=brighten-type-reconstruct -brighten-type-mode=conservative -S < %s | FileCheck-21 %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @test_conflict() {
entry:
  ; CHECK: %obj = alloca [8 x i8]
  %obj = alloca [8 x i8], align 4

  %p0 = getelementptr [8 x i8], ptr %obj, i64 0, i64 0
  store i32 100, ptr %p0, align 4

  ; Store float at the exact same offset -> conflict!
  store float 2.5, ptr %p0, align 4

  ret void
}
