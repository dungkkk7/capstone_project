; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-state-ssa-pass -S %s | FileCheck-21 %s

define void @helper(ptr %buf) {
entry:
  store i8 1, ptr %buf, align 1
  ret void
}

define i64 @caller(ptr %state, ptr %buf) {
entry:
  %state_slot = getelementptr i8, ptr %state, i64 8
  %a = load i64, ptr %state_slot, align 8
  %b = add i64 %a, 1
  store i64 %b, ptr %state_slot, align 8
  call void @helper(ptr %buf)
  %c = load i64, ptr %state_slot, align 8
  ret i64 %c
}

; CHECK-LABEL: define i64 @caller
; CHECK: call void @helper(ptr %buf)
; CHECK-NOT: getelementptr i8, ptr %buf, i64 8
