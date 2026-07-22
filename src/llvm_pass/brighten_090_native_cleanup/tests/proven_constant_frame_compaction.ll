; Positive executable case: every read is dominated by a bounded write, so
; the 16 MiB fake backing can become one exact four-byte native frame.
@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer, align 16

define i32 @main() {
entry:
  ; Exercise the constant-expression spelling left by O3 after a recovered
  ; stack pointer round-trips through integer SSA.
  store i32 7, ptr inttoptr (i64 add (
      i64 ptrtoint (ptr getelementptr (i8, ptr @frame_storage_backing.main,
                                       i64 16711680) to i64),
      i64 -8) to ptr), align 4
  %value = load i32, ptr inttoptr (i64 add (
      i64 ptrtoint (ptr getelementptr (i8, ptr @frame_storage_backing.main,
                                       i64 16711680) to i64),
      i64 -8) to ptr), align 4
  ret i32 %value
}
