; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x.get('proof_engine')=='z3_bv_tuple_equivalence_unsat']; assert d['metrics']['flag_cones_recovered']==4 and len(p)==4 and len({x['proof_query_hash'] for x in p})==1 and all(x['dependencies']==['complete_test_flag_bundle_use_coverage','fixed_width_x86_flag_formula','identical_poison_support_per_flag'] for x in p)"

define i8 @test_flag_bundle(i8 %a, i8 %b) {
; CHECK-LABEL: @test_flag_bundle(
; CHECK: [[RESULT:%.*]] = and i8 %a, %b
; CHECK: icmp eq i8 [[RESULT]], 0
; CHECK: icmp ne i8 [[RESULT]], 0
; CHECK: icmp slt i8 [[RESULT]], 0
; CHECK: call i8 @llvm.ctpop.i8(i8 [[RESULT]])
  %result = and i8 %a, %b
  %zf = icmp eq i8 %result, 0
  %nz = icmp ne i8 %result, 0
  %sf.shift = lshr i8 %result, 7
  %sf = trunc i8 %sf.shift to i1
  %p4 = lshr i8 %result, 4
  %px4 = xor i8 %result, %p4
  %p2 = lshr i8 %px4, 2
  %px2 = xor i8 %px4, %p2
  %p1 = lshr i8 %px2, 1
  %px1 = xor i8 %px2, %p1
  %odd = trunc i8 %px1 to i1
  %pf = xor i1 %odd, true
  %zf8 = zext i1 %zf to i8
  %sf8 = zext i1 %sf to i8
  %pf8 = zext i1 %pf to i8
  %nz8 = zext i1 %nz to i8
  %sf.bit = shl i8 %sf8, 1
  %pf.bit = shl i8 %pf8, 2
  %nz.bit = shl i8 %nz8, 3
  %m0 = or i8 %zf8, %sf.bit
  %m1 = or i8 %m0, %pf.bit
  %mask = or i8 %m1, %nz.bit
  ret i8 %mask
}

define i32 @main() {
  %flags = call i8 @test_flag_bundle(i8 -16, i8 -127)
  ; result=0x80: SF and NZ are set, PF is clear.
  %ok = icmp eq i8 %flags, 10
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
