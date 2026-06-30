; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-stack-frame-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer
@RSP_0_i = alias i64, ptr @__mcsema_reg_state

define void @stack_wide_slot(i128 %v) {
entry:
  %rsp = load i64, ptr @RSP_0_i, align 8
  %slot = sub i64 %rsp, 16
  %ptr = inttoptr i64 %slot to ptr
  store i128 %v, ptr %ptr, align 16
  ret void
}

; CHECK-LABEL: define void @stack_wide_slot
; CHECK: %stack_frame = alloca [16 x i8]
; CHECK: store i128 %v, ptr %frame_ptr
; CHECK-NOT: inttoptr
