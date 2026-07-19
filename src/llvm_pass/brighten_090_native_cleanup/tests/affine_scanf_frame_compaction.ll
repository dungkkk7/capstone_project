; The frame index is exactly -28 relative to frame_top in the i64 ring.  The
; strict cleanup must prove that cancellation, bound scanf's destination from
; the constant format, preserve zero-on-failed-conversion behavior, and emit
; a small native frame rather than retaining the 16 MiB guest backing.

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer, align 16
@format = private constant [3 x i8] c"%d\00"

declare i32 @scanf(ptr, ...)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %read = call i32 (ptr, ...) @scanf(
      ptr @format,
      ptr getelementptr (
          i8,
          ptr getelementptr inbounds (
              i8, ptr @frame_storage_backing.main, i64 16711680),
          i64 sub (
              i64 add (
                  i64 ptrtoint (
                      ptr getelementptr inbounds (
                          i8, ptr @frame_storage_backing.main, i64 16711680)
                      to i64),
                  i64 -28),
              i64 ptrtoint (
                  ptr getelementptr inbounds (
                      i8, ptr @frame_storage_backing.main, i64 16711680)
                  to i64))))
  %value = load i32, ptr getelementptr (
      i8,
      ptr getelementptr inbounds (
          i8, ptr @frame_storage_backing.main, i64 16711680),
      i64 -28), align 4
  ret i32 %value
}
