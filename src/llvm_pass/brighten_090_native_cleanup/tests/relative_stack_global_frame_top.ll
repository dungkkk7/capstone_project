; Entry wrappers can carry a relative stack function attribute while their
; only recoverable anchor is the module-level frame_storage_backing.main
; object.  A stack address formed as ptrtoint(frame_top) - 32 must materialize
; at frame_top - 32, not at frame_storage_backing.main - 32.

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer,
  align 16

define i32 @main() "brighten.relative-stack" {
entry:
  %absolute.stack.address = add i64 ptrtoint (
      ptr getelementptr (i8, ptr @frame_storage_backing.main,
                         i64 16711680) to i64), -32
  %pointer = inttoptr i64 %absolute.stack.address to ptr
  store i32 7, ptr %pointer, align 4
  %result = load i32, ptr %pointer, align 4
  ret i32 %result
}
