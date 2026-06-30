; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

declare ptr @__remill_function_call(ptr, i64, ptr)

define internal ptr @sub_1170(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @caller(ptr %state, ptr %memory) {
entry:
  %out = call ptr @__remill_function_call(ptr %state, i64 4464, ptr %memory)
  ret ptr %out
}

; CHECK-LABEL: define ptr @caller(ptr %state, ptr %memory) {
; CHECK-NOT: call ptr @__remill_function_call
; CHECK: call ptr @sub_1170(ptr %state, i64 4464, ptr %memory)
; CHECK: ret ptr
