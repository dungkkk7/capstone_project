@__mcsema_reg_state = global [4096 x i8] zeroinitializer

define ptr @sub_flag_volatile(ptr %state, i64 %pc, ptr %memory) {
entry:
  %zf = getelementptr i8, ptr %state, i64 2071
  store i8 1, ptr %zf
  store volatile i8 0, ptr %zf
  %observed = load i8, ptr %zf
  %use = zext i8 %observed to i64
  %rax = getelementptr i8, ptr %state, i64 2216
  store i64 %use, ptr %rax
  ret ptr %memory
}

define ptr @sub_flag_external_observer(ptr %state, i64 %pc, ptr %memory) {
entry:
  %cf = getelementptr i8, ptr %state, i64 2065
  store i8 1, ptr %cf
  ret ptr %memory
}

; CHECK-LABEL: define ptr @sub_flag_volatile
; CHECK: store volatile i8 0
; CHECK: %observed = load i8
; CHECK-LABEL: define ptr @sub_flag_external_observer
; CHECK: store i8 1

