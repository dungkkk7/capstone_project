; A nested function can address a local as
;   (frame_top + current_rsp) - frame_top + K.
; This odd but algebraically valid shape is produced by lifted absolute stack
; carriers before the surrounding anchor cancellation is simplified.
; The post-O3 cleanup retry must not independently rebase the constant
; frame_top operand: doing so applies the incoming call depth twice.

@frame_storage_backing.worker = internal global [16777216 x i8] zeroinitializer,
    align 16

define internal i32 @worker(ptr %frame_base, i64 %state_in_2312) {
entry:
  %frame.anchor = ptrtoint ptr getelementptr inbounds
      ([16777216 x i8], ptr @frame_storage_backing.worker, i64 0, i64 16711680)
      to i64
  %absolute.carrier = getelementptr i8,
      ptr getelementptr inbounds
          ([16777216 x i8], ptr @frame_storage_backing.worker, i64 0,
           i64 16711680),
      i64 %state_in_2312
  %cancel.anchor = sub i64 0, %frame.anchor
  %local.index = add i64 %cancel.anchor, -172
  %local = getelementptr i8, ptr %absolute.carrier, i64 %local.index
  %value = load i32, ptr %local, align 4
  ret i32 %value
}

define i32 @main() {
entry:
  %frame.top = getelementptr inbounds [16777216 x i8],
      ptr @frame_storage_backing.worker, i64 0, i64 16711680
  %rsp = ptrtoint ptr %frame.top to i64
  %nested.rsp = add i64 %rsp, -192
  %result = call i32 @worker(ptr %frame.top, i64 %nested.rsp)
  ret i32 %result
}
