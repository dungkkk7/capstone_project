; Swapping two header values is a parallel-copy transition.  The current
; proof deliberately rejects it transactionally instead of rewiring only the
; state edge and changing the loop-carried register values.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %hub

hub:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %a = phi i32 [ 7, %entry ], [ %next.a, %latch ]
  %b = phi i32 [ 2, %entry ], [ %next.b, %latch ]
  switch i32 %state, label %bad [
    i32 1, label %swap
    i32 2, label %done
  ]

swap:
  br label %latch

latch:
  %next.state = phi i32 [ 2, %swap ]
  %next.a = phi i32 [ %b, %swap ]
  %next.b = phi i32 [ %a, %swap ]
  br label %hub

done:
  %result = sub i32 %a, %b
  ret i32 %result

bad:
  ret i32 99
}

; CHECK-LABEL: define i32 @main(
; CHECK: hub:
; CHECK: %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
; CHECK: %a = phi i32 [ 7, %entry ], [ %next.a, %latch ]
; CHECK: %b = phi i32 [ 2, %entry ], [ %next.b, %latch ]
; CHECK: switch i32 %state
; CHECK-NOT: region.thread

