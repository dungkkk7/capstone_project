; Exact ABI contract: destination is arg #1, bounded to four bytes,
; non-retained. It may fail, so only the producer's explicit entry-reset
; contract permits compaction; the emitted local memset preserves the zero
; observed by a failed scanf.
@backing = internal global [16777216 x i8] zeroinitializer, align 8,
  !brighten.entry.stack.contract !0
@format = private constant [3 x i8] c"%d\00"

!brighten.entry.stack.producer = !{!2}

declare i32 @scanf(ptr, ...)

define i32 @worker() !brighten.entry.stack.owner !1 {
entry:
  %slot = getelementptr i8, ptr @backing, i64 4
  %result = call i32 (ptr, ...) @scanf(ptr @format, ptr %slot), !brighten.scanf.destination !3
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

!0 = !{i32 1, i64 16777216, i64 16711680, i1 true}
!1 = !{ptr @backing, i32 1}
!2 = !{ptr @backing, i32 1}
!3 = !{i32 1, i32 1, i64 4, i1 true}
