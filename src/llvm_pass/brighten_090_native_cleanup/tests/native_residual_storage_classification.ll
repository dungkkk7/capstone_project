@native_residual_closed = internal global [64 x i8] zeroinitializer
@native_residual_dispatched = internal global [64 x i8] zeroinitializer

define i8 @closed_native_storage(i64 %index) {
entry:
  %pointer = getelementptr i8, ptr @native_residual_closed, i64 %index
  store i8 7, ptr %pointer, align 1
  %value = load i8, ptr %pointer, align 1
  ret i8 %value
}

define i8 @mapper_identity_is_not_closed(i1 %mapped, ptr %fallback) {
entry:
  %pointer = select i1 %mapped, ptr @native_residual_dispatched, ptr %fallback
  %value = load i8, ptr %pointer, align 1
  ret i8 %value
}

; CHECK: @native_storage_closed = internal global [64 x i8] zeroinitializer
; CHECK: @native_residual_dispatched = internal global [64 x i8] zeroinitializer
; CHECK-LABEL: define i8 @closed_native_storage(
; CHECK: %pointer = getelementptr i8, ptr @native_storage_closed, i64 %index
; CHECK-LABEL: define i8 @mapper_identity_is_not_closed(
; CHECK: select i1 %mapped, ptr @native_residual_dispatched, ptr %fallback
