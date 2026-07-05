target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @my_ext_global = global [8 x i8]

@my_ext_global = global [8 x i8] c"\01\02\03\04\05\06\07\08"

define void @test_ext_global() {
entry:
  ; CHECK: getelementptr (%brighten.struct.global.my_ext_global, ptr @my_ext_global, i32 0, i32 1)
  %p4 = getelementptr [8 x i8], ptr @my_ext_global, i64 0, i64 4
  %v4 = load i32, ptr %p4, align 4
  ret void
}
