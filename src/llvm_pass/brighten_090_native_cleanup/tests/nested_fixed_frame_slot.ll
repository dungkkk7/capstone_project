; A recovered callee's fixed backing slots are relative to its allocated-frame
; RSP.  With a 72-byte prologue, backing_top+16 denotes entry_rsp-56, not
; entry_rsp+16.

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer,
  align 16

define void @worker.native(ptr %frame_base, i64 %state_in_2312) {
entry:
  %post_prologue_rsp = add i64 %state_in_2312, -72
  store i64 7, ptr getelementptr (
      i8, ptr @frame_storage_backing.main, i64 16711696), align 8
  call void @consume(i64 %post_prologue_rsp)
  ret void
}

declare void @consume(i64)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  call void @worker.native(ptr @frame_storage_backing.main, i64 16711680)
  ret i32 0
}
