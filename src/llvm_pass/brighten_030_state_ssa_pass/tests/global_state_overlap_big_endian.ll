target datalayout = "E-m:e-p:64:64-i64:64-n8:16:32:64-S128"

define ptr @sub_big_overlap(ptr %state, i64 %pc, ptr %memory) {
entry:
  %wide = getelementptr i8, ptr %state, i64 100
  store i64 1234605616436508552, ptr %wide, align 1
  %partial = getelementptr i8, ptr %state, i64 102
  store i16 -21829, ptr %partial, align 1
  %partial.value = load i16, ptr %partial, align 1
  %result = load i64, ptr %wide, align 1
  ret ptr %memory
}

; CHECK-LABEL: define ptr @sub_big_overlap
; CHECK: %state_100 = alloca i64
; CHECK: or i64 {{.*}}, 187720135606272
; CHECK: lshr i64 {{.*}}, 32
