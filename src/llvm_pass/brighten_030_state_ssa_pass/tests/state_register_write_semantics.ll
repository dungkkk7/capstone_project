; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-state-ssa-pass,verify -S %s -o - | FileCheck-21 %s
;
; These checks cover architectural x86 register-write semantics rather than
; merely checking that a State load/store disappeared.

target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"

declare void @sink64(i64)

define ptr @sub_eax_zero_ext(ptr %state, i64 %pc, ptr %memory, i32 %v) {
entry:
  %rax = getelementptr i8, ptr %state, i64 2216
  store i64 -1, ptr %rax, align 1
  store i32 %v, ptr %rax, align 1
  %out = load i64, ptr %rax, align 1
  call void @sink64(i64 %out)
  ret ptr %memory
}

; CHECK-LABEL: define ptr @sub_eax_zero_ext(
; CHECK: %state_cell_2216 = alloca i64
; CHECK: %state.gpr32.zero_extend = zext i32 %v to i64
; CHECK: store i64 %state.gpr32.zero_extend, ptr %state_cell_2216
; CHECK-NOT: state.store.keep
; CHECK: call void @sink64

define ptr @sub_ax_merge(ptr %state, i64 %pc, ptr %memory, i16 %v) {
entry:
  %rax = getelementptr i8, ptr %state, i64 2216
  store i64 -1, ptr %rax, align 1
  store i16 %v, ptr %rax, align 1
  %out = load i64, ptr %rax, align 1
  call void @sink64(i64 %out)
  ret ptr %memory
}

; CHECK-LABEL: define ptr @sub_ax_merge(
; CHECK: %state.store.old = load i64, ptr %state_cell_2216
; CHECK: %state.store.keep = and i64 %state.store.old, -65536
; CHECK: %state.store.merge = or i64 %state.store.keep
; CHECK: call void @sink64

define ptr @sub_ah_merge(ptr %state, i64 %pc, ptr %memory, i8 %v) {
entry:
  %rax = getelementptr i8, ptr %state, i64 2216
  %ah = getelementptr i8, ptr %state, i64 2217
  store i64 0, ptr %rax, align 1
  store i8 %v, ptr %ah, align 1
  %out = load i64, ptr %rax, align 1
  call void @sink64(i64 %out)
  ret ptr %memory
}

; CHECK-LABEL: define ptr @sub_ah_merge(
; CHECK: %state_cell_2216 = alloca i64
; CHECK-NOT: state_cell_2217
; CHECK: %state.store.shifted = shl i64 {{.*}}, 8
; CHECK: %state.store.keep = and i64 {{.*}}, -65281
; CHECK: %state.store.merge = or i64 %state.store.keep, %state.store.shifted
; CHECK: call void @sink64
