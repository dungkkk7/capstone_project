; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-state-ssa-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer

define i64 @sub_401000_native(ptr %memory) {
entry:
  %slot = getelementptr i8, ptr %memory, i64 16
  %v = load i64, ptr %slot, align 8
  %inc = add i64 %v, 1
  store i64 %inc, ptr %slot, align 8
  ret i64 %inc
}

; CHECK-LABEL: define i64 @sub_401000_native
; CHECK-NOT: state_16
; CHECK: %slot = getelementptr i8, ptr %memory, i64 16
; CHECK: %v = load i64, ptr %slot
; CHECK: store i64 %inc, ptr %slot
