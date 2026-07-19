; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x.get('proof_engine')=='z3_bv_tuple_equivalence_unsat']; assert d['metrics']['flag_cones_recovered']==8 and len(p)==8 and len({x['proof_query_hash'] for x in p})==1 and all(x['dependencies']==['complete_sub_flag_bundle_use_coverage','fixed_width_x86_flag_formula','identical_poison_support_per_flag'] for x in p)"

define i8 @sub_flag_bundle(i8 %a, i8 %b) {
; CHECK-LABEL: @sub_flag_bundle(
; CHECK: [[DIFF:%.*]] = sub i8 %a, %b
; CHECK: icmp eq i8 %a, %b
; CHECK: icmp slt i8 [[DIFF]], 0
; CHECK: icmp ult i8 %a, %b
; CHECK: icmp uge i8 %a, %b
; CHECK: call i8 @llvm.ctpop.i8(i8 [[DIFF]])
; CHECK: icmp slt i8 %a, %b
; CHECK: icmp sle i8 %a, %b
  %diff = sub i8 %a, %b
  %zf = icmp eq i8 %diff, 0
  %sf.shift = lshr i8 %diff, 7
  %sf = trunc i8 %sf.shift to i1
  %ab = xor i8 %a, %b
  %ar = xor i8 %a, %diff
  %of.bits = and i8 %ab, %ar
  %of.shift = lshr i8 %of.bits, 7
  %of = trunc i8 %of.shift to i1
  %not.a = xor i8 %a, -1
  %borrow.generate = and i8 %not.a, %b
  %not.ab = xor i8 %ab, -1
  %borrow.propagate = and i8 %not.ab, %diff
  %borrow.bits = or i8 %borrow.generate, %borrow.propagate
  %cf.shift = lshr i8 %borrow.bits, 7
  %cf = trunc i8 %cf.shift to i1
  %ae = xor i1 %cf, true
  %p4 = lshr i8 %diff, 4
  %px4 = xor i8 %diff, %p4
  %p2 = lshr i8 %px4, 2
  %px2 = xor i8 %px4, %p2
  %p1 = lshr i8 %px2, 1
  %px1 = xor i8 %px2, %p1
  %odd = trunc i8 %px1 to i1
  %pf = xor i1 %odd, true
  %l = xor i1 %sf, %of
  %le = or i1 %l, %zf
  %zf8 = zext i1 %zf to i8
  %sf8 = zext i1 %sf to i8
  %of8 = zext i1 %of to i8
  %cf8 = zext i1 %cf to i8
  %pf8 = zext i1 %pf to i8
  %l8 = zext i1 %l to i8
  %le8 = zext i1 %le to i8
  %ae8 = zext i1 %ae to i8
  %sf.bit = shl i8 %sf8, 1
  %of.bit = shl i8 %of8, 2
  %cf.bit = shl i8 %cf8, 3
  %pf.bit = shl i8 %pf8, 4
  %l.bit = shl i8 %l8, 5
  %le.bit = shl i8 %le8, 6
  %ae.bit = shl i8 %ae8, 7
  %m0 = or i8 %zf8, %sf.bit
  %m1 = or i8 %m0, %of.bit
  %m2 = or i8 %m1, %cf.bit
  %m3 = or i8 %m2, %pf.bit
  %m4 = or i8 %m3, %l.bit
  %m5 = or i8 %m4, %le.bit
  %mask = or i8 %m5, %ae.bit
  ret i8 %mask
}

define i32 @main() {
  %a = call i8 @sub_flag_bundle(i8 -128, i8 1)
  ; diff=127: OF, signed L/LE, and unsigned AE are set.
  %ok = icmp eq i8 %a, -28
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
