; A constant transition at the end of a multi-block case is insufficient for
; the single-block region threader.  It must leave the nested path intact.

define i32 @nested_case(i1 %take) {
entry:
  br label %header

header:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %value = phi i32 [ 4, %entry ], [ %next.value, %latch ]
  br label %hub

hub:
  switch i32 %state, label %fallback [
    i32 1, label %case.entry
    i32 2, label %case.two
  ]

case.entry:
  br i1 %take, label %case.tail, label %case.side

case.side:
  %side = add i32 %value, 7
  br label %case.tail

case.tail:
  %out = phi i32 [ %value, %case.entry ], [ %side, %case.side ]
  br label %latch

case.two:
  ret i32 %value

fallback:
  br label %latch

latch:
  %next.state = phi i32 [ 2, %case.tail ], [ 2, %fallback ]
  %next.value = phi i32 [ %out, %case.tail ], [ %value, %fallback ]
  br label %header
}

