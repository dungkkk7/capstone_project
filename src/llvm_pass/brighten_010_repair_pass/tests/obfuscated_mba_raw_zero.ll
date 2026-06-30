; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

define i32 @mba_raw_or_xor_add(i32 %a, i32 %b) {
entry:
  %orv = or i32 %a, %b
  %twice = mul i32 %orv, 2
  %xorv = xor i32 %a, %b
  %sub1 = sub i32 %twice, %xorv
  %sum = add i32 %a, %b
  %sub2 = sub i32 %sub1, %sum
  ret i32 %sub2
}

define i32 @mba_raw_add_xor_and(i32 %a, i32 %b) {
entry:
  %sum = add i32 %a, %b
  %xorv = xor i32 %a, %b
  %sub1 = sub i32 %sum, %xorv
  %andv = and i32 %a, %b
  %twice = mul i32 %andv, 2
  %sub2 = sub i32 %sub1, %twice
  ret i32 %sub2
}

define i32 @mba_raw_or_xor_and(i32 %a, i32 %b) {
entry:
  %orv = or i32 %a, %b
  %xorv = xor i32 %a, %b
  %sub1 = sub i32 %orv, %xorv
  %andv = and i32 %a, %b
  %sub2 = sub i32 %sub1, %andv
  ret i32 %sub2
}

; CHECK-LABEL: define i32 @mba_raw_or_xor_add(i32 %a, i32 %b) {
; CHECK: ret i32 0
; CHECK-LABEL: define i32 @mba_raw_add_xor_and(i32 %a, i32 %b) {
; CHECK: ret i32 0
; CHECK-LABEL: define i32 @mba_raw_or_xor_and(i32 %a, i32 %b) {
; CHECK: ret i32 0
