; RUN: opt -load-pass-plugin ../build/BrightenNativeCleanupPass.so \
; RUN:   -passes='brighten-native-cleanup-pass,verify' -S %s | FileCheck %s

%struct.State = type { i64 }
@__mcsema_reg_state = internal global %struct.State zeroinitializer, align 8

define i64 @main(i64 %input) {
entry:
  %slot = getelementptr inbounds %struct.State, ptr @__mcsema_reg_state, i32 0, i32 0
  store i64 %input, ptr %slot, align 8
  %value = load i64, ptr %slot, align 8
  %result = add i64 %value, 1
  ret i64 %result
}

; CHECK-LABEL: define i64 @main(i64 %input)
; CHECK-NOT: @__mcsema_reg_state
; CHECK: %native.register.state = alloca %struct.State
; CHECK: store %struct.State zeroinitializer, ptr %native.register.state
; CHECK: store i64 %input
; CHECK: load i64
