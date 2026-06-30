; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-devirt-pass -S %s | FileCheck-21 %s

declare ptr @__remill_function_return(ptr, i64, ptr)

define ptr @callee_return(ptr %state, i64 %pc, ptr %memory) {
entry:
  %res = call ptr @__remill_function_return(ptr %state, i64 %pc, ptr %memory)
  %dead = getelementptr i8, ptr %res, i64 8
  ret ptr %dead
}

; CHECK-LABEL: define ptr @callee_return
; CHECK: ret ptr %memory
; CHECK-NOT: __remill_function_return
; CHECK-NOT: getelementptr
