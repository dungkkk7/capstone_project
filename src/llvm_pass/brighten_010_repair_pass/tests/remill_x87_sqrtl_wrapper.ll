; RUN: opt-16 -load-pass-plugin %plugin -passes=refine-semantic-pass -S %s | FileCheck-16 %s

@__mcsema_reg_state = global [128 x i8] zeroinitializer
@RSP_0_i = private alias i64, ptr @__mcsema_reg_state
@RAX_0_i = private alias i64, getelementptr (i8, ptr @__mcsema_reg_state, i64 8)
@RDI_0_i = private alias i64, getelementptr (i8, ptr @__mcsema_reg_state, i64 16)
@ST0_0_x87 = private alias x86_fp80, getelementptr (i8, ptr @__mcsema_reg_state, i64 32)
@ST7_0_i = private alias i64, getelementptr (i8, ptr @__mcsema_reg_state, i64 64)

declare i64 @sqrtl(i64)

define internal ptr @ext_4120_sqrtl(ptr %state, i64 %pc, ptr %memory) {
  %sp = load i64, ptr @RSP_0_i
  %after_ret = add i64 %sp, 8
  %bad_arg = load i64, ptr @RDI_0_i
  %bad_ret = call i64 @sqrtl(i64 %bad_arg)
  store i64 %bad_ret, ptr @RAX_0_i
  store i64 %after_ret, ptr @RSP_0_i
  ret ptr %memory
}

; CHECK-LABEL: define internal ptr @ext_4120_sqrtl
; CHECK: [[SP:%[0-9]+]] = load i64, ptr @RSP_0_i{{.*}}
; CHECK: [[AFTER:%[0-9]+]] = add i64 [[SP]], 8
; CHECK: [[ARGP:%[0-9]+]] = inttoptr i64 [[AFTER]] to ptr
; CHECK: [[ARG:%[0-9]+]] = load x86_fp80, ptr [[ARGP]], align 1
; CHECK: [[RES:%[0-9]+]] = call x86_fp80 @llvm.sqrt.f80(x86_fp80 [[ARG]])
; CHECK: store x86_fp80 [[RES]], ptr @ST0_0_x87, align 1
; CHECK: store i64 [[AFTER]], ptr @RSP_0_i{{.*}}
; CHECK-NOT: load i64, ptr @ST7_0_i
; CHECK-NOT: store i64 {{.*}}, ptr @RAX_0_i
