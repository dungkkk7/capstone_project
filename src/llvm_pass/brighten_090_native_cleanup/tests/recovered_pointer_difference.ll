; A recovered base used in a real pointer difference must remain native, while
; an unrelated integer-identity use of the same base must remain a guest
; constant.

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@moji = internal global [7 x i8] c"AIDUNY\00", !brighten.guest.range !0
@data_405048 = alias i8, ptr @moji
@counts = internal global [8 x i32] zeroinitializer, !brighten.guest.range !1

; CHECK-LABEL: define i32 @pointer_difference
; CHECK: %base = ptrtoint ptr @moji to i64
; CHECK: %difference = sub i64 %pointer.bits, %base
; CHECK: %slot = getelementptr i8, ptr @counts, i64 %scaled
define i32 @pointer_difference(ptr %pointer) {
entry:
  %pointer.bits = ptrtoint ptr %pointer to i64
  %base = ptrtoint ptr @data_405048 to i64
  %difference = sub i64 %pointer.bits, %base
  %scaled = mul i64 %difference, 4
  %slot = getelementptr i8, ptr @counts, i64 %scaled
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; InstCombine canonicalizes p - base to p + (0 - base).  The second cleanup
; sweep must preserve that constant-expression spelling as well.
; CHECK-LABEL: define i32 @negated_pointer_difference
; CHECK: %difference = add i64 %pointer.bits, sub (i64 0, i64 ptrtoint (ptr @moji to i64))
define i32 @negated_pointer_difference(ptr %pointer) {
entry:
  %pointer.bits = ptrtoint ptr %pointer to i64
  %difference = add i64 %pointer.bits, sub (i64 0, i64 ptrtoint (ptr @data_405048 to i64))
  %scaled = mul i64 %difference, 4
  %slot = getelementptr i8, ptr @counts, i64 %scaled
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; Recovered strings use a GEP to their first byte rather than the aggregate
; global directly.
; CHECK-LABEL: define i32 @negated_gep_pointer_difference
; CHECK: ptrtoint (ptr @moji to i64)
define i32 @negated_gep_pointer_difference(ptr %pointer) {
entry:
  %pointer.bits = ptrtoint ptr %pointer to i64
  %difference = add i64 %pointer.bits, sub (i64 0, i64 ptrtoint (ptr getelementptr ([7 x i8], ptr @moji, i64 0, i64 0) to i64))
  %scaled = mul i64 %difference, 4
  %slot = getelementptr i8, ptr @counts, i64 %scaled
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; O3 can combine an obfuscation constant into the negated recovered base.
; CHECK-LABEL: define i32 @affine_negated_pointer_difference
; CHECK: add (i64 sub (i64 0, i64 ptrtoint (ptr @moji to i64)), i64 820920968)
define i32 @affine_negated_pointer_difference(ptr %pointer) {
entry:
  %pointer.bits = ptrtoint ptr %pointer to i64
  %difference = add i64 %pointer.bits, add (i64 sub (i64 0, i64 ptrtoint (ptr @moji to i64)), i64 820920968)
  %scaled = mul i64 %difference, 4
  %slot = getelementptr i8, ptr @counts, i64 %scaled
  %value = load i32, ptr %slot, align 4
  ret i32 %value
}

; CHECK-LABEL: define i64 @opaque_identity
; CHECK-NOT: ptrtoint ptr @moji
; CHECK: %difference = sub i64 %value, 4214856
define i64 @opaque_identity(i64 %value) {
entry:
  %base = ptrtoint ptr @data_405048 to i64
  %difference = sub i64 %value, %base
  ret i64 %difference
}

!0 = !{i64 4214856, i64 4214863}
!1 = !{i64 4214896, i64 4214928}
