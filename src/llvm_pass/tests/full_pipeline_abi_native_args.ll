@__mcsema_reg_state = global [4096 x i8] zeroinitializer

define ptr @sub_401000_add(ptr %state, i64 %pc, ptr %memory) {
entry:
  %rdi_ptr = getelementptr i8, ptr %state, i64 2296
  %rsi_ptr = getelementptr i8, ptr %state, i64 2280
  %rax_ptr = getelementptr i8, ptr %state, i64 2216
  %a = load i64, ptr %rdi_ptr, align 8
  %b = load i64, ptr %rsi_ptr, align 8
  %sum = add i64 %a, %b
  store i64 %sum, ptr %rax_ptr, align 8
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

; CHECK-LABEL: define ptr @caller(ptr %state, ptr %memory) {
; CHECK-NOT: state_init
; CHECK: store i64 9
; CHECK: store i64 7
; CHECK: call i64 @sub_401000_add_native(i64 7, i64 9)
; CHECK-NOT: ptr poison
; CHECK-LABEL: define internal i64 @sub_401000_add_native(i64 %0, i64 %1) {
; CHECK: ret i64
