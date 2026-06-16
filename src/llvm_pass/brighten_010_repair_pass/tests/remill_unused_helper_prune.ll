define ptr @__remill_function_call(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @__remill_function_return(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @__remill_jump(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @__remill_missing_block(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @__remill_async_hyper_call(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @__mcsema_detach_call_value(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @__mcsema_debug_get_reg_state() {
entry:
  ret ptr null
}

define ptr @__remill_error(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @__mcsema_init_reg_state() {
entry:
  ret ptr null
}

define ptr @__remill_live_helper(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @caller(ptr %state, i64 %pc, ptr %memory) {
entry:
  %state0 = call ptr @__mcsema_init_reg_state()
  %next = call ptr @__remill_live_helper(ptr %state, i64 %pc, ptr %memory)
  ret ptr %next
}

; CHECK-NOT: define ptr @__remill_function_call
; CHECK-NOT: define ptr @__remill_function_return
; CHECK-NOT: define ptr @__remill_jump
; CHECK-NOT: define ptr @__remill_missing_block
; CHECK-NOT: define ptr @__remill_async_hyper_call
; CHECK-NOT: define ptr @__mcsema_detach_call_value
; CHECK-NOT: define ptr @__mcsema_debug_get_reg_state
; CHECK-NOT: define ptr @__remill_error
; CHECK-LABEL: define internal ptr @__mcsema_init_reg_state
; CHECK-LABEL: define ptr @__remill_live_helper
; CHECK-LABEL: define ptr @caller
; CHECK: call ptr @__mcsema_init_reg_state()
