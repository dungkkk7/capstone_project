; Direct predicate/jump catalog coverage for the independent LLVM port.

define i1 @predicate_setz_self(i32 %x) {
entry:
  %p = icmp eq i32 %x, %x
  ret i1 %p
}
define i1 @predicate_setnz_self(i32 %x) {
entry:
  %p = icmp ne i32 %x, %x
  ret i1 %p
}
define i1 @predicate_setb_self(i32 %x) {
entry:
  %p = icmp ult i32 %x, %x
  ret i1 %p
}
define i1 @predicate_setae_self(i32 %x) {
entry:
  %p = icmp uge i32 %x, %x
  ret i1 %p
}
define i1 @predicate_seta_self(i32 %x) {
entry:
  %p = icmp ugt i32 %x, %x
  ret i1 %p
}
define i1 @predicate_setbe_self(i32 %x) {
entry:
  %p = icmp ule i32 %x, %x
  ret i1 %p
}
define i1 @predicate_setl_self(i32 %x) {
entry:
  %p = icmp slt i32 %x, %x
  ret i1 %p
}
define i1 @predicate_setge_self(i32 %x) {
entry:
  %p = icmp sge i32 %x, %x
  ret i1 %p
}
define i1 @predicate_setg_self(i32 %x) {
entry:
  %p = icmp sgt i32 %x, %x
  ret i1 %p
}
define i1 @predicate_setle_self(i32 %x) {
entry:
  %p = icmp sle i32 %x, %x
  ret i1 %p
}

define i1 @predicate_setz_and_complement(i32 %x) {
entry:
  %nx = xor i32 %x, -1
  %v = and i32 %x, %nx
  %p = icmp eq i32 %v, 0
  ret i1 %p
}
define i1 @predicate_setnz_or_complement(i32 %x) {
entry:
  %nx = xor i32 %x, -1
  %v = or i32 %x, %nx
  %p = icmp ne i32 %v, 0
  ret i1 %p
}
define i1 @predicate_setz_xor_self(i32 %x) {
entry:
  %v = xor i32 %x, %x
  %p = icmp eq i32 %v, 0
  ret i1 %p
}
define i1 @predicate_setnz_xor_self(i32 %x) {
entry:
  %v = xor i32 %x, %x
  %p = icmp ne i32 %v, 0
  ret i1 %p
}
define i1 @predicate_setnz_or_one(i32 %x) {
entry:
  %v = or i32 %x, 3
  %p = icmp ne i32 %v, 0
  ret i1 %p
}
define i1 @predicate_setz_and_zero(i32 %x) {
entry:
  %v = and i32 %x, 0
  %p = icmp eq i32 %v, 0
  ret i1 %p
}
define i1 @predicate_setnz_or_minus_one(i32 %x) {
entry:
  %v = or i32 %x, -1
  %p = icmp ne i32 %v, 0
  ret i1 %p
}
define i1 @predicate_setb_zero(i32 %x) {
entry:
  %p = icmp ult i32 %x, 0
  ret i1 %p
}
define i1 @predicate_setae_zero(i32 %x) {
entry:
  %p = icmp uge i32 %x, 0
  ret i1 %p
}
define i1 @predicate_set_const() {
entry:
  %p = icmp eq i32 4, 5
  ret i1 %p
}
define i1 @predicate_lnot_one() {
entry:
  %p = xor i1 true, true
  ret i1 %p
}
define i1 @predicate_lnot_zero() {
entry:
  %p = xor i1 false, true
  ret i1 %p
}

define i32 @jump_jnz_rule1(i32 %x) {
entry:
  %nx = xor i32 %x, -1
  %bit = and i32 %nx, 1
  %neg = sub i32 0, %bit
  %p = icmp ne i32 %neg, %x
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
define i32 @jump_jnz_rule2(i32 %x) {
entry:
  %nx = xor i32 %x, -1
  %v = or i32 %nx, 3
  %p = icmp ne i32 %v, 0
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
define i32 @jump_jnz_rule3(i32 %x) {
entry:
  %nx = xor i32 %x, -1
  %v = or i32 %x, %nx
  %p = icmp ne i32 %v, 0
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
define i32 @jump_jnz_rule4(i32 %x) {
entry:
  %v = xor i32 %x, %x
  %p = icmp ne i32 %v, 0
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
define i32 @jump_jz_rule1(i32 %x) {
entry:
  %nx = xor i32 %x, -1
  %v = and i32 %x, %nx
  %p = icmp eq i32 %v, 0
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
define i32 @jump_jz_rule2(i32 %x) {
entry:
  %v = xor i32 %x, %x
  %p = icmp eq i32 %v, 0
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
define i32 @jump_jb_rule1(i32 %x) {
entry:
  %p = icmp ult i32 %x, %x
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
define i32 @jump_jae_rule1(i32 %x) {
entry:
  %p = icmp uge i32 %x, %x
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
define i32 @jump_jz_const() {
entry:
  %p = icmp eq i32 9, 9
  br i1 %p, label %yes, label %no
yes:
  ret i32 1
no:
  ret i32 0
}
