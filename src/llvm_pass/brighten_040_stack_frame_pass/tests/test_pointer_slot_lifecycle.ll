; The production tail must leave a proven slot pointer-typed.  The input is
; the post-canonical boundary: the full pipeline orders this immediately after
; its final address canonicalizer, then only the non-mutating final reporter.

@slot_backing = internal global [64 x i8] zeroinitializer, align 8,
  !brighten.stack.synthetic.created !0
@bytes = internal global [32 x i8] zeroinitializer, align 1

declare ptr @calloc(i64, i64)
declare i64 @strlen(ptr)
declare void @free(ptr)

define i64 @slot_lifecycle(i64 %n) {
entry:
  %p = call ptr @calloc(i64 %n, i64 1)
  %bits = ptrtoint ptr %p to i64
  store i64 %bits, ptr getelementptr inbounds ([64 x i8], ptr @slot_backing, i64 0, i64 8), align 8
  %raw = load i64, ptr getelementptr inbounds ([64 x i8], ptr @slot_backing, i64 0, i64 8), align 8
  %fallback = inttoptr i64 %raw to ptr
  %delta = add i64 %raw, -4096
  %in.range = icmp ult i64 %delta, 32
  %candidate = getelementptr i8, ptr @bytes, i64 %raw
  %selected = select i1 %in.range, ptr %candidate, ptr %fallback
  %len = call i64 @strlen(ptr %selected)
  call void @free(ptr %selected)
  ret i64 %len
}

!0 = !{ptr @slot_lifecycle, i32 1}
