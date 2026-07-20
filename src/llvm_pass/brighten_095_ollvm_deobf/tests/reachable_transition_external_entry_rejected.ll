; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,sroa,instcombine<no-verify-fixpoint>,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); q=[x for x in d['proofs'] if x['kind']=='cff_dispatcher' and x['proof_engine']=='complete_cyclic_state_family_region']; assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and len(q)==1 and 'complete_external_edge_coverage' in q[0]['dependencies'] and 'multi_entry_case_join_ssa_reconstruction' in q[0]['dependencies']; assert not [x for x in d['proofs'] if x['result']!='proved']"

; The dispatcher has both a normal seed and an independent function-entry
; edge into a case.  Recovery must preserve both exact entry paths and rebuild
; the loop-carried accumulator at their join.
define i32 @external_case_entry(i1 %external) {
; CHECK-LABEL: @external_case_entry(
; CHECK-NOT: switch i32
; CHECK: select i1 %external, i32 9, i32 7
entry:
  br i1 %external, label %case.bogus, label %init

init:
  br label %dispatch

dispatch:
  %state = phi i32 [ 10, %init ], [ %next, %latch ]
  %acc = phi i32 [ 0, %init ], [ %next.acc, %latch ]
  switch i32 %state, label %latch [
    i32 10, label %case.live
    i32 20, label %exit
    i32 30, label %case.bogus
    i32 40, label %exit
  ]

case.live:
  br label %latch

case.bogus:
  br label %latch

latch:
  %next = phi i32 [ 20, %case.live ],
                    [ 20, %case.bogus ],
                    [ %state, %dispatch ]
  %next.acc = phi i32 [ 7, %case.live ],
                        [ 9, %case.bogus ],
                        [ %acc, %dispatch ]
  br label %dispatch

exit:
  ret i32 %acc
}

define i32 @main() {
  %normal = call i32 @external_case_entry(i1 false)
  %external = call i32 @external_case_entry(i1 true)
  %normal.ok = icmp eq i32 %normal, 7
  %external.ok = icmp eq i32 %external, 9
  %ok = and i1 %normal.ok, %external.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
