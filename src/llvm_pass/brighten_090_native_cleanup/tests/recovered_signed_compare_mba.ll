; RUN: opt-21 -load-pass-plugin %plugin -passes='brighten-native-cleanup-post-souper-pass,verify' -S %s | FileCheck-21 %s
;
; This is the overflow-correct signed comparison emitted by lifted/MBA IR:
; sign(a-b) xor (sign(a xor b) and sign(a xor (a-b))).  Recover the native
; predicate without relying on constants from any dataset program.

define i1 @signed_less_equal(i32 %a, i32 %b) {
entry:
  %difference = sub i32 %a, %b
  %equal = icmp eq i32 %a, %b
  %ab.xor = xor i32 %a, %b
  %ab.sign = lshr i32 %ab.xor, 31
  %da.xor = xor i32 %difference, %a
  %da.sign = lshr i32 %da.xor, 31
  %overflow.sum = add nuw nsw i32 %ab.sign, %da.sign
  %overflow = icmp eq i32 %overflow.sum, 2
  %negative = icmp slt i32 %difference, 0
  %less = xor i1 %negative, %overflow
  %less.equal = or i1 %equal, %less
  ret i1 %less.equal
}

; CHECK-LABEL: define i1 @signed_less_equal(
; CHECK: %native.sle = icmp sle i32 %a, %b
; CHECK-NEXT: ret i1 %native.sle
; CHECK-NOT: lshr

