; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: jq -e '.metrics.dispatchers_unresolved == 0 and ([.proofs[] | select(.proof_engine == "complete_ssa_transition_and_plumbing_set" and (.dependencies | index("seed_reachable_transition_induction")))] | length == 1)' %t.json >/dev/null

; The unmatched edge reloads a shadow state and returns to the dispatcher.
; Its value is intentionally unknown, but the concrete seed and complete
; reachable transition closure prove that this edge is never entered.

@shadow.state = internal global i32 99

define i32 @main() {
entry:
  br label %header

header:
  %state = phi i32 [ 1, %entry ], [ %next, %latch ]
  %carry = phi i32 [ 0, %entry ], [ %carry.next, %latch ]
  switch i32 %state, label %default.carrier [
    i32 1, label %case.one
    i32 2, label %case.two
    i32 3, label %exit
    i32 4, label %dead.case
  ]

case.one:
  br label %latch

case.two:
  br label %latch

dead.case:
  br label %latch

default.carrier:
  %shadow = load i32, ptr @shadow.state
  br label %latch

latch:
  %next = phi i32 [ 2, %case.one ], [ 3, %case.two ],
                  [ 4, %dead.case ], [ %shadow, %default.carrier ]
  %carry.next = phi i32 [ %carry, %case.one ], [ %carry, %case.two ],
                        [ %carry, %dead.case ], [ %carry, %default.carrier ]
  br label %header

exit:
  ret i32 %carry
}

; CHECK-LABEL: define i32 @main()
; CHECK-NOT: switch i32
; CHECK-NOT: default.carrier
; CHECK: ret i32
