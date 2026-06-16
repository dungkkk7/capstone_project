@__mcsema_reg_state = global [64 x i8] zeroinitializer
@ZF_0_i = private alias i8, ptr @__mcsema_reg_state

define i1 @flag_load_forward(i8 %v) {
entry:
  store i8 %v, ptr @ZF_0_i
  %flag = load i8, ptr @ZF_0_i
  %cond = icmp ne i8 %flag, 0
  ret i1 %cond
}

; CHECK-LABEL: define i1 @flag_load_forward
; CHECK-NOT: store i8
; CHECK-NOT: load i8, ptr @ZF_0_i
; CHECK: %cond = icmp ne i8 %v, 0
; CHECK: ret i1 %cond
