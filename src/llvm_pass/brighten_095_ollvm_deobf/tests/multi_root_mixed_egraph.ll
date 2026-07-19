; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x.get('proof_engine')=='multi_root_mixed_bv_tuple_z3_unsat']; assert len(p)==1 and p[0]['result']=='proved' and p[0]['proof_query_hash'] and p[0]['dependencies']==['bounded_pure_integer_mixed_operator_dag','cheaper_existing_dominating_representative','identical_poison_support_per_root']"

define {i32, i32, i32} @mixed_mux_roots(i32 %x, i32 %y) {
; CHECK-LABEL: @mixed_mux_roots(
; CHECK: [[XM:%.*]] = and i32 %x, 16711935
; CHECK: [[YM:%.*]] = and i32 %y, -16711936
; CHECK: [[REP:%.*]] = or i32 [[XM]], [[YM]]
; CHECK-NOT: xor i32
; CHECK: insertvalue { i32, i32, i32 } poison, i32 [[REP]], 0
  %x.mask = and i32 %x, 16711935
  %y.notmask = and i32 %y, -16711936
  %rep = or i32 %x.mask, %y.notmask

  %xy = xor i32 %x, %y
  %delta = and i32 %xy, 16711935
  %mux1 = xor i32 %y, %delta
  %expensive1 = or i32 %mux1, %mux1

  %yx = xor i32 %y, %x
  %delta2 = and i32 %yx, 16711935
  %mux2 = xor i32 %y, %delta2
  %poison.zero = xor i32 %x, %x
  %expensive2 = or i32 %mux2, %poison.zero

  %a = insertvalue {i32, i32, i32} poison, i32 %rep, 0
  %b = insertvalue {i32, i32, i32} %a, i32 %expensive1, 1
  %c = insertvalue {i32, i32, i32} %b, i32 %expensive2, 2
  ret {i32, i32, i32} %c
}

define i32 @main() {
  %triple = call {i32, i32, i32} @mixed_mux_roots(i32 287454020, i32 1432778632)
  %a = extractvalue {i32, i32, i32} %triple, 0
  %b = extractvalue {i32, i32, i32} %triple, 1
  %c = extractvalue {i32, i32, i32} %triple, 2
  %a.ok = icmp eq i32 %a, 1428322116
  %b.ok = icmp eq i32 %b, 1428322116
  %c.ok = icmp eq i32 %c, 1428322116
  %ab.ok = and i1 %a.ok, %b.ok
  %ok = and i1 %ab.ok, %c.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
