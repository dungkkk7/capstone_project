; Synthetic coverage for the supported opaque-predicate proof families.
; optnone keeps the source pattern intact until pass 095's own matcher runs.

attributes #0 = { noinline optnone }

@predicate.minus_one = constant i8 -1
@predicate.one = constant i8 1
@predicate.seven = constant i8 7
@predicate.zero = constant i8 0

define i32 @setz_self(i32 %x) #0 {
  %c = icmp eq i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setnz_self(i32 %x) #0 {
  %c = icmp ne i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setb_self(i32 %x) #0 {
  %c = icmp ult i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setae_self(i32 %x) #0 {
  %c = icmp uge i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @seta_self(i32 %x) #0 {
  %c = icmp ugt i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setbe_self(i32 %x) #0 {
  %c = icmp ule i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setl_self(i32 %x) #0 {
  %c = icmp slt i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setge_self(i32 %x) #0 {
  %c = icmp sge i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setg_self(i32 %x) #0 {
  %c = icmp sgt i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setle_self(i32 %x) #0 {
  %c = icmp sle i32 %x, %x
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setz_and_complement(i32 %x) #0 {
  %n = xor i32 %x, -1
  %v = and i32 %x, %n
  %c = icmp eq i32 %v, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setnz_or_complement(i32 %x) #0 {
  %n = xor i32 %x, -1
  %v = or i32 %x, %n
  %c = icmp ne i32 %v, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setz_xor_self(i32 %x) #0 {
  %v = xor i32 %x, %x
  %c = icmp eq i32 %v, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setnz_xor_self(i32 %x) #0 {
  %v = xor i32 %x, %x
  %c = icmp ne i32 %v, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setnz_or_one(i32 %x) #0 {
  %v = or i32 %x, 5
  %c = icmp ne i32 %v, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setz_and_zero(i32 %x) #0 {
  %v = and i32 %x, 0
  %c = icmp eq i32 %v, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setnz_or_minus_one(i32 %x) #0 {
  %v = or i32 %x, -1
  %c = icmp ne i32 %v, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setb_zero(i32 %x) #0 {
  %c = icmp ult i32 %x, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @setae_zero(i32 %x) #0 {
  %c = icmp uge i32 %x, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @set_const() #0 {
  %a = load volatile i8, ptr @predicate.minus_one
  %b = load volatile i8, ptr @predicate.one
  %c = icmp slt i8 %a, %b
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @lnot_one() #0 {
  %a = load volatile i8, ptr @predicate.seven
  %z = load volatile i8, ptr @predicate.zero
  %c = icmp eq i8 %a, %z
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @lnot_zero() #0 {
  %a = load volatile i8, ptr @predicate.zero
  %z = load volatile i8, ptr @predicate.zero
  %c = icmp eq i8 %a, %z
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @lnot_lnot(i32 %x) #0 {
  %base = icmp ult i32 %x, 10
  %n1 = xor i1 %base, true
  %n2 = xor i1 %n1, true
  br i1 %n2, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @set_rule_z3(i32 %x) #0 {
  %next = add i32 %x, 1
  %product = mul i32 %x, %next
  %parity = urem i32 %product, 2
  %c = icmp eq i32 %parity, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

; Negative/fail-closed cases.

define i32 @negative_width_cast(i8 %x) #0 {
  %z = zext i8 %x to i32
  %s = sext i8 %x to i32
  %c = icmp eq i32 %z, %s
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @negative_signed_or_odd(i32 %x) #0 {
  %v = or i32 %x, 1
  %c = icmp sgt i32 %v, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @negative_undef() #0 {
  %c = icmp eq i32 undef, 0
  br i1 %c, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}

define i32 @negative_poison() #0 {
  br i1 poison, label %yes, label %no
yes: ret i32 1
no: ret i32 0
}
