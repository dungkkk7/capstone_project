; Regression for the bounded generic opaque-predicate prover.
;
; The first condition is a bit-vector identity even when the add wraps.  The
; other two have concrete wrap/signedness counterexamples, so the prover must
; leave their branches intact rather than treating arithmetic as mathematical
; integers or conflating signed with unsigned comparison.

attributes #0 = { noinline optnone }

define i32 @proven_modular_identity(i8 %x) #0 {
entry:
  %inc = add i8 %x, 1
  %roundtrip = sub i8 %inc, 1
  %is_original = icmp eq i8 %roundtrip, %x
  br i1 %is_original, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @unsigned_wrap_counterexample(i8 %x) #0 {
entry:
  %inc = add i8 %x, 1
  %same_bits = xor i8 %inc, 0
  %increased = icmp ugt i8 %same_bits, %x
  br i1 %increased, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @signed_wrap_counterexample(i8 %x) #0 {
entry:
  %inc = add i8 %x, 1
  %same_bits = xor i8 %inc, 0
  %increased = icmp sgt i8 %same_bits, %x
  br i1 %increased, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @undef_counterexample() #0 {
entry:
  %condition = icmp eq i8 undef, 0
  br i1 %condition, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @poison_counterexample() #0 {
entry:
  br i1 poison, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
