; A stale vector hint on pointer-backed State storage is not proof that the
; function returns a 128-bit XMM value.  Selecting that ABI would create a
; vector native signature whose original pointer return cannot be rewritten.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@__mcsema_reg_state = internal global [3376 x i8] zeroinitializer

define ptr @sub_pointer_hint(ptr %state, i64 %pc, ptr %memory) {
entry:
  %stale.xmm0 = alloca ptr, align 8, !brighten.state.abi_type !0
  store ptr %memory, ptr %stale.xmm0, align 8
  %value = load ptr, ptr %stale.xmm0, align 8
  %xmm0 = getelementptr i8, ptr %state, i64 16
  store ptr %value, ptr %xmm0, align 8
  ret ptr %memory
}

define void @observe_pointer_hint() {
entry:
  %memory = call ptr @sub_pointer_hint(
      ptr @__mcsema_reg_state, i64 0, ptr null)
  %xmm0 = getelementptr i8, ptr @__mcsema_reg_state, i64 16
  %observed = load <2 x double>, ptr %xmm0, align 16
  call void @consume_vector(<2 x double> %observed)
  ret void
}

declare void @consume_vector(<2 x double>)

; CHECK-NOT: define internal <2 x double> @sub_pointer_hint.native
; CHECK: define internal void @sub_pointer_hint.native

!0 = !{!"vector"}
