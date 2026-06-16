; CHECK-NOT: nsw
; CHECK-NOT: nuw
; CHECK-NOT: getelementptr inbounds

define i64 @ub_flags(i64 %a, i64 %b, i64* %base) {
entry:
  %x = add nsw i64 %a, %b
  %y = sub nuw i64 %x, 1
  %p = getelementptr inbounds i64, i64* %base, i64 %y
  %z = load i64, i64* %p, align 8
  ret i64 %z
}
