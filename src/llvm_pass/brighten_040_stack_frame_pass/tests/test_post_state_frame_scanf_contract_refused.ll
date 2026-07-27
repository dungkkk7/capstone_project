; Every malformed schema must refuse before the rewrite transaction starts.
@wrong_version = internal global [16 x i8] zeroinitializer, !brighten.stack.ensured !0
@wrong_index = internal global [16 x i8] zeroinitializer, !brighten.stack.ensured !0
@wrong_size = internal global [16 x i8] zeroinitializer, !brighten.stack.ensured !0
@retained = internal global [16 x i8] zeroinitializer, !brighten.stack.ensured !0
@duplicate_use = internal global [16 x i8] zeroinitializer, !brighten.stack.ensured !0
@bundle_use = internal global [16 x i8] zeroinitializer, !brighten.stack.ensured !0

declare i32 @scanf(ptr, ...)

define i32 @bad_version() {
  %p = getelementptr i8, ptr @wrong_version, i64 4
  %r = call i32 (ptr, ...) @scanf(ptr null, ptr %p), !brighten.scanf.destination !1
  %v = load i32, ptr %p, align 4
  ret i32 %v
}
define i32 @bad_index() {
  %p = getelementptr i8, ptr @wrong_index, i64 4
  %r = call i32 (ptr, ...) @scanf(ptr null, ptr %p), !brighten.scanf.destination !2
  %v = load i32, ptr %p, align 4
  ret i32 %v
}
define i32 @bad_size() {
  %p = getelementptr i8, ptr @wrong_size, i64 4
  %r = call i32 (ptr, ...) @scanf(ptr null, ptr %p), !brighten.scanf.destination !3
  %v = load i32, ptr %p, align 4
  ret i32 %v
}
define i32 @bad_retained() {
  %p = getelementptr i8, ptr @retained, i64 4
  %r = call i32 (ptr, ...) @scanf(ptr null, ptr %p), !brighten.scanf.destination !4
  %v = load i32, ptr %p, align 4
  ret i32 %v
}
define i32 @duplicate_destination_use() {
  %p = getelementptr i8, ptr @duplicate_use, i64 4
  %r = call i32 (ptr, ...) @scanf(ptr %p, ptr %p), !brighten.scanf.destination !5
  %v = load i32, ptr %p, align 4
  ret i32 %v
}
define i32 @operand_bundle() {
  %p = getelementptr i8, ptr @bundle_use, i64 4
  %r = call i32 (ptr, ...) @scanf(ptr null, ptr %p) [ "deopt"(i32 0) ], !brighten.scanf.destination !5
  %v = load i32, ptr %p, align 4
  ret i32 %v
}

!0 = !{}
!1 = !{i32 2, i32 1, i64 4, i1 true}
!2 = !{i32 1, i32 0, i64 4, i1 true}
!3 = !{i32 1, i32 1, i64 8, i1 true}
!4 = !{i32 1, i32 1, i64 4, i1 false}
!5 = !{i32 1, i32 1, i64 4, i1 true}
