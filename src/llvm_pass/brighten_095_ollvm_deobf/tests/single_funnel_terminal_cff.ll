; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,sroa,instcombine<no-verify-fixpoint>,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='cff_dispatcher' and x['proof_engine']=='complete_cyclic_state_family_region']; assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and len(p)==1 and set(['closed_default_linked_lookup_ring','exact_forwarded_state_family','ordered_lookup_resolution','complete_external_edge_coverage','exact_phi_and_plumbing_translation','multi_entry_case_join_ssa_reconstruction']).issubset(p[0]['dependencies']); assert not [x for x in d['proofs'] if x['result']!='proved']"

; A single (non-partitioned) dispatcher can carry semantic state through a
; two-level funnel/latch recurrence.  State 40 is a dispatcher-owned funnel
; trampoline; state 99 is an exact terminal-latch state.
define i32 @single_funnel_terminal() {
; CHECK-LABEL: @single_funnel_terminal(
; CHECK-NOT: switch
; CHECK-NOT: dispatch.header
; CHECK-NOT: dispatch.funnel
; CHECK-NOT: dispatch.latch
; CHECK: ret i32 6
entry:
  br label %dispatch.header

dispatch.header:
  %state = phi i32 [ 10, %entry ], [ %state.latch, %dispatch.latch ]
  %acc = phi i32 [ 0, %entry ], [ %acc.latch, %dispatch.latch ]
  switch i32 %state, label %dispatch.latch [
    i32 10, label %case.10
    i32 20, label %case.20
    i32 30, label %case.30
    i32 40, label %dispatch.funnel
    i32 50, label %case.50
  ]

case.10:
  %acc.10 = add i32 %acc, 1
  br label %dispatch.funnel

case.20:
  %acc.20 = add i32 %acc, 2
  br label %dispatch.funnel

case.30:
  %acc.30 = add i32 %acc, 3
  br label %dispatch.funnel

case.50:
  %acc.50 = add i32 %acc, 50
  br label %dispatch.funnel

dispatch.funnel:
  %state.funnel = phi i32 [ 50, %dispatch.header ],
                            [ 20, %case.10 ],
                            [ 30, %case.20 ],
                            [ 99, %case.30 ],
                            [ 99, %case.50 ]
  %acc.funnel = phi i32 [ %acc, %dispatch.header ],
                          [ %acc.10, %case.10 ],
                          [ %acc.20, %case.20 ],
                          [ %acc.30, %case.30 ],
                          [ %acc.50, %case.50 ]
  br label %dispatch.latch

dispatch.latch:
  %state.latch = phi i32 [ %state, %dispatch.header ],
                           [ %state.funnel, %dispatch.funnel ]
  %acc.latch = phi i32 [ %acc, %dispatch.header ],
                         [ %acc.funnel, %dispatch.funnel ]
  %done = icmp eq i32 %state.latch, 99
  br i1 %done, label %exit, label %dispatch.header

exit:
  ret i32 %acc.latch
}

define i32 @main() {
  %result = call i32 @single_funnel_terminal()
  %ok = icmp eq i32 %result, 6
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
