; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,sroa,instcombine<no-verify-fixpoint>,simplifycfg,adce,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['status']=='pass_detected_scope' and d['metrics']['dispatchers_recovered']==1 and d['metrics']['dispatchers_unresolved']==0"

; The live case computes its next state through a three-arm acyclic PHI.
; Recovery must prove the complete finite value set rather than requiring a
; fixture-specific two-arm select shape.
define i32 @finite_phi_transition(i32 %mode) {
; CHECK-LABEL: @finite_phi_transition(
; CHECK-NOT: switch i32 %state
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 10, %entry ], [ %next, %latch ]
  %acc = phi i32 [ 0, %entry ], [ %next.acc, %latch ]
  switch i32 %state, label %latch [
    i32 10, label %case.live
    i32 20, label %exit
    i32 30, label %exit
    i32 40, label %exit
  ]

case.live:
  %is.zero = icmp eq i32 %mode, 0
  br i1 %is.zero, label %path.zero, label %path.nonzero

path.nonzero:
  %is.one = icmp eq i32 %mode, 1
  br i1 %is.one, label %path.one, label %path.other

path.zero:
  br label %merge

path.one:
  br label %merge

path.other:
  br label %merge

merge:
  %next.value = phi i32 [ 20, %path.zero ],
                          [ 30, %path.one ],
                          [ 40, %path.other ]
  %acc.value = phi i32 [ 7, %path.zero ],
                         [ 8, %path.one ],
                         [ 9, %path.other ]
  br label %latch

latch:
  %next = phi i32 [ %next.value, %merge ], [ %state, %dispatch ]
  %next.acc = phi i32 [ %acc.value, %merge ], [ %acc, %dispatch ]
  br label %dispatch

exit:
  ret i32 %acc
}

define i32 @main() {
  %a = call i32 @finite_phi_transition(i32 0)
  %b = call i32 @finite_phi_transition(i32 1)
  %c = call i32 @finite_phi_transition(i32 2)
  %ab = add i32 %a, %b
  %sum = add i32 %ab, %c
  %ok = icmp eq i32 %sum, 24
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
