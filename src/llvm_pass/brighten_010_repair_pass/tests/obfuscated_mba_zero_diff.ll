; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

define i32 @mba_zero_diff(i32 %x) {
entry:
  %xorv = xor i32 %x, 106305085
  %sum = add i32 %x, %xorv
  %sh = shl i32 %x, 1
  %orv = or i32 %sh, 212610170
  %lhs = add i32 %orv, -106305085
  %diff = sub i32 %lhs, %sum
  ret i32 %diff
}

; CHECK-LABEL: define i32 @mba_zero_diff(i32 %x) {
; CHECK: ret i32 0
