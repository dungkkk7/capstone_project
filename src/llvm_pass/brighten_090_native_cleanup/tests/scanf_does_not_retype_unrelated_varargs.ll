; A scanf in the function must not make every GP vararg-save slot a pointer.
; The unrelated area models integer printf arguments in the same lifted body.

@scan_format = private constant [3 x i8] c"%d\00"

declare i32 @vscanf(ptr, ptr)

define i32 @mixed_varargs(i64 %state_in_2312) {
entry:
  %scan_va_list = alloca [24 x i8], align 8
  %scan_reg_save_area = alloca [48 x i8], align 8
  %scan_area_field = getelementptr i8, ptr %scan_va_list, i64 16
  store ptr %scan_reg_save_area, ptr %scan_area_field, align 8
  %ignored = call i32 @vscanf(ptr @scan_format, ptr %scan_va_list)

  %printf_reg_save_area = alloca [48 x i8], align 8
  %integer_slot = getelementptr i8, ptr %printf_reg_save_area, i64 8
  %numeric_value = add i64 %state_in_2312, 12344
  store i64 %numeric_value, ptr %integer_slot, align 8
  ret i32 0
}
