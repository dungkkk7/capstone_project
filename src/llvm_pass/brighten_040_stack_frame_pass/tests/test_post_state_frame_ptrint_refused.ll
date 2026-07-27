; Integerized pointers can carry target-dependent provenance and poison.
@backing = internal global [16 x i8] zeroinitializer, align 8,
  !brighten.stack.ensured !0

define i32 @worker() {
entry:
  %base = ptrtoint ptr @backing to i64
  %address = add nsw i64 %base, 4
  %slot = inttoptr i64 %address to ptr
  store i32 7, ptr %slot, align 4
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

!0 = !{}
