; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer
@dead_alias = alias [4096 x i8], ptr @__mcsema_reg_state

define ptr @__remill_function_call(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define void @keep() {
entry:
  ret void
}

; CHECK-LABEL: define void @keep
; CHECK-NOT: @__mcsema_reg_state
; CHECK-NOT: @dead_alias
; CHECK-NOT: @__remill_function_call
