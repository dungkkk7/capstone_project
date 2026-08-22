; RUN: opt-21 -load-pass-plugin=%builddir/BrightenTypeReconstructionPass.so -passes=brighten-type-reconstruct -S < %s | FileCheck-21 %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.stack.test_func.obj = type { i32, [4 x i8], i64, i32, [4 x i8] }

define void @test_func() {
entry:
  ; CHECK: %obj = alloca %brighten.struct.stack.test_func.obj
  %obj = alloca [24 x i8], align 8
  
  ; CHECK: {{%brighten.gep.*}} = getelementptr %brighten.struct.stack.test_func.obj, ptr %obj, i32 0, i32 0
  ; CHECK-NEXT: store i32 12, ptr {{%brighten.gep.*}}
  %p0 = getelementptr [24 x i8], ptr %obj, i64 0, i64 0
  store i32 12, ptr %p0, align 4

  ; CHECK: {{%brighten.gep.*}} = getelementptr %brighten.struct.stack.test_func.obj, ptr %obj, i32 0, i32 2
  ; CHECK-NEXT: store i64 34, ptr {{%brighten.gep.*}}
  %p8 = getelementptr [24 x i8], ptr %obj, i64 0, i64 8
  store i64 34, ptr %p8, align 8

  ; CHECK: {{%brighten.gep.*}} = getelementptr %brighten.struct.stack.test_func.obj, ptr %obj, i32 0, i32 3
  ; CHECK-NEXT: store i32 56, ptr {{%brighten.gep.*}}
  %p16 = getelementptr [24 x i8], ptr %obj, i64 0, i64 16
  store i32 56, ptr %p16, align 4

  ret void
}
