@__mcsema_reg_state = global [128 x i8] zeroinitializer
@CF_0_i = private alias i8, ptr @__mcsema_reg_state
@ZF_0_i = private alias i8, ptr @__mcsema_reg_state
@SF_0_i = private alias i8, ptr @__mcsema_reg_state
@RIP_0_i = private alias i64, ptr @__mcsema_reg_state

declare void @opaque_use(ptr)

define void @prune_unused_flag_and_rip(i8 %flag, i64 %pc) {
entry:
  %flag2 = xor i8 %flag, 1
  store i8 %flag2, ptr @CF_0_i
  %pc2 = add i64 %pc, 4
  store i64 %pc2, ptr @RIP_0_i
  ret void
}

define void @keep_escaped_flag(i8 %flag) {
entry:
  store i8 %flag, ptr @ZF_0_i
  call void @opaque_use(ptr @ZF_0_i)
  ret void
}

define void @keep_cross_function_writer(i8 %flag) {
entry:
  store i8 %flag, ptr @SF_0_i
  ret void
}

define i8 @cross_function_reader() {
entry:
  %flag = load i8, ptr @SF_0_i
  ret i8 %flag
}

; CHECK-LABEL: define void @prune_unused_flag_and_rip
; CHECK-NOT: xor i8
; CHECK-NOT: add i64
; CHECK-NOT: store i8
; CHECK-NOT: store i64
; CHECK: ret void

; CHECK-LABEL: define void @keep_escaped_flag
; CHECK: store i8 %flag, ptr @ZF_0_i
; CHECK: call void @opaque_use(ptr @ZF_0_i)
; CHECK: ret void

; CHECK-LABEL: define void @keep_cross_function_writer
; CHECK: store i8 %flag, ptr @SF_0_i
; CHECK: ret void

; CHECK-LABEL: define i8 @cross_function_reader
; CHECK: %flag = load i8, ptr @SF_0_i
; CHECK: ret i8 %flag
