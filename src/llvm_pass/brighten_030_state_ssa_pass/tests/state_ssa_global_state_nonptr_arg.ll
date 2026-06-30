; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-state-ssa-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [8 x i8] zeroinitializer
@ZF_0_i = private alias i8, ptr @__mcsema_reg_state

define i8 @global_state_nonptr_arg(i8 %v) {
entry:
  store i8 %v, ptr @ZF_0_i, align 1
  %flag = load i8, ptr @ZF_0_i, align 1
  ret i8 %flag
}

; CHECK-LABEL: define i8 @global_state_nonptr_arg
; CHECK: %state_0 = alloca i8
; CHECK: store i8 %v, ptr %state_0
; CHECK-NOT: store i8 %v, i8 %v
