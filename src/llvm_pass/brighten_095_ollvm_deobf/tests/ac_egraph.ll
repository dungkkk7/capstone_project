; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); s=[x for x in d['proofs'] if x['kind']=='bv_egraph_rewrite' and x['proof_engine']=='ac_saturation_z3_unsat']; m=[x for x in d['proofs'] if x['kind']=='bv_egraph_rewrite' and x['proof_engine']=='multi_root_ac_tuple_z3_unsat']; assert len(s)==1 and len(m)==2 and all(x['result']=='proved' and x['old_hash'] and x['new_hash'] and x['proof_query_hash'] for x in s+m) and all(x['dependencies']==['pure_integer_dag','identical_poison_support'] for x in s) and all(x['dependencies']==['pure_integer_multi_root_dag','shared_dominating_ac_extraction','identical_poison_support_per_root'] for x in m); assert d['metrics']['poison_support_rejects']>=1"

define i32 @and_idempotent_ac(i32 %x, i32 %y) {
; CHECK-LABEL: @and_idempotent_ac(
; CHECK: [[R:%.*]] = and i32 %x, %y
; CHECK-NEXT: ret i32 [[R]]
  %xy = and i32 %x, %y
  %r = and i32 %xy, %x
  ret i32 %r
}

define i32 @or_idempotent_ac(i32 %x, i32 %y) {
; CHECK-LABEL: @or_idempotent_ac(
; CHECK: [[R:%.*]] = or i32 %x, %y
; CHECK-NEXT: ret i32 [[R]]
  %xy = or i32 %x, %y
  %r = or i32 %xy, %y
  ret i32 %r
}

define i32 @xor_frozen_ac(i32 %x, i32 %y) {
; CHECK-LABEL: @xor_frozen_ac(
; CHECK: ret i32 %y
  %frozen = freeze i32 %x
  %a = xor i32 %frozen, %y
  %r = xor i32 %a, %frozen
  ret i32 %r
}

; Mathematically the same cancellation as xor_frozen_ac, but eliminating %x
; would eliminate poison propagation.  It must not be committed.
define i32 @xor_poison_sensitive_ac(i32 %x, i32 %y) {
; CHECK-LABEL: @xor_poison_sensitive_ac(
; CHECK: %a = xor i32 %x, %y
; CHECK-NEXT: %r = xor i32 %a, %x
; CHECK-NEXT: ret i32 %r
  %a = xor i32 %x, %y
  %r = xor i32 %a, %x
  ret i32 %r
}

define i32 @main() {
  %a = call i32 @and_idempotent_ac(i32 15, i32 10)
  %a.ok = icmp eq i32 %a, 10
  %b = call i32 @or_idempotent_ac(i32 5, i32 10)
  %b.ok = icmp eq i32 %b, 15
  %c = call i32 @xor_frozen_ac(i32 123, i32 77)
  %c.ok = icmp eq i32 %c, 77
  %d = call i32 @xor_poison_sensitive_ac(i32 123, i32 77)
  %d.ok = icmp eq i32 %d, 77
  %ab = and i1 %a.ok, %b.ok
  %cd = and i1 %c.ok, %d.ok
  %ok = and i1 %ab, %cd
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
