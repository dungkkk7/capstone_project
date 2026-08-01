; A State flag slot has byte storage, not an i1 value contract.  Preserve a
; raw incoming byte when the PHI's exact value is observable.

@__mcsema_reg_state = global [4096 x i8] zeroinitializer

define ptr @sub_raw_flag_phi(ptr %state, i64 %pc, ptr %memory) {
entry:
  %take.raw = trunc i64 %pc to i1
  br i1 %take.raw, label %raw, label %zero

raw:
  %zf.ptr = getelementptr i8, ptr %state, i64 2071
  %raw.flag = load i8, ptr %zf.ptr
  br label %merge

zero:
  br label %merge

merge:
  %flag.byte = phi i8 [ %raw.flag, %raw ], [ 0, %zero ]
  %observed = zext i8 %flag.byte to i64
  %rax.ptr = getelementptr i8, ptr %state, i64 2216
  store i64 %observed, ptr %rax.ptr
  ret ptr %memory
}

; CHECK-LABEL: define ptr @sub_raw_flag_phi
; CHECK: %flag.byte = phi i8
; CHECK: %observed = zext i8 %flag.byte to i64
