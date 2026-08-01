; Pointer integerization prevents local frame recovery even with valid
; provenance metadata: wrapping/provenance/poison belong to pointer recovery.
@backing = internal global [64 x i8] zeroinitializer, align 16,
  !brighten.stack.ensured !0

define i32 @worker() {
entry:
  %slot = getelementptr i8, ptr @backing, i64 32
  %address = ptrtoint ptr %slot to i64
  %value = trunc i64 %address to i32
  store i32 7, ptr %slot, align 4
  ret i32 %value
}

!0 = !{}
