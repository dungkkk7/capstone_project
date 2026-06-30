; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-stack-frame-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer
@RSP_0_i = alias i64, ptr @__mcsema_reg_state

declare ptr @__translate_guest_pointer(i64, i1)

define void @stack_translate_guest(i64 %v) {
entry:
  %rsp = load i64, ptr @RSP_0_i, align 8
  %slot = sub i64 %rsp, 8
  %ptr = call ptr @__translate_guest_pointer(i64 %slot, i1 false)
  store i64 %v, ptr %ptr, align 8
  ret void
}

; CHECK-LABEL: define void @stack_translate_guest
; CHECK: %stack_frame = alloca [8 x i8]
; CHECK: store i64 %v, ptr %frame_ptr
; CHECK-NOT: __translate_guest_pointer
