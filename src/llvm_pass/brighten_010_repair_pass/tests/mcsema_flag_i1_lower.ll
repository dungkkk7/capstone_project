@__mcsema_reg_state = global [64 x i8] zeroinitializer
@ZF_0_i = private alias i8, ptr @__mcsema_reg_state

define i1 @flag_i1_lower(i8 %v) {
entry:
  store i8 %v, ptr @ZF_0_i
  %flag = load i1, ptr @ZF_0_i
  ret i1 %flag
}

; CHECK-LABEL: define i1 @flag_i1_lower
; CHECK-NOT: store i8
; CHECK-NOT: load i1
; CHECK: %0 = icmp ne i8 %v, 0
; CHECK: ret i1 %0
