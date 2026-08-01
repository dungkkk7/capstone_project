; A late external-ABI rewrite can see an RSP-derived integer that predates
; stack relativization.  It is already frame_top - 8, not the relative -8.

@frame_storage_backing.worker = internal global [16777216 x i8] zeroinitializer,
  align 16
@format = private constant [3 x i8] c"%d\00"

declare i32 @vscanf(ptr, ptr)

define internal void @worker(ptr %native_stack, i64 %state_in_2312)
    "brighten.relative-stack" {
entry:
  %reg_save_area = alloca [48 x i8], align 16
  %va_list = alloca [24 x i8], align 8
  %state_2312 = add i64 ptrtoint (
      ptr getelementptr (i8, ptr @frame_storage_backing.worker,
                         i64 16711680) to i64), 0
  %absolute.stack.address = add i64 %state_2312, -8
  %save.slot = getelementptr i8, ptr %reg_save_area, i64 8
  store i64 %absolute.stack.address, ptr %save.slot, align 8
  %va.save.area = getelementptr i8, ptr %va_list, i64 16
  store ptr %reg_save_area, ptr %va.save.area, align 8
  %ignored = call i32 @vscanf(ptr @format, ptr %va_list)
  ret void
}
