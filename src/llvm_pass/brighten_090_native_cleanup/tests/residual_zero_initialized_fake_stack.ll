; A straight-line function is still not native when its locals live in the
; zero-filled compatibility backing.  Keep this separate from the flattened
; dispatcher fixture so strict rejection cannot be attributed to CFG shape.
target triple = "x86_64-pc-linux-gnu"

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer, align 16

define i32 @main() {
entry:
  %value = load i32, ptr getelementptr inbounds ([16777216 x i8], ptr @frame_storage_backing.main, i64 0, i64 16711672), align 4
  ret i32 %value
}
