; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-devirt-pass -S %s | FileCheck-21 %s

declare ptr @__remill_function_call(ptr, i64, ptr)

define internal ptr @sub_401000_main(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define ptr @caller(ptr %state, ptr %memory) {
entry:
  %res = call ptr @__remill_function_call(ptr %state, i64 4198400, ptr %memory)
  ret ptr %res
}

; CHECK-LABEL: define ptr @caller
; CHECK: call ptr @sub_401000_main(ptr %state, i64 4198400, ptr %memory)
; CHECK-NOT: call ptr @__remill_function_call
