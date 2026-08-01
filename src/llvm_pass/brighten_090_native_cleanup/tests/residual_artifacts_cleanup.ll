; A residual image or dynamic byte backing can be rooted only by llvm.used.
; The final verifier must preserve and reject these recovery artifacts.

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
