; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='x86_flag_recovery']; single=[x for x in p if x['proof_engine']=='z3_bv_equivalence_unsat']; bundle=[x for x in p if x['proof_engine']=='z3_bv_tuple_equivalence_unsat']; assert d['metrics']['flag_cones_recovered']==9 and len(p)==9 and len(single)==6 and len(bundle)==3 and all(x['old_hash'] and x['new_hash'] and x['proof_query_hash'] for x in p) and all(x['dependencies']==['fixed_width_x86_flag_formula','identical_poison_support'] for x in single) and all(x['dependencies']==['complete_sub_flag_bundle_use_coverage','fixed_width_x86_flag_formula','identical_poison_support_per_flag'] for x in bundle)"

define i1 @zf_sub(i8 %a, i8 %b) {
; CHECK-LABEL: @zf_sub(
; CHECK-NEXT: [[P:%.*]] = icmp eq i8 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  %result = sub i8 %a, %b
  %zf = icmp eq i8 %result, 0
  ret i1 %zf
}

define i1 @cf_or_zf(i16 %a, i16 %b) {
; CHECK-LABEL: @cf_or_zf(
; CHECK-NEXT: [[P:%.*]] = icmp ule i16 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  %cf = icmp ult i16 %a, %b
  %zf = icmp eq i16 %a, %b
  %below_or_equal = or i1 %cf, %zf
  ret i1 %below_or_equal
}

define i1 @sf_xor_of(i8 %a, i8 %b) {
; CHECK-LABEL: @sf_xor_of(
; CHECK-NEXT: [[P:%.*]] = icmp slt i8 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  %result = sub i8 %a, %b
  %sf.shift = lshr i8 %result, 7
  %sf = trunc i8 %sf.shift to i1
  %ab = xor i8 %a, %b
  %ar = xor i8 %a, %result
  %of.bits = and i8 %ab, %ar
  %of.shift = lshr i8 %of.bits, 7
  %of = trunc i8 %of.shift to i1
  %signed_less = xor i1 %sf, %of
  ret i1 %signed_less
}

define i1 @standalone_sf(i16 %value) {
; CHECK-LABEL: @standalone_sf(
; CHECK-NEXT: [[P:%.*]] = icmp slt i16 %value, 0
; CHECK-NEXT: ret i1 [[P]]
  %shift = lshr i16 %value, 15
  %sf = trunc i16 %shift to i1
  ret i1 %sf
}

define i1 @add_cf(i8 %a, i8 %b) {
; CHECK-LABEL: @add_cf(
; CHECK: [[SUM:%.*]] = add i8 %a, %b
; CHECK-NEXT: [[P:%.*]] = icmp ult i8 [[SUM]], %a
; CHECK-NEXT: ret i1 [[P]]
  %sum = add i8 %a, %b
  %generate = and i8 %a, %b
  %either = or i8 %a, %b
  %not.sum = xor i8 %sum, -1
  %propagate = and i8 %either, %not.sum
  %carry.bits = or i8 %generate, %propagate
  %shift = lshr i8 %carry.bits, 7
  %cf = trunc i8 %shift to i1
  ret i1 %cf
}

define i1 @sub_cf(i8 %a, i8 %b) {
; CHECK-LABEL: @sub_cf(
; CHECK-NEXT: [[P:%.*]] = icmp ult i8 %a, %b
; CHECK-NEXT: ret i1 [[P]]
  %diff = sub i8 %a, %b
  %not.a = xor i8 %a, -1
  %generate = and i8 %not.a, %b
  %ab = xor i8 %a, %b
  %not.ab = xor i8 %ab, -1
  %propagate = and i8 %not.ab, %diff
  %borrow.bits = or i8 %generate, %propagate
  %shift = lshr i8 %borrow.bits, 7
  %cf = trunc i8 %shift to i1
  ret i1 %cf
}

define i1 @low_byte_pf(i8 %value) {
; CHECK-LABEL: @low_byte_pf(
; CHECK: [[COUNT:%.*]] = call i8 @llvm.ctpop.i8(i8 %value)
; CHECK-NEXT: [[BIT:%.*]] = and i8 [[COUNT]], 1
; CHECK-NEXT: [[P:%.*]] = icmp eq i8 [[BIT]], 0
; CHECK-NEXT: ret i1 [[P]]
  %s4 = lshr i8 %value, 4
  %x4 = xor i8 %value, %s4
  %s2 = lshr i8 %x4, 2
  %x2 = xor i8 %x4, %s2
  %s1 = lshr i8 %x2, 1
  %x1 = xor i8 %x2, %s1
  %odd = trunc i8 %x1 to i1
  %pf = xor i1 %odd, true
  ret i1 %pf
}

define i1 @malformed_pf_retained(i8 %value) {
; CHECK-LABEL: @malformed_pf_retained(
; CHECK-NOT: @llvm.ctpop.i8
  %s4 = lshr i8 %value, 3
  %x4 = xor i8 %value, %s4
  %s2 = lshr i8 %x4, 2
  %x2 = xor i8 %x4, %s2
  %s1 = lshr i8 %x2, 1
  %x1 = xor i8 %x2, %s1
  %odd = trunc i8 %x1 to i1
  %pf = xor i1 %odd, true
  ret i1 %pf
}

define i1 @poison_flag_cone_retained(i8 %a, i8 %b) {
; CHECK-LABEL: @poison_flag_cone_retained(
; CHECK: %result = sub nsw i8 %a, %b
; CHECK-NEXT: %zf = icmp eq i8 %result, 0
  %result = sub nsw i8 %a, %b
  %zf = icmp eq i8 %result, 0
  ret i1 %zf
}

define i1 @poison_nz_flag_cone_retained(i8 %a, i8 %b) {
; CHECK-LABEL: @poison_nz_flag_cone_retained(
; CHECK: %result = sub nsw i8 %a, %b
; CHECK-NEXT: %nz = icmp ne i8 %result, 0
  %result = sub nsw i8 %a, %b
  %nz = icmp ne i8 %result, 0
  ret i1 %nz
}

define i1 @uncovered_shared_flag_retained(i8 %a, i8 %b, i1 %external) {
; CHECK-LABEL: @uncovered_shared_flag_retained(
; CHECK: %carry.bits = or i8 %generate, %propagate
; CHECK: %cf = trunc i8 %shift to i1
; CHECK: %mixed = xor i1 %cf, %external
  %sum = add i8 %a, %b
  %generate = and i8 %a, %b
  %either = or i8 %a, %b
  %not.sum = xor i8 %sum, -1
  %propagate = and i8 %either, %not.sum
  %carry.bits = or i8 %generate, %propagate
  %shift = lshr i8 %carry.bits, 7
  %cf = trunc i8 %shift to i1
  ; This is not a known x86 condition-code consumer.  Rewriting the inner CF
  ; would lose the complete producer/use evidence, so the transaction must
  ; stay fail-closed even though CF alone is recognizable.
  %mixed = xor i1 %cf, %external
  ret i1 %mixed
}

define i32 @main() {
  %a = call i1 @zf_sub(i8 44, i8 44)
  %b = call i1 @zf_sub(i8 44, i8 45)
  %b.ok = xor i1 %b, true
  %c = call i1 @cf_or_zf(i16 65535, i16 7)
  %c.ok = xor i1 %c, true
  %d = call i1 @cf_or_zf(i16 7, i16 7)
  %e = call i1 @sf_xor_of(i8 -128, i8 1)
  %f = call i1 @sf_xor_of(i8 127, i8 -1)
  %f.ok = xor i1 %f, true
  %g = call i1 @standalone_sf(i16 -1)
  %h = call i1 @add_cf(i8 -1, i8 1)
  %i = call i1 @sub_cf(i8 0, i8 1)
  %j = call i1 @low_byte_pf(i8 3)
  %ab = and i1 %a, %b.ok
  %cd = and i1 %c.ok, %d
  %ef = and i1 %e, %f.ok
  %abcd = and i1 %ab, %cd
  %abcdef = and i1 %abcd, %ef
  %gh = and i1 %g, %h
  %ij = and i1 %i, %j
  %ghij = and i1 %gh, %ij
  %ok0 = and i1 %abcdef, %ghij
  %k = call i1 @malformed_pf_retained(i8 0)
  %ok = and i1 %ok0, %k
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
