; An entry wrapper can carry an absolute frame-top integer while a recovered
; stack GEP still subtracts the backing address.  The stack transaction must
; remain absolute until that GEP has been normalized to frame_base + offset.

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer,
  align 16

define i32 @main() {
entry:
  %native_stack_storage = getelementptr inbounds [16777216 x i8],
      ptr @frame_storage_backing.main, i32 0, i32 0
  %native_stack_top = getelementptr i8, ptr %native_stack_storage,
      i64 16711680
  %rsp = ptrtoint ptr %native_stack_top to i64
  %absolute.delta = sub i64 %rsp,
      ptrtoint (ptr @frame_storage_backing.main to i64)
  %absolute.base = getelementptr i8, ptr @frame_storage_backing.main,
      i64 %absolute.delta
  %slot = getelementptr i8, ptr %absolute.base, i64 -100
  %value = load volatile i32, ptr %slot, align 4
  ret i32 %value
}
