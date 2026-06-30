; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-stack-frame-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer
@RSP_0_i = alias i64, ptr @__mcsema_reg_state

define void @stack_gep_wide_slot(i64 %v) {
entry:
  %rsp = load i64, ptr @RSP_0_i, align 8
  %base_i = sub i64 %rsp, 16
  %base_p = inttoptr i64 %base_i to ptr
  %field_p = getelementptr i8, ptr %base_p, i64 8
  store i64 %v, ptr %field_p, align 8
  ret void
}

; CHECK-LABEL: define void @stack_gep_wide_slot
; CHECK: %stack_frame = alloca [16 x i8]
; CHECK: %field_p = getelementptr i8, ptr %frame_ptr, i64 8
; CHECK: store i64 %v, ptr %field_p
; CHECK-NOT: inttoptr
