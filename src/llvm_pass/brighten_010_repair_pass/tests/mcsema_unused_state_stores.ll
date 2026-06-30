; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [64 x i8] zeroinitializer
@ZF_0_i = private alias i8, ptr @__mcsema_reg_state
@SF_0_i = private alias i8, ptr @__mcsema_reg_state
@RIP_8_i = private alias i64, getelementptr inbounds ([64 x i8], ptr @__mcsema_reg_state, i64 0, i64 8)

declare void @opaque_use(ptr)

define void @prune_unused_flag_and_rip(i8 %flag, i64 %pc) {
entry:
  store i8 %flag, ptr @ZF_0_i
  %flag2 = xor i8 %flag, 1
  store i8 %flag2, ptr @ZF_0_i
  store i64 %pc, ptr @RIP_8_i
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
; CHECK: %flag2 = xor i8 %flag, 1
; CHECK: store i8 %flag2, ptr @__mcsema_reg_state
; CHECK: ret void

; CHECK-LABEL: define void @keep_escaped_flag
; CHECK: store i8 %flag, ptr @__mcsema_reg_state
; CHECK: call void @opaque_use(ptr @__mcsema_reg_state)
; CHECK: ret void

; CHECK-LABEL: define void @keep_cross_function_writer
; CHECK: store i8 %flag, ptr @__mcsema_reg_state
; CHECK: ret void

; CHECK-LABEL: define i8 @cross_function_reader
; CHECK: %flag = load i8, ptr @__mcsema_reg_state
; CHECK: ret i8 %flag
