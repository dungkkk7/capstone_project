; LLVM may introduce a poison second vector operand even when every shuffle
; mask lane selects the first operand.  The poison is provably unobserved and
; must not survive the final native contract audit.

define <2 x i64> @reverse(<2 x i64> %value) {
entry:
  %result = shufflevector <2 x i64> %value, <2 x i64> poison,
      <2 x i32> <i32 1, i32 0>
  ret <2 x i64> %result
}

; CHECK-LABEL: define <2 x i64> @reverse
; CHECK: shufflevector <2 x i64> %value, <2 x i64> zeroinitializer
; CHECK-NOT: poison

