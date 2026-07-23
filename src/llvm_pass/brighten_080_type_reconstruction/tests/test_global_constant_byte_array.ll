target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @my_global = internal global [2 x i32] [i32 67305985, i32 134678021], !brighten.guest.range ![[RANGE:[0-9]+]]
; CHECK: ![[RANGE]] = !{i64 4096, i64 4104}

@my_global = internal global [8 x i8] c"\01\02\03\04\05\06\07\08",
  !brighten.guest.range !0

define void @test_global() {
entry:
  %p0 = getelementptr [8 x i8], ptr @my_global, i64 0, i64 0
  %v0 = load i32, ptr %p0, align 4

  %p4 = getelementptr [8 x i8], ptr @my_global, i64 0, i64 4
  %v4 = load i32, ptr %p4, align 4

  ret void
}

!0 = !{i64 4096, i64 4104}
