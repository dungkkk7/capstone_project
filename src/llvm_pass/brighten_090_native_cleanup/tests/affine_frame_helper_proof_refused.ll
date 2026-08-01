; A multi-owner backing whose merged owner cannot prove a finite affine stack
; PHI must retain both helper call sites exactly as they were.
target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

@frame_storage_backing.main = internal global [256 x i8] zeroinitializer, align 16

define i32 @main() {
entry:
  store i32 1, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 8), align 4
  %left = call i32 @worker()
  %right = call i32 @worker()
  %sum = add i32 %left, %right
  ret i32 %sum
}

define internal i32 @worker() {
entry:
  %value = load i32, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 8), align 4
  %next = add i32 %value, 1
  store i32 %next, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 8), align 4
  ret i32 %next
}
