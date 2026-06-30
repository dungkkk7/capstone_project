; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

define i32 @mba_nested_sub_zero(i32 %a, i32 %b) {
entry:
  %orv = or i32 %a, %b
  %twice = mul i32 %orv, 2
  %xorv = xor i32 %a, %b
  %sub1 = sub i32 %twice, %xorv
  %sub2 = sub i32 %sub1, %a
  %sub3 = sub i32 %sub2, %b
  ret i32 %sub3
}

define i32 @mba_nested_and_or_sub_zero(i32 %a, i32 %b) {
entry:
  %andv = and i32 %a, %b
  %orv = or i32 %a, %b
  %sum = add i32 %andv, %orv
  %sub1 = sub i32 %sum, %a
  %sub2 = sub i32 %sub1, %b
  ret i32 %sub2
}

; CHECK-LABEL: define i32 @mba_nested_sub_zero(i32 %a, i32 %b) {
; CHECK: ret i32 0
; CHECK-LABEL: define i32 @mba_nested_and_or_sub_zero(i32 %a, i32 %b) {
; CHECK: ret i32 0
