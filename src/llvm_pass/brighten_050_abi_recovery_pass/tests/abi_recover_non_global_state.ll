; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-abi-recovery-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer

define ptr @sub_402000_inc(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rdi_ptr = getelementptr i8, ptr %state, i64 2296
  %rax_ptr = getelementptr i8, ptr %state, i64 2216
  %a = load i64, ptr %rdi_ptr, align 8
  %b = add i64 %a, 1
  %c = xor i64 %b, 0
  %d = add i64 %c, 0
  %e = sub i64 %d, 0
  %f = or i64 %e, 0
  %g = and i64 %f, -1
  %h = add i64 %g, 0
  %i = xor i64 %h, 0
  %j = add i64 %i, 0
  %k = xor i64 %j, 0
  %l = or i64 %k, 0
  store i64 %l, ptr %rax_ptr, align 8
  ret ptr %memory
}

define ptr @caller(ptr %local_state, ptr %memory) {
entry:
  %rdi_ptr = getelementptr i8, ptr %local_state, i64 2296
  store i64 41, ptr %rdi_ptr, align 8
  %out = call ptr @sub_402000_inc(ptr %local_state, i64 4202496, ptr %memory)
  ret ptr %out
}

; CHECK-LABEL: define ptr @caller
; CHECK: call i64 @sub_402000_inc_native
; CHECK-SAME: ptr %memory
; CHECK-LABEL: define i64 @sub_402000_inc_native
; CHECK-SAME: (i64 %0, ptr %1)
; CHECK-NOT: @__mcsema_reg_state
; CHECK: call ptr @sub_402000_inc(ptr %state_alloca, i64 4202496, ptr %1)
; CHECK: ret i64
