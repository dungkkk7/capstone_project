; Negative executable case: replacing the zero-initialized global with an
; alloca would make this read undefined, so compaction must reject atomically.
@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer, align 16

define i32 @main() {
entry:
  %value = load i32, ptr getelementptr inbounds ([16777216 x i8], ptr @frame_storage_backing.main, i64 0, i64 16711672), align 4
  ret i32 %value
}
