; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-abi-recovery-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer
@fp = global ptr @sub_403000_addr_taken

define ptr @sub_403000_addr_taken(ptr %state, i64 %pc, ptr %memory) {
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
  store i64 %k, ptr %rax_ptr, align 8
  ret ptr %memory
}

; CHECK: @fp = global ptr @sub_403000_addr_taken
; CHECK-LABEL: define internal ptr @sub_403000_addr_taken(
; CHECK-LABEL: define i64 @sub_403000_addr_taken_native(
; CHECK: call ptr @sub_403000_addr_taken(ptr %state_alloca, i64 4206592, ptr %1)
