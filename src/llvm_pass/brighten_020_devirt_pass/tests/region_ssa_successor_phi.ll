; A carried value used by the latch PHI belongs to the case->latch edge.  When
; case.one is threaded directly to case.two, that edge must use the newly
; carried counter (1), not the previous header counter (0).

define i32 @main() {
entry:
  br label %header

header:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %counter = phi i32 [ 0, %entry ], [ %next.counter, %latch ]
  br label %hub

hub:
  switch i32 %state, label %fallback [
    i32 1, label %case.one
    i32 2, label %case.two
    i32 3, label %case.three
  ]

case.one:
  %incremented = add i32 %counter, 1
  br label %latch

case.two:
  br label %latch

case.three:
  ret i32 %counter

fallback:
  ret i32 -1

latch:
  %next.state = phi i32 [ 2, %case.one ], [ 3, %case.two ]
  %next.counter = phi i32 [ %incremented, %case.one ], [ %counter, %case.two ]
  br label %header
}
