; Transactional affine-frame preflight must not inline this two-call helper:
; its unresolved state dispatcher makes frame compaction ineligible.
target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

@frame_storage_backing.main = internal global [256 x i8] zeroinitializer, align 16

define i32 @main() {
entry:
  store i8 0, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 8), align 1
  %left = call i32 @worker()
  %right = call i32 @worker()
  %sum = add i32 %left, %right
  ret i32 %sum
}

define internal i32 @worker() {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 0, %entry ], [ %state, %dispatch ], [ 1000, %again ]
  switch i32 %state, label %dispatch [
    i32 0, label %again
    i32 1000, label %done
  ]

again:
  store i32 7, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 32), align 4
  br label %dispatch

done:
  %value = load i32, ptr getelementptr (i8, ptr @frame_storage_backing.main, i64 32), align 4
  ret i32 %value
}
