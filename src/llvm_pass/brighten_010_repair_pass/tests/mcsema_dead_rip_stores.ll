@__mcsema_reg_state = global [64 x i8] zeroinitializer
@RIP_0_i = private alias i64, ptr @__mcsema_reg_state

define void @dead_rip_store() {
entry:
  store i64 4096, ptr @RIP_0_i
  store i64 4100, ptr @RIP_0_i
  ret void
}

; CHECK-LABEL: define void @dead_rip_store
; CHECK-NOT: store i64 4096, ptr @RIP_0_i
; CHECK-NOT: store i64 4100, ptr @RIP_0_i
; CHECK: ret void
