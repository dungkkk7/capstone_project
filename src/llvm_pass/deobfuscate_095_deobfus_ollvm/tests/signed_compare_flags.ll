@fmt = private constant [61 x i8] c"%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\0A\00"

declare i32 @printf(ptr, ...)

; Exact x86 SF/OF/ZF expansion of signed x >= 0, including INT_MIN overflow.
define i1 @lifted_sge_zero(i32 %x) {
entry:
  %neg = sub i32 0, %x
  %zero = icmp eq i32 %x, 0
  %sx = lshr i32 %x, 31
  %sn = lshr i32 %neg, 31
  %signs = add nuw nsw i32 %sn, %sx
  %overflow = icmp eq i32 %signs, 2
  %negative.neg = icmp slt i32 %neg, 0
  %positive = xor i1 %negative.neg, %overflow
  %result = or i1 %zero, %positive
  ret i1 %result
}

; A nearby but inequivalent tree must not be claimed by the exact rule.
define i1 @near_miss(i32 %x) {
entry:
  %neg = sub i32 0, %x
  %zero = icmp eq i32 %x, 0
  %sx = lshr i32 %x, 31
  %sn = lshr i32 %neg, 31
  %signs = add i32 %sn, %sx
  %different = icmp eq i32 %signs, 1
  %negative.neg = icmp slt i32 %neg, 0
  %positive = xor i1 %negative.neg, %different
  %result = or i1 %zero, %positive
  ret i1 %result
}

; The subtraction form is exact when a dominating guard proves the RHS
; nonnegative: a <= b is ZF || (SF xor OF).
define i1 @lifted_sle_nonnegative_rhs(i32 %a, i32 %b) {
entry:
  %rhs.ok = icmp sge i32 %b, 0
  br i1 %rhs.ok, label %flags, label %refuse

flags:
  %difference = sub i32 %a, %b
  %equal = icmp eq i32 %a, %b
  %sign.a = lshr i32 %a, 31
  %difference.xor.a = xor i32 %difference, %a
  %sign.overflow = lshr i32 %difference.xor.a, 31
  %signs = add nuw nsw i32 %sign.a, %sign.overflow
  %overflow = icmp eq i32 %signs, 2
  %negative = icmp slt i32 %difference, 0
  %less = xor i1 %negative, %overflow
  %result = or i1 %equal, %less
  ret i1 %result

refuse:
  ret i1 false
}

; The strict form is SF xor OF without a zero-flag term.
define i1 @lifted_slt_nonnegative_rhs(i32 %a, i32 %b) {
entry:
  %rhs.ok = icmp sge i32 %b, 0
  br i1 %rhs.ok, label %flags, label %refuse

flags:
  %difference = sub i32 %a, %b
  %sign.a = lshr i32 %a, 31
  %difference.xor.a = xor i32 %difference, %a
  %sign.overflow = lshr i32 %difference.xor.a, 31
  %signs = add nuw nsw i32 %sign.a, %sign.overflow
  %overflow = icmp eq i32 %signs, 2
  %negative = icmp slt i32 %difference, 0
  %result = xor i1 %negative, %overflow
  ret i1 %result

refuse:
  ret i1 false
}

; The complete x86 overflow graph includes sign(A xor B), so it is exact for
; arbitrary signed operands and needs no nonnegative-RHS guard.
define i1 @lifted_slt_complete_overflow(i32 %a, i32 %b) {
entry:
  %difference = sub i32 %a, %b
  %a.xor.b = xor i32 %a, %b
  %signs.differ = lshr i32 %a.xor.b, 31
  %difference.xor.a = xor i32 %difference, %a
  %result.differs = lshr i32 %difference.xor.a, 31
  %signs = add nuw nsw i32 %signs.differ, %result.differs
  %overflow = icmp eq i32 %signs, 2
  %negative = icmp slt i32 %difference, 0
  %result = xor i1 %negative, %overflow
  ret i1 %result
}

; Loop induction canonicalization can reassociate A = base + 1 and
; A - 10 = base - 9 while retaining the exact same flag equations.
define i1 @lifted_slt_reassociated(i32 %base) {
entry:
  %a = add i32 %base, 1
  %difference = add i32 %base, -9
  %sign.a = lshr i32 %a, 31
  %difference.xor.a = xor i32 %difference, %a
  %sign.overflow = lshr i32 %difference.xor.a, 31
  %signs = add nuw nsw i32 %sign.a, %sign.overflow
  %overflow = icmp eq i32 %signs, 2
  %negative = icmp slt i32 %difference, 0
  %result = xor i1 %negative, %overflow
  ret i1 %result
}

; Reassociation often leaves the zero flag comparing the difference rather
; than the original operands.  It is the same exact <= condition.
define i1 @lifted_sle_difference_zero(i32 %a, i32 %b) {
entry:
  %rhs.ok = icmp sge i32 %b, 0
  br i1 %rhs.ok, label %flags, label %refuse

flags:
  %difference = sub i32 %a, %b
  %equal = icmp eq i32 %difference, 0
  %sign.a = lshr i32 %a, 31
  %difference.xor.a = xor i32 %difference, %a
  %sign.overflow = lshr i32 %difference.xor.a, 31
  %signs = add nuw nsw i32 %sign.a, %sign.overflow
  %overflow = icmp eq i32 %signs, 2
  %negative = icmp slt i32 %difference, 0
  %less = xor i1 %negative, %overflow
  %result = or i1 %equal, %less
  ret i1 %result

refuse:
  ret i1 false
}

; A > B is !ZF && !(SF xor OF).  The lift spells !OF as `signs != 2`.
define i1 @lifted_sgt_nonnegative_rhs(i32 %a, i32 %b) {
entry:
  %rhs.ok = icmp sge i32 %b, 0
  br i1 %rhs.ok, label %flags, label %refuse

flags:
  %difference = sub i32 %a, %b
  %different = icmp ne i32 %difference, 0
  %sign.a = lshr i32 %a, 31
  %difference.xor.a = xor i32 %difference, %a
  %sign.overflow = lshr i32 %difference.xor.a, 31
  %signs = add nuw nsw i32 %sign.a, %sign.overflow
  %not.overflow = icmp ne i32 %signs, 2
  %negative = icmp slt i32 %difference, 0
  %not.less = xor i1 %negative, %not.overflow
  %result = and i1 %different, %not.less
  ret i1 %result

refuse:
  ret i1 false
}

; An equivalent strict-greater spelling complements SF rather than OF:
; !ZF && ((difference >= 0) xor OF).  With sign(A xor B), the overflow
; equation is complete and remains exact for an arbitrary signed RHS.
define i1 @lifted_sgt_complete_nonnegative_sign(i32 %a, i32 %b) {
entry:
  %difference = sub i32 %a, %b
  %different = icmp ne i32 %a, %b
  %a.xor.b = xor i32 %a, %b
  %signs.differ = lshr i32 %a.xor.b, 31
  %difference.xor.a = xor i32 %difference, %a
  %result.differs = lshr i32 %difference.xor.a, 31
  %signs = add nuw nsw i32 %signs.differ, %result.differs
  %overflow = icmp eq i32 %signs, 2
  %nonnegative = icmp sgt i32 %difference, -1
  %greater = xor i1 %nonnegative, %overflow
  %result = and i1 %different, %greater
  ret i1 %result
}

; The lifted subtraction may stay wide while InstCombine sinks the sext out of
; its sign test.  The nsw flag is independently proven by the i8 signed range.
define i1 @lifted_slt_narrow_sign_test(i8 %x) {
entry:
  %a.narrow = sext i8 %x to i32
  %difference.narrow = add nsw i32 %a.narrow, -32
  %sign.a.narrow = lshr i32 %a.narrow, 31
  %difference.xor.a.narrow = xor i32 %difference.narrow, %a.narrow
  %sign.overflow.narrow = lshr i32 %difference.xor.a.narrow, 31
  %signs.narrow = add nuw nsw i32 %sign.a.narrow, %sign.overflow.narrow
  %overflow.narrow = icmp eq i32 %signs.narrow, 2
  %negative.narrow = icmp slt i8 %x, 32
  %result.narrow = xor i1 %negative.narrow, %overflow.narrow
  ret i1 %result.narrow
}

define i1 @lifted_sgt_narrow_nonnegative_test(i8 %x) {
entry:
  %a.narrow.gt = sext i8 %x to i32
  %difference.narrow.gt = add nsw i32 %a.narrow.gt, -32
  %different.narrow.gt = icmp ne i32 %difference.narrow.gt, 0
  %sign.a.narrow.gt = lshr i32 %a.narrow.gt, 31
  %difference.xor.a.narrow.gt = xor i32 %difference.narrow.gt, %a.narrow.gt
  %sign.overflow.narrow.gt = lshr i32 %difference.xor.a.narrow.gt, 31
  %signs.narrow.gt = add nuw nsw i32 %sign.a.narrow.gt, %sign.overflow.narrow.gt
  %overflow.narrow.gt = icmp eq i32 %signs.narrow.gt, 2
  %nonnegative.narrow.gt = icmp sgt i8 %x, 31
  %greater.narrow.gt = xor i1 %nonnegative.narrow.gt, %overflow.narrow.gt
  %result.narrow.gt = and i1 %different.narrow.gt, %greater.narrow.gt
  ret i1 %result.narrow.gt
}

define i32 @main() {
entry:
  %a = call i1 @lifted_sge_zero(i32 -2147483648)
  %b = call i1 @lifted_sge_zero(i32 -1)
  %c = call i1 @lifted_sge_zero(i32 0)
  %d = call i1 @lifted_sge_zero(i32 1)
  %e = call i1 @lifted_sge_zero(i32 2147483647)
  %f = call i1 @near_miss(i32 -2147483648)
  %g = call i1 @near_miss(i32 7)
  %h = call i1 @lifted_sle_nonnegative_rhs(i32 -2147483648, i32 0)
  %i = call i1 @lifted_sle_nonnegative_rhs(i32 7, i32 7)
  %j = call i1 @lifted_sle_nonnegative_rhs(i32 8, i32 7)
  %k = call i1 @lifted_slt_nonnegative_rhs(i32 -2147483648, i32 0)
  %l = call i1 @lifted_slt_nonnegative_rhs(i32 7, i32 7)
  %m = call i1 @lifted_slt_nonnegative_rhs(i32 8, i32 7)
  %n = call i1 @lifted_sle_difference_zero(i32 -2147483648, i32 0)
  %o = call i1 @lifted_sle_difference_zero(i32 7, i32 7)
  %p = call i1 @lifted_sle_difference_zero(i32 8, i32 7)
  %q = call i1 @lifted_sgt_nonnegative_rhs(i32 -2147483648, i32 0)
  %r = call i1 @lifted_sgt_nonnegative_rhs(i32 7, i32 7)
  %s = call i1 @lifted_sgt_nonnegative_rhs(i32 8, i32 7)
  %t = call i1 @lifted_slt_reassociated(i32 8)
  %ai = zext i1 %a to i32
  %bi = zext i1 %b to i32
  %ci = zext i1 %c to i32
  %di = zext i1 %d to i32
  %ei = zext i1 %e to i32
  %fi = zext i1 %f to i32
  %gi = zext i1 %g to i32
  %hi = zext i1 %h to i32
  %ii = zext i1 %i to i32
  %ji = zext i1 %j to i32
  %ki = zext i1 %k to i32
  %li = zext i1 %l to i32
  %mi = zext i1 %m to i32
  %ni = zext i1 %n to i32
  %oi = zext i1 %o to i32
  %pi = zext i1 %p to i32
  %qi = zext i1 %q to i32
  %ri = zext i1 %r to i32
  %si = zext i1 %s to i32
  %ti = zext i1 %t to i32
  %ignored = call i32 (ptr, ...) @printf(ptr @fmt, i32 %ai, i32 %bi,
                                         i32 %ci, i32 %di, i32 %ei,
                                         i32 %fi, i32 %gi, i32 %hi,
                                         i32 %ii, i32 %ji, i32 %ki,
                                         i32 %li, i32 %mi, i32 %ni,
                                         i32 %oi, i32 %pi, i32 %qi,
                                         i32 %ri, i32 %si, i32 %ti)
  ret i32 0
}
