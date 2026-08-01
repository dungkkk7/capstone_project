declare i8 @__remill_undefined_8()
declare i32 @__remill_flag_computation_unknown(i32)
declare ptr @__remill_x86_unknown(ptr)
declare i64 @__mcsema_unknown()
declare void @__mcsema_attach_call()

define i64 @use_unknowns(ptr %state, i32 %x) {
entry:
  %a = call i8 @__remill_undefined_8()
  %b = call i32 @__remill_flag_computation_unknown(i32 %x)
  %c = call ptr @__remill_x86_unknown(ptr %state)
  %d = call i64 @__mcsema_unknown()
  call void @__mcsema_attach_call()
  %az = zext i8 %a to i64
  %bz = zext i32 %b to i64
  %sum = add i64 %az, %bz
  %out = add i64 %sum, %d
  ret i64 %out
}

; CHECK: declare i8 @__remill_undefined_8()
; CHECK: declare i32 @__remill_flag_computation_unknown(i32)
; CHECK: declare ptr @__remill_x86_unknown(ptr)
; CHECK: declare i64 @__mcsema_unknown()
; CHECK: declare void @__mcsema_attach_call()
; CHECK-LABEL: define i64 @use_unknowns
; CHECK: call i8 @__remill_undefined_8()
; CHECK: call i32 @__remill_flag_computation_unknown(i32 %x)
; CHECK: call ptr @__remill_x86_unknown(ptr %state)
; CHECK: call i64 @__mcsema_unknown()
; CHECK: call void @__mcsema_attach_call()

