; RUN: opt-16 -load-pass-plugin %plugin -passes=refine-semantic-pass -S %s | FileCheck-16 %s

@__mcsema_reg_state = global [128 x i8] zeroinitializer
@ST0_2488_payload = private alias double, getelementptr (i8, ptr @__mcsema_reg_state, i64 8)
@ST0_2488_bits = private alias i64, getelementptr (i8, ptr @__mcsema_reg_state, i64 8)
@ST0_2486_x87 = private alias x86_fp80, getelementptr (i8, ptr @__mcsema_reg_state, i64 6)
@ST1_2504_payload = private alias double, getelementptr (i8, ptr @__mcsema_reg_state, i64 24)
@ST1_2504_bits = private alias i64, getelementptr (i8, ptr @__mcsema_reg_state, i64 24)
@ST1_2502_payload = private alias double, getelementptr (i8, ptr @__mcsema_reg_state, i64 22)
@ST1_2502_x87 = private alias x86_fp80, getelementptr (i8, ptr @__mcsema_reg_state, i64 22)
@ST2_2520_payload = private alias double, getelementptr (i8, ptr @__mcsema_reg_state, i64 40)
@ST2_2520_bits = private alias i64, getelementptr (i8, ptr @__mcsema_reg_state, i64 40)
@ST2_2518_x87 = private alias x86_fp80, getelementptr (i8, ptr @__mcsema_reg_state, i64 38)

declare i32 @fesetround(i32)

define double @use_pseudo_st0(double %x) {
entry:
  store double %x, ptr @ST0_2488_payload
  %raw = load x86_fp80, ptr @ST0_2486_x87
  %as_double = fptrunc x86_fp80 %raw to double
  ret double %as_double
}

; CHECK-LABEL: define double @use_pseudo_st0
; CHECK-NOT: load x86_fp80
; CHECK-NOT: fptrunc
; CHECK: ret double %x

define double @use_bitcast_st1(double %x) {
entry:
  %bits = bitcast double %x to i64
  store i64 %bits, ptr @ST1_2504_bits
  %raw = load x86_fp80, ptr @ST1_2502_x87
  %as_double = fptrunc x86_fp80 %raw to double
  ret double %as_double
}

; CHECK-LABEL: define double @use_bitcast_st1
; CHECK-NOT: load x86_fp80
; CHECK-NOT: fptrunc
; CHECK: ret double %x

define double @move_st1_to_st0(double %x) {
entry:
  store double %x, ptr @ST1_2504_payload
  %bits = load i64, ptr @ST1_2504_bits
  store i64 %bits, ptr @ST0_2488_bits
  %round = call i32 @fesetround(i32 0)
  %raw = load x86_fp80, ptr @ST0_2486_x87
  %as_double = fptrunc x86_fp80 %raw to double
  ret double %as_double
}

; CHECK-LABEL: define double @move_st1_to_st0
; CHECK-NOT: load x86_fp80
; CHECK-NOT: fptrunc
; CHECK: ret double %x

define double @merge_through_rounding_switch(double %x, i32 %sel) {
entry:
  store double %x, ptr @ST1_2504_payload
  %bits = load i64, ptr @ST1_2504_bits
  store i64 %bits, ptr @ST0_2488_bits
  switch i32 %sel, label %a [ i32 1, label %b ]
a:
  br label %merge
b:
  br label %merge
merge:
  %round = call i32 @fesetround(i32 0)
  %raw = load x86_fp80, ptr @ST0_2486_x87
  %as_double = fptrunc x86_fp80 %raw to double
  ret double %as_double
}

; CHECK-LABEL: define double @merge_through_rounding_switch
; CHECK-NOT: load x86_fp80
; CHECK-NOT: fptrunc
; CHECK: ret double %x

define double @push_st0_exposes_old_value_in_st1(double %old, double %new) {
entry:
  store double %old, ptr @ST0_2488_payload
  store double %new, ptr @ST0_2488_payload
  %raw = load x86_fp80, ptr @ST1_2502_x87
  %as_double = fptrunc x86_fp80 %raw to double
  ret double %as_double
}

; CHECK-LABEL: define double @push_st0_exposes_old_value_in_st1
; CHECK-NOT: load x86_fp80
; CHECK-NOT: fptrunc
; CHECK: ret double %old

define double @faddp_st1_st0_pops_result_to_st0(double %i, double %root) {
entry:
  store double %i, ptr @ST0_2488_payload
  %i_bits = load i64, ptr @ST0_2488_bits
  store i64 %i_bits, ptr @ST2_2520_bits
  %root_bits = bitcast double %root to i64
  store i64 %root_bits, ptr @ST1_2504_bits
  store double 1.000000e+00, ptr @ST0_2488_payload
  %lhs_raw = load x86_fp80, ptr @ST1_2502_x87
  %lhs = fptrunc x86_fp80 %lhs_raw to double
  %rhs_raw = load x86_fp80, ptr @ST0_2486_x87
  %rhs = fptrunc x86_fp80 %rhs_raw to double
  %sum = fadd double %lhs, %rhs
  store double %sum, ptr @ST1_2502_payload
  %cmp0_raw = load x86_fp80, ptr @ST0_2486_x87
  %cmp0 = fptrunc x86_fp80 %cmp0_raw to double
  %cmp1_raw = load x86_fp80, ptr @ST1_2502_x87
  %cmp1 = fptrunc x86_fp80 %cmp1_raw to double
  %ret = fsub double %cmp0, %cmp1
  ret double %ret
}

; CHECK-LABEL: define double @faddp_st1_st0_pops_result_to_st0
; CHECK-NOT: load x86_fp80
; CHECK-NOT: fptrunc
; CHECK: [[SUM:%[A-Za-z0-9_.]+]] = fadd double %root, 1.000000e+00
; CHECK: [[RET:%[A-Za-z0-9_.]+]] = fsub double [[SUM]], %i
; CHECK: ret double [[RET]]

define double @faddp_preserves_logical_raw_st1(double %root) {
entry:
  %old_bits = load i64, ptr @ST0_2488_bits
  store i64 %old_bits, ptr @ST2_2520_bits
  %root_bits = bitcast double %root to i64
  store i64 %root_bits, ptr @ST1_2504_bits
  store double 1.000000e+00, ptr @ST0_2488_payload
  %lhs_raw = load x86_fp80, ptr @ST1_2502_x87
  %lhs = fptrunc x86_fp80 %lhs_raw to double
  %rhs_raw = load x86_fp80, ptr @ST0_2486_x87
  %rhs = fptrunc x86_fp80 %rhs_raw to double
  %sum = fadd double %lhs, %rhs
  store double %sum, ptr @ST1_2502_payload
  %phys0 = load i64, ptr @ST0_2488_bits
  %phys1 = load i64, ptr @ST1_2504_bits
  %cmp1_raw = load x86_fp80, ptr @ST1_2502_x87
  %cmp1 = fptrunc x86_fp80 %cmp1_raw to double
  %ret = fsub double %sum, %cmp1
  ret double %ret
}

; CHECK-LABEL: define double @faddp_preserves_logical_raw_st1
; CHECK-NOT: load x86_fp80
; CHECK-NOT: fptrunc
; CHECK: [[SUM2:%[A-Za-z0-9_.]+]] = fadd double %root, 1.000000e+00
; CHECK: [[OLD:%[A-Za-z0-9_.]+]] = bitcast i64 %old_bits to double
; CHECK: [[RET2:%[A-Za-z0-9_.]+]] = fsub double [[SUM2]], [[OLD]]
; CHECK: ret double [[RET2]]

define double @faddp_result_survives_raw_pop_shift(double %root) {
entry:
  %old_bits = load i64, ptr @ST0_2488_bits
  store i64 %old_bits, ptr @ST2_2520_bits
  %root_bits = bitcast double %root to i64
  store i64 %root_bits, ptr @ST1_2504_bits
  store double 1.000000e+00, ptr @ST0_2488_payload
  %lhs_raw = load x86_fp80, ptr @ST1_2502_x87
  %lhs = fptrunc x86_fp80 %lhs_raw to double
  %rhs_raw = load x86_fp80, ptr @ST0_2486_x87
  %rhs = fptrunc x86_fp80 %rhs_raw to double
  %sum = fadd double %lhs, %rhs
  store double %sum, ptr @ST1_2502_payload
  %phys1 = load i64, ptr @ST1_2504_bits
  store i64 %phys1, ptr @ST0_2488_bits
  %phys2 = load i64, ptr @ST2_2520_bits
  store i64 %phys2, ptr @ST1_2504_bits
  %top_raw = load x86_fp80, ptr @ST0_2486_x87
  %top = fptrunc x86_fp80 %top_raw to double
  ret double %top
}

; CHECK-LABEL: define double @faddp_result_survives_raw_pop_shift
; CHECK-NOT: load x86_fp80
; CHECK-NOT: fptrunc
; CHECK: [[SUM3:%[A-Za-z0-9_.]+]] = fadd double %root, 1.000000e+00
; CHECK: ret double [[SUM3]]

define double @merge_distinct_st0_values_uses_phi(double %pos, double %neg, i1 %is_neg) {
entry:
  br i1 %is_neg, label %neg_path, label %pos_path

pos_path:
  store double %pos, ptr @ST0_2488_payload
  br label %join

neg_path:
  store double %neg, ptr @ST0_2488_payload
  br label %join

join:
  %raw = load x86_fp80, ptr @ST0_2486_x87
  %as_double = fptrunc x86_fp80 %raw to double
  ret double %as_double
}

; CHECK-LABEL: define double @merge_distinct_st0_values_uses_phi
; CHECK-NOT: load x86_fp80
; CHECK-NOT: fptrunc
; CHECK: [[PHI:%[A-Za-z0-9_.]+]] = phi double [ %neg, %neg_path ], [ %pos, %pos_path ]
; CHECK: ret double [[PHI]]
