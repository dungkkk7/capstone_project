; RUN: opt-16 -load-pass-plugin %plugin -passes=refine-semantic-pass -S %s | FileCheck-16 %s

%struct.State = type { [64 x i8] }

@__mcsema_reg_state = global %struct.State zeroinitializer
@fmt_obj = internal constant [4 x i8] c"%f\0A\00"
@fmt = internal alias i8, ptr @fmt_obj
@RDI_0_p = private alias ptr, ptr @__mcsema_reg_state
@RSP_0_i = private alias i64, ptr @__mcsema_reg_state
@RAX_0_i = private alias i64, ptr @__mcsema_reg_state
@XMM0_0_d = private alias double, ptr @__mcsema_reg_state

declare i32 @printf(ptr, ...)

define internal ptr @ext_4010_printf(ptr %state, i64 %pc, ptr %memory) {
  %fmt_runtime = load ptr, ptr @RDI_0_p
  %ret = call i32 (ptr, ...) @printf(ptr %fmt_runtime, i64 0)
  %ret64 = zext i32 %ret to i64
  store i64 %ret64, ptr @RAX_0_i
  ret ptr %memory
}

define ptr @sub_1000(ptr %state, i64 %pc, ptr %memory) {
entry:
  store double 6.250000e-01, ptr @XMM0_0_d
  store ptr @fmt, ptr @RDI_0_p
  %out = call ptr @ext_4010_printf(ptr %state, i64 undef, ptr %memory)
  ret ptr %out
}

; CHECK-LABEL: define ptr @sub_1000
; CHECK: [[FP:%[0-9]+]] = load double, ptr @XMM0_0_d
; CHECK: call i32 (ptr, ...) @printf(ptr @fmt, double [[FP]])
; CHECK-NOT: call ptr @ext_4010_printf
