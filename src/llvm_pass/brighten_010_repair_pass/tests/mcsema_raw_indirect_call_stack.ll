; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [64 x i8] zeroinitializer
@RSP_0_i = private alias i64, ptr @__mcsema_reg_state
@callee_bits = global i64 0

define internal ptr @sub_raw_indirect(ptr %state, i64 %pc, ptr %memory) {
entry:
  %old_sp = load i64, ptr @RSP_0_i
  %new_sp = add i64 %old_sp, -8
  %ret_slot = inttoptr i64 %new_sp to ptr
  store i64 4660, ptr %ret_slot
  %target = load i64, ptr @callee_bits
  %callee = inttoptr i64 %target to ptr
  %ret = call i64 %callee(i64 1, i64 2, i64 3, i64 4, i64 5, i64 6, i64 7, i64 8)
  store i64 %old_sp, ptr @RSP_0_i
  ret ptr %memory
}

; CHECK-LABEL: define internal ptr @sub_raw_indirect
; CHECK: [[OLD:%[A-Za-z0-9_.]+]] = load i64, ptr {{@RSP_0_i|@__mcsema_reg_state}}
; CHECK: [[NEW:%[A-Za-z0-9_.]+]] = add i64 [[OLD]], -8
; CHECK: store i64 4660, ptr
; CHECK: [[TARGET:%[A-Za-z0-9_.]+]] = load i64, ptr @callee_bits
; CHECK: [[CALLEE:%[A-Za-z0-9_.]+]] = call ptr @__translate_guest_pointer(i64 [[TARGET]], i1 false)
; CHECK: store i64 [[NEW]], ptr {{@RSP_0_i|@__mcsema_reg_state}}
; CHECK: call i64 {{.*}}[[CALLEE]]
; CHECK: store i64 [[OLD]], ptr {{@RSP_0_i|@__mcsema_reg_state}}
