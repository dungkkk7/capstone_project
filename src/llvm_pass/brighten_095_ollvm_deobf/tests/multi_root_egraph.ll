; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); a=[x for x in d['proofs'] if x.get('proof_engine')=='multi_root_affine_tuple_z3_unsat']; c=[x for x in d['proofs'] if x.get('proof_engine')=='multi_root_ac_tuple_z3_unsat']; assert len(a)==2 and len(c)==1 and all(x['result']=='proved' for x in a+c) and all(x['dependencies']==['pure_integer_multi_root_dag','shared_dominating_extraction','identical_poison_support_per_root'] for x in a) and all(x['dependencies']==['pure_integer_multi_root_dag','shared_dominating_ac_extraction','identical_poison_support_per_root'] for x in c)"

define {i32, i32} @shared_affine_roots(i32 %x) {
; CHECK-LABEL: @shared_affine_roots(
; CHECK: [[SHARED:%.*]] = add i32 %x, 9
; CHECK-NOT: mul i32
; CHECK: [[A:%.*]] = insertvalue { i32, i32 } poison, i32 [[SHARED]], 0
; CHECK: [[B:%.*]] = insertvalue { i32, i32 } [[A]], i32 [[SHARED]], 1
; CHECK: ret { i32, i32 } [[B]]
  %x3 = mul i32 %x, 3
  %x5 = mul i32 %x, 5
  %x8 = add i32 %x3, %x5
  %x7 = mul i32 %x, 7
  %x1 = sub i32 %x8, %x7
  %root.a = add i32 %x1, 9
  %x11 = mul i32 %x, 11
  %x10 = mul i32 %x, 10
  %x1b = sub i32 %x11, %x10
  %root.b = add i32 %x1b, 9
  %a = insertvalue {i32, i32} poison, i32 %root.a, 0
  %b = insertvalue {i32, i32} %a, i32 %root.b, 1
  ret {i32, i32} %b
}

define {i32, i32} @shared_ac_roots(i32 %x, i32 %y) {
; CHECK-LABEL: @shared_ac_roots(
; CHECK: [[SHARED:%.*]] = and i32 %x, %y
; CHECK-NOT: and i32
; CHECK: [[A:%.*]] = insertvalue { i32, i32 } poison, i32 [[SHARED]], 0
; CHECK: [[B:%.*]] = insertvalue { i32, i32 } [[A]], i32 [[SHARED]], 1
; CHECK: ret { i32, i32 } [[B]]
  %xy = and i32 %x, %y
  %root.a = and i32 %xy, %x
  %yx = and i32 %y, %x
  %root.b = and i32 %yx, %x
  %a = insertvalue {i32, i32} poison, i32 %root.a, 0
  %b = insertvalue {i32, i32} %a, i32 %root.b, 1
  ret {i32, i32} %b
}

define i32 @main() {
  %pair = call {i32, i32} @shared_affine_roots(i32 1234567)
  %a = extractvalue {i32, i32} %pair, 0
  %b = extractvalue {i32, i32} %pair, 1
  %a.ok = icmp eq i32 %a, 1234576
  %b.ok = icmp eq i32 %b, 1234576
  %ok = and i1 %a.ok, %b.ok
  %ac = call {i32, i32} @shared_ac_roots(i32 287454020, i32 1432778632)
  %ac.a = extractvalue {i32, i32} %ac, 0
  %ac.b = extractvalue {i32, i32} %ac, 1
  %ac.a.ok = icmp eq i32 %ac.a, 287453952
  %ac.b.ok = icmp eq i32 %ac.b, 287453952
  %ac.ok = and i1 %ac.a.ok, %ac.b.ok
  %all.ok = and i1 %ok, %ac.ok
  %status = select i1 %all.ok, i32 0, i32 1
  ret i32 %status
}
