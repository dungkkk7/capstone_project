; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-abi-recovery-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer

define ptr @sub_401000_add(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rdi_ptr = getelementptr i8, ptr %state, i64 2296
  %rsi_ptr = getelementptr i8, ptr %state, i64 2280
  %rax_ptr = getelementptr i8, ptr %state, i64 2216
  %a = load i64, ptr %rdi_ptr, align 8
  %b = load i64, ptr %rsi_ptr, align 8
  %s0 = add i64 %a, %b
  %s1 = xor i64 %s0, 0
  %s2 = add i64 %s1, 0
  %s3 = sub i64 %s2, 0
  %s4 = or i64 %s3, 0
  %s5 = and i64 %s4, -1
  %s6 = add i64 %s5, 0
  %s7 = xor i64 %s6, 0
  store i64 %s7, ptr %rax_ptr, align 8
  ret ptr %memory
}

define ptr @caller(ptr %state, ptr %memory) {
entry:
  %rdi_ptr = getelementptr i8, ptr %state, i64 2296
  %rsi_ptr = getelementptr i8, ptr %state, i64 2280
  store i64 7, ptr %rdi_ptr, align 8
  store i64 9, ptr %rsi_ptr, align 8
  %out = call ptr @sub_401000_add(ptr %state, i64 4198400, ptr %memory)
  ret ptr %out
}

; CHECK-LABEL: define internal ptr @sub_401000_add(
; CHECK-LABEL: define ptr @caller
; CHECK: call i64 @sub_401000_add_native
; CHECK-SAME: i64 %1
; CHECK-SAME: i64 %3
; CHECK-SAME: ptr %memory
; CHECK-LABEL: define i64 @sub_401000_add_native
; CHECK-SAME: (i64
; CHECK-SAME: i64
; CHECK-SAME: ptr %2
; CHECK: call ptr @sub_401000_add(ptr %state_alloca, i64 4198400, ptr %2)
; CHECK: ret i64
