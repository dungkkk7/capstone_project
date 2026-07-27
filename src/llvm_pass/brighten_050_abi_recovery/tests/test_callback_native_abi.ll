; A callback adapter with a completely proven register protocol is rewritten
; to call the recovered native body directly. Once that bridge is the final
; user, its local shared State object and identified type disappear too.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

%struct.State = type { [3000 x i8] }

@__mcsema_reg_state = internal global %struct.State zeroinitializer
@RAX_2216 = internal global i64 0
@RSI_2280 = internal global i64 0
@RDI_2296 = internal global i64 0
@callback_slot = global ptr @compar.native_callback

; CHECK-NOT: %struct.State = type
; CHECK-NOT: @__mcsema_reg_state

define ptr @sub_compare(ptr %state, i64 %pc, ptr %memory) {
entry:
  %lhs = load i64, ptr @RDI_2296
  %rhs = load i64, ptr @RSI_2280
  %less = icmp slt i64 %lhs, %rhs
  %result = select i1 %less, i64 -1, i64 1
  store i64 %result, ptr @RAX_2216
  ret ptr %memory
}

define internal ptr @compar_wrapper(ptr %state, i64 %pc, ptr %memory) {
entry:
  %token = call ptr @sub_compare(ptr %state, i64 %pc, ptr %memory)
  %rax.ptr = getelementptr i8, ptr %state, i64 2216
  %result = load i64, ptr %rax.ptr
  ret ptr %token
}

; CHECK-LABEL: define internal i32 @compar.native_callback(ptr %lhs, ptr %rhs)
; CHECK-NEXT: entry:
; CHECK-NOT: @__mcsema_reg_state
; CHECK-NOT: call ptr @compar_wrapper
; CHECK: [[LHS:%.*]] = ptrtoint ptr %lhs to i64
; CHECK: [[RHS:%.*]] = ptrtoint ptr %rhs to i64
; CHECK: [[RET:%.*]] = call i64 @sub_compare.native(ptr null, i64 [[LHS]], i64 [[RHS]])
; CHECK: [[RET32:%.*]] = trunc i64 [[RET]] to i32
; CHECK-NEXT: ret i32 [[RET32]]
define internal i32 @compar.native_callback(ptr %lhs, ptr %rhs) {
entry:
  %lhs.bits = ptrtoint ptr %lhs to i64
  store i64 %lhs.bits, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2296)
  %rhs.bits = ptrtoint ptr %rhs to i64
  store i64 %rhs.bits, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2280)
  %token = call ptr @compar_wrapper(ptr @__mcsema_reg_state, i64 4198400, ptr null)
  %result = load i32, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2216)
  ret i32 %result
}
