@__mcsema_reg_state = global [64 x i8] zeroinitializer
@RSP_0_i = private alias i64, ptr @__mcsema_reg_state

define i32 @guest_stack_forward(i32 %x) {
entry:
  %sp = load i64, ptr @RSP_0_i
  %slot_i = add i64 %sp, -4
  %slot = inttoptr i64 %slot_i to ptr
  store i32 %x, ptr %slot
  %loaded = load i32, ptr %slot
  %y = add i32 %loaded, 7
  ret i32 %y
}

@global_sink = global i32 0

define i32 @guest_stack_forward_across_non_alias(i32 %x, i32 %other) {
entry:
  %sp = load i64, ptr @RSP_0_i
  %slot0_i = add i64 %sp, -4
  %slot0 = inttoptr i64 %slot0_i to ptr
  %slot1_i = add i64 %sp, -8
  %slot1 = inttoptr i64 %slot1_i to ptr
  store i32 %x, ptr %slot0
  store i32 %other, ptr @global_sink
  store i32 %other, ptr %slot1
  %loaded = load i32, ptr %slot0
  %y = add i32 %loaded, 3
  ret i32 %y
}

define i32 @guest_stack_keep_overlap(i64 %wide) {
entry:
  %sp = load i64, ptr @RSP_0_i
  %slot_i = add i64 %sp, -8
  %slot = inttoptr i64 %slot_i to ptr
  store i64 %wide, ptr %slot
  %narrow = load i32, ptr %slot
  ret i32 %narrow
}

define i32 @guest_stack_forward_across_reloaded_rsp(i32 %x) {
entry:
  %sp0 = load i64, ptr @RSP_0_i
  %slot0_i = add i64 %sp0, -4
  %slot0 = inttoptr i64 %slot0_i to ptr
  store i32 %x, ptr %slot0
  %sp1 = load i64, ptr @RSP_0_i
  %slot1_i = add i64 %sp1, -4
  %slot1 = inttoptr i64 %slot1_i to ptr
  %loaded = load i32, ptr %slot1
  ret i32 %loaded
}

define i32 @guest_stack_block_changed_rsp(i32 %x, i64 %new_sp) {
entry:
  %sp0 = load i64, ptr @RSP_0_i
  %slot0_i = add i64 %sp0, -4
  %slot0 = inttoptr i64 %slot0_i to ptr
  store i32 %x, ptr %slot0
  store i64 %new_sp, ptr @RSP_0_i
  %sp1 = load i64, ptr @RSP_0_i
  %slot1_i = add i64 %sp1, -4
  %slot1 = inttoptr i64 %slot1_i to ptr
  %loaded = load i32, ptr %slot1
  ret i32 %loaded
}

; CHECK-LABEL: define i32 @guest_stack_forward
; CHECK: %sp = load i64, ptr @RSP_0_i
; CHECK: %slot_i = add i64 %sp, -4
; CHECK: %slot = inttoptr i64 %slot_i to ptr
; CHECK: store i32 %x, ptr %slot
; CHECK-NOT: load i32, ptr %slot
; CHECK: %y = add i32 %x, 7
; CHECK: ret i32 %y

; CHECK-LABEL: define i32 @guest_stack_forward_across_non_alias
; CHECK: store i32 %x, ptr %slot0
; CHECK: store i32 %other, ptr @global_sink
; CHECK: store i32 %other, ptr %slot1
; CHECK-NOT: load i32, ptr %slot0
; CHECK: %y = add i32 %x, 3
; CHECK: ret i32 %y

; CHECK-LABEL: define i32 @guest_stack_keep_overlap
; CHECK: store i64 %wide, ptr %slot
; CHECK: %narrow = load i32, ptr %slot
; CHECK: ret i32 %narrow

; CHECK-LABEL: define i32 @guest_stack_forward_across_reloaded_rsp
; CHECK: store i32 %x, ptr %slot0
; CHECK-NOT: load i32, ptr %slot1
; CHECK: ret i32 %x

; CHECK-LABEL: define i32 @guest_stack_block_changed_rsp
; CHECK: store i32 %x, ptr %slot0
; CHECK: store i64 %new_sp, ptr @RSP_0_i
; CHECK: %loaded = load i32, ptr %slot1
; CHECK: ret i32 %loaded
