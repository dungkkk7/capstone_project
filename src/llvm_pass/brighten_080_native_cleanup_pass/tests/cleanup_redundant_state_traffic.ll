; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

define i64 @sub_401000_add_native(i64 %a, i64 %b, ptr %memory) {
entry:
  %sum = add i64 %a, %b
  ret i64 %sum
}

define ptr @caller(ptr %state, ptr %memory) {
entry:
  %rsi_ptr = getelementptr i8, ptr %state, i64 2280
  %rbp_ptr = getelementptr i8, ptr %state, i64 2328
  %saved_rbp = load i64, ptr %rbp_ptr, align 4
  %rdi_ptr = getelementptr i8, ptr %state, i64 2296
  store i64 9, ptr %rsi_ptr, align 4
  store i64 %saved_rbp, ptr %rbp_ptr, align 4
  store i64 7, ptr %rdi_ptr, align 4
  %native_ret = call i64 @sub_401000_add_native(i64 7, i64 9, ptr poison)
  %rax_ptr = getelementptr i8, ptr %state, i64 2216
  store i64 %native_ret, ptr %rax_ptr, align 8
  %rdi_after = load i64, ptr %rdi_ptr, align 4
  store i64 %rdi_after, ptr %rdi_ptr, align 4
  store i64 %saved_rbp, ptr %rbp_ptr, align 4
  ret ptr %memory
}

; CHECK-LABEL: define ptr @caller(ptr %state, ptr %memory) {
; CHECK-NOT: saved_rbp
; CHECK-NOT: rdi_after
; CHECK: %rsi_ptr = getelementptr i8, ptr %state, i64 2280
; CHECK: %rdi_ptr = getelementptr i8, ptr %state, i64 2296
; CHECK: store i64 9, ptr %rsi_ptr, align 4
; CHECK: store i64 7, ptr %rdi_ptr, align 4
; CHECK: %native_ret = call i64 @sub_401000_add_native(i64 7, i64 9, ptr poison)
; CHECK: %rax_ptr = getelementptr i8, ptr %state, i64 2216
; CHECK: store i64 %native_ret, ptr %rax_ptr, align 8
; CHECK: ret ptr %memory
