; A seventh-or-later SysV integer argument is read above the recovered
; callee's entry RSP.  Even when the function has a deep allocated frame, the
; incoming argument must not be rebased on the post-prologue RSP.

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer,
  align 16

define i64 @worker.native(ptr %frame_base, i64 %state_in_2312) {
entry:
  ; Retain the recovered prologue adjustment that used to confuse the fixed
  ; stack-address heuristic.
  %post_prologue_rsp = add i64 %state_in_2312, -568
  call void @consume(i64 %post_prologue_rsp)

  ; backing_top+16 models entry_rsp+16 (the second stack-passed argument).
  %arg8 = load i64, ptr getelementptr (
      i8, ptr @frame_storage_backing.main, i64 16711696), align 8
  ret i64 %arg8
}

declare void @consume(i64)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %value = call i64 @worker.native(
      ptr @frame_storage_backing.main, i64 16711680)
  %result = trunc i64 %value to i32
  ret i32 %result
}
