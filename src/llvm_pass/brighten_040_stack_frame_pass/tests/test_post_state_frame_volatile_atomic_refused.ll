@volatile_backing = internal global [16 x i8] zeroinitializer, align 8,
  !brighten.stack.ensured !0
@atomic_backing = internal global [16 x i8] zeroinitializer, align 8,
  !brighten.stack.ensured !0

define i32 @volatile_access() {
entry:
  %slot = getelementptr i8, ptr @volatile_backing, i64 4
  store volatile i32 7, ptr %slot, align 4
  %value = load volatile i32, ptr %slot, align 4
  ret i32 %value
}

define i32 @atomic_access() {
entry:
  %slot = getelementptr i8, ptr @atomic_backing, i64 4
  store atomic i32 7, ptr %slot monotonic, align 4
  %value = load atomic i32, ptr %slot monotonic, align 4
  ret i32 %value
}

!0 = !{}
