target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; CHECK: @late_init = internal externally_initialized global [8 x i8] c"\01\02\03\04\05\06\07\08"
; CHECK-NOT: @late_init = internal externally_initialized global [2 x i32]
@late_init = internal externally_initialized global [8 x i8] c"\01\02\03\04\05\06\07\08"

define i32 @read_late_init() {
entry:
  ; CHECK: getelementptr (%brighten.struct.global.late_init, ptr @late_init, i32 0, i32 1)
  %p4 = getelementptr [8 x i8], ptr @late_init, i64 0, i64 4
  %v = load i32, ptr %p4, align 4
  ret i32 %v
}
