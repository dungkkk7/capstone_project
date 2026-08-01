; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

%struct.State = type { [8 x i8] }

@__mcsema_reg_state = global %struct.State zeroinitializer
@__mcsema_stack = internal thread_local(initialexec) global [1048576 x i8] zeroinitializer, align 16
@RSP = alias i64, ptr @__mcsema_reg_state

define ptr @__mcsema_init_reg_state() {
entry:
  %stack.top = ptrtoint ptr getelementptr inbounds ([1048576 x i8], ptr @__mcsema_stack, i32 0, i32 1048064) to i64
  %stack.aligned = and i64 %stack.top, -16
  store i64 %stack.aligned, ptr @RSP
  ret ptr @__mcsema_reg_state
}

define ptr @caller() {
entry:
  %state = call ptr @__mcsema_init_reg_state()
  ret ptr %state
}

; CHECK: @__lifter_refine_mcsema_stack = internal global [16777216 x i8] zeroinitializer
; CHECK-LABEL: define internal ptr @__mcsema_init_reg_state
; CHECK: %stack.top = ptrtoint ptr getelementptr inbounds ([16777216 x i8], ptr @__lifter_refine_mcsema_stack, i32 0, i32 16776704) to i64
; CHECK: %stack.aligned = and i64 %stack.top, -16
; CHECK: store i64 %stack.aligned, ptr @RSP
; CHECK-LABEL: define ptr @caller
; CHECK: call ptr @__mcsema_init_reg_state()
