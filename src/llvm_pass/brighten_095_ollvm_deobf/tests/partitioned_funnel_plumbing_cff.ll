; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,sroa,instcombine<no-verify-fixpoint>,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='cff_dispatcher' and x['proof_engine']=='complete_cyclic_state_family_region']; assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and len(p)==1 and set(['closed_default_linked_lookup_ring','exact_forwarded_state_family','ordered_lookup_resolution','complete_external_edge_coverage','exact_phi_and_plumbing_translation','multi_entry_case_join_ssa_reconstruction']).issubset(p[0]['dependencies']); assert not [x for x in d['proofs'] if x['result']!='proved']"

define i32 @partitioned_funnel_plumbing() {
; CHECK-LABEL: @partitioned_funnel_plumbing(
; CHECK-NOT: switch
; CHECK-NOT: dispatch.header
; CHECK-NOT: dispatch.eq
; CHECK-NOT: dispatch.shard
; CHECK-NOT: dispatch.funnel
; CHECK-NOT: dispatch.latch
; CHECK: ret i32 11
entry:
  br label %dispatch.header

dispatch.header:
  %state = phi i32 [ 10, %entry ], [ %state.latch, %dispatch.latch ]
  %packed = phi i32 [ 0, %entry ], [ %packed.next, %dispatch.latch ]
  %acc = phi i32 [ 1, %entry ], [ %acc.latch, %dispatch.latch ]
  switch i32 %state, label %dispatch.eq [
    i32 10, label %case.10
    i32 15, label %dispatch.funnel
    i32 20, label %case.20
    i32 11, label %exit
  ]

dispatch.eq:
  %is.sparse.case = icmp eq i32 %state, 12
  br i1 %is.sparse.case, label %exit, label %dispatch.shard

case.10:
  %acc.10 = add i32 %acc, 2
  br label %dispatch.funnel

case.20:
  %acc.20 = add i32 %acc, 3
  br label %dispatch.funnel

dispatch.shard:
  switch i32 %state, label %dispatch.latch [
    i32 25, label %dispatch.funnel
    i32 30, label %case.30
    i32 40, label %exit
    i32 41, label %exit
  ]

case.30:
  %acc.30 = add i32 %acc, 4
  br label %dispatch.funnel

dispatch.funnel:
  %state.funnel = phi i32 [ 20, %dispatch.header ],
                            [ 30, %dispatch.shard ],
                            [ 15, %case.10 ],
                            [ 25, %case.20 ],
                            [ 40, %case.30 ]
  %packed.funnel = phi i32 [ %packed, %dispatch.header ],
                             [ %packed, %dispatch.shard ],
                             [ %packed, %case.10 ],
                             [ %packed, %case.20 ],
                             [ %packed, %case.30 ]
  %acc.funnel = phi i32 [ %acc, %dispatch.header ],
                          [ %acc, %dispatch.shard ],
                          [ %acc.10, %case.10 ],
                          [ %acc.20, %case.20 ],
                          [ %acc.30, %case.30 ]
  br label %dispatch.latch

dispatch.latch:
  %state.latch = phi i32 [ %state, %dispatch.shard ],
                           [ %state.funnel, %dispatch.funnel ]
  %packed.base = phi i32 [ %packed, %dispatch.shard ],
                           [ %packed.funnel, %dispatch.funnel ]
  %acc.latch = phi i32 [ %acc, %dispatch.shard ],
                         [ %acc.funnel, %dispatch.funnel ]
  %packed.next = or i32 %packed.base, 1
  br label %dispatch.header

exit:
  %result = add i32 %acc, %packed
  ret i32 %result
}

define i32 @main() {
  %result = call i32 @partitioned_funnel_plumbing()
  %ok = icmp eq i32 %result, 11
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
