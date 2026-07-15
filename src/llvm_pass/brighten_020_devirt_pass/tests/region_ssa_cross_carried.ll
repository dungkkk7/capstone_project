; Cross-carried swaps need parallel-copy lowering and must be refused without
; leaving a partial thread block.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  br label %header
header:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %a = phi i32 [ 3, %entry ], [ %next.a, %latch ]
  %b = phi i32 [ 4, %entry ], [ %next.b, %latch ]
  br label %hub
hub:
  switch i32 %state, label %done [ i32 1, label %body ]
body:
  br label %latch
latch:
  %next.state = phi i32 [ 1, %body ]
  %next.a = phi i32 [ %b, %body ]
  %next.b = phi i32 [ %a, %body ]
  br label %header
done:
  %sum = add i32 %a, %b
  ret i32 %sum
}
