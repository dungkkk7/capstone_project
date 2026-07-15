; Positive executable case: every read is dominated by a bounded write, so
; the 16 MiB fake backing can become one exact four-byte native frame.
@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer, align 16

define i32 @main() {
entry:
  store i32 7, ptr getelementptr inbounds ([16777216 x i8], ptr @frame_storage_backing.main, i64 0, i64 16711672), align 4
  %value = load i32, ptr getelementptr inbounds ([16777216 x i8], ptr @frame_storage_backing.main, i64 0, i64 16711672), align 4
  ret i32 %value
}
