; SysV has five GP vararg slots after vscanf's fixed format argument.  The
; sixth scanf destination is loaded through va_list.overflow_arg_area and
; must be translated just like the register-save destinations.

@format = private constant [19 x i8] c"%lf%lf%lf%lf%lf%lf\00"
@g_arr_0 = internal global [48 x i8] zeroinitializer, align 8,
  !brighten.guest.range !0

declare i32 @vscanf(ptr, ptr)

define i32 @scan_six() {
entry:
  %va_list = alloca [24 x i8], align 8
  %reg_save_area = alloca [48 x i8], align 8
  %overflow_area = alloca [8 x i8], align 8
  store i64 4214968, ptr %overflow_area, align 8

  %gp_offset = getelementptr i8, ptr %va_list, i64 0
  store i32 8, ptr %gp_offset, align 4
  %fp_offset = getelementptr i8, ptr %va_list, i64 4
  store i32 48, ptr %fp_offset, align 4
  %overflow_field = getelementptr i8, ptr %va_list, i64 8
  store ptr %overflow_area, ptr %overflow_field, align 8
  %save_area_field = getelementptr i8, ptr %va_list, i64 16
  store ptr %reg_save_area, ptr %save_area_field, align 8

  %result = call i32 @vscanf(ptr @format, ptr %va_list)
  ret i32 %result
}

; CHECK: %native.vararg.overflow = alloca [1 x i64], align 8
; CHECK: store ptr %native.vararg.overflow, ptr %overflow_field
; CHECK: %[[SOURCE:.*]] = getelementptr i8, ptr %overflow_area, i64 0
; CHECK: %native.vararg.overflow.guest.address = load i64, ptr %[[SOURCE]]
; CHECK: getelementptr i8, ptr @g_arr_0
; CHECK: call i32 @vscanf

!0 = !{i64 4214928, i64 4214976}
