; The v1 matcher accepted only PHI -> add/sub/mul/xor(constant) and required
; ConstantInt PHI inputs.  The v2 evaluator proves this ordinary AND/OR/shift
; selector from predecessor-local expressions.

define i32 @finite_selector(i1 %choose) {
entry:
  br i1 %choose, label %left, label %right

left:
  %l0 = xor i32 10, 3
  br label %hub

right:
  %r0 = shl i32 2, 2
  br label %hub

hub:
  %state = phi i32 [ %l0, %left ], [ %r0, %right ]
  %tagged = or i32 %state, 16
  %selector = and i32 %tagged, 31
  switch i32 %selector, label %fallback [
    i32 25, label %case_left
    i32 24, label %case_right
  ]

case_left:
  ret i32 11

case_right:
  ret i32 22

fallback:
  ret i32 0
}

; CHECK-LABEL: define i32 @finite_selector(
; CHECK: left:
; CHECK: br label %case_left
; CHECK: right:
; CHECK: br label %case_right
; CHECK-NOT: hub:
; CHECK-NOT: switch i32
