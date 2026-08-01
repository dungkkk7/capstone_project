; A shared callback register backing with only exact integer accesses is not an
; opaque frame.  Mixed i8/i64 accesses at one offset must remain byte-exact.
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"

@native_register_storage = internal unnamed_addr global [32 x i8] zeroinitializer, align 8

define internal i8 @callback() {
entry:
  %low = load i8, ptr getelementptr (i8, ptr @native_register_storage, i64 8), align 8
  %next = add i8 %low, 1
  store i8 %next, ptr getelementptr (i8, ptr @native_register_storage, i64 8), align 8
  ret i8 %next
}

define i32 @main() {
entry:
  store i64 41, ptr getelementptr (i8, ptr @native_register_storage, i64 8), align 8
  ; This disjoint component has only a partial write.  It must disappear
  ; before scalarization manufactures a load/mask/merge for the i16 store.
  store i16 99, ptr getelementptr (i8, ptr @native_register_storage, i64 24), align 2
  %callback.result = call i8 @callback()
  %whole = load i64, ptr getelementptr (i8, ptr @native_register_storage, i64 8), align 8
  %low.ok = icmp eq i8 %callback.result, 42
  %whole.ok = icmp eq i64 %whole, 42
  %ok = and i1 %low.ok, %whole.ok
  %failed = xor i1 %ok, true
  %status = zext i1 %failed to i32
  ret i32 %status
}

; CHECK-NOT: @native_register_storage
; CHECK: @native_state_slot_8 = internal unnamed_addr global i64 0, align 8
; CHECK-NOT: native_state_slot_24
; CHECK-NOT: store i16 99
; CHECK-LABEL: define internal i8 @callback()
; CHECK: load i64, ptr @native_state_slot_8
; CHECK: trunc i64
; CHECK: and i64
; CHECK: or i64
; CHECK: store i64
; CHECK-LABEL: define i32 @main()
; CHECK: store i64 41, ptr @native_state_slot_8
; CHECK: load i64, ptr @native_state_slot_8
