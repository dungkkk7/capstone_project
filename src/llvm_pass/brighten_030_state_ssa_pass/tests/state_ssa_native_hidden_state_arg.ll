; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-state-ssa-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer

define i64 @sub_401000_native(i64 %a, ptr %memory, ptr %state) {
entry:
  %rax_ptr = getelementptr i8, ptr %state, i64 2216
  store i64 %a, ptr %rax_ptr, align 8
  %v = load i64, ptr %rax_ptr, align 8
  ret i64 %v
}

; CHECK-LABEL: define i64 @sub_401000_native
; CHECK: %state_2216 = alloca i64
; CHECK: getelementptr i8, ptr %state, i64 2216
; CHECK-NOT: getelementptr i8, ptr @__mcsema_reg_state, i64 2216
; CHECK: ret i64
