; This resembles a state dispatcher, but the entry state is program data.
; Removing it would specialize normal switch semantics, so it must remain.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ %argc, %entry ], [ 0, %step ]
  switch i32 %state, label %other [
    i32 0, label %zero
    i32 1, label %step
  ]

step:
  br label %dispatch

zero:
  ret i32 0

other:
  ret i32 7
}

; CHECK-LABEL: define i32 @main(
; CHECK: dispatch:
; CHECK: %state = phi i32 [ %argc, %entry ], [ 0, %step ]
; CHECK: switch i32 %state

