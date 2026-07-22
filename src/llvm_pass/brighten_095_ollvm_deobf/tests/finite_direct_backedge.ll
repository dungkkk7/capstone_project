; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes='brighten-ollvm-deobf-pass,verify' -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: jq -e '[.proofs[] | select(.proof_engine == "finite_direct_backedge_transition_set" and .result == "proved")] | length == 1' %t.json >/dev/null

; Regression for a generic loop-rotated CFF recurrence whose next state is
; computed directly in the backedge rather than merged through a latch PHI.
; The dynamic entry switch remains exact, while the finite cyclic transition
; is routed directly to its two proved targets.

define i32 @finite_direct_backedge(i1 %choose, i32 %seed) {
entry:
  br label %header

header:
  %state = phi i32 [ %seed, %entry ], [ %next, %backedge ]
  %carried = phi i32 [ 0, %entry ], [ %carried.next, %backedge ]
  switch i32 %state, label %trap [
    i32 10, label %backedge
    i32 20, label %result.true
    i32 30, label %result.false
    i32 40, label %other
    i32 50, label %other.2
    i32 60, label %other.3
    i32 70, label %other.4
  ]

backedge:
  %carried.next = add i32 %carried, 1
  %next = select i1 %choose, i32 20, i32 30
  br label %header

result.true:
  ret i32 %carried

result.false:
  ret i32 %carried

other:
  br label %backedge

other.2:
  br label %backedge

other.3:
  br label %backedge

other.4:
  ret i32 10

trap:
  unreachable
}

; CHECK-LABEL: define i32 @finite_direct_backedge(
; CHECK: header:
; CHECK: switch i32 {{.*}}, label %trap
; CHECK: backedge:
; CHECK: %next = select i1 %choose, i32 20, i32 30
; CHECK-NOT: br label %header
; CHECK: icmp eq i32 %next, 30
; CHECK: br i1 {{.*}}, label %result.false, label %result.true
