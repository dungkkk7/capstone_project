; A flattened state hub is removable only because every incoming edge supplies
; a literal state and the hub carries no application SSA value.

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %sum = alloca i32, align 4
  store i32 0, ptr %sum, align 4
  br label %dispatch

dispatch:
  %state = phi i32 [ 11, %entry ], [ 22, %case11 ], [ 33, %case22 ]
  %encoded = mul i32 %state, 5
  switch i32 %encoded, label %bad [
    i32 55, label %case11
    i32 110, label %case22
    i32 165, label %done
  ]

case11:
  %a = load i32, ptr %sum, align 4
  %b = add i32 %a, 1
  store i32 %b, ptr %sum, align 4
  br label %dispatch

case22:
  %c = load i32, ptr %sum, align 4
  %d = add i32 %c, 2
  store i32 %d, ptr %sum, align 4
  br label %dispatch

done:
  %result = load i32, ptr %sum, align 4
  ret i32 %result

bad:
  ret i32 99
}

; CHECK-LABEL: define i32 @main(
; CHECK-NOT: dispatch:
; CHECK-NOT: switch i32
; CHECK: entry:
; CHECK: br label %case11
; CHECK: case11:
; CHECK: br label %case22
; CHECK: case22:
; CHECK: br label %done
