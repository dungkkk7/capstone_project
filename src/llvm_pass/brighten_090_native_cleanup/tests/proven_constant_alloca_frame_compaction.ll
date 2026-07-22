; A recovered entry frame may still be a multi-megabyte alloca even though
; every surviving access is a constant, non-escaping slot.  Compact the
; proven window directly instead of requiring an intermediate global backing.

@source = private constant [4 x i8] c"abc\00"

declare ptr @fgets(ptr, i32, ptr)
declare ptr @memcpy(ptr, ptr, i64)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %frame_storage = alloca [2097152 x i8], align 16
  %slot = getelementptr inbounds [2097152 x i8], ptr %frame_storage,
      i64 0, i64 2096880
  %slot.addr = ptrtoint ptr %slot to i64
  %top = getelementptr inbounds [2097152 x i8], ptr %frame_storage,
      i64 0, i64 2096884
  %top.addr = ptrtoint ptr %top to i64
  %distance = sub i64 %top.addr, %slot.addr
  %distance.i32 = trunc i64 %distance to i32
  store i32 7, ptr %slot, align 16
  %value = load i32, ptr %slot, align 16
  %result = add i32 %value, %distance.i32
  ret i32 %result
}

define i32 @bounded_libc_frame(ptr %stream) {
entry:
  %frame_storage = alloca [2097152 x i8], align 16
  %input = getelementptr inbounds [2097152 x i8], ptr %frame_storage,
      i64 0, i64 2096800
  %copy = getelementptr inbounds [2097152 x i8], ptr %frame_storage,
      i64 0, i64 2096816
  %fgets.result = call ptr @fgets(ptr %input, i32 8, ptr %stream)
  %memcpy.result = call ptr @memcpy(ptr %copy, ptr @source, i64 4)
  %value = load i8, ptr %copy, align 1
  %result = zext i8 %value to i32
  ret i32 %result
}

; CHECK-NOT: alloca [2097152 x i8]
; CHECK: %native_frame.compact = alloca [4 x i8], align 16
; CHECK: %slot.addr = ptrtoint ptr %native.frame.slot{{[0-9]*}} to i64
; CHECK: %top.addr = ptrtoint ptr %native.frame.slot{{[0-9]*}} to i64
; CHECK: store i32 7, ptr %native.frame.slot{{[0-9]*}}, align 16
; CHECK: %value = load i32, ptr %native.frame.slot{{[0-9]*}}, align 16
; CHECK-LABEL: define i32 @bounded_libc_frame(
; CHECK: call ptr @fgets(ptr %native.frame.slot{{[0-9]*}}, i32 8, ptr %stream)
; CHECK: call ptr @memcpy(ptr %native.frame.slot{{[0-9]*}}, ptr @source, i64 4)
; CHECK: ret i32
