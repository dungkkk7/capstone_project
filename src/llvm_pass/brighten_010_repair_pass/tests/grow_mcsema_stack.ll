; RUN: opt-16 -load-pass-plugin %plugin -passes=refine-semantic-pass -S %s | FileCheck-16 %s

%struct.State = type { [8 x i8] }

@__mcsema_reg_state = global %struct.State zeroinitializer
@__mcsema_stack = internal thread_local(initialexec) global [1048576 x i8] zeroinitializer, align 16
@RSP = alias i64, ptr @__mcsema_reg_state

define ptr @__mcsema_init_reg_state() {
entry:
  store i64 and (i64 ptrtoint (ptr getelementptr inbounds ([1048576 x i8], ptr @__mcsema_stack, i32 0, i32 1048064) to i64), i64 -16), ptr @RSP
  ret ptr @__mcsema_reg_state
}

define ptr @caller() {
entry:
  %state = call ptr @__mcsema_init_reg_state()
  ret ptr %state
}

; CHECK: @__lifter_refine_mcsema_stack = internal global [16777216 x i8] zeroinitializer
; CHECK-LABEL: define internal ptr @__mcsema_init_reg_state
; CHECK: store i64 and (i64 ptrtoint (ptr getelementptr inbounds ([16777216 x i8], ptr @__lifter_refine_mcsema_stack, i32 0, i32 16776704) to i64), i64 -16)
; CHECK-LABEL: define ptr @caller
; CHECK: call ptr @__mcsema_init_reg_state()
