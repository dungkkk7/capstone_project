; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-stack-frame-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer
@RSP_0_ptr = alias ptr, ptr @__mcsema_reg_state

define void @stack_pointer_type(i64 %v) {
entry:
  %rsp = load ptr, ptr @RSP_0_ptr, align 8
  %ptr = getelementptr i64, ptr %rsp, i32 -1
  store i64 %v, ptr %ptr, align 8
  ret void
}

; CHECK-LABEL: define void @stack_pointer_type
; CHECK: %stack_frame = alloca [16 x i8]
; CHECK: store i64 %v, ptr %ptr
; CHECK-NOT: load ptr, ptr @RSP_0_ptr
