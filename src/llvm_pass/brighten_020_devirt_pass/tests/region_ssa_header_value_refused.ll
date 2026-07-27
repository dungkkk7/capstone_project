; A Header instruction dominates the old latch in the unthreaded CFG, but not
; the direct region.thread edge produced by this pass.  Refuse transactionally.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %hub

hub:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %value = phi i32 [ 5, %entry ], [ %next.value, %latch ]
  %biased = add i32 %value, 1
  switch i32 %state, label %bad [
    i32 1, label %case.one
    i32 2, label %done
  ]

case.one:
  br label %latch

latch:
  %next.state = phi i32 [ 2, %case.one ]
  %next.value = phi i32 [ %biased, %case.one ]
  br label %hub

done:
  ret i32 %value

bad:
  ret i32 99
}

; CHECK-LABEL: define i32 @main(
; CHECK: hub:
; CHECK: %biased = add i32 %value, 1
; CHECK: switch i32 %state
; CHECK-NOT: region.thread
