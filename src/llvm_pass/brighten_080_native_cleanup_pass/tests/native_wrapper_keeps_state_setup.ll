; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-native-cleanup-pass -S %s | FileCheck-21 %s

define ptr @sub_402000(ptr %state, i64 %pc, ptr %memory) {
entry:
  ret ptr %memory
}

define i64 @sub_402000_native(i64 %a, ptr %memory) {
entry:
  %state = alloca [64 x i8], align 16
  %rax_ptr = getelementptr i8, ptr %state, i64 8
  store i64 %a, ptr %rax_ptr, align 8
  %res = call ptr @sub_402000(ptr %state, i64 4202496, ptr %memory)
  ret i64 %a
}

; CHECK-LABEL: define internal i64 @sub_402000_native
; CHECK: store i64 %a, ptr %rax_ptr, align 8
; CHECK: call ptr @sub_402000(ptr %state, i64 4202496, ptr %memory)
