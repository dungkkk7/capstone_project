; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-abi-recovery-pass -S %s | FileCheck-21 %s

@__mcsema_reg_state = global [4096 x i8] zeroinitializer

define ptr @sub_404000_leaf(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rdi_ptr = getelementptr i8, ptr %state, i64 2296
  %rax_ptr = getelementptr i8, ptr %state, i64 2216
  %a = load i64, ptr %rdi_ptr, align 8
  %b = add i64 %a, 5
  store i64 %b, ptr %rax_ptr, align 8
  ret ptr %memory
}

; CHECK-LABEL: define i64 @sub_404000_leaf_native
; CHECK: call ptr @sub_404000_leaf(ptr %state_alloca, i64 4210688, ptr %{{.*}})
; CHECK-NOT: call i64 @sub_404000_leaf_native
