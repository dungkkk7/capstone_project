; A normal loop-counter comparison is not a recovered pointer range guard.
; The final contract detector must not classify it as pointer dispatch.
define i32 @counter(i32 %x) {
entry:
  %cmp = icmp ult i32 %x, 10
  br i1 %cmp, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
