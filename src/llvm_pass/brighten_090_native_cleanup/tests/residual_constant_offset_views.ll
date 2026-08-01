target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Constant anchors may acquire readable aliases, but the residual remains one
; allocation.  The dynamic access rooted at byte zero is deliberately not
; assigned a guessed object boundary.
@native_residual_image = internal global [64 x i8] zeroinitializer,
  !brighten.guest.range !0

define internal void @write_scalar(i32 %value) {
entry:
  store i32 %value,
      ptr getelementptr (i8, ptr @native_residual_image, i64 8), align 4
  ret void
}

define internal i32 @read_scalar() {
entry:
  %value = load i32,
      ptr getelementptr (i8, ptr @native_residual_image, i64 8), align 4
  ret i32 %value
}

define internal i8 @read_named_object(i64 %index) {
entry:
  %object = getelementptr i8, ptr @native_residual_image, i64 16
  %element = getelementptr i8, ptr %object, i64 %index
  %value = load i8, ptr %element, align 1
  ret i8 %value
}

; The view offset must include both GEPs.  Looking only at the outer `+3`
; would silently redirect this access from guest 0x1013 to 0x1003.
define internal i8 @read_nested_constant() {
entry:
  %object = getelementptr i8, ptr @native_residual_image, i64 16
  %element = getelementptr i8, ptr %object, i64 3
  %value = load i8, ptr %element, align 1
  ret i8 %value
}

define internal i8 @read_unbounded_backing(i64 %index) {
entry:
  %element = getelementptr i8, ptr @native_residual_image, i64 %index
  %value = load i8, ptr %element, align 1
  ret i8 %value
}

define i32 @main() {
entry:
  call void @write_scalar(i32 42)
  store i8 7, ptr getelementptr (i8, ptr @native_residual_image, i64 19), align 1
  %scalar = call i32 @read_scalar()
  %object = call i8 @read_named_object(i64 3)
  %nested = call i8 @read_nested_constant()
  %backing = call i8 @read_unbounded_backing(i64 19)
  %scalar.ok = icmp eq i32 %scalar, 42
  %object.ok = icmp eq i8 %object, 7
  %nested.ok = icmp eq i8 %nested, 7
  %backing.ok = icmp eq i8 %backing, 7
  %named.ok = and i1 %object.ok, %nested.ok
  %bytes.ok = and i1 %named.ok, %backing.ok
  %ok = and i1 %scalar.ok, %bytes.ok
  %failed = xor i1 %ok, true
  %status = zext i1 %failed to i32
  ret i32 %status
}

; CHECK: @native_residual_image = internal global [64 x i8] zeroinitializer
; CHECK: @native_scalar_1008 = internal alias i32, getelementptr (i8, ptr @native_residual_image, i64 8)
; CHECK: @native_object_1010 = internal alias i8, getelementptr (i8, ptr @native_residual_image, i64 16)
; CHECK: @native_scalar_1013 = internal alias i8, getelementptr (i8, ptr @native_residual_image, i64 19)
; CHECK-NOT: @native_scalar_1003

; CHECK-LABEL: define internal void @write_scalar(i32 %value)
; CHECK: store i32 %value, ptr @native_scalar_1008

; CHECK-LABEL: define internal i32 @read_scalar()
; CHECK: %value = load i32, ptr @native_scalar_1008

; CHECK-LABEL: define internal i8 @read_named_object(i64 %index)
; CHECK: %element = getelementptr i8, ptr @native_object_1010, i64 %index

; CHECK-LABEL: define internal i8 @read_nested_constant()
; CHECK: %value = load i8, ptr @native_scalar_1013

; CHECK-LABEL: define internal i8 @read_unbounded_backing(i64 %index)
; CHECK: %element = getelementptr i8, ptr @native_residual_image, i64 %index
; CHECK-NOT: native_object_native_residual_image_offset_0

!0 = !{i64 4096, i64 4160}
