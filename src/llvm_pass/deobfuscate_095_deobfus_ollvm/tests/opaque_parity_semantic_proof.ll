; Exact parity opaque-predicate regression.  The positive roots are noundef,
; so replacing x*~x/x*(x+1) & 1 with zero preserves LLVM poison semantics.
; Every negative is deliberately algebraically tempting but must remain.

attributes #0 = { noinline optnone }

define i32 @parity_i8_not(i8 noundef %x) #0 {
entry:
  %not = xor i8 -1, %x
  %mul = mul i8 %not, %x
  %low = and i8 1, %mul
  %c = icmp eq i8 %low, 0
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @parity_i32_next(i32 noundef %x) #0 {
entry:
  %next = add i32 1, %x
  %mul = mul i32 %next, %x
  %low = and i32 %mul, 1
  %c = icmp ne i32 %low, 1
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i64 @parity_i64_integer(i64 noundef %x) #0 {
entry:
  %not = xor i64 %x, -1
  %mul = mul i64 %x, %not
  %low = and i64 %mul, 1
  ret i64 %low
}

; Different SSA values: no consecutive-product proof exists.
define i32 @negative_different_ssa(i8 noundef %x, i8 noundef %y) #0 {
entry:
  %noty = xor i8 %y, -1
  %mul = mul i8 %x, %noty
  %low = and i8 %mul, 1
  %c = icmp eq i8 %low, 0
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

; nowrap flags have poison preconditions and are outside this rule.
define i32 @negative_nsw(i8 noundef %x) #0 {
entry:
  %next = add nsw i8 %x, 1
  %mul = mul i8 %x, %next
  %low = and i8 %mul, 1
  %c = icmp eq i8 %low, 0
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @negative_nuw(i8 noundef %x) #0 {
entry:
  %not = xor i8 %x, -1
  %mul = mul nuw i8 %x, %not
  %low = and i8 %mul, 1
  %c = icmp eq i8 %low, 0
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

; An ordinary parameter may itself be poison/undef: do not replace its use.
define i32 @negative_unproven_parameter(i8 %x) #0 {
entry:
  %not = xor i8 %x, -1
  %mul = mul i8 %x, %not
  %low = and i8 %mul, 1
  %c = icmp eq i8 %low, 0
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @negative_freeze(i8 %x) #0 {
entry:
  %f = freeze i8 %x
  %not = xor i8 %f, -1
  %mul = mul i8 %f, %not
  %low = and i8 %mul, 1
  %c = icmp eq i8 %low, 0
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @negative_undef() #0 {
entry:
  %not = xor i8 undef, -1
  %mul = mul i8 undef, %not
  %low = and i8 %mul, 1
  %c = icmp eq i8 %low, 0
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define i32 @negative_poison() #0 {
entry:
  %not = xor i8 poison, -1
  %mul = mul i8 poison, %not
  %low = and i8 %mul, 1
  %c = icmp eq i8 %low, 0
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}

define <4 x i1> @negative_vector(<4 x i8> %x) #0 {
entry:
  %not = xor <4 x i8> %x, <i8 -1, i8 -1, i8 -1, i8 -1>
  %mul = mul <4 x i8> %x, %not
  %low = and <4 x i8> %mul, <i8 1, i8 1, i8 1, i8 1>
  %c = icmp eq <4 x i8> %low, zeroinitializer
  ret <4 x i1> %c
}

; This is mathematically true, but only eq/ne polarity is owned by this rule.
define i32 @negative_comparison_polarity(i8 noundef %x) #0 {
entry:
  %not = xor i8 %x, -1
  %mul = mul i8 %x, %not
  %low = and i8 %mul, 1
  %c = icmp ult i8 %low, 1
  br i1 %c, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
