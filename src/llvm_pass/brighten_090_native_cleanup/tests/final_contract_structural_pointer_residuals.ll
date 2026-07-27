; Neutral names ensure the final contract recognizes residual pointer models
; from their IR shape rather than generated symbol conventions.
target triple = "x86_64-pc-linux-gnu"

@a = internal global [128 x i8] zeroinitializer

define i8 @f(i64 %x) {
entry:
  %v0 = sub i64 %x, 4096
  %v1 = icmp ult i64 %v0, 128
  %v2 = getelementptr i8, ptr @a, i64 %v0
  %v3 = inttoptr i64 %x to ptr
  %v4 = select i1 %v1, ptr %v2, ptr %v3
  %v5 = load i8, ptr %v4, align 1
  ret i8 %v5
}

define void @g(i64 %x, i8 %y) {
entry:
  %v0 = sub i64 %x, 4096
  %v1 = icmp ult i64 %v0, 128
  br i1 %v1, label %b0, label %b1

b0:
  %v2 = getelementptr i8, ptr @a, i64 %v0
  br label %b2

b1:
  %v3 = inttoptr i64 %x to ptr
  br label %b2

b2:
  %v4 = phi ptr [ %v2, %b0 ], [ %v3, %b1 ]
  store i8 %y, ptr %v4, align 1
  ret void
}

define i8 @h(ptr %x, i64 %y, i1 %z) {
entry:
  %v0 = ptrtoint ptr %x to i64
  %v1 = sub i64 %y, 8192
  %v2 = add i64 %v0, %v1
  %v3 = select i1 %z, i64 %v2, i64 %y
  %v4 = inttoptr i64 %v3 to ptr
  %v5 = load i8, ptr %v4, align 1
  ret i8 %v5
}

define i8 @i(ptr %x, i64 %y, i1 %z) {
entry:
  br i1 %z, label %b0, label %b1

b0:
  %v0 = ptrtoint ptr %x to i64
  %v1 = sub i64 %y, 16384
  %v2 = add i64 %v0, %v1
  br label %b2

b1:
  br label %b2

b2:
  %v3 = phi i64 [ %v2, %b0 ], [ %y, %b1 ]
  %v4 = inttoptr i64 %v3 to ptr
  %v5 = load i8, ptr %v4, align 1
  ret i8 %v5
}
