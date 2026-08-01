; Even with a constant next-state transition, the hub carries application SSA.
; Bypassing it without rebuilding that SSA would change the loop result.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 1, %entry ], [ 0, %step ]
  %value = phi i32 [ 40, %entry ], [ %next, %step ]
  switch i32 %state, label %bad [
    i32 1, label %step
    i32 0, label %done
  ]

step:
  %next = add i32 %value, 2
  br label %dispatch

done:
  ret i32 %value

bad:
  ret i32 99
}

; CHECK-LABEL: define i32 @main(
; CHECK: dispatch:
; CHECK: %state = phi i32 [ 1, %entry ], [ 0, %step ]
; CHECK: %value = phi i32 [ 40, %entry ], [ %next, %step ]
; CHECK: switch i32 %state

