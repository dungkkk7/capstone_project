; These resemble a producer record but were not emitted by the 090 producer.
; In particular, the preexisting global is absent from the module producer
; registry, while the duplicate record is malformed. Neither may be reset.
@preexisting = internal global [16777216 x i8] zeroinitializer, align 16,
  !brighten.entry.stack.contract !0
@duplicate = internal global [16777216 x i8] zeroinitializer, align 16,
  !brighten.entry.stack.contract !0

!brighten.entry.stack.producer = !{!3, !4}

define i32 @preexisting_owner() !brighten.entry.stack.owner !1 {
entry:
  %slot = getelementptr i8, ptr @preexisting, i64 32
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

define i32 @duplicate_owner() !brighten.entry.stack.owner !2 {
entry:
  %slot = getelementptr i8, ptr @duplicate, i64 32
  store i32 7, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

!0 = !{i32 1, i64 16777216, i64 16711680, i1 true}
!1 = !{ptr @preexisting, i32 1}
!2 = !{ptr @duplicate, i32 1}
!3 = !{ptr @duplicate, i32 1}
!4 = !{ptr @duplicate, i32 1}
