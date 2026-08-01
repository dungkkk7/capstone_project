; Edge-local values from the case predecessor remain safe to thread.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %hub

hub:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %value = phi i32 [ 5, %entry ], [ %next.value, %latch ]
  switch i32 %state, label %bad [
    i32 1, label %case.one
    i32 2, label %done
  ]

case.one:
  %incremented = add i32 %value, 7
  br label %latch

latch:
  %next.state = phi i32 [ 2, %case.one ]
  %next.value = phi i32 [ %incremented, %case.one ]
  br label %hub

done:
  ret i32 %value

bad:
  ret i32 99
}

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: switch i32
; CHECK: %incremented = add i32 5, 7
; CHECK: ret i32 %incremented
