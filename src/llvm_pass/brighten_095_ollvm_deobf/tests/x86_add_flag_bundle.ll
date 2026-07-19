; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x.get('proof_engine')=='z3_bv_tuple_equivalence_unsat']; assert d['metrics']['flag_cones_recovered']==5 and len(p)==5 and len({x['proof_query_hash'] for x in p})==1 and all(x['dependencies']==['complete_add_flag_bundle_use_coverage','fixed_width_x86_flag_formula','identical_poison_support_per_flag'] for x in p)"

define i8 @add_flag_bundle(i8 %a, i8 %b) {
; CHECK-LABEL: @add_flag_bundle(
; CHECK: [[SUM:%.*]] = add i8 %a, %b
; CHECK: icmp eq i8 [[SUM]], 0
; CHECK: icmp slt i8 [[SUM]], 0
; CHECK: icmp ult i8 [[SUM]], %a
; CHECK: call i8 @llvm.ctpop.i8(i8 [[SUM]])
  %sum = add i8 %a, %b
  %zf = icmp eq i8 %sum, 0
  %sf.shift = lshr i8 %sum, 7
  %sf = trunc i8 %sf.shift to i1
  %ab = xor i8 %a, %b
  %not.ab = xor i8 %ab, -1
  %as = xor i8 %a, %sum
  %of.bits = and i8 %not.ab, %as
  %of.shift = lshr i8 %of.bits, 7
  %of = trunc i8 %of.shift to i1
  %carry.generate = and i8 %a, %b
  %either = or i8 %a, %b
  %not.sum = xor i8 %sum, -1
  %carry.propagate = and i8 %either, %not.sum
  %carry.bits = or i8 %carry.generate, %carry.propagate
  %cf.shift = lshr i8 %carry.bits, 7
  %cf = trunc i8 %cf.shift to i1
  %p4 = lshr i8 %sum, 4
  %px4 = xor i8 %sum, %p4
  %p2 = lshr i8 %px4, 2
  %px2 = xor i8 %px4, %p2
  %p1 = lshr i8 %px2, 1
  %px1 = xor i8 %px2, %p1
  %odd = trunc i8 %px1 to i1
  %pf = xor i1 %odd, true
  %zf8 = zext i1 %zf to i8
  %sf8 = zext i1 %sf to i8
  %of8 = zext i1 %of to i8
  %cf8 = zext i1 %cf to i8
  %pf8 = zext i1 %pf to i8
  %sf.bit = shl i8 %sf8, 1
  %of.bit = shl i8 %of8, 2
  %cf.bit = shl i8 %cf8, 3
  %pf.bit = shl i8 %pf8, 4
  %m0 = or i8 %zf8, %sf.bit
  %m1 = or i8 %m0, %of.bit
  %m2 = or i8 %m1, %cf.bit
  %mask = or i8 %m2, %pf.bit
  ret i8 %mask
}

define i32 @main() {
  %flags = call i8 @add_flag_bundle(i8 127, i8 1)
  %ok = icmp eq i8 %flags, 6
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
