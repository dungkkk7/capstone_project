; CHECK-NOT: getelementptr inbounds

@buf = global [4 x i64] zeroinitializer
@p = global ptr getelementptr inbounds ([4 x i64], ptr @buf, i64 0, i64 8)

define i64 @use_p() {
entry:
  %v = load ptr, ptr @p, align 8
  %x = ptrtoint ptr %v to i64
  ret i64 %x
}
