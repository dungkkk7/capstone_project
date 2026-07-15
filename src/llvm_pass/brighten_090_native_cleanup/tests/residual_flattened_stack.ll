; A native-looking ABI is not sufficient when the function still carries the
; generated guest-stack backing and an OLLVM-style state dispatcher.
target triple = "x86_64-pc-linux-gnu"

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer, align 16

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ -1805578658, %entry ], [ 1039594562, %case.zero ], [ %state, %dispatch ]
  switch i32 %state, label %dispatch [
    i32 -1805578658, label %case.zero
    i32 1039594562, label %done
  ]

case.zero:
  store i8 0, ptr getelementptr inbounds ([16777216 x i8], ptr @frame_storage_backing.main, i64 0, i64 16711672)
  br label %dispatch

done:
  ret i32 0
}
