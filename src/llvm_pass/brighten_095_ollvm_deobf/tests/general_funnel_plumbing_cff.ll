; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,sroa,instcombine<no-verify-fixpoint>,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='cff_dispatcher' and x['proof_engine']=='complete_cyclic_state_family_region']; assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and len(p)==1 and set(['closed_default_linked_lookup_ring','exact_forwarded_state_family','ordered_lookup_resolution','complete_external_edge_coverage','exact_phi_and_plumbing_translation','multi_entry_case_join_ssa_reconstruction']).issubset(p[0]['dependencies']); assert not [x for x in d['proofs'] if x['result']!='proved']"

define i32 @general_funnel_plumbing() {
; CHECK-LABEL: @general_funnel_plumbing(
; CHECK-NOT: switch
; CHECK-NOT: dispatch.header
; CHECK-NOT: dispatch.outer
; CHECK-NOT: dispatch.sink
; CHECK: ret i32 10
entry:
  br label %dispatch.outer

dispatch.outer:
  %state = phi i32 [ 10, %entry ], [ %state.sink, %dispatch.sink ]
  %acc = phi i32 [ 1, %entry ], [ %acc.sink, %dispatch.sink ]
  br label %dispatch.header

dispatch.header:
  switch i32 %state, label %dispatch.header [
    i32 10, label %case.10
    i32 15, label %dispatch.sink
    i32 20, label %case.20
    i32 30, label %case.join
    i32 40, label %exit
  ]

case.10:
  %acc.10 = add i32 %acc, 2
  br label %dispatch.sink

case.20:
  %acc.20 = add i32 %acc, 3
  br label %dispatch.sink

case.join:
  %joined = phi i32 [ %acc, %dispatch.header ]
  %acc.30 = add i32 %joined, 4
  br label %dispatch.sink

dispatch.sink:
  %state.sink = phi i32 [ 20, %dispatch.header ],
                          [ 15, %case.10 ],
                          [ 30, %case.20 ],
                          [ 40, %case.join ]
  %acc.sink = phi i32 [ %acc, %dispatch.header ],
                        [ %acc.10, %case.10 ],
                        [ %acc.20, %case.20 ],
                        [ %acc.30, %case.join ]
  br label %dispatch.outer

exit:
  ret i32 %acc
}

define i32 @main() {
  %result = call i32 @general_funnel_plumbing()
  %ok = icmp eq i32 %result, 10
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
