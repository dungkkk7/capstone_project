; A dynamic select is not a singleton edge fact.  The abstract interpreter must
; fail closed and retain the dispatcher instead of arbitrarily choosing an arm.

define i32 @dynamic_selector(i1 %condition) {
entry:
  %state = select i1 %condition, i32 7, i32 9
  br label %hub

hub:
  %selector = xor i32 %state, 16
  switch i32 %selector, label %fallback [
    i32 23, label %case_a
    i32 25, label %case_b
  ]

case_a:
  ret i32 1

case_b:
  ret i32 2

fallback:
  ret i32 0
}

; CHECK-LABEL: define i32 @dynamic_selector(
; CHECK: hub:
; CHECK: switch i32 %selector
