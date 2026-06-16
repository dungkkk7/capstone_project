@__mcsema_reg_state = global [64 x i8] zeroinitializer
@ZF_0_i = private alias i8, ptr @__mcsema_reg_state

define i8 @dead_flag_store(i8 %v) {
entry:
  store i8 0, ptr @ZF_0_i
  store i8 %v, ptr @ZF_0_i
  %flag = load i8, ptr @ZF_0_i
  ret i8 %flag
}

; CHECK-LABEL: define i8 @dead_flag_store
; CHECK-NOT: store i8 0, ptr @ZF_0_i
; CHECK-NOT: store i8 %v, ptr @ZF_0_i
; CHECK-NOT: load i8, ptr @ZF_0_i
; CHECK: ret i8 %v
