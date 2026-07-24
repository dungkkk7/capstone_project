; RUN: opt-21 -load-pass-plugin=%llvmshlibdir/BrightenNativeCleanupPass%shlibext \
; RUN:   -passes='brighten-native-cleanup-pass,verify' -S %s -o - | FileCheck %s

%struct.State = type { i64, i64 }

@__mcsema_reg_state = internal global %struct.State zeroinitializer, align 8

define i32 @main() {
entry:
  store i64 3, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 8), align 8
  call void @helper()
  %value = load i64, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 0), align 8
  %result = trunc i64 %value to i32
  ret i32 %result
}

define internal void @helper() {
entry:
  store i64 9, ptr getelementptr (i8, ptr @__mcsema_reg_state, i64 0), align 8
  ret void
}

; CHECK-NOT: @__mcsema_reg_state
; CHECK-NOT: %struct.State = type
; CHECK: @__native_state_context = internal unnamed_addr global ptr null
; CHECK: %native.register.state = alloca [16 x i8]
; CHECK: store ptr %native.register.state, ptr @__native_state_context
; CHECK-LABEL: define internal void @helper()
; CHECK: %native.register.state.context = load ptr, ptr @__native_state_context
; CHECK: store i64 9, ptr %native.register.state.context
