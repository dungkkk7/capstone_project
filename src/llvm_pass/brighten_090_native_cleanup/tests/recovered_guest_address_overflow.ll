; A recovered guest base at UINT64_MAX cannot be advanced by one byte.
; The address must remain unresolved instead of wrapping to zero.
@overflow_object = internal global [16 x i8] zeroinitializer, !brighten.guest.range !0

define i64 @overflow_address() {
entry:
  %address = ptrtoint ptr getelementptr ([16 x i8], ptr @overflow_object, i64 0, i64 1) to i64
  ret i64 %address
}

!0 = !{i64 -1, i64 16}
