; llvm.used is a temporary optimization root for recovered segment images.
; A lifted segment with no real use must be dropped at final cleanup, while
; unrelated roots remain intact.
;
; CHECK-NOT: %seg_dead_type
; CHECK-NOT: @seg_dead
; CHECK: @kept = internal global i32 7
; CHECK: @llvm.used = appending global [1 x ptr] [ptr @kept]

%seg_dead_type = type { [16 x i8] }

@seg_dead = internal global %seg_dead_type zeroinitializer
@kept = internal global i32 7
@llvm.used = appending global [2 x ptr] [ptr @seg_dead, ptr @kept],
    section "llvm.metadata"

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %value = load i32, ptr @kept
  ret i32 %value
}
