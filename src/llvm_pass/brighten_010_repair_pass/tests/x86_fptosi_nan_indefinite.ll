; RUN: opt-21 -load-pass-plugin %plugin -passes=brighten-repair-pass,verify -S %s -o - | FileCheck-21 %s

declare double @llvm.fabs.f64(double)

define i64 @lifted_cvttsd2si(double %input) {
entry:
  %truncated = call double @llvm.trunc.f64(double %input)
  %absolute = call double @llvm.fabs.f64(double %truncated)
  %outside = fcmp ogt double %absolute, 0x41DFFFFFFFC00000
  %converted = fptosi double %truncated to i32
  %extended = zext i32 %converted to i64
  %result = select i1 %outside, i64 2147483648, i64 %extended
  ret i64 %result
}

; CHECK-LABEL: define i64 @lifted_cvttsd2si
; CHECK: %outside = fcmp ugt double %absolute, 0x41DFFFFFFFC00000
; CHECK: %result = select i1 %outside, i64 2147483648, i64 %extended

define i64 @unrelated_ordered_compare(double %input) {
entry:
  %absolute = call double @llvm.fabs.f64(double %input)
  %outside = fcmp ogt double %absolute, 1.000000e+00
  %result = select i1 %outside, i64 7, i64 9
  ret i64 %result
}

; CHECK-LABEL: define i64 @unrelated_ordered_compare
; CHECK: %outside = fcmp ogt double %absolute, 1.000000e+00
