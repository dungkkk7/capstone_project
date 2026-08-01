; A State backing lowered during an earlier conservative cleanup sweep must
; still be localizable after inlining/DCE leaves it with one non-escaping
; owner. Localization must not depend on the original __mcsema_reg_state name.

@native_register_storage = internal global [64 x i8] zeroinitializer, align 8

define i64 @owner(i64 %input) {
entry:
  %slot = getelementptr inbounds i8, ptr @native_register_storage, i64 16
  store i64 %input, ptr %slot, align 8
  %value = load i64, ptr %slot, align 8
  %result = add i64 %value, 1
  ret i64 %result
}

; CHECK-NOT: @native_register_storage
; CHECK-LABEL: define i64 @owner(i64 %input)
; CHECK: %native_state_storage = alloca [64 x i8]
; CHECK: store [64 x i8] zeroinitializer, ptr %native_state_storage
; CHECK: store i64 %input
; CHECK: load i64
