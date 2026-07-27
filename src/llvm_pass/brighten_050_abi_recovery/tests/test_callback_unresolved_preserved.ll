; An unresolved indirect callback bridge is not enough evidence to invent a
; native target or callback signature. Keep its complete compatibility path.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"

%struct.State = type { [3000 x i8] }

@__mcsema_reg_state = internal global %struct.State zeroinitializer
@unknown_bridge = external global ptr
@callback_slot = global ptr @unknown.native_callback

; CHECK: @__mcsema_reg_state = internal global %struct.State zeroinitializer
; CHECK: @unknown_bridge = external global ptr
; CHECK: @callback_slot = global ptr @unknown.native_callback

; CHECK-LABEL: define internal i32 @unknown.native_callback(ptr %lhs, ptr %rhs)
; CHECK-NOT: callback.native.call
; CHECK: store i64 %lhs.bits, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2296)
; CHECK: store i64 %rhs.bits, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2280)
; CHECK: [[BRIDGE:%.*]] = load ptr, ptr @unknown_bridge
; CHECK: call ptr [[BRIDGE]](ptr @__mcsema_reg_state, i64 4198400, ptr null)
; CHECK: load i32, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2216)
define internal i32 @unknown.native_callback(ptr %lhs, ptr %rhs) {
entry:
  %lhs.bits = ptrtoint ptr %lhs to i64
  store i64 %lhs.bits, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2296)
  %rhs.bits = ptrtoint ptr %rhs to i64
  store i64 %rhs.bits, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2280)
  %bridge = load ptr, ptr @unknown_bridge
  %token = call ptr %bridge(ptr @__mcsema_reg_state, i64 4198400, ptr null)
  %result = load i32, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 2216)
  ret i32 %result
}
