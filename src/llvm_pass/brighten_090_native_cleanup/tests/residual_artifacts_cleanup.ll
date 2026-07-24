; A residual image or dynamic byte backing can be rooted only by llvm.used.
; Final cleanup must remove those dead roots while preserving a backing with
; a real instruction use.
;
; CHECK-NOT: @native_residual_dead
; CHECK-NOT: @dyn_bytes_dead
; CHECK: @native_data_live__byte_backing = internal global [4 x i8]
; CHECK: load i8, ptr @native_data_live__byte_backing

@native_residual_dead = internal constant [4 x i8] c"dead"
@dyn_bytes_dead = internal global [4 x i8] zeroinitializer
@dyn_bytes_live = internal global [4 x i8] zeroinitializer
@llvm.used = appending global [3 x ptr] [ptr @native_residual_dead,
    ptr @dyn_bytes_dead, ptr @dyn_bytes_live], section "llvm.metadata"

define i32 @main() {
entry:
  %value = load i8, ptr @dyn_bytes_live
  %result = zext i8 %value to i32
  ret i32 %result
}
