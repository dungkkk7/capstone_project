; One dynamic address keeps the whole shared storage transaction fail-closed.
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"

@native_register_storage = internal unnamed_addr global [32 x i8] zeroinitializer, align 8

define i8 @dynamic_state_access(i64 %offset) {
entry:
  %slot = getelementptr i8, ptr @native_register_storage, i64 %offset
  %value = load i8, ptr %slot, align 1
  ret i8 %value
}

; CHECK: @native_register_storage = internal unnamed_addr global [32 x i8] zeroinitializer
; CHECK-NOT: @native_state_slot_
; CHECK-LABEL: define i8 @dynamic_state_access(
; CHECK: %slot = getelementptr i8, ptr @native_register_storage, i64 %offset
