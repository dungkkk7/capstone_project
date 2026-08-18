@__mcsema_reg_state = global [64 x i8] zeroinitializer
@RAX_0_i = private alias i64, ptr @__mcsema_reg_state
@RBX_0_i = private alias i64, ptr @__mcsema_reg_state
@RSP_8_i = private alias i64, getelementptr inbounds ([64 x i8], ptr @__mcsema_reg_state, i64 0, i64 8)

define i64 @state_load_forward(i64 %x) {
entry:
  store i64 %x, ptr @RBX_0_i
  %rbx = load i64, ptr @RBX_0_i
  %y = add i64 %rbx, 7
  ret i64 %y
}

define i64 @state_load_keep_across_unknown_store(i64 %x, ptr %p) {
entry:
  store i64 %x, ptr @RBX_0_i
  store i64 123, ptr %p
  %rbx = load i64, ptr @RBX_0_i
  ret i64 %rbx
}

define i64 @state_load_keep_across_guest_stack_store(i64 %x) {
entry:
  %sp = load i64, ptr @RSP_8_i
  %slot_i = add i64 %sp, -8
  %slot = inttoptr i64 %slot_i to ptr
  store i64 %x, ptr @RBX_0_i
  store i64 123, ptr %slot
  %rbx = load i64, ptr @RBX_0_i
  ret i64 %rbx
}

define i64 @state_load_keep_rax(i64 %x) {
entry:
  store i64 %x, ptr @RAX_0_i
  %rax = load i64, ptr @RAX_0_i
  %y = add i64 %rax, 7
  ret i64 %y
}

; CHECK-LABEL: define i64 @state_load_forward
; CHECK: store i64 %x, ptr @RBX_0_i
; CHECK-NOT: load i64, ptr @RBX_0_i
; CHECK: %y = add i64 %x, 7
; CHECK: ret i64 %y

; CHECK-LABEL: define i64 @state_load_keep_across_unknown_store
; CHECK: store i64 %x, ptr @RBX_0_i
; CHECK: store i64 123, ptr %p
; CHECK: %rbx = load i64, ptr @RBX_0_i
; CHECK: ret i64 %rbx

; CHECK-LABEL: define i64 @state_load_keep_across_guest_stack_store
; CHECK: store i64 %x, ptr @RBX_0_i
; CHECK: store i64 123, ptr %slot
; CHECK: %rbx = load i64, ptr @RBX_0_i
; CHECK: ret i64 %rbx

; CHECK-LABEL: define i64 @state_load_keep_rax
; CHECK: store i64 %x, ptr @RAX_0_i
; CHECK: %rax = load i64, ptr @RAX_0_i
; CHECK: %y = add i64 %rax, 7
