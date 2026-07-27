; A self-hub dispatcher carries both the flattened state and native program
; values across its backedge.  The proven 1 -> 2 transition may be threaded
; only after reconstructing all three PHIs on the new case edge.

@trace = internal global i32 0

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %hub

hub:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %value = phi i32 [ 5, %entry ], [ %next.value, %latch ]
  %iteration = phi i32 [ 0, %entry ], [ %next.iteration, %latch ]
  store i32 %state, ptr @trace
  switch i32 %state, label %bad [
    i32 1, label %case.one
    i32 2, label %case.two
  ]

case.one:
  %incremented = add i32 %value, 7
  %stepped = add i32 %iteration, 1
  br label %latch

case.two:
  %result = add i32 %value, %iteration
  ret i32 %result

bad:
  ret i32 99

latch:
  %next.state = phi i32 [ 2, %case.one ]
  %next.value = phi i32 [ %incremented, %case.one ]
  %next.iteration = phi i32 [ %stepped, %case.one ]
  store i32 %next.value, ptr @trace
  br label %hub
}

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: switch i32
; CHECK: entry:
; CHECK: store i32 1, ptr @trace
; CHECK: %incremented = add i32 5, 7
; CHECK: %stepped = add i32 0, 1
; CHECK: store i32 %incremented, ptr @trace
; CHECK: store i32 2, ptr @trace
; CHECK: %result = add i32 %incremented, %stepped
; CHECK: ret i32 %result
