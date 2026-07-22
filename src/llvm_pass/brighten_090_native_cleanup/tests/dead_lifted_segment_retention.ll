; A lifted whole-segment blob retained only by llvm.used is a temporary
; recovery artifact.  Removing it must rebuild the partially retained array
; with the matching LLVM type while preserving genuinely live globals.

%seg_dead_type = type { [32 x i8] }

@seg_dead = internal global %seg_dead_type zeroinitializer, align 16
@live_native = internal global i32 7, align 4
@llvm.used = appending global [2 x ptr] [ptr @seg_dead, ptr @live_native], section "llvm.metadata"

define i32 @main() {
entry:
  %value = load i32, ptr @live_native, align 4
  ret i32 %value
}

; CHECK-NOT: %seg_dead_type
; CHECK-NOT: @seg_dead
; CHECK: @live_native = internal global i32 7
; CHECK: @llvm.used = appending global [1 x ptr] [ptr @live_native]
