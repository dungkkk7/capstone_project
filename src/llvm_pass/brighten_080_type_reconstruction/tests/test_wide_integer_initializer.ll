target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: %brighten.struct.global.wide = type { i128 }
; CHECK: @wide = internal global %brighten.struct.global.wide { i128 21345817372864405881847059188222722561 }
@wide = internal global [16 x i8] c"\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10"

define i128 @read_wide() {
entry:
  %p = getelementptr [16 x i8], ptr @wide, i64 0, i64 0
  %v = load i128, ptr %p, align 16
  ret i128 %v
}
