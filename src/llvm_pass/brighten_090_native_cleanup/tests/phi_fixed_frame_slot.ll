; Fixed recovered-frame addresses used as PHI incoming values must be
; materialized on their predecessor edges.  Emitting the address arithmetic
; in %join before %slot would violate both PHI grouping and SSA dominance.

@frame_storage_backing.main = internal global [16777216 x i8] zeroinitializer,
  align 16

define i64 @worker.native(ptr %frame_base, i64 %state_in_2312, i1 %pick) {
entry:
  %post_prologue_rsp = add i64 %state_in_2312, -72
  br i1 %pick, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %slot = phi ptr [ getelementptr (i8, ptr @frame_storage_backing.main,
                                    i64 16711696), %left ],
                  [ getelementptr (i8, ptr @frame_storage_backing.main,
                                    i64 16711704), %right ]
  %value = load i64, ptr %slot, align 8
  call void @consume(i64 %post_prologue_rsp)
  ret i64 %value
}

declare void @consume(i64)

define i32 @main(i32 %argc, ptr %argv) {
entry:
  %pick = icmp ne i32 %argc, 0
  %value = call i64 @worker.native(
      ptr @frame_storage_backing.main, i64 16711680, i1 %pick)
  %status = trunc i64 %value to i32
  ret i32 %status
}
