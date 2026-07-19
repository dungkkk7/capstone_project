; A bounded, non-volatile memset is a proven frame write, not an unknown
; pointer escape.  Post-Souper cleanup must retain the write while replacing
; the 16 MiB guest backing with the exact compact native frame.
;
; CHECK-NOT: @frame_storage_backing.main
; CHECK: native_frame.compact = alloca [4 x i8], align 16
; CHECK: call void @llvm.memset.p0.i64(ptr align 16 {{.*}}, i8 90, i64 4, i1 false)

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer, align 16

declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  call void @llvm.memset.p0.i64(
      ptr align 16 getelementptr inbounds (
          i8, ptr @frame_storage_backing.main, i64 16711664),
      i8 90, i64 4, i1 false)
  %value = load i32, ptr getelementptr inbounds (
      i8, ptr @frame_storage_backing.main, i64 16711664), align 16
  ret i32 %value
}
