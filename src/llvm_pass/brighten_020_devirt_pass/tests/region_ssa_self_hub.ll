; The selector PHI may live in the switch hub itself, and a large flattened
; dispatcher may split cases across a pure default switch.  Both arms of the
; 1 -> select(2, 3) transition are still provable.  The argument-dependent
; transition must remain on the original fallback path.

@trace = internal global i32 0

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %hub

hub:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  store i32 %state, ptr @trace
  switch i32 %state, label %nested [
    i32 1, label %case.one
  ]

nested:
  switch i32 %state, label %fallback [
    i32 2, label %case.two
    i32 3, label %case.three
  ]

case.one:
  %take.two = icmp sgt i32 %argc, 0
  %selected = select i1 %take.two, i32 2, i32 3
  br label %latch

case.two:
  ret i32 3

case.three:
  ret i32 3

fallback:
  %dynamic = add i32 %argc, 1
  br label %latch

latch:
  %next.state = phi i32 [ %selected, %case.one ], [ %dynamic, %fallback ]
  store i32 %next.state, ptr @trace
  br label %hub
}

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: switch i32
; CHECK: br i1 %take.two, label %region.thread, label %region.thread
; CHECK: region.thread:
; CHECK: store i32 2, ptr @trace
; CHECK: br label %common.ret
; CHECK: region.thread1:
; CHECK: store i32 3, ptr @trace
; CHECK-NOT: switch i32
