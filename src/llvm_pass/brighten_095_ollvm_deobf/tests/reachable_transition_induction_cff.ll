; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,sroa,instcombine<no-verify-fixpoint>,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=[x for x in d['proofs'] if x['kind']=='cff_dispatcher' and x['proof_engine']=='complete_ssa_transition_and_plumbing_set']; assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_unresolved']==0 and len(p)==1 and 'seed_reachable_transition_induction' in p[0]['dependencies']; assert not [x for x in d['proofs'] if x['result']!='proved']"

; State 30 is a syntactic bogus case whose transition deliberately falls into
; the default cycle.  It may be removed only after induction from seed 10
; proves that the live transition closure is 10 -> 20 -> exit.
define i32 @reachable_transition_induction() {
; CHECK-LABEL: @reachable_transition_induction(
; CHECK-NOT: switch
; CHECK-NOT: dispatch
; CHECK: ret i32 7
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 10, %entry ], [ %next, %latch ]
  %acc = phi i32 [ 0, %entry ], [ %next.acc, %latch ]
  switch i32 %state, label %latch [
    i32 10, label %case.live
    i32 20, label %exit
    i32 30, label %case.bogus
    i32 40, label %exit
  ]

case.live:
  br label %latch

case.bogus:
  %bogus.next = xor i32 %state, 1234567
  br label %latch

latch:
  %next = phi i32 [ 20, %case.live ],
                    [ %bogus.next, %case.bogus ],
                    [ %state, %dispatch ]
  %next.acc = phi i32 [ 7, %case.live ],
                        [ 99, %case.bogus ],
                        [ %acc, %dispatch ]
  br label %dispatch

exit:
  ret i32 %acc
}

define i32 @main() {
  %result = call i32 @reachable_transition_induction()
  %ok = icmp eq i32 %result, 7
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
