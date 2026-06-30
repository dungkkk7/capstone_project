; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-state-ssa-pass -S %s | FileCheck-21 %s

define i128 @subreg_i128(ptr %state, i64 %lo) {
entry:
  %slot = getelementptr i8, ptr %state, i64 0
  %old = load i128, ptr %slot, align 16
  store i64 %lo, ptr %slot, align 8
  %out = load i128, ptr %slot, align 16
  ret i128 %out
}

; CHECK-LABEL: define i128 @subreg_i128
; CHECK: and i128 {{.*}}, -18446744073709551616
; CHECK: zext i64 %lo to i128
; CHECK: or i128
